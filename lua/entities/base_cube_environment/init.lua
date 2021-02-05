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
	local size = self:GetSize()
	if size == 0 then
		return false
	end
	ent:SetCollisionBounds(Vector(-size, -size, -size), Vector(size, size, size))
	ent:PhysicsInitBox(Vector(-size, -size, -size), Vector(size, size, size))
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
	--if self.sbenvironment.unstable and math.random(1, 20) < 2 then
		--self:GetParent():Fire("invalue", "shake", "0") --self:GetParent():Fire("invalue", "rumble", "0")
	--end
end

function ENT:GetPriority()
	return 1
end

function ENT:CreateEnvironment(ent, radius, gravity, atmosphere, pressure, temperature, temperature2, o2, co2, n, h, flags, name)
	--needs a parent!
	if not ent then
		self:Remove()
	end

	self:SetParent(ent)
	self:SetFlags(flags)

	--set Radius if one is given
	if radius and type(radius) == "number" then
		if radius < 0 then
			radius = 0
		end

		self.sbenvironment.size = radius
	end

	--set temperature2 if given
	if temperature2 and type(temperature2) == "number" then
		self.sbenvironment.temperature2 = temperature2
	end

	BaseClass.CreateEnvironment(self, gravity, atmosphere, pressure, temperature, o2, co2, n, h, name)
end

function ENT:UpdateEnvironment(radius, gravity, atmosphere, pressure, temperature, o2, co2, n, h, temperature2, flags)
	if radius and type(radius) == "number" then
		self:SetFlags(flags)
		self:UpdateSize(self.sbenvironment.size, radius)
	end

	--set temperature2 if given
	if temperature2 and type(temperature2) == "number" then
		self.sbenvironment.temperature2 = temperature2
	end

	BaseClass.UpdateEnvironment(self, gravity, atmosphere, pressure, temperature, o2, co2, n, h)
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

function ENT:PosInEnvironment(pos, other)
	if other and other == self then return other end

	if (pos.x < cen.x + size and pos.x > cen.x - size) and (pos.y < cen.y + size and pos.y > cen.y - size) and (pos.z < cen.z + size and pos.z > cen.z - size) then
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