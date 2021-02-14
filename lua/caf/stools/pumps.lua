TOOL.Category = "Resource Distribution"
TOOL.Name = "#Resource Pumps"
TOOL.DeviceName = "Resource Pump"
TOOL.DeviceNamePlural = "Resource Pumps"
TOOL.ClassName = "pumps"
TOOL.DevSelect = true
TOOL.CCVar_type = "rd_pump"
TOOL.CCVar_sub_type = "normal"
TOOL.CCVar_model = "models/props_lab/tpplugholder_single.mdl"
TOOL.Limited = true
TOOL.LimitName = "pumps"
TOOL.Limit = 10
CAFToolSetup.SetLang("RD Resource Pumps", "Create Resource Pumps attached to any surface.", "Left-Click: Spawn a Device.  Reload: Repair Device.")
TOOL.ExtraCCVars = {}

local function resource_pump_func(ent, type, sub_type, devinfo, Extra_Data, ent_extras)
	local volume_mul = 1 --Change to be 0 by default later on
	local base_volume = 2272
	local base_mass = 10
	local base_health = 50
	local phys = ent:GetPhysicsObject()

	if phys:IsValid() then
		volume_mul = math.Round(phys:GetVolume()) / base_volume
	end

	local mass = math.Round(base_mass * volume_mul)
	local maxhealth = math.Round(base_health * volume_mul)

	return mass, maxhealth
end

TOOL.Devices = {
	rd_pump = {
		Name = "Resource Pump",
		type = "rd_pump",
		class = "rd_pump",
		func = resource_pump_func,
		devices = {
			normal = {
				Name = "Default",
				model = "models/ResourcePump/resourcepump.mdl",
			},
			normal_2 = {
				Name = "CE Pump",
				model = "models/ce_ls3additional/resource_pump/resource_pump.mdl",
			},
		},
	},
}