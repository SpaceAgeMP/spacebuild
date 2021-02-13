﻿--[[ Serverside Custom Addon file Base ]]
--
--require("sb_space")
player_manager.AddValidModel("MedicMarine", "models/player/samzanemesis/MarineMedic.mdl")
player_manager.AddValidModel("SpecialMarine", "models/player/samzanemesis/MarineSpecial.mdl")
player_manager.AddValidModel("OfficerMarine", "models/player/samzanemesis/MarineOfficer.mdl")
player_manager.AddValidModel("TechMarine", "models/player/samzanemesis/MarineTech.mdl")
util.PrecacheModel("models/player/samzanemesis/MarineMedic.mdl")
util.PrecacheModel("models/player/samzanemesis/MarineSpecial.mdl")
util.PrecacheModel("models/player/samzanemesis/MarineOfficer.mdl")
util.PrecacheModel("models/player/samzanemesis/MarineTech.mdl")
local SB = {}
--local NextUpdateTime
local SB_InSpace = 0
--SetGlobalInt("InSpace", 0)
TrueSun = {}
SunAngle = nil
SB.Override_PlayerHeatDestroy = 0
SB.Override_EntityHeatDestroy = 0
SB.Override_PressureDamage = 0
SB.PlayerOverride = 0
local sb_spawned_entities = {}
local volumes = {}
CreateConVar("SB_NoClip", "1")
CreateConVar("SB_PlanetNoClipOnly", "1")
CreateConVar("SB_AdminSpaceNoclip", "1")
CreateConVar("SB_SuperAdminSpaceNoclip", "1")

local ForceModel = CreateConVar("SB_Force_Model", "0", {FCVAR_ARCHIVE})

--Think + Environments
local Environments = {}
local Planets = {}
local Stars = {}
local numenv = 0

local MapEntities = {"base_sb_planet1", "base_sb_planet2", "base_sb_star1", "base_sb_star2", "nature_dev_tree", "sb_environment", "base_cube_environment"}

local function PhysgunPickup(ply, ent)
	local notallowed = MapEntities
	if table.HasValue(notallowed, ent:GetClass()) then return false end
end

hook.Add("PhysgunPickup", "SB_PhysgunPickup_Check", PhysgunPickup)
--Don't remove environment on cleanup
local originalCleanUpMap = game.CleanUpMap

function game.CleanUpMap(dontSendToClients, ExtraFilters)
	if ExtraFilters then
		table.Add(ExtraFilters, MapEntities)
	else
		ExtraFilters = MapEntities
	end

	originalCleanUpMap(dontSendToClients, ExtraFilters)
end

local function OnEntitySpawn(ent)
	--Msg("Spawn: "..tostring(ent).."\n")
	if not table.HasValue(sb_spawned_entities, ent) then
		table.insert(sb_spawned_entities, ent)
	end
end

hook.Add("CAFOnEntitySpawn", "SB_OnEntitySpawn", OnEntitySpawn)

local function PlayerNoClip(ply, on)
	if SB_InSpace == 1 and not ply.EnableSpaceNoclip and ply.environment and ply.environment:IsSpace() then
		return false
	end
end

--Send the player info about the Stars and Planets for Effects
local function PlayerInitialSpawn(ply)
	if Planets then
		for k, v in pairs(Planets) do
			if IsValid(v) then
				v:SendData(ply)
			end
		end
	end

	if Stars then
		for k, v in pairs(Stars) do
			if IsValid(v) then
				v:SendSunBeam(ply)
			end
		end
	end
end

local function Register_Sun()
	Msg("Registering Sun\n")
	local suns = ents.FindByClass("env_sun")

	for _, ent in ipairs(suns) do
		if ent:IsValid() then
			local values = ent:GetKeyValues()

			for key, value in pairs(values) do
				if (key == "target") and (string.len(value) > 0) then
					local targets = ents.FindByName("sun_target")

					for _, target in pairs(targets) do
						SunAngle = (target:GetPos() - ent:GetPos()):Normalize()
						--Sunangle set, all that was needed

						return
					end
				end
			end

			--Sun angle still not set, but sun found
			local ang = ent:GetAngles()
			ang.p = ang.p - 180
			ang.y = ang.y - 180
			--get within acceptable angle values no matter what...
			ang.p = math.NormalizeAngle(ang.p)
			ang.y = math.NormalizeAngle(ang.y)
			ang.r = math.NormalizeAngle(ang.r)
			SunAngle = ang:Forward()

			return
		end
	end

	--no sun found, so just set a default angle
	if not SunAngle then
		SunAngle = Vector(0, 0, -1)
	end
end

local sb_space = {}

function sb_space.Get()
	if sb_space.instance then return sb_space.instance end
	local space = {}

	function space:CheckAirValues()
		-- Do nothing
	end

	function space:IsOnPlanet()
		return nil
	end

	function space:AddExtraAirResource(resource, start, ispercentage)
		-- Do nothing
	end

	function space:PrintVars()
		Msg("No Values for Space\n")
	end

	function space:Convert(res1, res2, amount)
		return 0
	end

	function space:GetEnvironmentName()
		return "Space"
	end

	function space:GetResourceAmount(res)
		return 0
	end

	function space:GetResourcePercentage(res)
		return 0
	end

	function space:SetEnvironmentName(value)
		--not implemented
	end

	function space:Convert(air1, air2, value)
		return 0
	end

	function space:GetSize()
		return 0
	end

	function space:SetSize(size)
		--not implemented
	end

	function space:GetSBGravity()
		return 0
	end

	function space:UpdatePressure(ent)
		-- not implemented
	end

	function space:GetO2Percentage()
		return 0
	end

	function space:GetCO2Percentage()
		return 0
	end

	function space:GetNPercentage()
		return 0
	end

	function space:GetHPercentage()
		return 0
	end

	function space:GetEmptyAirPercentage()
		return 0
	end

	function space:UpdateGravity(ent)
		if not ent then return end
		if ent.gravity and ent.gravity == 0 then return end
		ent.gravity = 0

		local phys = ent:GetPhysicsObject()
		if not phys:IsValid() then return end

		phys:EnableGravity(false)
		phys:EnableDrag(false)
		ent:SetGravity(0.00001)
	end

	function space:GetPriority()
		return 0
	end

	function space:GetAtmosphere()
		return 0
	end

	function space:GetPressure()
		return 0
	end

	function space:GetTemperature()
		return 14
	end

	function space:GetEmptyAir()
		return 0
	end

	function space:GetO2()
		return 0
	end

	function space:GetCO2()
		return 0
	end

	function space:GetN()
		return 0
	end

	function space:CreateEnvironment(gravity, atmosphere, pressure, temperature, o2, co2, n)
		--Not implemented
	end

	function space:UpdateSize(oldsize, newsize)
		--not implemented
	end

	function space:UpdateEnvironment(gravity, atmosphere, pressure, temperature, o2, co2, n)
		--not implemented
	end

	function space:GetVolume()
		return 0
	end

	function space:IsPlanet()
		return false
	end

	function space:IsStar()
		return false
	end

	function space:IsSpace()
		return true
	end

	sb_space.instance = space

	return space
end

local function Register_Environments()
	local CONFIGS = {}
	Msg("Registering planets\n")
	local Blooms = {}
	local Colors = {}
	local Planetscolor = {}
	local Planetsbloom = {}
	--Load the planets/stars/bloom/color
	local entities = ents.FindByClass("logic_case")
	local case1, case2, case3, case4, case5, case6, case7, case8, case9, case10, case11, case12, case13, case14, case15, case16, hash, angles, pos

	for _, ent in ipairs(entities) do
		case1, case2, case3, case4, case5, case6, case7, case8, case9, case10, case11, case12, case13, case14, case15, case16, hash = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
		local values = ent:GetKeyValues()

		for key, value in pairs(values) do
			if key == "Case01" then
				case1 = value
			elseif key == "Case02" then
				case2 = value
			elseif key == "Case03" then
				case3 = value
			elseif key == "Case04" then
				case4 = value
			elseif key == "Case05" then
				case5 = value
			elseif key == "Case06" then
				case6 = value
			elseif key == "Case07" then
				case7 = value
			elseif key == "Case08" then
				case8 = value
			elseif key == "Case09" then
				case9 = value
			elseif key == "Case10" then
				case10 = value
			elseif key == "Case11" then
				case11 = value
			elseif key == "Case12" then
				case12 = value
			elseif key == "Case13" then
				case13 = value
			elseif key == "Case14" then
				case14 = value
			elseif key == "Case15" then
				case15 = value
			elseif key == "Case16" then
				case16 = value
			end
		end

		table.insert(CONFIGS, {case1, case2, case3, case4, case5, case6, case7, case8, case9, case10, case11, case12, case13, case14, case15, case16, ent:GetAngles(), ent:GetPos()})
	end

	timer.Simple(1, function()
		for _, c in ipairs(CONFIGS) do
			case1, case2, case3, case4, case5, case6, case7, case8, case9, case10, case11, case12, case13, case14, case15, case16, hash, angles, pos = c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12], c[13], c[14], c[15], c[16], nil, c[17], c[18]

			if case1 == "planet" then
				SB_InSpace = 1

				--SetGlobalInt("InSpace", 1)
				if not table.HasValue(TrueSun, pos) then
					case2 = tonumber(case2) --radius
					case3 = tonumber(case3) -- gravity
					case4 = tonumber(case4) -- atmosphere
					case5 = tonumber(case5) -- stemperature
					case6 = tonumber(case6) -- ltemperature

					if string.len(case7) == 0 then
						case7 = nil -- COLORID
					end

					if string.len(case8) == 0 then
						case8 = nil -- BloomID
					end

					case15 = tonumber(case15) --disabled
					case16 = tonumber(case16) -- flags

					if case15 ~= 1 then
						local planet = ents.Create("base_sb_planet1")
						planet:SetModel("models/props_lab/huladoll.mdl")
						planet:SetAngles(angles)
						planet:SetPos(pos)
						planet:Spawn()
						planet:CreateEnvironment(case2, case3, case4, case5, case6, case16)

						if case7 then
							Planetscolor[case7] = planet
						end

						if case8 then
							Planetsbloom[case8] = planet
						end

						print(planet)
						table.insert(Planets, planet)
						print("Registered new SB2 planet", planet, planet:GetEnvironmentName())
					end
				end
			elseif case1 == "planet2" then
				SB_InSpace = 1

				--SetGlobalInt("InSpace", 1)
				if  not table.HasValue(TrueSun, pos) then
					case2 = tonumber(case2) -- radius
					case3 = tonumber(case3) -- gravity
					case4 = tonumber(case4) -- atmosphere
					case5 = tonumber(case5) -- pressure
					case6 = tonumber(case6) -- stemperature
					case7 = tonumber(case7) -- ltemperature
					case8 = tonumber(case8) -- flags
					case9 = tonumber(case9) -- o2
					case10 = tonumber(case10) -- co2
					case11 = tonumber(case11) -- n
					case12 = tonumber(case12) -- h
					case13 = tostring(case13) --name

					if string.len(case15) == 0 then
						case15 = nil -- COLORID
					end

					if string.len(case16) == 0 then
						case16 = nil -- BloomID
					end

					local planet = ents.Create("base_sb_planet2")
					planet:SetModel("models/props_lab/huladoll.mdl")
					planet:SetAngles(angles)
					planet:SetPos(pos)
					planet:Spawn()

					if case13 == "" then
						case13 = "Planet " .. tostring(planet:GetEnvironmentID())
					end

					planet:CreateEnvironment(case2, case3, case4, case5, case6, case7, case9, case10, case11, case12, case8, case13)

					if case15 then
						Planetscolor[case15] = planet
					end

					if case16 then
						Planetsbloom[case16] = planet
					end

					table.insert(Planets, planet)
					print("Registered new SB3 planet", planet, planet:GetEnvironmentName())
				end
			elseif case1 == "cube" then
				SB_InSpace = 1

				--SetGlobalInt("InSpace", 1)
				if table.HasValue(TrueSun, pos) then
					case2 = tonumber(case2) -- radius
					case3 = tonumber(case3) -- gravity
					case4 = tonumber(case4) -- atmosphere
					case5 = tonumber(case5) -- pressure
					case6 = tonumber(case6) -- stemperature
					case7 = tonumber(case7) -- ltemperature
					case8 = tonumber(case8) -- flags
					case9 = tonumber(case9) -- o2
					case10 = tonumber(case10) -- co2
					case11 = tonumber(case11) -- n
					case12 = tonumber(case12) -- h
					case13 = tostring(case13) --name

					if string.len(case15) == 0 then
						case15 = nil -- COLORID
					end

					if string.len(case16) == 0 then
						case16 = nil -- BloomID
					end

					local planet = ents.Create("base_cube_environment")
					planet:SetModel("models/props_lab/huladoll.mdl")
					planet:SetAngles(angles)
					planet:SetPos(pos)
					planet:Spawn()

					if case13 == "" then
						case13 = "Cube Environment " .. tostring(planet:GetEnvironmentID())
					end

					planet:CreateEnvironment(case2, case3, case4, case5, case6, case7, case9, case10, case11, case12, case8, case13)

					if case15 then
						Planetscolor[case15] = planet
					end

					if case16 then
						Planetsbloom[case16] = planet
					end

					table.insert(Planets, planet)
					print("Registered new cube planet", planet, planet:GetEnvironmentName())
				end
			elseif case1 == "sb_dev_tree" then
				local tree = ents.Create("nature_dev_tree")
				tree:SetRate(tonumber(case2), true)
				tree:SetAngles(angles)
				tree:SetPos(pos)
				tree:Spawn()
				print("Registered new SB tree", tree)
			elseif case1 == "planet_color" then
				hash = {}

				if string.len(case2) > 0 then
					hash.AddColor_r = tonumber(string.Left(case2, string.find(case2, " ") - 1))
					case2 = string.Right(case2, string.len(case2) - string.find(case2, " "))
					hash.AddColor_g = tonumber(string.Left(case2, string.find(case2, " ") - 1))
					case2 = string.Right(case2, string.len(case2) - string.find(case2, " "))
					hash.AddColor_b = tonumber(case2)
				end

				if string.len(case3) > 0 then
					hash.MulColor_r = tonumber(string.Left(case3, string.find(case3, " ") - 1))
					case3 = string.Right(case3, string.len(case3) - string.find(case3, " "))
					hash.MulColor_g = tonumber(string.Left(case3, string.find(case3, " ") - 1))
					case3 = string.Right(case3, string.len(case3) - string.find(case3, " "))
					hash.MulColor_b = tonumber(case3)
				end

				if case4 then
					hash.Brightness = tonumber(case4)
				end

				if case5 then
					hash.Contrast = tonumber(case5)
				end

				if case6 then
					hash.Color = tonumber(case6)
				end

				Colors[case16] = hash
				print("Registered new planet color", case16)
			elseif case1 == "planet_bloom" then
				hash = {}

				if string.len(case2) > 0 then
					hash.Col_r = tonumber(string.Left(case2, string.find(case2, " ") - 1))
					case2 = string.Right(case2, string.len(case2) - string.find(case2, " "))
					hash.Col_g = tonumber(string.Left(case2, string.find(case2, " ") - 1))
					case2 = string.Right(case2, string.len(case2) - string.find(case2, " "))
					hash.Col_b = tonumber(case2)
				end

				if string.len(case3) > 0 then
					hash.SizeX = tonumber(string.Left(case3, string.find(case3, " ") - 1))
					case3 = string.Right(case3, string.len(case3) - string.find(case3, " "))
					hash.SizeY = tonumber(case3)
				end

				if case4 then
					hash.Passes = tonumber(case4)
				end

				if case5 then
					hash.Darken = tonumber(case5)
				end

				if case6 then
					hash.Multiply = tonumber(case6)
				end

				if case7 then
					hash.Color = tonumber(case7)
				end

				Blooms[case16] = hash
				print("Registered new planet bloom", case16)
			elseif case1 == "star" then
				SB_InSpace = 1

				--SetGlobalInt("InSpace", 1)
				if not table.HasValue(TrueSun, pos) then
					local planet = ents.Create("base_sb_star1")
					planet:SetModel("models/props_lab/huladoll.mdl")
					planet:SetAngles(angles)
					planet:SetPos(pos)
					planet:Spawn()
					planet:CreateEnvironment(tonumber(case2))
					table.insert(TrueSun, pos)
					print("Registered new SB2 star", planet, planet:GetEnvironmentName())
				end
			elseif case1 == "star2" then
				SB_InSpace = 1

				--SetGlobalInt("InSpace", 1)
				if not table.HasValue(TrueSun, pos) then
					case2 = tonumber(case2) -- radius
					case3 = tonumber(case3) -- temp1
					case4 = tonumber(case4) -- temp2
					case5 = tonumber(case5) -- temp3
					case6 = tostring(case6) -- name

					local planet = ents.Create("base_sb_star2")
					planet:SetModel("models/props_lab/huladoll.mdl")
					planet:SetAngles(angles)
					planet:SetPos(pos)
					planet:Spawn()

					if case6 == "" then
						case6 = "Star " .. tostring(planet:GetEnvironmentID())
					end

					planet:CreateEnvironment(case2, case3, case4, case5, case6)

					table.insert(TrueSun, pos)
					print("Registered new SB3 star", planet, planet:GetEnvironmentName())
				end
			end
		end

		for k, v in pairs(Blooms) do
			if Planetsbloom[k] then
				Planetsbloom[k]:BloomEffect(v.Col_r, v.Col_g, v.Col_b, v.SizeX, v.SizeY, v.Passes, v.Darken, v.Multiply, v.Color)
			end
		end

		for k, v in pairs(Colors) do
			if Planetscolor[k] then
				Planetscolor[k]:ColorEffect(v.AddColor_r, v.AddColor_g, v.AddColor_b, v.MulColor_r, v.MulColor_g, v.MulColor_b, v.Brightness, v.Contrast, v.Color)
			end
		end

		-- compatibility patch, since this map does not convert to sb3 properly. ~Dubby
		if game.GetMap() == "gm_interplaneteryfunk" then
			local p = Entity(40):GetParent()
			Entity(40):Remove()
			Entity(41):GetParent():Remove()
			Entity(42):GetParent():Remove()
			Entity(43):GetParent():Remove()
			Entity(44):GetParent():Remove()
			local e = ents.Create("base_cube_environment")
			e:SetModel("models/props_lab/huladoll.mdl")
			e:SetAngles(Angle(0, 0, 0))
			e:SetPos(Vector(0, 0, -17400))
			e:Spawn()
			e:CreateEnvironment(p, 15344, 1, 1, 1, 289, 300, 21, 0.45, 78, 0.55, 0, "Earth")
			e.Active = true
			--lua_run local e = ents.Create("base_cube_environment") e:SetModel("models/props_lab/huladoll.mdl") e:SetAngles(Angle(0,0,0)) e:SetPos(Vector(0,0,-14472)) e:Spawn() e:CreateEnvironment(Entity(41):GetParent(),15000,1,1,1,289,300,21,0.45,78,0.55,0,"Earth")
		end

		if SB_InSpace == 1 then
			SB.__Construct()
		end
	end)
end

local function ForcePlyModel(ply)
	if ForceModel:GetInt() == 1 then
		if not ply.sbmodel then
			local i = math.Rand(0, 4)

			if i <= 1 then
				ply.sbmodel = "models/player/samzanemesis/MarineMedic.mdl"
			elseif i <= 2 then
				ply.sbmodel = "models/player/samzanemesis/MarineSpecial.mdl"
			elseif i <= 3 then
				ply.sbmodel = "models/player/samzanemesis/MarineOfficer.mdl"
			else --if i <= 4 then
				ply.sbmodel = "models/player/samzanemesis/MarineTech.mdl"
			end
		end

		ply:SetModel(ply.sbmodel)

		return true
	end
end

--End Local Stuff
--[[
	The AutoStart functions
	Optional
	Get's called before/replacing __Construct on CAF Startup
	Return true = AutoStart (Addon got enabled)
	Return nil or false = addon didn't get enabled
]]
function SB.__AutoStart()
	Register_Sun()
	Register_Environments()
end

local function ResetGravity()
	for k, ent in ipairs(sb_spawned_entities) do
		if ent and IsValid(ent) then
			local phys = ent:GetPhysicsObject()

			if phys:IsValid() and not (ent.IgnoreGravity and ent.IgnoreGravity == true) then
				ent:SetGravity(1)
				ent.gravity = 1
				phys:EnableGravity(true)
				phys:EnableDrag(true)
			end
		else
			table.remove(sb_spawned_entities, k)
		end
	end
end

--[[
	The Constructor for this Custom Addon Class
	Required
	Return True if succesfully able to start up this addon
	Return false, the reason of why it wasn't able to start
]]
function SB.__Construct()
	if SB_InSpace == 1 then
		hook.Add("PlayerNoClip", "SB_PlayerNoClip_Check", PlayerNoClip)
		hook.Add("PlayerFullLoad", "SB_PlayerInitialSpawn_Check", PlayerInitialSpawn)
		hook.Add("PlayerSetModel", "SB_Force_Model_Check", ForcePlyModel)
		timer.Create("SBEnvironmentCheck", 1, 0, SB.PerformEnvironmentCheck)
		ResetGravity()

		for k, v in pairs(player.GetAll()) do
			PlayerInitialSpawn(v)
		end

		return true
	end

	return false, "Not on a Spacebuild Map!"
end

--[[
	Get the required Addons for this Addon Class
	Optional
	Put the string names of the Addons in here in table format
	The CAF startup system will use this to decide if the Addon can be Started up or not. If a required addon isn't installed then Construct will not be called
	Example: return {"Resource Distribution", "Life Support"}
	
	Works together with the startup Level number at the bottom of this file
]]
function SB.GetRequiredAddons()
	return {}
end

--[[
	Get the Version of this Custom Addon Class
	Optional (but should be put it in most cases!)
]]
function SB.GetVersion()
	return 3.1, "Beta"
end

--[[
	You can send all the files from here that you want to add to send to the client
	Optional
]]
function SB.AddResourcesToSend()
	resource.AddFile("models/player/samzanemesis/MarineMedic.mdl")
	resource.AddFile("models/player/samzanemesis/MarineSpecial.mdl")
	resource.AddFile("models/player/samzanemesis/MarineOfficer.mdl")
	resource.AddFile("models/player/samzanemesis/MarineTech.mdl")
	resource.AddFile("materials/models/player/male/medic_body.vmt")
	resource.AddFile("materials/models/player/male/medic_body_female.vmt")
	resource.AddFile("materials/models/player/male/medic_helmet.vmt")
	resource.AddFile("materials/models/player/male/medic_helmet_female.vmt")
	resource.AddFile("materials/models/player/male/officer_body.vmt")
	resource.AddFile("materials/models/player/male/medic_helmet.vmt")
	resource.AddFile("materials/models/player/male/special_weapons_body.vmt")
	resource.AddFile("materials/models/player/male/special_weapons_body_female.vmt")
	resource.AddFile("materials/models/player/male/special_weapons_helmet.vmt")
	resource.AddFile("materials/models/player/male/special_weapons_helmet_female.vmt")
	resource.AddFile("materials/models/player/male/tech_body.vmt")
	resource.AddFile("materials/models/player/male/tech_helmet.vmt")
	resource.AddFile("materials/models/player/male/back_unit/medic_back_unit.vmt")
	resource.AddFile("materials/models/player/male/back_unit/medic_back_unit_female.vmt")
	resource.AddFile("materials/models/player/male/back_unit/officer_back_unit.vmt")
	resource.AddFile("materials/models/player/male/back_unit/special_weapons_back_unit.vmt")
	resource.AddFile("materials/models/player/male/back_unit/special_weapons_back_unit_female.vmt")
	resource.AddFile("materials/models/player/male/back_unit/tech_back_unit.vmt")
end

CAF.RegisterAddon("Spacebuild", SB, "1")

function SB.PerformEnvironmentCheck()
	if SB_InSpace == 0 then return end

	for k, ent in ipairs(sb_spawned_entities) do
		if IsValid(ent) and not ent.SkipSBChecks and ent.environment and not ent.IsEnvironment then
			ent.environment:UpdateGravity(ent)
			ent.environment:UpdatePressure(ent)
		else
			table.remove(sb_spawned_entities, k)
		end
	end
end

concommand.Add("sb_toggle_space_noclip", function (ply, cmd, args)
	if not IsValid(ply) then
		return
	end
	if not ply:IsAdmin() then
		ply:ChatPrint("You cannot use this command")
		return
	end
	ply.EnableSpaceNoclip = not ply.EnableSpaceNoclip
	if ply.EnableSpaceNoclip then
		ply:ChatPrint("Space noclip now enabled!")
	else
		ply:ChatPrint("Space noclip now disabled!")
	end
end)

function SB.PerformEnvironmentCheckOnEnt(ent)
	if SB_InSpace == 0 then return end
	if not ent then return end
	if ent.SkipSBChecks then return end

	local environment = sb_space.Get() --restore to default before doing the Environment checks

	for env, _ in pairs(ent.SBInEnvironments) do
		if not IsValid(env) then
			ent.SBInEnvironments[env] = nil
			continue
		end

		if env ~= ent and env:IsPreferredOver(environment) then
			environment = env
		end
	end

	if ent.environment ~= environment then
		ent.environment = environment
		SB.OnEnvironmentChanged(ent)
	end

	ent.environment:UpdateGravity(ent)
	ent.environment:UpdatePressure(ent)

	if ent:IsPlayer() and ent:GetMoveType() == MOVETYPE_NOCLIP and ent.environment and ent.environment:IsSpace() and not ent.EnableSpaceNoclip then
		ent:SetMoveType(MOVETYPE_WALK)
	end

	if (not ent.IsEnvironment or not ent:IsEnvironment() or (ent:GetVolume() == 0 and not ent:IsPlanet() and not ent:IsStar())) and ent.environment and ent.environment:GetTemperature(ent) > 10000 then
		if ent:IsPlayer() then
			ent:SilentKill()
		else
			ent:Remove()
		end
	end
end

local function cloneTable(tbl)
	local tmp = {}
	for k, v in pairs(tbl) do
		table.insert(tmp, v)
	end
	return tmp
end

-- Environment Functions
function SB.GetPlanets()
	return cloneTable(Planets)
end

function SB.GetStars()
	return cloneTable(Stars)
end

function SB.OnEnvironmentChanged(ent)
	if not ent.oldsbtmpenvironment or ent.oldsbtmpenvironment ~= ent.environment then
		local tmp = ent.oldsbtmpenvironment
		ent.oldsbtmpenvironment = ent.environment

		if tmp then
			gamemode.Call("OnEnvironmentChanged", ent, tmp, ent.environment)
		end
	end
end

function SB.GetSpace()
	return sb_space.Get()
end

function SB.AddEnvironment(env)
	if not env or not env.GetEnvClass or env:GetEnvClass() ~= "SB ENVIRONMENT" then return 0 end

	--if v.IsStar and not v:IsStar() and v.IsPlanet and not v:IsPlanet() then
	if env.IsStar and env:IsStar() then
		if not table.HasValue(Stars, env) then
			table.insert(Stars, env)
			numenv = numenv + 1
			env:SetEnvironmentID(numenv)

			return numenv
		end
	elseif env.IsPlanet and env:IsPlanet() then
		if not table.HasValue(Planets, env) then
			table.insert(Planets, env)
			numenv = numenv + 1
			env:SetEnvironmentID(numenv)

			return numenv
		end
	elseif not table.HasValue(Environments, env) then
		table.insert(Environments, env)
		numenv = numenv + 1
		env:SetEnvironmentID(numenv)

		return numenv
	end

	return env:GetEnvironmentID()
end

function SB.RemoveEnvironment(env)
	if not env or not env.GetEnvClass or env:GetEnvClass() ~= "SB ENVIRONMENT" then return end

	if env.IsStar and env:IsStar() then
		for k, v in pairs(Stars) do
			if env == v then
				table.remove(Stars, k)
			end
		end
	elseif env.IsPlanet and env:IsPlanet() then
		for k, v in pairs(Planets) do
			if env == v then
				table.remove(Planets, k)
			end
		end
	else
		for k, v in pairs(Environments) do
			if env == v then
				table.remove(Environments, k)
			end
		end
	end
end

function SB.GetEnvironments()
	local tmp = {}

	for k, v in pairs(Planets) do
		table.insert(tmp, v)
	end

	for k, v in pairs(Stars) do
		table.insert(tmp, v)
	end

	for k, v in pairs(Environments) do
		table.insert(tmp, v)
	end

	return tmp
end

function SB.AddOverride_PressureDamage()
	SB.Override_PressureDamage = SB.Override_PressureDamage + 1
end

--Volume Functions
--[[
* @param name
* @return Volume(table) or nil
*
]]
function SB.GetVolume(name)
	return volumes[name]
end


function SB.FindClosestPlanet(pos, starsto)
	local closestplanet = nil
	local closestDist = 99999999999999

	for k, v in pairs(Planets) do
		if not IsValid(v) then
			continue
		end
		local dist = v:GetPos():Distance(pos) - v:GetSize()
		if dist < closestDist then
			closestplanet = v
			closestDist = dist
		end
	end

	return closestplanet
end
