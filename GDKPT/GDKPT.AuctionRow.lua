GDKPT.AuctionRow = {}

-------------------------------------------------------------------
-- Function for updating the timer underneath the itemlink on a row
-------------------------------------------------------------------

function GDKPT.AuctionRow.UpdateRowTimer(self, elapsed)

    -- Accumulate time elapsed since the last frame
    self.timeAccumulator = (self.timeAccumulator or 0) + elapsed

    -- Only proceed if at least 1 second has accumulated
    if self.timeAccumulator < 1.0 then
        return
    end

    -- Reset the accumulator, subtracting full seconds that passed
    -- Using math.floor ensures we handle cases where elapsed is slightly > 1.0
    self.timeAccumulator = self.timeAccumulator - math.floor(self.timeAccumulator)

    if not self.endTime or self.endTime == 0 then
        self.timerText:SetText("Time Left: |cffaaaaaa--:--|r")
        -- Stop the OnUpdate script if the timer is invalid/finished
        self:SetScript("OnUpdate", nil)
        return
    end

    -- Recalculate remaining time using the system time
    local remaining = self.endTime - GetTime()

    if remaining > 0 then
        -- Floor the remaining time to get clean second counts for display
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)

        -- Determine color code
        local colorCode = (remaining < 10) and "|cffff2222" or "|cffffffff"

        self.timerText:SetText(string.format("Time Left: %s%02d:%02d|r", colorCode, minutes, seconds))
    else
        -- Auction is officially over
        self.timerText:SetText("Time Left: |cffff000000:00|r")
        -- Stop the OnUpdate script as the auction is finished
        self.timeAccumulator = 0
        self:SetScript("OnUpdate", nil)
    end
end



-------------------------------------------------------------------
-- Function that gets called when a player clicks the bidButton
-- bidButton makes the player always bid the least possible amount
-------------------------------------------------------------------

local function ClickBidButton(self)
    -- auctionId is set by the HandleAuctionStart() function
    local auctionId = self.auctionId
    local row = GDKPT.Core.AuctionFrames[auctionId]

    if not row then
        print("|cffff8800[GDKPT]|r Error: Could not find auction data.")
        return
    end

    local currentBid = row.currentBid or 0 -- Default to 0 if no bids yet
    local minInc = row.minIncrement

    local bidAmount

    if row.topBidder == "" then
        -- If no top bidder exists, the first bid must be at least the starting bid
        bidAmount = row.startBid
    else
        -- If a top bidder exists, the next allowed bid is currentBid + minInc
        bidAmount = currentBid + minInc
    end

    -- Send the bid to the leader addon
    if bidAmount and bidAmount > 0 then
        local msg = string.format("BID:%d:%d", auctionId, bidAmount)
        SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")

        -- Lock the UI while waiting for the leader's response
        row.bidButton:Disable()
        row.bidButton:SetText("Syncing...")

        SendChatMessage(string.format("[GDKPT] I'm bidding %d gold on %s !", bidAmount, row.itemLink), "RAID")
    end
end


-------------------------------------------------------------------
-- Function that gets called when a player enters a manual bid into 
-- the bidBox
-------------------------------------------------------------------


local function HandleBidBoxEnter(self)
    local row = self:GetParent() -- Get the parent row frame
    local bidAmount = tonumber(self:GetText())
    local auctionId = row.auctionId

    self:ClearFocus() -- Clear focus immediately upon pressing Enter

    if not auctionId or not row then
        print("|cffff8800[GDKPT]|r Error: There is no auction data for this bidBox.")
        return
    end

    local currentBid = row.currentBid or 0
    local minInc = row.minIncrement
    local nextMinBid = currentBid > 0 and (currentBid + minInc) or row.startBid

    -- Validation 1: Check if the input is a valid positive number
    if not bidAmount or bidAmount <= 0 then
        print("|cffff8800[GDKPT]|r Invalid bid amount. Please enter a positive number.")
        self:SetText("")
        --self:SetText(tostring(nextMinBid)) -- Reset to the minimum allowed bid
        return
    end

    -- Validation 2: Check if the bid meets the minimum required bid
    if bidAmount < nextMinBid then
        print(string.format("|cffff8800[GDKPT]|r Bid must be at least %d gold.", nextMinBid))
        self:SetText("")
        --self:SetText(tostring(nextMinBid)) -- Reset to the minimum allowed bid
        return
    end

    -- Send the validated bid to the leader addon
    local msg = string.format("BID:%d:%d", auctionId, bidAmount)
    SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")

    -- Lock the UI while waiting for the leader's response
    row.bidButton:Disable()
    row.bidButton:SetText("Syncing...")

    -- Update the chat announcement
    SendChatMessage(string.format("[GDKPT] I'm manually bidding %d gold on %s !", bidAmount, row.itemLink), "RAID")

    -- Clear the bidBox after sending the bid
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
    
    -- Store the retrieved default values on the row for later use
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
            bgFile = "Interface/Tooltips/UI-Tooltip-Background", -- A light gray background
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", -- Standard WoW border texture
            tile = true,
            tileSize = 16,
            edgeSize = 8,
            insets = {left = 3, right = 3, top = 3, bottom = 3}
        }
    )
    -- Set the backdrop color to make it visually distinct
    row.bidBox:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
    row.bidBox:SetBackdropBorderColor(0.8, 0.6, 0, 1) -- Gold-ish border color

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
    -- Anchor directly below the auction number (Element 8)
    row.favoriteButton:SetPoint("TOP", row.auctionNumber, "BOTTOM", 0, -5)

    row.favoriteButton:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    row.favoriteIcon = row.favoriteButton:GetNormalTexture()

    -- Ensure the retrieved texture object exists before trying to manipulate it
    if row.favoriteIcon then
        row.favoriteIcon:SetAllPoints()
        row.favoriteIcon:SetVertexColor(1, 0.8, 0, 1) -- Gold color for the 'favorite' placeholder
    end

    -- Add a highlight texture for visual feedback on mouseover
    local highlight = row.favoriteButton:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight") 
    highlight:SetVertexColor(1, 1, 1, 0.5) -- White transparency
    row.favoriteButton:SetHighlightTexture(highlight)

    row.isFavorite = false
    row.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Grayed out


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
    -- Semi-transparent black background
    row.endOverlay:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    row.endOverlay:SetFrameLevel(row:GetFrameLevel() + 2) -- Ensure it covers other elements

    row.winnerText = row.endOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    row.winnerText:SetPoint("CENTER")
    row.winnerText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    row.winnerText:SetTextColor(1, 1, 0, 1) -- Default Gold/Yellow color

    row.endOverlay:Hide() 



    return row
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

-------------------------------------------------------------------
-- 
-------------------------------------------------------------------