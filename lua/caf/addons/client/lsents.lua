﻿local RD = {}

--The Class
--[[
	The Constructor for this Custom Addon Class
]]
function RD.__Construct()
	return true, "No Implementation yet"
end


--[[
	Get the required Addons for this Addon Class
]]
function RD.GetRequiredAddons()
	return {"Resource Distribution"}
end

--[[
	Get the Version of this Custom Addon Class
]]
function RD.GetVersion()
	return 3.05, "Beta"
end

local isuptodatecheck

--[[
	Update check
]]
function RD.IsUpToDate(callBackfn)
	if not CAF.HasInternet then return end

	if isuptodatecheck ~= nil then
		callBackfn(isuptodatecheck)

		return
	end
end

--[[
	Gets a menu from this Custom Addon Class
]]
--Name is nil for main menu, String for others
function RD.GetMenu(menutype, menuname)
	local data = {}

	if not menutype then
		data.Info = {
			["Wiki Home"] = {
				localurl = "test/test.html",
				interneturl = "http://www.snakesvx.net/index.php/module_Wiki/title_Garrysmod_Info_Life_Support"
			},
			["Generators"] = {
				localurl = "test/test.html",
				interneturl = "http://www.snakesvx.net/index.php/module_Wiki/title_Garrysmod_Info_Life_Support_Generators"
			},
			["Storage Devices"] = {
				localurl = "test/test.html",
				interneturl = "http://www.snakesvx.net/index.php/module_Wiki/title_Garrysmod_Info_Life_Support_Storage_Devices"
			},
			["Special Devices"] = {
				localurl = "test/test.html",
				interneturl = "http://www.snakesvx.net/index.php/module_Wiki/title_Garrysmod_Info_Life_Support_Special_Devices"
			},
			["Environmental Controls"] = {
				localurl = "test/test.html",
				interneturl = "http://www.snakesvx.net/index.php/module_Wiki/title_Garrysmod_Info_Life_Support_Environment_Controls"
			}
		}

		data.Help = {
			["Wiki Home"] = {
				localurl = "test/test.html",
				interneturl = "http://www.snakesvx.net/index.php/module_Wiki/title_Garrysmod_Info_Life_Support"
			}
		}
	end

	return data
end

--[[
	Can the Status of the addon be changed?
]]
function RD.CanChangeStatus()
	return false
end

--[[
	Returns a table containing the Description of this addon
]]
function RD.GetDescription()
	return {"Life Support Entities", "", ""}
end

CAF.RegisterAddon("Life Support Entities", RD, "2")