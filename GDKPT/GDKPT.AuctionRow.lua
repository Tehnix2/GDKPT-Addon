GDKPT.AuctionRow = GDKPT.AuctionRow or {}

-- Create a custom confirmation modal that we will reuse for all bid confirmations
do
    local frame = CreateFrame("Frame", "GDKPT_BidConfirmationFrame", UIParent)
    frame:SetSize(300, 150)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()
    GDKPT.AuctionRow.ConfirmationFrame = frame

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOP", 0, -20)
    text:SetWidth(280)
    text:SetText("")
    frame.Text = text

    local YesButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    YesButton:SetSize(100, 25)
    YesButton:SetPoint("BOTTOMLEFT", 20, 20)
    YesButton:SetText("Confirm Bid")
    YesButton:SetScript("OnClick", function(self)
        if frame.confirmAction then
            frame.confirmAction() -- Execute the stored action (ExecuteBid)
        end
        frame:Hide()
    end)

    local NoButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    NoButton:SetSize(100, 25)
    NoButton:SetPoint("BOTTOMRIGHT", -20, 20)
    NoButton:SetText("Cancel")
    NoButton:SetScript("OnClick", function()
        frame:Hide()
    end)
end


-------------------------------------------------------------------
-- Core function to execute the bid (called after confirmation or immediately)
-------------------------------------------------------------------



local function ExecuteBid(auctionId, bidAmount, itemLink, isManual)
    
    local row = GDKPT.Core.AuctionFrames[auctionId]

    local msg = string.format("BID:%d:%d", auctionId, bidAmount)
    SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")

    -- Lock the UI while waiting for the leader's response
    if row and row.bidButton then
        row.bidButton:Disable()
        row.bidButton:SetText("Syncing...")
    end

    if isManual then
        SendChatMessage(string.format("[GDKPT] I'm manually bidding %d gold on %s !", bidAmount, itemLink), "RAID")
    else
        SendChatMessage(string.format("[GDKPT] I'm bidding %d gold on %s !", bidAmount, itemLink), "RAID")
    end
end


-------------------------------------------------------------------
-- Function for updating the timer underneath the itemlink on a row
-------------------------------------------------------------------

-------------------------------------------------------------------
-- Function for updating the timer underneath the itemlink on a row
-- IMPROVED: Added buffer zone to handle sync delays gracefully
-------------------------------------------------------------------

function GDKPT.AuctionRow.UpdateRowTimer(self, elapsed)

    self.timeAccumulator = (self.timeAccumulator or 0) + elapsed

    if self.timeAccumulator < 1.0 then
        return
    end

    self.timeAccumulator = self.timeAccumulator - math.floor(self.timeAccumulator)

    if not self.endTime or self.endTime == 0 then
        self.timerText:SetText("Time Left: |cffaaaaaa--:--|r")
        self:SetScript("OnUpdate", nil)
        return
    end

    local remaining = self.endTime - GetTime()

    -- IMPROVED: Buffer zone for network delays
    local SYNC_BUFFER = 3 -- Stop showing countdown at 3 seconds to handle sync delays
    
    if remaining > SYNC_BUFFER then
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)

        local colorCode
        if remaining < 10 then
            colorCode = "|cffff2222" -- Red for last 10 seconds
        elseif remaining < 30 then
            colorCode = "|cffffaa22" -- Orange for last 30 seconds
        else
            colorCode = "|cffffffff" -- White otherwise
        end

        self.timerText:SetText(string.format("Time Left: %s%02d:%02d|r", colorCode, minutes, seconds))
    elseif remaining > 0 then
        -- In the buffer zone - show "Ending soon"
        self.timerText:SetText("Time Left: |cffff9900Ending Soon...|r")
    else
        -- Auction should have ended - waiting for server confirmation
        self.timerText:SetText("Time Left: |cffff0000Awaiting Results...|r")
        -- Keep the timer running to update if leader is delayed
    end
end


--[[

function GDKPT.AuctionRow.UpdateRowTimer(self, elapsed)

    self.timeAccumulator = (self.timeAccumulator or 0) + elapsed

    if self.timeAccumulator < 1.0 then
        return
    end

    self.timeAccumulator = self.timeAccumulator - math.floor(self.timeAccumulator)

    if not self.endTime or self.endTime == 0 then
        self.timerText:SetText("Time Left: |cffaaaaaa--:--|r")
        self:SetScript("OnUpdate", nil)
        return
    end

    local remaining = self.endTime - GetTime()

    if remaining > 0 then
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)

        local colorCode = (remaining < 10) and "|cffff2222" or "|cffffffff"

        self.timerText:SetText(string.format("Time Left: %s%02d:%02d|r", colorCode, minutes, seconds))
    else
        self.timerText:SetText("Time Left: |cffff000000:00|r")
        self.timeAccumulator = 0
        self:SetScript("OnUpdate", nil)
    end
end

]]


-------------------------------------------------------------------
-- Function that gets called when a player clicks the bidButton
-- bidButton makes the player always bid the least possible amount
-------------------------------------------------------------------

local function ClickBidButton(self)
    local auctionId = self.auctionId
    local row = GDKPT.Core.AuctionFrames[auctionId]

    if not row then
        print("|cffff8800[GDKPT]|r Error: Could not find auction data.")
        return
    end

    local currentBid = row.currentBid or 0 
    local minInc = row.minIncrement

    local bidAmount

    if row.topBidder == "" then
        bidAmount = row.startBid
    else
        bidAmount = currentBid + minInc
    end

    if not bidAmount or bidAmount <= 0 then
        print("|cffff8800[GDKPT]|r Cannot place bid. Invalid calculated amount.")
        return
    end


    if GDKPT.Core.Settings.LimitBidsToGold == 1 then
        local playerGoldInCopper = GetMoney()
        local bidInCopper = bidAmount * 10000 -- BidAmount is in Gold

        if bidInCopper > playerGoldInCopper then
            print(string.format("|cffff8800[GDKPT]|r Bid failed: You only have %s and cannot afford %d gold.", GetCoinText(playerGoldInCopper), bidAmount))
            return 
        end
    end


    if GDKPT.Core.Settings.ConfirmBid == 1 then
        local confFrame = GDKPT.AuctionRow.ConfirmationFrame
        confFrame.Text:SetText(string.format("|cffffffffAre you sure you want to place a MIN bid of |cffFFC125%d Gold|cffffffff on %s?|r", bidAmount, row.itemLink))
        confFrame.confirmAction = function()
            ExecuteBid(auctionId, bidAmount, row.itemLink, false)
        end
        confFrame:Show()
    else
        ExecuteBid(auctionId, bidAmount, row.itemLink, false)
    end
end


-------------------------------------------------------------------
-- Function that gets called when a player enters a manual bid into 
-- the bidBox
-------------------------------------------------------------------


local function HandleBidBoxEnter(self)
    local row = self:GetParent() 
    local bidAmount = tonumber(self:GetText())
    local auctionId = row.auctionId

    self:ClearFocus() 

    if not auctionId or not row then
        print("|cffff8800[GDKPT]|r Error: There is no auction data for this bidBox.")
        return
    end

    local currentBid = row.currentBid or 0
    local minInc = row.minIncrement
    local nextMinBid = currentBid > 0 and (currentBid + minInc) or row.startBid

    if not bidAmount or bidAmount <= 0 then
        print("|cffff8800[GDKPT]|r Invalid bid amount. Please enter a positive number.")
        self:SetText("")
        return
    end

    if bidAmount < nextMinBid then
        print(string.format("|cffff8800[GDKPT]|r Bid must be at least %d gold.", nextMinBid))
        self:SetText("")
        return
    end


    if GDKPT.Core.Settings.LimitBidsToGold == 1 then
        local playerGoldInCopper = GetMoney()
        local bidInCopper = bidAmount * 10000 -- BidAmount is in Gold

        if bidInCopper > playerGoldInCopper then
            print(string.format("|cffff8800[GDKPT]|r Bid failed: You only have %s and cannot afford %d gold.", GetCoinText(playerGoldInCopper), bidAmount))
            self:SetText("")
            return -- Stop the bid
        end
    end


    if GDKPT.Core.Settings.ConfirmBidBox == 1 then
        local confFrame = GDKPT.AuctionRow.ConfirmationFrame
        confFrame.Text:SetText(string.format("|cffffffffAre you sure you want to place a manual bid of |cffFFC125%d Gold|cffffffff on %s?|r", bidAmount, row.itemLink))
        confFrame.confirmAction = function()
            ExecuteBid(auctionId, bidAmount, row.itemLink, true)
        end
        confFrame:Show()
    else
        ExecuteBid(auctionId, bidAmount, row.itemLink, true)
    end

    self:SetText("")
end


-------------------------------------------------------------------
-- Dynamic Auction Row Creation
-------------------------------------------------------------------




function GDKPT.AuctionRow.CreateAuctionRow()
 

    local row = CreateFrame("Frame", nil, GDKPT.UI.AuctionContentFrame)
    row:SetSize(750, 55)
    row:SetBackdrop(
        {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            edgeSize = 12,
            insets = {left = 3, right = 3, top = 3, bottom = 3}
        }
    )

    local r, g, b, a = row:GetBackdropColor()
    row.DEFAULT_R, row.DEFAULT_G, row.DEFAULT_B, row.DEFAULT_A = r, g, b, a

    row:Hide()

    -- Variable needed for the auction timer
    row.timeAccumulator = 0

    -- 1. Item Icon
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(40, 40)
    row.icon:SetPoint("LEFT", 40, 0)

    -- 2. Item Link with a hidden button behind it for mouseover tooltip
    row.itemButton = CreateFrame("Button", nil, row)
    row.itemButton:SetSize(250, 20)
    row.itemButton:SetPoint("LEFT", row.icon, "RIGHT", 40, 8)
    row.itemLinkText = row.itemButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.itemLinkText:SetFont("Fonts\\FRIZQT__.TTF", 14)
    row.itemLinkText:SetAllPoints()
    row.itemLinkText:SetJustifyH("LEFT")
    row.itemButton:SetScript(
        "OnEnter",
        function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(row.itemLink)
            GameTooltip:Show()
        end
    )
    row.itemButton:SetScript(
        "OnLeave",
        function()
            GameTooltip:Hide()
        end
    )

    -- 3. Timer Text
    row.timerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.timerText:SetPoint("LEFT", row.itemButton, "LEFT", 0, -20)
    row.timerText:SetFont("Fonts\\FRIZQT__.TTF", 12)

    --Countdown timer underneath the itemLink on each row, triggered on frame update

    row:SetScript("OnUpdate", GDKPT.AuctionRow.UpdateRowTimer)

    -- 4. Current Bid Text
    row.bidText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.bidText:SetPoint("CENTER", 50, 8)
    row.bidText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

    -- 5. Top Bidder Text
    row.topBidderText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.topBidderText:SetPoint("TOP", row.bidText, "BOTTOM", 0, -5)
    row.topBidderText:SetFont("Fonts\\FRIZQT__.TTF", 12)

    -- 6. Bid EditBox
    row.bidBox = CreateFrame("EditBox", nil, row)
    row.bidBox:SetSize(80, 32)
    row.bidBox:SetPoint("RIGHT", -150, 0)
    row.bidBox:SetNumeric(true)
    row.bidBox:SetAutoFocus(false)
    row.bidBox:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

    row.bidBox:SetTextInsets(4, 4, 0, 0)

    row.bidBox:SetBackdrop(
        {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
            tile = true,
            tileSize = 16,
            edgeSize = 8,
            insets = {left = 3, right = 3, top = 3, bottom = 3}
        }
    )

    row.bidBox:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
    row.bidBox:SetBackdropBorderColor(0.8, 0.6, 0, 1) 

    row.bidBox:SetScript("OnEnterPressed", HandleBidBoxEnter)

    row.bidBox:SetScript(
        "OnEscapePressed",
        function(self)
            self:ClearFocus()
        end
    )

    -- 7. Bid Button
    row.bidButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.bidButton:SetSize(80, 25)
    row.bidButton:SetPoint("LEFT", row.bidBox, "RIGHT", 30, 0)
    row.bidButton:SetText("Min Bid")

    row.bidButton:SetScript("OnClick", ClickBidButton)

    -- 8. Auction Id on top left
    row.auctionNumber = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.auctionNumber:SetPoint("LEFT", 10, 8)
    row.auctionNumber:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")

    row.auctionNumber:SetText(row.auctionId or "")

    -- 9. Favourite star icon below

    row.favoriteButton = CreateFrame("Button", nil, row)
    row.favoriteButton:SetSize(15, 15)
    row.favoriteButton:SetPoint("TOP", row.auctionNumber, "BOTTOM", 0, -5)

    row.favoriteButton:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    row.favoriteIcon = row.favoriteButton:GetNormalTexture()

    if row.favoriteIcon then
        row.favoriteIcon:SetAllPoints()
        row.favoriteIcon:SetVertexColor(1, 0.8, 0, 1) 
    end

    local highlight = row.favoriteButton:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight") 
    highlight:SetVertexColor(1, 1, 1, 0.5) 
    row.favoriteButton:SetHighlightTexture(highlight)

    row.isFavorite = false
    row.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1) 


    row.favoriteButton:SetScript(
        "OnClick",
        function(self)
            if row.itemLink then
                GDKPT.AuctionFavorites.ToggleFavorite(row.itemLink)
            else
                print("|cffff8800[GDKPT]|r Error: No itemLink found on this auction row.")
            end
        end
    )


    -- 10. Auction End Overlay Frame
    row.endOverlay = CreateFrame("Frame", nil, row)
    row.endOverlay:SetAllPoints(row)
    row.endOverlay:SetBackdrop(
        {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            edgeSize = 12,
            insets = {left = 3, right = 3, top = 3, bottom = 3}
        }
    )
    row.endOverlay:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    row.endOverlay:SetFrameLevel(row:GetFrameLevel() + 2) 

    row.winnerText = row.endOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    row.winnerText:SetPoint("CENTER")
    row.winnerText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    row.winnerText:SetTextColor(1, 1, 0, 1) 

    row.endOverlay:Hide() 

    -- 11. Manual Adjustment Overlay Frame
    row.manualAdjustmentOverlay = CreateFrame("Frame",nil,row)
    row.manualAdjustmentOverlay:SetAllPoints(row)
    row.manualAdjustmentOverlay:SetBackdrop(
        {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            edgeSize = 12,
            insets = {left = 3, right = 3, top = 3, bottom = 3}
        }
    )
    row.manualAdjustmentOverlay:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    row.manualAdjustmentOverlay:SetFrameLevel(row:GetFrameLevel() + 4) 
    row.manualAdjustmentOverlay:Hide()


    row.manualAdjustmentText = row.manualAdjustmentOverlay:CreateFontString(nil, "OVERLAY2", "GameFontNormalLarge")
    row.manualAdjustmentText:SetPoint("CENTER")
    row.manualAdjustmentText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    row.manualAdjustmentText:SetTextColor(1, 1, 0, 1) 
    row.manualAdjustmentText:SetText("MANUALLY ADJUSTED")
    
    return row
end
