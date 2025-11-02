GDKPT.AuctionHistory = GDKPT.AuctionHistory or {}

local HistoryEntryPool = {}
local HistoryEntryID = 1






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
