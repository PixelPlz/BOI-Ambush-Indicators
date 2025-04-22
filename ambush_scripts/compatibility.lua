local mod = AmbushSpawnIndicators



function mod:LoadCompatibility()
	--[[ Enhanced Boss Bars ]]--
	if HPBars then
		-- Remove the door locker's boss bar
		local stringID = tostring(mod.DoorLocker.Type) .. "." .. tostring(mod.DoorLocker.Variant)
		HPBars.BossIgnoreList[stringID] = true
	end



	--[[ Boss Butch ]]--
	if BossButch then
		-- Hide Sparky
		mod:AddSpawnData("Hidden", BossButch.Entities.Sparky.Type, BossButch.Entities.Sparky.Variant)

		-- Snap his holes to the walls
		mod:AddSpawnData("SnapToWalls", BossButch.Entities.SparkyWallHole.Type, BossButch.Entities.SparkyWallHole.Variant)
	end



	--[[ Fiend Folio ]]--
	if FiendFolio then
		-- Maze Runner extra marker
		mod:AddSpawnData("MirroredMarker", FiendFolio.FF.MazeRunner.ID, FiendFolio.FF.MazeRunner.Var)

		-- Hidden entities
		local hidden = {
			FiendFolio.FF.Aper,
			FiendFolio.FF.OrgBashful,
			FiendFolio.FF.OrgSpeedy,
		}
		for i, entry in pairs(hidden) do
			mod:AddSpawnData("Hidden", entry.ID, entry.Var)
		end


		-- Remove Scowl Creep's tractor beam
		function mod:ScowlCreepBeam(entity)
			if entity.Variant == FiendFolio.FF.ScowlCreep.Var then
				for i, beam in pairs(Isaac.FindByType(EntityType.ENTITY_LASER)) do
					if beam.SpawnerEntity and beam.SpawnerEntity.Index == entity.Index then
						beam.Visible = false
						beam:Remove()
					end
				end
			end
		end
		mod:AddCallback(mod.PostQueueCallback, mod.ScowlCreepBeam, FiendFolio.FF.ScowlCreep.ID)
	end



	--[[ Fall from Grace ]]--
	if FFGRACE then
		-- Hide Tootie
		mod:AddSpawnData("Hidden", FFGRACE.ENT.TOOTIE.id, FFGRACE.ENT.TOOTIE.variant)


		-- Stop the wall effects for queued Dirt Diggers
		function mod:DirtDiggerDirt(entity)
			if entity.Variant == FFGRACE.ENT.DIRT_DIGGER.variant then
				local effects = {
					EffectVariant.POOF01,
					FFGRACE.ENT.DIRT_DIGGER_CRACK.variant,
					EffectVariant.DUST_CLOUD,
					EffectVariant.ROCK_PARTICLE,
				}

				-- Remove the visual effects
				for i, entry in pairs(effects) do
					for j, effect in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, entry)) do
						if effect.SpawnerEntity and effect.SpawnerEntity.Index == entity.Index then
							effect.Visible = false
							effect:Remove()
						end
					end
				end

				-- Stop the sound
				SFXManager():Stop(SoundEffect.SOUND_ROCK_CRUMBLE)
			end
		end
		mod:AddCallback(mod.PostQueueCallback, mod.DirtDiggerDirt, FFGRACE.ENT.DIRT_DIGGER.id)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, mod.LoadCompatibility)