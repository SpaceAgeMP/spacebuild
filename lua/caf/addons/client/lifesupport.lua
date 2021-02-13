﻿local LS = {}
--Local Stuff
local Display_temperature = CreateClientConVar("LS_Display_Temperature", "K", true, false)
local Display_hud = CreateClientConVar("LS_Display_HUD", "1", true, false)

--local ls_sb_mode = false
surface.CreateFont("LS3HudHeader", {
	font = "Verdana",
	size = 18,
	weight = 500
})

surface.CreateFont("LS3HudSubtitle", {
	font = "Verdana",
	size = 15,
	weight = 500
})

surface.CreateFont("LS3HudSubSubtitle", {
	font = "Verdana",
	size = 12,
	weight = 500
})

--Temperate 
local FairTemp_Min = 283
local FairTemp_Max = 308
--Hook Values
local ls_environment = {
	o2 = 0,
	temperature = 0
}

local ls_suit = {
	o2 = 0,
	coolant = 0,
	energy = 0
}

local ScH = ScrH()
local MidW = ScrW() / 2
local huds = {}
--Hud 1
local hud1 = {
	ScH = ScH,
	MidW = MidW,
	Left = MidW - 80, --70
	Left2 = MidW - 90, --80
	Right = MidW + 80, --70
	H1 = ScH / 8,
	Font = "LS3HudHeader"
}

hud1.H2 = ScH - hud1.H1
hud1.H3 = hud1.H1 - 5
hud1.TH = {hud1.H2 + 5, hud1.H2 + 20, hud1.H2 + 35, hud1.H2 + 50}

huds[1] = hud1
hud1 = nil
--Hud2
local hud2 = {
	ScH = ScH,
	MidW = MidW,
	Width = 224,
	Height = 128,
	Bottom = ScH - 32,
	HalfWidth = 224 / 2,
	Left = MidW - 224 / 2,
	Rounding = 8,
	Top2 = ScH + 8,
	Font = "LS3HudHeader",
	Font2 = "LS3HudSubtitle",
	Font3 = "LS3HudSubSubtitle"
}
hud2.Top = ScH - 32 - hud2.Height

huds[2] = hud2
hud2 = nil
local colors = {}
colors.White = Color(225, 225, 225, 255)
colors.Black = Color(0, 0, 0, 100)
colors.Cold = Color(0, 225, 255, 255)
colors.Hot = Color(225, 0, 0, 255)
colors.Warn = Color(255, 165, 0, 255)
colors.Grey = Color(150, 150, 150, 255)
colors.Green = Color(0, 225, 0, 255)
local MaxAmounts = 4000
local MaxAmountsDivide = MaxAmounts / 100

local function lifesupport_HUDPaint()
	if GetConVarString("cl_hudversion") ~= "" then
		return
	end
	local ls_sb_mode = false

	if CAF.GetAddon("Spacebuild") then
		ls_sb_mode = true
	end

	local ply = LocalPlayer()
	if not ply or not ply:Alive() then return end
	local hud_to_use = Display_hud:GetInt()

	if hud_to_use == 0 then
		return
	end
	if not ls_sb_mode then
		if ply:WaterLevel() > 2 then
			local Air = ls_suit.o2 / MaxAmountsDivide
			local valcol = colors.White

			if Air < 4 then
				valcol = colors.Warn
			end

			local hud = huds[1]
			local air_time_left = math.floor(ls_suit.o2 / 5)
			draw.RoundedBox(8, hud.Left2, hud.H2, 180, 20, colors.Black)
			draw.DrawText(CAF.GetLangVar("Air") .. ":", hud.Font, hud.Left, hud.H2 + 5, colors.White, 0)
			draw.DrawText(tostring(Air) .. "% (" .. tostring(air_time_left) .. "s)", hud.Font, hud.Right, hud.H2 + 5, valcol, 2)
		end
		return
	end
	if not (ply:WaterLevel() > 2 or ls_environment.o2 < 5 or (ls_environment.temperature > 0 and not (ls_environment.temperature >= FairTemp_Min and ls_environment.temperature <= FairTemp_Max)) or (ply.LSHudOn and ply.LSHudOn == true)) then
		return
	end
	if hud_to_use == 2 then
		local hud = huds[2]
		--[[
			Draw Left Side
		]]
		draw.RoundedBox(hud.Rounding, hud.Left, hud.Top, hud.HalfWidth, hud.Height, colors.Black)
		surface.SetFont(hud.Font)
		local width, height = surface.GetTextSize(CAF.GetLangVar("Suit"))
		if width == nil or height == nil then return end
		local top = hud.Top
		draw.DrawText(CAF.GetLangVar("Suit"), hud.Font, hud.Left + 64 - math.floor(width / 2), top, colors.White, 0)
		top = top + 16
		--Oxygen
		--top = top + 2
		draw.DrawText(CAF.GetLangVar("Air"), hud.Font2, hud.Left + 16, top, colors.White, 0)
		top = top + 16 --18
		local Air = ls_suit.o2 / MaxAmountsDivide
		top = top + 4
		draw.RoundedBox(0, hud.Left + 16, top, 8, 10, colors.Hot) -- 0 -> 10
		draw.RoundedBox(0, hud.Left + 24, top, 12, 10, colors.Warn) -- 10 -> 25
		draw.RoundedBox(0, hud.Left + 36, top, 60, 10, colors.Green) -- 25 -> 100
		surface.SetFont(hud.Font3)
		local air_text = tostring(Air) .. "%"
		width, height = surface.GetTextSize(air_text)
		draw.DrawText(air_text, hud.Font3, hud.Left + 16 + 40 - math.floor(width / 2), top, colors.White, 0) -- top +6

		--													=((8 + 12 + 60)/2)
		if Air > 100 then
			Air = 100
		end

		local air_pos = hud.Left + 16 + math.Round(Air * 0.8) --1.6
		draw.RoundedBox(0, air_pos, top - 2, 1, 10, colors.Grey)
		draw.RoundedBox(2, air_pos - 3, top - 4, 6, 6, colors.Grey)
		top = top + 8
		draw.RoundedBox(2, air_pos - 3, top, 6, 6, colors.Grey)
		top = top + 4
		--Energy
		--top = top + 2
		draw.DrawText(CAF.GetLangVar("Energy"), hud.Font2, hud.Left + 16, top, colors.White, 0)
		top = top + 16
		local Energy = ls_suit.energy / MaxAmountsDivide
		top = top + 4
		draw.RoundedBox(0, hud.Left + 16, top, 8, 10, colors.Hot) -- 0 -> 10
		draw.RoundedBox(0, hud.Left + 24, top, 12, 10, colors.Warn) -- 10 -> 25
		draw.RoundedBox(0, hud.Left + 36, top, 60, 10, colors.Green) -- 25 -> 100
		surface.SetFont(hud.Font3)
		local energy_text = tostring(Energy) .. "%"
		width, height = surface.GetTextSize(energy_text)
		draw.DrawText(energy_text, hud.Font3, hud.Left + 16 + 40 - math.floor(width / 2), top, colors.White, 0)

		if Energy > 100 then
			Energy = 100
		end

		local energy_pos = hud.Left + 16 + math.Round(Energy * 0.8)
		draw.RoundedBox(0, energy_pos, top, 1, 10, colors.Grey)
		draw.RoundedBox(2, energy_pos - 3, top - 4, 6, 6, colors.Grey)
		top = top + 8
		draw.RoundedBox(2, energy_pos - 3, top, 6, 6, colors.Grey)
		top = top + 4
		--Coolant
		--top = top + 2
		draw.DrawText(CAF.GetLangVar("Coolant"), hud.Font2, hud.Left + 16, top, colors.White, 0)
		top = top + 16
		local Coolant = ls_suit.coolant / MaxAmountsDivide
		top = top + 4
		draw.RoundedBox(0, hud.Left + 16, top, 33, 10, colors.Hot) -- 0 -> 10
		draw.RoundedBox(0, hud.Left + 24, top, 12, 10, colors.Warn) -- 10 -> 25
		draw.RoundedBox(0, hud.Left + 36, top, 60, 10, colors.Green) -- 25 -> 100
		surface.SetFont(hud.Font3)
		local coolant_text = tostring(Coolant) .. "%"
		width, height = surface.GetTextSize(coolant_text)
		draw.DrawText(coolant_text, hud.Font3, hud.Left + 16 + 40 - math.floor(width / 2), top, colors.White, 0)

		if Coolant > 100 then
			Coolant = 100
		end

		local coolant_pos = hud.Left + 16 + math.Round(Coolant * 0.8)
		draw.RoundedBox(0, coolant_pos, top, 1, 10, colors.Grey)
		draw.RoundedBox(2, coolant_pos - 3, top - 4, 6, 6, colors.Grey)
		top = top + 8
		draw.RoundedBox(2, coolant_pos - 3, top, 6, 6, colors.Grey)
		top = top + 4
		--[[
			Draw Right Side
		]]
		top = hud.Top
		draw.RoundedBox(hud.Rounding, hud.Left + hud.HalfWidth, hud.Top, hud.HalfWidth, hud.Height, colors.Black)
		surface.SetFont(hud.Font)
		width, height = surface.GetTextSize(CAF.GetLangVar("Environment"))
		draw.DrawText(CAF.GetLangVar("Environment"), hud.Font, hud.Left + hud.HalfWidth + 64 - math.floor(width / 2), top, colors.White, 0)
		top = top + 16
		--Temperature
		--top = top + 2
		draw.DrawText(CAF.GetLangVar("Temperature"), hud.Font2, hud.Left + hud.HalfWidth + 16, top, colors.White, 0)
		top = top + 16 --18
		top = top + 4
		draw.RoundedBox(0, hud.Left + hud.HalfWidth + 16, top, 32, 10, colors.Cold) -- 0 -> 273
		draw.RoundedBox(0, hud.Left + hud.HalfWidth + 16 + 32, top, 3, 10, colors.Warn) -- 273 -> 283
		draw.RoundedBox(0, hud.Left + hud.HalfWidth + 16 + 32 + 3, top, 6, 10, colors.Green) -- 283 -> 308
		draw.RoundedBox(0, hud.Left + hud.HalfWidth + 16 + 32 + 3 + 6, top, 3, 10, colors.Warn) -- 308 ->318
		draw.RoundedBox(0, hud.Left + hud.HalfWidth + 16 + 32 + 3 + 6 + 3, top, 20, 10, colors.Hot) -- 318 ->546
		surface.SetFont(hud.Font3)
		--local air_text = tostring(Air).."%"
		--width, height = surface.GetTextSize(air_text)
		--draw.DrawText( air_text, hud.Font3, hud.Left + hud.HalfWidth + 16 + 40 - math.floor(width/2) , top , colors.White,	0 ) -- top +6
		--													=((8 + 12 + 60)/2)
		local temp = ls_environment.temperature
		temp = temp - 136.5

		if temp > 444.6 then
			temp = 444.6
		elseif temp < 0 then
			temp = 0
		end

		local temp2 = (temp / 273) * 100
		local temp_pos = hud.Left + hud.HalfWidth + 16 + math.Round(temp2 * 0.8) --1.6
		draw.RoundedBox(0, temp_pos, top - 2, 1, 10, colors.Grey)
		draw.RoundedBox(2, temp_pos - 3, top - 4, 6, 6, colors.Grey)
		top = top + 8
		draw.RoundedBox(2, temp_pos - 3, top, 6, 6, colors.Grey)
		top = top + 4
		--Pressure
		--top = top + 2
		draw.DrawText(CAF.GetLangVar("Pressure"), hud.Font2, hud.Left + hud.HalfWidth + 16, top, colors.White, 0)
		top = top + 16
		local Energy = ls_suit.energy / MaxAmountsDivide
		top = top + 4
		draw.RoundedBox(0, hud.Left + 16 + hud.HalfWidth, top, 8, 10, colors.Hot) -- 0 -> 10
		draw.RoundedBox(0, hud.Left + 24 + hud.HalfWidth, top, 12, 10, colors.Warn) -- 10 -> 25
		draw.RoundedBox(0, hud.Left + 36 + hud.HalfWidth, top, 60, 10, colors.Green) -- 25 -> 100
		surface.SetFont(hud.Font3)
		local energy_text = tostring(Energy) .. "%"
		width, height = surface.GetTextSize(energy_text)
		draw.DrawText(energy_text, hud.Font3, hud.Left + hud.HalfWidth + 16 + 40 - math.floor(width / 2), top, colors.White, 0)

		if Energy > 100 then
			Energy = 100
		end

		local energy_pos = hud.Left + hud.HalfWidth + 16 + math.Round(Energy * 0.8)
		draw.RoundedBox(0, energy_pos, top, 1, 10, colors.Grey)
		draw.RoundedBox(2, energy_pos - 3, top - 4, 6, 6, colors.Grey)
		top = top + 8
		draw.RoundedBox(2, energy_pos - 3, top, 6, 6, colors.Grey)
		top = top + 4
		--Habitable
		--top = top + 2
		draw.DrawText(CAF.GetLangVar("Habitable"), hud.Font2, hud.Left + hud.HalfWidth + 16, top, colors.White, 0)
		top = top + 16
		local o2 = ls_environment.o2
		top = top + 4
		draw.RoundedBox(0, hud.Left + 16 + hud.HalfWidth, top, 4, 10, colors.Hot) -- 0 -> 5
		draw.RoundedBox(0, hud.Left + 20 + hud.HalfWidth, top, 8, 10, colors.Warn) -- 5 -> 15
		draw.RoundedBox(0, hud.Left + 28 + hud.HalfWidth, top, 68, 10, colors.Green) -- 15 -> 100
		surface.SetFont(hud.Font3)

		--local coolant_text = tostring(Coolant).."%"
		--width, height = surface.GetTextSize(coolant_text)
		--draw.DrawText( coolant_text, hud.Font3, hud.Left + hud.HalfWidth + 16 + 40 - math.floor(width/2) , top , colors.White,	0 )
		if o2 > 100 then
			o2 = 100
		end

		local hab_pos = hud.Left + hud.HalfWidth + 16 + math.Round(o2 * 0.8)
		draw.RoundedBox(0, hab_pos, top, 1, 10, colors.Grey)
		draw.RoundedBox(2, hab_pos - 3, top - 4, 6, 6, colors.Grey)
		top = top + 8
		draw.RoundedBox(2, hab_pos - 3, top, 6, 6, colors.Grey)
		top = top + 4
	else
		local hud = huds[1]
		local Temp = ls_environment.temperature
		local Air = ls_suit.o2 / MaxAmountsDivide
		local Coolant = ls_suit.coolant / MaxAmountsDivide
		local Energy = ls_suit.energy / MaxAmountsDivide

		local ValCol = {colors.White, colors.White, colors.White, colors.White}

		if Temp < FairTemp_Min then
			ValCol[1] = colors.Cold
		elseif Temp > FairTemp_Max then
			ValCol[1] = colors.Hot
		end

		if Air < 4 then
			ValCol[2] = colors.Warn
		end

		if Coolant < 4 then
			ValCol[3] = colors.Warn
		end

		if Energy < 4 then
			ValCol[4] = colors.Warn
		end

		draw.RoundedBox(8, hud.Left2, hud.H2, 180, hud.H3, colors.Black)
		local d_temp = Temp
		local d_temp_type = "K"

		if string.upper(Display_temperature:GetString()) == "C" then
			d_temp = Temp - 273
			d_temp_type = "C"
		elseif string.upper(Display_temperature:GetString()) == "F" then
			d_temp = (Temp * (9 / 5)) - 459.67
			d_temp_type = "F"
		end

		local air_time_left = math.floor(ls_suit.o2 / 5)
		local energy_time_left = math.floor(ls_suit.energy / 5)
		local coolant_time_left = math.floor(ls_suit.coolant / 5)
		draw.DrawText(CAF.GetLangVar("Temperature") .. ":", hud.Font, hud.Left, hud.TH[1], colors.White, 0)
		draw.DrawText(tostring(d_temp) .. " " .. d_temp_type, hud.Font, hud.Right, hud.TH[1], ValCol[1], 2)
		draw.DrawText(CAF.GetLangVar("Air") .. ":", hud.Font, hud.Left, hud.TH[2], colors.White, 0)
		draw.DrawText(tostring(Air) .. "% (" .. tostring(air_time_left) .. "s)", hud.Font, hud.Right, hud.TH[2], ValCol[2], 2)
		draw.DrawText(CAF.GetLangVar("Coolant") .. ":", hud.Font, hud.Left, hud.TH[3], colors.White, 0)
		draw.DrawText(tostring(Coolant) .. "% (" .. tostring(coolant_time_left) .. "s)", hud.Font, hud.Right, hud.TH[3], ValCol[3], 2)
		draw.DrawText(CAF.GetLangVar("Energy") .. ":", hud.Font, hud.Left, hud.TH[4], colors.White, 0)
		draw.DrawText(tostring(Energy) .. "% (" .. tostring(energy_time_left) .. "s)", hud.Font, hud.Right, hud.TH[4], ValCol[4], 2)
	end
end

local function LS_umsg_hook1()
	ls_environment.o2 = net.ReadFloat()
	ls_suit.o2 = net.ReadInt(32)
	ls_environment.temperature = net.ReadInt(32)
	ls_suit.coolant = net.ReadInt(32)
	ls_suit.energy = net.ReadInt(32)
end

net.Receive("LS_umsg1", LS_umsg_hook1)

local function LS_umsg_hook2()
	ls_suit.o2 = net.ReadInt(32)
end

net.Receive("LS_umsg2", LS_umsg_hook2)

--The Class
--[[
	The Constructor for this Custom Addon Class
]]
function LS.__Construct()
	hook.Add("HUDPaint", "LS_Core_HUDPaint", lifesupport_HUDPaint)

	return true
end

--[[
	Get the required Addons for this Addon Class
]]
function LS.GetRequiredAddons()
	return {"Resource Distribution"}
end

--[[
	Get the Version of this Custom Addon Class
]]
function LS.GetVersion()
	return 3.1, "Beta"
end

local isuptodatecheck

--[[
	Update check
]]
function LS.IsUpToDate(callBackfn)
	if not CAF.HasInternet then return end

	if isuptodatecheck ~= nil then
		callBackfn(isuptodatecheck)

		return
	end
end

--[[
	Gets a menu from this Custom Addon Class
]]
--Name is nil for main menu, String for others
function LS.GetMenu(menutype, menuname)
	local data = {}

	if not menutype then
		--Create Info Menu
		data["Info"] = {}
		local tmp = data["Info"]
		tmp["Wiki Home"] = {}
		tmp["Wiki Home"].localurl = "test/test.html"
		tmp["Wiki Home"].interneturl = "http://www.snakesvx.net/index.php/module_Wiki/title_Garrysmod_Info_Life_Support"
		--Create Help Menu
		data["Help"] = {}
		tmp = data["Help"]
		tmp["Wiki Home"] = {}
		tmp["Wiki Home"].localurl = "test/test.html"
		tmp["Wiki Home"].interneturl = "http://www.snakesvx.net/index.php/module_Wiki/title_Garrysmod_Info_Life_Support"
	end

	return data
end

function LS.AddResourcesToSend()
end

--[[
	Returns a table containing the Description of this addon
]]
function LS.GetDescription()
	return {"Life Support 3", "", ""}
end

CAF.RegisterAddon("Life Support", LS, "2")