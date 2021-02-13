local CAF2 = CAF
local CAF3 = CAF2.CAF3
local Addons = CAF3.Addons
local addonlevel = CAF3.addonlevel

function CAF2.begintime()
	return os.clock()
end

function CAF2.endtime(begintime)
	return CAF2.begintime() - begintime
end

CAF2.version = 0.5
--COLOR Settings
CAF2.colors = {}
CAF2.colors.red = Color(230, 0, 0, 230)
CAF2.colors.green = Color(0, 230, 0, 230)
CAF2.colors.white = Color(255, 255, 255, 255)

--END COLOR Settings
-- CAF Custom Status Saving
if not sql.TableExists("CAF_Custom_Vars") then
	sql.Query("CREATE TABLE IF NOT EXISTS CAF_Custom_Vars ( varname VARCHAR(255) , varvalue VARCHAR(255));")
end

local vars = {}

local function InsertVar(name, value)
	if not name or not value then return false, "Problem with the Parameters" end
	name = sql.SQLStr(name)
	value = sql.SQLStr(value)
	sql.Query("INSERT INTO CAF_Custom_Vars(varname, varvalue) VALUES(" .. name .. ", " .. value .. ");")
end

function CAF2.SaveVar(name, value)
	if not name or not value then return false, "Problem with the Parameters" end
	CAF2.LoadVar(name, value)
	name = sql.SQLStr(name)
	value = sql.SQLStr(value)
	sql.Query("UPDATE CAF_Custom_Vars SET varvalue=" .. value .. " WHERE varname=" .. name .. ";")
	vars[name] = value
end

function CAF2.LoadVar(name, defaultvalue)
	if not defaultvalue then
		defaultvalue = "0"
	end

	if not name then return false, "Problem with the Parameters" end
	if vars[name] then return vars[name] end
	local data = sql.Query("SELECT * FROM CAF_Custom_Vars WHERE varname = '" .. name .. "';")

	if not data then
		print(sql.LastError())
		InsertVar(name, defaultvalue)
	else
		defaultvalue = string.TrimRight(data[1]["varvalue"])
	end

	Msg("-" .. tostring(defaultvalue) .. "-\n")
	vars[name] = defaultvalue

	return defaultvalue
end

--[[
	Returns the reference to the Custom Addon, nil if not existant
]]
function CAF2.GetAddon(AddonName)
	if not AddonName then return nil, "No AddonName given" end

	return Addons[AddonName]
end

--[[
	Registers an addon with the game name into the table
	Overwrites if 2 addons use the same name
]]
function CAF2.RegisterAddon(AddonName, AddonClass, level)
	if not AddonName then return nil, "No AddonName given" end
	if not AddonClass then return nil, "No AddonClass given" end

	if not level then
		level = 5
	end

	level = tonumber(level)

	if level < 1 then
		level = 1
	elseif level > 5 then
		level = 5
	end

	Addons[AddonName] = AddonClass
	table.insert(addonlevel[level], AddonName)

	return true
end

function CAF2.GetLangVar(name)
	return CAF2.LANGUAGE[name] or name
end