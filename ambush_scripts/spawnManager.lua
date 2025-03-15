local mod = AmbushSpawnIndicators



-- Create / reset the spawn manager
function AmbushSpawnIndicators:ResetSpawnManager()
	-- Remove the door locker first if it exists
	if mod.SpawnManager and mod.SpawnManager.DoorLocker then
		mod.SpawnManager.DoorLocker:Remove()
		mod.SpawnManager.DoorLocker = nil
	end

	mod.SpawnManager = { Waves = {}, }
end
mod:ResetSpawnManager()

-- Reset the wave manager and wave counters when entering a room
function mod:ResetEverything()
	mod:ResetSpawnManager()
	mod.WaveCounter = 0
	mod.StopNextSummonSound = nil
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.ResetEverything)



-- Prevent the next wave from spawning
function AmbushSpawnIndicators:PreventNextWave()
	local room = Game():GetRoom()

	-- Stop the Greed Mode timer from going down
	if Game():IsGreedMode() then
		if not mod.SpawnManager.GreedModeTimer then
			mod.SpawnManager.GreedModeTimer = room:GetGreedWaveTimer()
		end
		room:SetGreedWaveTimer(30)
	end

	-- Boss entity for Boss Rush and challenge room waves
	if not mod.SpawnManager.DoorLocker
	or not mod.SpawnManager.DoorLocker:Exists() then
		mod.SpawnManager.DoorLocker = Isaac.Spawn(mod.DoorLocker.Type, mod.DoorLocker.Variant, 0, Vector.Zero, Vector.Zero, nil):ToNPC()
	end
end



-- Update the spawn manager
function mod:UpdateSpawnManager()
	local room = Game():GetRoom()

	if #mod.SpawnManager.Waves > 0 then
		local spawnedWaves = {}

		-- Go through all the waves
		for i, wave in pairs(mod.SpawnManager.Waves) do
			local spawns = {}

			if wave.Timer <= 0 then
				-- Spawn the stored entities
				for j, entry in pairs(wave.Spawns) do
					local entity = Game():Spawn(entry.Type, entry.Variant, entry.Position, entry.Velocity, entry.Spawner, entry.SubType, entry.Seed)
					entity:AddEntityFlags(EntityFlag.FLAG_AMBUSH)
					entity:GetData().DelayedSpawn = true
					table.insert(spawns, entity)

					-- Set its champion type
					if entry.ChampionIdx ~= -1 then
						entity:ToNPC():MakeChampion(entry.Seed, entry.ChampionIdx, true)
					end
				end

				-- Update the entities after all of them spawned (mainly for segmented bosses)
				for j, entity in pairs(spawns) do
					if entity and entity:Exists() then
						entity:Update()
					end
				end

				table.insert(spawnedWaves, i)
				SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND)

			else
				wave.Timer = wave.Timer - 1
			end
		end

		-- Remove spawned waves after all of them have been processed
		for i, wave in pairs(spawnedWaves) do
			mod.SpawnManager.Waves[wave] = nil
		end


		-- Prevent the next wave while there are pending spawns
		if #mod.SpawnManager.Waves > 0 then
			mod:PreventNextWave()

		-- Reset the manager otherwise
		else
			-- Set the Greed Mode timer back
			if mod.SpawnManager.GreedModeTimer then
				room:SetGreedWaveTimer(mod.SpawnManager.GreedModeTimer)
			end
			mod:ResetSpawnManager()
		end


	-- Skip the button blinking in Greed Mode
	elseif mod.SavedData.GreedMode
	and room:GetGreedWaveTimer() > 1 -- 0 is inactive and 1 spawns the next wave
	and room:GetGreedWaveTimer() <= mod:GetSpawnDelay() then
		room:SetGreedWaveTimer(1)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.UpdateSpawnManager)



-- Door locker entity
function mod:DoorLockerInit(entity)
	if entity.Variant == mod.DoorLocker.Variant then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity:AddEntityFlags(
			EntityFlag.FLAG_NO_STATUS_EFFECTS |
			EntityFlag.FLAG_NO_TARGET |
			EntityFlag.FLAG_DONT_OVERWRITE |
			EntityFlag.FLAG_HIDE_HP_BAR |
			EntityFlag.FLAG_NO_REWARD |
			EntityFlag.FLAG_NO_PLAYER_CONTROL |
			EntityFlag.FLAG_NO_QUERY
		)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity.Visible = false
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.DoorLockerInit, mod.DoorLocker.Type)

function mod:DoorLockerUpdate(entity)
	if entity.Variant == mod.DoorLocker.Variant then
		-- Failsafe
		if not mod.SpawnManager.DoorLocker
		or mod.SpawnManager.DoorLocker.Index ~= entity.Index then
			entity:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DoorLockerUpdate, mod.DoorLocker.Type)