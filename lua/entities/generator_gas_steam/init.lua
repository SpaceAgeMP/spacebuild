AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
util.PrecacheSound("apc_engine_start")
util.PrecacheSound("apc_engine_stop")
include("shared.lua")
DEFINE_BASECLASS("base_rd3_entity")

local Water_Increment = 10
local RD = CAF.GetAddon("Resource Distribution")

function ENT:Initialize()
	BaseClass.Initialize(self)
	self.Active = 0
	self.overdrive = 0
	self.damaged = 0
	self.lastused = 0
	self.time = 0
	self.Mute = 0
	self.Multiplier = 1

	if WireAddon ~= nil then
		self.WireDebugName = self.PrintName

		self.Inputs = Wire_CreateInputs(self, {"On", "Overdrive", "Mute", "Multiplier"})

		self.Outputs = Wire_CreateOutputs(self, {"On", "Overdrive", "EnergyUsage", "WaterUsage", "SteamProduction"})
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
	if value then
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
		if value ~= 0 then
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
	self:StopSound("apc_engine_start")
end

local STEAM_TEMPERATURE = 473 -- Make 200C steam

function ENT:Proc_Water()
	local energy = self:GetResourceAmount("energy")
	local water, _, waterTemp = self:GetResourceData("water")

	if waterTemp >= STEAM_TEMPERATURE then
		return
	end

	local winc = Water_Increment + (self.overdrive * Water_Increment)
	winc = math.ceil(winc * self:GetMultiplier()) * self.Multiplier

	local einc = math.ceil(RD.GetResourceEnergyContent("water", winc, STEAM_TEMPERATURE - waterTemp) * 1.2)

	if WireAddon ~= nil then
		Wire_TriggerOutput(self, "EnergyUsage", einc)
		Wire_TriggerOutput(self, "WaterUsage", winc)
		Wire_TriggerOutput(self, "SteamProduction", winc)
	end

	if energy < einc or water < winc then
		self:TurnOff()
		return
	end

	self:ConsumeResource("energy", einc)
	self:ConsumeResource("water", winc)
	self:SupplyResource("water", winc, STEAM_TEMPERATURE)
end

function ENT:Think()
	BaseClass.Think(self)

	if self.Active == 1 then
		self:Proc_Water()
	end

	self:NextThink(CurTime() + 1)

	return true
end