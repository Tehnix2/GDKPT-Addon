GDKPT.AuctionFilters = {}

---
-- Main filter application function with OR logic
-- Shows auction if ANY active filter matches
---
function GDKPT.AuctionFilters.ApplyAllFilters()
    local playerName = UnitName("player")
    
    -- Check if any filters are active
    local anyFilterActive = GDKPT.Core.FilterMyBidsActive or 
                            GDKPT.Core.FilterOutbidActive or 
                            GDKPT.Core.isFavoriteFilterActive
    
    if not anyFilterActive then
        -- No filters: show all rows
        for _, row in pairs(GDKPT.Core.AuctionFrames) do
            if row then
                row:Show()
            end
        end
    else
        -- At least one filter is active - use OR logic
        for auctionId, row in pairs(GDKPT.Core.AuctionFrames) do
            if row then
                local showRow = false
                
                -- "My Bids" filter - show if player has bid
                if GDKPT.Core.FilterMyBidsActive then
                    if GDKPT.Core.PlayerBidHistory[auctionId] then
                        showRow = true
                    end
                end
                
                -- "Outbid" filter - show if player bid but is not winning
                if GDKPT.Core.FilterOutbidActive then
                    local hasBid = GDKPT.Core.PlayerBidHistory[auctionId]
                    local isWinning = (row.topBidder == playerName)
                    if hasBid and not isWinning and row.topBidder ~= "" then
                        showRow = true
                    end
                end
                
                -- "Favorites" filter - show if item is favorite
                if GDKPT.Core.isFavoriteFilterActive then
                    if row.isFavorite then
                        showRow = true
                    end
                end
                
                -- Apply visibility (OR logic: show if ANY filter matches)
                if showRow then
                    row:Show()
                else
                    row:Hide()
                end
            end
        end
    end
    
    -- Reposition all visible auctions
    if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
        GDKPT.AuctionLayout.RepositionAllAuctions()
    end
    
    -- Update dropdown text to reflect current filters
    if GDKPT.UI.UpdateFilterDropdownText then
        GDKPT.UI.UpdateFilterDropdownText()
    end
end

---
-- Backward compatibility: ApplyFilters is an alias for ApplyAllFilters
---
GDKPT.AuctionFilters.ApplyFilters = GDKPT.AuctionFilters.ApplyAllFilters

---
-- Toggle "My Bids" filter (kept for backward compatibility if called elsewhere)
---
function GDKPT.AuctionFilters.FilterByMyBids()
    GDKPT.Core.FilterMyBidsActive = not GDKPT.Core.FilterMyBidsActive
    GDKPT.AuctionFilters.ApplyAllFilters()
end

---
-- Toggle "Outbid" filter (kept for backward compatibility if called elsewhere)
---
function GDKPT.AuctionFilters.FilterByOutbid()
    GDKPT.Core.FilterOutbidActive = not GDKPT.Core.FilterOutbidActive
    GDKPT.AuctionFilters.ApplyAllFilters()
end

---
-- Toggle "Favorites" filter (kept for backward compatibility if called elsewhere)
---
function GDKPT.AuctionFilters.FilterByFavorites()
    GDKPT.Core.isFavoriteFilterActive = not GDKPT.Core.isFavoriteFilterActive
    GDKPT.AuctionFilters.ApplyAllFilters()
end