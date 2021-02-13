﻿AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
util.PrecacheSound("Airboat_engine_idle")
util.PrecacheSound("Airboat_engine_stop")
util.PrecacheSound("apc_engine_start")
include("shared.lua")
DEFINE_BASECLASS("base_rd3_entity")
local Pressure_Increment = 80
local Energy_Increment = 10

function ENT:Initialize()
	BaseClass.Initialize(self)
	self.Active = 0
	self.overdrive = 0
	self.damaged = 0
	self.lastused = 0
	self.Mute = 0
	self.Multiplier = 1

	if WireAddon ~= nil then
		self.WireDebugName = self.PrintName

		self.Inputs = Wire_CreateInputs(self, {"On", "Overdrive", "Mute", "Multiplier"})

		self.Outputs = Wire_CreateOutputs(self, {"On", "Overdrive", "EnergyUsage", "GasProduction"})
	else
		self.Inputs = {
			{
				Name = "On"
			},
			{
				Name = "Overdrive"
			}
		}
	end

	self.caf.custom.resource = "oxygen"
end

function ENT:TurnOn()
	if self.Active == 0 then
		if self.Mute == 0 then
			self:EmitSound("Airboat_engine_idle")
		end

		self.Active = 1

		if WireAddon ~= nil then
			Wire_TriggerOutput(self, "On", self.Active)
		end

		self:SetOOO(1)
	elseif self.overdrive == 0 then
		self:TurnOnOverdrive()
	end
end

function ENT:TurnOff()
	if self.Active == 1 then
		if self.Mute == 0 then
			self:StopSound("Airboat_engine_idle")
			self:EmitSound("Airboat_engine_stop")
			self:StopSound("apc_engine_start")
		end

		self.Active = 0
		self.overdrive = 0

		if WireAddon ~= nil then
			Wire_TriggerOutput(self, "On", self.Active)
		end

		self:SetOOO(0)
	end
end

function ENT:TurnOnOverdrive()
	if self.Active == 1 then
		if self.Mute == 0 then
			self:StopSound("Airboat_engine_idle")
			self:EmitSound("Airboat_engine_idle")
			self:EmitSound("apc_engine_start")
		end

		self:SetOOO(2)
		self.overdrive = 1

		if WireAddon ~= nil then
			Wire_TriggerOutput(self, "Overdrive", self.overdrive)
		end
	end
end

function ENT:TurnOffOverdrive()
	if self.Active == 1 and self.overdrive == 1 then
		if self.Mute == 0 then
			self:StopSound("Airboat_engine_idle")
			self:EmitSound("Airboat_engine_idle")
			self:StopSound("apc_engine_start")
		end

		self:SetOOO(1)
		self.overdrive = 0

		if WireAddon ~= nil then
			Wire_TriggerOutput(self, "Overdrive", self.overdrive)
		end
	end
end

function ENT:SetActive(value)
	if value ~= nil then
		if value ~= 0 and self.Active == 0 then
			self:TurnOn()
		elseif value == 0 and self.Active == 1 then
			self:TurnOff()
		end
	else
		if self.Active == 0 then
			self.lastused = CurTime()
			self:TurnOn()
		else
			if ((CurTime() - self.lastused) < 2) and (self.overdrive == 0) then
				self:TurnOnOverdrive()
			else
				self.overdrive = 0
				self:TurnOff()
			end
		end
	end
end

function ENT:TriggerInput(iname, value)
	if iname == "On" then
		self:SetActive(value)
	elseif iname == "Overdrive" then
		if value > 0 then
			self:TurnOnOverdrive()
		else
			self:TurnOffOverdrive()
		end
	end

	if iname == "Mute" then
		if value > 0 then
			self.Mute = 1
		else
			self.Mute = 0
		end
	end

	if iname == "Multiplier" then
		if value > 0 then
			self.Multiplier = value
		else
			self.Multiplier = 1
		end
	end
end

function ENT:Damage()
	if self.damaged == 0 then
		self.damaged = 1
	end

	if (self.Active == 1) and (math.random(1, 10) <= 4) then
		self:TurnOff()
	end
end

function ENT:Repair()
	BaseClass.Repair(self)
	self:SetColor(Color(255, 255, 255, 255))
	self.damaged = 0
end

function ENT:Destruct()
	if CAF and CAF.GetAddon("Life Support") then
		CAF.GetAddon("Life Support").Destruct(self, true)
	end
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)
	self:StopSound("Airboat_engine_idle")
end

function ENT:Pump_Air()
	self.energy = self:GetResourceAmount("energy")
	local mul = 1
	local SB = CAF.GetAddon("Spacebuild")

	if SB and self.environment and (self.environment:IsSpace() or self.environment:IsStar()) then
		mul = 0 --Make the device still absorb energy, but not produce any gas anymore
	elseif SB and self.environment and self.environment:IsEnvironment() and not self.environment:IsPlanet() then
		mul = 0.5
	end

	local einc = (Energy_Increment + (self.overdrive * Energy_Increment)) * self.Multiplier
	einc = math.ceil(einc * self:GetMultiplier())

	if WireAddon ~= nil then
		Wire_TriggerOutput(self, "EnergyUsage", math.Round(einc))
	end

	if self.energy >= einc then
		local ainc = math.ceil((Pressure_Increment + (self.overdrive * Pressure_Increment)) * mul * self:GetMultiplier())

		if self.overdrive == 1 then
			ainc = ainc * 2

			if CAF and CAF.GetAddon("Life Support") then
				CAF.GetAddon("Life Support").DamageLS(self, math.random(2, 3))
			else
				self:SetHealth(self:Health() - math.Random(2, 3))

				if self:Health() <= 0 then
					self:Remove()
				end
			end
		end

		self:ConsumeResource("energy", einc)

		if ainc > 0 then
			ainc = (ainc * self:GetMultiplier()) * self.Multiplier

			if WireAddon ~= nil then
				Wire_TriggerOutput(self, "GasProduction", math.Round(ainc))
			end

			local sb_resources = {"oxygen", "carbon dioxide", "hydrogen", "nitrogen"}

			if SB and table.HasValue(sb_resources, self.caf.custom.resource) then
				local usage = ainc

				if self.environment then
					if self.caf.custom.resource == "oxygen" then
						usage = self.environment:Convert(0, -1, ainc)
					elseif self.caf.custom.resource == "carbon dioxide" then
						usage = self.environment:Convert(1, -1, ainc)
					elseif self.caf.custom.resource == "hydrogen" then
						usage = self.environment:Convert(3, -1, ainc)
					elseif self.caf.custom.resource == "nitrogen" then
						usage = self.environment:Convert(2, -1, ainc)
					end
				end

				local left = self:SupplyResource(self.caf.custom.resource, usage)

				if self.environment then
					if self.caf.custom.resource == "oxygen" then
						self.environment:Convert(-1, 0, left)
					elseif self.caf.custom.resource == "carbon dioxide" then
						self.environment:Convert(-1, 1, left)
					elseif self.caf.custom.resource == "hydrogen" then
						self.environment:Convert(-1, 3, left)
					elseif self.caf.custom.resource == "nitrogen" then
						self.environment:Convert(-1, 2, left)
					end
				end
			else
				self:SupplyResource(self.caf.custom.resource, ainc)
			end
		end
	else
		self:TurnOff()
	end
end

function ENT:Think()
	BaseClass.Think(self)

	if self.Active == 1 then
		local waterlevel = 0

		if CAF then
			waterlevel = self:WaterLevel2()
		else
			waterlevel = self:WaterLevel()
		end

		if waterlevel > 1 then
			self:SetColor(Color(50, 50, 50, 255))
			self:TurnOff()
			self:Destruct()
		else
			self:Pump_Air()
		end
	end

	return true
end