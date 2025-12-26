GDKPT.PlayerHistory = {}



-------------------------------------------------------------------
-- Personal Player History
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
PlayerHistoryWindow:SetFrameLevel(GDKPT.UI.AuctionWindow:GetFrameLevel() + 5)


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
        if GDKPT.Utils.BringToFront then
            GDKPT.Utils.BringToFront(self)
        end
        GDKPT.PlayerHistory.RefreshPlayerHistoryList()
    end
)


-- Button to Show the Personal Player History Window

local PlayerHistoryButton = CreateFrame("Button", "GDKP_PlayerHistoryButton", GDKPT.MyWonAuctions.WonAuctionsFrame, "UIPanelButtonTemplate")
PlayerHistoryButton:SetSize(100, 20)
PlayerHistoryButton:SetPoint("TOPLEFT", GDKPT.MyWonAuctions.WonAuctionsFrame, "TOPLEFT", 5, -5) 
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

function GDKPT.PlayerHistory.RefreshPlayerHistoryList()
    local flattenedList, totalGoldSpent, totalItemsWon = FlattenHistoryData() 
    local numItems = #flattenedList
    local totalContentHeight = numItems * 21

    HistoryContentFrame:SetHeight(math.max(totalContentHeight, 1))
    
    HistorySummaryPanel.totalItemsValue:SetText(totalItemsWon)
    HistorySummaryPanel.totalSpentValue:SetText(GDKPT.Utils.FormatMoney(totalGoldSpent * 10000))

    local averageCost = 0
    if totalItemsWon > 0 then
        averageCost = totalGoldSpent / totalItemsWon
    end
    HistorySummaryPanel.totalAverageCostValue:SetText(GDKPT.Utils.FormatMoney(averageCost * 10000))
    
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





-- Expose button for slash command

GDKPT.UI.PlayerHistoryButton = PlayerHistoryButton