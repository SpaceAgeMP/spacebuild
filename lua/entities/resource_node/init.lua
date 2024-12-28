﻿AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.netid = CAF.GetAddon("Resource Distribution").CreateNetwork(self)
	self:SetNWInt("netid", self.netid)
	self:SetNWInt("overlaymode", 1)
	self.range = self.range or 512
	self:SetNWInt("range", self.range)
end

function ENT:SetCustomNodeName(name)
	self:SetNWString("rd_node_name", name)
end

function ENT:SetActive(value, caller)
end

function ENT:Repair()
	self:SetHealth(self:GetMaxHealth())
end

function ENT:SetRange(range)
	self.range = range
	self:SetNWInt("range", self.range)
end

function ENT:AcceptInput(name, activator, caller)
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
	local rd = CAF.GetAddon("Resource Distribution")
	local nettable = rd.GetNetTable(self.netid)

	for k, ent in pairs(nettable.entities) do
		if IsValid(ent) then
			local pos = ent:GetPos()

			if pos:Distance(self:GetPos()) > self.range then
				rd.Unlink(ent)
				self:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
				ent:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
			end
		end
	end

	local cons = nettable.cons


	for k, v in pairs(cons) do
		local tab = rd.GetNetTable(v)

		if not tab then
			continue
		end
		local ent = tab.nodeent

		if IsValid(ent) then
			local pos = ent:GetPos()
			local range = pos:Distance(self:GetPos())

			if range > self.range and range > ent.range then
				rd.UnlinkNodes(self.netid, ent.netid)
				self:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
				ent:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
			end
		end
	end

	self:NextThink(CurTime() + 1)

	return true
end

function ENT:OnRemove()
	local rd = CAF.GetAddon("Resource Distribution")
	rd.UnlinkAllFromNode(self.netid)
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