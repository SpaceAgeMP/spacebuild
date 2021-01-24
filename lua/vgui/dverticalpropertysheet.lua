local PANEL = {}
Derma_Hook(PANEL, "Paint", "Paint", "PropertySheet")
AccessorFunc(PANEL, "m_bBackground", "DrawBackground")
AccessorFunc(PANEL, "m_pActiveTab", "ActiveTab")
AccessorFunc(PANEL, "m_iPadding", "Padding")
AccessorFunc(PANEL, "m_fFadeTime", "FadeTime")
AccessorFunc(PANEL, "m_bShowIcons", "ShowIcons")

function PANEL:Init()
	self:SetShowIcons(true)
	self.leftPanel = vgui.Create("DPanel", self)
	self.leftPanel:SetPos(0, 10)
	self.rightPanel = vgui.Create("DPanel", self)
	self.rightPanel:SetPos(101, 10)
	self.tabScroller = vgui.Create("DVerticalScroller", self.leftPanel)
	self.tabScroller:SetOverlap(2)
	self:SetFadeTime(0.1)
	self:SetPadding(5)
	self.animFade = Derma_Anim("Fade", self, self.CrossFade)
	self.Items = {}
end

function PANEL:AddSheet(label, panel, material, NoStretchX, NoStretchY, Tooltip)
	if (not IsValid(panel)) then return end
	local Sheet = {}
	Sheet.Tab = vgui.Create("DTab", self.leftPanel)
	Sheet.Tab:SetTooltip(Tooltip)
	Sheet.Tab:Setup(label, self, panel, material)
	Sheet.Panel = panel
	Sheet.Panel.NoStretchX = NoStretchX
	Sheet.Panel.NoStretchY = NoStretchY
	panel:SetParent(self.rightPanel)
	table.insert(self.Items, Sheet)

	if (not self:GetActiveTab()) then
		self:SetActiveTab(Sheet.Tab)
	end

	self.tabScroller:AddPanel(Sheet.Tab)
end

function PANEL:SetActiveTab(active)
	if (self.m_pActiveTab == active) then return end

	if (self.m_pActiveTab) then
		self.animFade:Start(self:GetFadeTime(), {
			OldTab = self.m_pActiveTab,
			NewTab = active
		})
	end

	self.m_pActiveTab = active
	self:InvalidateLayout()
end

function PANEL:Think()
	self.animFade:Run()
end

function PANEL:CrossFade(anim, delta, data)
	local old = data.OldTab:GetPanel()
	local new = data.NewTab:GetPanel()

	if (anim.Finished) then
		old:SetVisible(false)
		new:SetAlpha(255)
		old:SetZPos(0)
		new:SetZPos(0)

		return
	end

	if (anim.Started) then
		old:SetZPos(0)
		new:SetZPos(1)
		old:SetAlpha(255)
		new:SetAlpha(0)
	end

	old:SetVisible(true)
	new:SetVisible(true)
	new:SetAlpha(255 * delta)
end

function PANEL:PerformLayout(w, h)
	local ActiveTab = self:GetActiveTab()
	local Padding = self:GetPadding()
	self.leftPanel:InvalidateLayout(true)
	self.rightPanel:InvalidateLayout(true)
	if (not ActiveTab) then return end
	-- Update size now, so the height is definitiely right.
	ActiveTab:InvalidateLayout(true)
	self.tabScroller:StretchToParent(4, 4, 4, 4)
	self.tabScroller:SetWide(100)
	self.tabScroller:InvalidateLayout(true)

	for k, v in pairs(self.Items) do
		v.Tab:GetPanel():SetVisible(false)
		v.Tab:SetZPos(100 - k)
		v.Tab:SetWide(100)
		v.Tab:ApplySchemeSettings()
	end

	self.leftPanel:SetSize(100, h)
	self.rightPanel:SetTall(w - 101, h)
	self.tabScroller:SetTall(h - 10)

	if (ActiveTab) then
		local ActivePanel = ActiveTab:GetPanel()
		ActivePanel:SetVisible(true)
		ActivePanel:SetPos(Padding, Padding * 2)

		if (not ActivePanel.NoStretchX) then
			ActivePanel:SetWide(self.rightPanel:GetWide() - Padding * 2)
		else
			ActivePanel:CenterHorizontal()
		end

		if (not ActivePanel.NoStretchY) then
			ActivePanel:SetTall(self.rightPanel:GetTall() - Padding * 2)
		else
			ActivePanel:CenterVertical()
		end

		ActivePanel:InvalidateLayout()
		ActiveTab:SetZPos(100)
	end

	-- Give the animation a chance
	self.animFade:Run()
end

function PANEL:SizeToContentWidth()
	local tall = 0

	for k, v in pairs(self.Items) do
		if (v.Panel) then
			v.Panel:InvalidateLayout(true)
			tall = math.max(tall, v.Panel:GetTall() + self.m_iPadding * 2) --math.max( wide, v.Panel:GetWide()  + self.m_iPadding * 2 )
		end
	end

	self:SetTall(tall)
end

derma.DefineControl("DVerticalPropertySheet", "", PANEL, "Panel")