--
--	Custom Addon Framework Tab Module and Tool Helper
--
include("caf/core/shared/caf_tools.lua")
local usetab = CreateClientConVar("CAF_UseTab", "1", true, false)

local function CAFTab()
	if usetab:GetBool() then
		spawnmenu.AddToolTab("Custom Addon Framework", "CAF")
	end
end

hook.Add("AddToolMenuTabs", "CAFTab", CAFTab)
