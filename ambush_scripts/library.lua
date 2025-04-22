local mod = AmbushSpawnIndicators



-- Convert an entity's Type, Variant and Subtype to a string key
---@param type integer
---@param variant? integer Can be left out to count all Variants.
---@param subtype? integer Can be left out to count all SubTypes.
---@return string
function AmbushSpawnIndicators:TypeKey(type, variant, subtype)
	local key = tostring(type)

	-- Variant
	if variant then
		key = key .. "." .. variant
	end
	 -- SubType
	if subtype then
		key = key .. "." .. subtype
	end

	return key
end



-- Check if the given entity is in the given list using its Type, Variant and Subtype as a string key
---@param list table
---@param entity Entity
---@return table | boolean
function AmbushSpawnIndicators:IsOnList(list, entity)
	return
	list[ entity.Type .. "." .. entity.Variant .. "." .. entity.SubType ]
	or list[ entity.Type .. "." .. entity.Variant ]
	or list[ tostring(entity.Type) ]
	or false
end



-- Check if the entity is part of the current wave
---@param entity Entity
---@return boolean
function AmbushSpawnIndicators:IsWaveSpawn(entity)
	-- Entities that should be completely ignored
	local result = mod:IsOnList(mod.SpawnData.Ignore, entity)
	local blacklisted = result and (type(result) ~= "function" or result(entity))

	-- Non-NPC entities that should also be queued (eg. Troll bombs)
	local validNonNPC = mod:IsOnList(mod.SpawnData.ValidNonNPCs, entity)

	return entity.FrameCount <= 0
	and (entity:IsActiveEnemy() or validNonNPC)
	and not blacklisted
	and not entity:GetData().WasQueued
	and not entity:GetData().DelayedSpawn
end

-- Check if the entity should be queued
---@param entity Entity
---@return boolean?
function AmbushSpawnIndicators:IsValidSpawn(entity)
	return not mod:IsOnList(mod.SpawnData.NoQueue, entity)
	and (not (entity.SpawnerEntity and entity.SpawnerEntity:ToNPC())
	or entity.SpawnerType == EntityType.ENTITY_GIDEON)
end



-- Check if the entity should have a marker
---@param entity Entity
---@return boolean
function AmbushSpawnIndicators:IsHidden(entity)
	local result = mod:IsOnList(mod.SpawnData.Hidden, entity)
	return result and (type(result) ~= "function" or result(entity))
end



-- Get the spawn delay
---@return integer
function AmbushSpawnIndicators:GetSpawnDelay()
	return mod.SavedData.Delay * 10
end



-- Create an ambush marker for an entity
---@param entity Entity
---@param pos? Vector
---@return EntityEffect marker
function AmbushSpawnIndicators:CreateMarker(entity, pos)
	pos = pos or entity.Position
	local marker = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TARGET, 0, pos, Vector.Zero, entity):ToEffect()
	marker.Timeout = mod:GetSpawnDelay()
	marker.DepthOffset = -1000
	marker.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
	marker:GetData().AmbushMarker = true

	-- Set the sprite
	local sprite = marker:GetSprite()
	sprite:Load("gfx/ambush_marker.anm2", true)
	sprite:Play("Blink", true)
	sprite.Color = Color(0.8,0.2,0.2, 1)


	-- Get the size of the marker
	local baseSize = 28 * 0.65
	local sizeMulti = math.max(entity.SizeMulti.X, entity.SizeMulti.Y)
	local size = entity.Size * sizeMulti / baseSize

	local spriteScale = 1
	local bigThreshold = 1.3
	local smallThreshold = 0.7

	-- Big
	if size >= bigThreshold then
		sprite:GetLayer("default"):SetVisible(false)
		sprite:GetLayer("small"):SetVisible(false)
		spriteScale = bigThreshold

	-- Small
	elseif size <= smallThreshold then
		sprite:GetLayer("big"):SetVisible(false)
		sprite:GetLayer("default"):SetVisible(false)
		spriteScale = smallThreshold

	-- Default
	else
		sprite:GetLayer("big"):SetVisible(false)
		sprite:GetLayer("small"):SetVisible(false)
	end

	marker.SpriteScale = Vector.One * (size / spriteScale / spriteScale)

	return marker
end



-- Queue all valid enemies (this is really stupid and I hate it but I couldn't find a better way to do it)
---@return boolean
function AmbushSpawnIndicators:QueueWaveSpawns()
	local spawns = {}

	for i, entity in pairs(Isaac.GetRoomEntities()) do
		if mod:IsWaveSpawn(entity) then
			-- Only save entities that weren't spawned by another one (except Gideon)
			if mod:IsValidSpawn(entity) then
				-- Store the needed data
				local isVisFatty = entity.Type == EntityType.ENTITY_VIS_FATTY and entity.Variant == 0
				local subtype = isVisFatty and 0 or entity.SubType -- Kilburn you fucking idiot

				local championIdx = entity:ToNPC() and entity:ToNPC():GetChampionColorIdx() or -1

				local data = {
					Type 		= entity.Type,
					Variant 	= entity.Variant,
					SubType 	= subtype,
					Position 	= entity.Position,
					Velocity 	= entity.Velocity,
					Spawner 	= entity.SpawnerEntity,
					Seed 		= entity.InitSeed,
					ChampionIdx = championIdx,
				}
				table.insert(spawns, data)


				-- Create the marker if the entity isn't hidden
				if not mod:IsHidden(entity) then
					local pos = entity.Position

					-- Entities that snap to walls
					if mod:IsOnList(mod.SpawnData.SnapToWalls, entity) then
						local nearestDistance = 9999

						for j = -180, 90, 90 do
							local vector = Vector.FromAngle(j)
							local checkPos = EntityLaser.CalculateEndPoint(entity.Position, vector, Vector.Zero, entity, 0)
							local distance = checkPos:Distance(entity.Position)

							if distance < nearestDistance then
								pos = checkPos
								nearestDistance = distance
							end
						end
					end

					-- Maze Roamer type beat
					if mod:IsOnList(mod.SpawnData.MirroredMarker, entity) then
						local room = Game():GetRoom()
						local x = room:GetBottomRightPos().X + (room:GetTopLeftPos().X - entity.Position.X)
						local y = room:GetBottomRightPos().Y + (room:GetTopLeftPos().Y - entity.Position.Y)
						mod:CreateMarker(entity, Vector(x, y))
					end

					local offset = mod:IsOnList(mod.SpawnData.PositionOffset, entity) or Vector.Zero
					mod:CreateMarker(entity, pos + offset)
				end
			end


			-- Remove the entity
			if entity:ToNPC() then
				entity:ToNPC().CanShutDoors = false
				entity:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
				entity.MaxHitPoints = 0
			end

			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			entity.Visible = false
			entity:GetData().WasQueued = true
			entity:Remove()

			-- Run any post-queue callbacks
			Isaac.RunCallbackWithParam("AMBUSH_INDICATOR_POST_QUEUE", entity.Type, entity)
		end
	end


	-- Fire it up!
	if #spawns > 0 then
		local wave = {
			Spawns = spawns,
			Timer = mod:GetSpawnDelay() - 1,
		}
		table.insert(mod.SpawnManager.Waves, wave)

		mod:PreventNextWave()
		SFXManager():Stop(SoundEffect.SOUND_SUMMONSOUND)
		return true
	end

	return false
end