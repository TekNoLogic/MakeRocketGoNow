
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


-----------------------------
--      Block factory      --
-----------------------------

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

	frame:SetScript("OnClick", dataobj.OnClick)

	frame.texture = frame:CreateTexture()
	frame.texture:SetAllPoints()
	frame.texture:SetTexture(dataobj.icon)

--~ 	ldb.RegisterCallback(frame, "LibDataBroker_AttributeChanged_"..dataobjname.."_text", "TextUpdate")
end

ldb.RegisterCallback(f, "LibDataBroker_DataObjectCreated", "NewDataobject")
