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
		local sparky = mod:TypeKey(BossButch.Entities.Sparky.Type, BossButch.Entities.Sparky.Variant)
		mod.SpawnData.Hidden[sparky] = true

		-- Snap his holes to the walls
		local wallHole = mod:TypeKey(BossButch.Entities.SparkyWallHole.Type, BossButch.Entities.SparkyWallHole.Variant)
		mod.SpawnData.SnapToWalls[wallHole] = true
	end



	--[[ Fiend Folio ]]--
	if FiendFolio then
		-- Maze Runner extra marker
		local mazeRunner = mod:TypeKey(FiendFolio.FF.MazeRunner.ID, FiendFolio.FF.MazeRunner.Var)
		mod.SpawnData.MirroredMarker[mazeRunner] = true

		-- Hidden entities
		local hidden = {
			mod:TypeKey(FiendFolio.FF.Aper.ID, 		 FiendFolio.FF.Aper.Var),
			mod:TypeKey(FiendFolio.FF.OrgBashful.ID, FiendFolio.FF.OrgBashful.Var),
			mod:TypeKey(FiendFolio.FF.OrgSpeedy.ID,  FiendFolio.FF.OrgSpeedy.Var),
		}
		for i, key in pairs(hidden) do
			mod.SpawnData.Hidden[key] = true
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
		-- Tootie
		local tootie = mod:TypeKey(FFGRACE.ENT.TOOTIE.id, FFGRACE.ENT.TOOTIE.variant)
		mod.SpawnData.Hidden[tootie] = true


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