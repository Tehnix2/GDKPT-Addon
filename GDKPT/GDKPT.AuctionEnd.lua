GDKPT.AuctionEnd = {}




local WonItemEntryPool = {}
local WonItemEntryID = 1

-- Function to create a single entry in the won items list
local function CreateWonAuctionEntry(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(32) -- Standard icon height
    frame:EnableMouse(true)

    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", frame, "LEFT", 40, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.icon = icon

    -- Item Name (Text)
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetJustifyH("LEFT")
    frame.nameText = nameText

    -- Bid Amount (Text)
    local bidText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bidText:SetPoint("RIGHT", -5, 0)
    bidText:SetJustifyH("RIGHT")
    frame.bidText = bidText

    -- Mouseover for tooltip (shows item link if available)
    frame:SetScript(
        "OnEnter",
        function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.itemLink then
                GameTooltip:SetHyperlink(self.itemLink)
            else
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



 
local function UpdateWonItemsList(ScrollFrame,ScrollContent)

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

        -- Set data
        entry.itemName = item.name
        entry.itemLink = item.link
        entry.bidAmount = item.bid

        entry.nameText:SetText(item.name)
        entry.bidText:SetText(GDKPT.Utils.FormatMoney(item.bid * 10000))

        -- Get texture from item link (requires item info to be loaded)
        -- NOTE: GetItemInfo expects itemID or itemLink, using item.link is correct here.
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(item.link)
        if texture then
            entry.icon:SetTexture(texture)
        else
            entry.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        -- Position and Show
        local prevEntry = WonItemEntryPool[WonItemEntryID - 2]
        if not prevEntry then
            entry:SetPoint("TOP", ScrollContent, "TOP", 0, -2) -- 2 pixel margin from top
        else
            entry:SetPoint("TOP", prevEntry, "BOTTOM", 0, -2) -- 2 pixel spacing
        end

        entry:SetWidth(ScrollContent:GetWidth())
        entry:Show()

        totalHeight = totalHeight + entry:GetHeight() + 2
    end

    -- Adjust ScrollContent height to accommodate all entries
    local contentHeight = math.max(ScrollFrame:GetHeight() - 10, totalHeight + 2) -- Ensure minimum scroll area
    ScrollContent:SetHeight(contentHeight)

    if ScrollFrame.ScrollBar then
        ScrollFrame.ScrollBar:SetValue(0) -- Scroll to top on refresh
    end
end

-- Function to update the gold summary panel
local function UpdateSummaryPanel(WonAuctionsSummaryPanel)
    local totalPaid = GDKPT.Utils.CalculateTotalPaid()

    WonAuctionsSummaryPanel.totalCostValue:SetText(GDKPT.Utils.FormatMoney(totalPaid))
    WonAuctionsSummaryPanel.payUpValue:SetText(GDKPT.Utils.FormatMoney(totalPaid))

    -- Calculate how much gold the player is leaving the raid with
    local goldLeft = PlayerCut - totalPaid

    -- Format Gold Left with color-coding
    local color
    if goldLeft > 0 then
        color = "|cff33ff33" -- Green
    elseif goldLeft < 0 then
        color = "|cffff3333" -- Red
    else
        color = "|cffcccccc" -- Gray/White
    end

    WonAuctionsSummaryPanel.goldLeftValue:SetText(color .. GDKPT.Utils.FormatMoney(goldLeft) .. "|r")
end

local function UpdateWonItemsDisplay(WonAuctionsFrame)
    if WonAuctionsFrame and WonAuctionsFrame.ScrollFrame then

        local ScrollFrame = WonAuctionsFrame.ScrollFrame
        local ScrollContent = ScrollFrame:GetScrollChild()

        if ScrollContent then
            UpdateWonItemsList(ScrollFrame, ScrollContent)
            UpdateSummaryPanel(WonAuctionsFrame.SummaryPanel)
        else
            print(
                "|cffff3333[GDKPT]|r Error: MyWonItemsFrame UI component structure is incomplete (missing ScrollChild)."
            )
        end
    end
end






-------------------------------------------------------------------
-- 
-------------------------------------------------------------------






-------------------------------------------------------------------
-- Function that gets called whenever an auction ends
-------------------------------------------------------------------

function GDKPT.AuctionEnd.HandleAuctionEnd(auctionId, GDKP_Pot, itemID, winningPlayer, finalBid)
    local row = GDKPT.Core.AuctionFrames[auctionId]
    if not row then
        return
    end

    row:SetScript("OnUpdate", nil) -- Stop the timer

    -- Disable interaction elements
    if row.bidBox then
        row.bidBox:EnableMouse(false)
        row.bidBox:SetText("")
        -- Change border to gray for disabled state
        row.bidBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end

    if row.bidButton then
        row.bidButton:Disable()
        row.bidButton:SetText("ENDED")
    end

    -- Set the winner text and show the overlay
    if winningPlayer == "Bulk" then
        row.winnerText:SetText("BULK")
        row.winnerText:SetTextColor(1, 0, 0, 1) -- Red for Bulk
        row.endOverlay:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) -- Red border
    else
        row.winnerText:SetText("Winner: " .. winningPlayer .. " (" .. GDKPT.Utils.FormatMoney(finalBid * 10000) .. ")")
        row.winnerText:SetTextColor(0, 1, 0, 1) -- Green text for winner
        row.endOverlay:SetBackdropBorderColor(0.2, 0.8, 0.2, 1) -- Green border
    end

    row.endOverlay:Show()

    -- Hide the row and move it to the pool for reuse
    --row:Hide()

    --row.auctionId = nil
    --table.insert(AuctionFramePool, row)
    --AuctionFrames[auctionId] = nil

    --UpdateAuctionLayout()
    GDKPT.UI.UpdateTotalPotAmount(GDKP_Pot * 10000)
    GDKPT.UI.UpdateCurrentCutAmount(GDKP_Pot * 10000 / GDKPT.Core.leaderSettings.splitCount)

    if winningPlayer == UnitName("player") and finalBid > 0 then
        local itemName, itemLink = GetItemInfo(itemID)

        -- Adding won items to PlayerWonItems table
        table.insert(
            GDKPT.Core.PlayerWonItems,
            {
                name = itemName,
                link = itemLink,
                bid = finalBid
            }
        )

        print(string.format("|cff00ff00[GDKPT]|r Congratulations! You won %s for %d G.", itemName, finalBid))

        UpdateWonItemsDisplay(GDKPT.UI.AuctionWindow.WonAuctionsFrame)
    end
end












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