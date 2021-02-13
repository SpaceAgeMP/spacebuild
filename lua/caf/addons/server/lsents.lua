local RD = {}

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

function RD.AddResourcesToSend()
end

CAF.RegisterAddon("Life Support Entities", RD, "2")