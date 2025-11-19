GDKPT.Settings = {}


-------------------------------------------------------------------
-- Addon Settings Frame
-------------------------------------------------------------------

local SettingsFrame = CreateFrame("Frame", "GDKPT_SettingsFrame", UIParent) 
SettingsFrame:SetSize(500, 480)
SettingsFrame:SetPoint("CENTER", GDKPT.UI.AuctionWindow, "CENTER", 0, 0)
SettingsFrame:SetMovable(true)
SettingsFrame:EnableMouse(true)
SettingsFrame:RegisterForDrag("LeftButton")
SettingsFrame:SetBackdrop(
    {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    }
)
SettingsFrame:SetClampedToScreen(true)
SettingsFrame:SetBackdropColor(0, 0, 0, 0.6)
SettingsFrame:Hide()

SettingsFrame:SetFrameLevel(GDKPT.UI.AuctionWindow:GetFrameLevel() + 2)

SettingsFrame:SetScript("OnDragStart", SettingsFrame.StartMoving)
SettingsFrame:SetScript("OnDragStop", SettingsFrame.StopMovingOrSizing)

SettingsFrame:SetScript(
    "OnShow",
    function(self)
        GDKPT.Utils.BringToFront(self)
    end
)


_G["GDKPT_SettingsFrame"] = SettingsFrame
tinsert(UISpecialFrames, "GDKPT_SettingsFrame")


local SettingsFrameTitle = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
SettingsFrameTitle:SetText("GDKPT Settings")
SettingsFrameTitle:SetPoint("TOP", SettingsFrame, "TOP", 0, -10)
SettingsFrameTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

local CloseSettingsFrameButton = CreateFrame("Button", "", SettingsFrame, "UIPanelCloseButton")
CloseSettingsFrameButton:SetPoint("TOPRIGHT", -5, -5)
CloseSettingsFrameButton:SetSize(35, 35)


local SettingsScrollFrame = CreateFrame("ScrollFrame", "GDKP_SettingsScrollFrame", SettingsFrame, "UIPanelScrollFrameTemplate")
SettingsScrollFrame:SetPoint("TOPLEFT", 10, -35)
SettingsScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

SettingsFrame.ScrollFrame = SettingsScrollFrame

local SettingsScrollContent = CreateFrame("Frame", nil, SettingsScrollFrame)
SettingsScrollContent:SetWidth(SettingsScrollFrame:GetWidth())
SettingsScrollContent:SetHeight(1)
SettingsScrollContent:SetPoint("TOPRIGHT",SettingsFrame,"TOPRIGHT",0,-16)
SettingsScrollFrame:SetScrollChild(SettingsScrollContent)


local SettingsFrameButton = CreateFrame("Button", "GDKP_SettingsFrameButton", GDKPT.UI.AuctionWindow, "UIPanelButtonTemplate")
SettingsFrameButton:SetSize(120, 22)
SettingsFrameButton:SetPoint("TOP", GDKPT.UI.AuctionWindow, "TOP", -85, -15)
SettingsFrameButton:SetText("Settings")

SettingsFrameButton:SetScript(
    "OnClick",
    function(self)
        if SettingsFrame:IsVisible() then
            SettingsFrame:Hide()
        else
            SettingsFrame:Show()
        end
    end
)

GDKPT.Settings.SettingsFrameButton = SettingsFrameButton


-------------------------------------------------------------------
-- Setting Rows
-------------------------------------------------------------------



local function CreateSettingCheckbox(parent, key, label, offsetY)
    local checkButton = CreateFrame("CheckButton", "GDKPT_Setting_"..key, parent, "UICheckButtonTemplate")
    checkButton:SetSize(24, 24)
    checkButton:SetPoint("TOPLEFT", 10, offsetY)

    local labelText = checkButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelText:SetPoint("LEFT", checkButton, "RIGHT", 5, 0)
    labelText:SetText(label)

    checkButton:SetScript("OnClick", function(self)
        GDKPT.Core.Settings[key] = self:GetChecked() and 1 or 0
        print(GDKPT.Core.print ..label.." set to: "..(self:GetChecked() and "ON" or "OFF"))
    end)

    checkButton.UpdateState = function()
        checkButton:SetChecked(GDKPT.Core.Settings[key] == 1)
    end

    checkButton:UpdateState()
    return checkButton
end

local function CreateSectionLabel(parent, text, offsetY)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 10, offsetY)
    label:SetText(text) 
    return offsetY - 25
end

-------------------------------------------------------------------
-- Build Settings Layout
-------------------------------------------------------------------

local offsetY = -5
SettingsFrame.CheckButtons = {}

-------------------------------------------------------
-- General Section
-------------------------------------------------------
offsetY = CreateSectionLabel(SettingsScrollContent, "General", offsetY)

local generalSettings = {
    {"HideToggleButton", "Hide GDKPT Toggle Button after opening the Auction Window"},
    {"HideToggleInCombat","Hide GDKPT Toggle Button while in combat"},
    {"AutoFillTradeGold", "Allow the AutoFill button to autofill gold on GDKP - Trades"},
    {"AutoFillTradeAccept", "Allow the AutoFill button to also accept trades"}
}

for _, data in ipairs(generalSettings) do
    local key, label = unpack(data)
    local btn = CreateSettingCheckbox(SettingsScrollContent, key, label, offsetY)
    offsetY = offsetY - 30
    table.insert(SettingsFrame.CheckButtons, btn)
end

-------------------------------------------------------
-- Bidding Behaviour Section
-------------------------------------------------------
offsetY = CreateSectionLabel(SettingsScrollContent, "Bidding", offsetY)

local biddingSettings = {
    {"LimitBidsToGold", "Limit bids to total current gold on character"},
    {"PreventSelfOutbid", "Prevent bidding on auctions you're already winning"},
    {"ConfirmBid", "Confirmation popup on clicking the minimum-bid button"},
    {"ConfirmBidBox", "Confirmation popup on entering a manual bid into the bid box"},
    {"ConfirmAutoBid", "Confirmation popup before setting autobid for favorites"},
}

for _, data in ipairs(biddingSettings) do
    local key, label = unpack(data)
    local btn = CreateSettingCheckbox(SettingsScrollContent, key, label, offsetY)
    offsetY = offsetY - 30
    table.insert(SettingsFrame.CheckButtons, btn)
end


-------------------------------------------------------
-- Display Section
-------------------------------------------------------

offsetY = CreateSectionLabel(SettingsScrollContent, "Display", offsetY)

local displaySettings = {
    {"NewAuctionsOnTop", "Show new auctions at the top of the list"},
    {"SortBidsToTop", "Sort auctions you've bid on to the top of the list"},
    {"GreenBidRows","Show auction rows in green on bid"},
    {"RedOutbidRows","Show auction rows in red when outbid"},
    {"HideCompletedAuctions","Automatically hide finished auctions 5 seconds after completion"}
}

for _, data in ipairs(displaySettings) do
    local key, label = unpack(data)
    local btn = CreateSettingCheckbox(SettingsScrollContent, key, label, offsetY)
    offsetY = offsetY - 30
    table.insert(SettingsFrame.CheckButtons, btn)
end


-------------------------------------------------------
-- Favorites Section
-------------------------------------------------------
offsetY = CreateSectionLabel(SettingsScrollContent, "Favorites", offsetY)

local favoriteSettings = {
    {"Fav_ShowGoldenRows", "Show favorite item auctions as golden rows"},
    {"Fav_ChatAlert", "Chat alert when lootmaster loots a favorite item"},
    {"Fav_PopupAlert", "Popup frame when lootmaster loots a favorite item"},
    {"Fav_AudioAlert", "Audio alert when lootmaster loots a favorite item"},
    {"Fav_RemoveItemOnWin","Remove item from favorites when favorite auction won"}
}

for _, data in ipairs(favoriteSettings) do
    local key, label = unpack(data)
    local btn = CreateSettingCheckbox(SettingsScrollContent, key, label, offsetY)
    offsetY = offsetY - 30
    table.insert(SettingsFrame.CheckButtons, btn)
end


-------------------------------------------------------
-- Notification settings
-------------------------------------------------------
offsetY = CreateSectionLabel(SettingsScrollContent, "Notifications", offsetY)

local notificationSettings = {
    {"OutbidAudioAlert", "Play sound when you get outbid on an auction"},
}


for _, data in ipairs(notificationSettings) do
    local key, label = unpack(data)
    local btn = CreateSettingCheckbox(SettingsScrollContent, key, label, offsetY)
    offsetY = offsetY - 30
    table.insert(SettingsFrame.CheckButtons, btn)
end


-------------------------------------------------------
-- Cooldown Tracker settings
-------------------------------------------------------
offsetY = CreateSectionLabel(SettingsScrollContent, "Cooldown Tracker", offsetY)

local cooldownSettings = {
    {"SendCooldownMessages", "Allow cooldown tracking of my spells (type /gdkp cd to open Tracker)"},
}

for _, data in ipairs(cooldownSettings) do
    local key, label = unpack(data)
    local btn = CreateSettingCheckbox(SettingsScrollContent, key, label, offsetY)
    offsetY = offsetY - 30
    table.insert(SettingsFrame.CheckButtons, btn)
end



-------------------------------------------------------
-- Adjust Layout based on the amount of settings
-------------------------------------------------------
SettingsScrollContent:SetHeight(-offsetY + 20)

SettingsFrame:SetScript("OnShow", function(self)
    GDKPT.Utils.BringToFront(self)
    for _, btn in ipairs(self.CheckButtons or {}) do
        if btn.UpdateState then
            btn:UpdateState()
        end
    end
end)

SettingsFrame:SetScript("OnHide", function(self)
    if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
        GDKPT.AuctionLayout.RepositionAllAuctions()
    end
end)



SettingsScrollFrame:EnableMouseWheel(true)
SettingsScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local newScroll = math.max(0, math.min(current - delta * 20, self:GetVerticalScrollRange()))
    self:SetVerticalScroll(newScroll)
end)

