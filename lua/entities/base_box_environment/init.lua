AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
require("caf_util")
DEFINE_BASECLASS("base_sb_environment")

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.sbenvironment.temperature2 = 0
	self.sbenvironment.sunburn = false
	self.sbenvironment.unstable = false

	self:DrawShadow(false)

	if CAF then
		self.caf = self.caf or {}
		self.caf.custom = self.caf.custom or {}
		self.caf.custom.canreceivedamage = false
		self.caf.custom.canreceiveheatdamage = false
	end
end

function ENT:SBEnvPhysics(ent)
	ent:SetCollisionBounds(self.mins, self.maxs)
	ent:PhysicsInitBox(self.mins, self.maxs)
	ent:SetNotSolid(true)
end

function ENT:GetSunburn()
	return self.sbenvironment.sunburn
end

function ENT:GetUnstable()
	return self.sbenvironment.unstable
end

function ENT:SetFlags(flags)
	if not flags or type(flags) ~= "number" then return end
	self.sbenvironment.unstable = caf_util.isBitSet(flags, 1)
	self.sbenvironment.sunburn = caf_util.isBitSet(flags, 2)
end

function ENT:Unstable()

end

function ENT:GetPriority()
	return 1
end

function ENT:CreateEnvironment(gravity, atmosphere, pressure, temperature, temperature2, o2, co2, n, h, flags, name)
	self:SetFlags(flags)

	--set temperature2 if given
	if temperature2 and type(temperature2) == "number" then
		self.sbenvironment.temperature2 = temperature2
	end

	BaseClass.CreateEnvironment(self, gravity, atmosphere, pressure, temperature, o2, co2, n, h, name)
end

function ENT:UpdateEnvironment(gravity, atmosphere, pressure, temperature, o2, co2, n, h, temperature2, flags)
	self:SetFlags(flags)

	--set temperature2 if given
	if temperature2 and type(temperature2) == "number" then
		self.sbenvironment.temperature2 = temperature2
	end

	BaseClass.UpdateEnvironment(self, gravity, atmosphere, pressure, temperature, o2, co2, n, h)
end

function ENT:UpdateOBB(mins, maxs)
	self.mins = mins
	self.maxs = maxs
end

function ENT:IsPlanet()
	return true
end

function ENT:CanTool()
	return false
end

function ENT:GravGunPunt()
	return false
end

function ENT:GravGunPickupAllowed()
	return false
end

function ENT:Think()
	self:Unstable()
	self:NextThink(CurTime() + 1)

	return true
end
