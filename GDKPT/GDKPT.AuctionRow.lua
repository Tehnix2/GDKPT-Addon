GDKPT.AuctionRow = GDKPT.AuctionRow or {}


-------------------------------------------------------------------
-- Bid Confirmation Popup frame
-------------------------------------------------------------------
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
            frame.confirmAction() 
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
-- Small button to the right of the bidButton that gets enabled when 
-- the bidButton is stuck on Syncing... for a longer time
-------------------------------------------------------------------


function GDKPT.AuctionRow.CreateUnstuckButton(row)
    local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btn:SetSize(30, 25)
    btn:SetPoint("LEFT", row.bidButton, "RIGHT", 5, 0)
    btn:SetText("Fix")
    btn:Hide()


    -- Tooltip overlay
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Fix Button", 1, 1, 1) 
        GameTooltip:AddLine("Click this button if your bid button is stuck on Syncing...", 1, 1, 0) 
        GameTooltip:AddLine("It will re-enable the bid button and bid box.", 1, 1, 0) 
        GameTooltip:Show()
    end)
    
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    btn:SetScript("OnClick", function(self)
        if row.clientSideEnded or (row.endOverlay and row.endOverlay:IsShown()) then
            print(GDKPT.Core.errorprint .. "This auction has already ended.")
            self:Hide()
            return
        end
        
        -- Re-enable the bid button
        if row.bidButton then
            row.bidButton:Enable()
            local nextMinBid = row.topBidder == "" and row.startBid or (row.currentBid or 0) + (GDKPT.Core.leaderSettings.minIncrement or 1)
            row.bidButton:SetText(nextMinBid .. " G")
        end
        
        -- Re-enable the bid box
        if row.bidBox then
            row.bidBox:Enable()
            row.bidBox:EnableMouse(true)
        end
        
        print(GDKPT.Core.print .. "Bid Button and Bid Box re-enabled for Auction #" .. (row.auctionId or "?"))
        self:Hide()
        
        -- Cancel the timer since we fixed it manually
        if row.unstuckCheckTimer then
            row.unstuckCheckTimer:Cancel()
            row.unstuckCheckTimer = nil
        end
    end)
    
    return btn
end











-------------------------------------------------------------------
-- Utility function to clear and disable a bid box
-- This ensures the player cannot continue typing in the box
-------------------------------------------------------------------

local function ClearAndDisableBidBox(bidBox)
    if not bidBox then return end
    
    bidBox:ClearFocus()
    bidBox:SetText("")
    bidBox:EnableMouse(false)
    bidBox:Disable()
    bidBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
end

GDKPT.AuctionRow.ClearAndDisableBidBox = ClearAndDisableBidBox



-------------------------------------------------------------------
-- Function to update row background colors
-------------------------------------------------------------------


GDKPT.AuctionRow.UpdateRowColor = function(row)
    if not row then return end
    
    local playerName = UnitName("player")
    local hasBid = GDKPT.Core.PlayerBidHistory[row.auctionId]
    
    if not hasBid then
        row:SetBackdropColor(row.DEFAULT_R, row.DEFAULT_G, row.DEFAULT_B, row.DEFAULT_A)
        return
    end
    
    if row.topBidder == playerName then
        if GDKPT.Core.Settings.GreenBidRows == 1 then
            row:SetBackdropColor(0, 1, 0.6, 0.8)
        end
    else
        if GDKPT.Core.Settings.RedOutbidRows == 1 then
            row:SetBackdropColor(0.77, 0.12, 0.23, 0.8)
        end
    end
end








-------------------------------------------------------------------
-- ExecuteBid is called after any bid (button or manual input)
-------------------------------------------------------------------



local function ExecuteBid(auctionId, bidAmount, itemLink, isManual)
    
    local row = GDKPT.Core.AuctionFrames[auctionId]

    -- Dont allow bids on ended auctions
    if row and row.clientSideEnded then
        print(GDKPT.Core.errorprint .. "Cannot bid - this auction has already ended!")
        return
    end

    -- Overflow prevention
    if bidAmount > GDKPT.Core.MaxBid then
        print(string.format(GDKPT.Core.errorprint .. "Bid amount too large! Maximum bid is %s.", 
            GDKPT.Utils.FormatMoney(GDKPT.Core.MaxBid * 10000)))
        return
    end

    -- Total bid cap 
    local bidCap = tonumber(GDKPT.UI.TotalBidCapInput:GetText()) or 0
    local currentCommitted = GDKPT.Utils.GetTotalCommittedGold()
    local prevBid = GDKPT.Core.PlayerActiveBids[auctionId] or 0
    local additionalCommit = bidAmount - prevBid
    local availableGold = bidCap - currentCommitted


    if bidCap ~= 0 and additionalCommit > availableGold then
        print(string.format(GDKPT.Core.errorprint .. "Cannot bid %d on Auction %d - this would exceed your set Bid Cap.", bidAmount, auctionId))
        return
    end

    GDKPT.UI.MyBidsText:SetText(currentCommitted+additionalCommit)

    -- Find and disable mini bid frame row immediately
    if GDKPT.MiniBidFrame and GDKPT.MiniBidFrame.Frame and GDKPT.MiniBidFrame.Frame:IsShown() then
        local miniRows = GDKPT.MiniBidFrame.Frame.scrollChild:GetChildren()
        for _, miniRow in pairs({miniRows}) do
            if miniRow.auctionId == auctionId and miniRow.bidBtn then
                miniRow.bidBtn:Disable()
                miniRow.bidBtn:SetText("...")
            end
        end
    end

    -- Track this bid
    GDKPT.Core.PlayerActiveBids[auctionId] = bidAmount
    GDKPT.Core.PlayerBidHistory[auctionId] = true


    local msg = string.format("BID:%d:%d", auctionId, bidAmount)
    SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")




     -- Lock the UI while waiting for the leader's response
    if row and row.bidButton then
        row.bidButton:Disable()
        row.bidButton:SetText("Syncing...") 
    end


    if row.unstuckCheckTimer then
        row.unstuckCheckTimer:Cancel()
    end


    row.unstuckCheckTimer = C_Timer.NewTicker(5, function()
        if row and row.bidButton and row.bidButton:GetText() == "Syncing..." 
           and row.bidButton:IsEnabled() == 0 
           and not row.clientSideEnded then
            if row.unstuckButton then
                row.unstuckButton:Show()
            end
        end
    end)
end


-------------------------------------------------------------------
-- Function for updating the timer underneath the itemlink on a row
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

    
    local SYNC_BUFFER = 5 -- Stop showing countdown at 5 seconds to handle sync delays
    
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
        -- at SYNC_BUFFER or less remaining show Ending soon... instead of the actual duration
        self.timerText:SetText("Time Left: |cffff9900Ending Soon...|r")
    else        
        if not self.clientSideEnded then
            self.clientSideEnded = true -- Mark as ended to prevent multiple triggers
            
            -- Disable bidding controls immediately
            if self.bidButton then
                self.bidButton:Disable()
                self.bidButton:SetText("Processing...")
            end
            if self.bidBox then
                self.bidBox:EnableMouse(false)
                self.bidBox:ClearFocus()
                self.bidBox:SetText("")
                self.bidBox:Disable()
                self.bidBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) -- Gray out the border
            end

            self.timerText:SetText("Time Left: |cffff0000Awaiting Results...|r")
       end
    end
end


-------------------------------------------------------------------
-- Function that gets called when a player clicks the bidButton
-- bidButton makes the player always bid the least possible amount
-------------------------------------------------------------------

local function ClickBidButton(self)
    local auctionId = self.auctionId
    local row = GDKPT.Core.AuctionFrames[auctionId]

    if not row then
        print(GDKPT.Core.errorprint .. "Could not find auction data.")
        return
    end

    if row.clientSideEnded then
        print(GDKPT.Core.errorprint .. "This auction has already ended!")
        return
    end


    if GDKPT.Core.Settings.PreventSelfOutbid == 1 then
        if row.topBidder == UnitName("player") then
            print(GDKPT.Core.errorprint .. "You are already the highest bidder on this auction! Self-Outbid prevention is enabled in settings.")
            return
        end
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
        print(GDKPT.Core.errorprint .. "Cannot place bid. Invalid calculated amount.")
        return
    end

    if GDKPT.Core.Settings.LimitBidsToGold == 1 then
        local playerGoldInCopper = GetMoney()
        local bidInCopper = bidAmount * 10000 -- BidAmount is in Gold

        if bidInCopper > playerGoldInCopper then
            print(string.format(GDKPT.Core.errorprint .. "Bid failed: You only have %s and cannot afford %d gold. Limit bids to gold on character setting is enabled.", GetCoinText(playerGoldInCopper), bidAmount))
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


-------------------------------------------------------------------------------
-- Function that gets called when a player enters a manual bid into the bid box
-------------------------------------------------------------------------------




local function HandleBidBoxEnter(self)
    local row = self:GetParent() 
    local bidAmount = tonumber(self:GetText())
    local auctionId = row.auctionId

    self:ClearFocus() 

    if not auctionId or not row then
        print(GDKPT.Core.errorprint .. "There is no auction data for this bidBox.")
        return
    end


    if row.clientSideEnded then
        print(GDKPT.Core.errorprint .. "This auction has already ended!")
        self:SetText("")
        return
    end

    if GDKPT.Core.Settings.PreventSelfOutbid == 1 then
        if row.topBidder == UnitName("player") then
            print(GDKPT.Core.errorprint .."You are already the highest bidder on this auction! Self-outbid prevention is enabled in settings.")
            self:SetText("")
            return
        end
    end

    local currentBid = row.currentBid or 0
    local minInc = row.minIncrement
    local nextMinBid = currentBid > 0 and (currentBid + minInc) or row.startBid

    if not bidAmount or bidAmount <= 0 then
        print(GDKPT.Core.errorprint .. "Invalid bid amount. Please enter a positive number.")
        self:SetText("")
        return
    end

    if bidAmount > GDKPT.Core.MaxBid then
        print(string.format(GDKPT.Core.errorprint .. "Bid amount too large! Maximum bid is %s.", 
            GDKPT.Utils.FormatMoney(GDKPT.Core.MaxBid * 10000)))
        self:SetText("")
        return
    end

    if bidAmount < nextMinBid then
        print(string.format(GDKPT.Core.errorprint .. "Bid must be at least %d gold.", nextMinBid))
        self:SetText("")
        return
    end


    if GDKPT.Core.Settings.LimitBidsToGold == 1 then
        local playerGoldInCopper = GetMoney()
        local bidInCopper = bidAmount * 10000 -- BidAmount is in Gold

        if bidInCopper > playerGoldInCopper then
            print(string.format(GDKPT.Core.errorprint .. "Bid failed: You only have %s and cannot afford %d gold. Limit bids to gold on character setting is enabled.", GetCoinText(playerGoldInCopper), bidAmount))
            self:SetText("")
            return 
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
    row:SetHeight(55) 
    row:SetWidth(GDKPT.UI.AuctionContentFrame:GetWidth())
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


    -- Make the icon respond to mouse events
    row.iconFrame = CreateFrame("Button", nil, row)
    row.iconFrame:SetSize(40, 40)
    row.iconFrame:SetPoint("CENTER", row.icon, "CENTER")
    row.iconFrame:EnableMouse(true)

    -- Tooltip scripts
    row.iconFrame:SetScript("OnEnter", function(self)
        if row.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(row.itemLink)
            GameTooltip:Show()
        end
    end)

    row.iconFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)



    row.stackText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.stackText:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", -2, 2)
    row.stackText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    row.stackText:SetTextColor(1, 1, 1, 1)
    row.stackText:SetText("") 
    row.stackText:Hide()


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

    -- bidButton unstuck button 
    row.unstuckButton = GDKPT.AuctionRow.CreateUnstuckButton(row)

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
                GDKPT.Favorites.ToggleFavorite(row.itemLink)
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



    -- 12. right click a row to hide it
    row.userHidden = false  -- Track if player manually hid this row

    row:EnableMouse(true)

    row:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        self:Hide()  
        self.userHidden = true

        if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
            GDKPT.AuctionLayout.RepositionAllAuctions()  -- Reposition all remaining rows automatically
        end
    end
end)






    
    return row
end


-- dusty priest cloak