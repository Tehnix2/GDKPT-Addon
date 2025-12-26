GDKPT.Macros = {}


-------------------------------------------------------------------
-- Main Macro Frame
-------------------------------------------------------------------

local MacroFrame = CreateFrame("Frame", "GDKPT_MacroFrame", UIParent, "BackdropTemplate")
MacroFrame:SetSize(600, 300)
MacroFrame:SetPoint("CENTER")
MacroFrame:SetMovable(true)
MacroFrame:EnableMouse(true)
MacroFrame:RegisterForDrag("LeftButton")
MacroFrame:SetScript("OnDragStart", MacroFrame.StartMoving)
MacroFrame:SetScript("OnDragStop", MacroFrame.StopMovingOrSizing)
MacroFrame:SetFrameStrata("DIALOG")
MacroFrame:SetFrameLevel(100)
MacroFrame:Hide()

MacroFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 32,
    insets = {left = 8, right = 8, top = 8, bottom = 8}
})
MacroFrame:SetBackdropColor(0, 0, 0, 0.95)

GDKPT.Macros.MacroFrame = MacroFrame

local TitleBar = CreateFrame("Frame", nil, MacroFrame)
TitleBar:SetSize(400, 30)
TitleBar:SetPoint("TOP", 0, 12)
TitleBar:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    edgeSize = 16,
    tileSize = 16,
    insets = {left = 5, right = 5, top = 5, bottom = 5}
})
TitleBar:SetBackdropColor(0.1, 0.1, 0.1, 1)

local TitleText = TitleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
TitleText:SetPoint("CENTER")
TitleText:SetText("|cffFFC125GDKPT Macro Generator|r")

local CloseButton = CreateFrame("Button", nil, MacroFrame, "UIPanelCloseButton")
CloseButton:SetPoint("TOPRIGHT", -5, -5)
CloseButton:SetSize(32, 32)
CloseButton:SetScript("OnClick", function() MacroFrame:Hide() end)

-------------------------------------------------------------------
-- Macro Type Dropdown
-------------------------------------------------------------------

local MacroLabel = MacroFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MacroLabel:SetPoint("TOPLEFT", 20, -50)
MacroLabel:SetText("Macro Type:")

local MacroDropdown = CreateFrame("Frame", "GDKPT_MacroTypeDropdown", MacroFrame, "UIDropDownMenuTemplate")
MacroDropdown:SetPoint("LEFT", MacroLabel, "RIGHT", -15, -2)

local selectedMacroType = "Favorite"

local function MacroDropdown_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()

    info.text = "Favorite Macro"
    info.value = "Favorite"
    info.func = function()
        selectedMacroType = "Favorite"
        UIDropDownMenu_SetSelectedValue(MacroDropdown, "Favorite")
    end
    info.checked = (selectedMacroType == "Favorite")
    UIDropDownMenu_AddButton(info, level)

    info.text = "Trade Macro"
    info.value = "Trade"
    info.func = function()
        selectedMacroType = "Trade"
        UIDropDownMenu_SetSelectedValue(MacroDropdown, "Trade")
    end
    info.checked = (selectedMacroType == "Trade")
    UIDropDownMenu_AddButton(info, level)

    info.text = "Cooldown Request: Use Spell"
    info.value = "SpellRequest"
    info.func = function()
        selectedMacroType = "SpellRequest"
        UIDropDownMenu_SetSelectedValue(MacroDropdown, "SpellRequest")
    end
    info.checked = (selectedMacroType == "SpellRequest")
    UIDropDownMenu_AddButton(info, level)

    info.text = "RaidLeader: Start Auction Macro"
    info.value = "StartAuction"
    info.func = function()
        selectedMacroType = "StartAuction"
        UIDropDownMenu_SetSelectedValue(MacroDropdown, "StartAuction")
    end
    info.checked = (selectedMacroType == "StartAuction")
    UIDropDownMenu_AddButton(info, level)

    info.text = "RaidLeader: Hand Out Cut"
    info.value = "HandOutCut"
    info.func = function()
        selectedMacroType = "HandOutCut"
        UIDropDownMenu_SetSelectedValue(MacroDropdown, "HandOutCut")
    end
    info.checked = (selectedMacroType == "HandOutCut")
    UIDropDownMenu_AddButton(info, level)

    info.text = "RaidLeader: Auto Masterloot"
    info.value = "AutoMasterloot"
    info.func = function()
        selectedMacroType = "AutoMasterloot"
        UIDropDownMenu_SetSelectedValue(MacroDropdown, "AutoMasterloot")
    end
    info.checked = (selectedMacroType == "AutoMasterloot")
    UIDropDownMenu_AddButton(info, level)

    info.text = "RaidLeader: Bulk Item Toggle"
    info.value = "BulkItemToggle"
    info.func = function()
        selectedMacroType = "BulkItemToggle"
        UIDropDownMenu_SetSelectedValue(MacroDropdown, "BulkItemToggle")
    end
    info.checked = (selectedMacroType == "BulkItemToggle")
    UIDropDownMenu_AddButton(info, level)





end

UIDropDownMenu_Initialize(MacroDropdown, MacroDropdown_Initialize)
UIDropDownMenu_SetSelectedValue(MacroDropdown, "Favorite")
UIDropDownMenu_SetWidth(MacroDropdown, 140)

-------------------------------------------------------------------
-- Generate Button
-------------------------------------------------------------------

local GenerateButton = CreateFrame("Button", nil, MacroFrame, "GameMenuButtonTemplate")
GenerateButton:SetSize(150, 30)
GenerateButton:SetPoint("LEFT", MacroDropdown, "RIGHT", 100, 5)
GenerateButton:SetText("Generate Macro")
GenerateButton:SetNormalFontObject("GameFontNormalLarge")
GenerateButton:SetHighlightFontObject("GameFontHighlightLarge")

-------------------------------------------------------------------
-- Scroll Frame and EditBox
-------------------------------------------------------------------

local ScrollFrame = CreateFrame("ScrollFrame", nil, MacroFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 20, -150)
ScrollFrame:SetPoint("BOTTOMRIGHT", -40, 50)

local MacroTextBox = CreateFrame("EditBox", nil, ScrollFrame)
MacroTextBox:SetMultiLine(true)
MacroTextBox:SetAutoFocus(false)
MacroTextBox:SetFontObject(ChatFontNormal)
MacroTextBox:SetWidth(ScrollFrame:GetWidth() - 20)
MacroTextBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
MacroTextBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

ScrollFrame:SetScrollChild(MacroTextBox)
MacroFrame.MacroTextBox = MacroTextBox

local Instructions = MacroFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
Instructions:SetPoint("BOTTOM", 0, 15)
Instructions:SetText("|cffffaa00Click inside the box and press Ctrl+A then Ctrl+C to copy the macro|r")

local CopyAllButton = CreateFrame("Button", nil, MacroFrame, "GameMenuButtonTemplate")
CopyAllButton:SetSize(100, 25)
CopyAllButton:SetPoint("BOTTOMLEFT", 20, 10)
CopyAllButton:SetText("Select All")
CopyAllButton:SetScript("OnClick", function()
    MacroTextBox:SetFocus()
    MacroTextBox:HighlightText()
end)

-------------------------------------------------------------------
-- Macros
-------------------------------------------------------------------

local function GenerateFavoriteMacro()
    return '/run DEFAULT_CHAT_FRAME.editBox:SetText("/gdkp f " .. select(2, GameTooltip:GetItem()));ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)'
end

local function GenerateTradeMacro()
    return '/run GDKPT_AutoFillButton:Click();'
end

local function GenerateStartAuctionMacro()
    return '/run DEFAULT_CHAT_FRAME.editBox:SetText("/gdkpleader auction " .. select(2, GameTooltip:GetItem()));ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)'
end

local function GenerateHandOutCutMacro()
    return '/run HandOutCutButton:Click();'
end

local function GenerateAutoMasterlootMacro()
    return '/run AutoMasterlootButton:Click();'
end

local function GenerateSpellRequestMacro()
    return '/click GDKPTSpellRequestCastButton'
end

local function GenerateBulkToggleMacro()
    return '/run GDKPT.RaidLeader.BulkAuction.ToggleItemInBulkList();'
end


-------------------------------------------------------------------
-- Macro descriptions
-------------------------------------------------------------------


GDKPT.Macros.Descriptions = {
    Favorite = "Mouseover any item or itemlink to add/remove the item to your list of favorites.",
    Trade    = "Press this macro to autofill gold costs of all won auctions into trades with the raidleader.\nPressing it twice also accepts the trade.",
    SpellRequest = "Press this macro to cast the spell requested by another player through the cooldown tracker.\nBindable to a key for quick response to spell requests.",
    StartAuction = "Create a new auction for all raidmembers for the item you currently mouseover.\nOnly useful for raidleaders running the leader version of GDKPT.",
    HandOutCut = "Press this macro to automatically hand out the cut to raidmembers. Pressing it twice also accepts the trade.\nOnly useful for raidleaders running the leader version of GDKPT.",
    AutoMasterloot = "Press this macro to automatically masterloot all items from the loot window to yourself and announce the loot in raidchat. \nOnly useful for raidleaders running the leader version of GDKPT.",
    BulkItemToggle = "Mouseover any item or itemlink to add/remove the item to the bulk auction list.\nOnly useful for raidleaders running the leader version of GDKPT.",
}


local MacroDescription = MacroFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MacroDescription:SetPoint("TOP", ScrollFrame, "TOP", 0, 50)
MacroDescription:SetJustifyH("LEFT")
MacroDescription:SetWidth(ScrollFrame:GetWidth())
MacroDescription:SetTextColor(0, 1, 1) 

GenerateButton:SetScript("OnClick", function()
    local macroCode = ""

    if selectedMacroType == "Favorite" then
        macroCode = GenerateFavoriteMacro()
        MacroDescription:SetText(GDKPT.Macros.Descriptions.Favorite)
    elseif selectedMacroType == "Trade" then
        macroCode = GenerateTradeMacro()
        MacroDescription:SetText(GDKPT.Macros.Descriptions.Trade)
    elseif selectedMacroType == "SpellRequest" then
        macroCode = GenerateSpellRequestMacro()
        MacroDescription:SetText(GDKPT.Macros.Descriptions.SpellRequest)
    elseif selectedMacroType == "StartAuction" then
        macroCode = GenerateStartAuctionMacro()
        MacroDescription:SetText(GDKPT.Macros.Descriptions.StartAuction)
    elseif selectedMacroType == "HandOutCut" then
        macroCode = GenerateHandOutCutMacro()
        MacroDescription:SetText(GDKPT.Macros.Descriptions.HandOutCut)
    elseif selectedMacroType == "AutoMasterloot" then
        macroCode = GenerateAutoMasterlootMacro()
        MacroDescription:SetText(GDKPT.Macros.Descriptions.AutoMasterloot)
    elseif selectedMacroType == "BulkItemToggle" then
        macroCode = GenerateBulkToggleMacro()
        MacroDescription:SetText(GDKPT.Macros.Descriptions.BulkItemToggle)
    end

    MacroTextBox:SetText(macroCode)
    MacroTextBox:SetFocus()
    MacroTextBox:HighlightText()
end)









-------------------------------------------------------------------
-- Public Functions
-------------------------------------------------------------------

function GDKPT.Macros.Show()
    MacroFrame:Show()
end

function GDKPT.Macros.Hide()
    MacroFrame:Hide()
end









-------------------------------------------------------------------

-------------------------------------------------------------------

-------------------------------------------------------------------

-------------------------------------------------------------------

-------------------------------------------------------------------

-------------------------------------------------------------------

