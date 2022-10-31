﻿--load our other stools first
--include( "RD2/tool_manifest.lua" )
--dev link stool
--TOOL			= ToolObj:Create()
TOOL.Mode = "rd3_dev_link3"
TOOL.Category = "Resource Distribution"
TOOL.Name = "#Auto Link Tool"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT and GetConVarNumber("CAF_UseTab") == 1 then
	TOOL.Tab = "Custom Addon Framework"
end

if CLIENT then
	language.Add("tool.rd3_dev_link3.name", "Auto Link Tool")
	language.Add("tool.rd3_dev_link3.desc", "Links Resource-Carrying Devices together to a Resource Node, including Vehicle Pods.")
	language.Add("tool.rd3_dev_link3.0", "Left Click: Auto link all devices in the range of the select node that aren't connected and are owned by you.  Right Click: Unlink Two Devices.  Reload: Unlink Device from All.")
	language.Add("tool.rd3_dev_link3.1", "Right Click on another Resource-Carrying Device (or the same one to unlink ALL)")
	language.Add("rd3_dev_link3_addlength", "Add Length:")
	language.Add("rd3_dev_link3_width", "Width:")
	language.Add("rd3_dev_link3_material", "Material:")
	language.Add("rd3_dev_link3_colour", "Color:")
end

TOOL.ClientConVar["width"] = "2"
TOOL.ClientConVar["material"] = "cable/cable2"
TOOL.ClientConVar["color_r"] = "255"
TOOL.ClientConVar["color_g"] = "255"
TOOL.ClientConVar["color_b"] = "255"
TOOL.ClientConVar["color_a"] = "255"

local function link_in_range(ent, range)
	if not IsValid(ent) then
		return
	end
	local rd = CAF.GetAddon("Resource Distribution")
	for k, v in pairs(ents.FindInSphere(ent:GetPos(), range)) do
		local enttable = rd.GetEntityTable(v)

		if IsValid(v) and enttable.network == 0 and (CPPI and CPPI.GetOwner and CPPI.GetOwner(ent) ~= CPPI.GetOwner(v)) or (ent.GetPlayerName and v.GetPlayerName and ent:GetPlayerName() == v:GetPlayerName()) then
			-- try CPPI first, fallback if CPPI is not available
			rd.Link(v, ent.netid)
		end
	end
end

function TOOL:LeftClick(trace)
	if not trace.Entity:IsValid() or trace.Entity:IsPlayer() then return end
	if CLIENT then return true end

	if trace.Entity.IsNode then
		local ent = trace.Entity
		local range = ent.range
		link_in_range(ent, range * 2)
	else
		CAF.NotifyOwner(self, "You need to select a Resource Node to auto-link!")
	end

	return true
end

function TOOL:RightClick(trace)
	--if not valid or player, exit
	if trace.Entity:IsValid() and trace.Entity:IsPlayer() then return end
	--if client exit
	if CLIENT then return true end
	-- If there's no physics object then we can't constraint it!
	if SERVER and not util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone) then return false end
	--how many objects stored
	local iNum = self:NumObjects() + 1
	--save clicked postion
	self:SetObject(iNum, trace.Entity, trace.HitPos, trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone), trace.PhysicsBone, trace.HitNormal)

	if iNum <= 1 then
		self:SetStage(iNum)
		return true
	end
	-- Get information we're about to use
	local Ent1, Ent2 = self:GetEnt(1), self:GetEnt(2)

	local rd = CAF.GetAddon("Resource Distribution")

	if Ent1 == Ent2 then
		if Ent1.IsNode then
			rd.UnlinkAllFromNode(Ent1.netid)
		elseif Ent1.IsValve then
			if Ent1.IsEntityValve then
				Ent1:SetRDEntity(nil)
				Ent1:SetNode(nil)
			else
				Ent1:SetNode1(nil)
				Ent1:SetNode2(nil)
			end
		elseif Ent1.IsPump then
			Ent1.node = nil
			Ent1:SetNetwork(0)
			rd.Beam_clear(Ent1)
		else
			rd.Unlink(Ent1)
		end
	else
		if Ent1.IsNode and Ent2.IsNode then
			rd.UnlinkNodes(Ent1.netid, Ent2.netid)
		elseif Ent1.IsValve and Ent2.IsNode then
			if Ent1.IsEntityValve then
				if Ent1:GetNode() and Ent1:GetNode() == Ent2 then
					Ent1:SetNode(nil)
				else
					CAF.NotifyOwner(self, "This Entity Valve and Resource Node weren\\'t connected!")
				end
			else
				if Ent1:GetNode() and Ent1:GetNode1() == Ent2 then
					Ent1:SetNode1(nil)
				elseif Ent1:GetNode2() and Ent1:GetNode2() == Ent2 then
					Ent1:SetNode2(nil)
				else
					CAF.NotifyOwner(self, "This Resource Node Valve and Resource Node weren\\'t connected!")
				end
			end
		elseif Ent2.IsValve and Ent1.IsNode then
			if Ent2.IsEntityValve then
				if Ent2:GetNode() and Ent2:GetNode() == Ent1 then
					Ent2:SetNode(nil)
				else
					CAF.NotifyOwner(self, "This Entity Valve and Resource Node weren\\'t connected!")
				end
			else
				if Ent2:GetNode() and Ent2:GetNode1() == Ent1 then
					Ent2:SetNode1(nil)
				elseif Ent2:GetNode2() and Ent2:GetNode2() == Ent1 then
					Ent2:SetNode2(nil)
				else
					CAF.NotifyOwner(self, "This Resource Node Valve and Resource Node weren\\'t connected!")
				end
			end
		elseif Ent1.IsPump and Ent2.IsNode then
			Ent1.node = nil
			Ent1:SetNetwork(0)
			rd.Beam_clear(Ent1)
		elseif Ent2.IsPump and Ent1.IsNode then
			Ent2.node = nil
			Ent2:SetNetwork(0)
			rd.Beam_clear(Ent2)
		elseif Ent1.IsValve and Ent1.IsEntityValve and table.Count(rd.GetEntityTable(Ent2)) > 0 then
			if Ent1:GetRDEntity() == Ent2 then
				Ent1:SetRDEntity(nil)
			else
				CAF.NotifyOwner(self, "This Entity Valve and Entity weren\\'t connected!")
			end
		elseif Ent2.IsValve and Ent2.IsEntityValve and table.Count(rd.GetEntityTable(Ent1)) > 0 then
			if Ent2:GetRDEntity() == Ent1 then
				Ent2:SetRDEntity(nil)
			else
				CAF.NotifyOwner(self, "This Entity Valve and Entity weren\\'t connected!")
			end
		elseif Ent1.IsNode and rd.GetEntityTable(Ent2).network == Ent1.netid then
			rd.Unlink(Ent2)
		elseif Ent2.IsNode and rd.GetEntityTable(Ent1).network == Ent2.netid then
			rd.Unlink(Ent1)
		else
			CAF.NotifyOwner(self, "Invalid Combination!")
		end
	end

	-- Clear the objects so we're ready to go again
	self:ClearObjects()

	return true
end

function TOOL:Reload(trace)
	--if not valid or player, exit
	if trace.Entity:IsValid() and trace.Entity:IsPlayer() then return end
	--if client exit
	if CLIENT then return true end

	local rd = CAF.GetAddon("Resource Distribution")


	if trace.Entity.IsNode then
		rd.UnlinkAllFromNode(trace.Entity.netid)
	elseif trace.Entity.IsValve then
		if trace.Entity.IsEntityValve then
			trace.Entity:SetRDEntity(nil)
			trace.Entity:SetNode(nil)
		else
			trace.Entity:SetNode1(nil)
			trace.Entity:SetNode2(nil)
		end

		rd.Beam_clear(trace.Entity)
	elseif trace.Entity.IsPump then
		trace.Entity.node = nil
		trace.Entity:SetNetwork(0)
		rd.Beam_clear(trace.Entity)
	else
		rd.Unlink(trace.Entity)
	end

	self:ClearObjects() --clear objects

	return true
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", {
		Text = "#tool.rd3_dev_link.name",
		Description = "#tool.rd3_dev_link.desc"
	})

	panel:AddControl("Slider", {
		Label = "#rd3_dev_link3_width",
		Type = "Float",
		Min = ".1",
		Max = "20",
		Command = "rd3_dev_link3_width"
	})

	panel:AddControl("MatSelect", {
		Height = "1",
		Label = "#rd3_dev_link3_material",
		ItemWidth = 24,
		ItemHeight = 64,
		ConVar = "rd3_dev_link3_material",
		Options = list.Get("BeamMaterials")
	})

	panel:AddControl("Color", {
		Label = "#rd3_dev_link3_colour",
		Red = "rd3_dev_link3_color_r",
		Green = "rd3_dev_link3_color_g",
		Blue = "rd3_dev_link3_color_b",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
end