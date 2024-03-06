AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
util.PrecacheSound("RD/pump/beep-4.wav")
util.PrecacheSound("RD/pump/beep-3.wav")
util.PrecacheSound("RD/pump/beep-5.wav")
include("shared.lua")
local pumps = {}
util.AddNetworkString("RD_Add_ResourceRate_to_Pump")
util.AddNetworkString("RD_Open_Pump_Menu")

local RD = CAF.GetAddon("Resource Distribution")

function ENT:CheckPlayerOK(ply)
	if not ply then
		return true
	end

	if not IsValid(ply) then
		return false
	end

	return self:CPPICanUse(ply)
end

local function HandleConCmdError(ply, ok, err)
	if not ok and IsValid(ply) then
		ply:ChatPrint(err or "Unknown pump control error")
	end
	return ok
end

local function TurnOnPump(ply, com, args)
	local id = args[1]
	if not id then return end
	local ent = ents.GetByIndex(id)
	if not ent then return end

	if ent.IsPump and ent.TurnOn then
		HandleConCmdError(ply, ent:TurnOn(ply))
	end
end
concommand.Add("PumpTurnOn", TurnOnPump)

local function TurnOffPump(ply, com, args)
	local id = args[1]
	if not id then return end
	local ent = ents.GetByIndex(id)
	if not ent then return end

	if ent.IsPump and ent.TurnOff then
		HandleConCmdError(ply, ent:TurnOff(ply))
	end
end
concommand.Add("PumpTurnOff", TurnOffPump)

function ENT:SetResourceAmount(ply, res, amount)
	if not self:CheckPlayerOK(ply) then
		return false, "You are not allowed to control this pump!"
	end

	if not amount then
		return false, "Amount needs to be specified!"
	end

	amount = tonumber(amount)
	if amount < 0 then
		amount = 0
	end

	self.ResourcesToSend[res] = amount
	net.Start("RD_Add_ResourceRate_to_Pump")
		net.WriteEntity(self)
		net.WriteString(res)
		net.WriteUInt(amount, 32)
	net.Broadcast()

	return true
end

local function SetResourceAmount(ply, com, args)
	local id = args[1]
	if not id or not args[2] or not args[3] then return end
	local ent = ents.GetByIndex(id)
	if not ent then return end

	if ent.IsPump and ent.SetResourceAmount then
		HandleConCmdError(ply, ent:SetResourceAmount(ply, args[2], tonumber(args[3])))
	end
end
concommand.Add("SetResourceAmount", SetResourceAmount)

function ENT:LinkToPump(ply, ent)
	if not self:CheckPlayerOK(ply) then
		return false, "You are not allowed to control this pump!"
	end

	if not (IsValid(ent) and ent.IsPump) then
		return false, "The other entity is not a pump"
	end

	if ent == self then
		return false, "Pump cannot connect to itself"
	end

	if self.otherpump == ent then
		return true
	end

	if self.otherpump then
		self:EmitSound("RD/pump/beep-5.wav", 256)
		return false, "This Pump is already connected to another pump!"
	elseif self:GetPos():Distance(ent:GetPos()) > 512 then
		self:EmitSound("RD/pump/beep-5.wav", 256)
		return false, "There can only be a distance of 512 units between 2 pumps!"
	else
		self:Connect(ent)
	end

	return true
end

local function LinkToPump(ply, com, args)
	local id = args[1]
	local id2 = args[2]
	if not id or not id2 then return end
	id = tonumber(id)
	id2 = tonumber(id2)
	local ent = ents.GetByIndex(id)
	local ent2 = ents.GetByIndex(id2)
	if not ent or not ent2 then return end

	if ent.IsPump and ent.LinkToPump then
		HandleConCmdError(ply, ent:LinkToPump(ply, ent2))
	end
end
concommand.Add("LinkToPump", LinkToPump)

local function SetPumpName(ply, com, args)
	local id = args[1]
	local name = args[2]
	if not id or not name then return end
	id = tonumber(id)
	name = tostring(name)
	local ent = ents.GetByIndex(id)
	if not ent or not ent.IsPump then return end
	local oldname = ent:GetPumpName()
	if HandleConCmdError(ply, ent:SetPumpName(ply, name)) then
		ply:ChatPrint("Changed name for pump <" .. tostring(oldname) .. "> to <" .. name .. ">")
	end
end
concommand.Add("SetPumpName", SetPumpName)

local function UnlinkPump(ply, com, args)
	local id = args[1]
	if not id then return end
	local ent = ents.GetByIndex(id)
	if not ent then return end

	if ent.IsPump then
		ent:Disconnect()
	end
end
concommand.Add("UnlinkPump", UnlinkPump)

local function UserConnect(ply)
	for k, v in pairs(pumps) do
		if IsValid(v) then
			for l, w in pairs(v.ResourcesToSend) do
				net.Start("RD_Add_ResourceRate_to_Pump")
					net.WriteEntity(v)
					net.WriteString(l)
					net.WriteUInt(w, 32)
				net.Send(ply)
			end
		end
	end
end
hook.Add("PlayerFullLoad", "RD_Pump_info_Update", UserConnect)

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetNWInt("overlaymode", 1)
	self:SetNWInt("OOO", 0)
	self.Active = 0
	self.ResourcesToSend = {}
	self.netid = 0
	self:SetNWInt("netid", self.netid)
	self.otherpump = nil
	self.WireConnectPump = -1
	table.insert(pumps, self)

	if WireAddon ~= nil then
		self.WireDebugName = self.PrintName

		self.Inputs = Wire_CreateInputs(self, {"On", "Disconnect", "ConnectID", "Connect"})

		self.Outputs = Wire_CreateOutputs(self, {"On", "PumpID", "ConnectedPumpID"})

		Wire_TriggerOutput(self, "PumpID", self:EntIndex())
		Wire_TriggerOutput(self, "ConnectedPumpID", -1)
	else
		self.Inputs = {
			{
				Name = "On"
			},
			{
				Name = "Disconnect"
			},
			{
				Name = "ConnectID"
			},
			{
				Name = "Connect"
			}
		}
	end

	self:SetNWString("name", "test")
	self:SetPumpName(nil, "Pump_" .. tostring(self:EntIndex()))
end

function ENT:GetPumpName()
	return self:GetNWString("name")
end

function ENT:SetPumpName(ply, name)
	if not self:CheckPlayerOK(ply) then
		return false, "You are not allowed to control this pump!"
	end

	self:SetNWString("name", name)
	return true
end

function ENT:SetNetwork(netid)
	if not netid then return end
	self.netid = netid
	self:SetNWInt("netid", self.netid)
end

function ENT:TurnOn(ply)
	if not self:CheckPlayerOK(ply) then
		return false, "You are not allowed to control this pump!"
	end

	if self.Active == 0 then
		self.Active = 1
		self:SetOOO(1)

		if WireAddon ~= nil then
			Wire_TriggerOutput(self, "On", self.Active)
		end
	end

	return true
end

function ENT:TurnOff(ply)
	if not self:CheckPlayerOK(ply) then
		return false, "You are not allowed to control this pump!"
	end

	if self.Active == 1 then
		self.Active = 0
		self:SetOOO(0)

		if WireAddon ~= nil then
			Wire_TriggerOutput(self, "On", self.Active)
		end
	end

	return true
end

function ENT:TriggerInput(iname, value)
	if iname == "On" then
		if value == 0 then
			self:TurnOff()
		elseif value == 1 then
			self:TurnOn()
		end
	elseif iname == "Disconnect" then
		if value == 1 then
			self:Disconnect()
		end
	elseif iname == "ConnectID" then
		if value > -1 then
			self.WireConnectPump = value
		end
	elseif iname == "Connect" then
		if value ~= 0 and self.WireConnectPump >= 0 then
			local ent2 = ents.GetByIndex(self.WireConnectPump)
			if not ent2 then return end

			self:LinkToPump(nil, ent2)
		end
	end
end

--use this to set self.active
--put a self:TurnOn and self:TurnOff() in your ent
--give value as nil to toggle
--override to do overdrive
--AcceptInput (use action) calls this function with value = nil
function ENT:SetActive(value, caller)
	net.Start("RD_Open_Pump_Menu")
	net.WriteEntity(self)
	net.Send(caller)
end

function ENT:SetResourceNode(node)
	if not node then return end
	self.node = node
end

function ENT:SetOOO(value)
	self:SetNWInt("OOO", value)
end

AccessorFunc(ENT, "LSMULTIPLIER", "Multiplier", FORCE_NUMBER)

function ENT:GetMultiplier()
	return self.LSMULTIPLIER or 1
end

function ENT:Repair()
	self:SetHealth(self:GetMaxHealth())
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
	if self.otherpump and self.otherpump:GetPos():Distance(self:GetPos()) > 768 then
		self:Disconnect()
	end

	--if not self.otherpump then Wire_TriggerOutput(self, "ConnectedPumpID", -1) end --Suggested wireoutput fix, needed??
	if self.node and (not IsValid(self.node) or self.node:GetPos():Distance(self:GetPos()) > self.node.range) then
		RD.Beam_clear(self)

		if IsValid(self.node) then
			self:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
			self.node:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
		end

		self.node = nil
		self:SetNetwork(0)
		self.netid = 0
	elseif not self.node and self.netid ~= 0 then
		self:SetNetwork(0)
		self.netid = 0
	end

	if self.Active == 1 then
		if not self.otherpump then
			self:TurnOff()
		else
			if self.ResourcesToSend then
				for k, v in pairs(self.ResourcesToSend) do
					local curResourceAmount, _, curResourceTemperature = RD.GetNetResourceData(self.netid, k)
					if curResourceAmount == 0 then
						continue
					end
					if curResourceAmount > v then
						self:Send(k, v, curResourceTemperature)
					else
						self:Send(k, curResourceAmount, curResourceTemperature)
					end
				end
			end
		end
	end

	self:NextThink(CurTime() + 1)

	return true
end

function ENT:Send(resource, amount, temperature)
	if not self.otherpump then return end
	local left = self.otherpump:Receive(resource, amount, temperature)
	if not left then
		self:Disconnect()
		return
	end
	RD.ConsumeNetResource(self.netid, resource, amount - left)
end

function ENT:Receive(resource, amount, temperature)
	if not self.otherpump then return end
	return RD.SupplyNetResource(self.netid, resource, amount, temperature)
end

function ENT:Connect(ent)
	if ent and ent.IsPump then
		self:SetNWInt("connectedpump", ent:EntIndex())
		self.otherpump = ent
		ent:SetNWInt("connectedpump", self:EntIndex())
		ent.otherpump = self
		Wire_TriggerOutput(self, "ConnectedPumpID", ent:EntIndex())
		Wire_TriggerOutput(ent, "ConnectedPumpID", self:EntIndex())
		self:EmitSound("RD/pump/beep-3.wav", 256)
		self.otherpump:EmitSound("RD/pump/beep-3.wav", 256)
	end
end

function ENT:Disconnect(ply)
	if self.otherpump then
		self:EmitSound("RD/pump/beep-4.wav", 256)
		self.otherpump:EmitSound("RD/pump/beep-4.wav", 256)
		self.otherpump:SetNWInt("connectedpump", 0)
		self.otherpump.otherpump = nil
		Wire_TriggerOutput(self, "ConnectedPumpID", -1)
		Wire_TriggerOutput(self.otherpump, "ConnectedPumpID", -1)
		self:SetNWInt("connectedpump", 0)
		self.otherpump = nil
	end
end

function ENT:OnRemove()
	self:Disconnect()
	RD.Unlink(self)
	RD.RemoveRDEntity(self)

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