AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local SB = CAF.GetAddon("Spacebuild")

function ENT:Initialize()
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:DrawShadow(false)
	self:SetNoDraw(true)
	self.TouchTable = {}
end

function ENT:UpdateTransmitState()	
	return TRANSMIT_NEVER
end

function ENT:ResetTouchTable()
	for ent, _ in pairs(self.TouchTable) do
		self:EndTouch(ent)
	end
	self.TouchTable = {}

end

function ENT:SetEnvironment(env)
	self:SetPos(env:GetPos())
	self:SetParent(env)
	self.sbenv = env
	env:SBEnvPhysics(self)

	local phys = self:GetPhysicsObject()
	phys:EnableMotion(false)
	phys:EnableGravity(false)
	phys:EnableDrag(false)
	phys:Wake()

	self:SetTrigger(true)
end

function ENT:OnRemove()
	for ent, _ in pairs(self.TouchTable) do
		self:EndTouch(ent)
	end
	self.TouchTable = {}
end

function ENT:StartTouch(ent)
	if ent.SkipSBChecks or not self.sbenv then
		return
	end

	if not ent.SBInEnvironments then
		ent.SBInEnvironments = {}
	end

	self.TouchTable[ent] = true
	ent.SBInEnvironments[self.sbenv] = true
	SB.PerformEnvironmentCheckOnEnt(ent)
end

function ENT:EndTouch(ent)
	if ent.SkipSBChecks or not self.sbenv then
		return
	end

	if not ent.SBInEnvironments then
		ent.SBInEnvironments = {}
	end

	self.TouchTable[ent] = nil
	ent.SBInEnvironments[self.sbenv] = nil
	SB.PerformEnvironmentCheckOnEnt(ent)
end
