AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
require("caf_util")
DEFINE_BASECLASS("base_box_environment")

function ENT:CreateEnvironment(radius, gravity, atmosphere, pressure, temperature, temperature2, o2, co2, n, h, flags, name)
	--set Radius if one is given
	if radius and type(radius) == "number" then
		if radius < 0 then
			radius = 0
		end

		self.sbenvironment.size = radius
	end

	BaseClass.CreateEnvironment(self, gravity, atmosphere, pressure, temperature, temperature2, o2, co2, n, h, name)
end

function ENT:UpdateEnvironment(radius, gravity, atmosphere, pressure, temperature, o2, co2, n, h, temperature2, flags)
	if radius and type(radius) == "number" then
		self:UpdateSize(self.sbenvironment.size, radius)
	end

	BaseClass.UpdateEnvironment(self, gravity, atmosphere, pressure, temperature, o2, co2, n, h, temperature2, flags)
end

function ENT:UpdateSize(oldsize, newsize)
	BaseClass.UpdateOBB(self, Vector(-newsize, -newsize, -newsize), Vector(newsize, newsize, newsize))
	BaseClass.UpdateSize(self, oldsize, newsize)
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