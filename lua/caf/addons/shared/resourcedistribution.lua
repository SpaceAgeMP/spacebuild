if SERVER then
	AddCSLuaFile()
end

local resourcenames = {}
local resourceids = {}
local resources = {}

function RD:__AddResources()
	self.AddProperResourceName("energy", CAF.GetLangVar("Energy"))
	self.AddProperResourceName("water", CAF.GetLangVar("Water"))
	self.AddProperResourceName("nitrogen", CAF.GetLangVar("Nitrogen"))
	self.AddProperResourceName("hydrogen", CAF.GetLangVar("Hydrogen"))
	self.AddProperResourceName("oxygen", CAF.GetLangVar("Oxygen"))
	self.AddProperResourceName("carbon dioxide", CAF.GetLangVar("Carbon Dioxide"))
	self.AddProperResourceName("heavy water", CAF.GetLangVar("Heavy Water"))
end

function RD.AddProperResourceName(resource, name)
	if not resource or not name then return end

	if not table.HasValue(resources, resource) then
		table.insert(resources, resource)
		resourceids[resource] = #resources
	end

	resourcenames[resource] = name
end

function RD.GetProperResourceName(resource)
	if not resource then return "" end
	if resourcenames[resource] then return resourcenames[resource] end

	return resource
end

function RD.GetResourceID(resource)
	return resourceids[resource]
end

function RD.GetResourceNameByID(id)
	return resources[id]
end

function RD.GetAllRegisteredResources()
	if not resourcenames or table.Count(resourcenames) < 0 then return {} end

	return table.Copy(resourcenames)
end

function RD.GetRegisteredResources()
	return table.Copy(resources)
end
