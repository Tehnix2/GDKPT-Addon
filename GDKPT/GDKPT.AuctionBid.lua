GDKPT.AuctionBid = {}

GDKPT.Core.LastKnownTopBidder = {}  -- Tracks the last known top bidder for each auctionId


-------------------------------------------------------------------
-- Handle when the player is outbid
-------------------------------------------------------------------

local function HandleOutbid(row, auctionId, newBid, topBidder)
    -- Show UI message
    if GDKPT.UI.ShowOutbidMessage then
        GDKPT.UI.ShowOutbidMessage(
            auctionId,
            row.itemLink,
            topBidder,
            newBid
        )
    end

    -- Play sound alert if activated
    if GDKPT.Core.Settings.OutbidAudioAlert == 1 then
        PlaySoundFile("Interface\\AddOns\\GDKPT\\Sounds\\Outbid.ogg", "Master")
    end

    -- Remove this auction from the player's active bids
    GDKPT.Core.PlayerActiveBids[auctionId] = nil
end




-------------------------------------------------------------------
-- Update visual row fields
-------------------------------------------------------------------

local function UpdateRowFields(row, newBid, topBidder)
    row.currentBid = newBid
    row.topBidder = topBidder

    -- Update bid text
    row.bidText:SetText(string.format("Current Bid: |cffffd700%d|r", newBid))

    -- Update top bidder text + color
    row.topBidderText:SetText("Top Bidder: " .. topBidder)
    if topBidder == UnitName("player") then
        row.topBidderText:SetTextColor(0, 1, 0) -- green
    else
        row.topBidderText:SetTextColor(1, 1, 1) -- white
    end

    -- Next minimum bid button text
    local nextMinBid = newBid + row.minIncrement
    row.bidButton:Enable()
    row.bidButton:SetText(nextMinBid .. " G")
end





-------------------------------------------------------------------
-- Validate and update remaining auction time
-------------------------------------------------------------------

local function UpdateAuctionTimer(row, remainingTime)
    if row.duration and remainingTime > row.duration then
        remainingTime = row.duration
    end

    row.endTime = GetTime() + remainingTime

    -- Auction is over (0 seconds left)
    if remainingTime <= 0 then
        row.bidBox:SetText("")
    end
end


-------------------------------------------------------------------
-- Update UI dependencies after a change
-------------------------------------------------------------------

local function UpdateGlobalUI()
    GDKPT.AuctionLayout.RepositionAllAuctions()

    if GDKPT.Utils.UpdateMyBidsDisplay then
        GDKPT.Utils.UpdateMyBidsDisplay()
    end

    if GDKPT.MiniBidFrame
        and GDKPT.MiniBidFrame.Frame
        and GDKPT.MiniBidFrame.Frame:IsShown()
    then
        GDKPT.MiniBidFrame.Update()
    end
end



-------------------------------------------------------------------
-- Auction Update function that gets called whenever an auction 
-- receives a new bid from any player
-------------------------------------------------------------------


function GDKPT.AuctionBid.HandleAuctionUpdate(auctionId, newBid, topBidder, remainingTime)

    local row = GDKPT.Core.AuctionFrames[auctionId]
    if not row then
        return  -- Auction row doesn't exist (should never happen)
    end

    -- player and previous bidder
    local playerName = UnitName("player")
    local previousBidder = GDKPT.Core.LastKnownTopBidder[auctionId]

    -- OUTBID - Player was previously the top bidder but no longer is
    if previousBidder == playerName
        and topBidder ~= playerName
        and topBidder ~= ""
    then
        HandleOutbid(row, auctionId, newBid, topBidder)
    end
    
    -- Update internal tracking of the top bidder
    GDKPT.Core.LastKnownTopBidder[auctionId] = topBidder

    -- Update visual row data
    UpdateRowFields(row, newBid, topBidder)
    UpdateAuctionTimer(row, remainingTime)

    -- Update row color
    if GDKPT.AuctionRow.UpdateRowColor then
        GDKPT.AuctionRow.UpdateRowColor(row)
    end

    -- Reveal and reposition UI elements
    row:Show()
    UpdateGlobalUI()
end
