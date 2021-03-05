--glualint:ignore-file
local RD = CAF.GetAddon("Resource Distribution")
E2Lib.RegisterExtension("lifesupport", false)

local function bool_to_number(val)
	return val and 1 or 0
end

local E2_MAX_ARRAY_SIZE = 64

local function e2defaulttable()
	return {n={},ntypes={},s={},stypes={},size=0}
end

local function convert_table_to_e2_table(tab)
	local newTab = e2defaulttable()
	for k, v in pairs(tab) do
		local ty = string.lower(type(v))
		local validType = true
		if ty == "string" then
			newTab.stypes[k] = "s"
		elseif ty == "number" then
			newTab.stypes[k] = "n"
		elseif ty == "entity" then
			newTab.stypes[k] = "e"
		else
			validType = false
		end
		if validType then
			newTab.s[k] = v
			newTab.size = newTab.size + 1
		end
	end
	return newTab
end

local function ls_table_to_e2_table(sbenv)
	local retTab = convert_table_to_e2_table(sbenv)
	if sbenv.air then
		for k, v in pairs(sbenv.air) do
			if type(v) == "number" then
				k = "air"..k
				retTab.s[k] = v
				retTab.stypes[k] = "n"
				retTab.size = retTab.size + 1
			end
		end
	end
	return retTab
end

local function e2_ls_info(ent)
	local retTab = e2defaulttable()

	if ent.sbenvironment then
		retTab = ls_table_to_e2_table(ent.sbenvironment)
		if IsValid(ent) then
			retTab.s.entity = ent
			retTab.stypes.entity = "e"
			retTab.size = retTab.size + 1
		end
		return retTab
	end

	if ent.environment and ent.environment.sbenvironment then
		retTab = ls_table_to_e2_table(ent.environment.sbenvironment)
		if IsValid(ent.environment) then
			retTab.s.entity = ent.environment
			retTab.stypes.entity = "e"
			retTab.size = retTab.size + 1
		end
		return retTab
	end

	return retTab
end

local function ls_get_ent_netid(this)
	if not IsValid(this) then return nil end
	local netid = this.netid
	if netid <= 0 then return nil end
	return netid
end

local function ls_get_nettbl_by_ent(this)
	local netid = ls_get_ent_netid(this)
	if not netid then return nil end
	local nettable = RD.GetNetTable(netid)
	if not nettable.resources then return nil end
	return nettable.resources
end

local function ls_get_res_by_ent(this, res)
	local netid = ls_get_ent_netid(this)
	if not netid then return nil end
	local amount, capacity, temperature = RD.GetNetResourceData(netid, res)
	return amount, capacity, temperature
end

__e2setcost(10)
e2function table entity:lsInfo()
	if not IsValid(this) then return e2defaulttable() end
	return e2_ls_info(this)
end

e2function table lsInfo()
	local ent = self.entity
	if ent.environment == nil then
		ent:PhysWake()
	end
	return e2_ls_info(ent)
end

e2function array entity:lsGetResources()
	local nettable = ls_get_nettbl_by_ent(this)
	if not nettable then return {} end
	local aTab = {}
	for k, v in pairs(nettable) do
		table.insert(aTab, k)
		if #aTab >= E2_MAX_ARRAY_SIZE then break end
	end
	return aTab
end

__e2setcost(5)
e2function string lsGetName(string key)
	return RD.GetProperResourceName(key)
end

e2function number entity:lsGetAmount(string key)
	local amount, _, _ = ls_get_res_by_ent(this, key)
	return amount or 0
end

e2function number entity:lsGetCapacity(string key)
	local _, capacity, _ = ls_get_res_by_ent(this, key)
	return capacity or 0
end

e2function number entity:lsGetTemperature(string key)
	local _, _, temperature = ls_get_res_by_ent(this, key)
	return temperature or 0
end

-- PUMP FUNCTIONS
local function ls_ensure_valid_pump(ent)
	return ent and IsValid(ent) and ent:GetClass() == "rd_pump"
end

e2function number entity:lsPumpSetResourceAmount(string res, number amount)
	if not ls_ensure_valid_pump(this) then
		return 0
	end

	local ok = this:SetResourceAmount(self.player, res, amount)
	return bool_to_number(ok)
end

e2function number entity:lsPumpLink(entity otherpump)
	if not (ls_ensure_valid_pump(this) and ls_ensure_valid_pump(otherpump)) then
		return 0
	end

	local ok = this:LinkToPump(self.player, otherpump)
	return bool_to_number(ok)
end

e2function number entity:lsPumpUnlink()
	if not ls_ensure_valid_pump(this) then
		return 0
	end

	local ok = this:Disconnect(self.player)
	return bool_to_number(ok)
end

e2function number entity:lsPumpSetActive(number active)
	if not ls_ensure_valid_pump(this) then
		return 0
	end

	local ok
	if active == 0 then
		ok = this:TurnOff(self.player)
	else
		ok = this:TurnOn(self.player)
	end
	return bool_to_number(ok)
end

e2function number entity:lsPumpSetName(string name)
	if not ls_ensure_valid_pump(this) then
		return 0
	end

	local ok = this:SetPumpName(self.player, name)
	return bool_to_number(ok)
end

e2function string entity:lsPumpGetName()
	if not ls_ensure_valid_pump(this) then
		return 0
	end

	return this:GetPumpName()
end

e2function entity entity:lsPumpGetConnectedPump()
	if not ls_ensure_valid_pump(this) then
		return 0
	end

	return this.otherpump
end

e2function table entity:lsPumpGetResources()
	if not ls_ensure_valid_pump(this) then
		return 0
	end

	return convert_table_to_e2_table(this.ResourcesToSend)
end
-- END PUMP FUNCTIONS

e2function table entity:lsGetData(string key)
	local amount, capacity, temperature = ls_get_res_by_ent(this, key)
	return {
		n={},
		ntypes={},
		s={
			amount = amount or 0,
			capacity = capacity or 0,
			temperature = temperature or 0
		},
		stypes={
			amount = "n",
			capacity = "n",
			temperature = "n"
		},
		size=3
	}
end


-- NODE LINKING FUNCTIONS
__e2setcost(10)
e2function number entity:lsLink(entity node)
	if not IsValid(this) or not IsValid(node) or not node.IsNode then
		return nil
	end

	local canToolThis = this:CPPICanTool(self.player, "toolgun") and 1 or 0
	local canToolNode = node:CPPICanTool(self.player, "toolgun") and 1 or 0
	if canToolThis and canToolNode then
		local distance = this:GetPos():Distance(node:GetPos())
		if distance <= node.range then
			local netid = ls_get_ent_netid(node)
			RD.Link(this, netid)
			return 1
		end
	end
	return 0
end

e2function number entity:lsUnlink()
	if not IsValid(this) then
		return nil
	end

	local canTool = this:CPPICanTool(self.player, "toolgun") and 1 or 0
	if canTool then
		RD.Unlink(this)
		return 1
	end
	return 0
end

e2function number entity:lsUnlinkAll()
	if not IsValid(this) or not this.IsNode then
		return nil
	end

	local canTool = this:CPPICanTool(self.player, "toolgun") and 1 or 0
	if canTool then
		local netid = ls_get_ent_netid(this)
		RD.UnlinkAllFromNode(netid)
		return 1
	end
	return 0
end

e2function number entity:lsLinkNodes(entity node)
	if not IsValid(this) or not this.IsNode or not IsValid(node) or not node.IsNode then
		return nil
	end

	local canToolThis = this:CPPICanTool(self.player, "toolgun") and 1 or 0
	local canToolNode = node:CPPICanTool(self.player, "toolgun") and 1 or 0
	if canToolThis and canToolNode then
		local distance = this:GetPos():Distance(node:GetPos())
		if distance <= this.range and distance <= node.range then
			local netidThis = ls_get_ent_netid(this)
			local netidNode = ls_get_ent_netid(node)
			RD.LinkNodes(netidThis, netidNode)
			return 1
		end
	end
	return 0
end

e2function number entity:lsUnlinkNodes(entity node)
	if not IsValid(this) or not this.IsNode or not IsValid(node) or not node.IsNode then
		return nil
	end

	local canToolThis = this:CPPICanTool(self.player, "toolgun") and 1 or 0
	local canToolNode = node:CPPICanTool(self.player, "toolgun") and 1 or 0
	if canToolThis and canToolNode then
		local netidThis = ls_get_ent_netid(this)
		local netidNode = ls_get_ent_netid(node)
		RD.UnlinkNodes(netidThis, netidNode)
		return 1
	end
	return 0
end
-- END NODE LINKING FUNCTIONS