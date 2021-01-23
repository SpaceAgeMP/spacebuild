include("shared.lua")
language.Add("nature_planet", "Plant")

function ENT:DoNormalDraw(bDontDrawModel)
	local mode = self:GetNWInt("overlaymode")

	if not bDontDrawModel then
		self:DrawModel()
	end

	local trace = LocalPlayer():GetEyeTrace()
	if not (trace.Entity == self and EyePos():Distance(self:GetPos()) < 256 and mode ~= 0) then
		return
	end

	local rd = CAF.GetAddon("Resource Distribution")
	local nettable = rd.GetEntityTable(self)
	if table.Count(nettable) <= 0 then return end
	local playername = self:GetPlayerName()

	if playername == "" then
		playername = "World"
	end

	if not mode or mode ~= 2 then
		local OverlayText = ""
		OverlayText = OverlayText .. self.PrintName .. "\n"

		if nettable.network == 0 then
			OverlayText = OverlayText .. "Not connected to a network\n"
		else
			OverlayText = OverlayText .. "Network " .. nettable.network .. "\n"
		end

		OverlayText = OverlayText .. "Owner: " .. playername .. "\n"

		if self:GetOOO() == 0 then
			OverlayText = OverlayText .. "This Plant needs water\n"
		else
			OverlayText = OverlayText .. "This plant is healthy and has " .. tostring(self:GetNWInt(1)) .. " water left\n"
		end

		OverlayText = OverlayText .. "Connected resources:\n"
		OverlayText = OverlayText .. rd.GetProperResourceName("carbon dioxide") .. ": " .. rd.GetResourceAmount(self, "carbon dioxide") .. "\n"
		OverlayText = OverlayText .. rd.GetProperResourceName("water") .. ": " .. rd.GetResourceAmount(self, "water") .. "\n"
		AddWorldTip(self:EntIndex(), OverlayText, 0.5, self:GetPos(), self)
		return
	end
	local TempY = 0
	--local pos = self:GetPos() + (self:GetForward() ) + (self:GetUp() * 40 ) + (self:GetRight())
	local pos = self:GetPos() + (self:GetUp() * (self:BoundingRadius() + 10))
	local angle = (LocalPlayer():GetPos() - trace.HitPos):Angle()
	angle.r = angle.r + 90
	angle.y = angle.y + 90
	angle.p = 0
	local textStartPos = -375
	cam.Start3D2D(pos, angle, 0.03)
	surface.SetDrawColor(0, 0, 0, 125)
	surface.DrawRect(textStartPos, 0, 1250, 500)
	surface.SetDrawColor(155, 155, 155, 255)
	surface.DrawRect(textStartPos, 0, -5, 500)
	surface.DrawRect(textStartPos, 0, 1250, -5)
	surface.DrawRect(textStartPos, 500, 1250, -5)
	surface.DrawRect(textStartPos + 1250, 0, 5, 500)
	TempY = TempY + 10
	surface.SetFont("ConflictText")
	surface.SetTextColor(255, 255, 255, 255)
	surface.SetTextPos(textStartPos + 15, TempY)
	surface.DrawText(self.PrintName)
	TempY = TempY + 70
	surface.SetFont("Flavour")
	surface.SetTextColor(155, 155, 255, 255)
	surface.SetTextPos(textStartPos + 15, TempY)
	surface.DrawText("Owner: " .. playername)
	TempY = TempY + 70
	surface.SetTextPos(textStartPos + 15, TempY)

	if nettable.network == 0 then
		surface.DrawText("Not connected to a network")
	else
		surface.DrawText("Network " .. nettable.network)
	end

	TempY = TempY + 70
	surface.SetTextPos(textStartPos + 15, TempY)

	if self:GetOOO() == 0 then
		surface.DrawText("This Plant needs water")
	else
		surface.DrawText("This plant is healthy and has " .. tostring(self:GetNWInt(1)) .. " water left")
	end

	TempY = TempY + 70
	local stringUsage = ""
	surface.SetTextPos(textStartPos + 15, TempY)
	stringUsage = stringUsage .. "[" .. rd.GetProperResourceName("water") .. ": " .. rd.GetResourceAmount(self, "water") .. "] "
	surface.DrawText(stringUsage)
	TempY = TempY + 70
	stringUsage = ""
	surface.SetTextPos(textStartPos + 15, TempY)
	stringUsage = stringUsage .. "[" .. rd.GetProperResourceName("carbon dioxide") .. ": " .. rd.GetResourceAmount(self, "carbon dioxide") .. "] "
	surface.DrawText(stringUsage)
	TempY = TempY + 70
	cam.End3D2D()
end