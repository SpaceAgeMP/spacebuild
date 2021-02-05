TOOL.Category = "Life Support"
TOOL.Name = "#Environmental Control"
TOOL.DeviceName = "Environmental Control"
TOOL.DeviceNamePlural = "Environmental Controls"
TOOL.ClassName = "ls3_environmental_control"
TOOL.DevSelect = true
TOOL.CCVar_type = "other_dispenser"
TOOL.CCVar_sub_type = "default_other_dispenser"
TOOL.CCVar_model = "models/props_combine/combine_emitter01.mdl"
TOOL.Limited = true
TOOL.LimitName = "ls3_environmental_control"
TOOL.Limit = 30
CAFToolSetup.SetLang("Environmental Controls", "Create life support devices attached to any surface.", "Left-Click: Spawn a Device.  Reload: Repair Device.")

function TOOL.EnableFunc()
	if not CAF then return false end
	local rd = CAF.GetAddon("Resource Distribution")
	if not rd or not rd.GetStatus() then return false end

	return true
end

TOOL.ExtraCCVars = {
	extra_num = 0,
	extra_bool = 0,
}

function TOOL.ExtraCCVarsCP(tool, panel)
end

function TOOL:GetExtraCCVars()
	local Extra_Data = {}

	return Extra_Data
end

local function environmental_control_func(ent, type, sub_type, devinfo, Extra_Data, ent_extras)
	local volume_mul = 1 --Change to be 0 by default later on
	local base_volume = 4084 --Change to the actual base volume later on
	local base_mass = 10
	local base_health = 100

	if type == "other_dispenser" then
		base_volume = 4084 --This will need changed
	elseif type == "base_climate_control" then
		base_volume = 4084
		base_mass = 1200
		base_health = 1000
	elseif type == "other_probe" then
		base_volume = 4084
		base_mass = 20
		base_health = 1000
	elseif type == "nature_plant" then
		base_volume = 4084
		base_mass = 10
		base_health = 50
	end

	CAF.GetAddon("Resource Distribution").RegisterNonStorageDevice(ent)
	local phys = ent:GetPhysicsObject()

	if phys:IsValid() and phys.GetVolume then
		local vol = phys:GetVolume()
		vol = math.Round(vol)
		volume_mul = vol / base_volume
	end

	ent:SetMultiplier(volume_mul)
	local mass = math.Round(base_mass * volume_mul)
	ent.mass = mass
	local maxhealth = math.Round(base_health * volume_mul)

	return mass, maxhealth
end

local function sbCheck()
	local SB = CAF.GetAddon("Spacebuild")
	if SB and SB.GetStatus() then return true end

	return false
end

TOOL.Devices = {
	other_dispenser = {
		Name = "Suit Dispensers",
		type = "other_dispenser",
		class = "other_dispenser",
		func = environmental_control_func,
		devices = {
			default_other_dispenser = {
				Name = "Suit Dispenser",
				model = "models/props_combine/combine_emitter01.mdl",
				skin = 0,
				legacy = false,
			},
		},
	},
	base_climate_control = {
		Name = "Climate Regulators",
		type = "base_climate_control",
		class = "base_climate_control",
		func = environmental_control_func,
		EnableFunc = sbCheck,
		devices = {
			normal = {
				Name = "Climate Regulator",
				model = "models/props_combine/combine_generator01.mdl",
				skin = 0,
				legacy = false,
			},
		},
	},
	other_probe = {
		Name = "Atmospheric Probes",
		type = "other_probe",
		class = "other_probe",
		func = environmental_control_func,
		EnableFunc = sbCheck,
		devices = {
			normal = {
				Name = "Atmospheric Probe",
				model = "models/props_combine/combine_mine01.mdl",
				skin = 0,
				legacy = false,
			},
		},
	},
	nature_plant = {
		Name = "Air Hydroponics",
		type = "nature_plant",
		class = "nature_plant",
		func = environmental_control_func,
		devices = {
			normal = {
				Name = "Air Hydroponics",
				model = "models/props/cs_office/plant01.mdl",
				skin = 0,
				legacy = false,
			},
		},
	},
}