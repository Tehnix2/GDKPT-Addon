GDKPT.UI = {}



-------------------------------------------------------------------
-- Main Auction Frame
-------------------------------------------------------------------

local AuctionWindow = CreateFrame("Frame", "GDKP_Auction_Window", UIParent)

AuctionWindow:SetSize(800, 600)
AuctionWindow:SetMovable(true)
AuctionWindow:EnableMouse(true)
AuctionWindow:RegisterForDrag("LeftButton")
AuctionWindow:SetPoint("CENTER")
AuctionWindow:Hide()
AuctionWindow:SetFrameLevel(8)
AuctionWindow:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 20,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    }
)

AuctionWindow:SetScript("OnDragStart", AuctionWindow.StartMoving)
AuctionWindow:SetScript("OnDragStop", AuctionWindow.StopMovingOrSizing)

_G["GDKP_Auction_Window"] = AuctionWindow
tinsert(UISpecialFrames, "GDKP_Auction_Window")

local CloseAuctionWindowButton = CreateFrame("Button", "CloseAuctionWindowButton", AuctionWindow, "UIPanelCloseButton")
CloseAuctionWindowButton:SetPoint("TOPRIGHT", -5, -5)
CloseAuctionWindowButton:SetSize(35, 35)

local AuctionWindowTitleBar = CreateFrame("Frame", "", AuctionWindow, nil)
AuctionWindowTitleBar:SetSize(180, 25)
AuctionWindowTitleBar:SetBackdrop(
    {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        edgeSize = 16,
        tileSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    }
)
AuctionWindowTitleBar:SetPoint("TOP", 0, 0)

local AuctionWindowTitleText = AuctionWindowTitleBar:CreateFontString("")
AuctionWindowTitleText:SetFont("Fonts\\FRIZQT__.TTF", 14)
AuctionWindowTitleText:SetText("|cffFFC125GDKPT " .. "- v " .. GDKPT.Core.version .. "|r")
AuctionWindowTitleText:SetPoint("CENTER", 0, 0)




-------------------------------------------------------------------
-- Bottom Info Panel
-------------------------------------------------------------------

local function CreateBottomInfoPanelFontString(name, offsetX, text)
    local fs = AuctionWindow:CreateFontString(name, "OVERLAY", "GameFontNormal")
    fs:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    fs:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", offsetX, 10)

    if text then
        fs:SetText(text)
    end

    return fs
end


local TotalPotText          = CreateBottomInfoPanelFontString("TotalPotText", -350, "Total Pot: ")
local TotalPotAmountText    = CreateBottomInfoPanelFontString("TotalPotAmountText", -240, nil)
local CurrentCutText        = CreateBottomInfoPanelFontString("CurrentCutText", -100, "Current Cut: ")
local CurrentCutAmountText  = CreateBottomInfoPanelFontString("CurrentCutAmountText", 20, nil)
local CurrentGoldText       = CreateBottomInfoPanelFontString("CurrentGoldText", 165, "Current Gold: ")
local CurrentGoldAmountText = CreateBottomInfoPanelFontString("CurrentGoldAmountText", 290, nil)




-------------------------------------------------------------------
-- Info Button on the top left that players can hover over to see 
-- global auction settings
-------------------------------------------------------------------

local InfoButton = CreateFrame("Button", "GDKP_InfoButton", AuctionWindow, "UIPanelButtonTemplate")
InfoButton:SetSize(20, 20)
InfoButton:SetPoint("TOPLEFT", AuctionWindow, "TOPLEFT", 5, -5)

local InfoButtonIcon = InfoButton:CreateTexture(nil, "OVERLAY")
InfoButtonIcon:SetSize(16, 16) 
InfoButtonIcon:SetPoint("CENTER")

function GDKPT.UI.UpdateInfoButtonStatus()
    local isSynced = GDKPT.Core.leaderSettings and GDKPT.Core.leaderSettings.isSet

    if isSynced then
        InfoButtonIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    else
        InfoButtonIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    end
end

GDKPT.UI.UpdateInfoButtonStatus() 


InfoButton:SetScript(
    "OnEnter",
    function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        GameTooltip:AddLine("GDKPT Auction Settings", 1, 1, 1)

        if GDKPT.Core.leaderSettings and GDKPT.Core.leaderSettings.isSet then
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("Duration: |cffffd100" .. GDKPT.Core.leaderSettings.duration .. " sec|r", 1, 1, 1)
            GameTooltip:AddLine("Extra Time/Bid: |cffffd100" .. GDKPT.Core.leaderSettings.extraTime .. " sec|r", 1, 1, 1)
            GameTooltip:AddLine("Starting Bid: |cffffd100" .. GDKPT.Core.leaderSettings.startBid .. " gold|r", 1, 1, 1)
            GameTooltip:AddLine("Min Increment: |cffffd100" .. GDKPT.Core.leaderSettings.minIncrement .. " gold|r", 1, 1, 1)
            GameTooltip:AddLine("Split Count: |cffffd100" .. GDKPT.Core.leaderSettings.splitCount .. " players|r", 1, 1, 1)
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cff00ff00Settings successfully synced.|r", 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cffff0000Settings Not Synced|r", 1, 0, 0)
            GameTooltip:AddLine("Press the Sync request button in the middle!", 0.8, 0.8, 0.8)
        end

        GameTooltip:Show()
    end
)

InfoButton:SetScript(
    "OnLeave",
    function()
        GameTooltip:Hide()
    end
)



------------------------------------------------------------------------------------
-- Leader Settings sync button thats visible until settings are synced
------------------------------------------------------------------------------------

local SyncSettingsButton = CreateFrame("Button", "GDKP_SyncSettingsButton", AuctionWindow, "UIPanelButtonTemplate")
SyncSettingsButton:SetSize(250, 40)
SyncSettingsButton:SetPoint("CENTER", 0, 0)
SyncSettingsButton:SetText("Sync Auction Settings")
SyncSettingsButton:Show() 

local function RequestSettingsSync(self)
    local leaderName = GDKPT.Utils.GetRaidLeaderName()

    if IsInRaid() and leaderName then
        -- Send a specific message to the leader's addon asking for settings
        local msg = "REQUEST_SETTINGS_SYNC"
        SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")

        self:SetText("Request Sent...")
        self:Disable()

        -- Implement a temporary frame to re-enable the button after a delay
        local frame = CreateFrame("Frame")
        local elapsed = 0
        frame:SetScript(
            "OnUpdate",
            function(self, delta)
                elapsed = elapsed + delta
                if elapsed >= 5.0 then
                    self:SetScript("OnUpdate", nil)
                    -- Only re-enable if settings were NOT received during the delay
                    if not GDKPT.Core.leaderSettings.isSet then
                        SyncSettingsButton:Enable()
                        SyncSettingsButton:SetText("Sync Auction Settings")
                    end
                end
            end
        )
        print("|cff99ff99[GDKPT]|r Requesting settings from raidleader |cffFFC125" .. leaderName .. "|r...")
    else
        print("|cffff8800[GDKPT]|r Error: You must be in a raid with a raidleader to sync auction settings.")
    end
end

SyncSettingsButton:SetScript("OnClick", RequestSettingsSync)




-------------------------------------------------------------------
-- Scroll Frame that will hold all of the auctions
-------------------------------------------------------------------

local AuctionScrollFrame = CreateFrame("ScrollFrame", "GDKP_Auction_ScrollFrame", AuctionWindow, "UIPanelScrollFrameTemplate")
AuctionScrollFrame:SetPoint("TOPLEFT", 10, -40)
AuctionScrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
AuctionScrollFrame:Hide() -- Hide until leader settings have been synced, then show

local AuctionContentFrame = CreateFrame("Frame", "GDKP_Auction_ContentFrame", AuctionScrollFrame)
AuctionContentFrame:SetSize(760, 100)
AuctionScrollFrame:SetScrollChild(AuctionContentFrame)




-------------------------------------------------------------------
-- Won Auctions
-------------------------------------------------------------------


local WonAuctionsFrame = CreateFrame("Frame", "GDKP_WonAuctionsFrame", UIParent)
WonAuctionsFrame:SetSize(400, 300)
WonAuctionsFrame:SetPoint("BOTTOMRIGHT", AuctionWindow, "BOTTOMRIGHT", -10, 10)
WonAuctionsFrame:SetBackdrop(
    {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    }
)
WonAuctionsFrame:SetBackdropColor(0, 0, 0, 0.6)
WonAuctionsFrame:SetFrameLevel(AuctionWindow:GetFrameLevel() + 2)
WonAuctionsFrame:Hide()

WonAuctionsFrame:SetMovable(true)
WonAuctionsFrame:EnableMouse(true)
WonAuctionsFrame:RegisterForDrag("LeftButton")

WonAuctionsFrame:SetScript(
    "OnShow",
    function(self)
        GDKPT.Utils.BringToFront(self)
    end
)

WonAuctionsFrame:SetScript("OnDragStart", WonAuctionsFrame.StartMoving)
WonAuctionsFrame:SetScript("OnDragStop", WonAuctionsFrame.StopMovingOrSizing)

_G["GDKP_WonAuctionsFrame"] = WonAuctionsFrame
tinsert(UISpecialFrames, "GDKP_WonAuctionsFrame")

AuctionWindow.WonAuctionsFrame = WonAuctionsFrame -- Attach to main window for easy access

local WonAuctionsTitle = WonAuctionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
WonAuctionsTitle:SetText("Won Auctions")
WonAuctionsTitle:SetPoint("TOP", WonAuctionsFrame, "TOP", 0, -10)
WonAuctionsTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

local CloseWonAuctionsButton = CreateFrame("Button", "", WonAuctionsFrame, "UIPanelCloseButton")
CloseWonAuctionsButton:SetPoint("TOPRIGHT", -5, -5)
CloseWonAuctionsButton:SetSize(35, 35)

-- Button in AuctionWindow to show/hide the WonAuctionsFrame

local WonAuctionsButton = CreateFrame("Button", "GDKP_WonAuctionsButton", AuctionWindow, "UIPanelButtonTemplate")
WonAuctionsButton:SetSize(120, 22)
WonAuctionsButton:SetPoint("TOPRIGHT", AuctionWindow, "TOPRIGHT", -170, -15)

WonAuctionsButton:SetText("Won Auctions")

WonAuctionsButton:SetScript(
    "OnClick",
    function(self)
        if WonAuctionsFrame:IsVisible() then
            WonAuctionsFrame:Hide()
        else
            WonAuctionsFrame:Show()
        end
    end
)


local WonAuctionsScrollFrame = CreateFrame("ScrollFrame", "GDKP_WonItemsScrollFrame", WonAuctionsFrame, "UIPanelScrollFrameTemplate")
WonAuctionsScrollFrame:SetPoint("TOPLEFT", -30, -35)
WonAuctionsScrollFrame:SetPoint("BOTTOMRIGHT", -30, 80)

WonAuctionsFrame.ScrollFrame = WonAuctionsScrollFrame


local WonAuctionsScrollContent = CreateFrame("Frame", nil, WonAuctionsScrollFrame)
WonAuctionsScrollContent:SetWidth(WonAuctionsScrollFrame:GetWidth())
WonAuctionsScrollContent:SetHeight(1) -- Will be adjusted dynamically
WonAuctionsScrollFrame:SetScrollChild(WonAuctionsScrollContent)


local WonAuctionsSummaryPanel = CreateFrame("Frame", "GDKP_WonItemsSummaryPanel", WonAuctionsFrame)
WonAuctionsSummaryPanel:SetSize(WonAuctionsFrame:GetWidth() - 20, 80)
WonAuctionsSummaryPanel:SetPoint("BOTTOM", 0, 10)
WonAuctionsSummaryPanel:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    }
)
WonAuctionsSummaryPanel:SetBackdropColor(0, 0, 0, 0.4)

WonAuctionsFrame.SummaryPanel = WonAuctionsSummaryPanel


-- Amount of won items (top left)

local amountItemsLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
amountItemsLabel:SetText("Amount of Items:")
amountItemsLabel:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -130, 20)
amountItemsLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)

local amountItemsValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
amountItemsValue:SetText(0)
amountItemsValue:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -60, 20)
amountItemsValue:SetFont("Fonts\\FRIZQT__.TTF", 12)

WonAuctionsSummaryPanel.amountItemsValue = amountItemsValue


-- Average cost per item (bottom left)

local averageCostLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
averageCostLabel:SetText("Average Cost:")
averageCostLabel:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -140, -20)
averageCostLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)

local averageCostValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
averageCostValue:SetText(GDKPT.Utils.FormatMoney(0))
averageCostValue:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -50, -20)
averageCostValue:SetFont("Fonts\\FRIZQT__.TTF", 12)


WonAuctionsSummaryPanel.averageCostValue = averageCostValue


-- Total Cost (top right)
local totalCostLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
totalCostLabel:SetText("Total Cost:")
totalCostLabel:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", 50, 20)
totalCostLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)

local totalCostValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
totalCostValue:SetText(GDKPT.Utils.FormatMoney(0))
totalCostValue:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", 140, 20)
totalCostValue:SetFont("Fonts\\FRIZQT__.TTF", 12)

WonAuctionsSummaryPanel.totalCostValue = totalCostValue


-- Gold from Raid (bottom right)
local goldFromRaidLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
goldFromRaidLabel:SetText("Gold from Raid:")
goldFromRaidLabel:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", 50, -20)
goldFromRaidLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)

local goldFromRaidValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
goldFromRaidValue:SetText(GDKPT.Utils.FormatMoney(0))
goldFromRaidValue:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER",  140, -20)
goldFromRaidValue:SetFont("Fonts\\FRIZQT__.TTF", 12)

WonAuctionsSummaryPanel.goldFromRaidValue = goldFromRaidValue




-------------------------------------------------------------------
-- Toggle Button to show the main window
-------------------------------------------------------------------



local GDKPToggleButton = CreateFrame("Button", "GDKPToggleButton", UIParent)
GDKPToggleButton:SetSize(40, 40)
GDKPToggleButton:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
GDKPToggleButton:SetMovable(true)
GDKPToggleButton:EnableMouse(true)
GDKPToggleButton:RegisterForDrag("LeftButton")
GDKPToggleButton:SetFrameStrata("MEDIUM") 


local toggleIcon = GDKPToggleButton:CreateTexture(nil, "ARTWORK")
toggleIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
toggleIcon:SetAllPoints()

local toggleHighlight = GDKPToggleButton:CreateTexture(nil, "HIGHLIGHT")
toggleHighlight:SetAllPoints()
toggleHighlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
toggleHighlight:SetBlendMode("ADD")

local buttonText = GDKPToggleButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
buttonText:SetPoint("CENTER", 0, 30)
buttonText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
buttonText:SetText("GDKPT")


-- Function to check the raid status and update visibility
local function UpdateToggleButtonVisibility()
    if IsInRaid() then  
        if not AuctionWindow:IsVisible() then
            GDKPToggleButton:Show()
        end
    else
        GDKPToggleButton:Hide()
    end
end

-- Create a temporary frame to listen for events
local toggleButtonEventFrame = CreateFrame("Frame")
toggleButtonEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
toggleButtonEventFrame:RegisterEvent("PLAYER_LOGIN")
toggleButtonEventFrame:RegisterEvent("GROUP_JOINED")
toggleButtonEventFrame:RegisterEvent("GROUP_LEFT")
toggleButtonEventFrame:RegisterEvent("GROUP_UNGROUPED")
toggleButtonEventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
toggleButtonEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_LOGIN" or event == "GROUP_JOINED" or event == "GROUP_LEFT" or event == "GROUP_UNGROUPED" or event == "PARTY_MEMBERS_CHANGED" then
        UpdateToggleButtonVisibility()
    end
end)




GDKPToggleButton:SetScript(
    "OnClick",
    function(self)
        AuctionWindow:Show()
        self:Hide()
    end
)


GDKPToggleButton:SetScript("OnDragStart", GDKPToggleButton.StartMoving)

GDKPToggleButton:SetScript(
    "OnDragStop",
    function(self)
        self:StopMovingOrSizing()

        local point, _, _, x, y = self:GetPoint()

        -- Check if GDKPT.Core.Settings is initialized before saving
        local settings = GDKPT.Core.Settings
        if settings then
            -- Save the new position data
            settings.toggleButtonPos = {
                x = x,
                y = y,
                anchor = point,
            }
        end
    end
)


function GDKPT.Core.LoadToggleButtonPosition()
    local pos = GDKPT.Core.Settings and GDKPT.Core.Settings.toggleButtonPos

    -- Apply the saved position if it exists
    if pos and pos.anchor then
        GDKPToggleButton:ClearAllPoints()
        GDKPToggleButton:SetPoint(pos.anchor, UIParent, pos.anchor, pos.x, pos.y)
    end

    UpdateToggleButtonVisibility()
end


AuctionWindow:SetScript(
    "OnHide",
    function()
        if IsInGroup() or IsInRaid() then
            UpdateToggleButtonVisibility()
        end
    end
)


local originalShowFunction = AuctionWindow.Show
function AuctionWindow:Show(...)
    originalShowFunction(self, ...) 
    GDKPToggleButton:Hide() 
end

UpdateToggleButtonVisibility()





-------------------------------------------------------------------
-- Filter by favorites Button
-------------------------------------------------------------------

local FavoriteFilterButton = CreateFrame("Button", "GDKP_FavoriteFilterButton", AuctionWindow, "UIPanelButtonTemplate")
FavoriteFilterButton:SetSize(120, 22)
FavoriteFilterButton:SetPoint("TOPLEFT", AuctionWindow, "TOPLEFT", 50, -15)

function GDKPT.UI.UpdateFilterButtonText()
    if not GDKPT.Core.isFavoriteFilterActive then
        FavoriteFilterButton:SetText("Favorites only")
    else
        FavoriteFilterButton:SetText("All Auctions")
    end
end

GDKPT.UI.UpdateFilterButtonText() 







-------------------------------------------------------------------
-- Favorite Frame
-------------------------------------------------------------------


local FavoriteFrame = CreateFrame("Frame", "GDKPT_FavoriteListFrame", UIParent) 
FavoriteFrame:SetSize(380, 480)
FavoriteFrame:SetPoint("LEFT", AuctionWindow, "LEFT", -100, 0)
FavoriteFrame:SetMovable(true)
FavoriteFrame:EnableMouse(true)
FavoriteFrame:RegisterForDrag("LeftButton")
FavoriteFrame:SetBackdrop(
    {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    }
)
FavoriteFrame:SetBackdropColor(0, 0, 0, 0.6)
FavoriteFrame:Hide()

FavoriteFrame:SetFrameLevel(AuctionWindow:GetFrameLevel() + 2)

FavoriteFrame:SetScript("OnDragStart", FavoriteFrame.StartMoving)
FavoriteFrame:SetScript("OnDragStop", FavoriteFrame.StopMovingOrSizing)

FavoriteFrame:SetScript(
    "OnShow",
    function(self)
        GDKPT.Utils.BringToFront(self)
    end
)


_G["GDKPT_FavoriteListFrame"] = FavoriteFrame
tinsert(UISpecialFrames, "GDKPT_FavoriteListFrame")


local FavoriteFrameTitle = FavoriteFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FavoriteFrameTitle:SetText("Favorite Items")
FavoriteFrameTitle:SetPoint("TOP", FavoriteFrame, "TOP", 0, -10)
FavoriteFrameTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

local CloseFavoritesFrameButton = CreateFrame("Button", "", FavoriteFrame, "UIPanelCloseButton")
CloseFavoritesFrameButton:SetPoint("TOPRIGHT", -5, -5)
CloseFavoritesFrameButton:SetSize(35, 35)


local FavoriteScrollFrame = CreateFrame("ScrollFrame", "GDKP_FavoritesScrollFrame", FavoriteFrame, "UIPanelScrollFrameTemplate")
FavoriteScrollFrame:SetPoint("TOPLEFT", 10, -35)
FavoriteScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

FavoriteFrame.ScrollFrame = FavoriteScrollFrame

local FavoriteScrollContent = CreateFrame("Frame", nil, FavoriteScrollFrame)
FavoriteScrollContent:SetWidth(FavoriteScrollFrame:GetWidth())
FavoriteScrollContent:SetHeight(1) 
FavoriteScrollFrame:SetScrollChild(FavoriteScrollContent)


local FavoriteFrameButton = CreateFrame("Button", "GDKP_FavoriteFrameButton", AuctionWindow, "UIPanelButtonTemplate")
FavoriteFrameButton:SetSize(75, 22)
FavoriteFrameButton:SetPoint("TOPLEFT", AuctionWindow, "TOPLEFT", 180, -15)

FavoriteFrameButton:SetText("Fav.List")

FavoriteFrameButton:SetScript(
    "OnClick",
    function(self)
        if FavoriteFrame:IsVisible() then
            FavoriteFrame:Hide()
        else
            GDKPT.FavoritesUI.Update()
            FavoriteFrame:Show()
        end
    end
)




-------------------------------------------------------------------
-- General Auction History
-------------------------------------------------------------------

local GeneralHistoryFrame = CreateFrame("Frame", "GDKP_GeneralHistoryFrame", UIParent)
GeneralHistoryFrame:SetSize(600, 400) 
GeneralHistoryFrame:SetPoint("CENTER", AuctionWindow, "CENTER", 0, 0)
GeneralHistoryFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
GeneralHistoryFrame:SetBackdropColor(0, 0, 0, 0.8)
GeneralHistoryFrame:SetFrameLevel(AuctionWindow:GetFrameLevel() + 2)
GeneralHistoryFrame:Hide()

GeneralHistoryFrame:SetMovable(true)
GeneralHistoryFrame:EnableMouse(true)
GeneralHistoryFrame:RegisterForDrag("LeftButton")
GeneralHistoryFrame:SetScript("OnDragStart", GeneralHistoryFrame.StartMoving)
GeneralHistoryFrame:SetScript("OnDragStop", GeneralHistoryFrame.StopMovingOrSizing)

_G["GDKP_GeneralHistoryFrame"] = GeneralHistoryFrame
tinsert(UISpecialFrames, "GDKP_GeneralHistoryFrame")


GeneralHistoryFrame:SetScript(
    "OnShow",
    function(self)
        GDKPT.Utils.BringToFront(self)
    end
)

local GeneralHistoryTitle = GeneralHistoryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
GeneralHistoryTitle:SetText("Complete Auction History")
GeneralHistoryTitle:SetPoint("TOP", 0, -10)
GeneralHistoryTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

local CloseGeneralHistoryButton = CreateFrame("Button", "", GeneralHistoryFrame, "UIPanelCloseButton")
CloseGeneralHistoryButton:SetPoint("TOPRIGHT", -5, -5)
CloseGeneralHistoryButton:SetSize(35, 35)
CloseGeneralHistoryButton:SetScript("OnClick", function() GeneralHistoryFrame:Hide() end)



local FilterLabel = GeneralHistoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
FilterLabel:SetText("Filter by Character Name or Item Name:")
FilterLabel:SetPoint("TOPLEFT", 15, -40)

local FilterBox = CreateFrame("EditBox", "GDKP_HistoryFilterBox", GeneralHistoryFrame, "InputBoxTemplate")
FilterBox:SetSize(250, 20)
FilterBox:SetPoint("TOPLEFT", FilterLabel, "BOTTOMLEFT", 0, -5)
FilterBox:SetMaxLetters(50)
FilterBox:SetText("")
FilterBox:SetAutoFocus(false) 


GeneralHistoryFrame.FilterText = ""
GeneralHistoryFrame.FilterBox = FilterBox
FilterBox:SetScript("OnTextChanged", function(self) 
    GeneralHistoryFrame.FilterText = self:GetText() 
    GDKPT.AuctionHistory.UpdateGeneralHistoryList() 
end)
FilterBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)



local GeneralHistoryScrollFrame = CreateFrame("ScrollFrame", "GDKP_GeneralHistoryScrollFrame", GeneralHistoryFrame, "UIPanelScrollFrameTemplate")
GeneralHistoryScrollFrame:SetPoint("TOPLEFT", 10, -90) 
GeneralHistoryScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)



GeneralHistoryFrame.ScrollFrame = GeneralHistoryScrollFrame


local GeneralHistoryScrollContent = CreateFrame("Frame", nil, GeneralHistoryScrollFrame)
GeneralHistoryScrollContent:SetWidth(GeneralHistoryScrollFrame:GetWidth())
GeneralHistoryScrollContent:SetHeight(1) -- Will be adjusted dynamically
GeneralHistoryScrollFrame:SetScrollChild(GeneralHistoryScrollContent)

GDKPT.UI.GeneralHistoryFrame = GeneralHistoryFrame
GDKPT.UI.GeneralHistoryScrollFrame = GeneralHistoryScrollFrame
GDKPT.UI.GeneralHistoryScrollContent = GeneralHistoryScrollContent



local GeneralHistoryButton = CreateFrame("Button", "GDKP_GeneralHistoryButton", AuctionWindow, "UIPanelButtonTemplate")
GeneralHistoryButton:SetSize(120, 22)
GeneralHistoryButton:SetPoint("LEFT", WonAuctionsButton, "RIGHT", 5, 0) 
GeneralHistoryButton:SetText("Auction History")

GeneralHistoryButton:SetScript(
    "OnClick",
    function(self)
        if GDKPT.UI.GeneralHistoryFrame:IsVisible() then
                    GDKPT.UI.GeneralHistoryFrame:Hide()
                else
                    GDKPT.AuctionHistory.UpdateGeneralHistoryList() 
                    GDKPT.UI.GeneralHistoryFrame:Show()
                end
    end
)

GDKPT.UI.GeneralHistoryButton = GeneralHistoryButton 




-------------------------------------------------------------------
-- Player History 
-------------------------------------------------------------------

local WINDOW_WIDTH = 450
local WINDOW_HEIGHT = 550
local ROW_HEIGHT = 20
local SUMMARY_HEIGHT = 70


-- Use a higher strata for pop-up windows
--local WINDOW_STRATA = "MEDIUM" 


local PlayerHistoryWindow = CreateFrame("Frame", "GDKP_PlayerHistoryWindow", UIParent)
PlayerHistoryWindow:SetSize(450, 550)
PlayerHistoryWindow:SetPoint("CENTER", 0, 0)
PlayerHistoryWindow:Hide()
PlayerHistoryWindow:SetMovable(true)
PlayerHistoryWindow:EnableMouse(true)
PlayerHistoryWindow:RegisterForDrag("LeftButton")
PlayerHistoryWindow:SetScript("OnDragStart", PlayerHistoryWindow.StartMoving)
PlayerHistoryWindow:SetScript("OnDragStop", PlayerHistoryWindow.StopMovingOrSizing)

PlayerHistoryWindow:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
PlayerHistoryWindow:SetBackdropColor(0, 0, 0, 0.8)
PlayerHistoryWindow:SetFrameLevel(AuctionWindow:GetFrameLevel() + 5)


local PlayerHistoryWindowTitle = PlayerHistoryWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
PlayerHistoryWindowTitle:SetText("My Auction History")
PlayerHistoryWindowTitle:SetPoint("TOP", 0, -10)
PlayerHistoryWindowTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)


local ClosePlayerHistoryButton = CreateFrame("Button", "", PlayerHistoryWindow, "UIPanelCloseButton")
ClosePlayerHistoryButton:SetPoint("TOPRIGHT", -5, -5)
ClosePlayerHistoryButton:SetSize(35, 35)
ClosePlayerHistoryButton:SetScript("OnClick", function() PlayerHistoryWindow:Hide() end)




-- Add the BringToFront logic when the window is shown
PlayerHistoryWindow:SetScript(
    "OnShow", 
    function(self)
        if GDKPT.UI.BringToFront then
            GDKPT.UI.BringToFront(self)
        end
        GDKPT.UI.RefreshPlayerHistoryList()
    end
)



-- =========================================================================
-- 2. SCROLL FRAME AND ROW TEMPLATE
-- =========================================================================

-- Scroll Frame Area
local HistoryScrollFrame = CreateFrame("ScrollFrame", "GDKP_HistoryScrollFrame", PlayerHistoryWindow, "UIPanelScrollFrameTemplate")
HistoryScrollFrame:SetSize(450, 200)
HistoryScrollFrame:SetPoint("TOPLEFT", PlayerHistoryWindow, 10, -32)
HistoryScrollFrame:SetPoint("BOTTOMRIGHT", PlayerHistoryWindow, -10, SUMMARY_HEIGHT + 30)

-- Content Frame
local HistoryContentFrame = CreateFrame("Frame", nil, HistoryScrollFrame)
HistoryContentFrame:SetWidth(HistoryScrollFrame:GetWidth())
HistoryContentFrame:SetHeight(1) -- will be adjusted dynamically
HistoryScrollFrame:SetScrollChild(HistoryContentFrame)



-- Template for a single history list row
local function CreateHistoryListRow(parent, index)
    -- Revert back to Frame. It handles OnEnter/OnLeave for the tooltip.
    local row = CreateFrame("Frame", nil, parent) 
    row:SetHeight(ROW_HEIGHT)
    row:SetWidth(WINDOW_WIDTH - 38) -- Account for padding and scrollbar
    
    -- MUST enable mouse interaction for OnEnter/OnLeave
    row:EnableMouse(true) 
    
    -- Anchor to the frame. Will be positioned dynamically
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    
    -- Date/Timestamp
    row.Date = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.Date:SetPoint("LEFT", 5, 0)
    row.Date:SetWidth(60)
    row.Date:SetJustifyH("LEFT")


    -- Item Link Text (FontString)
    row.Item = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.Item:SetPoint("LEFT", row.Date, "RIGHT", 5, 0) 
    row.Item:SetWidth(277) -- Wider width to fill the gap
    row.Item:SetJustifyH("LEFT")

    -- Sell Price (Gold Paid)
    row.Price = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.Price:SetPoint("RIGHT", -5, 0)
    row.Price:SetWidth(70)
    row.Price:SetJustifyH("RIGHT")

    -- Used to store the raw item data
    row.data = nil 
    
    -- ** 1. Mouse Over Highlighting (Tooltip) - Handled by the main 'row' Frame **
    row:SetScript("OnEnter", function(self)
        self:SetBackdrop({bgFile = "Interface\\Tooltips\\Tooltip-Background"})
        self:SetBackdropColor(0.2, 0.2, 0.2, 0.5)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.data and self.data.itemLink then
            -- This correctly sets the tooltip content based on the stored itemLink
            GameTooltip:SetHyperlink(self.data.itemLink)
        else
            GameTooltip:AddLine("No item data available.")
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdrop(nil)
        GameTooltip:Hide()
    end)
    
    -- ** 2. Dedicated invisible button for click functionality **
    -- This button is created over the item name text to capture clicks and prevent the "OnClick" script error on the main frame.
    local ItemButton = CreateFrame("Button", nil, row)
    ItemButton:SetAllPoints(row.Item) -- Cover the item text area
    --ItemButton:SetFrameLevel(row.Item:GetFrameLevel() + 1) -- Ensure it's clickable above the font string
    
    -- Make the button invisible (transparent textures)
    ItemButton:SetNormalTexture("")
    ItemButton:SetPushedTexture("")
    ItemButton:SetHighlightTexture("")
    ItemButton:SetAlpha(0)
    
    -- OnClick script on the dedicated button
    ItemButton:SetScript("OnClick", function(self, button)
        -- Access row.data via the 'row' upvalue (the parent frame)
        if row.data and row.data.itemLink then
            -- This opens the item inspection window or links it to chat if a modifier is held.
            ChatFrame_OnHyperlinkClick(row.data.itemLink, nil, button)
        end
    end)


    return row
end





-- =========================================================================
-- 3. PERMANENT SUMMARY PANEL (BOTTOM)
-- =========================================================================

local HistorySummaryPanel = CreateFrame("Frame", nil, PlayerHistoryWindow)
HistorySummaryPanel:SetSize(WINDOW_WIDTH, 80)
HistorySummaryPanel:SetPoint("BOTTOM", 0, 5)
HistorySummaryPanel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", insets = {left = 0, right = 0, top = 0, bottom = 0}})
HistorySummaryPanel:SetBackdropColor(0, 0, 0, 0.6)

local function CreateSummaryLine(parent, text, xOffset, yOffset, name)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetText(text)
    label:SetPoint("TOPLEFT", parent, xOffset, yOffset)

    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetText("N/A")
    value:SetPoint("TOPRIGHT", parent, -xOffset, yOffset)
    
    parent[name] = value
end

-- Summary Lines
CreateSummaryLine(HistorySummaryPanel, "Total Items Won:", 5, -10, "totalItemsValue")
CreateSummaryLine(HistorySummaryPanel, "Total Gold Spent:", 5, -25, "totalSpentValue")
CreateSummaryLine(HistorySummaryPanel, "Total Cut Received:", 5, -40, "totalCutValue")
CreateSummaryLine(HistorySummaryPanel, "Net Gold:", 5, -55, "netGoldValue")

-- =========================================================================
-- 4. REFRESH AND DATA LOGIC
-- =========================================================================

local MAX_VISIBLE_ROWS = math.floor((WINDOW_HEIGHT - 32 - SUMMARY_HEIGHT) / ROW_HEIGHT)
local historyRows = {}



-- Flattens all historical data from GeneralHistory into a single list, FILTERING for the current player
local function FlattenHistoryData()
    local flattenedList = {}
    local totalGoldSpent = 0 
    local totalCut = 0       
    local totalItemsWon = 0
    
    local generalHistory = GDKPT.Core.GeneralHistory or {}
    -- Get the current player's name for filtering
    local currentPlayerName = UnitName("player") 
    
    -- Iterate through each general auction entry
    for i, item in ipairs(generalHistory) do
        -- *** FILTER: Only include items won by the current player ***
        if item.winner == currentPlayerName then
            local price = item.bid or 0
            
            -- Gold spent is the final price for items *I* won
            totalGoldSpent = totalGoldSpent + price
            totalItemsWon = totalItemsWon + 1

            -- Map GeneralHistory fields to the row structure
            table.insert(flattenedList, {
                timestamp = item.timestamp or time(),
                itemLink = item.link or "|cffffffffUnknown Item|r", 
                finalPrice = price, 
                winner = item.winner 
            })
        end
    end

    return flattenedList, totalGoldSpent, totalCut, totalItemsWon
end


--[[










-- Flattens all historical data into a single list of item entries
-- Flattens all historical data from GeneralHistory into a single list of item entries
local function FlattenHistoryData()
    local flattenedList = {}
    local totalGoldSold = 0 -- Renamed from totalSpent to reflect gold sold
    local totalCut = 0      -- This data is not available in GeneralHistory
    local totalItems = 0
    
    -- *** FIX: Using GDKPT.Core.GeneralHistory as requested ***
    local generalHistory = GDKPT.Core.GeneralHistory or {}
    
    -- Iterate through each general auction entry
    for i, item in ipairs(generalHistory) do
        -- Add to total gold sold across all auctions
        local price = item.bid or 0
        totalGoldSold = totalGoldSold + price
        totalItems = totalItems + 1

        -- Map GeneralHistory fields to the row structure
        table.insert(flattenedList, {
            timestamp = item.timestamp or time(),
            itemLink = item.link or "|cffffffffUnknown Item|r", 
            finalPrice = price, 
            winner = item.winner or "Unknown"
        })
    end

    -- Return adjusted totals (totalGoldSold replaces totalSpent)
    return flattenedList, totalGoldSold, totalCut, totalItems
end



]]





function GDKPT.UI.RefreshPlayerHistoryList()
    local flattenedList, totalGoldSpent, totalCut, totalItemsWon = FlattenHistoryData() 
    local numItems = #flattenedList
    local totalContentHeight = numItems * ROW_HEIGHT

    -- Update Content Frame Size
    HistoryContentFrame:SetHeight(math.max(totalContentHeight, 1))
    
    -- Update Summary Panel - reflecting personal items won/gold spent
    HistorySummaryPanel.totalItemsValue:SetText(totalItemsWon)
    HistorySummaryPanel.totalSpentValue:SetText(GDKPT.Utils.FormatMoney(totalGoldSpent * 10000))
    
    -- Update N/A for irrelevant fields in this view
    HistorySummaryPanel.totalCutValue:SetText("N/A (Win History)")
    HistorySummaryPanel.netGoldValue:SetText("N/A (Win History)")


    -- Update Rows
    for i = 1, numItems do
        if not historyRows[i] then
            historyRows[i] = CreateHistoryListRow(HistoryContentFrame, i)
        end
        local row = historyRows[i]
        local itemData = flattenedList[i]
        
        -- Date Formatting 
        local dateString = date("%Y/%m/%d", itemData.timestamp)
        row.Date:SetText(dateString)

        -- Item Link (This is now the only text between Date and Price)
        row.Item:SetText(itemData.itemLink)
        
        -- Price
        row.Price:SetText(GDKPT.Utils.FormatMoney(itemData.finalPrice * 10000)) 

        row.data = itemData 
        row:Show()
    end

    -- Hide unused rows
    for i = numItems + 1, #historyRows do
        historyRows[i]:Hide()
    end

    -- Scroll to top
    HistoryScrollFrame:SetVerticalScroll(0)
end








--[[





function GDKPT.UI.RefreshPlayerHistoryList()
    -- totalSpent is now effectively totalGoldSold from General History
    local flattenedList, totalGoldSold, totalCut, totalItems = FlattenHistoryData() 
    local numItems = #flattenedList
    local totalContentHeight = numItems * ROW_HEIGHT

    -- Update Content Frame Size
    HistoryContentFrame:SetHeight(math.max(totalContentHeight, 1))
    
    -- Update Summary Panel (Note: totalCut and netGold will be zero/N/A)
    HistorySummaryPanel.totalItemsValue:SetText(totalItems)
    HistorySummaryPanel.totalSpentValue:SetText(GDKPT.Utils.FormatMoney(totalGoldSold * 10000))
    
    -- Set cut/net to zero as it's not applicable to general history
    HistorySummaryPanel.totalCutValue:SetText("N/A")
    HistorySummaryPanel.netGoldValue:SetText("N/A")


    -- Update Rows
    for i = 1, numItems do
        if not historyRows[i] then
            historyRows[i] = CreateHistoryListRow(HistoryContentFrame, i)
        end
        local row = historyRows[i]
        local itemData = flattenedList[i]
        
        -- Date Formatting 
        local dateString = date("%Y/%m/%d", itemData.timestamp)
        row.Date:SetText(dateString)

        -- *** NEW: Populate the Winner field ***
        row.Winner:SetText(itemData.winner)

        -- Item Link
        row.Item:SetText(itemData.itemLink)
        
        -- Price
        row.Price:SetText(GDKPT.Utils.FormatMoney(itemData.finalPrice * 10000)) -- Assuming bid is in raw gold, convert to copper/full string.

        row.data = itemData 
        row:Show()
    end

    -- Hide unused rows
    for i = numItems + 1, #historyRows do
        historyRows[i]:Hide()
    end

    -- Scroll to top
    HistoryScrollFrame:SetVerticalScroll(0)
end


]]

-- =========================================================================
-- 5. UPDATE PLAYER HISTORY BUTTON
-- =========================================================================

-- Redefine the PlayerHistoryButton to link to the new window

local PlayerHistoryButton = CreateFrame("Button", "GDKP_PlayerHistoryButton", WonAuctionsFrame, "UIPanelButtonTemplate")
PlayerHistoryButton:SetSize(100, 20)
PlayerHistoryButton:SetPoint("TOPLEFT", WonAuctionsFrame, "TOPLEFT", 5, -5) 
PlayerHistoryButton:SetText("Past Raids")

-- Remove OnEnter/OnLeave tooltips
PlayerHistoryButton:SetScript("OnEnter", nil)
PlayerHistoryButton:SetScript("OnLeave", nil)

-- Set OnClick to show the new History Window
PlayerHistoryButton:SetScript(
    "OnClick",
    function()
        GDKP_PlayerHistoryWindow:Show()
    end
)









--[[


local PlayerHistoryButton = CreateFrame("Button", "GDKP_PlayerHistoryButton", WonAuctionsFrame, "UIPanelButtonTemplate")
PlayerHistoryButton:SetSize(100, 20)
PlayerHistoryButton:SetPoint("TOPLEFT", WonAuctionsFrame, "TOPLEFT", 5, -5) 
PlayerHistoryButton:SetText("Past Raids")

PlayerHistoryButton:SetScript(
    "OnEnter",
    function(self)
        -- Use GameTooltip to display the summary for a clean, quick solution
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Past Raid Summary:", 1, 1, 1)
        
        local history = GDKPT.Core.PlayerHistory
        local totalRaids = #history
        
        if totalRaids == 0 then
            GameTooltip:AddLine("No previous raid data found.", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine(string.format("Total Raids Recorded: |cff00ff00%d|r", totalRaids), 1, 1, 1)
            GameTooltip:AddLine("Last Raid:", 0.8, 0.8, 0.8)
            
            -- Display last raid summary
            local lastRaid = history[totalRaids]
            local paid = GDKPT.Utils.FormatMoney(lastRaid.totalPaid * 10000)
            local cut = GDKPT.Utils.FormatMoney(lastRaid.cutReceived * 10000)
            local net = GDKPT.Utils.FormatMoney((lastRaid.cutReceived - lastRaid.totalPaid) * 10000)
            
            GameTooltip:AddLine(string.format("  Won Items: |cffffd100%d|r", #lastRaid.itemsWon), 1, 1, 1)
            GameTooltip:AddLine(string.format("  Gold Cut: %s", cut), 0.5, 0.5, 1)
            GameTooltip:AddLine(string.format("  Gold Spent: %s", paid), 1, 0.5, 0.5)
            GameTooltip:AddLine(string.format("  Net: %s", net), 0.5, 1, 0.5)
        end
        
        GameTooltip:Show()
    end
)

PlayerHistoryButton:SetScript(
    "OnLeave",
    function()
        GameTooltip:Hide()
    end
)



GDKPT.UI.PlayerHistoryButton = PlayerHistoryButton -- Export the button



]]












-------------------------------------------------------------------
-- Macro Frame for letting players copy paste macros /gdkp macro
-------------------------------------------------------------------


local MacroWindow = CreateFrame("Frame", "GDKP_MacroWindow", UIParent, "BackdropTemplate")
MacroWindow:SetSize(600, 160)
MacroWindow:SetPoint("CENTER", 0, 0)
MacroWindow:Hide()
MacroWindow:SetMovable(true)
MacroWindow:EnableMouse(true)
MacroWindow:RegisterForDrag("LeftButton")
MacroWindow:SetScript("OnDragStart", MacroWindow.StartMoving)
MacroWindow:SetScript("OnDragStop", MacroWindow.StopMovingOrSizing)
MacroWindow:SetFrameStrata("HIGH")

MacroWindow:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
MacroWindow:SetBackdropColor(0, 0, 0, 0.8)


local MacroWindowTitle = MacroWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MacroWindowTitle:SetText("Favorite Item Macro")
MacroWindowTitle:SetPoint("TOP", 0, -10)
MacroWindowTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)


local CloseButton = CreateFrame("Button", nil, MacroWindow, "UIPanelCloseButton")
CloseButton:SetPoint("TOPRIGHT", 0, 0)
CloseButton:SetSize(35, 35)
CloseButton:SetScript("OnClick", function() MacroWindow:Hide() end)

local MacroEditBox = CreateFrame("EditBox", nil, MacroWindow, "InputBoxTemplate")
MacroEditBox:SetPoint("TOPLEFT", 15, -40)
MacroEditBox:SetPoint("BOTTOMRIGHT", -15, 40)
MacroEditBox:SetText("/run DEFAULT_CHAT_FRAME.editBox:SetText(\"/gdkp f \" .. select(2, GameTooltip:GetItem()));ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)")
MacroEditBox:SetFontObject(GameFontNormalSmall)
MacroEditBox:SetMaxBytes(256)
MacroEditBox:SetAutoFocus(false)  
MacroEditBox:SetMultiLine(true)
MacroEditBox:SetJustifyH("LEFT")
MacroEditBox:SetJustifyV("TOP")

MacroEditBox:EnableMouse(true) 
MacroEditBox:SetScript("OnMouseUp", function(self) self:HighlightText() end) 
MacroEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)


local Instructions = MacroWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
Instructions:SetText("Copy the text below and paste it into a new game macro. This macro lets you favorite items on mouseover.")
Instructions:SetPoint("BOTTOM", MacroEditBox, "TOP", 0, 5)
Instructions:SetTextColor(1, 1, 1, 1)

function GDKPT.UI.ShowMacroFrame()
    GDKP_MacroWindow:Show()
    MacroEditBox:SetFocus()
    MacroEditBox:HighlightText()
end











-------------------------------------------------------------------
-- Functions to update the data on the bottom info panel
-------------------------------------------------------------------

function GDKPT.UI.UpdateTotalPotAmount(totalPotValue)

    GDKPT.Core.GDKP_Pot = tonumber(totalPotValue) or 0 -- Store in Core
    TotalPotAmountText:SetText(string.format("%s", GDKPT.Utils.FormatMoney(GDKPT.Core.GDKP_Pot)))

   -- currentPot = tonumber(totalPotValue) or 0
    --TotalPotAmountText:SetText(string.format("%s", GDKPT.Utils.FormatMoney(currentPot)))
end

function GDKPT.UI.UpdateCurrentCutAmount(currentCutValue) -- Accept the synced value
    local cut = tonumber(currentCutValue) or 0
    GDKPT.Core.PlayerCut = cut -- Store in Core
    CurrentCutAmountText:SetText(string.format("%s", GDKPT.Utils.FormatMoney(cut)))


    --currentCut = tonumber(currentCutValue) or 0
    --PlayerCut = currentCut
    --CurrentCutAmountText:SetText(string.format("%s", GDKPT.Utils.FormatMoney(currentCut)))
end

function GDKPT.UI.UpdateCurrentGoldAmount()
    CurrentGoldAmountText:SetText(GDKPT.Utils.FormatMoney(GetMoney()))
end




-------------------------------------------------------------------
-- Function to show the auction window, called through /gdkp show
-------------------------------------------------------------------

function GDKPT.UI.ShowAuctionWindow()
    AuctionWindow:Show()
    GDKPT.UI.UpdateCurrentGoldAmount()
end




-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


GDKPT.UI.AuctionWindow = AuctionWindow
GDKPT.UI.AuctionContentFrame = AuctionContentFrame
GDKPT.UI.FavoriteFilterButton = FavoriteFilterButton
GDKPT.UI.SyncSettingsButton = SyncSettingsButton
GDKPT.UI.AuctionScrollFrame = AuctionScrollFrame
GDKPT.UI.WonAuctionsFrame = WonAuctionsFrame


GDKPT.UI.FavoriteFrame = FavoriteFrame
GDKPT.UI.FavoriteScrollFrame = FavoriteScrollFrame
GDKPT.UI.FavoriteScrollContent = FavoriteScrollContent

-- Add a GameTooltip:Hide() to the WonAuctionsFrame OnLeave script
GDKPT.UI.WonAuctionsFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)