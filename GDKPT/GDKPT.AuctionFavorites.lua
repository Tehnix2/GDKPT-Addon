GDKPT.AuctionFavorites = {}
GDKPT.FavoritesUI = {}

local FAV_ROW_HEIGHT = 30 
local favoriteFramePool = {}


-------------------------------------------------------------------
-- Function toggles favorite status for items and auctions,
-- called through /gdkp favorite or clicking the star on an auction
-------------------------------------------------------------------

function GDKPT.AuctionFavorites.ToggleFavorite(itemLink)
    if not itemLink then return end
    
    local itemID = itemLink:match("item:(%d+):")
    
    if not itemID then
        print("|cffff8800[GDKPT]|r Could not parse itemID from link: " .. (itemLink or "nil"))
        return
    end

    itemID = tonumber(itemID) 

    -- Check if the item info is cached
    local itemName = GetItemInfo(itemLink)
    if not itemName then
        print("|cffff8800[GDKPT]|r Warning: Item info for " .. itemLink .. " is not cached. Favoriting anyway.")
    end

    if GDKPT.Core.PlayerFavorites[itemID] then
        -- Item is a favorite already, remove it
        GDKPT.Core.PlayerFavorites[itemID] = nil
        print(("|cff99ff99[GDKPT]|r Removed %s from favorites."):format(itemLink))
    else
        -- Item is not a favorite, add it
        GDKPT.Core.PlayerFavorites[itemID] = {
            link = itemLink,
            maxBid = 0 -- Default max bid
        }
        print(("|cff99ff99[GDKPT]|r Added %s to favorites."):format(itemLink))
    end

    if GDKPT.UI.FavoriteFrame and GDKPT.UI.FavoriteFrame:IsVisible() then
        GDKPT.FavoritesUI.Update()
    end

    GDKPT.AuctionFavorites.UpdateAuctionRowVisuals(itemID)
    
    
    if GDKPT.Core.isFavoriteFilterActive then
        GDKPT.AuctionFavorites.FilterByFavorites()
    end
end



-- Checks if an itemID is a favorite
function GDKPT.AuctionFavorites.IsFavorite(itemID)
    return GDKPT.Core.PlayerFavorites[itemID] ~= nil
end

-- Gets the favorite data {link, maxBid}
function GDKPT.AuctionFavorites.GetFavoriteData(itemID)
    return GDKPT.Core.PlayerFavorites[itemID]
end




-- Updates the star/glow for any matching auction rows
function GDKPT.AuctionFavorites.UpdateAuctionRowVisuals(itemID)
    for auctionID, frame in pairs(GDKPT.Core.AuctionFrames) do
        if frame.itemID == itemID then
            local isFav = GDKPT.AuctionFavorites.IsFavorite(itemID)
            frame.isFavorite = isFav -- This is used by FilterByFavorites()

            if frame.favoriteIcon then 
                if isFav then
                    frame.favoriteIcon:SetVertexColor(1, 0.8, 0, 1) -- Gold/Yellow
                else
                    frame.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Grayed out
                end
            end

            if isFav then
                -- Set the backdrop to a highlight color
                frame:SetBackdropColor(1,1,0,0.8)
            else
                -- Reset the backdrop to the default color, stored on the frame / row
                frame:SetBackdropColor(frame.DEFAULT_R, frame.DEFAULT_G, frame.DEFAULT_B, frame.DEFAULT_A)
            end
        end
    end
end


-- Updates all auction rows (e.g., on UI load)
function GDKPT.AuctionFavorites.UpdateAllAuctionRowVisuals()
     for auctionID, frame in pairs(GDKPT.Core.AuctionFrames) do
        if frame.itemID then
            GDKPT.AuctionFavorites.UpdateAuctionRowVisuals(frame.itemID)
        end
     end
end


-------------------------------------------------------------------
-- Auction Row Filtering 
-------------------------------------------------------------------

function GDKPT.AuctionFavorites.FilterByFavorites()
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
            -- Step 1: Set a permanent position for the row
            local yPosition = -5 - ((i - 1) * GDKPT.Core.ROW_HEIGHT)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", GDKPT.UI.AuctionContentFrame, "TOPLEFT", 5, yPosition)

            -- Step 2: Determine visibility based on the favorite filter.
            -- We must ensure frame.isFavorite is set *before* this runs.
            if GDKPT.Core.isFavoriteFilterActive then
                if frame.isFavorite then
                    frame:Show()
                else
                    frame:Hide()
                end
            else
                frame:Show()
            end
        end
    end

    -- Step 3: Adjust the content frame height
    GDKPT.UI.AuctionContentFrame:SetHeight(math.max(100, #sortedAuctionIDs * GDKPT.Core.ROW_HEIGHT))
end

-- Filter Button OnClick
GDKPT.UI.FavoriteFilterButton:SetScript(
    "OnClick",
    function(self)
        GDKPT.Core.isFavoriteFilterActive = not GDKPT.Core.isFavoriteFilterActive
        GDKPT.UI.UpdateFilterButtonText()
        GDKPT.AuctionFavorites.FilterByFavorites()
    end
)

-------------------------------------------------------------------
-- Function that creates favorite entries
-------------------------------------------------------------------

-- Utility function to create a single entry in the list
local function CreateFavoriteEntry(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FAV_ROW_HEIGHT)
    frame:SetWidth(parent:GetWidth())
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    -- Row background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    frame.bg = bg

    -- Item Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(FAV_ROW_HEIGHT - 4, FAV_ROW_HEIGHT - 4) -- Make icon almost full height
    icon:SetPoint("LEFT", 2, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Standard icon crop
    frame.icon = icon

    -- Item Link Text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetPoint("RIGHT", -155, 0) -- Make room for editbox and button
    nameText:SetJustifyH("LEFT")
    frame.nameText = nameText
    
    -- Max Bid EditBox
    local eb = CreateFrame("EditBox", nil, frame, "BackdropTemplate")   -- "InputBoxTemplate"
    eb:SetSize(80, 20)
    eb:SetPoint("RIGHT", -30, 0) -- Position adjusted for the 'X' button
    eb:SetNumeric(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontNormalSmall")
    eb:SetTextInsets(5, 5, 0, 0)
    eb.label = eb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    eb.label:SetText("Max Bid:")
    eb.label:SetPoint("RIGHT", eb, "LEFT", -3, 0)

    eb:SetBackdrop(
        {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            edgeSize = 12,
            insets = {left = 3, right = 3, top = 3, bottom = 3}
        }
    )

    eb:SetBackdropColor(0, 0, 0, 1)
    eb:SetBackdropBorderColor(1, 1, 1, 1)
    eb:SetTextInsets(5, 5, 3, 3)


    eb:SetScript("OnEnterPressed", function(self)
        self:ClearFocus() 
    end)
    eb:SetScript("OnEscapePressed", function(self)
        -- Reset to saved value on escape
        local data = GDKPT.Core.PlayerFavorites[frame.itemID]
        if data then
            self:SetText(data.maxBid > 0 and tostring(data.maxBid) or "")
        end
        self:ClearFocus()
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        local value = tonumber(self:GetText()) or 0
        if value < 0 then value = 0 end
        
        if GDKPT.Core.PlayerFavorites[frame.itemID] then
            GDKPT.Core.PlayerFavorites[frame.itemID].maxBid = value
            -- Update text to formatted number (e.g., remove leading zeros)
            self:SetText(value > 0 and tostring(value) or "") 
        end
    end)
    frame.maxBidEditBox = eb

    -- Remove Button
    local removeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    removeButton:SetSize(20, 20) -- Smaller 'X' button
    removeButton:SetPoint("RIGHT", -5, 0)
    removeButton:SetScript("OnClick", function()
        if frame.itemLink then
            GDKPT.AuctionFavorites.ToggleFavorite(frame.itemLink) 
        end
    end)
    
    -- Mouseover for tooltip
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.itemLink then
            GameTooltip:SetHyperlink(self.itemLink)
        else
            GameTooltip:SetText("Favorite Item")
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return frame
end




-------------------------------------------------------------------
-- Function to update the favorite UI
-------------------------------------------------------------------


function GDKPT.FavoritesUI.Update()
    -- Get frames from GDKPT.UI
    local ScrollFrame = GDKPT.UI.FavoriteScrollFrame
    local ScrollContent = GDKPT.UI.FavoriteScrollContent
    if not ScrollFrame or not ScrollContent then return end
    
    -- Hide all existing entries
    for _, entry in ipairs(favoriteFramePool) do
        entry:Hide()
    end

    local totalHeight = 0
    local sortedFavorites = {}
    
    -- Get all favorite links from the core table to sort them
    for itemID, data in pairs(GDKPT.Core.PlayerFavorites) do
        -- We need to sort by name, which we get from the link
        local name = GetItemInfo(data.link)
        table.insert(sortedFavorites, {id = itemID, link = data.link, maxBid = data.maxBid, name = name or "Unknown"})
    end
    
    -- Sort them alphabetically by name
    table.sort(sortedFavorites, function(a, b) return a.name < b.name end)
    
    for i, data in ipairs(sortedFavorites) do
        local entry = favoriteFramePool[i]
        if not entry then
            entry = CreateFavoriteEntry(ScrollContent)
            table.insert(favoriteFramePool, entry)
        end

        -- Set data
        entry.itemLink = data.link
        entry.itemID = data.id
        
        local itemName, itemLinkColored, _, _, _, _, _, _, _, texture = GetItemInfo(data.link)
        
        entry.nameText:SetText(itemLinkColored or itemName or "Unknown Item") 
        entry.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        entry.maxBidEditBox:SetText(data.maxBid > 0 and tostring(data.maxBid) or "")
        
        -- Set background color
        if i % 2 == 0 then
            entry.bg:SetVertexColor(0.15, 0.15, 0.15, 0.5)
        else
            entry.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
        end
        
        -- Position
        local yPosition = -2 - ((i - 1) * FAV_ROW_HEIGHT) -- 2px padding
        entry:ClearAllPoints()
        entry:SetPoint("TOPLEFT", ScrollContent, "TOPLEFT", 2, yPosition)
        entry:SetWidth(ScrollContent:GetWidth() - 4)
        entry:Show()
        
        totalHeight = totalHeight + FAV_ROW_HEIGHT
    end

    -- Adjust ScrollContent height
    local contentHeight = math.max(ScrollFrame:GetHeight() - 10, totalHeight + 10)
    ScrollContent:SetHeight(contentHeight)
end


-------------------------------------------------------------------
-- Auto-Bidding and Win-Handling Logic
-- These are stubs for you to call from your other addon files.
-------------------------------------------------------------------

-- CALL THIS when an auction update is received (e.g., new bid)
-- You must provide the auction's ID, its itemID, the *next minimum bid*,
-- and the name of the current high bidder.
function GDKPT.AuctionFavorites.CheckAutoBid(auctionID, itemID, minNextBid, highBidderName, itemLink)

    local myName = UnitName("player")
    if highBidderName == myName then
        return -- We are already the high bidder
    end

    local favoriteData = GDKPT.AuctionFavorites.GetFavoriteData(itemID)
    
    -- Not a favorite, or no max bid set
    if not favoriteData or favoriteData.maxBid <= 0 then
        return
    end

    local myMax = favoriteData.maxBid

    -- Our max bid is less than the minimum required bid
    if myMax < minNextBid then
        return
    end

    -- Determine bid amount
    local bidAmount = minNextBid
    local minIncrement = GDKPT.Core.leaderSettings.minIncrement or 1

    -- If our max bid is less than the *next* potential bid, just bid our max
    if myMax < (minNextBid + minIncrement) then
        bidAmount = myMax
    end
    
    -- Final check: Ensure we don't bid more than our max
    if bidAmount > myMax then
        bidAmount = myMax
    end

    --[[
    -- Check if we have enough gold
    if GetMoney() < (bidAmount * 10000) then
        print(("|cffff8800[GDKPT]|r Auto-bid failed for %s. Not enough gold to bid %dg."):format(favoriteData.link, bidAmount))
        return
    end
    ]]


    print(("|cff99ff99[GDKPT]|r Auto-bidding %dg on %s..."):format(bidAmount, favoriteData.link))

    local msg = string.format("BID:%d:%d", auctionID, bidAmount)
    SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")
    SendChatMessage(string.format("[GDKPT] [Autobid] I'm bidding %d gold on %s !", bidAmount, itemLink), "RAID")

end

-- CALL THIS when an auction ends and you know the winner.
function GDKPT.AuctionFavorites.HandleAuctionWon(itemID, winnerName)
    local myName = UnitName("player")
    
    if winnerName == myName then
        local favoriteData = GDKPT.AuctionFavorites.GetFavoriteData(itemID)
        if favoriteData then
            print(("|cff99ff99[GDKPT]|r You won %s! Removing from favorites."):format(favoriteData.link))
            -- This will remove it and update the UI
            GDKPT.AuctionFavorites.ToggleFavorite(favoriteData.link)
        end
    end
end
