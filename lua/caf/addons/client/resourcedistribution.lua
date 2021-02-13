﻿local RD = {}
--local ent_table = {};

local rd_cache = cache.create(1, false) --Store data for 1 second
--[[

]]
--local functions

_G.RD = RD
include("caf/addons/shared/resourcedistribution.lua")
_G.RD = nil

RD_OverLay_Distance = CreateClientConVar("rd_overlay_distance", "512", false, false)
RD_OverLay_Mode = CreateClientConVar("rd_overlay_mode", "-1", false, false)
local client_chosen_number = CreateClientConVar("number_to_send", "1", false, false)
local client_chosen_hold = CreateClientConVar("number_to_hold", "0", false, false)

local REQUEST_ENT = 1
local REQUEST_NET = 2

----------NetTable functions

local function ClearNets()
	rd_cache:clear()
end

net.Receive("RD_ClearNets", ClearNets)

local function ReadBool()
	return net.ReadBit() == 1
end

local function ReadShort()
	return net.ReadInt(16)
end

local function ReadLong()
	return net.ReadInt(32)
end

local function ReadResource()
	local id = net.ReadUInt(8)
	if id == 0 then
		return net.ReadString()
	end
	return RD.GetResourceNameByID(id)
end

local dev = GetConVar("developer")

local function AddEntityToCache(nrofbytes)
	if dev:GetBool() then
		print("RD_Entity_Data #", nrofbytes, " bytes received")
	end

	local data = {}
	data.entid = ReadShort() --Key
	local up_to_date = ReadBool()

	if up_to_date then
		rd_cache:update("entity_" .. tostring(data.entid))
	end

	data.network = ReadShort() --network key
	data.resources = {}
	local nr_of_resources = ReadShort()

	if nr_of_resources > 0 then
		--print("nr_of_sources", nr_of_resources)
		local resource
		local maxvalue
		local value
		local temperature

		for i = 1, nr_of_resources do
			--print(i)
			resource = ReadResource()
			maxvalue = ReadLong()
			value = ReadLong()
			temperature = net.ReadFloat()

			if not resource then
				continue
			end

			data.resources[resource] = {
				value = value,
				maxvalue = maxvalue,
				temperature = temperature
			}
		end
	end

	rd_cache:add("entity_" .. tostring(data.entid), data)
end

net.Receive("RD_Entity_Data", AddEntityToCache)

local function AddNetworkToCache(nrofbytes)
	if dev:GetBool() then
		print("RD_Network_Data #", nrofbytes, " bytes received")
	end

	local data = {}
	data.netid = ReadShort() --network key
	local up_to_date = ReadBool()

	if up_to_date then
		rd_cache:update("network_" .. tostring(data.netid))
		return
	end

	data.resources = {}
	local nr_of_resources = ReadShort()

	if nr_of_resources > 0 then
		--print("nr_of_sources", nr_of_resources)
		local resource
		local maxvalue
		local value
		local temperature

		for _ = 1, nr_of_resources do
			--print(i)
			resource = ReadResource()
			maxvalue = ReadLong()
			value = ReadLong()
			temperature = net.ReadFloat()

			data.resources[resource] = {
				value = value,
				maxvalue = maxvalue,
				temperature = temperature,
			}
		end
	end

	data.cons = {}
	local nr_of_cons = ReadShort()

	if nr_of_cons > 0 then
		--print("nr_of_cons", nr_of_cons)
		for i = 1, nr_of_cons do
			--print(i)
			local con = ReadShort()
			table.insert(data.cons, con)
		end
	end

	rd_cache:add("network_" .. tostring(data.netid), data)
end

net.Receive("RD_Network_Data", AddNetworkToCache)

--end local functions
--The Class
--[[
	The Constructor for this Custom Addon Class
]]
function RD.__Construct()
	RD:__AddResources()

	return true
end

--[[
	Get the required Addons for this Addon Class
]]
function RD.GetRequiredAddons()
	return {}
end

--[[
	Get the Version of this Custom Addon Class
]]
function RD.GetVersion()
	return 3.1, "Alpha"
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

	return data
end

--[[
	Returns a table containing the Description of this addon
]]
function RD.GetDescription()
	return {"Resource Distribution", "", ""}
end

CAF.RegisterAddon("Resource Distribution", RD, "1")

function RD.GetNetResourceAmount(netid, resource)
	if not resource then return 0, "No resource given" end
	local data = RD.GetNetTable(netid)
	if not data then return 0, "Not a valid network" end
	if not data.resources or not data.resources[resource] then return 0, "No resources available" end
	return data.resources[resource].value
end

function RD.GetResourceAmount(ent, resource)
	if not IsValid(ent) then return 0, "Not a valid entity" end
	if not resource then return 0, "No resource given" end
	local data = RD.GetEntityTable(ent)
	if not data.resources or not data.resources[resource] then return 0, "No resources available" end
	return data.resources[resource].value
end

--[[function RD.GetUnitCapacity(ent, resource)
	if not IsValid( ent ) then return 0, "Not a valid entity" end
	if not resource then return 0, "No resource given" end
	local amount = 0
	if ent_table[ent:EntIndex( )] then
		local index = ent_table[ent:EntIndex( )];
		if index.resources[resource] then
			amount = index.resources[resource].maxvalue
		end
	end
	return amount
end]]
function RD.GetNetNetworkCapacity(netid, resource)
	if not resource then return 0, "No resource given" end
	local data = RD.GetNetTable(netid)
	if not data then return 0, "Not a valid network" end
	if not data.resources or not data.resources[resource] then return 0, "No resources available" end
	return data.resources[resource].maxvalue
end

function RD.GetNetworkCapacity(ent, resource)
	if not IsValid(ent) then return 0, "Not a valid entity" end
	if not resource then return 0, "No resource given" end
	local data = RD.GetEntityTable(ent)
	if not data then return 0, "Not a valid network" end
	if not data.resources or not data.resources[resource] then return 0, "No resources available" end
	return data.resources[resource].maxvalue
end

local requests = {}
local ttl = 0.2 --Wait 0.2 second before doing a new request

function RD.GetEntityTable(ent)
	if not IsValid(ent) then
		return {}
	end

	local entid = ent:EntIndex()
	local id = "entity_" .. tostring(entid)
	local data, needs_update = rd_cache:get(id)

	if not data or needs_update and not requests[id] or requests[id] < CurTime() then
		--Do (new) request
		requests[id] = CurTime() + ttl
		net.Start("RD_Network_Data")
			net.WriteUInt(REQUEST_ENT, 8)
			net.WriteUInt(entid, 32)
			net.WriteBool(needs_update)
		net.SendToServer()
	end
	--PrintTable(data)

	return data or {}
end

function RD.GetNetTable(netid)
	if not netid then
		return {}
	end

	local id = "network_" .. tostring(netid)
	local data, needs_update = rd_cache:get(id)

	if not data or needs_update and not requests[id] or requests[id] < CurTime() then
		--Do (new) request
		requests[id] = CurTime() + ttl
		net.Start("RD_Network_Data")
			net.WriteUInt(REQUEST_NET, 8)
			net.WriteUInt(netid, 32)
			net.WriteBool(needs_update)
		net.SendToServer()
	end

	return data or {}
end

--TODO UPDATE TO HERE

function RD.PrintDebug(ent)
	if ent then
		if ent.IsNode then
			PrintTable(RD.GetNetTable(ent.netid))
		else -- --
			local enttable = RD.GetEntityTable(ent)
			PrintTable(enttable)
		end
	end
end

list.Add("BeamMaterials", "cable/rope_icon")
list.Add("BeamMaterials", "cable/cable2")
list.Add("BeamMaterials", "cable/xbeam")
list.Add("BeamMaterials", "cable/redlaser")
list.Add("BeamMaterials", "cable/blue_elec")
list.Add("BeamMaterials", "cable/physbeam")
list.Add("BeamMaterials", "cable/hydra")
--holds the materials
local beamMat = {}

for _, mat in pairs(list.Get("BeamMaterials")) do
	beamMat[mat] = Material(mat)
end

-----------------------------------------
--START BEAMS BY MADDOG
-----------------------------------------
local xbeam = Material("cable/xbeam")

-- Desc: draws beams on ents
function RD.Beam_Render(ent)
	--get the number of beams to use
	local intBeams = ent:GetNWInt("Beams")

	--if we have beams, then create them
	if intBeams and intBeams ~= 0 then
		--make some vars we are about to use
		local start, scroll = ent:GetNWVector("Beam1"), CurTime() * 0.5
		--get beam info and explode into a table
		local beamInfo = string.Explode(";", ent:GetNWString("BeamInfo"))
		--get beam info from table (1: beamMaterial 2: beamSize 3: beamR 4: beamG 5: beamB 6: beamAlpha)
		local beamMaterial, beamSize, color = (beamMat[beamInfo[1]] or xbeam), (beamInfo[2] or 2), Color(beamInfo[3] or 255, beamInfo[4] or 255, beamInfo[5] or 255, beamInfo[6] or 255)
		-- set material
		render.SetMaterial(beamMaterial)
		render.StartBeam(intBeams) --how many links (points) the beam has

		--loop through all beams
		for i = 1, intBeams do
			--get beam data
			local beam, subent = ent:GetNWVector("Beam" .. tostring(i)), ent:GetNWEntity("BeamEnt" .. tostring(i))

			--if no beam break for statement
			if not beam or not subent or not subent:IsValid() then
				ent:SetNWInt("Beams", 0)
				break
			end

			--get beam world vector
			local pos = subent:LocalToWorld(beam)
			--update scroll
			scroll = scroll - (pos - start):Length() / 10
			-- add point
			render.AddBeam(pos, beamSize, scroll, color)
			--reset start postion
			start = pos
		end

		--beam done
		render.EndBeam()
	end
end

-----------------------------------------
--END BEAMS BY MADDOG
-----------------------------------------
--Alternate Use Code--
local function GenUseMenu(ent)
	local SmallFrame = vgui.Create("DFrame")
	SmallFrame:SetPos((ScrW() / 2) - 110, (ScrH() / 2) - 100)
	SmallFrame:SetSize(220, (#ent.Inputs * 40) + 90)
	SmallFrame:SetTitle(ent.PrintName)
	local ypos = 30
	local HoldSlider = vgui.Create("DNumSlider", SmallFrame)
	HoldSlider:SetPos(10, ypos)
	HoldSlider:SetSize(200, 30)
	HoldSlider:SetText("Time to Hold:")
	HoldSlider:SetMin(0)
	HoldSlider:SetMax(10)
	HoldSlider:SetDecimals(1)
	HoldSlider:SetConVar("number_to_hold")
	ypos = ypos + 40

	for k, v in pairs(ent.Inputs) do
		local NumSliderThingy = vgui.Create("DNumSlider", SmallFrame)
		NumSliderThingy:SetPos(10, ypos)
		NumSliderThingy:SetSize(120, 30)
		NumSliderThingy:SetText(v .. " :")
		NumSliderThingy:SetMin(0)
		NumSliderThingy:SetMax(10)
		NumSliderThingy:SetDecimals(0)
		NumSliderThingy:SetConVar("number_to_send")
		local SendButton = vgui.Create("DButton", SmallFrame)
		SendButton:SetPos(140, ypos)
		SendButton:SetText("Send Command")
		SendButton:SizeToContents()

		SendButton.DoClick = function()
			RunConsoleCommand("send_input_selection_to_server", ent:EntIndex(), v, client_chosen_number:GetInt(), client_chosen_hold:GetFloat())
		end

		ypos = ypos + 40
	end

	SmallFrame:MakePopup()
end

local function RecieveInputs()
	local last = net.ReadBool()
	local input = net.ReadString()
	local ent = net.ReadEntity()

	if not ent.Inputs then
		ent.Inputs = {}
	end

	if not table.HasValue(ent.Inputs, input) then
		table.insert(ent.Inputs, input)
	end

	if last and last == true then
		GenUseMenu(ent)
	end
end

net.Receive("RD_AddInputToMenu", RecieveInputs)