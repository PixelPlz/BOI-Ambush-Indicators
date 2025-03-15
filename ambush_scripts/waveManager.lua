local mod = AmbushSpawnIndicators



-- Turn the first spawn of a wave into my personal wave count checker
-- (What no ambush callbacks does to a mf...)
function mod:WaveManager(entity)
	if mod:IsWaveSpawn(entity) then
		local level = Game():GetLevel()
		local room = Game():GetRoom()
		local shouldQueue = false


		-- Greed Mode
		if mod.SavedData.GreedMode
		and Game():IsGreedMode()
		and level:GetCurrentRoomIndex() == level:GetStartingRoomIndex()
		and mod.WaveCounter ~= level.GreedModeWave then
			shouldQueue = true
			mod.WaveCounter = level.GreedModeWave


		-- Ambush
		elseif mod.SavedData.ChallengeRooms
		and room:IsAmbushActive() then
			local wave = Ambush.GetCurrentWave()

			if mod.WaveCounter ~= wave then
				shouldQueue = true
				mod.WaveCounter = wave
			end
		end


		-- Queue all the spawns and prevent this poor sucker from updating
		if shouldQueue then
			mod:QueueWaveSpawns()
			entity:SetDead(false) -- Otherwise they might do their death effects
			return true
		end
	end
end
mod:AddPriorityCallback(ModCallbacks.MC_PRE_NPC_RENDER,  CallbackPriority.IMPORTANT * 10, mod.WaveManager)
mod:AddPriorityCallback(ModCallbacks.MC_PRE_BOMB_RENDER, CallbackPriority.IMPORTANT * 10, mod.WaveManager)



-- Gread Gideon
function mod:GideonUpdate(entity)
	if entity.SubType ~= 1 then
		local sprite = entity:GetSprite()


		-- Start the next wave as soon as the current one is done
		if mod.SavedData.FastGideon
		and entity.FrameCount >= 1 and entity.HitPoints >= 1
		and (entity.I1 == 1 or entity.I1 == 257) and entity.State ~= NpcState.STATE_SUMMON then -- The current wave is done
			local lastState = entity.State
			local lastAnimation = sprite:GetAnimation()
			local lastFrame = sprite:GetFrame()

			-- Summon the next wave
			if mod.SavedData.Gideon then
				mod.StopNextSummonSound = true
			end

			entity.State = NpcState.STATE_SUMMON
			sprite:Play("Summon", true)
			sprite:SetFrame(100)
			sprite:Update()
			entity:Update()

			-- Do the summon animation for the first wave
			if entity.HitPoints == entity.MaxHitPoints then
				entity.State = NpcState.STATE_SUMMON2
				sprite:Play("Summon", true)

			-- Resume the previous state otherwise
			else
				entity.State = lastState
				sprite:Play(lastAnimation, true)
				sprite:SetFrame(lastFrame)
			end
		end


		-- Custom summon state
		if entity.State == NpcState.STATE_SUMMON2 then
			if sprite:IsEventTriggered("Sound") then
				entity:PlaySound(SoundEffect.SOUND_MONSTER_YELL_B, 1, 2, false, 0.9)

			elseif sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end


		elseif mod.SavedData.Gideon then
			-- Stop the summon sound
			if sprite:IsPlaying("Summon") then
				mod.StopNextSummonSound = true

			-- Queue the next wave
			elseif sprite:IsFinished("Summon") then
				mod:QueueWaveSpawns()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GideonUpdate, EntityType.ENTITY_GIDEON)



-- Event spawns
function mod:PreEventSpawn(effect)
	if effect:IsDead() then
		mod.StopNextSummonSound = true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_EFFECT_UPDATE, mod.PreEventSpawn, EffectVariant.SPAWNER)

function mod:EventSpawn(entity)
	if entity.Variant == EffectVariant.SPAWNER and mod.SavedData.EventSpawns then
		mod:QueueWaveSpawns()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.EventSpawn, EntityType.ENTITY_EFFECT)



-- Stop the summond sound when queuing wave enemies
function mod:StopSummondSound()
	-- Event spawns / Gideon minions
	if mod.StopNextSummonSound then
		mod.StopNextSummonSound = nil
		return false

	-- Greed Mode
	elseif mod.SavedData.GreedMode
	and Game():IsGreedMode()
	and mod.WaveCounter ~= Game():GetLevel().GreedModeWave then
		return false

	-- Ambush
	elseif mod.SavedData.ChallengeRooms
	and Game():GetRoom():IsAmbushActive()
	and mod.WaveCounter ~= Ambush.GetCurrentWave() then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_SFX_PLAY, mod.StopSummondSound, SoundEffect.SOUND_SUMMONSOUND)