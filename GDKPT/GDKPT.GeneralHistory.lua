GDKPT.AuctionHistory = GDKPT.AuctionHistory or {}

local HistoryEntryPool = {}
local HistoryEntryID = 1




-------------------------------------------------------------------
-- General Auction History
-------------------------------------------------------------------

local GeneralHistoryFrame = CreateFrame("Frame", "GDKP_GeneralHistoryFrame", UIParent)
GeneralHistoryFrame:SetSize(800, 400) 
GeneralHistoryFrame:SetPoint("CENTER", GDKPT.UI.AuctionWindow, "CENTER", 0, 0)
GeneralHistoryFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
GeneralHistoryFrame:SetBackdropColor(0, 0, 0, 0.8)
GeneralHistoryFrame:SetFrameLevel(GDKPT.UI.AuctionWindow:GetFrameLevel() + 2)
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


local GeneralHistoryButton = CreateFrame("Button", "GDKP_GeneralHistoryButton", GDKPT.UI.AuctionWindow, "UIPanelButtonTemplate")
GeneralHistoryButton:SetSize(120, 22)
GeneralHistoryButton:SetPoint("TOP", GDKPT.UI.AuctionWindow, "TOP", 380, -15) 
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

-- Expose button for slash command

GDKPT.UI.GeneralHistoryButton = GeneralHistoryButton




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




local function CreateHistoryEntry(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(32)
    frame:EnableMouse(true)

    -- Date/Timestamp
    frame.Date = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    frame.Date:SetPoint("LEFT", 5, 0)
    frame.Date:SetWidth(80)
    frame.Date:SetJustifyH("LEFT")
    
    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", frame.Date, "RIGHT", 5, 0)
    frame.icon = icon

    -- Item Name (Text)
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetJustifyH("LEFT")
    frame.nameText = nameText

    -- Winner Name (Text)
    local winnerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    winnerText:SetPoint("RIGHT", -150, 0)
    winnerText:SetJustifyH("RIGHT")
    frame.winnerText = winnerText

    -- Bid Amount (Text)
    local bidText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bidText:SetPoint("RIGHT", -5, 0)
    bidText:SetJustifyH("RIGHT")
    frame.bidText = bidText

    -- Mouseover for tooltip
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.isAdjustment then
            GameTooltip:SetText("Manual Adjustment", 1, 1, 1)
            GameTooltip:AddLine("Player: " .. self.winner, 1, 1, 1)
            local adjustmentType = (self.bidAmount > 0) and "Increased debt" or "Reduced debt"
            GameTooltip:AddLine(adjustmentType .. ": " .. math.abs(self.bidAmount) .. " Gold")
        elseif self.itemLink then
            GameTooltip:SetHyperlink(self.itemLink)
        else
            GameTooltip:SetText("Winner: " .. self.winner, 1, 1, 1)
            GameTooltip:AddLine("Won for: " .. self.bidAmount .. " Gold")
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return frame
end








function GDKPT.AuctionHistory.UpdateGeneralHistoryList()
    local HistoryFrame = GDKPT.UI.GeneralHistoryFrame
    local ScrollFrame = HistoryFrame.ScrollFrame
    local ScrollContent = HistoryFrame.ScrollFrame:GetScrollChild()

    if not ScrollContent then return end

    local filter = (HistoryFrame.FilterText or ""):lower()

    for i, entry in ipairs(HistoryEntryPool) do
        entry:Hide()
    end
    HistoryEntryID = 1
    
    local historyTable = GDKPT.Core.History
    local totalHeight = 0
    local count = #historyTable

    -- Loop backwards to show newest items on top
    for i = count, 1, -1 do
        local item = historyTable[i]
        
        local itemName = "Unknown Item"
        local texture = nil
        
        -- Check if this is a manual adjustment
        if item.isAdjustment then
            itemName = "Manual Adjustment"
            texture = "Interface\\Icons\\INV_Misc_Coin_02"
        elseif item.link then
            local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(item.link)
            itemName = name or "Unknown Item"
            texture = tex
        end
        
        local itemNameLower = itemName:lower()
        local winnerLower = (item.winner or ""):lower()
        
        local shouldShow = filter == "" or winnerLower:match(filter) or itemNameLower:match(filter)
        
        if shouldShow then
            local entry = HistoryEntryPool[HistoryEntryID]
            if not entry then
                entry = CreateHistoryEntry(ScrollContent)
                HistoryEntryPool[HistoryEntryID] = entry
            end
            HistoryEntryID = HistoryEntryID + 1

            entry.timestamp = item.timestamp
            entry.itemLink = item.link
            entry.bidAmount = item.bid
            entry.winner = item.winner
            entry.isAdjustment = item.isAdjustment or false
            
            entry.Date:SetText(date("%d/%m/%Y", entry.timestamp))
            
            if item.isAdjustment then
                local color = (item.bid > 0) and "|cffff0000" or "|cff00ff00"
                local prefix = (item.bid > 0) and "+" or ""
                entry.nameText:SetText(color .. "Manual Adjustment|r")
                entry.bidText:SetText(color .. prefix .. GDKPT.Utils.FormatMoney(item.bid * 10000) .. "|r")
            else
                entry.nameText:SetText(itemName)
                entry.bidText:SetText(GDKPT.Utils.FormatMoney(item.bid * 10000))
            end
            
            entry.winnerText:SetText(item.winner)
            entry.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

            local prevEntry = HistoryEntryPool[HistoryEntryID - 2]
            if not prevEntry then
                entry:SetPoint("TOP", ScrollContent, "TOP", 0, -2)
            else
                entry:SetPoint("TOP", prevEntry, "BOTTOM", 0, -2)
            end

            entry:SetWidth(ScrollContent:GetWidth())
            entry:Show()
            totalHeight = totalHeight + entry:GetHeight() + 2
        end
    end

    local contentHeight = math.max(ScrollFrame:GetHeight(), totalHeight + 2)
    ScrollContent:SetHeight(contentHeight)
    
    if ScrollFrame.ScrollBar then
        ScrollFrame.ScrollBar:SetValue(0)
    end
end
