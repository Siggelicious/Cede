local function print(msg) DEFAULT_CHAT_FRAME:AddMessage("Cede: " .. msg) end

local CedeBar = CreateFrame("Frame", "CedeBar", UIParent)

local timerSize = 32

local CedeDefaults = {
	["ids"] = {
		[1044] = 25,
		[19647] = 24,
		[38768] = 10,
		[14311] = 30,
		[1020] = 300,
		[22812] = 60,
		[26889] = 300,
		[13809] = 30,
		[26669] = 300,
		[19639] = 10,
		[20616] = 15,
		[10308] = 60,
		[2094] = 180,
		[36554] = 30,
		[10890] = 30,
		[10278] = 300,
		[19503] = 30,
		[2139] = 24,
		[27223] = 120,
		[15487] = 45,
		[20066] = 60,
		[16979] = 15,
		[31224] = 60,
		[14185] = 600,
		[8643] = 20,
		[5246] = 300,
		[29166] = 360,
		[16689] = 60,
		[8042] = 6,
		[23920] = 10
	},
	["options"] = {
		["scale"] = 1,
		["yOffs"] = -200
	}
}

local CedeTimers = {}

local activeTimers = {}

CedeBar:SetWidth(32)
CedeBar:SetHeight(32)

CedeBar:RegisterEvent("VARIABLES_LOADED")
CedeBar:RegisterEvent("ZONE_CHANGED_NEW_AREA")
CedeBar:RegisterEvent("DUEL_FINISHED")
CedeBar:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function CedeSetBarPos()
	CedeBar:SetPoint("CENTER", UIParent, "CENTER", 0, CedeOptions["options"]["yOffs"])
end

local function CedeGetActiveTimers()
	activeTimers = {}

	for k,v in pairs(CedeTimers) do
		if v:IsShown() then
			table.insert(activeTimers, v)
		end
	end
end

local function CedeUpdatePos()
	if #activeTimers > 0 then

		local xOffs = (#activeTimers * timerSize) / -2

		activeTimers[1]:ClearAllPoints()
		activeTimers[1]:SetPoint("LEFT", CedeBar, "CENTER", xOffs, 0)

		for i=2,#activeTimers do
			activeTimers[i]:ClearAllPoints()
			activeTimers[i]:SetPoint("LEFT", activeTimers[i-1], "RIGHT", 0, 0)
		end
	end 
end

local function CedeStartTimer(spellName)
	CedeTimers[spellName]:SetCooldown(GetTime(), CedeTimers[spellName].cd)

	CedeGetActiveTimers()
	CedeUpdatePos()
end

local function CedeTimerOnHide(self)
	CedeGetActiveTimers()
	CedeUpdatePos()
end

local function CedeTest()
	for k,v in pairs(CedeTimers) do
		CedeStartTimer(k)
	end
end

local function CedeResetAllTimers()
	for k,v in pairs(activeTimers) do
		v:Hide()
	end
	activeTimers = {}
end

local function CedeBar_ADDON_LOADED(self) 
	if not CedeOptions then
		CedeOptions = CedeDefaults
		print("SavedVariables weren't found, generating...")
	end

	CedeSetBarPos()

	for k,v in pairs(CedeOptions["ids"]) do
		local name, icon 
		name, _, icon = GetSpellInfo(k)
		timerSize = 32 * CedeOptions["options"]["scale"]

		CedeTimers[name] = CreateFrame("Cooldown", "CedeTimer" .. name, self, "CedeTimerTemplate")
		CedeTimers[name]:SetWidth(timerSize)
		CedeTimers[name]:SetHeight(timerSize)
		CedeTimers[name].cd = v
		CedeTimers[name].name = name
		CedeTimers[name]:SetScript("OnHide", CedeTimerOnHide)
		_G["CedeTimer" .. name .. "Icon"]:SetTexture(icon)
	end
end

local function CedeBar_COMBAT_LOG_EVENT_UNFILTERED(self, ...)
	local eventType, srcName, srcFlags
	_, eventType, _, srcName, srcFlags, _, _, _, _, spellName = ...

	-- prints all the args 
	--[[
	for i=1, 10 do
		if select(i, ...) then 
			print(i .. ": " .. select(i, ...))
		end
	end
	]]--

	if bit.band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 and eventType == "SPELL_CAST_SUCCESS" then 
		if CedeTimers[spellName] then

			CedeStartTimer(spellName)
		end
	end
end

local eventHandler = {
	["VARIABLES_LOADED"] = function(self) CedeBar_ADDON_LOADED(self) end,
	["ZONE_CHANGED_NEW_AREA"] = function(self) CedeResetAllTimers() end,
	["DUEL_FINISHED"] = function(self) CedeResetAllTimers() end,
	["COMBAT_LOG_EVENT_UNFILTERED"] = function(self, ...) CedeBar_COMBAT_LOG_EVENT_UNFILTERED(self, ...) end
}

local function CedeBar_OnEvent(self, event, ...)
	eventHandler[event](self, ...)
end

CedeBar:SetScript("OnEvent", CedeBar_OnEvent)


---------------------------------------------

function CedeOptionsPanel_OnLoad(self)
	self:RegisterEvent("VARIABLES_LOADED")

	self.name = "Cede"

	_G[self:GetName() .. "OffsetSlider"]:SetScript("OnValueChanged", function(self)
		CedeOptions["options"]["yOffs"] = self:GetValue()
		CedeSetBarPos()
	end)

	_G[self:GetName() .. "ScaleSlider"]:SetScript("OnValueChanged", function(self)
		CedeOptions["options"]["scale"] = self:GetValue()
		timerSize = CedeOptions["options"]["scale"] * 32
		for k,v in pairs(CedeTimers) do
			v:SetWidth(timerSize)
			v:SetHeight(timerSize)
		end
	end)

	_G[self:GetName() .. "TestButton"]:SetScript("OnClick", function(self)
		CedeTest()
	end)

	InterfaceOptions_AddCategory(self)
end

function CedeOptionsPanel_VARIABLES_LOADED(self)
	_G[self:GetName() .. "OffsetSlider"]:SetValue(CedeOptions["options"]["yOffs"])
	_G[self:GetName() .. "ScaleSlider"]:SetValue(CedeOptions["options"]["scale"])
end

local CedeOptionsPanel = CreateFrame("Frame", "CedeOptionsPanel", UIParent, "CedeOptionsPanelTemplate")