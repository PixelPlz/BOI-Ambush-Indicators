local mod = AmbushSpawnIndicators

mod.PostQueueCallback = "AMBUSH_INDICATOR_POST_QUEUE"



-- Door locker enums
mod.DoorLocker = {
	Type 	= Isaac.GetEntityTypeByName("Ambush Spawn Indicators Door Locker"),
	Variant = Isaac.GetEntityVariantByName("Ambush Spawn Indicators Door Locker"),
}



-- Extra spawn data
AmbushSpawnIndicators.SpawnData = {
	-- Ignore completely
	Ignore = {
		[ mod:TypeKey(mod.DoorLocker.Type, mod.DoorLocker.Variant) ] = true,
	},

	-- Remove but don't queue
	NoQueue = {
		[ mod:TypeKey(EntityType.ENTITY_VISAGE, 1) ] = true,
	},

	-- Non-NPC entities that should also be queued
	ValidNonNPCs = {
		[ mod:TypeKey(EntityType.ENTITY_BOMB, BombVariant.BOMB_TROLL) ] 	  = true,
		[ mod:TypeKey(EntityType.ENTITY_BOMB, BombVariant.BOMB_SUPERTROLL) ]  = true,
		[ mod:TypeKey(EntityType.ENTITY_BOMB, BombVariant.BOMB_GOLDENTROLL) ] = true,
	},

	-- Entities that don't get markers
	Hidden = {
		[ mod:TypeKey(EntityType.ENTITY_DOPLE) ] 			 = true,
		[ mod:TypeKey(EntityType.ENTITY_DUST) ] 			 = true,
		[ mod:TypeKey(EntityType.ENTITY_DUSTY_DEATHS_HEAD) ] = true,
	},

	-- Position offset for the marker
	PositionOffset = {
		[ mod:TypeKey(EntityType.ENTITY_GURDY) ] 	= Vector(0,  20),
		[ mod:TypeKey(EntityType.ENTITY_MEGA_MAW) ] = Vector(0, -60),
		[ mod:TypeKey(EntityType.ENTITY_GATE) ] 	= Vector(0, -40),
	},

	-- Snaps the marker to the nearest wall
	SnapToWalls = {
		[ mod:TypeKey(EntityType.ENTITY_WALL_CREEP) ]  = true,
		[ mod:TypeKey(EntityType.ENTITY_RAGE_CREEP) ]  = true,
		[ mod:TypeKey(EntityType.ENTITY_BLIND_CREEP) ] = true,
		[ mod:TypeKey(EntityType.ENTITY_THE_THING) ]   = true,
	},

	-- Creates a second marker with a mirrored position
	MirroredMarker = {
		[ mod:TypeKey(EntityType.ENTITY_MAZE_ROAMER) ] = true,
	},
}