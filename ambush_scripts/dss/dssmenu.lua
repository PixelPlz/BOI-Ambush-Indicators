local mod = AmbushSpawnIndicators



--[[ Initialize Dead Sea Scrolls ]]--
local DSSModName = "Dead Sea Scrolls (" .. mod.Name .. ")"
local DSSCoreVersion = 7
local MenuProvider = {}

function MenuProvider.SaveSaveData()
	mod:HandleExitSave()
end
function MenuProvider.GetPaletteSetting()
	return mod.SavedData.DSS.PaletteSetting
end
function MenuProvider.SavePaletteSetting(var)
	mod.SavedData.DSS.PaletteSetting = var
end
function MenuProvider.GetHudOffsetSetting()
	return Options.HUDOffset * 10
end
function MenuProvider.SaveHudOffsetSetting(var)
	if not REPENTANCE then
		mod.SavedData.DSS.HudOffset = var
	end
end
function MenuProvider.GetGamepadToggleSetting()
	return mod.SavedData.DSS.GamepadToggle
end
function MenuProvider.SaveGamepadToggleSetting(var)
	mod.SavedData.DSS.GamepadToggle = var
end
function MenuProvider.GetMenuKeybindSetting()
	return mod.SavedData.DSS.MenuKeybind
end
function MenuProvider.SaveMenuKeybindSetting(var)
	mod.SavedData.DSS.MenuKeybind = var
end
function MenuProvider.GetMenuHintSetting()
	return mod.SavedData.DSS.MenuHint
end
function MenuProvider.SaveMenuHintSetting(var)
	mod.SavedData.DSS.MenuHint = var
end
function MenuProvider.GetMenuBuzzerSetting()
	return mod.SavedData.DSS.MenuBuzzer
end
function MenuProvider.SaveMenuBuzzerSetting(var)
	mod.SavedData.DSS.MenuBuzzer = var
end
function MenuProvider.GetMenusNotified()
	return mod.SavedData.DSS.MenusNotified
end
function MenuProvider.SaveMenusNotified(var)
	mod.SavedData.DSS.MenusNotified = var
end
function MenuProvider.GetMenusPoppedUp()
	return mod.SavedData.DSS.MenusPoppedUp
end
function MenuProvider.SaveMenusPoppedUp(var)
	mod.SavedData.DSS.MenusPoppedUp = var
end

local DSSInitializerFunction = require("ambush_scripts.dss.dssmenucore")
local dssmod = DSSInitializerFunction(DSSModName, DSSCoreVersion, MenuProvider)





--[[ Helpers ]]--
-- Create a DSS option entry
---@param settingName string
---@param displayName string
---@param displayTooltip? table
---@param choices? table If left out it will default to an `on / off` toggle.
---@return table
function mod:CreateDSSOption(settingName, displayName, displayTooltip, choices)
	-- Create the setting entry
	local setting = {
		str = displayName,
		fsize = 2,
		setting = 1,
		choices = choices or {'on', 'off'},
		variable = settingName,

		-- Load the saved option
		load = function()
			if choices then
				return mod.SavedData[settingName] or mod.DefaultSettings[settingName]
			else
				return mod.SavedData[settingName] and 1 or 2
			end
		end,

		-- Save the option
		store = function(var)
			if choices then
				mod.SavedData[settingName] = var
			else
				mod.SavedData[settingName] = var == 1
			end
		end
	}

	-- Add the tooltip
	if displayTooltip then
		setting.tooltip = { strset = displayTooltip }
	end

	return setting
end



--[[ Create the menus ]]--
local directory = {
	-- Main menu
	main = {
		title = 'ambush markers',
		buttons = {
			{ str = 'resume game', action = 'resume' },
			{ str = 'general', 	   dest   = 'general' },
			{ str = 'waves', 	   dest   = 'waves' },
			dssmod.changelogsButton,
		},
		tooltip = dssmod.menuOpenToolTip
	},

	-- General
	general = {
		title = 'general settings',
		buttons = {
			mod:CreateDSSOption(
				"Delay",
				"spawn delay",
				{ 'how long', 'to display', 'markers for', },
				{ '0.33 seconds', '0.66 seconds (default)', '1 second', }
			),
			{ str = '', fsize = 3, nosel = true },

			mod:CreateDSSOption(
				"FastGideon",
				"faster gideon",
				{ 'enables', 'great gideon', 'summoning', 'waves', 'instantly', 'after the', 'previous one', }
			),

			-- DSS defaults
			{ str = '', fsize = 3, nosel = true },
			dssmod.gamepadToggleButton,
			dssmod.menuKeybindButton,
			dssmod.paletteButton,
			dssmod.menuHintButton,
			dssmod.menuBuzzerButton,
		},
	},

	-- Waves
	waves = {
		title = 'wave indicators',
		buttons = {
			mod:CreateDSSOption( "GreedMode", "greed mode" ),
			{ str = '', fsize = 1, nosel = true },
			mod:CreateDSSOption( "ChallengeRooms", "challenge rooms", { 'also includes', 'boss rush', } ),
			{ str = '', fsize = 1, nosel = true },
			mod:CreateDSSOption( "Gideon", "great gideon" ),
			{ str = '', fsize = 1, nosel = true },
			mod:CreateDSSOption( "EventSpawns", "event spawns", { 'e.g.', 'from buttons', } ),
		},
	},
}





--[[ Add the menu to DSS ]]--
local directorykey = {
	Item = directory.main,
	Main = 'main',
	Idle = false,
	MaskAlpha = 1,
	Settings = {},
	SettingsChanged = false,
	Path = {},
}

DeadSeaScrollsMenu.AddMenu("Ambush Markers", {
	Run = dssmod.runMenu,
	Open = dssmod.openMenu,
	Close = dssmod.closeMenu,
	UseSubMenu = false,
	Directory = directory,
	DirectoryKey = directorykey
})