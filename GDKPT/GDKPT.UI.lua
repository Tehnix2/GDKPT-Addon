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

local function HideAllAuctionRows()
    for _, row in pairs(GDKPT.Core.AuctionFrames) do
        if row then
            row:Hide()
        end
    end
end



InfoButton:SetScript("OnClick",function(self, button)

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





-------------------------------------------------------------------
-- Filter by favorites Button
-------------------------------------------------------------------

local FavoriteFilterButton = CreateFrame("Button", "GDKP_FavoriteFilterButton", AuctionWindow, "UIPanelButtonTemplate")
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
WonAuctionsSummaryPanel:SetSize(400, 80)
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
amountItemsLabel:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -140, 20)
amountItemsLabel:SetFont("Fonts\\FRIZQT__.TTF", 12)

local amountItemsValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
amountItemsValue:SetText(0)
amountItemsValue:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -60, 20)
amountItemsValue:SetFont("Fonts\\FRIZQT__.TTF", 12)

WonAuctionsSummaryPanel.amountItemsValue = amountItemsValue


-- Average cost per item (bottom left)

local averageCostLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
averageCostLabel:SetText("Average Cost:")
averageCostLabel:SetPoint("CENTER", WonAuctionsSummaryPanel, "CENTER", -150, -20)
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




--[[

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



]]







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


local SettingsScrollFrame = CreateFrame("ScrollFrame", "GDKP_FavoritesScrollFrame", SettingsFrame, "UIPanelScrollFrameTemplate")
SettingsScrollFrame:SetPoint("TOPLEFT", 10, -35)
SettingsScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

SettingsFrame.ScrollFrame = SettingsScrollFrame

local SettingsScrollContent = CreateFrame("Frame", nil, SettingsScrollFrame)
SettingsScrollContent:SetWidth(SettingsScrollFrame:GetWidth())
SettingsScrollContent:SetHeight(1) 
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
    {"AutoFillTradeGold", "Auto-fill gold values on auction trades with the leader"},
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



--[[






-------------------------------------------------------------------
-- Setting: Require Bid Confirmation
-------------------------------------------------------------------

local ConfirmBidCheckButton = CreateFrame("CheckButton", "GDKPT_ConfirmBidCheckButton", SettingsScrollContent, "UICheckButtonTemplate")
ConfirmBidCheckButton:SetSize(24, 24)
ConfirmBidCheckButton:SetPoint("TOPLEFT", 10, -5) 

local ConfirmBidText = ConfirmBidCheckButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ConfirmBidText:SetPoint("LEFT", ConfirmBidCheckButton, "RIGHT", 5, 0)
ConfirmBidText:SetText("Require bid confirmation")

SettingsScrollContent:SetHeight(ConfirmBidCheckButton:GetBottom() * -1 + 5) 


local function UpdateConfirmBidState()
    -- ConfirmBid: 1 = enabled (checked), 0 = disabled (unchecked)
    local isEnabled = (GDKPT.Core.Settings.ConfirmBid == 1)
    ConfirmBidCheckButton:SetChecked(isEnabled)
end

-- Set the initial state when the frame is created
UpdateConfirmBidState()

ConfirmBidCheckButton:SetScript(
    "OnClick",
    function(self)
        local isChecked = self:GetChecked()
        GDKPT.Core.Settings.ConfirmBid = isChecked and 1 or 0
        print("[GDKPT] ConfirmBid setting changed to:", GDKPT.Core.Settings.ConfirmBid)
    end
)

SettingsFrame:SetScript(
    "OnShow",
    function(self)
        GDKPT.Utils.BringToFront(self)
        UpdateConfirmBidState() -- Ensure the checkbox state matches the setting
    end
)

SettingsFrame.ConfirmBidCheckButton = ConfirmBidCheckButton



]]




-- Settings ideas:
-- ConfirmBid popup for bidbutton -> yes/no
-- ConfirmBid popup for bidBox -> yes/no
-- ConfirmAutoBid popup when setting autobid for a favorited item -> yes/no
-- Limit bids to total current gold on character -> yes/no
-- Hide GDKPT Auction Window toggle button on click -> yes/no
-- 
-- Auto fill in gold values on trades for won auctions -> yes/no ---> double popup to really confirm this 
--
-- Favorites section
-- - Show favorite item auctions in golden rows -> yes/no
-- - Alwys show favorite item auctions on the top when filtering by favorites -> yes/no
-- - Chat alert when lootmaster is looting a favorited item -> yes/no
-- - Popup frame notification when lootmaster is looting a favorited item -> yes/no
-- - Audio alert when lootmaster is looting a favorited item -> yes/no
--

-- 




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



