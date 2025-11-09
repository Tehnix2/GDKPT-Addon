GDKPT.MyWonAuctions = {}


-------------------------------------------------------------------
-- Won Auctions
-------------------------------------------------------------------


local WonAuctionsFrame = CreateFrame("Frame", "GDKP_WonAuctionsFrame", UIParent)
WonAuctionsFrame:SetSize(450, 300)
WonAuctionsFrame:SetPoint("BOTTOMRIGHT", GDKPT.UI.AuctionWindow, "BOTTOMRIGHT", -10, 10)
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
WonAuctionsFrame:SetFrameLevel(GDKPT.UI.AuctionWindow:GetFrameLevel() + 2)
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

GDKPT.UI.AuctionWindow.WonAuctionsFrame = WonAuctionsFrame 

local WonAuctionsTitle = WonAuctionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
WonAuctionsTitle:SetText("My Won Auctions")
WonAuctionsTitle:SetPoint("TOP", WonAuctionsFrame, "TOP", 0, -10)
WonAuctionsTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

local CloseWonAuctionsButton = CreateFrame("Button", "", WonAuctionsFrame, "UIPanelCloseButton")
CloseWonAuctionsButton:SetPoint("TOPRIGHT", -5, -5)
CloseWonAuctionsButton:SetSize(35, 35)

-- Button in AuctionWindow to show/hide the WonAuctionsFrame

local WonAuctionsButton = CreateFrame("Button", "GDKP_WonAuctionsButton", GDKPT.UI.AuctionWindow, "UIPanelButtonTemplate")
WonAuctionsButton:SetSize(120, 22)
WonAuctionsButton:SetPoint("TOP", GDKPT.UI.AuctionWindow, "TOP", 250, -15)

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


















--Expose button for slash command
GDKPT.MyWonAuctions.WonAuctionsButton = WonAuctionsButton

GDKPT.MyWonAuctions.WonAuctionsFrame = WonAuctionsFrame