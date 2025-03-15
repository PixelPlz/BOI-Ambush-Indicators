local mod = AmbushSpawnIndicators
local json = require("json")



-- Default settings
AmbushSpawnIndicators.DefaultSettings = {
	Delay 	   = 2,
	FastGideon = true,

	GreedMode 	   = true,
	ChallengeRooms = true,
	Gideon 		   = true,
	EventSpawns    = true,
}

-- Persistent settings
AmbushSpawnIndicators.SavedData = {
	Delay 	   = mod.DefaultSettings.Delay,
	FastGideon = mod.DefaultSettings.FastGideon,

	GreedMode 	   = mod.DefaultSettings.GreedMode,
	ChallengeRooms = mod.DefaultSettings.ChallengeRooms,
	Gideon 		   = mod.DefaultSettings.Gideon,
	EventSpawns    = mod.DefaultSettings.EventSpawns,

	DSS = {},
}



-- Load the save data
function mod:RefreshSaveData(isContinue)
	if mod:HasData() then
		mod.SavedData = json.decode(mod:LoadData())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.RefreshSaveData)



-- Save when exiting a run
function mod:HandleExitSave()
	mod:SaveData(json.encode(mod.SavedData))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.HandleExitSave)

-- Save when luamodding
function mod:HandleLuamodSave(unloadedMod)
	if unloadedMod.Name == self.Name and Game():GetNumPlayers() > 0
	and mod.SavedData then
		mod:ResetSpawnManager() -- Removes any door lockers
		mod:SaveData(json.encode(mod.SavedData))
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, mod.HandleLuamodSave)