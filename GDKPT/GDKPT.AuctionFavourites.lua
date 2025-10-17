GDKPT.AuctionFavourites = {}


-------------------------------------------------------------------
-- Function that updates the layout of the auction content frame
-- based on the amount of active auctions at a time.
-- This function also handles filtering by favorites.
-------------------------------------------------------------------



function GDKPT.AuctionFavourites.FilterByFavourites()

    -- To ensure a consistent order, we'll sort the auction IDs.
    local sortedAuctionIDs = {}
    for id in pairs(GDKPT.Core.AuctionFrames) do
        table.insert(sortedAuctionIDs, id)
    end
    table.sort(sortedAuctionIDs)

    -- Loop through the sorted list to assign a fixed position to each row
    for i, id in ipairs(sortedAuctionIDs) do
        local frame = GDKPT.Core.AuctionFrames[id]
        if frame then
            -- Step 1: Set a permanent position for the row based on its sorted index.
            -- This ensures that rows don't shift up when others are hidden.
            local yPosition = -5 - ((i - 1) * GDKPT.Core.ROW_HEIGHT)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", GDKPT.UI.AuctionContentFrame, "TOPLEFT", 5, yPosition)

            -- Step 2: Determine visibility based on the favorite filter.
            if GDKPT.Core.isFavoriteFilterActive then
                if frame.isFavorite then
                    frame:Show()
                else
                    frame:Hide()
                end
            else
                -- If the filter is off, ensure all frames are visible.
                frame:Show()
            end
        end
    end

    -- Step 3: Adjust the content frame height to fit ALL rows, visible or not,
    -- to maintain the layout structure.
    GDKPT.UI.AuctionContentFrame:SetHeight(math.max(100, #sortedAuctionIDs * GDKPT.Core.ROW_HEIGHT))
end



GDKPT.UI.FavoriteFilterButton:SetScript(
    "OnClick",
    function(self)
        GDKPT.Core.isFavoriteFilterActive = not GDKPT.Core.isFavoriteFilterActive
        GDKPT.UI.UpdateFilterButtonText()
        GDKPT.AuctionFavourites.FilterByFavourites()
    end
)












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
