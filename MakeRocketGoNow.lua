
----------------------
--      Locals      --
----------------------

local L = setmetatable({}, {__index=function(t,i) return i end})
local defaults, defaultsPC, db, dbpc = {}, {}
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local NUM_BUTTONS_WIDE, BUTTONSIZE, EDGE, GAP = 12, 32, 5, 2


------------------------------
--      Util Functions      --
------------------------------

local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99MakeRocketGoNow|r:", ...)) end

local debugf = tekDebug and tekDebug:GetFrame("MakeRocketGoNow")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end


------------------------
--      LDB feed      --
------------------------

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("MakeRocketGoNow", {
	type = "data source",
	text = "Rocket",
	icon = "Interface\\Icons\\Ability_Mount_RocketMount",
})


-------------------------------
--      Container frame      --
-------------------------------

local container = CreateFrame("Button", nil, UIParent)
container:SetWidth(EDGE*2) container:SetHeight(BUTTONSIZE + EDGE*2)
container:Hide()

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

	container:SetScript("OnUpdate", nil)
	self:Hide()
end


local function containerOnEnter()
	container:SetScript("OnUpdate", nil)
end


local function containerOnLeave()
	hideelapsed = 0
	container:SetScript("OnUpdate", OnUpdate)
end


container:SetScript("OnEnter", containerOnEnter)
container:SetScript("OnLeave", containerOnLeave)


local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end


function dataobj:OnClick()
	containerOnLeave()
	container:ClearAllPoints()
	container:SetPoint(GetTipAnchor(self))
	container:Show()
end


-----------------------------
--      Block factory      --
-----------------------------

local function OnEnter(self, ...)
	containerOnEnter()

	if self.dataobj.OnEnter then self.dataobj.OnEnter(self, ...)
	else
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetPoint(GetTipAnchor(self))
		GameTooltip:ClearLines()

		if self.dataobj.OnTooltipShow then
			self.dataobj.OnTooltipShow(GameTooltip)
		else
			local name, title, notes, _, _, reason  = GetAddOnInfo(self.dataobj.tocname or self.doname)
			if reason == "MISSING" then
				GameTooltip:AddLine(self.dataobj.label or self.doname)
			else
				GameTooltip:AddLine(title or name)
				GameTooltip:AddLine(notes, 1, 1, 1)
			end
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


local function TexCoordChanged(self, event, name, key, value, dataobj)
	if value then self.texture:SetTexCoord(unpack(dataobj.texcoord))
	else self.texture:SetTexCoord(0,1,0,1) end
end


local function OnClickChanged(self, event, name, key, value, dataobj)
	self:SetScript("OnClick", value)
end


local framenames, frames, lastframe = {}, {}
local function Reanchor()
	for name,frame in pairs(frames) do frame:ClearAllPoints() end
	table.sort(framenames)

	local lastframe, lastrow
	for i,name in ipairs(framenames) do
		local frame = frames[name]
		if i == 1 then
			frame:SetPoint("TOPLEFT", container, "TOPLEFT", EDGE, -EDGE)
			lastrow = frame
		elseif i % NUM_BUTTONS_WIDE == 1 then
			frame:SetPoint("TOPLEFT", lastrow, "BOTTOMLEFT", 0, -GAP)
			lastrow = frame
		else
			frame:SetPoint("LEFT", lastframe, "RIGHT", GAP, 0)
		end

		local numbutts = #framenames
		if numbutts < NUM_BUTTONS_WIDE then
			container:SetWidth(EDGE*2 + numbutts*BUTTONSIZE + (numbutts-1)*GAP)
		else
			container:SetWidth(EDGE*2 + NUM_BUTTONS_WIDE*BUTTONSIZE + (NUM_BUTTONS_WIDE-1)*GAP)
		end

		local numrows = math.ceil(numbutts/NUM_BUTTONS_WIDE)
		container:SetHeight(numrows*BUTTONSIZE + (numrows-1)*GAP + EDGE*2)

		lastframe = frame
	end
end


function container:NewDataobject(event, name, dataobj)
	dataobj = dataobj or ldb:GetDataObjectByName(name)
	if dataobj.type ~= "launcher" then return end

	local frame = CreateFrame("Button", nil, container)
	frame:SetWidth(BUTTONSIZE) frame:SetHeight(BUTTONSIZE)
	table.insert(framenames, name)
	frames[name] = frame
	Reanchor()

	frame.doname, frame.dataobj, frame.IconChanged, frame.OnClickChanged, frame.TexCoordChanged = name, dataobj, IconChanged, OnClickChanged, TexCoordChanged

	frame:SetScript("OnEnter", OnEnter)
	frame:SetScript("OnLeave", OnLeave)
	frame:SetScript("OnClick", dataobj.OnClick)
	frame:RegisterForClicks("anyUp")

	frame.texture = frame:CreateTexture()
	frame.texture:SetAllPoints()
	frame.texture:SetTexture(dataobj.icon)
	if dataobj.texcoord then frame.texture:SetTexCoord(unpack(dataobj.texcoord)) end

	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_icon", "IconChanged")
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_texcoord", "TexCoordChanged")
	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..name.."_OnClick", "OnClickChanged")
end


for name,dataobj in ldb:DataObjectIterator() do if dataobj.type == "launcher" then container:NewDataobject(nil, name, dataobj) end end
ldb.RegisterCallback(container, "LibDataBroker_DataObjectCreated", "NewDataobject")


---------------------------
--      About panel      --
---------------------------

local about = LibStub("tekKonfig-AboutPanel").new(nil, "MakeRocketGoNow")


----------------------------------------
--      Quicklaunch registration      --
----------------------------------------

LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("MakeRocketGoNowLauncher", {
	type = "launcher",
	tocname= "MakeRocketGoNow",
	icon = "Interface\\Icons\\Ability_Mount_RocketMount",
	OnClick = function() InterfaceOptionsFrame_OpenToCategory(about) end,
})
