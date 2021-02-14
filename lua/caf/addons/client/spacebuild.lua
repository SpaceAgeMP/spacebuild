list.Set("PlayerOptionsModel", "MedicMarine", "models/player/samzanemesis/MarineMedic.mdl")
list.Set("PlayerOptionsModel", "SpecialMarine", "models/player/samzanemesis/MarineSpecial.mdl")
list.Set("PlayerOptionsModel", "OfficerMarine", "models/player/samzanemesis/MarineOfficer.mdl")
list.Set("PlayerOptionsModel", "TechMarine", "models/player/samzanemesis/MarineTech.mdl")
local SB = {}
--Local functions
-- used for sun effects
local stars = {}

local function DrawSunEffects()
	-- no pixel shaders? no sun effects!
	if not render.SupportsPixelShaders_2_0() then return end
	local eyePos = EyePos()

	-- render each star.
	for ent, Sun in pairs(stars) do
		-- calculate brightness.
		local entpos = Sun.Position --Sun.ent:LocalToWorld( Vector(0,0,0) )
		local normVec = Vector(entpos - eyePos)
		normVec:Normalize()
		local dot = math.Clamp(EyeAngles():Forward():Dot(normVec), -1, 1)
		dot = math.abs(dot)
		--local dist = Vector( entpos - EyePos() ):Length();
		local dist = entpos:Distance(eyePos) / 1.5
		-- draw sunbeams.
		local sunpos = eyePos + normVec * (dist * 0.5)
		local scrpos = sunpos:ToScreen()

		if dist <= Sun.BeamRadius and dot > 0 then
			local frac = (1 - ((1 / Sun.BeamRadius) * dist)) * dot
			-- draw sun.
			--DrawSunbeams( darken, multiply, sunsize, sunx, suny )
			DrawSunbeams(0.95, frac, 0.255, scrpos.x / ScrW(), scrpos.y / ScrH())
		end

		-- can the sun see us?
		local tr = util.TraceLine({
			start = entpos,
			endpos = eyePos,
			filter = LocalPlayer(),
		})

		-- draw!
		if dist <= Sun.Radius and dot > 0 and tr.Fraction >= 1 then
			-- calculate brightness.
			local frac = (1 - ((1 / Sun.Radius) * dist)) * dot
			-- draw bloom.
			DrawBloom(0.428, 3 * frac, 15 * frac, 15 * frac, 5, 0, 1, 1, 1)
			-- draw colormod.
			DrawColorModify({
				["$pp_colour_addr"] = 0.35 * frac,
				["$pp_colour_addg"] = 0.15 * frac,
				["$pp_colour_addb"] = 0.05 * frac,
				["$pp_colour_brightness"] = 0.8 * frac,
				["$pp_colour_contrast"] = 1 + (0.15 * frac),
				["$pp_colour_colour"] = 1,
				["$pp_colour_mulr"] = 0,
				["$pp_colour_mulg"] = 0,
				["$pp_colour_mulb"] = 0,
			})
		end
	end
end

-- render.
local function Render()
	DrawSunEffects()
end

-- receive sun information
local function recvSun(msg)
	local ent = net.ReadInt(32)
	local position = net.ReadVector()
	local tmpname = net.ReadString()
	local radius = net.ReadFloat()

	stars[ent] = {
		name = tmpname,
		Position = position,
		Radius = radius, -- * 2
		BeamRadius = radius * 1.5, --*3
	}
end

net.Receive("AddStar", recvSun)

--End Local Functions
--The Class
--[[
	The Constructor for this Custom Addon Class
]]
function SB.__Construct()
	hook.Add("RenderScreenspaceEffects", "SB_VFX_Render", Render)

	return true
end

--[[
	Get the Version of this Custom Addon Class
]]
function SB.GetVersion()
	return 3.1, "Beta"
end

--[[
	Gets a menu from this Custom Addon Class
]]
--Name is nil for main menu, String for others
function SB.GetMenu(menutype, menuname)
	local data = {}

	return data
end

--[[
	Returns a table containing the Description of this addon
]]
function SB.GetDescription()
	return {"Spacebuild Addon", "", "Prviously a Gamemode", ""}
end

CAF.RegisterAddon("Spacebuild", SB, "1")