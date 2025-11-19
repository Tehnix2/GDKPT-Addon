GDKPT.AuctionLayout = {}

-------------------------------------------------------------------
-- Function reorders all auction rows, depending on activated setting
-------------------------------------------------------------------
function GDKPT.AuctionLayout.RepositionAllAuctions()
    local auctionIds = {}
    for id, row in pairs(GDKPT.Core.AuctionFrames) do
        if row:IsShown() then  
            table.insert(auctionIds, id)
        end
    end
    
    if #auctionIds == 0 then
        GDKPT.UI.AuctionContentFrame:SetHeight(100)
        return
    end
    
    -- Sort auctions based on settings
    if GDKPT.Core.Settings.SortBidsToTop == 1 then
        -- Custom sort: priority order
        table.sort(auctionIds, function(a, b)
            local playerName = UnitName("player")
            local rowA = GDKPT.Core.AuctionFrames[a]
            local rowB = GDKPT.Core.AuctionFrames[b]
            
            -- Check if auctions have ended
            local auctionEndedA = rowA.endOverlay and rowA.endOverlay:IsShown()
            local auctionEndedB = rowB.endOverlay and rowB.endOverlay:IsShown()
            
            -- Check if player has bid on each auction
            local hasBidA = GDKPT.Core.PlayerBidHistory[a] or false
            local hasBidB = GDKPT.Core.PlayerBidHistory[b] or false
            
            -- Check if player is winning
            local isWinningA = (rowA.topBidder == playerName)
            local isWinningB = (rowB.topBidder == playerName)
            
            -- Check if player was outbid (has bid but not winning and someone else is winning)
            local isOutbidA = hasBidA and not isWinningA and rowA.topBidder ~= ""
            local isOutbidB = hasBidB and not isWinningB and rowB.topBidder ~= ""
            
            -- Ended auctions go back to normal position (sorted by ID only)
            -- They lose priority regardless of bid status
            if auctionEndedA and not auctionEndedB then return false end
            if not auctionEndedA and auctionEndedB then return true end
            if auctionEndedA and auctionEndedB then
                -- Apply NewAuctionsOnTop setting even for ended auctions
                if GDKPT.Core.Settings.NewAuctionsOnTop == 1 then
                    return a > b  -- Newer (higher ID) on top
                else
                    return a < b  -- Older (lower ID) on top
                end
            end
            
            -- For active auctions:
            -- Priority 1: Outbid auctions (highest priority - most urgent!)
            if isOutbidA and not isOutbidB then return true end
            if not isOutbidA and isOutbidB then return false end
            
            -- Priority 2: Winning auctions
            if isWinningA and not isWinningB then return true end
            if not isWinningA and isWinningB then return false end
            
            -- Priority 3: Any auctions with bids (but not winning/outbid)
            if hasBidA and not hasBidB then return true end
            if not hasBidA and hasBidB then return false end
            
            -- Priority 4: For auctions without bids, apply NewAuctionsOnTop
            if GDKPT.Core.Settings.NewAuctionsOnTop == 1 then
                return a > b  -- Newer (higher ID) on top
            else
                return a < b  -- Older (lower ID) on top
            end
        end)
    else
        -- Default sort: just by auction ID
        -- First sort normally
        table.sort(auctionIds)
        
        -- Then reverse if NewAuctionsOnTop is enabled
        local showNewOnTop = GDKPT.Core.Settings.NewAuctionsOnTop == 1
        if showNewOnTop then
            -- Reverse the array in place
            local i, j = 1, #auctionIds
            while i < j do
                auctionIds[i], auctionIds[j] = auctionIds[j], auctionIds[i]
                i = i + 1
                j = j - 1
            end
        end
    end
    
    -- Position all visible auctions
    local yOffset = -5
    local visibleCount = 0
    for i, auctionId in ipairs(auctionIds) do
        local row = GDKPT.Core.AuctionFrames[auctionId]
        if row and row:IsShown() then
            row:ClearAllPoints()
            row:SetPoint("TOP", GDKPT.UI.AuctionContentFrame, "TOP", 0, yOffset)
            yOffset = yOffset - (row:GetHeight() + 5)
            visibleCount = visibleCount + 1
        end
    end


    --[[
    -- Position all visible auctions
    local yOffset = -5
    local visibleCount = 0
    for i, auctionId in ipairs(auctionIds) do
        local row = GDKPT.Core.AuctionFrames[auctionId]
        if row and row:IsShown() then
            row:ClearAllPoints()
            row:SetPoint("TOP", GDKPT.UI.AuctionContentFrame, "TOP", 0, yOffset)
            yOffset = yOffset - (row:GetHeight() + 5)
            visibleCount = visibleCount + 1
        end
    end
    ]]
    
    local totalHeight = math.max(100, math.abs(yOffset) + 10)
    GDKPT.UI.AuctionContentFrame:SetHeight(totalHeight)
end
