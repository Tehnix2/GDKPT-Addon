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



local TotalPotText = AuctionWindow:CreateFontString("TotalPotText", "OVERLAY", "GameFontNormal")
TotalPotText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
TotalPotText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", -350, 10)
TotalPotText:SetText("Total Pot: ")

local TotalPotAmountText = AuctionWindow:CreateFontString("TotalPotAmountText", "OVERLAY", "GameFontNormal")
TotalPotAmountText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
TotalPotAmountText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", -240, 10)

local CurrentCutText = AuctionWindow:CreateFontString("CurrentCutText", "OVERLAY", "GameFontNormal")
CurrentCutText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
CurrentCutText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", -100, 10)
CurrentCutText:SetText("Current Cut: ")

local CurrentCutAmountText = AuctionWindow:CreateFontString("CurrentCutAmountText", "OVERLAY", "GameFontNormal")
CurrentCutAmountText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
CurrentCutAmountText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", 20, 10)

local CurrentGoldText = AuctionWindow:CreateFontString("CurrentGoldText", "OVERLAY", "GameFontNormal")
CurrentGoldText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
CurrentGoldText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", 165, 10)
CurrentGoldText:SetText("Current Gold: ")

local CurrentGoldAmountText = AuctionWindow:CreateFontString("CurrentGoldAmountText", "OVERLAY", "GameFontNormal")
CurrentGoldAmountText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
CurrentGoldAmountText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", 290, 10)



-------------------------------------------------------------------
-- Info Button on the top left that players can hover over to see global auction settings
-------------------------------------------------------------------


local InfoButton = CreateFrame("Button", "GDKP_InfoButton", AuctionWindow, "UIPanelButtonTemplate")
InfoButton:SetSize(20, 20)
InfoButton:SetPoint("TOPLEFT", AuctionWindow, "TOPLEFT", 0, 0)
InfoButton:SetText("i")

-- Tooltip Handlers for the Info Button
InfoButton:SetScript(
    "OnEnter",
    function(self)
        -- Set up the tooltip anchored to the button
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
            GameTooltip:AddLine("Ask the raid leader to sync settings.", 0.8, 0.8, 0.8)
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



-------------------------------------------------------------------
-- Leader Settings sync button thats visible until settings are received and synced
-------------------------------------------------------------------

local SyncSettingsButton = CreateFrame("Button", "GDKP_SyncSettingsButton", AuctionWindow, "UIPanelButtonTemplate")
SyncSettingsButton:SetSize(250, 40)
SyncSettingsButton:SetPoint("CENTER", 0, 0)
SyncSettingsButton:SetText("Request Leader Settings Sync")
SyncSettingsButton:Show() -- Show by default

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
                        SyncSettingsButton:SetText("Request Leader Settings Sync")
                    end
                end
            end
        )
        print("|cff99ff99[GDKPT]|r Requesting settings from leader |cffFFC125" .. leaderName .. "|r...")
    else
        print("|cffff8800[GDKPT]|r Error: You must be in a raid with a leader to request settings.")
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
-- New Frame for won auctions
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
WonAuctionsFrame:SetFrameLevel(AuctionWindow:GetFrameLevel() + 1)
WonAuctionsFrame:Hide()

WonAuctionsFrame:SetMovable(true)
WonAuctionsFrame:EnableMouse(true)
WonAuctionsFrame:RegisterForDrag("LeftButton")

WonAuctionsFrame:SetScript("OnDragStart", WonAuctionsFrame.StartMoving)
WonAuctionsFrame:SetScript("OnDragStop", WonAuctionsFrame.StopMovingOrSizing)

AuctionWindow.WonAuctionsFrame = WonAuctionsFrame -- Attach to main window for easy access

local WonAuctionsTitle = WonAuctionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
WonAuctionsTitle:SetText("Won Auctions")
WonAuctionsTitle:SetPoint("TOP", WonAuctionsFrame, "TOP", 0, -10)

local CloseWonAuctionsButton = CreateFrame("Button", "", WonAuctionsFrame, "UIPanelCloseButton")
CloseWonAuctionsButton:SetPoint("TOPRIGHT", -5, -5)
CloseWonAuctionsButton:SetSize(35, 35)

-- Button in AuctionWindow to show/hide the WonAuctionsFrame

local WonItemsButton = CreateFrame("Button", "GDKP_WonItemsButton", AuctionWindow, "UIPanelButtonTemplate")
WonItemsButton:SetSize(120, 22)
WonItemsButton:SetPoint("TOPRIGHT", AuctionWindow, "TOPRIGHT", -170, -15)

-- Set initial text based on the frame's initial hidden state
WonItemsButton:SetText("Won Auctions")

WonItemsButton:SetScript(
    "OnClick",
    function(self)
        if WonAuctionsFrame:IsVisible() then
            WonAuctionsFrame:Hide()
        else
            WonAuctionsFrame:Show()
        end
    end
)




-- ScrollFrame container
local WonAuctionsScrollFrame = CreateFrame("ScrollFrame", "GDKP_WonItemsScrollFrame", WonAuctionsFrame, "UIPanelScrollFrameTemplate")
WonAuctionsScrollFrame:SetPoint("TOPLEFT", -30, -35)
WonAuctionsScrollFrame:SetPoint("BOTTOMRIGHT", -30, 80)

WonAuctionsFrame.ScrollFrame = WonAuctionsScrollFrame

-- Scroll Content
local WonAuctionsScrollContent = CreateFrame("Frame", nil, WonAuctionsScrollFrame)
WonAuctionsScrollContent:SetWidth(WonAuctionsScrollFrame:GetWidth())
WonAuctionsScrollContent:SetHeight(1) -- Will be adjusted dynamically
WonAuctionsScrollFrame:SetScrollChild(WonAuctionsScrollContent)

-- Summary Panel
local WonAuctionsSummaryPanel = CreateFrame("Frame", "GDKP_WonItemsSummaryPanel", WonAuctionsFrame)
WonAuctionsSummaryPanel:SetSize(WonAuctionsFrame:GetWidth() - 20, 72)
WonAuctionsSummaryPanel:SetPoint("BOTTOM", 0, 10)
WonAuctionsSummaryPanel:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    }
)
WonAuctionsSummaryPanel:SetBackdropColor(0, 0, 0, 0.4)

WonAuctionsFrame.SummaryPanel = WonAuctionsSummaryPanel

-- Total Cost
local totalCostLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
totalCostLabel:SetText("Total Won Auctions Cost:")
totalCostLabel:SetPoint("TOPLEFT", 5, -5)

local totalCostValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
totalCostValue:SetText(GDKPT.Utils.FormatMoney(0))
totalCostValue:SetPoint("TOPRIGHT", -5, -5)

WonAuctionsSummaryPanel.totalCostValue = totalCostValue

-- Need to Pay Up
local payUpLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
payUpLabel:SetText("Need to Pay Up:")
payUpLabel:SetPoint("TOPLEFT", 5, -29)

local payUpValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
payUpValue:SetText(GDKPT.Utils.FormatMoney(0))
payUpValue:SetPoint("TOPRIGHT", -5, -29)

WonAuctionsSummaryPanel.payUpValue = payUpValue

-- Gold Left After Raid (PlayerCut is a placeholder until pot split is done)
local goldLeftLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
goldLeftLabel:SetText("Gold from Raid:")
goldLeftLabel:SetPoint("TOPLEFT", 5, -53)

local goldLeftValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
goldLeftValue:SetText(GDKPT.Utils.FormatMoney(0))
goldLeftValue:SetPoint("TOPRIGHT", -5, -53)

WonAuctionsSummaryPanel.goldLeftValue = goldLeftValue


-------------------------------------------------------------------
-- Toggle Button to show the main window
-------------------------------------------------------------------

local GDKPToggleButton = CreateFrame("Button", "GDKPToggleButton", UIParent)
GDKPToggleButton:SetSize(40, 40)
GDKPToggleButton:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
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
buttonText:SetPoint("CENTER", 0, 0)
buttonText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
buttonText:SetText("GDKPT")

GDKPToggleButton:SetScript("OnDragStart", GDKPToggleButton.StartMoving)
GDKPToggleButton:SetScript("OnDragStop", GDKPToggleButton.StopMovingOrSizing)


GDKPToggleButton:SetScript(
    "OnClick",
    function(self)
        AuctionWindow:Show()
        self:Hide()
    end
)


AuctionWindow:SetScript(
    "OnHide",
    function()
        GDKPToggleButton:Show()
    end
)


local originalShowFunction = AuctionWindow.Show
function AuctionWindow:Show(...)
    originalShowFunction(self, ...) 
    GDKPToggleButton:Hide() 
end

GDKPToggleButton:Show()






-------------------------------------------------------------------
-- 
-------------------------------------------------------------------

local FavoriteFilterButton = CreateFrame("Button", "GDKP_FavoriteFilterButton", AuctionWindow, "UIPanelButtonTemplate")
FavoriteFilterButton:SetSize(120, 22)
FavoriteFilterButton:SetPoint("TOPLEFT", AuctionWindow, "TOPLEFT", 50, -15)



-------------------------------------------------------------------
-- Filter auction rows by favourites
-------------------------------------------------------------------



function GDKPT.UI.UpdateFilterButtonText()
    if not GDKPT.Core.isFavoriteFilterActive then
        FavoriteFilterButton:SetText("Favourites only")
    else
        FavoriteFilterButton:SetText("All Auctions")
    end
end

GDKPT.UI.UpdateFilterButtonText() -- Set initial text




-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------


-------------------------------------------------------------------
-- 
-------------------------------------------------------------------

-------------------------------------------------------------------
-- 
-------------------------------------------------------------------



-------------------------------------------------------------------
-- Functions to update the data on the bottom info panel
-------------------------------------------------------------------

function GDKPT.UI.UpdateTotalPotAmount(totalPotValue)
    currentPot = tonumber(totalPotValue) or 0
    TotalPotAmountText:SetText(string.format("%s", GDKPT.Utils.FormatMoney(currentPot)))
end

function GDKPT.UI.UpdateCurrentCutAmount(currentCutValue) -- Accept the synced value
    currentCut = tonumber(currentCutValue) or 0
    PlayerCut = currentCut
    CurrentCutAmountText:SetText(string.format("%s", GDKPT.Utils.FormatMoney(currentCut)))
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
