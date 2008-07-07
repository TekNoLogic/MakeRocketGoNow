
----------------------
--      Locals      --
----------------------

local L = setmetatable({}, {__index=function(t,i) return i end})
local defaults, defaultsPC, db, dbpc = {}, {}
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local BUTTONSIZE, EDGE, GAP = 32, 5, 2

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
container:SetWidth(EDGE*2) container:SetHeight(BUTTONSIZE + EDGE*2)
container:SetPoint("RIGHT", UIParent, "LEFT", EDGE, 0)

container:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 16,
	insets = {left = EDGE, right = EDGE, top = EDGE, bottom = EDGE},
	tile = true, tileSize = 16,
})
container:SetBackdropColor(0.09, 0.09, 0.19, 0.5)
container:SetBackdropBorderColor(1, 1, 0.5, 0.5)


local hideelapsed = 0
local function OnUpdate(self, elapsed)
	hideelapsed = hideelapsed + elapsed
	if hideelapsed < 2 then return end

	self:ClearAllPoints()
	self:SetPoint("RIGHT", UIParent, "LEFT", EDGE, 0)
	self:SetScript("OnUpdate", nil)
end


local function containerOnEnter()
	container:SetScript("OnUpdate", nil)
	container:ClearAllPoints()
	container:SetPoint("LEFT", UIParent, "LEFT", -EDGE, 0)
end


local function containerOnLeave()
	hideelapsed = 0
	container:SetScript("OnUpdate", OnUpdate)
end


container:SetScript("OnEnter", containerOnEnter)
container:SetScript("OnLeave", containerOnLeave)


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


local function OnEnter(self, ...)
	containerOnEnter()

	if self.dataobj.OnEnter then self.dataobj.OnEnter(self, ...)
	else
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
end


local function OnLeave(self, ...)
	containerOnLeave()
	if self.dataobj.OnLeave then self.dataobj.OnLeave(self, ...)
	else GameTooltip:Hide() end
end


local function IconChanged(self, event, name, key, value, dataobj)
	self.texture:SetTexture(value)
end


local function OnClickChanged(self, event, name, key, value, dataobj)
	self:SetScript("OnClick", value)
end


local frames, lastframe = {}
function f:NewDataobject(event, name, dataobj)
	dataobj = dataobj or ldb:GetDataObjectByName(name)
	if not dataobj.launcher then return end

	local frame = CreateFrame("Button", nil, container)
	frame:SetWidth(BUTTONSIZE) frame:SetHeight(BUTTONSIZE)
	frame:SetPoint("LEFT", lastframe or container, lastframe and "RIGHT" or "LEFT", lastframe and GAP or EDGE, 0)
	container:SetWidth(container:GetWidth() + BUTTONSIZE + (lastframe and GAP or 0))
	frame.doname, frame.dataobj, frame.IconChanged, frame.OnClickChanged = name, dataobj, IconChanged, OnClickChanged

	frame:SetScript("OnEnter", OnEnter)
	frame:SetScript("OnLeave", OnLeave)
	frame:SetScript("OnClick", dataobj.OnClick)

	frame.texture = frame:CreateTexture()
	frame.texture:SetAllPoints()
	frame.texture:SetTexture(dataobj.icon)

	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_icon", "IconChanged")
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_OnClick", "OnClickChanged")

	frames[name], lastframe = frame, frame
end


for name,dataobj in ldb:DataObjectIterator() do if dataobj.launcher then f:NewDataobject(nil, name, dataobj) end end
ldb.RegisterCallback(f, "LibDataBroker_DataObjectCreated", "NewDataobject")
ldb.RegisterCallback(f, "LibDataBroker_AttributeChanged__launcher", function(event, name, key, value, dataobj)
	if value and not frames[name] then f:NewDataobject(nil, name, dataobj) end
end)
