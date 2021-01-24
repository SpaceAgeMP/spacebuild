AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
util.PrecacheSound("k_lab.ambient_powergenerators")
util.PrecacheSound("ambient/machines/thumper_startup1.wav")
include("shared.lua")
DEFINE_BASECLASS("base_rd3_entity")

local RD = CAF.GetAddon("Resource Distribution")

local MIN_FUSION_TEMP = 1000000

local HydrogenToEnergy = 3

local Energy_Increment = 500
local Hydrogen_Increment = 2000

function ENT:Initialize()
	BaseClass.Initialize(self)
	self.Active = 0
	self.Temperature = -1

	self.WireDebugName = self.PrintName

	self.Inputs = WireLib.CreateInputs(self, {"On"})
	self.Outputs = WireLib.CreateOutputs(self, {"On", "Fusion", "Temperature"})
end

function ENT:TurnOn()
	if (self.Active == 0) then
		self.Active = 1
		self:EmitSound("k_lab.ambient_powergenerators")
		self:EmitSound("ambient/machines/thumper_startup1.wav")

		WireLib.TriggerOutput(self, "On", 1)

		self:SetOOO(1)
	end
end

function ENT:TurnOff()
	if (self.Active == 1) then
		self.Active = 0
		self:StopSound("k_lab.ambient_powergenerators")

		WireLib.TriggerOutput(self, "On", 0)

		self:SetOOO(0)
	end
end

function ENT:TriggerInput(iname, value)
	if iname == "On" then
		self:SetActive(value)
	end
end

function ENT:OnRemove()
	self:StopSound("k_lab.ambient_powergenerators")
	BaseClass.OnRemove(self)
end

function ENT:Extract_Energy()
	if self.Temperature >= MIN_FUSION_TEMP then
		WireLib.TriggerOutput(self, "Fusion", 1)

		local hydrogenUse = math.ceil(Hydrogen_Increment * self:GetMultiplier())
		local usedHydrogen = self:ConsumeResource("hydrogen", hydrogenUse)
		if usedHydrogen <= 0 then
			return
		end

		local madeEnergy = usedHydrogen * HydrogenToEnergy

		local _, _, waterTemp = self:GetResourceData("water")
		if self.Temperature > waterTemp then
			local delta = self.Temperature - waterTemp
			local waterUse = RD.GetResourceAmountFromEnergy("water", madeEnergy * 0.95, delta)
			local usedWater = self:ConsumeResource("water", waterUse)
			local waterEnergyDiff = RD.GetResourceEnergyContent("water", usedWater, delta)
			self:SupplyResource("water", usedWater, self.Temperature)
			madeEnergy = madeEnergy - waterEnergyDiff
		end

		self:WarmUpWithEnergy(madeEnergy)
	else
		local energyUse = math.ceil(Energy_Increment * self.ThermalMass)
		self:WarmUpWithEnergy(energyUse)
		WireLib.TriggerOutput(self, "Fusion", 0)
	end
end

function ENT:Think()
	BaseClass.Think(self)
	self:NextThink(CurTime() + 1)

	if self.Temperature < 0 then
		return true
	end

	WireLib.TriggerOutput(self, "Temperature", self.Temperature)

	if self.Active == 1 then
		self:Extract_Energy()
	end
	return true
end