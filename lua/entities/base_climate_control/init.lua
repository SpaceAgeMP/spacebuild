--if not GAMEMODE.IsSpacebuildDerived then return end --Dont register the climate Control!
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
util.PrecacheSound("apc_engine_start")
util.PrecacheSound("apc_engine_stop")
util.PrecacheSound("common/warning.wav")
include("shared.lua")
DEFINE_BASECLASS("base_sb_environment")

function ENT:Initialize()
	self.UserCreatedEnvironment = true
	BaseClass.Initialize(self)
	self.Active = 0
	self.damaged = 0
	self:CreateEnvironment(1, 1, 1, 0, 0, 0, 0, 0)
	self.currentsize = 1024
	self.maxsize = 4096
	self.maxO2Level = 100

	if WireAddon ~= nil then
		self.WireDebugName = self.PrintName

		self.Inputs = Wire_CreateInputs(self, {"On", "Radius", "Gravity", "Max O2 level"})

		self.Outputs = Wire_CreateOutputs(self, {"On", "Oxygen-Level", "Temperature", "Gravity"})
	else
		self.Inputs = {
			{
				Name = "On"
			},
			{
				Name = "Radius"
			},
			{
				Name = "Gravity"
			},
			{
				Name = "Max O2 level"
			}
		}
	end
end

local function calcSizeMultiplier(ent)
	return math.ceil(ent.sbenvironment.size / ent.maxsize) * math.ceil(ent.maxsize / 1024)
end

function ENT:TurnOn()
	if self.Active == 0 then
		self:EmitSound("apc_engine_start")
		self.Active = 1
		self:UpdateSize(self.sbenvironment.size, self.currentsize) --We turn the forcefield that contains the environment on
		self:ConsumeResource("energy", calcSizeMultiplier(self) * 200)

		if WireAddon ~= nil then
			Wire_TriggerOutput(self, "On", self.Active)
		end

		self:SetOOO(1)
	end
end

function ENT:TurnOff()
	if self.Active == 0 then
		return
	end

	self:StopSound("apc_engine_start")
	self:EmitSound("apc_engine_stop")
	self.Active = 0
	local sbenvironment = self.sbenvironment

	local environment = self.environment

	--flush all resources into the environment if we are in one (used for the slownes of the SB updating process, we don't want errors do we?)
	if environment then
		if sbenvironment.air.o2 > 0 then
			local left = self:SupplyResource("oxygen", sbenvironment.air.o2)
			environment:Convert(-1, 0, left)
		end

		if sbenvironment.air.co2 > 0 then
			local left = self:SupplyResource("carbon dioxide", sbenvironment.air.co2)
			environment:Convert(-1, 1, left)
		end

		if sbenvironment.air.n > 0 then
			local left = self:SupplyResource("nitrogen", sbenvironment.air.n)
			environment:Convert(-1, 2, left)
		end

		if sbenvironment.air.h > 0 then
			local left = self:SupplyResource("hydrogen", sbenvironment.air.h)
			environment:Convert(-1, 3, left)
		end
	end

	sbenvironment.temperature = 0
	self:UpdateSize(sbenvironment.size, 0) --We turn the forcefield that contains the environment off!

	if WireAddon ~= nil then
		Wire_TriggerOutput(self, "On", self.Active)
	end

	self:SetOOO(0)
end

function ENT:TriggerInput(iname, value)
	local sbenvironment = self.sbenvironment

	if iname == "On" then
		self:SetActive(value)
	elseif iname == "Radius" then
		if value >= 0 and value < self.maxsize then
			if self.Active == 1 then
				self:UpdateSize(sbenvironment.size, value)
			end

			self.currentsize = value
		else
			if self.Active == 1 then
				self:UpdateSize(sbenvironment.size, self.maxsize) --Default value
			end

			self.currentsize = self.maxsize
		end
	elseif iname == "Gravity" then
		local gravity = value

		if value <= 0 then
			gravity = 0
		end

		sbenvironment.gravity = gravity
	elseif iname == "Max O2 level" then
		local level = 100
		level = math.Clamp(math.Round(value), 0, 100)
		self.maxO2Level = level
	end
end

function ENT:Damage()
	if self.damaged == 0 then
		self.damaged = 1
	end

	if (self.Active == 1) and (math.random(1, 10) <= 3) then
		self:TurnOff()
	end
end

function ENT:Repair()
	BaseClass.Repair(self)
	self:SetColor(Color(255, 255, 255, 255))
	self.damaged = 0
end

function ENT:Destruct()
	CAF.GetAddon("Spacebuild").RemoveEnvironment(self)
	CAF.GetAddon("Life Support").LS_Destruct(self, true)
end

function ENT:OnRemove()
	CAF.GetAddon("Spacebuild").RemoveEnvironment(self)
	BaseClass.OnRemove(self)
	self:StopSound("apc_engine_start")
end

function ENT:UpdateSize(oldsize, newsize)
	if oldsize == newsize or (not oldsize) or (not newsize) or (oldsize < 0) or (newsize < 0) then return end

	local sbenvironment = self.sbenvironment
	local environment = self.environment

	if oldsize == 0 then
		sbenvironment.size = newsize
		sbenvironment.air.o2 = 0
		sbenvironment.air.co2 = 0
		sbenvironment.air.n = 0
		sbenvironment.air.h = 0
		sbenvironment.air.empty = math.Round(25 * (self:GetVolume() / 1000) * sbenvironment.atmosphere)
	elseif newsize == 0 then
		local tomuch = sbenvironment.air.o2

		if environment then
			tomuch = environment:Convert(-1, 0, tomuch)
		end

		tomuch = sbenvironment.air.co2

		if environment then
			tomuch = environment:Convert(-1, 1, tomuch)
		end

		tomuch = sbenvironment.air.n

		if environment then
			tomuch = environment:Convert(-1, 2, tomuch)
		end

		tomuch = sbenvironment.air.h

		if environment then
			tomuch = environment:Convert(-1, 3, tomuch)
		end

		sbenvironment.air.o2 = 0
		sbenvironment.air.co2 = 0
		sbenvironment.air.n = 0
		sbenvironment.air.h = 0
		sbenvironment.air.empty = 0
		sbenvironment.size = 0
	else
		sbenvironment.air.o2 = (newsize / oldsize) * sbenvironment.air.o2
		sbenvironment.air.co2 = (newsize / oldsize) * sbenvironment.air.co2
		sbenvironment.air.n = (newsize / oldsize) * sbenvironment.air.n
		sbenvironment.air.h = (newsize / oldsize) * sbenvironment.air.h
		sbenvironment.air.empty = (newsize / oldsize) * sbenvironment.air.empty
		sbenvironment.size = newsize
	end

	sbenvironment.air.max = math.Round(25 * (self:GetVolume() / 1000) * sbenvironment.atmosphere)

	if sbenvironment.air.o2 > sbenvironment.air.max then
		local tomuch = sbenvironment.air.o2 - sbenvironment.air.max
		tomuch = self:SupplyResource("oxygen", tomuch)

		if environment then
			tomuch = environment:Convert(-1, 0, tomuch)
		end

		sbenvironment.air.o2 = sbenvironment.air.max + tomuch
	end

	if sbenvironment.air.co2 > sbenvironment.air.max then
		local tomuch = sbenvironment.air.co2 - sbenvironment.air.max
		tomuch = self:SupplyResource("carbon dioxide", tomuch)

		if environment then
			tomuch = environment:Convert(-1, 1, tomuch)
		end

		sbenvironment.air.co2 = sbenvironment.air.max + tomuch
	end

	if sbenvironment.air.n > sbenvironment.air.max then
		local tomuch = sbenvironment.air.n - sbenvironment.air.max
		tomuch = self:SupplyResource("nitrogen", tomuch)

		if environment then
			tomuch = environment:Convert(-1, 2, tomuch)
		end

		sbenvironment.air.n = sbenvironment.air.max + tomuch
	end

	if sbenvironment.air.h > sbenvironment.air.max then
		local tomuch = sbenvironment.air.h - sbenvironment.air.max
		tomuch = self:SupplyResource("hydrogen", tomuch)

		if environment then
			tomuch = environment:Convert(-1, 3, tomuch)
		end

		sbenvironment.air.h = sbenvironment.air.max + tomuch
	end

	self:SBUpdatePhysics()
end

function ENT:Climate_Control()
	local temperature = 0
	local pressure = 0
	local environment = self.environment

	if environment then
		temperature = environment:GetTemperature(self)
		pressure = environment:GetPressure()
	end

	--Only do something if the device is on
	if self.Active ~= 1 then
		self:TriggerWireOutputs() -- needed?
		return
	end
	local energy = self:GetResourceAmount("energy")

	local sizeMultiplier = calcSizeMultiplier(self)

	--Don't have enough power to keep the controler's think process running, shut it all down
	if energy == 0 or energy < sizeMultiplier * 3  then
		self:TurnOff()
		return
	end
	self:ConsumeResource("energy", sizeMultiplier * 3)
	local air = self:GetResourceAmount("oxygen")
	energy = self:GetResourceAmount("energy")
	local sbenvironment = self.sbenvironment

	--First let check our air supply and try to stabilize it if we got oxygen left in storage at a rate of 5 oxygen per second
	if sbenvironment.air.o2 < sbenvironment.air.max * (self.maxO2Level / 100) then
		--We need some energy to fire the pump!
		local energyneeded = sizeMultiplier * 5
		local mul = 1

		if energy < energyneeded then
			mul = energy / energyneeded
			self:ConsumeResource("energy", energy)
		else
			self:ConsumeResource("energy", energyneeded)
		end

		local airNeeded = math.ceil(5000 * mul)

		if air < airNeeded then
			airNeeded = air
		end

		if sbenvironment.air.empty > 0 then
			local actual = self:Convert(-1, 0, airNeeded)
			self:ConsumeResource("oxygen", actual)
		elseif sbenvironment.air.co2 > 0 then
			local actual = self:Convert(1, 0, airNeeded)
			self:ConsumeResource("oxygen", actual)
			local left = self:SupplyResource("carbon dioxide", actual)

			if environment then
				environment:Convert(-1, 1, left)
			end
		elseif sbenvironment.air.n > 0 then
			local actual = self:Convert(2, 0, airNeeded)
			self:ConsumeResource("oxygen", actual)
			local left = self:SupplyResource("nitrogen", actual)

			if environment then
				environment:Convert(-1, 2, left)
			end
		elseif sbenvironment.air.h > 0 then
			local actual = self:Convert(3, 0, airNeeded)
			self:ConsumeResource("oxygen", actual)
			local left = self:SupplyResource("hydrogen", actual)

			if environment then
				environment:Convert(-1, 1, left)
			end
		end
	elseif sbenvironment.air.o2 > sbenvironment.air.max then
		local tmp = sbenvironment.air.o2 - sbenvironment.air.max
		local left = self:SupplyResource("oxygen", tmp)

		if environment then
			environment:Convert(-1, 0, left)
		end
	end

	--Now let's check the pressure, if pressure is larger then 1 then we need some more power to keep the climate_controls environment stable. We don' want any leaks do we?
	if pressure > 1 then
		self:ConsumeResource("energy", (pressure - 1) * sizeMultiplier * 2)
	end

	if temperature < sbenvironment.temperature then
		local dif = sbenvironment.temperature - temperature
		dif = math.ceil(dif / 100) --Change temperature depending on the outside temperature, 5� difference does a lot less then 10000� difference
		sbenvironment.temperature = sbenvironment.temperature - dif
	elseif temperature > sbenvironment.temperature then
		local dif = temperature - sbenvironment.temperature
		dif = math.ceil(dif / 100)
		sbenvironment.temperature = sbenvironment.temperature + dif
	end

	if sbenvironment.temperature < 283 then
		if sbenvironment.temperature + 60 <= 308 then
			self:IncreaseTemperature(12)
		elseif sbenvironment.temperature + 30 <= 308 then
			self:IncreaseTemperature(9)
		elseif sbenvironment.temperature + 15 <= 308 then
			self:IncreaseTemperature(3)
		else
			self:IncreaseTemperature(1)
		end
	elseif sbenvironment.temperature > 308 then
		if sbenvironment.temperature - 60 >= 283 then
			self:LowerTemperature(12)
		elseif sbenvironment.temperature - 30 >= 283 then
			self:LowerTemperature(6)
		elseif sbenvironment.temperature - 15 >= 283 then
			self:LowerTemperature(3)
		else
			self:LowerTemperature(1)
		end
	end
	self:TriggerWireOutputs()
end

function ENT:IncreaseTemperature(factor)
	local sizeMul = calcSizeMultiplier(self)
	self:ConsumeResource("energy", sizeMul * 2)
	local energy = self:GetResourceAmount("energy")
	local requiredEnergy = sizeMul * 5 * factor
	local sbenvironment = self.sbenvironment

	if energy > requiredEnergy then
		sbenvironment.temperature = sbenvironment.temperature + 5 * factor
		self:ConsumeResource("energy", requiredEnergy)
		return
	end
	-- apply fractionally
	sbenvironment.temperature = sbenvironment.temperature + math.ceil((energy / requiredEnergy) * 5 * factor)
	self:ConsumeResource("energy", energy)
end

function ENT:LowerTemperature(factor)
	local coolant = self:GetResourceAmount("water")
	local coolant2 = self:GetResourceAmount("nitrogen")
	local consumptionBase = calcSizeMultiplier(self) * factor
	self:ConsumeResource("energy", consumptionBase * 2)

	local requiredCoolant2 = consumptionBase
	local requiredCoolant = requiredCoolant2 * 5
	local sbenvironment = self.sbenvironment


	if coolant2 > requiredCoolant2 then
		sbenvironment.temperature = sbenvironment.temperature - factor
		self:ConsumeResource("nitrogen", requiredCoolant2)
		return
	end
	if coolant > requiredCoolant then
		sbenvironment.temperature = sbenvironment.temperature - factor
		self:ConsumeResource("water", requiredCoolant)
		return
	end

	-- apply fractionally
	if coolant2 > 0 then
		sbenvironment.temperature = sbenvironment.temperature - math.ceil((coolant2 / requiredCoolant2) * factor)
		self:ConsumeResource("nitrogen", coolant2)
	elseif coolant > 0 then
		sbenvironment.temperature = sbenvironment.temperature - math.ceil((coolant / requiredCoolant) * factor)
		self:ConsumeResource("water", coolant)
	end
end

function ENT:TriggerWireOutputs()
	if WireAddon == nil then
		return
	end
	Wire_TriggerOutput(self, "Oxygen-Level", tonumber(self:GetO2Percentage()))
	Wire_TriggerOutput(self, "Temperature", tonumber(self.sbenvironment.temperature))
	Wire_TriggerOutput(self, "Gravity", tonumber(self.sbenvironment.gravity))
end

function ENT:Think()
	BaseClass.Think(self)
	self:Climate_Control()
	self:NextThink(CurTime() + 1)

	return true
end