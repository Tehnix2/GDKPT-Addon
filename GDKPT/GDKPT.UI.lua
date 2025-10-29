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
AuctionWindow:SetClampedToScreen(true)

AuctionWindow:SetScript("OnDragStart", AuctionWindow.StartMoving)
AuctionWindow:SetScript("OnDragStop", AuctionWindow.StopMovingOrSizing)

_G["GDKP_Auction_Window"] = AuctionWindow
tinsert(UISpecialFrames, "GDKP_Auction_Window")

local CloseAuctionWindowButton = CreateFrame("Button", "CloseAuctionWindowButton", AuctionWindow, "UIPanelCloseButton")
CloseAuctionWindowButton:SetPoint("TOP", AuctionWindow, "TOP", 390, 5)
CloseAuctionWindowButton:SetSize(30, 30)


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
-- Scroll Frame that will hold all of the auctions
-------------------------------------------------------------------

local AuctionScrollFrame = CreateFrame("ScrollFrame", "GDKP_Auction_ScrollFrame", AuctionWindow, "UIPanelScrollFrameTemplate")
AuctionScrollFrame:SetPoint("TOPLEFT", 10, -40)
AuctionScrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
--AuctionScrollFrame:Hide() -- Hide until leader settings have been synced, then show
AuctionScrollFrame:Show()


local AuctionContentFrame = CreateFrame("Frame", "GDKP_Auction_ContentFrame", AuctionScrollFrame)
AuctionContentFrame:SetSize(760, 100)
AuctionScrollFrame:SetScrollChild(AuctionContentFrame)





-------------------------------------------------------------------
-- Info Button on the top left that players can hover over to see 
-- global auction settings
-------------------------------------------------------------------

local InfoButton = CreateFrame("Button", "GDKP_InfoButton", AuctionWindow, "UIPanelButtonTemplate")
InfoButton:SetSize(20, 20)
InfoButton:SetPoint("TOP", AuctionWindow, "TOP", -390, 0)

local InfoButtonIcon = InfoButton:CreateTexture(nil, "OVERLAY")
InfoButtonIcon:SetSize(16, 16) 
InfoButtonIcon:SetPoint("CENTER")
InfoButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

function GDKPT.UI.UpdateInfoButtonStatus()
    local isSynced = GDKPT.Core.leaderSettings and GDKPT.Core.leaderSettings.isSet

    if isSynced then
        InfoButtonIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    else
        InfoButtonIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    end
end

GDKPT.UI.UpdateInfoButtonStatus() 


-- UPDATED: Disable bidding on all auction rows immediately
local function DisableAllBidding()
    for _, row in pairs(GDKPT.Core.AuctionFrames) do
        if row then
            if row.bidButton then
                row.bidButton:Disable()
                row.bidButton:SetText("Syncing...")
            end
            if row.bidBox then
                row.bidBox:EnableMouse(false)
                row.bidBox:ClearFocus()
                row.bidBox:SetText("")
            end
        end
    end
end









local function HideAllAuctionRows()
    for _, row in pairs(GDKPT.Core.AuctionFrames) do
        if row then
            row:Hide()
        end
    end
end


local INFO_BUTTON_COOLDOWN = 10
local lastClickTime = 0



InfoButton:SetScript("OnClick",function(self, button)

    local now = GetTime()

    -- Cooldown check
    if (now - lastClickTime) < INFO_BUTTON_COOLDOWN then
        print("|cffff0000[GDKPT]|r Please wait before clicking again!")
        return
    end

    lastClickTime = now

    -- Disable button briefly (visual feedback)
    self:Disable()
    C_Timer.After(INFO_BUTTON_COOLDOWN, function()
        self:Enable()
    end)

    DisableAllBidding()


    if button == "LeftButton" then
        local msg = "REQUEST_SETTINGS_SYNC"
        SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID") 
    elseif button == "RightButton" then
        HideAllAuctionRows()
        local msg = "REQUEST_AUCTION_SYNC"
        SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID") 
    end
end)


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
            GameTooltip:AddLine("|cff00ff00Auctions are synced|r", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("|cff00ff00Right click for re-sync (10sec cd)|r", 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cffff0000Settings Not Synced|r", 1, 0, 0)
            GameTooltip:AddLine("Press the Sync request button in the middle", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("or left-click the info button!", 0.8, 0.8, 0.8)
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
SyncSettingsButton:SetText("Synchronize Auctions")
SyncSettingsButton:Show() 



local ArrowFrame = CreateFrame("Frame", nil, AuctionWindow)
ArrowFrame:SetSize(200, 200) -- size of the whole indicator
ArrowFrame:SetPoint("CENTER", SyncSettingsButton, "CENTER", 0, 5)

-- Arrow texture pointing downward
local ArrowTexture = ArrowFrame:CreateTexture(nil, "OVERLAY")
ArrowTexture:SetTexture("Interface\\Icons\\ability_blackhand_marked4death") -- placeholder white triangle
ArrowTexture:SetVertexColor(1, 1, 1) 
ArrowTexture:SetSize(64, 64)
ArrowTexture:SetPoint("CENTER", ArrowFrame, "CENTER", 0, 60)

-- "CLICK THIS" text above the arrow
local ArrowText = ArrowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
ArrowText:SetText("CLICK THIS BUTTON")
ArrowText:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
ArrowText:SetTextColor(1, 1, 1, 1)
ArrowText:SetPoint("CENTER", ArrowTexture, "CENTER", 0, 80)

-- Pulsing animation
local ag = ArrowFrame:CreateAnimationGroup()

local fadeOut = ag:CreateAnimation("Alpha")
fadeOut:SetOrder(1)
fadeOut:SetDuration(0.6)
fadeOut:SetChange(-0.7)
fadeOut:SetSmoothing("IN_OUT")

local fadeIn = ag:CreateAnimation("Alpha")
fadeIn:SetOrder(2)
fadeIn:SetDuration(0.6)
fadeIn:SetChange(0.7)
fadeIn:SetSmoothing("IN_OUT")

ag:SetLooping("REPEAT")
ag:Play()





local function RequestSettingsSync(self)
    local leaderName = GDKPT.Utils.GetRaidLeaderName()

    if IsInRaid() and leaderName then

        DisableAllBidding()

        ArrowTexture:Hide()
        ArrowText:Hide()
        local msg = "REQUEST_SETTINGS_SYNC"
        SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")

        self:SetText("Request Sent...")

        C_Timer.After(1,function()
            local msg2 = "REQUEST_AUCTION_SYNC"
            SendAddonMessage(GDKPT.Core.addonPrefix, msg2, "RAID")
        end)

        self:Disable()

        local frame = CreateFrame("Frame")
        local elapsed = 0
        frame:SetScript(
            "OnUpdate",
            function(self, delta)
                elapsed = elapsed + delta
                if elapsed >= 5.0 then
                    self:SetScript("OnUpdate", nil)
                    if not GDKPT.Core.leaderSettings.isSet then
                        SyncSettingsButton:Enable()
                        SyncSettingsButton:SetText("Syncing...")
                    end
                end
            end
        )
        print("|cff99ff99[GDKPT]|r Requesting settings and auctions from raidleader |cffFFC125" .. leaderName .. "|r...")
    else
        print("|cffff8800[GDKPT]|r Error: You must be in a raid with a raidleader to sync auction settings.")
    end
end



SyncSettingsButton:SetScript("OnClick", RequestSettingsSync)




-- Make the DisableAllBidding function available globally if needed elsewhere
GDKPT.UI.DisableAllBidding = DisableAllBidding













-------------------------------------------------------------------
-- Favorite Frame
-------------------------------------------------------------------





local FavoriteFrame = CreateFrame("Frame", "GDKPT_FavoriteListFrame", UIParent) 
FavoriteFrame:SetSize(450, 500)
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
FavoriteFrame:SetClampedToScreen(true)

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


-- Button in AuctionWindow to show FavoriteFrame

local FavoriteFrameButton = CreateFrame("Button", "GDKP_FavoriteFrameButton", AuctionWindow, "UIPanelButtonTemplate")
FavoriteFrameButton:SetSize(120, 22)
FavoriteFrameButton:SetPoint("TOP", AuctionWindow, "TOP", -165, -15)
FavoriteFrameButton:SetText("Favorites List")

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
-- Won Auctions
-------------------------------------------------------------------


local WonAuctionsFrame = CreateFrame("Frame", "GDKP_WonAuctionsFrame", UIParent)
WonAuctionsFrame:SetSize(450, 300)
WonAuctionsFrame:SetPoint("BOTTOMRIGHT", AuctionWindow, "BOTTOMRIGHT", -10, 10)
WonAuctionsFrame:SetBackdrop(
    {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    }
)
WonAuctionsFrame:SetClampedToScreen(true)
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

AuctionWindow.WonAuctionsFrame = WonAuctionsFrame 

local WonAuctionsTitle = WonAuctionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
WonAuctionsTitle:SetText("My Won Auctions")
WonAuctionsTitle:SetPoint("TOP", WonAuctionsFrame, "TOP", 0, -10)
WonAuctionsTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

local CloseWonAuctionsButton = CreateFrame("Button", "", WonAuctionsFrame, "UIPanelCloseButton")
CloseWonAuctionsButton:SetPoint("TOPRIGHT", -5, -5)
CloseWonAuctionsButton:SetSize(35, 35)

-- Button in AuctionWindow to show/hide the WonAuctionsFrame

local WonAuctionsButton = CreateFrame("Button", "GDKP_WonAuctionsButton", AuctionWindow, "UIPanelButtonTemplate")
WonAuctionsButton:SetSize(120, 22)
WonAuctionsButton:SetPoint("TOP", AuctionWindow, "TOP", 165, -15)

WonAuctionsButton:SetText("My Won Auctions")

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
WonAuctionsSummaryPanel:SetSize(450, 80)
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
amountItemsLabel:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -170, 20)
amountItemsLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)

local amountItemsValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
amountItemsValue:SetText(0)
amountItemsValue:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -90, 20)
amountItemsValue:SetFont("Fonts\\FRIZQT__.TTF", 12)

WonAuctionsSummaryPanel.amountItemsValue = amountItemsValue


-- Average cost per item (bottom left)

local averageCostLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
averageCostLabel:SetText("Average Cost:")
averageCostLabel:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -180, -20)
averageCostLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)

local averageCostValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
averageCostValue:SetText(GDKPT.Utils.FormatMoney(0))
averageCostValue:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -80, -20)
averageCostValue:SetFont("Fonts\\FRIZQT__.TTF", 12)


WonAuctionsSummaryPanel.averageCostValue = averageCostValue


-- Total Cost (top right)
local totalCostLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
totalCostLabel:SetText("Total Cost:")
totalCostLabel:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", 50, 20)
totalCostLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)

local totalCostValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
totalCostValue:SetText(GDKPT.Utils.FormatMoney(0))
totalCostValue:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", 170, 20)
totalCostValue:SetFont("Fonts\\FRIZQT__.TTF", 12)

WonAuctionsSummaryPanel.totalCostValue = totalCostValue


-- Gold from Raid (bottom right)
local goldFromRaidLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
goldFromRaidLabel:SetText("Gold from Raid:")
goldFromRaidLabel:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", 50, -20)
goldFromRaidLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)

local goldFromRaidValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
goldFromRaidValue:SetText(GDKPT.Utils.FormatMoney(0))
goldFromRaidValue:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER",  170, -20)
goldFromRaidValue:SetFont("Fonts\\FRIZQT__.TTF", 12)

WonAuctionsSummaryPanel.goldFromRaidValue = goldFromRaidValue






-------------------------------------------------------------------
-- Personal Player History, triggered from a button in the WonAuctionsFrame
-------------------------------------------------------------------


local PlayerHistoryWindow = CreateFrame("Frame", "GDKP_PlayerHistoryWindow", UIParent)
PlayerHistoryWindow:SetSize(500, 550)
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



PlayerHistoryWindow:SetScript(
    "OnShow", 
    function(self)
        if GDKPT.UI.BringToFront then
            GDKPT.UI.BringToFront(self)
        end
        GDKPT.UI.RefreshPlayerHistoryList()
    end
)


-- Button to Show the Personal Player History Window

local PlayerHistoryButton = CreateFrame("Button", "GDKP_PlayerHistoryButton", WonAuctionsFrame, "UIPanelButtonTemplate")
PlayerHistoryButton:SetSize(100, 20)
PlayerHistoryButton:SetPoint("TOPLEFT", WonAuctionsFrame, "TOPLEFT", 5, -5) 
PlayerHistoryButton:SetText("My History")

PlayerHistoryButton:SetScript(
    "OnClick",
    function()
        GDKP_PlayerHistoryWindow:Show()
    end
)



-- Scroll Frame and Content

local HistoryScrollFrame = CreateFrame("ScrollFrame", "GDKP_HistoryScrollFrame", PlayerHistoryWindow, "UIPanelScrollFrameTemplate")
HistoryScrollFrame:SetSize(500, 230)
HistoryScrollFrame:SetPoint("TOPLEFT", PlayerHistoryWindow, 10, -32)
HistoryScrollFrame:SetPoint("BOTTOMRIGHT", PlayerHistoryWindow, -10, 100)


local HistoryContentFrame = CreateFrame("Frame", nil, HistoryScrollFrame)
HistoryContentFrame:SetWidth(HistoryScrollFrame:GetWidth())
HistoryContentFrame:SetHeight(1) -- will be adjusted dynamically
HistoryScrollFrame:SetScrollChild(HistoryContentFrame)



-- Summary on the bottom of the PlayerHistoryWindow

local HistorySummaryPanel = CreateFrame("Frame", nil, PlayerHistoryWindow)
HistorySummaryPanel:SetSize(450, 70)
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
CreateSummaryLine(HistorySummaryPanel, "Average Cost:", 5, -40, "totalAverageCostValue")






-- Function to create a row within the personal player auction history

local function CreateHistoryListRow(parent, index)
    
    local row = CreateFrame("Frame", nil, parent) 
    row:SetHeight(20)
    row:SetWidth(412) 
    row:EnableMouse(true) 
    row:SetPoint("TOPLEFT", 0, -(index - 1) * 20)
    
    -- Date/Timestamp
    row.Date = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.Date:SetPoint("LEFT", 5, 0)
    row.Date:SetWidth(80)
    row.Date:SetJustifyH("LEFT")

    -- Item Link Text
    row.Item = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.Item:SetPoint("LEFT", row.Date, "RIGHT", 20, 0) 
    row.Item:SetWidth(277)
    row.Item:SetJustifyH("LEFT")

    local ItemButton = CreateFrame("Button", nil, row)
    ItemButton:SetAllPoints(row.Item) 

    row:SetScript("OnEnter", function(self)
        self:SetBackdrop({bgFile = "Interface\\Tooltips\\Tooltip-Background"})
        self:SetBackdropColor(0.2, 0.2, 0.2, 0.5)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.data and self.data.itemLink then
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


    -- Auction Price
    row.Price = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.Price:SetPoint("RIGHT", 0, 0)
    row.Price:SetWidth(70)
    row.Price:SetJustifyH("RIGHT")

    -- Used to store the raw item data
    row.data = nil 
   
    return row
end







-- Filters the GDKPT.Core.GeneralHistory table for the current player and returns values
local function FlattenHistoryData()
    local flattenedList = {}
    local totalGoldSpent = 0       
    local totalItemsWon = 0
    
    local generalHistory = GDKPT.Core.History or {}

    local currentPlayerName = UnitName("player") 
    
    for i, item in ipairs(generalHistory) do
        if item.winner == currentPlayerName then
            local price = item.bid or 0
            
            totalGoldSpent = totalGoldSpent + price
            totalItemsWon = totalItemsWon + 1

            table.insert(flattenedList, {
                timestamp = item.timestamp or time(),
                itemLink = item.link or "|cffffffffUnknown Item|r", 
                finalPrice = price, 
                winner = item.winner 
            })
        end
    end

    table.sort(flattenedList, function(a, b)
        return a.timestamp > b.timestamp
    end)

    return flattenedList, totalGoldSpent, totalItemsWon
end



local historyRows = {}

function GDKPT.UI.RefreshPlayerHistoryList()
    local flattenedList, totalGoldSpent, totalItemsWon = FlattenHistoryData() 
    local numItems = #flattenedList
    local totalContentHeight = numItems * 21

    HistoryContentFrame:SetHeight(math.max(totalContentHeight, 1))
    
    HistorySummaryPanel.totalItemsValue:SetText(totalItemsWon)
    HistorySummaryPanel.totalSpentValue:SetText(GDKPT.Utils.FormatMoney(totalGoldSpent * 10000))
    HistorySummaryPanel.totalAverageCostValue:SetText(GDKPT.Utils.FormatMoney(totalGoldSpent/totalItemsWon * 10000))
    
    for i = 1, numItems do
        if not historyRows[i] then
            historyRows[i] = CreateHistoryListRow(HistoryContentFrame, i)
        end
        local row = historyRows[i]
        local itemData = flattenedList[i]
        
        local dateString = date("%d/%m/%Y", itemData.timestamp)   
        row.Date:SetText(dateString)

        row.Item:SetText(itemData.itemLink)
        
        row.Price:SetText(GDKPT.Utils.FormatMoney(itemData.finalPrice * 10000)) 

        row.data = itemData 
        row:Show()
    end

    for i = numItems + 1, #historyRows do
        historyRows[i]:Hide()
    end

    HistoryScrollFrame:SetVerticalScroll(0)
end





-------------------------------------------------------------------
-- General Auction History
-------------------------------------------------------------------

local GeneralHistoryFrame = CreateFrame("Frame", "GDKP_GeneralHistoryFrame", UIParent)
GeneralHistoryFrame:SetSize(800, 400) 
GeneralHistoryFrame:SetPoint("CENTER", AuctionWindow, "CENTER", 0, 0)
GeneralHistoryFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
GeneralHistoryFrame:SetBackdropColor(0, 0, 0, 0.8)
GeneralHistoryFrame:SetFrameLevel(AuctionWindow:GetFrameLevel() + 2)
GeneralHistoryFrame:SetClampedToScreen(true)
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


-- Button in AuctionWindow to show/hide the Auction History


local GeneralHistoryButton = CreateFrame("Button", "GDKP_GeneralHistoryButton", AuctionWindow, "UIPanelButtonTemplate")
GeneralHistoryButton:SetSize(120, 22)
GeneralHistoryButton:SetPoint("TOP", AuctionWindow, "TOP", 300, -15) 
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




local ClearHistoryButton = CreateFrame("Button", "GDKP_ClearHistoryButton", GeneralHistoryFrame, "UIPanelButtonTemplate")
ClearHistoryButton:SetSize(100, 22)
ClearHistoryButton:SetPoint("TOPRIGHT", GeneralHistoryFrame, "TOPRIGHT", -40, -40)
ClearHistoryButton:SetText("Clear History")

ClearHistoryButton:SetScript("OnClick", function()
    StaticPopupDialogs["GDKPT_CONFIRM_CLEAR_HISTORY"] = {
        text = "Are you sure you want to clear ALL auction history? This cannot be undone!",
        button1 = "Yes, Clear All",
        button2 = "Cancel",
        OnAccept = function()
            wipe(GDKPT.Core.History)
            GDKPT.AuctionHistory.UpdateGeneralHistoryList()
            print("|cff00ff00[GDKPT]|r Auction history has been cleared.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("GDKPT_CONFIRM_CLEAR_HISTORY")
end)








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
-- Functions to update the data on the bottom info panel
-------------------------------------------------------------------

function GDKPT.UI.UpdateTotalPotAmount(totalPotValue)
    GDKPT.Core.GDKP_Pot = tonumber(totalPotValue) or 0 
    TotalPotAmountText:SetText(string.format("%s", GDKPT.Utils.FormatMoney(GDKPT.Core.GDKP_Pot)))
end

function GDKPT.UI.UpdateCurrentCutAmount(currentCutValue) 
    local cut = tonumber(currentCutValue) or 0
    GDKPT.Core.PlayerCut = cut 
    CurrentCutAmountText:SetText(string.format("%s", GDKPT.Utils.FormatMoney(cut)))
end

function GDKPT.UI.UpdateCurrentGoldAmount()
    CurrentGoldAmountText:SetText(GDKPT.Utils.FormatMoney(GetMoney()))
end




-------------------------------------------------------------------
-- Function to show the auction window, called through /gdkp show
-- or the toggle button
-------------------------------------------------------------------

function GDKPT.UI.ShowAuctionWindow()
    AuctionWindow:Show()
    GDKPT.UI.UpdateCurrentGoldAmount()
end




-------------------------------------------------------------------
-- MAIN SELECTION WINDOW (/gdkp macro)
-------------------------------------------------------------------

local MacroSelectWindow = CreateFrame("Frame", "GDKP_MacroSelectWindow", UIParent, "BackdropTemplate")
MacroSelectWindow:SetSize(300, 160)
MacroSelectWindow:SetPoint("CENTER")
MacroSelectWindow:Hide()
MacroSelectWindow:SetMovable(true)
MacroSelectWindow:EnableMouse(true)
MacroSelectWindow:RegisterForDrag("LeftButton")
MacroSelectWindow:SetScript("OnDragStart", MacroSelectWindow.StartMoving)
MacroSelectWindow:SetScript("OnDragStop", MacroSelectWindow.StopMovingOrSizing)
MacroSelectWindow:SetFrameStrata("HIGH")

MacroSelectWindow:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
MacroSelectWindow:SetBackdropColor(0, 0, 0, 0.8)

GDKPT.UI.MacroSelectWindow = MacroSelectWindow


local SelectTitle = MacroSelectWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
SelectTitle:SetText("Select a Macro to Copy")
SelectTitle:SetPoint("TOP", 0, -10)
SelectTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

local CloseButtonSelect = CreateFrame("Button", nil, MacroSelectWindow, "UIPanelCloseButton")
CloseButtonSelect:SetPoint("TOPRIGHT", 0, 0)
CloseButtonSelect:SetSize(35, 35)
CloseButtonSelect:SetScript("OnClick", function() MacroSelectWindow:Hide() end)

local FavoriteMacroButton = CreateFrame("Button", nil, MacroSelectWindow, "UIPanelButtonTemplate")
FavoriteMacroButton:SetSize(120, 30)
FavoriteMacroButton:SetPoint("CENTER", 0, 10)
FavoriteMacroButton:SetText("Favorite Macro")

local TradeMacroButton = CreateFrame("Button", nil, MacroSelectWindow, "UIPanelButtonTemplate")
TradeMacroButton:SetSize(120, 30)
TradeMacroButton:SetPoint("CENTER", 0, -30)
TradeMacroButton:SetText("Trade Macro")

-------------------------------------------------------------------
-- FAVORITE MACRO FRAME
-------------------------------------------------------------------

local FavoriteMacroWindow = CreateFrame("Frame", "GDKP_FavoriteMacroWindow", UIParent, "BackdropTemplate")
FavoriteMacroWindow:SetSize(600, 160)
FavoriteMacroWindow:SetPoint("CENTER")
FavoriteMacroWindow:Hide()
FavoriteMacroWindow:SetMovable(true)
FavoriteMacroWindow:EnableMouse(true)
FavoriteMacroWindow:RegisterForDrag("LeftButton")
FavoriteMacroWindow:SetScript("OnDragStart", FavoriteMacroWindow.StartMoving)
FavoriteMacroWindow:SetScript("OnDragStop", FavoriteMacroWindow.StopMovingOrSizing)
FavoriteMacroWindow:SetFrameStrata("HIGH")

FavoriteMacroWindow:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
FavoriteMacroWindow:SetBackdropColor(0, 0, 0, 0.8)

local FavTitle = FavoriteMacroWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FavTitle:SetText("Favorite Item Macro")
FavTitle:SetPoint("TOP", 0, -10)
FavTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

local FavClose = CreateFrame("Button", nil, FavoriteMacroWindow, "UIPanelCloseButton")
FavClose:SetPoint("TOPRIGHT", 0, 0)
FavClose:SetSize(35, 35)
FavClose:SetScript("OnClick", function() FavoriteMacroWindow:Hide() end)

local FavEditBox = CreateFrame("EditBox", nil, FavoriteMacroWindow, "InputBoxTemplate")
FavEditBox:SetPoint("TOPLEFT", 15, -40)
FavEditBox:SetPoint("BOTTOMRIGHT", -15, 40)
FavEditBox:SetText('/run DEFAULT_CHAT_FRAME.editBox:SetText("/gdkp f " .. select(2, GameTooltip:GetItem()));ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)')
FavEditBox:SetFontObject(GameFontNormalSmall)
FavEditBox:SetAutoFocus(false)
FavEditBox:SetMultiLine(true)
FavEditBox:SetJustifyH("LEFT")
FavEditBox:SetJustifyV("TOP")
FavEditBox:EnableMouse(true)
FavEditBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)
FavEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local FavInstructions = FavoriteMacroWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
FavInstructions:SetText("Copy this macro to favorite items on mouseover.")
FavInstructions:SetPoint("BOTTOM", FavEditBox, "TOP", 0, 5)
FavInstructions:SetTextColor(1, 1, 1)

-------------------------------------------------------------------
-- TRADE MACRO FRAME
-------------------------------------------------------------------

local TradeMacroWindow = CreateFrame("Frame", "GDKP_TradeMacroWindow", UIParent, "BackdropTemplate")
TradeMacroWindow:SetSize(600, 160)
TradeMacroWindow:SetPoint("CENTER")
TradeMacroWindow:Hide()
TradeMacroWindow:SetMovable(true)
TradeMacroWindow:EnableMouse(true)
TradeMacroWindow:RegisterForDrag("LeftButton")
TradeMacroWindow:SetScript("OnDragStart", TradeMacroWindow.StartMoving)
TradeMacroWindow:SetScript("OnDragStop", TradeMacroWindow.StopMovingOrSizing)
TradeMacroWindow:SetFrameStrata("HIGH")

TradeMacroWindow:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
TradeMacroWindow:SetBackdropColor(0, 0, 0, 0.8)

local TradeTitle = TradeMacroWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
TradeTitle:SetText("Trade Macro")
TradeTitle:SetPoint("TOP", 0, -10)
TradeTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

local TradeClose = CreateFrame("Button", nil, TradeMacroWindow, "UIPanelCloseButton")
TradeClose:SetPoint("TOPRIGHT", 0, 0)
TradeClose:SetSize(35, 35)
TradeClose:SetScript("OnClick", function() TradeMacroWindow:Hide() end)

local TradeEditBox = CreateFrame("EditBox", nil, TradeMacroWindow, "InputBoxTemplate")
TradeEditBox:SetPoint("TOPLEFT", 15, -40)
TradeEditBox:SetPoint("BOTTOMRIGHT", -15, 40)
TradeEditBox:SetText("/run GDKPT_AutoTradeButton:Click();")
TradeEditBox:SetFontObject(GameFontNormalSmall)
TradeEditBox:SetAutoFocus(false)
TradeEditBox:SetMultiLine(true)
TradeEditBox:SetJustifyH("LEFT")
TradeEditBox:SetJustifyV("TOP")
TradeEditBox:EnableMouse(true)
TradeEditBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)
TradeEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local TradeInstructions = TradeMacroWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TradeInstructions:SetText("Copy this macro to auto-click the trade button after pot split.")
TradeInstructions:SetPoint("BOTTOM", TradeEditBox, "TOP", 0, 5)
TradeInstructions:SetTextColor(1, 1, 1)

-------------------------------------------------------------------
-- BUTTON HANDLERS
-------------------------------------------------------------------

FavoriteMacroButton:SetScript("OnClick", function()
    MacroSelectWindow:Hide()
    FavoriteMacroWindow:Show()
    FavEditBox:SetFocus()
    FavEditBox:HighlightText()
end)

TradeMacroButton:SetScript("OnClick", function()
    MacroSelectWindow:Hide()
    TradeMacroWindow:Show()
    TradeEditBox:SetFocus()
    TradeEditBox:HighlightText()
end)






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
GDKPToggleButton:SetClampedToScreen(true)


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
        GDKPT.UI.ShowAuctionWindow()
        if GDKPT.Core.Settings.HideToggleButton == 1 then
            self:Hide()
        end
    end
)


GDKPToggleButton:SetScript("OnDragStart", GDKPToggleButton.StartMoving)

GDKPToggleButton:SetScript(
    "OnDragStop",
    function(self)
        self:StopMovingOrSizing()

        local point, _, _, x, y = self:GetPoint()

        local settings = GDKPT.Core.Settings
        if settings then
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
   -- GDKPToggleButton:Hide() 
end

UpdateToggleButtonVisibility()




-------------------------------------------------------------------
-- Addon Settings 
-------------------------------------------------------------------



local SettingsFrame = CreateFrame("Frame", "GDKPT_SettingsFrame", UIParent) 
SettingsFrame:SetSize(380, 480)
SettingsFrame:SetPoint("CENTER", AuctionWindow, "CENTER", 0, 0)
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

SettingsFrame:SetFrameLevel(AuctionWindow:GetFrameLevel() + 2)

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





-- Button in AuctionWindow to show SettingsFrame

local SettingsFrameButton = CreateFrame("Button", "GDKP_SettingsFrameButton", AuctionWindow, "UIPanelButtonTemplate")
SettingsFrameButton:SetSize(120, 15)
SettingsFrameButton:SetPoint("TOP", AuctionWindow, "TOP", 0, -25)
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


-------------------------------------------------------------------
-- Setting rows
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
        print("|cffFFC125[GDKPT]|r "..label.." set to: "..(self:GetChecked() and "ON" or "OFF"))
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
    {"HideToggleButton", "Hide GDKPT Auction Window toggle button after opening the Auction Window"},
    {"AutoFillTradeGold", "Enable Autofill Button functionality on GDKP - Trades"},
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
-- Finalize
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




-------------------------------------------------------
-- Notification frame 
-------------------------------------------------------


local OutbidMessageFrame = CreateFrame("Frame", "GDKPT_OutbidMessageFrame", AuctionWindow)
OutbidMessageFrame:SetSize(760, 25)
OutbidMessageFrame:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", 0, -35)
OutbidMessageFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets = {left = 2, right = 2, top = 2, bottom = 2}
})
OutbidMessageFrame:SetBackdropColor(0.8, 0.2, 0.2, 0.7)
OutbidMessageFrame:SetBackdropBorderColor(1, 0, 0, 1)
OutbidMessageFrame:Hide()

OutbidMessageFrame.Text = OutbidMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
OutbidMessageFrame.Text:SetPoint("CENTER")
OutbidMessageFrame.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

GDKPT.UI.OutbidMessageFrame = OutbidMessageFrame

-- Function to show outbid message
function GDKPT.UI.ShowOutbidMessage(auctionId, itemLink, newBidder, newBid)
    local frame = GDKPT.UI.OutbidMessageFrame
    if not frame then return end
    
    local message = string.format("You've been OUTBID on Auction #%d (%s) by %s with %dg!", 
        auctionId, itemLink, newBidder, newBid)
    
    frame.Text:SetText(message)
    frame:Show()
    
    -- Flash the frame
    --UIFrameFlash(frame, 10, 5, 15, false, 0, 0)
    
    -- Auto-hide after 5 seconds
    C_Timer.After(10, function()
        frame:Hide()
    end)
end







-------------------------------------------------------------------
-- Frame that alerts players when their favorite item dropped
-------------------------------------------------------------------


GDKPT.UI.FavoriteAlertFrame = CreateFrame("Frame", nil, UIParent)
local alertFrame = GDKPT.UI.FavoriteAlertFrame

alertFrame:SetSize(250, 60)
alertFrame:SetPoint("CENTER", 0, -100) 
alertFrame:SetFrameStrata("HIGH") 
alertFrame:Hide()


alertFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
alertFrame:SetBackdropColor(0, 0.1, 0.4, 0.9) 

alertFrame.ItemIcon = alertFrame:CreateTexture(nil, "ARTWORK")
alertFrame.ItemIcon:SetSize(50, 50)
alertFrame.ItemIcon:SetPoint("LEFT", 5, 0)

alertFrame.AlertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
alertFrame.AlertText:SetPoint("TOPLEFT", alertFrame.ItemIcon, "TOPRIGHT", 5, -5)
alertFrame.AlertText:SetText("|cff00FFFFFAVORITE LOOT DROPPED!|r")
alertFrame.AlertText:SetTextColor(0, 1, 1, 1) -- Cyan

alertFrame.ItemName = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
alertFrame.ItemName:SetPoint("BOTTOMLEFT", alertFrame.ItemIcon, "BOTTOMRIGHT", 5, 5)
alertFrame.ItemName:SetPoint("RIGHT", -5, 0)
alertFrame.ItemName:SetText("...") 

alertFrame.CloseButton = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
alertFrame.CloseButton:SetSize(20, 20)
alertFrame.CloseButton:SetPoint("TOPRIGHT", 0, 0)
alertFrame.CloseButton:SetScript("OnClick", function(self)
    alertFrame:Hide()
    UIFrameFlash(alertFrame, 0) 
end)







-------------------------------------------------------------------
-- Function to visually reset the auction window
-------------------------------------------------------------------

function GDKPT.UI.ResetAuctionWindow()
    -- Clear all children from content frame
    local children = {GDKPT.UI.AuctionContentFrame:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Reset scroll position
    if GDKPT.UI.AuctionScrollFrame and GDKPT.UI.AuctionScrollFrame.ScrollBar then
        GDKPT.UI.AuctionScrollFrame.ScrollBar:SetValue(0)
    end
    
    -- Reset content frame size
    GDKPT.UI.AuctionContentFrame:SetHeight(100)
end








-------------------------------------------------------------------
-- Filter by favorites Button
-------------------------------------------------------------------

local FavoriteFilterButton = CreateFrame("Button", "GDKP_FavoriteFilterButton", AuctionWindow, "UIPanelButtonTemplate")

--[[
FavoriteFilterButton:SetSize(120, 22)
FavoriteFilterButton:SetPoint("TOP", AuctionWindow, "TOP", -300, -15)

function GDKPT.UI.UpdateFilterButtonText()
    if not GDKPT.Core.isFavoriteFilterActive then
        FavoriteFilterButton:SetText("Filter Favorites")
    else
        FavoriteFilterButton:SetText("Show All Auctions")
    end
end

GDKPT.UI.UpdateFilterButtonText() 
]]








-------------------------------------------------------------------
-- Auction Filters
-------------------------------------------------------------------

GDKPT.AuctionFilters = GDKPT.AuctionFilters or {}

-- Initialize filter states (if not done elsewhere)
GDKPT.Core.FilterMyBidsActive = false
GDKPT.Core.FilterOutbidActive = false
GDKPT.Core.isFavoriteFilterActive = false -- You already have this

-------------------------------------------------------------------
-- New Auction Filter Dropdown
-------------------------------------------------------------------


-- Create the dropdown frame
local FilterDropdown = CreateFrame("Frame", "GDKPT_FilterDropdown", AuctionWindow, "UIDropDownMenuTemplate")
FilterDropdown:SetPoint("TOP", AuctionWindow, "TOP", -350, -15)
UIDropDownMenu_SetWidth(FilterDropdown, 100)
UIDropDownMenu_SetButtonWidth(FilterDropdown, 100)




function GDKPT.AuctionFilters.ApplyAllFilters()
    local playerName = UnitName("player")
    
    -- Check if any filters are active
    local anyFilterActive = GDKPT.Core.FilterMyBidsActive or 
                            GDKPT.Core.FilterOutbidActive or 
                            GDKPT.Core.isFavoriteFilterActive
    
    if not anyFilterActive then
        -- No filters: show all rows
        for _, row in pairs(GDKPT.Core.AuctionFrames) do
            row:Show()
        end
    else
        -- At least one filter is active
        for auctionId, row in pairs(GDKPT.Core.AuctionFrames) do
            local showRow = false
            
            -- "My Bids" filter
            if GDKPT.Core.FilterMyBidsActive then
                if GDKPT.Core.PlayerBidHistory[auctionId] then
                    showRow = true
                end
            end
            
            -- "Outbid" filter
            if GDKPT.Core.FilterOutbidActive then
                local hasBid = GDKPT.Core.PlayerBidHistory[auctionId]
                local isWinning = (row.topBidder == playerName)
                if hasBid and not isWinning and row.topBidder ~= "" then
                    showRow = true
                end
            end
            
            -- "Favorites" filter
            if GDKPT.Core.isFavoriteFilterActive then
                if row.isFavorite then
                    showRow = true
                end
            end
            
            -- Apply visibility (OR logic: show if ANY filter matches)
            if showRow then
                row:Show()
            else
                row:Hide()
            end
        end
    end
    
    -- Reposition all visible auctions
    if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
        GDKPT.AuctionLayout.RepositionAllAuctions()
    end
    
    -- Update the dropdown text
    GDKPT.UI.UpdateFilterDropdownText()
end




function GDKPT.UI.UpdateFilterDropdownText()
    local filters = {}
    if GDKPT.Core.FilterMyBidsActive then
        table.insert(filters, "My Bids")
    end
    if GDKPT.Core.FilterOutbidActive then
        table.insert(filters, "Outbid")
    end
    if GDKPT.Core.isFavoriteFilterActive then
        table.insert(filters, "Favs")
    end
    
    if #filters == 0 then
        UIDropDownMenu_SetText(FilterDropdown, "All")
    elseif #filters == 1 then
        -- Shorten text for single filters
        local text = filters[1]
        if text == "My Bids" then
            text = "Bids"
        elseif text == "Favorites" then
            text = "Favs"
        end
        UIDropDownMenu_SetText(FilterDropdown, text)
    else
        -- Show count for multiple filters
        UIDropDownMenu_SetText(FilterDropdown, filters[1] .. " +" .. (#filters - 1))
    end
end



local function FilterDropdown_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()

    -- "Show All" option
    info.text = "Show All"
    info.value = "showall"
    info.notCheckable = true  -- This is a button, not checkbox
    info.func = function()
        GDKPT.Core.FilterMyBidsActive = false
        GDKPT.Core.FilterOutbidActive = false
        GDKPT.Core.isFavoriteFilterActive = false
        GDKPT.AuctionFilters.ApplyAllFilters()
        CloseDropDownMenus()  -- Close menu after selection
    end
    UIDropDownMenu_AddButton(info, level)

    -- Divider
    info = UIDropDownMenu_CreateInfo()
    info.disabled = 1
    info.notCheckable = 1
    info.text = ""
    UIDropDownMenu_AddButton(info, level)

    -- "My Bids" checkbox
    info = UIDropDownMenu_CreateInfo()
    info.text = "My Bids"
    info.value = "mybids"
    info.keepShownOnClick = true  -- FIXED: Correct property name
    info.isNotRadio = true
    info.checked = GDKPT.Core.FilterMyBidsActive
    info.func = function(self)
        GDKPT.Core.FilterMyBidsActive = not GDKPT.Core.FilterMyBidsActive
        GDKPT.AuctionFilters.ApplyAllFilters()
    end
    UIDropDownMenu_AddButton(info, level)
    
    -- "Outbid" checkbox
    info = UIDropDownMenu_CreateInfo()
    info.text = "Outbid"
    info.value = "outbid"
    info.keepShownOnClick = true
    info.isNotRadio = true
    info.checked = GDKPT.Core.FilterOutbidActive
    info.func = function(self)
        GDKPT.Core.FilterOutbidActive = not GDKPT.Core.FilterOutbidActive
        GDKPT.AuctionFilters.ApplyAllFilters()
    end
    UIDropDownMenu_AddButton(info, level)
    
    -- "Favorites" checkbox
    info = UIDropDownMenu_CreateInfo()
    info.text = "Favorites"
    info.value = "favorites"
    info.keepShownOnClick = true
    info.isNotRadio = true
    info.checked = GDKPT.Core.isFavoriteFilterActive
    info.func = function(self)
        GDKPT.Core.isFavoriteFilterActive = not GDKPT.Core.isFavoriteFilterActive
        GDKPT.AuctionFilters.ApplyAllFilters()
    end
    UIDropDownMenu_AddButton(info, level)
end

-- Initialize the dropdown
UIDropDownMenu_Initialize(FilterDropdown, FilterDropdown_Initialize)

-- Set initial text
GDKPT.UI.UpdateFilterDropdownText()

-- FIXED: Make dropdown smaller by adjusting the frame itself
FilterDropdown:SetScale(0.9)  -- Scale down the entire dropdown by 10%












-------------------------------------------------------------------
-- Frame and Content exposing for other files
-------------------------------------------------------------------


GDKPT.UI.AuctionWindow = AuctionWindow
GDKPT.UI.AuctionContentFrame = AuctionContentFrame
GDKPT.UI.FavoriteFilterButton = FavoriteFilterButton
GDKPT.UI.SyncSettingsButton = SyncSettingsButton
GDKPT.UI.AuctionScrollFrame = AuctionScrollFrame
GDKPT.UI.WonAuctionsFrame = WonAuctionsFrame
GDKPT.UI.ArrowFrame = ArrowFrame
GDKPT.UI.ArrowText = ArrowText


GDKPT.UI.FavoriteFrame = FavoriteFrame
GDKPT.UI.FavoriteScrollFrame = FavoriteScrollFrame
GDKPT.UI.FavoriteScrollContent = FavoriteScrollContent

GDKPT.UI.SettingsFrame = SettingsFrame
GDKPT.UI.SettingsScrollContent = SettingsScrollContent 
GDKPT.UI.SettingsFrameButton = SettingsFrameButton



