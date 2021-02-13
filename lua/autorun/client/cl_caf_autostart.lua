﻿local gmod_version_required = 145

if VERSION < gmod_version_required then
	error("SB CORE: Your gmod is out of date: found version ", VERSION, "required ", gmod_version_required)
end

local net = net
--Variable Declarations
local CAF2 = {}
CAF = CAF2
local CAF3 = {}
CAF2.StartingUp = false
CAF2.HasInternet = false
CAF2.InternetEnabled = true --Change this to false if you crash when CAF2 loads clientside

surface.CreateFont("GModCAFNotify", {
	font = "verdana",
	size = 15,
	weight = 600
})

--nederlands, english
local DEBUG = true
CAF3.DEBUG = DEBUG
local Addons = {}
CAF3.Addons = Addons
--Derma stuff
local MainInfoMenuData = nil
--local MainStatusMenuData = nil;
--local TopFrame = nil;
--local TopFrameHasText = false;
--local TopLabel = nil
--End Derma stuff
local addonlevel = {}
CAF3.addonlevel = addonlevel
addonlevel[1] = {}
addonlevel[2] = {}
addonlevel[3] = {}
addonlevel[4] = {}
addonlevel[5] = {}

local function ErrorOffStuff(String)
	Msg("----------------------------------------------------------------------\n")
	Msg("-----------Custom Addon Management Framework Error----------\n")
	Msg("----------------------------------------------------------------------\n")
	Msg(tostring(String) .. "\n")
end

CAF2.CAF3 = CAF3
include("caf/core/shared/sh_general_caf.lua")
CAF2.CAF3 = nil

local function OnAddonConstruct(name)
	if not name then return end

	if Addons[name] then
		local test, err = pcall(Addons[name].__Construct)

		if not test then
			CAF2.WriteToDebugFile("CAF_Construct", "Couldn't call constructor for " .. name .. " error: " .. err .. "\n")
			AddPopup(CAF.GetLangVar("Error loading Addon") .. ": " .. CAF.GetLangVar(name), "top", CAF2.colors.red)
		elseif not err then
			AddPopup(CAF.GetLangVar("An error occured when trying to enable Addon") .. ": " .. CAF.GetLangVar(name), "top", CAF2.colors.red)
		end
	end

	if not CAF2.StartingUp then
		hook.Call("CAFOnAddonConstruct", name)

		CAF2.RefreshMainMenu()
	end
end

--Global function
function CAF2.WriteToDebugFile(filename, message)
	if not filename or not message then return nil, "Missing Argument" end

	print("Filename: " .. tostring(filename) .. ", Message: " .. tostring(message))
end

function CAF2.ClearDebugFile(filename)
	if not filename then return nil, "Missing Argument" end
	local contents = file.Read("CAF_Debug/client/" .. filename .. ".txt")
	contents = contents or ""
	file.Write("CAF_Debug/client/" .. filename .. ".txt", "")
end

--Server-Client Synchronisation
function CAF2.ConstructAddon(len, client)
	local name = net.ReadString()
	OnAddonConstruct(name)
	--RunConsoleCommand("Main_CAF_Menu");
end

net.Receive("CAF_Addon_Construct", CAF2.ConstructAddon)

function CAF2.Start(len, client)
	CAF2.StartingUp = true
end

net.Receive("CAF_Start_true", CAF2.Start)

function CAF2.endStart(len, client)
	CAF2.StartingUp = false
end

net.Receive("CAF_Start_false", CAF2.endStart)
local displaypopups = {}
local popups = {}
--PopupSettings
local Font = "GModCAFNotify"
local clHudVersionCVar = GetConVar("cl_hudversion")

--End popupsettings
local function DrawPopups(w, h)
	local obj = displaypopups.top or displaypopups.left or displaypopups.right or displaypopups.bottom
	if clHudVersionCVar:GetBool() or not obj then
		return
	end
	surface.SetFont(Font)
	local width, height = surface.GetTextSize(obj.message)
	if width == nil or height == nil then return end
	width = width + 16
	height = height + 16
	left = 0
	top = 0
	if displaypopups.top then
		left = (w / 2) - (width / 2)
		top = 0
	end

	if displaypopups.left then
		left = 0
		top = h * 2 / 3
	end

	if displaypopups.right then
		left = w - width
		top = h * 2 / 3
	end

	if displaypopups.bottom then
		left = (w / 2) - (width / 2)
		top = h - height
	end

	draw.RoundedBox(4, left - 1, top - 1, width + 2, height + 2, obj.color)
	draw.RoundedBox(4, left + 1, top + 1, width, height, Color(0, 0, 0, 150))
	draw.DrawText(obj.message, Font, left + 8, top + 8, obj.color, 0)
end

hook.Add("HUDPaint", "CAF_Core_POPUPS", DrawPopups)

local locations = {"top", "left", "right", "bottom"}

--local function ShowNextTopMessage()
local function ShowNextPopupMessage()
	local ply = LocalPlayer()


	for k, v in pairs(locations) do
		if displaypopups[v] == nil and popups[v] and table.Count(popups[v]) > 0 then
			local obj = popups[v][1]
			table.remove(popups[v], 1)

			if ply and ply.ChatPrint then
				ply:ChatPrint(obj.message .. "\n")
			else
				Msg(obj.message .. "\n")
			end

			displaypopups[v] = obj

			timer.Simple(obj.time, function()
				ClearPopup(obj)
			end)
		end
	end
end

--function ClearTopTextMessage(obj)
function ClearPopup(obj)
	if obj then
		displaypopups[obj.location] = nil
	end

	if table.Count(popups[obj.location]) > 0 then
		ShowNextPopupMessage()
	end
end

local MessageLog = {}

--function AddTopInfoMessage(message)
function AddPopup(message, location, color, displaytime)

	if not popups[location] then
		popups[location] = {}
	end

	local obj = {
		message = message or "Corrupt Message",
		location = location or "top",
		time = displaytime or 1,
		color = color or CAF2.colors.white
	}

	table.insert(popups[location], obj)
	table.insert(MessageLog, obj)
	ShowNextPopupMessage()
end

local function GetHelpPanel(frame)
	local panel = vgui.Create("DPanel", frame)
	panel:StretchToParent(6, 80, 6, 6)
	local LeftTree = vgui.Create("DTree", panel)
	LeftTree:SetSize(200, panel:GetTall() - 2)
	LeftTree:SetPos(15, 1)
	local RightPanel = vgui.Create("DPanel", panel)
	RightPanel:SetSize(panel:GetWide() - 230, panel:GetTall() - 2)
	RightPanel:SetPos(220, 1)

	if not MainInfoMenuData then
		MainInfoMenuData = {}

		for k, v in pairs(Addons) do
			local content = v.GetMenu()

			if content then
				MainInfoMenuData[k] = content
			end
		end
	end

	LeftTree:Clear()

	--Fill the Tree
	for k, v in pairs(MainInfoMenuData) do
		--Addon Info
		local title = k
		local node = LeftTree:AddNode(title)

		--node.Icon:SetImage(devlist.icon)
		for l, w in pairs(v) do
			--Sub Menu's
			local Node = node:AddNode(l)

			function Node.DoClick(btn)
				if CAF2.HasInternet and w.interneturl then
					local HTMLTest = vgui.Create("HTML", RightPanel)
					HTMLTest:StretchToParent(10, 10, 10, 10)
					HTMLTest:OpenURL(w.interneturl)
				elseif w.localurl then
					local HTMLTest = vgui.Create("HTML", RightPanel)
					HTMLTest:StretchToParent(10, 10, 10, 10)
					HTMLTest:SetHTML(file.Read(w.localurl))
				end
			end

			for m, x in pairs(w) do
				--Links in submenu
				local cnode = Node:AddNode(m)

				function cnode.DoClick(btn)
					if CAF2.HasInternet and x.interneturl then
						RightPanel:Clear()
						local HTMLTest = vgui.Create("HTML", RightPanel)
						HTMLTest:StretchToParent(10, 10, 10, 10)
						HTMLTest:OpenURL(x.interneturl)
					elseif x.localurl then
						RightPanel:Clear()
						local HTMLTest = vgui.Create("HTML", RightPanel)
						HTMLTest:StretchToParent(10, 10, 10, 10)
						HTMLTest:SetHTML(file.Read(x.localurl))
					end
				end
			end
		end
	end

	return panel
end

function CAF2.Notice(message, title)
	if not message then return false end

	if not title then
		title = "Notice"
	end

	local dfpopup = vgui.Create("DFrame")
	dfpopup:SetDeleteOnClose()
	dfpopup:SetDraggable(false)
	dfpopup:SetTitle(title)
	local lbl = vgui.Create("DLabel", dfpopup)
	lbl:SetPos(10, 25)
	lbl:SetText(message)
	lbl:SizeToContents()
	dfpopup:SetSize(lbl:GetWide() + 4, lbl:GetTall() + 25)
	dfpopup:Center()
	dfpopup:MakePopup()

	return true
end

local function GetClientMenu(contentpanel)
	--Create clientside menu here => Language settings, ...
	local panel = vgui.Create("DPanel", contentpanel)
	local x = 10
	local y = 0
	--Title
	local lblTitle = vgui.Create("DLabel", panel)
	lblTitle:SetText(CAF2.GetLangVar("Clientside CAF Options"))
	lblTitle:SizeToContents()
	lblTitle:SetPos(x, y)
	y = y + 35
	x = x - lbl:GetWide() - 5
	--Other options here]]
	panel:SetSize(contentpanel:GetWide(), y + 10)

	return panel
end

local function AddCAFInfoToStatus(List)
	local descriptiontxt = nil

	if GetDescription then
		descriptiontxt = GetDescription()
	end

	local cafAddon = {}

	function cafAddon.GetVersion()
		return CAF2.version, "Core"
	end

	function cafAddon.CanChangeStatus()
		return false
	end

	function cafAddon.GetDisplayImage()
		--Change to something else later on?
		return "icon16/application.png"
	end

	local cat = vgui.Create("DCAFCollapsibleCategory")
	cat:Setup("Custom Addon Framework", cafAddon)
	--cat:SetExtraButtonAction(function() frame:Close()  end)
	local contentpanel = vgui.Create("DPanelList", cat)
	contentpanel:SetWide(List:GetWide())
	local clientMenu = nil

	if GetClientMenu then
		clientMenu = GetClientMenu(contentpanel)
	end

	local serverMenu = nil

	if GetServerMenu then
		serverMenu = GetServerMenu(contentpanel)
	end

	--Start Add Custom Stuff
	local x = 0
	local y = 0
	--Version Check
	local versionupdatetext = vgui.Create("DLabel", contentpanel)
	versionupdatetext:SetPos(x + 10, y)
	versionupdatetext:SetText(CAF.GetLangVar("No Update Information Available"))
	versionupdatetext:SetTextColor(Color(200, 200, 0, 200))
	versionupdatetext:SizeToContents()
	y = y + 30

	--ServerMenu
	if serverMenu then
		serverMenu:SetPos(x, y)
		y = y + serverMenu:GetTall() + 15
	end

	--Clientside menu
	if clientMenu then
		clientMenu:SetPos(x, y)
		y = y + clientMenu:GetTall() + 15
	end

	--Description
	if descriptiontxt ~= nil then
		local list = vgui.Create("DPanelList", contentpanel)
		list:SetPos(x, y)
		local size = 1
		list:SetPadding(10)
		--Description Blank Line
		lab = vgui.Create("DLabel", list)
		lab:SetText(CAF.GetLangVar("Description") .. ":")
		lab:SizeToContents()
		list:AddItem(lab)
		size = size + 1

		--Description
		for k, v in pairs(descriptiontxt) do
			lab = vgui.Create("DLabel", list)
			lab:SetText(v)
			lab:SizeToContents()
			list:AddItem(lab)
			size = size + 1
		end

		list:SetSize(List:GetWide() - 10, 15 * size)
		contentpanel:SizeToContents()
		y = y + (15 * size) + 15
	end

	contentpanel:SetTall(y)
	--End Add Custom Stuff
	cat:SetContents(contentpanel)
	cat:SizeToContents()
	cat:InvalidateLayout()
	cat:SetExpanded(true)
	List:AddItem(cat)
end

local function GetStatusPanel(frame)
	local panel = vgui.Create("DPanel", frame)
	panel:StretchToParent(6, 36, 6, 6)
	local List = vgui.Create("DPanelList", panel)
	List:EnableHorizontal(false)
	List:EnableVerticalScrollbar(true)
	List:SetPadding(5)
	List:SetSpacing(5)
	List:StretchToParent(2, 2, 2, 2)
	List:SetPos(2, 2)

	AddCAFInfoToStatus(List)

	for addonName, addon in pairs(Addons) do
		if not addon.IsVisible or not addon.IsVisible() then
			continue
		end
		local descriptiontxt = nil

		if addon.GetDescription then
			descriptiontxt = addon.GetDescription()
			--else
			--	descriptiontxt = {CAF.GetLangVar("No Description")};
		end

		local cat = vgui.Create("DCAFCollapsibleCategory")
		cat:Setup(addonName, addon)
		--cat:SetExtraButtonAction(function() frame:Close()  end)
		local contentpanel = vgui.Create("DPanelList", cat)
		contentpanel:SetWide(List:GetWide())
		local clientMenu = nil

		if addon.GetClientMenu then
			clientMenu = addon.GetClientMenu(contentpanel)
		end

		local serverMenu = nil

		if addon.GetServerMenu then
			serverMenu = addon.GetServerMenu(contentpanel)
		end

		--Start Add Custom Stuff
		local x = 0
		local y = 0
		--Version Check
		local versionupdatetext = vgui.Create("DLabel", contentpanel)
		versionupdatetext:SetPos(x + 10, y)
		versionupdatetext:SetText(CAF.GetLangVar("No Update Information Available"))
		versionupdatetext:SetTextColor(Color(200, 200, 0, 200))
		versionupdatetext:SizeToContents()
		y = y + 30

		--ServerMenu
		if serverMenu then
			serverMenu:SetPos(x, y)
			y = y + serverMenu:GetTall() + 15
		end

		--Clientside menu
		if clientMenu then
			clientMenu:SetPos(x, y)
			y = y + clientMenu:GetTall() + 15
		end

		--Description
		if descriptiontxt ~= nil then
			local list = vgui.Create("DPanelList", contentpanel)
			list:SetPos(x, y)
			local size = 1
			list:SetPadding(10)
			--Description Blank Line
			lab = vgui.Create("DLabel", list)
			lab:SetText(CAF.GetLangVar("Description") .. ":")
			lab:SizeToContents()
			list:AddItem(lab)
			size = size + 1

			--Description
			for k, v in pairs(descriptiontxt) do
				lab = vgui.Create("DLabel", list)
				lab:SetText(v)
				lab:SizeToContents()
				list:AddItem(lab)
				size = size + 1
			end

			list:SetSize(List:GetWide() - 10, 15 * size)
			contentpanel:SizeToContents()
			y = y + (15 * size) + 15
		end

		contentpanel:SetTall(y)
		--End Add Custom Stuff
		cat:SetContents(contentpanel)
		cat:SizeToContents()
		cat:InvalidateLayout()

		cat:SetExpanded(false)
		--end
		List:AddItem(cat)
	end

	return panel
end

function GetMessageLogPanel(frame)
	--TODO Create it
	local panel = vgui.Create("DPanel", frame)
	panel:StretchToParent(6, 36, 6, 6)
	local mylist = vgui.Create("DListView", panel)
	mylist:SetMultiSelect(false)
	mylist:SetPos(1, 1)
	mylist:StretchToParent(2, 2, 2, 2) --SetSize(panel:GetWide()- 2, panel:GetTall()-2)
	local colum = mylist:AddColumn("Time")
	colum:SetFixedWidth(math.Round(mylist:GetWide() * (0.5 / 5)))
	colum = mylist:AddColumn("Location")
	colum:SetFixedWidth(math.Round(mylist:GetWide() * (0.5 / 5)))
	colum = mylist:AddColumn("Message")
	colum:SetFixedWidth(math.Round(mylist:GetWide() * (4 / 5)))

	for k, v in pairs(MessageLog) do
		local line = mylist:AddLine(CurTime(), v.location, v.message)
		line.Columns[3]:SetTextColor(v.color)
	end

	return panel
end

local function GetServerSettingsPanel(frame)
	local panel = vgui.Create("DPanel", frame)
	panel:StretchToParent(6, 36, 6, 6)

	return panel
end

local function GetAboutPanel(frame)
	local panel = vgui.Create("DPanel", frame)
	panel:StretchToParent(6, 36, 6, 6)
	--
	local mylist = vgui.Create("DListView", panel)
	mylist:SetMultiSelect(false)
	mylist:SetPos(1, 1)
	mylist:SetSize(panel:GetWide() - 2, panel:GetTall() - 2)
	local colum = mylist:AddColumn("")
	colum:SetFixedWidth(5)
	local colum1 = mylist:AddColumn("About")
	colum1:SetFixedWidth(mylist:GetWide() - 5)
	mylist.SortByColumn = function() end
	----------
	--Text--
	----------
	mylist:AddLine("", "Custom Addon Framework")
	mylist:AddLine("", "More info to be added")
	mylist:AddLine("", "")
	mylist:AddLine("", "Made By SnakeSVx")
	--

	return panel
end

local MainFrame = nil

function CAF2.CloseMainMenu()
	if MainFrame then
		MainFrame:Close()
	end
end

function CAF2.RefreshMainMenu()
	if MainFrame then
		CAF2.OpenMainMenu()
	end
end

function CAF2.OpenMainMenu()
	CAF2.CloseMainMenu()
	MainFrame = vgui.Create("DFrame")
	MainFrame:SetDeleteOnClose()
	MainFrame:SetDraggable(false)
	MainFrame:SetTitle("Custom Addon Framework Main Menu")
	MainFrame:SetSize(ScrW() * 0.8, ScrH() * 0.9)
	MainFrame:Center()
	local ContentPanel = vgui.Create("DPropertySheet", MainFrame)
	ContentPanel:Dock(FILL)
	ContentPanel:AddSheet(CAF.GetLangVar("Installed Addons"), GetStatusPanel(ContentPanel), "icon16/application.png", true, true)
	ContentPanel:AddSheet(CAF.GetLangVar("Info and Help"), GetHelpPanel(ContentPanel), "icon16/box.png", true, true)

	if LocalPlayer():IsAdmin() then
		ContentPanel:AddSheet(CAF.GetLangVar("Server Settings"), GetServerSettingsPanel(ContentPanel), "icon16/wrench.png", true, true)
	end

	ContentPanel:AddSheet(CAF.GetLangVar("Message Log"), GetMessageLogPanel(ContentPanel), "icon16/wrench.png", true, true)
	ContentPanel:AddSheet(CAF.GetLangVar("About"), GetAboutPanel(ContentPanel), "icon16/group.png", true, true)
	MainFrame:MakePopup()
end

concommand.Add("Main_CAF_Menu", CAF2.OpenMainMenu)

--Panel
local function BuildMenu(Panel)
	Panel:ClearControls()

	Panel:AddControl("Header", {
		Text = "Custom Addon Framework",
		Description = "Custom Addon Framework"
	})

	Panel:AddControl("Button", {
		Label = "Open Menu",
		Text = "Custom Addon Framework",
		Command = "Main_CAF_Menu"
	})
end

local function CreateMenu()
	spawnmenu.AddToolMenuOption("Custom Addon Framework", "Custom Addon Framework", "MainInfoMenu", "Main Info Menu", "", "", BuildMenu, {})
end

hook.Add("PopulateToolMenu", "Caf_OpenMenu_AddMenu", CreateMenu)

function CAF2.POPUP(msg, location, color, displaytime)
	if msg then
		AddPopup(msg, location, color, displaytime)
	end
end

local function ProccessMessage(len, client)
	local msg = net.ReadString()
	local location = net.ReadString()
	local color = net.ReadColor()
	local displaytime = net.ReadUInt(16)
	CAF2.POPUP(msg, location, color, displaytime)
end

net.Receive("CAF_Addon_POPUP", ProccessMessage)
--CAF = CAF2
--Include clientside files
--Core
local coreFiles = file.Find("caf/core/client/*.lua", "LUA")

for k, File in ipairs(coreFiles) do
	local ErrorCheck, PCallError = pcall(include, "caf/core/client/" .. File)

	if not ErrorCheck then
		ErrorOffStuff(PCallError)
	end
end

local languageFiles = file.Find("caf/languagevars/*.lua", "LUA")

for k, File in ipairs(languageFiles) do
	local ErrorCheck, PCallError = pcall(include, "caf/languagevars/" .. File)

	if not ErrorCheck then
		ErrorOffStuff(PCallError)
	end
end

--Addons
local addonFiles = file.Find("caf/addons/client/*.lua", "LUA")

for k, File in ipairs(addonFiles) do
	local ErrorCheck, PCallError = pcall(include, "caf/addons/client/" .. File)

	if not ErrorCheck then
		ErrorOffStuff(PCallError)
	end
end

hook.Add("InitPostEntity", "InitPostEntity_FullLoad", function()
	net.Start("CAF_PlayerFullLoad")
	net.SendToServer()
end)
