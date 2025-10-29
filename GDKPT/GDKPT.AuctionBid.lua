GDKPT.AuctionBid = {}

GDKPT.Core.LastKnownTopBidder = {}  -- Track previous top bidder per auction

-------------------------------------------------------------------
-- Function that gets called whenever anyone has bid on any auction
-------------------------------------------------------------------


function GDKPT.AuctionBid.HandleAuctionUpdate(auctionId, newBid, topBidder, remainingTime)
    local row = GDKPT.Core.AuctionFrames[auctionId]
    if not row then
        return
    end


    local playerName = UnitName("player")
    local previousBidder = GDKPT.Core.LastKnownTopBidder[auctionId]
    
    -- NEW: Check if player was outbid
    if previousBidder == playerName and topBidder ~= playerName and topBidder ~= "" then
        -- Player was just outbid!
        
        -- Show message
        if GDKPT.UI.ShowOutbidMessage then
            GDKPT.UI.ShowOutbidMessage(auctionId, row.itemLink, topBidder, newBid)
        end
        
        -- Play sound if enabled
        if GDKPT.Core.Settings.OutbidAudioAlert == 1 then
            PlaySoundFile("Interface\\AddOns\\GDKPT\\Sounds\\Outbid.ogg","Master")
        end
    end
    
    -- Update tracking
    GDKPT.Core.LastKnownTopBidder[auctionId] = topBidder
    
    row.currentBid = newBid
    row.topBidder = topBidder
    
    row.endTime = GetTime() + remainingTime
    
    row.bidText:SetText(string.format("Current Bid: |cffffd700%d|r", newBid))
    row.topBidderText:SetText("Top Bidder: " .. topBidder)
    
    if topBidder == UnitName("player") then
        row.topBidderText:SetTextColor(0, 1, 0) 
    else
        row.topBidderText:SetTextColor(1, 1, 1) 
    end
    
    local nextMinBid = newBid + row.minIncrement

    local auctionEnded = (remainingTime <= 0)

    if auctionEnded then
        row.bidBox:SetText("")
    end

    --row.bidBox:SetText("")
    row.bidButton:Enable()
    row.bidButton:SetText(nextMinBid .. " G")

    if row.itemLink and row.stackCount and row.stackCount > 1 then
        local displayText = row.itemLink .. " |cffaaaaaa[x" .. row.stackCount .. "]|r"
        row.itemLinkText:SetText(displayText)
    end

    if GDKPT.AuctionRow.UpdateRowColor then
        GDKPT.AuctionRow.UpdateRowColor(row)
    end

    row:Show()
end
