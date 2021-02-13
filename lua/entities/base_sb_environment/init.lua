﻿AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local SB_AIR_O2 = 0
local SB_AIR_CO2 = 1
local SB_AIR_N = 2
local SB_AIR_H = 3

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetNWInt("overlaymode", 1)
	self:SetNWInt("OOO", 0)
	self.Active = 0
	self.sbenvironment = {
		air = {
			o2 = 0,
			o2per = 0,
			co2 = 0,
			co2per = 0,
			n = 0,
			nper = 0,
			h = 0,
			hper = 0,
			empty = 0,
			emptyper = 0,
			max = 0
		},
		size = 0,
		gravity = 0,
		atmosphere = 0,
		pressure = 0,
		temperature = 0,
		name = "No Name"
	}

	CAF.GetAddon("Spacebuild").AddEnvironment(self)
end

function ENT:SBUpdatePhysics()
	if IsValid(self.physEnt) then
		self:DontDeleteOnRemove(self.physEnt)
		self.physEnt:Remove()
		self.physEnt = nil
	end

	if self:GetSize() <= 0 then
		return
	end

	self.physEnt = ents.Create("base_sb_environment_collider")
	self.physEnt:Spawn()
	self.physEnt:Activate()
	self:DeleteOnRemove(self.physEnt)
	self.physEnt:SetEnvironment(self)
end

local HAVE_COLLIDER_MODELS = file.Exists("models/colliders/59_00/icosphere_5999.mdl", "GAME")
if HAVE_COLLIDER_MODELS then
	print("[SB3] Found collider model set!")
else
	print("[SB3] Did not find collider model set!")
end

function ENT:SBEnvPhysics(ent)
	local size = math.floor(self:GetSize())
	if size < 1 then
		size = 1
	end
	if HAVE_COLLIDER_MODELS and size < 6000 then
		local mdl = "models/colliders/" .. math.floor(size / 100) .. "_00/icosphere_" .. size .. ".mdl"
		ent:SetModel(mdl)
		ent:PhysicsInit(SOLID_VPHYSICS)
	else
		local subdivisions = 0
		if not self.UserCreatedEnvironment then
			print("[SB3] Map environment", self.sbenvironment.name, " with size", size, " needed custom mesh!")
			subdivisions = 2
		end
		local v = icosphere(subdivisions, size)
		ent:PhysicsInitConvex(v)
		ent:SetCollisionBounds(Vector(-size, -size, -size), Vector(size, size, size))
		ent:EnableCustomCollisions(true)
	end
	ent:SetSolid(SOLID_VPHYSICS)
	ent:SetNotSolid(true)
end

local ignore = {"o2per", "co2per", "nper", "hper", "emptyper", "max"}
--[[
	Will add a new resource to the environment Air Supply, will try to fill up any Vacuum with the new Air if a Start value (either value or percentage)  is set
]]
function ENT:AddExtraResource(res, start, ispercentage)
	if not res then return false end


	if table.HasValue(ignore, res) then return false end

	if not start then
		start = 0
	end

	if not self.sbenvironment.air[res] then
		self.sbenvironment.air[res] = 0

		if start > 0 then
			if ispercentage then
				start = math.Round(start * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
			end

			local available = self:GetEmptyAir()

			if available < start then
				start = available
			end

			self:Convert(-1, res, start)
		end
	end
end

function ENT:CheckAirValues()
	local percentage = 0

	for k, v in pairs(self.sbenvironment.air) do
		if not table.HasValue(ignore, k) then
			if v and v < 0 then
				v = 0
			elseif v and v > 0 then
				percentage = percentage + v

				if percentage > 100 then
					-- Remove all above 100%
					local tomuch = percentage - 100
					v = v - tomuch
				end
			end
		end
	end
end

function ENT:Repair()
	self:SetHealth(self:GetMaxHealth())
end

function ENT:GetResourceAmount(res)
	if not res or type(res) == "number" then return 0 end

	if table.HasValue(ignore, res) then return 0 end

	return self.sbenvironment.air[res] or 0
end

function ENT:GetResourcePercentage(res)
	if not res or type(res) == "number" then return 0 end
	if self.sbenvironment.air.max == 0 then return 0 end

	if table.HasValue(ignore, res) then return 0 end

	return (self:GetResourceAmount(res) / self.sbenvironment.air.max) * 100
end

-- RD stuff begin
--use this to set self.active
--put a self:TurnOn and self:TurnOff() in your ent
--give value as nil to toggle
--override to do overdrive
--AcceptInput (use action) calls this function with value = nil
function ENT:SetActive(value, caller)
	if ((not (value == nil) and value ~= 0) or (value == nil)) and self.Active == 0 then
		if self.TurnOn then
			self:TurnOn(nil, caller)
		end
	elseif ((not (value == nil) and value == 0) or (value == nil)) and self.Active == 1 then
		if self.TurnOff then
			self:TurnOff(nil, caller)
		end
	end
end

function ENT:SetOOO(value)
	self:SetNWInt("OOO", value)
end

AccessorFunc(ENT, "LSMULTIPLIER", "Multiplier", FORCE_NUMBER)

function ENT:GetMultiplier()
	return self.LSMULTIPLIER or 1
end

function ENT:AcceptInput(name, activator, caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		self:SetActive(nil, caller)
	end
end

--should make the damage go to the shield if the shield is installed(CDS)
function ENT:OnTakeDamage(DmgInfo)
	if self.Shield then
		self.Shield:ShieldDamage(DmgInfo:GetDamage())
		CDS_ShieldImpact(self:GetPos())

		return
	end

	if CAF and CAF.GetAddon("Life Support") then
		CAF.GetAddon("Life Support").DamageLS(self, DmgInfo:GetDamage())
	end
end

function ENT:Think()
	if self.NextOverlayTextTime and (CurTime() >= self.NextOverlayTextTime) then
		if self.NextOverlayText then
			self:SetNWString("GModOverlayText", self.NextOverlayText)
			self.NextOverlayText = nil
		end

		self.NextOverlayTextTime = CurTime() + 0.2 + math.random() * 0.2
	end
end

function ENT:OnRemove()
	local rd = CAF.GetAddon("Resource Distribution")
	rd.Unlink(self)
	rd.RemoveRDEntity(self)

	if WireAddon ~= nil then
		Wire_Remove(self)
	end
end

function ENT:OnRestore()
	if WireAddon ~= nil then
		Wire_Restored(self)
	end
end

function ENT:PreEntityCopy()
	CAF.GetAddon("Resource Distribution").BuildDupeInfo(self)

	if WireAddon ~= nil then
		local DupeInfo = WireLib.BuildDupeInfo(self)

		if DupeInfo then
			duplicator.StoreEntityModifier(self, "WireDupeInfo", DupeInfo)
		end
	end
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	CAF.GetAddon("Resource Distribution").ApplyDupeInfo(Ent, CreatedEntities)

	if WireAddon ~= nil and Ent.EntityMods and Ent.EntityMods.WireDupeInfo then
		WireLib.ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end
end

--NEW Functions 
function ENT:RegisterNonStorageDevice()
	CAF.GetAddon("Resource Distribution").RegisterNonStorageDevice(self)
end

function ENT:AddResource(resource, maxamount, defaultvalue)
	return CAF.GetAddon("Resource Distribution").AddResource(self, resource, maxamount, defaultvalue)
end

function ENT:ConsumeResource(resource, amount)
	return CAF.GetAddon("Resource Distribution").ConsumeResource(self, resource, amount)
end

function ENT:SupplyResource(resource, amount)
	return CAF.GetAddon("Resource Distribution").SupplyResource(self, resource, amount)
end

function ENT:Link(netid)
	CAF.GetAddon("Resource Distribution").Link(self, netid)
end

function ENT:Unlink()
	CAF.GetAddon("Resource Distribution").Unlink(self)
end

function ENT:GetResourceAmount(resource)
	return CAF.GetAddon("Resource Distribution").GetResourceAmount(self, resource)
end

function ENT:GetUnitCapacity(resource)
	return CAF.GetAddon("Resource Distribution").GetUnitCapacity(self, resource)
end

function ENT:GetNetworkCapacity(resource)
	return CAF.GetAddon("Resource Distribution").GetNetworkCapacity(self, resource)
end

function ENT:GetEntityTable()
	return CAF.GetAddon("Resource Distribution").GetEntityTable(self)
end

--END NEW Functions
--RD stuff end
function ENT:IsOnPlanet()
	if self:IsPlanet() then return self end

	local environments = {self}

	local environment = self.environment

	while (environment) do
		table.insert(environments, environment)
		if environment and environment.IsPlanet and environment:IsPlanet() then return environment end
		environment = environment.environment
		if not environment or table.HasValue(environments, environment) then return nil end
	end

	return nil
end

function ENT:SetEnvironmentID(id)
	if not id or type(id) ~= "number" then return false end
	self.sbenvironment.id = id
end

function ENT:GetEnvironmentID()
	return self.sbenvironment.id or 0
end

function ENT:PrintVars()
	Msg("Print Environment Data\n")
	PrintTable(self.sbenvironment)
	Msg("End Print Environment Data\n")
end

function ENT:GetEnvClass()
	return "SB ENVIRONMENT"
end

function ENT:GetSize()
	return self.sbenvironment.size or 0
end

function ENT:GetPriority()
	return 3
end

function ENT:GetO2Percentage()
	if self.sbenvironment.air.max == 0 then return 0 end

	return (self.sbenvironment.air.o2 / self.sbenvironment.air.max) * 100
end

function ENT:GetEmptyAirPercentage()
	if self.sbenvironment.air.max == 0 then return 0 end

	return (self.sbenvironment.air.empty / self.sbenvironment.air.max) * 100
end

function ENT:GetCO2Percentage()
	if self.sbenvironment.air.max == 0 then return 0 end

	return (self.sbenvironment.air.co2 / self.sbenvironment.air.max) * 100
end

function ENT:GetNPercentage()
	if self.sbenvironment.air.max == 0 then return 0 end

	return (self.sbenvironment.air.n / self.sbenvironment.air.max) * 100
end

function ENT:GetHPercentage()
	if self.sbenvironment.air.max == 0 then return 0 end

	return (self.sbenvironment.air.h / self.sbenvironment.air.max) * 100
end

function ENT:SetSize(size)
	if size and type(size) == "number" then
		if size < 0 then
			size = 0
		end

		self:UpdateSize(self.sbenvironment.size, size)
	end
end

--Updates the atmosphere and the pressure based on it together with values of air
function ENT:ChangeAtmosphere(newatmosphere)
	if not newatmosphere or type(newatmosphere) ~= "number" then return "Invalid parameter" end

	if newatmosphere < 0 then
		newatmosphere = 0
	elseif newatmosphere > 1 then
		newatmosphere = 1
	end

	--Update the pressure since it's based on atmosphere and gravity
	if self.sbenvironment.atmosphere ~= 0 then
		self.sbenvironment.pressure = self.sbenvironment.pressure * (newatmosphere / self.sbenvironment.atmosphere)
	else
		self.sbenvironment.pressure = self.sbenvironment.pressure * newatmosphere
	end

	--Update air values so they are correct again (
	if newatmosphere > self.sbenvironment.atmosphere then
		self.sbenvironment.air.max = math.Round(100 * 5 * (self:GetVolume() / 1000) * newatmosphere)
		local tmp = self.sbenvironment.air.max - (self.sbenvironment.air.o2 + self.sbenvironment.air.co2 + self.sbenvironment.air.n + self.sbenvironment.air.h)
		self.sbenvironment.air.empty = tmp
		self.sbenvironment.air.emptyper = self:GetEmptyAirPercentage()
	else
		self.sbenvironment.air.o2 = math.Round(self:GetO2Percentage() * 5 * (self:GetVolume() / 1000) * newatmosphere)
		self.sbenvironment.air.co2 = math.Round(self:GetCO2Percentage() * 5 * (self:GetVolume() / 1000) * newatmosphere)
		self.sbenvironment.air.n = math.Round(self:GetNPercentage() * 5 * (self:GetVolume() / 1000) * newatmosphere)
		self.sbenvironment.air.h = math.Round(self:GetHPercentage() * 5 * (self:GetVolume() / 1000) * newatmosphere)
		self.sbenvironment.air.empty = math.Round(self:GetEmptyAirPercentage() * 5 * (self:GetVolume() / 1000) * newatmosphere)
		self.sbenvironment.air.max = math.Round(100 * 5 * (self:GetVolume() / 1000) * newatmosphere)
	end

	self.sbenvironment.atmosphere = newatmosphere
end

--Updates the gravity and the pressure based on it
function ENT:ChangeGravity(newgravity)
	if not newgravity or type(newgravity) ~= "number" then return "Invalid parameter" end

	--Update the pressure since it's based on atmosphere and gravity
	if self.sbenvironment.gravity ~= 0 then
		self.sbenvironment.pressure = self.sbenvironment.pressure * (newgravity / self.sbenvironment.gravity)
	else
		self.sbenvironment.pressure = self.sbenvironment.pressure * newgravity
	end

	self.sbenvironment.gravity = newgravity
end

function ENT:GetEnvironmentName()
	return self.sbenvironment.name
end

function ENT:SetEnvironmentName(value)
	if not value then return end
	self.sbenvironment.name = value
end

function ENT:GetSBGravity()
	return self.sbenvironment.gravity or 0
end

local SB = CAF.GetAddon("Spacebuild")
function ENT:UpdatePressure(ent)
	if not ent or SB.Override_PressureDamage > 0 then return end
	if ent:IsPlayer() and SB.PlayerOverride > 0 then return end

	if self.sbenvironment.pressure and self.sbenvironment.pressure > 1.5 then
		ent:TakeDamage((self.sbenvironment.pressure - 1.5) * 10)
	end
end

--Converts air1 to air2 for the max amount of the specified value
--Returns the actual amount of converted airtype
function ENT:Convert(air1, air2, value)
	if not air1 or not air2 or not value then return 0 end
	if type(air1) ~= "number" or type(air2) ~= "number" or type(value) ~= "number" then return 0 end
	air1 = math.Round(air1)
	air2 = math.Round(air2)
	value = math.Round(value)
	if air1 < -1 or air1 > 3 then return 0 end
	if air2 < -1 or air2 > 3 then return 0 end
	if air1 == air2 then return 0 end
	if value < 1 then return 0 end

	if air1 == -1 then
		if self.sbenvironment.air.empty < value then
			value = self.sbenvironment.air.empty
		end

		self.sbenvironment.air.empty = self.sbenvironment.air.empty - value

		if air2 == SB_AIR_CO2 then
			self.sbenvironment.air.co2 = self.sbenvironment.air.co2 + value
		elseif air2 == SB_AIR_N then
			self.sbenvironment.air.n = self.sbenvironment.air.n + value
		elseif air2 == SB_AIR_H then
			self.sbenvironment.air.h = self.sbenvironment.air.h + value
		elseif air2 == SB_AIR_O2 then
			self.sbenvironment.air.o2 = self.sbenvironment.air.o2 + value
		end
	elseif air1 == SB_AIR_O2 then
		if self.sbenvironment.air.o2 < value then
			value = self.sbenvironment.air.o2
		end

		self.sbenvironment.air.o2 = self.sbenvironment.air.o2 - value

		if air2 == SB_AIR_CO2 then
			self.sbenvironment.air.co2 = self.sbenvironment.air.co2 + value
		elseif air2 == SB_AIR_N then
			self.sbenvironment.air.n = self.sbenvironment.air.n + value
		elseif air2 == SB_AIR_H then
			self.sbenvironment.air.h = self.sbenvironment.air.h + value
		elseif air2 == -1 then
			self.sbenvironment.air.empty = self.sbenvironment.air.empty + value
		end
	elseif air1 == SB_AIR_CO2 then
		if self.sbenvironment.air.co2 < value then
			value = self.sbenvironment.air.co2
		end

		self.sbenvironment.air.co2 = self.sbenvironment.air.co2 - value

		if air2 == SB_AIR_O2 then
			self.sbenvironment.air.o2 = self.sbenvironment.air.o2 + value
		elseif air2 == SB_AIR_N then
			self.sbenvironment.air.n = self.sbenvironment.air.n + value
		elseif air2 == SB_AIR_H then
			self.sbenvironment.air.h = self.sbenvironment.air.h + value
		elseif air2 == -1 then
			self.sbenvironment.air.empty = self.sbenvironment.air.empty + value
		end
	elseif air1 == SB_AIR_N then
		if self.sbenvironment.air.n < value then
			value = self.sbenvironment.air.n
		end

		self.sbenvironment.air.n = self.sbenvironment.air.n - value

		if air2 == SB_AIR_O2 then
			self.sbenvironment.air.o2 = self.sbenvironment.air.o2 + value
		elseif air2 == SB_AIR_CO2 then
			self.sbenvironment.air.co2 = self.sbenvironment.air.co2 + value
		elseif air2 == SB_AIR_H then
			self.sbenvironment.air.h = self.sbenvironment.air.h + value
		elseif air2 == -1 then
			self.sbenvironment.air.empty = self.sbenvironment.air.empty + value
		end
	else
		if self.sbenvironment.air.h < value then
			value = self.sbenvironment.air.h
		end

		self.sbenvironment.air.h = self.sbenvironment.air.h - value

		if air2 == SB_AIR_O2 then
			self.sbenvironment.air.o2 = self.sbenvironment.air.o2 + value
		elseif air2 == SB_AIR_CO2 then
			self.sbenvironment.air.co2 = self.sbenvironment.air.co2 + value
		elseif air2 == SB_AIR_N then
			self.sbenvironment.air.n = self.sbenvironment.air.n + value
		elseif air2 == -1 then
			self.sbenvironment.air.empty = self.sbenvironment.air.empty + value
		end
	end

	return value
end

function ENT:UpdateGravity(ent)
	if not ent then return end
	if ent.gravity and ent.gravity == self.sbenvironment.gravity then
		return
	end
	ent.gravity = self.sbenvironment.gravity or 0

	local phys = ent:GetPhysicsObject()
	if not phys:IsValid() or (ent.IgnoreGravity and ent.IgnoreGravity == true) then return end

	if ent.gravity == 0 then
		phys:EnableGravity(false)
		phys:EnableDrag(false)
		ent:SetGravity(0.00001)
	else
		ent:SetGravity(ent.gravity)
		phys:EnableGravity(true)
		phys:EnableDrag(true)
	end
end

function ENT:GetAtmosphere()
	return self.sbenvironment.atmosphere or 0
end

function ENT:GetPressure()
	if not self.sbenvironment.pressure then return 0 end

	return self.sbenvironment.pressure - (((self:GetEmptyAirPercentage() / 100) * self.sbenvironment.pressure) * 0.75)
end

function ENT:GetTemperature()
	return self.sbenvironment.temperature or 0
end

function ENT:GetO2()
	return self.sbenvironment.air.o2 or 0
end

function ENT:GetEmptyAir()
	return self.sbenvironment.air.empty or 0
end

function ENT:GetCO2()
	return self.sbenvironment.air.co2 or 0
end

function ENT:GetN()
	return self.sbenvironment.air.n or 0
end

function ENT:GetH()
	return self.sbenvironment.air.h or 0
end

function ENT:CreateEnvironment(gravity, atmosphere, pressure, temperature, o2, co2, n, h, name)
	--Msg("CreateEnvironment: "..tostring(gravity).."\n")
	--set Gravity if one is given
	if gravity and type(gravity) == "number" then
		if gravity < 0 then
			gravity = 0
		end

		self.sbenvironment.gravity = gravity
	end

	--set atmosphere if given
	if atmosphere and type(atmosphere) == "number" then
		if atmosphere < 0 then
			atmosphere = 0
		elseif atmosphere > 1 then
			atmosphere = 1
		end

		self.sbenvironment.atmosphere = atmosphere
	end

	--set pressure if given
	if pressure and type(pressure) == "number" and pressure >= 0 then
		self.sbenvironment.pressure = pressure
	else
		self.sbenvironment.pressure = math.Round(self.sbenvironment.atmosphere * self.sbenvironment.gravity)
	end

	--set temperature if given
	if temperature and type(temperature) == "number" then
		self.sbenvironment.temperature = temperature
	end

	--set o2 if given
	if o2 and type(o2) == "number" and o2 > 0 then
		if o2 < 0 then
			o2 = 0
		end

		if o2 > 100 then
			o2 = 100
		end

		self.sbenvironment.air.o2per = o2
		self.sbenvironment.air.o2 = math.Round(o2 * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
	else
		o2 = 0
		self.sbenvironment.air.o2per = 0
		self.sbenvironment.air.o2 = 0
	end

	--set co2 if given
	if co2 and type(co2) == "number" and co2 > 0 then
		if co2 < 0 then
			co2 = 0
		end

		if (100 - o2) < co2 then
			co2 = 100 - o2
		end

		self.sbenvironment.air.co2per = co2
		self.sbenvironment.air.co2 = math.Round(co2 * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
	else
		co2 = 0
		self.sbenvironment.air.co2per = 0
		self.sbenvironment.air.co2 = 0
	end

	--set n if given
	if n and type(n) == "number" and n > 0 then
		if n < 0 then
			n = 0
		end

		if ((100 - o2) - co2) < n then
			n = (100 - o2) - co2
		end

		self.sbenvironment.air.nper = n
		self.sbenvironment.air.n = math.Round(n * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
	else
		n = 0
		self.sbenvironment.air.n = 0
		self.sbenvironment.air.n = 0
	end

	--set h if given
	if h and type(h) == "number" and h > 0 then
		if h < 0 then
			h = 0
		end

		if (((100 - o2) - co2) - n) < h then
			h = ((100 - o2) - co2) - n
		end

		self.sbenvironment.air.hper = h
		self.sbenvironment.air.h = math.Round(h * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
	else
		h = 0
		self.sbenvironment.air.h = 0
		self.sbenvironment.air.h = 0
	end

	if o2 + co2 + n + h < 100 then
		local tmp = 100 - (o2 + co2 + n + h)
		self.sbenvironment.air.empty = math.Round(tmp * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
		self.sbenvironment.air.emptyper = tmp
	elseif o2 + co2 + n + h > 100 then
		local tmp = (o2 + co2 + n + h) - 100

		if co2 > tmp then
			self.sbenvironment.air.co2 = math.Round((co2 - tmp) * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
			self.sbenvironment.air.co2per = co2 + tmp
		elseif n > tmp then
			self.sbenvironment.air.n = math.Round((n - tmp) * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
			self.sbenvironment.air.nper = n + tmp
		elseif h > tmp then
			self.sbenvironment.air.h = math.Round((h - tmp) * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
			self.sbenvironment.air.hper = h + tmp
		elseif o2 > tmp then
			self.sbenvironment.air.o2 = math.Round((o2 - tmp) * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
			self.sbenvironment.air.o2per = o2 - tmp
		end
	end

	if name then
		self.sbenvironment.name = name
	end

	self.sbenvironment.air.max = math.Round(100 * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)

	self:SBUpdatePhysics()
end

function ENT:UpdateSize(oldsize, newsize)
	if oldsize == newsize then return end

	if oldsize and newsize and type(oldsize) == "number" and type(newsize) == "number" and oldsize >= 0 and newsize >= 0 then
		if oldsize == 0 then
			self.sbenvironment.size = newsize
			self:UpdateEnvironment(nil, nil, nil, nil, self.sbenvironment.air.o2per, self.sbenvironment.air.co2per, self.sbenvironment.air.nper)
		elseif newsize == 0 then
			local tomuch = self.sbenvironment.air.o2

			if self.environment then
				tomuch = self.environment:Convert(-1, 0, tomuch)
			end

			tomuch = self.sbenvironment.air.co2

			if self.environment then
				tomuch = self.environment:Convert(-1, 1, tomuch)
			end

			tomuch = self.sbenvironment.air.n

			if self.environment then
				tomuch = self.environment:Convert(-1, 2, tomuch)
			end

			tomuch = self.sbenvironment.air.h

			if self.environment then
				tomuch = self.environment:Convert(-1, 3, tomuch)
			end

			self.sbenvironment.air.o2 = 0
			self.sbenvironment.air.co2 = 0
			self.sbenvironment.air.n = 0
			self.sbenvironment.air.h = 0
			self.sbenvironment.air.empty = 0
			self.sbenvironment.size = 0
		else
			self.sbenvironment.air.o2 = (newsize / oldsize) * self.sbenvironment.air.o2
			self.sbenvironment.air.co2 = (newsize / oldsize) * self.sbenvironment.air.co2
			self.sbenvironment.air.n = (newsize / oldsize) * self.sbenvironment.air.n
			self.sbenvironment.air.h = (newsize / oldsize) * self.sbenvironment.air.h
			self.sbenvironment.air.empty = (newsize / oldsize) * self.sbenvironment.air.empty
			self.sbenvironment.size = newsize
		end

		self.sbenvironment.air.max = math.Round(100 * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)

		if self.sbenvironment.air.o2 > self.sbenvironment.air.max then
			local tomuch = self.sbenvironment.air.o2 - self.sbenvironment.air.max

			if self.environment then
				tomuch = self.environment:Convert(-1, 0, tomuch)
				self.sbenvironment.air.o2 = self.sbenvironment.air.max + tomuch
			end
		end

		if self.sbenvironment.air.co2 > self.sbenvironment.air.max then
			local tomuch = self.sbenvironment.air.co2 - self.sbenvironment.air.max

			if self.environment then
				tomuch = self.environment:Convert(-1, 1, tomuch)
				self.sbenvironment.air.co2 = self.sbenvironment.air.max + tomuch
			end
		end

		if self.sbenvironment.air.n > self.sbenvironment.air.max then
			local tomuch = self.sbenvironment.air.n - self.sbenvironment.air.max

			if self.environment then
				tomuch = self.environment:Convert(-1, 2, tomuch)
				self.sbenvironment.air.n = self.sbenvironment.air.max + tomuch
			end
		end

		if self.sbenvironment.air.h > self.sbenvironment.air.max then
			local tomuch = self.sbenvironment.air.h - self.sbenvironment.air.max

			if self.environment then
				tomuch = self.environment:Convert(-1, 3, tomuch)
				self.sbenvironment.air.h = self.sbenvironment.air.max + tomuch
			end
		end

		self:SBUpdatePhysics()
	end
end

function ENT:UpdateEnvironment(gravity, atmosphere, pressure, temperature, o2, co2, n, h)
	--set Gravity if one is given
	self:ChangeGravity(gravity)
	--set atmosphere if given
	self:ChangeAtmosphere(newatmosphere)

	--set pressure if given (Should never be updated manualy like this in most cases!)
	if pressure and type(pressure) == "number" then
		if pressure < 0 then
			pressure = 0
		end

		self.sbenvironment.pressure = pressure
	end

	--set temperature if given
	if temperature and type(temperature) == "number" then
		self.sbenvironment.temperature = temperature
	end

	self.sbenvironment.air.max = math.Round(100 * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)

	--set o2 if given
	if o2 and type(o2) == "number" then
		if o2 < 0 then
			o2 = 0
		end

		if o2 > 100 then
			o2 = 100
		end

		self.sbenvironment.air.o2 = math.Round(o2 * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
		self.sbenvironment.air.o2per = o2
	else
		o2 = self:GetO2Percentage()
	end

	--set co2 if given
	if co2 and type(co2) == "number" then
		if co2 < 0 then
			co2 = 0
		end

		if (100 - o2) < co2 then
			co2 = 100 - o2
		end

		self.sbenvironment.air.co2 = math.Round(co2 * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
		self.sbenvironment.air.co2per = co2
	else
		co2 = self:GetCO2Percentage()
	end

	--set n if given
	if n and type(n) == "number" then
		if n < 0 then
			n = 0
		end

		if ((100 - o2) - co2) < n then
			n = (100 - o2) - co2
		end

		self.sbenvironment.air.n = math.Round(n * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
		self.sbenvironment.air.nper = n
	else
		n = self:GetNPercentage()
	end

	if h and type(h) == "number" then
		if h < 0 then
			h = 0
		end

		if (((100 - o2) - co2) - n) < h then
			h = (((100 - o2) - co2) - n)
		end

		self.sbenvironment.air.h = math.Round(h * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
		self.sbenvironment.air.hper = h
	else
		h = self:GetHPercentage()
	end

	if o2 + co2 + n + h < 100 then
		local tmp = 100 - (o2 + co2 + n + h)
		self.sbenvironment.air.empty = math.Round(tmp * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
		self.sbenvironment.air.emptyper = tmp
	elseif o2 + co2 + n + h > 100 then
		local tmp = (o2 + co2 + n + h) - 100

		if co2 >= tmp then
			self.sbenvironment.air.co2 = math.Round((co2 - tmp) * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
			self.sbenvironment.air.co2per = co2 + tmp
		elseif n >= tmp then
			self.sbenvironment.air.n = math.Round((n - tmp) * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
			self.sbenvironment.air.nper = n + tmp
		elseif h >= tmp then
			self.sbenvironment.air.h = math.Round((h - tmp) * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
			self.sbenvironment.air.hper = h + tmp
		elseif o2 >= tmp then
			self.sbenvironment.air.o2 = math.Round((o2 - tmp) * 5 * (self:GetVolume() / 1000) * self.sbenvironment.atmosphere)
			self.sbenvironment.air.o2per = o2 - tmp
		end
	end
end

function ENT:GetVolume()
	return (4 / 3) * math.pi * self.sbenvironment.size * self.sbenvironment.size
end

function ENT:IsEnvironment()
	return true
end

function ENT:IsPlanet()
	return false
end

function ENT:IsStar()
	return false
end

function ENT:IsSpace()
	return false
end

function ENT:IsPreferredOver(environment)
	if environment == space then
		return true
	end

	if environment:GetPriority() < self:GetPriority() then
		return true
	end

	if environment:GetPriority() == self:GetPriority() and (environment:GetSize() == 0 or self:GetSize() <= environment:GetSize()) then
		return true
	end

	return false
end

function ENT:PosInEnvironment(pos, other)
	if other and other == self then return other end
	local dist2 = (pos - self:GetPos()):LengthSqr()
	local size = self:GetSize()
	local size2 = size * size

	if dist2 < size2 then
		if other then
			if other:GetPriority() < self:GetPriority() then
				return self
			elseif other:GetPriority() == self:GetPriority() then
				if self:GetSize() > other:GetSize() then return other end
			else
				return other
			end
		end

		return self
	end

	return other
end

function ENT:Remove()
	CAF.GetAddon("Spacebuild").RemoveEnvironment(self)
end