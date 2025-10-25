GDKPT.AuctionBid = {}



-------------------------------------------------------------------
-- Function that gets called whenever anyone has bid on any auction
-------------------------------------------------------------------


function GDKPT.AuctionBid.HandleAuctionUpdate(auctionId, newBid, topBidder, remainingTime)
    local row = GDKPT.Core.AuctionFrames[auctionId]
    if not row then
        return
    end
    
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
    row.bidBox:SetText("")
    row.bidButton:Enable()
    row.bidButton:SetText(nextMinBid .. "G")

    row:Show()
end
