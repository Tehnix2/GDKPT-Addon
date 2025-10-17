GDKPT.AuctionBid = {}



-------------------------------------------------------------------
-- Function that gets called whenever anyone has bid on any auction
-------------------------------------------------------------------



function GDKPT.AuctionBid.HandleAuctionUpdate(auctionId, newBid, topBidder, endTime)
    local row = GDKPT.Core.AuctionFrames[auctionId]
    if not row then
        return
    end

    -- Update internal data
    row.currentBid = newBid
    row.topBidder = topBidder
    row.endTime = tonumber(endTime)

    -- Update UI Text
    row.bidText:SetText(string.format("Current Bid: |cffffd700%d|r", newBid))
    row.topBidderText:SetText("Top Bidder: " .. topBidder)

    -- Set bidder text color
    if topBidder == UnitName("player") then
        row.topBidderText:SetTextColor(0, 1, 0) -- Green if you are the top bidder
    else
        row.topBidderText:SetTextColor(1, 1, 1) -- White otherwise
    end

    -- Calculate and display the next minimum bid on the bidBox
    local nextMinBid = newBid + row.minIncrement
    row.bidBox:SetText("")

    -- Re-enable the button and set its new text
    row.bidButton:Enable()
    row.bidButton:SetText(nextMinBid .. "G")
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