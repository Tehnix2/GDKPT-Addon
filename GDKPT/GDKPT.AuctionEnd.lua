
GDKPT.AuctionEnd = {}


local WonItemEntryPool = {}
local WonItemEntryID = 1


local function CreateWonAuctionEntry(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(32)
    frame:EnableMouse(true)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", frame, "LEFT", 40, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.icon = icon

    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetJustifyH("LEFT")
    frame.nameText = nameText

    local bidText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bidText:SetPoint("RIGHT", -5, 0)
    bidText:SetJustifyH("RIGHT")
    frame.bidText = bidText


    frame.adjustmentOverlay = CreateFrame("Frame", nil, frame)
    frame.adjustmentOverlay:SetPoint("TOPLEFT", frame, "TOPLEFT", 34, -2)
    frame.adjustmentOverlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 2) 
    frame.adjustmentOverlay:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.adjustmentOverlay:Hide()
    
    frame.adjustmentOverlay:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    frame.adjustmentOverlay:SetBackdropColor(0.8, 0.4, 0, 0.7)
    frame.adjustmentOverlay:SetBackdropBorderColor(1, 0.5, 0, 1)
    
    frame.adjustmentText = frame.adjustmentOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.adjustmentText:SetPoint("CENTER")
    frame.adjustmentText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")


    frame:SetScript(
        "OnEnter",
        function(self)
            if self.isAdjustment then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Manual Adjustment", 1, 1, 1)
                local adjustmentType = (self.bidAmount > 0) and "Added to your debt" or "Reduced from your debt"
                GameTooltip:AddLine(string.format("%s: %s", adjustmentType, GDKPT.Utils.FormatMoney(math.abs(self.bidAmount) * 10000)))
                GameTooltip:Show()
            elseif self.itemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.itemLink)
                
                -- Show payment status in tooltip
                if self.amountPaid and self.amountPaid > 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(string.format("Paid: %s", GDKPT.Utils.FormatMoney(self.amountPaid * 10000)), 0, 1, 0)
                    if self.amountOwed and self.amountOwed > 0 then
                        GameTooltip:AddLine(string.format("Still Owed: %s", GDKPT.Utils.FormatMoney(self.amountOwed * 10000)), 1, 0.5, 0)
                    end
                end
                GameTooltip:Show()
            else
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.itemName, 1, 1, 1)
                GameTooltip:AddLine("Won for: " .. self.bidAmount .. " Gold")
                GameTooltip:Show()
            end
        end
    )
    frame:SetScript(
        "OnLeave",
        function()
            GameTooltip:Hide()
        end
    )

    return frame
end




function GDKPT.AuctionEnd.UpdateWonItemsList(ScrollFrame, ScrollContent)

    for i, entry in ipairs(WonItemEntryPool) do
        entry:Hide()
    end
    WonItemEntryID = 1

    local totalHeight = 0

    if not ScrollContent then
        print("|cffff3333[GDKPT]|r Error: ScrollContent for My Won Items is missing. UI not fully initialized.")
        return
    end

    for i, item in ipairs(GDKPT.Core.PlayerWonItems) do
        local entry = WonItemEntryPool[WonItemEntryID]
        if not entry then
            entry = CreateWonAuctionEntry(ScrollContent)
            WonItemEntryPool[WonItemEntryID] = entry
        end
        WonItemEntryID = WonItemEntryID + 1

        if item.isAdjustment then
            entry.isAdjustment = true
            entry.itemName = "Manual Adjustment"
            entry.itemLink = nil
            entry.bidAmount = item.bid

            local color = (item.bid > 0) and "|cffff0000" or "|cff00ff00" 
            entry.nameText:SetText(color .. "Manual Adjustment|r")
            entry.bidText:SetText(color .. GDKPT.Utils.FormatMoney(item.bid * 10000) .. "|r")

            entry.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
            
            entry.adjustmentOverlay:Hide()
        else
            entry.isAdjustment = false
            entry.itemName = item.name
            entry.itemLink = item.link
            entry.bidAmount = item.bid

            -- Calculate payment status
            local amountPaid = item.amountPaid or 0
            local totalCost = item.bid or 0
            local amountOwed = totalCost - amountPaid
            
            entry.amountPaid = amountPaid
            entry.amountOwed = amountOwed

            -- Show item name with payment indicator
            local paymentIndicator = ""
            if amountPaid >= totalCost then
                paymentIndicator = " |cff00ff00[PAID]|r"
            elseif amountPaid > 0 then
                paymentIndicator = string.format(" |cffffaa00[%dg paid]|r", amountPaid)
            end
            
            entry.nameText:SetText(item.name .. paymentIndicator)
            
            -- Show remaining owed amount
            if amountOwed > 0 then
                entry.bidText:SetText("|cffff3333-" .. GDKPT.Utils.FormatMoney(amountOwed * 10000) .. "|r")
            else
                entry.bidText:SetText("|cff00ff00" .. GDKPT.Utils.FormatMoney(totalCost * 10000) .. "|r")
            end

            local texture
            if item.link then
                local _, _, _, _, _, _, _, _, _, newTexture = GetItemInfo(item.link)
                texture = newTexture
            end

            if texture then
                entry.icon:SetTexture(texture)
            else
                entry.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            
            if item.wasAdjusted then
                entry.adjustmentOverlay:Show()
                local adjAmount = item.adjustmentAmount or 0
                local adjColor = (adjAmount > 0) and "|cffff0000" or "|cff00ff00"
                entry.adjustmentText:SetText(string.format("ADJUSTED: %s%dg|r", adjColor, math.abs(adjAmount)))
            else
                entry.adjustmentOverlay:Hide()
            end
        end

        local prevEntry = WonItemEntryPool[WonItemEntryID - 2]
        if not prevEntry then
            entry:SetPoint("TOP", ScrollContent, "TOP", 0, -2)
        else
            entry:SetPoint("TOP", prevEntry, "BOTTOM", 0, -2)
        end

        entry:SetWidth(ScrollContent:GetWidth())
        entry:Show()

        totalHeight = totalHeight + entry:GetHeight() + 2
    end

    local contentHeight = math.max(ScrollFrame:GetHeight() - 10, totalHeight + 2)
    ScrollContent:SetHeight(contentHeight)

    if ScrollFrame.ScrollBar then
        ScrollFrame.ScrollBar:SetValue(0)
    end
end



-- Function to update the gold summary panel
local function UpdateSummaryPanel(WonAuctionsSummaryPanel)
    local totalPaid = 0         
    local totalOwed = 0         
    local actualItemsWon = 0     
    local adjustmentSum = 0      

    for _, item in ipairs(GDKPT.Core.PlayerWonItems) do
        if item.isAdjustment then
            adjustmentSum = adjustmentSum + (item.bid or 0)
        else
            if not item.wasAdjusted then
                local itemCost = item.bid or 0
                local amountPaid = item.amountPaid or 0
                local amountOwed = itemCost - amountPaid
                
                totalPaid = totalPaid + amountPaid
                totalOwed = totalOwed + amountOwed
                actualItemsWon = actualItemsWon + 1
            end
        end
    end

    local totalCost = totalPaid + totalOwed
    local totalPaidCopper = totalPaid * 10000
    local totalOwedCopper = totalOwed * 10000
    local adjustmentCopper = adjustmentSum * 10000

    -- Update total cost (shows total paid + what's owed)
    WonAuctionsSummaryPanel.totalCostValue:SetText(GDKPT.Utils.FormatMoney((totalCost) * 10000))
    WonAuctionsSummaryPanel.amountItemsValue:SetText(actualItemsWon)

    if actualItemsWon > 0 then
        WonAuctionsSummaryPanel.averageCostValue:SetText(GDKPT.Utils.FormatMoney(math.floor(((totalCost) * 10000 / actualItemsWon) + 0.5)))
    else
        WonAuctionsSummaryPanel.averageCostValue:SetText(GDKPT.Utils.FormatMoney(0))
    end

    local playerCutGold = (GDKPT.Core.PlayerCut or 0) / 10000  
    local goldLeft = playerCutGold - (totalOwed + adjustmentSum)

    -- Format Gold Left with color-coding
    local color
    if goldLeft > 0 then
        color = "|cff33ff33" -- Green
    elseif goldLeft < 0 then
        color = "|cffff3333" -- Red
    else
        color = "|cffcccccc" -- Gray/White
    end

    WonAuctionsSummaryPanel.goldFromRaidValue:SetText(color .. GDKPT.Utils.FormatMoney(math.floor((goldLeft * 10000) + 0.5)) .. "|r")

end




function GDKPT.AuctionEnd.UpdateWonItemsDisplay(WonAuctionsFrame)
    if WonAuctionsFrame and WonAuctionsFrame.ScrollFrame then

        local ScrollFrame = WonAuctionsFrame.ScrollFrame
        local ScrollContent = ScrollFrame:GetScrollChild()

        if ScrollContent then
            GDKPT.AuctionEnd.UpdateWonItemsList(ScrollFrame, ScrollContent)
            UpdateSummaryPanel(WonAuctionsFrame.SummaryPanel)
        else
            print(
                "|cffff3333[GDKPT]|r Error: MyWonItemsFrame UI component structure is incomplete (missing ScrollChild)."
            )
        end
    end
end






-------------------------------------------------------------------
-- Function that gets called whenever an auction ends
-------------------------------------------------------------------

function GDKPT.AuctionEnd.HandleAuctionEnd(auctionId, GDKP_Pot, itemID, winningPlayer, finalBid)
    local row = GDKPT.Core.AuctionFrames[auctionId]
    if not row then
        return
    end

    row:Show()

    row:SetScript("OnUpdate", nil) 

    -- Reset the client-side ended flag (in case we need to reuse this row later)
    row.clientSideEnded = false

    if row.bidBox then
        row.bidBox:EnableMouse(false)
        row.bidBox:SetText("")
        row.bidBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        GDKPT.AuctionRow.ClearAndDisableBidBox(row.bidBox)
    end




    if row.bidButton then
        row.bidButton:Disable()
        row.bidButton:SetText("ENDED")
    end

    if row.timerText then
        row.timerText:SetText("|cffff0000ENDED|r")
    end


    if winningPlayer == "Bulk" then
        row.winnerText:SetText("BULK")
        row.winnerText:SetTextColor(1, 0, 0, 1) 
        row.endOverlay:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) 
    else
        row.winnerText:SetText("Winner: " .. winningPlayer .. " (" .. GDKPT.Utils.FormatMoney(finalBid * 10000) .. ")")
        row.winnerText:SetTextColor(0, 1, 0, 1) 
        row.endOverlay:SetBackdropBorderColor(0.2, 0.8, 0.2, 1) 
    end

    row:SetBackdropColor(row.DEFAULT_R, row.DEFAULT_G, row.DEFAULT_B, row.DEFAULT_A)
    row.endOverlay:Show()


    GDKPT.UI.UpdateTotalPotAmount(GDKP_Pot * 10000)
    GDKPT.UI.UpdateCurrentCutAmount(GDKP_Pot * 10000 / GDKPT.Core.leaderSettings.splitCount)


    local _, itemLink = GetItemInfo(itemID)
    if itemLink and finalBid > 0 then 
        table.insert(
            GDKPT.Core.History,
            {
                winner = winningPlayer,
                bid = finalBid,
                link = itemLink,
                timestamp = time(), 
            }
        )
    end


    if winningPlayer == UnitName("player") and finalBid > 0 then
        local itemName, itemLink = GetItemInfo(itemID)
    
        if not itemName then
            local row = GDKPT.Core.AuctionFrames[auctionId]
            if row and row.itemName then
                itemName = row.itemName
                itemLink = row.itemLink
            end
        end
    
        if not itemName then
            itemName = "Unknown Item"
            itemLink = string.format("|cffffffff[Item:%d]|r", itemID)
        end

        table.insert(
            GDKPT.Core.PlayerWonItems,
            {
                name = itemName,
                link = itemLink,
                bid = finalBid,
                auctionId = auctionId,
                amountPaid = 0, 
                timestamp = time()
            }
        )

        print(string.format("|cff00ff00[GDKPT]|r Congratulations! You won %s for %d G.", itemLink, finalBid))

        GDKPT.AuctionEnd.UpdateWonItemsDisplay(GDKPT.UI.AuctionWindow.WonAuctionsFrame)
        GDKPT.Core.LastKnownTopBidder[auctionId] = nil


        if GDKPT.Core.Settings.Fav_RemoveItemOnWin == 1 then  
            GDKPT.Favorites.RemoveFavoriteWhenAuctionWon(itemID,winningPlayer)
        end

    end

end














