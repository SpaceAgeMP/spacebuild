local PANEL = {}

function PANEL:Init()
	self.Name = vgui.Create("DLabel", self)
	self.Name:SetPos(72, 5)
	self.Version = vgui.Create("DLabel", self)
	self.Version:SetPos(72, 22)
	self.Status = vgui.Create("DLabel", self)
	self.Status:SetPos(72, 39)
	self.Button = vgui.Create("DButton", self)
	self.Button:SetPos(72, 56)
	self:SetText("Show More")
end

function PANEL:PerformLayout(w)
	self.Name:SetSize(w - 60, 15)
	self.Status:SetSize(w - 60, 15)
	self.Version:SetSize(w - 60, 15)
	self.Button:SetSize(w - 120, 15)
	self:SetTall(72)
end

function PANEL:Setup(name, addon)
	local statustext = "Disabled"
	self.Status:SetTextColor(Color(255, 0, 0, 200))
	self.Button:SetText("Enable")

	function self.Button:DoClick()
		RunConsoleCommand("CAF_Addon_Construct", name)
	end

	local customstatus = ""
	local version = "0"
	local stringversion = "UnSpecified"

	if addon.GetVersion then
		version, stringversion = addon.GetVersion()
	end

	if addon.GetCustomStatus then
		customstatus = addon.GetCustomStatus()
	end

	self.Name:SetText(name)
	local statusstring = tostring(statustext)

	if customstatus and customstatus ~= "" then
		statusstring = statusstring .. " (" .. tostring(customstatus) .. ")"
	end

	self.Status:SetText(statusstring)
	self.Version:SetText("Version:" .. tostring(version) .. " (" .. tostring(stringversion) .. ")")

	if not LocalPlayer():IsAdmin() or (addon.CanChangeStatus and not addon.CanChangeStatus()) then
		self.Button:SetVisible(false)
	end

	local image = "icon16/application.png"

	if addon.GetDisplayImage then
		image = addon.GetDisplayImage()
	end

	if image then
		self.Material = Material(image)
	end
end

function PANEL:Paint(w, h)
	if not self.Material then return end
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(self.Material)
	surface.DrawTexturedRect(4, 4, 56, 56)
end

function PANEL:OnMousePressed(mcode)
	if mcode == MOUSE_LEFT then
		self:GetParent():Toggle()

		return
	end

	return self:GetParent():OnMousePressed(mcode)
end

derma.DefineControl("DCAFCategoryHeader", "CAF Category Header", PANEL, "DButton")

PANEL = {}
AccessorFunc(PANEL, "m_bSizeExpanded", "Expanded", FORCE_BOOL)
AccessorFunc(PANEL, "m_iContentHeight", "StartHeight")
AccessorFunc(PANEL, "m_fAnimTime", "AnimTime")
AccessorFunc(PANEL, "m_bDrawBackground", "DrawBackground", FORCE_BOOL)
AccessorFunc(PANEL, "m_iPadding", "Padding")

function PANEL:Setup(name, addon)
	self.Header:Setup(name, addon)
end

function PANEL:Init()
	self.Header = vgui.Create("DCAFCategoryHeader", self)
	self:SetExpanded(true)
	self:SetMouseInputEnabled(true)
	self:SetAnimTime(0.2)
	self.animSlide = Derma_Anim("Anim", self, self.AnimSlide)
	self:SetPaintBackgroundEnabled(true)
end

function PANEL:Think()
	self.animSlide:Run()
end

function PANEL:GetHeaderHeight()
	return self.Header:GetTall()
end

function PANEL:Paint(w, h)
	derma.SkinHook("Paint", "CollapsibleCategory", self, w, h)

	return false
end

function PANEL:SetContents(pContents)
	self.Contents = pContents
	self.Contents:SetParent(self)
	self:InvalidateLayout()
end

function PANEL:Toggle()
	self:SetExpanded(not self:GetExpanded())

	self.animSlide:Start(self:GetAnimTime(), {
		From = self:GetTall()
	})

	self:InvalidateLayout(true)
	self:GetParent():InvalidateLayout()
	self:GetParent():GetParent():InvalidateLayout()
	local cookie = '1'

	if not self:GetExpanded() then
		cookie = '0'
	end

	self:SetCookie("Open", cookie)
end

function PANEL:PerformLayout(w, h)
	local Padding = self:GetPadding() or 0
	self.Header:SetPos(0, 0)
	self.Header:SetWide(w)

	if self.Contents then
		if self:GetExpanded() then
			self.Contents:SetPos(Padding, self.Header:GetTall() + Padding)
			self.Contents:SetWide(w - Padding * 2)
			self.Contents:InvalidateLayout(true)
			self.Contents:SetVisible(true)
			self:SetTall(self.Contents:GetTall() + self.Header:GetTall() + Padding * 2)
		else
			self.Contents:SetVisible(false)
			self:SetTall(self.Header:GetTall())
		end
	end

	-- Make sure the color of header text is set
	self.Header:ApplySchemeSettings()
	self.animSlide:Run()
end

function PANEL:OnMousePressed(mcode)
	if not self:GetParent().OnMousePressed then return end

	return self:GetParent():OnMousePressed(mcode)
end

function PANEL:AnimSlide(anim, delta, data)
	if anim.Started then
		data.To = self:GetTall()
	end

	if anim.Finished then
		self:InvalidateLayout()

		return
	end

	if self.Contents then
		self.Contents:SetVisible(true)
	end

	self:SetTall(Lerp(delta, data.From, data.To))
	self:GetParent():InvalidateLayout()
	self:GetParent():GetParent():InvalidateLayout()
end

function PANEL:LoadCookies()
	local Open = self:GetCookieNumber("Open", 1) == 1
	self:SetExpanded(Open)
	self:InvalidateLayout(true)
	self:GetParent():InvalidateLayout()
	self:GetParent():GetParent():InvalidateLayout()
end

function PANEL:GenerateExample(ClassName, PropertySheet, Width, Height)
	local ctrl = vgui.Create(ClassName)
	ctrl:SetLabel("Category List Test Category")
	ctrl:SetSize(300, 300)
	ctrl:SetPadding(10)
	-- The contents can be any panel, even a DPanelList
	local Contents = vgui.Create("DButton")
	Contents:SetText("This is the content of the control")
	ctrl:SetContents(Contents)
	ctrl:InvalidateLayout(true)
	PropertySheet:AddSheet(ClassName, ctrl, nil, true, true)
end

derma.DefineControl("DCAFCollapsibleCategory", "CAF Collapsable Category Panel", PANEL, "Panel")