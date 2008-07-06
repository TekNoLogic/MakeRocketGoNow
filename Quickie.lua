
----------------------
--      Locals      --
----------------------

local L = setmetatable({}, {__index=function(t,i) return i end})
local defaults, defaultsPC, db, dbpc = {}, {}
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")


------------------------------
--      Util Functions      --
------------------------------

local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99Quickie|r:", ...)) end

local debugf = tekDebug and tekDebug:GetFrame("Quickie")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end


-----------------------------
--      Event Handler      --
-----------------------------

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")


function f:ADDON_LOADED(event, addon)
	if addon ~= "AddonTemplate" then return end

	AddonTemplateDB, QuickieDBPC = setmetatable(QuickieDB or {}, {__index = defaults}), setmetatable(QuickieDBPC or {}, {__index = defaultsPC})
	db, dbpc = QuickieDB, QuickieDBPC

	-- Do anything you need to do after addon has loaded

	LibStub("tekKonfig-AboutPanel").new("Quickie", "Quickie") -- Remove first arg if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end


function f:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_LOGOUT")

	-- Do anything you need to do after the player has entered the world

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


function f:PLAYER_LOGOUT()
	for i,v in pairs(defaults) do if db[i] == v then db[i] = nil end end
	for i,v in pairs(defaultsPC) do if dbpc[i] == v then dbpc[i] = nil end end

	-- Do anything you need to do as the player logs out
end


-----------------------------
--      Slash Handler      --
-----------------------------

SLASH_QUICKIE1 = "/quickie"
SlashCmdList.QUICKIE = function(msg)
	-- Do crap here
end


-------------------------------
--      Container frame      --
-------------------------------

local container = CreateFrame("Button", nil, UIParent)
container:SetWidth(40) container:SetHeight(32+5+5)
container:SetPoint("RIGHT", UIParent, "LEFT", 5, 0)

container:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 16,
	insets = {left = 5, right = 5, top = 5, bottom = 5},
	tile = true, tileSize = 16,
})
container:SetBackdropColor(0.09, 0.09, 0.19, 0.5)
container:SetBackdropBorderColor(1, 1, 0.5, 0.5)

container:SetScript("OnEnter", function(self)
	self:ClearAllPoints()
	self:SetPoint("LEFT", UIParent, "LEFT", -5, 0)
end)

container:SetScript("OnLeave", function(self)
	self:ClearAllPoints()
	self:SetPoint("RIGHT", UIParent, "LEFT", 5, 0)
end)


-----------------------------
--      Block factory      --
-----------------------------

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end


local function OnEnter(self)
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	local name, title, notes = GetAddOnInfo(self.dataobj.tocname or self.doname)
	if name then
		GameTooltip:AddLine(title or name)
		GameTooltip:AddLine(notes)
	else
		GameTooltip:AddLine(self.dataobj.label or self.doname)
	end

	GameTooltip:Show()
end


local function OnLeave() GameTooltip:Hide() end


function f:NewDataobject(event, name, dataobj)
	dataobj = dataobj or ldb:GetDataObjectByName(name)
	if not dataobj.launcher then return end

	local frame = CreateFrame("Button", nil, UIParent)
	frame:SetWidth(32) frame:SetHeight(32)
	frame:SetPoint("TOPLEFT", 100, -100)
	frame.doname, frame.dataobj = name, dataobj

	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = {left = 5, right = 5, top = 5, bottom = 5},
		tile = true, tileSize = 16,
	})

	frame:SetScript("OnEnter", dataobj.OnEnter or OnEnter)
	frame:SetScript("OnLeave", dataobj.OnLeave or OnLeave)
	frame:SetScript("OnClick", dataobj.OnClick)

	frame.texture = frame:CreateTexture()
	frame.texture:SetAllPoints()
	frame.texture:SetTexture(dataobj.icon)

--~ 	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..dataobjname.."_text", "TextUpdate")
end

ldb.RegisterCallback(f, "LibDataBroker_DataObjectCreated", "NewDataobject")
