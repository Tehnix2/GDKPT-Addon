GDKPT.AuctionFilters = {}





-------------------------------------------------------------------
-- Auction Filters
-------------------------------------------------------------------

GDKPT.AuctionFilters = GDKPT.AuctionFilters or {}

GDKPT.Core.FilterMyBidsActive = false
GDKPT.Core.FilterOutbidActive = false
GDKPT.Core.isFavoriteFilterActive = false

-------------------------------------------------------------------
-- New Auction Filter Dropdown
-------------------------------------------------------------------


-- Create the dropdown frame
local FilterDropdown = CreateFrame("Frame", "GDKPT_FilterDropdown", GDKPT.UI.AuctionWindow, "UIDropDownMenuTemplate")
FilterDropdown:SetPoint("TOP", GDKPT.UI.AuctionWindow, "TOP", -420, -15)
UIDropDownMenu_SetWidth(FilterDropdown, 100)
UIDropDownMenu_SetButtonWidth(FilterDropdown, 100)




function GDKPT.AuctionFilters.ApplyAllFilters()
    local playerName = UnitName("player")
    
    -- Check if any filters are active
    local anyFilterActive = GDKPT.Core.FilterMyBidsActive or 
                            GDKPT.Core.FilterOutbidActive or 
                            GDKPT.Core.isFavoriteFilterActive
    
    if not anyFilterActive then
        -- No filters: show all rows
        for _, row in pairs(GDKPT.Core.AuctionFrames) do
            row:Show()
        end
    else
        -- At least one filter is active
        for auctionId, row in pairs(GDKPT.Core.AuctionFrames) do
            local showRow = false
            
            -- "My Bids" filter
            if GDKPT.Core.FilterMyBidsActive then
                if GDKPT.Core.PlayerBidHistory[auctionId] then
                    showRow = true
                end
            end
            
            -- "Outbid" filter
            if GDKPT.Core.FilterOutbidActive then
                local hasBid = GDKPT.Core.PlayerBidHistory[auctionId]
                local isWinning = (row.topBidder == playerName)
                if hasBid and not isWinning and row.topBidder ~= "" then
                    showRow = true
                end
            end
            
            -- "Favorites" filter
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
    
    -- Reposition all visible auctions
    if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
        GDKPT.AuctionLayout.RepositionAllAuctions()
    end
    
    -- Update the dropdown text
    GDKPT.UI.UpdateFilterDropdownText()
end




function GDKPT.UI.UpdateFilterDropdownText()
    local filters = {}
    if GDKPT.Core.FilterMyBidsActive then
        table.insert(filters, "My Bids")
    end
    if GDKPT.Core.FilterOutbidActive then
        table.insert(filters, "Outbid")
    end
    if GDKPT.Core.isFavoriteFilterActive then
        table.insert(filters, "Favs")
    end
    
    if #filters == 0 then
        UIDropDownMenu_SetText(FilterDropdown, "All")
    elseif #filters == 1 then
        -- Shorten text for single filters
        local text = filters[1]
        if text == "My Bids" then
            text = "Bids"
        elseif text == "Favorites" then
            text = "Favs"
        end
        UIDropDownMenu_SetText(FilterDropdown, text)
    else
        -- Show count for multiple filters
        UIDropDownMenu_SetText(FilterDropdown, filters[1] .. " +" .. (#filters - 1))
    end
end



local function FilterDropdown_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()

    -- "Show All" option
    info.text = "Show All"
    info.value = "showall"
    info.notCheckable = true  -- This is a button, not checkbox
    info.func = function()
        GDKPT.Core.FilterMyBidsActive = false
        GDKPT.Core.FilterOutbidActive = false
        GDKPT.Core.isFavoriteFilterActive = false
        GDKPT.AuctionFilters.ApplyAllFilters()
        CloseDropDownMenus()  -- Close menu after selection
    end
    UIDropDownMenu_AddButton(info, level)

    -- Divider
    info = UIDropDownMenu_CreateInfo()
    info.disabled = 1
    info.notCheckable = 1
    info.text = ""
    UIDropDownMenu_AddButton(info, level)

    -- "My Bids" checkbox
    info = UIDropDownMenu_CreateInfo()
    info.text = "My Bids"
    info.value = "mybids"
    info.keepShownOnClick = true  -- FIXED: Correct property name
    info.isNotRadio = true
    info.checked = GDKPT.Core.FilterMyBidsActive
    info.func = function(self)
        GDKPT.Core.FilterMyBidsActive = not GDKPT.Core.FilterMyBidsActive
        GDKPT.AuctionFilters.ApplyAllFilters()
    end
    UIDropDownMenu_AddButton(info, level)
    
    -- "Outbid" checkbox
    info = UIDropDownMenu_CreateInfo()
    info.text = "Outbid"
    info.value = "outbid"
    info.keepShownOnClick = true
    info.isNotRadio = true
    info.checked = GDKPT.Core.FilterOutbidActive
    info.func = function(self)
        GDKPT.Core.FilterOutbidActive = not GDKPT.Core.FilterOutbidActive
        GDKPT.AuctionFilters.ApplyAllFilters()
    end
    UIDropDownMenu_AddButton(info, level)
    
    -- "Favorites" checkbox
    info = UIDropDownMenu_CreateInfo()
    info.text = "Favorites"
    info.value = "favorites"
    info.keepShownOnClick = true
    info.isNotRadio = true
    info.checked = GDKPT.Core.isFavoriteFilterActive
    info.func = function(self)
        GDKPT.Core.isFavoriteFilterActive = not GDKPT.Core.isFavoriteFilterActive
        GDKPT.AuctionFilters.ApplyAllFilters()
    end
    UIDropDownMenu_AddButton(info, level)
end

-- Initialize the dropdown
UIDropDownMenu_Initialize(FilterDropdown, FilterDropdown_Initialize)

-- Set initial text
GDKPT.UI.UpdateFilterDropdownText()


FilterDropdown:SetScale(0.9)  -- Scale down the entire dropdown by 10%










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