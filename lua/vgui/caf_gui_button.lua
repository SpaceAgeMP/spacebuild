local PANEL = {}

function PANEL:Init()
	self.SpawnButton = vgui.Create("Button", self)
end

function PANEL:PerformLayout(w, h)
	local Border = 3
	self.SpawnButton:SizeToContents()
	self.SpawnButton:SetSize(w - Border * 2, self.SpawnButton:GetTall() - Border + 6)
	--self.SpawnButton:SetSize( self:GetWide() - Border * 2, 24 - Border )
	self.SpawnButton:SetPos(Border, Border)
	-- TODO: This usually triggers a perform layout, infinite loop??
	-- self:SetSize(w, self.SpawnButton:GetTall() + Border * 2)
end

function PANEL:SetCommands(toolname, name, model, type, num)
	self.toolname = toolname
	self.name = name
	self.num = tostring(num)
	self.SpawnButton:SetText(name)

	self.SpawnButton.DoClick = function()
		LocalPlayer():ConCommand(toolname .. "_name " .. num .. "\n" .. toolname .. "_model " .. model .. "\n" .. toolname .. "_type " .. type .. "\n")
	end

	self:InvalidateLayout()
end

local bgColor = Color(50, 50, 255, 250)

function PANEL:Paint(w, h)
	if LocalPlayer():GetInfo(self.toolname .. "_name") == self.num then
		draw.RoundedBox(4, 0, 0, w, h, bgColor)
	end

	return false
end

vgui.Register("CAFButton", PANEL, "Panel")