﻿local gmod_version_required = 145

if VERSION < gmod_version_required then
	error("CAF: Your gmod is out of date: found version ", VERSION, "required ", gmod_version_required)
end

local net = net

local net_pools = {"CAF_Addon_Construct", "CAF_Start_true", "CAF_Start_false", "CAF_Addon_POPUP"}

for _, v in pairs(net_pools) do
	util.AddNetworkString(v)
end

-- Variable Declarations
local CAF2 = {}
CAF = CAF2
local CAF3 = {}
CAF2.CAF3 = CAF3
CAF2.StartingUp = false
local DEBUG = true
CAF3.DEBUG = DEBUG
local Addons = {}
CAF3.Addons = Addons
local addonlevel = {}
CAF3.addonlevel = addonlevel
addonlevel[1] = {}
addonlevel[2] = {}
addonlevel[3] = {}
addonlevel[4] = {}
addonlevel[5] = {}

function CAF2.AllowSpawn(type, sub_type, class, model)
	local res = hook.Call("CAFTOOLAllowEntitySpawn", type, sub_type, class, model)
	if res ~= nil then
		return res
	end
	return true
end

local function ErrorOffStuff(String)
	Msg("----------------------------------------------------------------------\n")
	Msg("-----------Custom Addon Management Framework Error----------\n")
	Msg("----------------------------------------------------------------------\n")
	Msg(tostring(String) .. "\n")
end

AddCSLuaFile("autorun/client/cl_caf_autostart.lua")
CAF2.CAF3 = CAF3
include("caf/core/shared/sh_general_caf.lua")
CAF2.CAF3 = nil

if not sql.TableExists("CAF_AddonStatus") then
	sql.Query("CREATE TABLE IF NOT EXISTS CAF_AddonStatus ( id VARCHAR(50) PRIMARY KEY , status TINYINT(1));")
end

--function Declarations
--Local functions
local function UpdateAddonStatus(addon, status)
	if not addon or not status then return false, "Missing parameter(s)" end
	local id = sql.SQLStr(addon)
	local stat = sql.SQLStr(status)
	sql.Query("UPDATE CAF_AddonStatus SET status=" .. stat .. " WHERE id=" .. id .. ";")
end

local function SaveAddonStatus(addon, status)
	if not addon or not status then return false, "Missing parameter(s)" end
	local id = sql.SQLStr(addon)
	local stat = sql.SQLStr(status)
	local data = sql.Query("INSERT INTO CAF_AddonStatus(id, status) VALUES(" .. id .. ", " .. stat .. ");")

	if data then
		MsgN("Error saving addon status " .. addon .. ":" .. status)
	end
end

local function LoadAddonStatus(addon, defaultstatus)
	if not addon then return false, "No Addon Given" end
	local id = sql.SQLStr(addon)
	local data = sql.Query("SELECT * FROM CAF_AddonStatus WHERE id = " .. id .. ";")

	if defaultstatus == nil then
		defaultstatus = 1
	else
		if defaultstatus then
			defaultstatus = 1
		else
			defaultstatus = 0
		end
	end

	if not data then
		SaveAddonStatus(addon, defaultstatus)
	else
		return tobool(data[1]["status"])
	end

	return tobool(defaultstatus)
end

local function OnEntitySpawn(ent, enttype, ply)
	if ent == NULL then return end
	ent.caf = ent.caf or {}
	ent.caf.custom = ent.caf.custom or {}

	if ent.caf.custom.canreceivedamage == nil then
		ent.caf.custom.canreceivedamage = true
	end

	if ent.caf.custom.canreceiveheatdamage == nil then
		ent.caf.custom.canreceiveheatdamage = true
	end

	hook.Call("CAFOnEntitySpawn", nil, ent, enttype, ply)
end

local function OnAddonConstruct(name)
	if not name then return end
	net.Start("CAF_Addon_Construct")
	net.WriteString(name)
	net.Broadcast()

	if not CAF2.StartingUp then
		hook.Call("CAFOnAddonConstruct", name)
	end
end

--Gmod Spawn Hooks
local function SpawnedSent(ply, ent)
	--Msg("Sent Spawned\n")
	OnEntitySpawn(ent, "SENT", ply)
end

local function SpawnedVehicle(ply, ent)
	--Msg("Vehicle Spawned\n")
	OnEntitySpawn(ent, "VEHICLE", ply)
end

local function SpawnedEnt(ply, model, ent)
	--Msg("Prop Spawned\n")
	OnEntitySpawn(ent, "PROP", ply)
end

local function PlayerSpawn(ply)
	--Msg("Prop Spawned\n")
	OnEntitySpawn(ply, "PLAYER", ply)
end

local function NPCSpawn(ply, ent)
	--Msg("Prop Spawned\n")
	OnEntitySpawn(ent, "NPC", ply)
end

hook.Add("PlayerSpawnedNPC", "CAF NPC Spawn", NPCSpawn)
hook.Add("PlayerInitialSpawn", "CAF PLAYER Spawn", PlayerSpawn)
hook.Add("PlayerSpawnedProp", "CAF PROP Spawn", SpawnedEnt)
hook.Add("PlayerSpawnedSENT", "CAF SENT Spawn", SpawnedSent)
hook.Add("PlayerSpawnedVehicle", "CAF VEHICLE Spawn", SpawnedVehicle)

--Global function
--[[

]]
--[[
	WriteToDebugFile
	This function will write the selected message to 
		1) the console
		2) the specified file into the CAF_DEBUG/Server/ folder
			If the file doesn't exist it will be created
]]
function CAF2.WriteToDebugFile(filename, message)
	if not filename or not message then return nil, "Missing Argument" end

	print("Filename: " .. tostring(filename) .. ", Message: " .. tostring(message))
end

--[[
	ClearDebugFile
		This function will clear the given file in the debug folder
		It will return the content that was in the file before it got cleared
]]
function CAF2.ClearDebugFile(filename)
	if not filename then return nil, "Missing Argument" end
	local contents = file.Read("CAF_Debug/server/" .. filename .. ".txt")
	contents = contents or ""
	file.Write("CAF_Debug/server/" .. filename .. ".txt", "")
end

--[[
	GetSavedAddonStatus
		This function will return the the status that was stored in the SQL file last time to make it easier so admins won't need to disable Addons again every time.
]]
function CAF2.GetSavedAddonStatus(addon, defaultstatus)
	return LoadAddonStatus(addon, defaultstatus)
end

--[[
	Start
		This function loads all the Custom Addons on Startup
]]
function CAF2.Start()
	Msg("Starting CAF Addons\n")
	CAF2.StartingUp = true
	net.Start("CAF_Start_true")
	net.Broadcast()

	for level, tab in pairs(addonlevel) do
		print("Loading Level " .. tostring(level) .. " Addons\n")

		for k, v in pairs(tab) do
			if not Addons[v] then
				continue
			end
			print("-->", "Loading addon " .. tostring(v) .. "\n")

			if Addons[v].AddResourcesToSend then
				local ok, err = pcall(Addons[v].AddResourcesToSend)

				if not ok then
					CAF2.WriteToDebugFile("CAF_ResourceSend", "AddResourcesToSend Error: " .. err .. "\n")
				end
			end

			local ok = true

			if Addons[v].GetRequiredAddons and Addons[v].GetRequiredAddons() then
				for l, w in pairs(Addons[v].GetRequiredAddons()) do
					if Addons[w] then
						continue
					end
					ok = false
				end
			end
			if not ok then
				continue
			end

			local state = CAF2.GetSavedAddonStatus(v, Addons[v].DEFAULTSTATUS)

			if Addons[v].__AutoStart then
				local ok2, err = pcall(Addons[v].__AutoStart, state)

				if not ok2 then
					CAF2.WriteToDebugFile("CAF_AutoStart", "Couldn't call AutoStart for " .. v .. ": " .. err .. "\n")
				else
					OnAddonConstruct(v)
					print("-->", "Auto Started Addon: " .. v .. "\n")
				end
			elseif state then
				local ok2, err = pcall(Addons[v].__Construct)

				if not ok2 then
					CAF2.WriteToDebugFile("CAF_Construct", "Couldn't call constructor for " .. v .. ": " .. err .. "\n")
				else
					OnAddonConstruct(v)
					print("-->", "Loaded addon: " .. v .. "\n")
				end
			end
		end
	end

	CAF2.StartingUp = false
	net.Start("CAF_Start_false")
	net.Broadcast()
end

hook.Add("InitPostEntity", "CAF_Start", CAF2.Start)

--[[
	This function will call the construct function of an addon  and return if it's was succesfull or not (+ the errormessage)
]]
function CAF2.Construct(addon)
	if not addon then return end
	if not Addons[addon] then return end
	local ok, mes = Addons[addon].__Construct()

	if ok then
		OnAddonConstruct(addon)
		UpdateAddonStatus(addon, 1)
	end

	return ok, mes
end

--[[
	This function will receive the construct info from the clientside VGUI menu
]]
local function AddonConstruct(ply, com, args)
	if not ply:IsAdmin() then
		ply:ChatPrint("You are not allowed to Construct a Custom Addon")

		return
	end

	if not args then
		ply:ChatPrint("You forgot to provide arguments")

		return
	end

	if not args[1] then
		ply:ChatPrint("You forgot to enter the Addon Name")

		return
	end

	--Construct the Addon name if it had spaces in it
	if table.Count(args) > 1 then
		for k, v in pairs(args) do
			if k ~= 1 then
				args[1] = args[1] .. " " .. v
			end
		end
	end

	local ok, mes = CAF2.Construct(args[1])

	if ok then
		ply:ChatPrint("Addon Succesfully Enabled")
	else
		ply:ChatPrint("Couldn't Enable the Addon for the following reason: " .. tostring(mes))
	end
end

concommand.Add("CAF_Addon_Construct", AddonConstruct)

--[[
	This function will update the Client with all active addons
]]
function CAF2.PlayerSpawn(ply)
	for k, v in pairs(Addons) do
		net.Start("CAF_Addon_Construct")
		net.WriteString(k)
		net.Send(ply)
	end
end

hook.Add("PlayerFullLoad", "CAF_In_Spawn", CAF2.PlayerSpawn)
local oldcreate = ents.Create

ents.Create = function(class)
	local ent = oldcreate(class)

	timer.Simple(0.1, function()
		OnEntitySpawn(ent, "SENT")
	end)

	return ent
end

--msg, location, color, displaytime
function CAF2.POPUP(ply, msg, location, color, displaytime)
	if msg then
		location = location or "top"
		color = color or CAF2.colors.white
		displaytime = displaytime or 1
		net.Start("CAF_Addon_POPUP")
		net.WriteString(msg)
		net.WriteString(location)
		net.WriteUInt(color.r, 8)
		net.WriteUInt(color.g, 8)
		net.WriteUInt(color.b, 8)
		net.WriteUInt(color.a, 8)
		net.WriteUInt(displaytime, 16)
		net.Send(ply)
	end
end

CAF = CAF2
--[[
	The following code sends the clientside and shared files to the client and includes CAF core code
]]
--Send Client and Shared files to the client and Include the ServerAddons
--Core files

for k, File in ipairs(file.Find("caf/core/server/*.lua", "LUA")) do
	local ErrorCheck, PCallError = pcall(include, "caf/core/server/" .. File)

	if not ErrorCheck then
		ErrorOffStuff(PCallError)
	end
end

for k, File in ipairs(file.Find("CAF/Core/client/*.lua", "LUA")) do
	local ErrorCheck, PCallError = pcall(AddCSLuaFile, "caf/core/client/" .. File)

	if not ErrorCheck then
		ErrorOffStuff(PCallError)
	end
end

for k, File in ipairs(file.Find("CAF/Core/shared/*.lua", "LUA")) do
	local ErrorCheck, PCallError = pcall(AddCSLuaFile, "caf/core/shared/" .. File)

	if not ErrorCheck then
		ErrorOffStuff(PCallError)
	end
end

for k, File in ipairs(file.Find("caf/languagevars/*.lua", "LUA")) do
	local ErrorCheck, PCallError = pcall(AddCSLuaFile, "caf/languagevars/" .. File)

	if not ErrorCheck then
		ErrorOffStuff(PCallError)
	end

	local ErrorCheck2, PCallError2 = pcall(include, "caf/languagevars/" .. File)

	if not ErrorCheck2 then
		ErrorOffStuff(PCallError2)
	end
end


--Main Addon
for k, File in ipairs(file.Find("caf/addons/server/*.lua", "LUA")) do
	local ErrorCheck, PCallError = pcall(include, "caf/addons/server/" .. File)

	if not ErrorCheck then
		ErrorOffStuff(PCallError)
	end
end

for k, File in ipairs(file.Find("caf/addons/client/*.lua", "LUA")) do
	local ErrorCheck, PCallError = pcall(AddCSLuaFile, "caf/addons/client/" .. File)

	if not ErrorCheck then
		ErrorOffStuff(PCallError)
	end
end

for k, File in ipairs(file.Find("caf/addons/shared/*.lua", "LUA")) do
	local ErrorCheck, PCallError = pcall(AddCSLuaFile, "caf/addons/shared/" .. File)

	if not ErrorCheck then
		ErrorOffStuff(PCallError)
	end
end

net.Receive("CAF_PlayerFullLoad", function(_, ply)
	if ply.PlayerFullLoaded then
		return
	end
	ply.PlayerFullLoaded = true
	hook.Run("PlayerFullLoad", ply)
end)
util.AddNetworkString("CAF_PlayerFullLoad")
