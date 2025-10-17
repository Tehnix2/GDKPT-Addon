

GDKPT.AuctionFavorites = {}
GDKPT.FavoritesUI = {}

local FAV_ROW_HEIGHT = 30 -- Increased height for EditBox
local favoriteFramePool = {}


-------------------------------------------------------------------
-- Core Favorite Logic
-------------------------------------------------------------------


-- Toggles an item's favorite status
function GDKPT.AuctionFavorites.ToggleFavorite(itemLink)
    if not itemLink then return end
    
    -- *** BUG FIX IS HERE ***
    -- We must parse the itemID from the link string, e.g., "|c...|Hitem:49623:...|h..."
    local itemID = itemLink:match("item:(%d+):")
    
    if not itemID then
        print("|cffff8800[GDKPT]|r Could not parse itemID from link: " .. (itemLink or "nil"))
        return
    end

    itemID = tonumber(itemID) -- itemID from match is a string

    -- Now, check if the item info is cached. This is just a safety check.
    local itemName = GetItemInfo(itemLink)
    if not itemName then
        print("|cffff8800[GDKPT]|r Warning: Item info for " .. itemLink .. " is not cached. Favoriting anyway.")
    end

    if GDKPT.Core.PlayerFavorites[itemID] then
        -- Item is a favorite, remove it
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

    -- 1. Refresh the Favorite List UI (if it's open)
    if GDKPT.UI.FavoriteFrame and GDKPT.UI.FavoriteFrame:IsVisible() then
        GDKPT.FavoritesUI.Update()
    end

    -- 2. Update any active auction rows for this item
    GDKPT.AuctionFavorites.UpdateAuctionRowVisuals(itemID)
    
    -- 3. Re-apply the favorite filter if it's active
    if GDKPT.Core.isFavoriteFilterActive then
        GDKPT.AuctionFavorites.FilterByFavorites()
    end
end



--[[





-- Toggles an item's favorite status
function GDKPT.AuctionFavorites.ToggleFavorite(itemLink)
    if not itemLink then return end
    
    -- GetItemInfo returns 19 values in 3.3.5, itemID is the 14th
    local itemName, _, _, _, _, _, _, _, _, _, _, _, _, itemID = GetItemInfo(itemLink)
    
    if not itemID then
        print("|cffff8800[GDKPT]|r Could not get item info for " .. (itemLink or "nil"))
        return
    end

    if GDKPT.Core.PlayerFavorites[itemID] then
        -- Item is a favorite, remove it
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

    -- 1. Refresh the Favorite List UI
    GDKPT.FavoritesUI.Update()

    -- 2. Update any active auction rows for this item
    GDKPT.AuctionFavorites.UpdateAuctionRowVisuals(itemID)
    
    -- 3. Re-apply the favorite filter if it's active
    if GDKPT.Core.isFavoriteFilterActive then
        GDKPT.AuctionFavorites.FilterByFavorites()
    end
end


]]

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

            -- *** VISUALS FIX IS HERE ***
            -- Use SetVertexColor on the icon, as defined in your AuctionRow file
            if frame.favoriteIcon then 
                if isFav then
                    frame.favoriteIcon:SetVertexColor(1, 0.8, 0, 1) -- Gold/Yellow
                else
                    frame.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Grayed out
                end
            end

            -- TODO: Apply/Remove Glow Effect
            if frame.GlowEffect then
                if isFav and frame.endOverlay:IsVisible() == false then -- Only glow if auction is active
                    frame.GlowEffect:Show()
                else
                    frame.GlowEffect:Hide()
                end
            end
        end
    end
end


--[[






-- Updates the star/glow for any matching auction rows
function GDKPT.AuctionFavorites.UpdateAuctionRowVisuals(itemID)
    for auctionID, frame in pairs(GDKPT.Core.AuctionFrames) do
        if frame.itemID == itemID then
            local isFav = GDKPT.AuctionFavorites.IsFavorite(itemID)
            frame.isFavorite = isFav -- This is used by FilterByFavorites()

            -- TODO: Update star icon
            -- Assuming the star button is frame.FavoriteButton
            if frame.FavoriteButton then
                -- SetChecked(true) usually shows the "pushed" or "lit" texture
                frame.FavoriteButton:SetChecked(isFav)
            end

            -- TODO: Apply/Remove Glow Effect
            -- This requires a glow texture/frame to be part of the row.
            -- Assuming frame.GlowEffect is a texture:
            if frame.GlowEffect then
                if isFav then
                    frame.GlowEffect:Show()
                else
                    frame.GlowEffect:Hide()
                end
            end
        end
    end
end


]]

-- Updates all auction rows (e.g., on UI load)
function GDKPT.AuctionFavorites.UpdateAllAuctionRowVisuals()
     for auctionID, frame in pairs(GDKPT.Core.AuctionFrames) do
        if frame.itemID then
            GDKPT.AuctionFavorites.UpdateAuctionRowVisuals(frame.itemID)
        end
     end
end


-------------------------------------------------------------------
-- Auction Row Filtering (Copied from original file)
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

-- Filter Button OnClick (Copied from original file)
GDKPT.UI.FavoriteFilterButton:SetScript(
    "OnClick",
    function(self)
        GDKPT.Core.isFavoriteFilterActive = not GDKPT.Core.isFavoriteFilterActive
        GDKPT.UI.UpdateFilterButtonText()
        GDKPT.AuctionFavorites.FilterByFavorites()
    end
)

-------------------------------------------------------------------
-- Favorite List UI (Re-implementation)
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
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
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
    local eb = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    eb:SetSize(80, 20)
    eb:SetPoint("RIGHT", -30, 0) -- Position adjusted for the 'X' button
    eb:SetNumeric(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontNormalSmall")
    eb:SetTextInsets(5, 5, 0, 0)
    eb.label = eb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    eb.label:SetText("Max Bid:")
    eb.label:SetPoint("RIGHT", eb, "LEFT", -3, 0)
    
    eb:SetScript("OnEnterPressed", function(self)
        self:ClearFocus() -- Lose focus
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

-- Main function to update the list display
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
function GDKPT.AuctionFavorites.CheckAutoBid(auctionID, itemID, minNextBid, highBidderName)
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

    -- Check if we have enough gold
    if GetMoney() < (bidAmount * 10000) then
        print(("|cffff8800[GDKPT]|r Auto-bid failed for %s. Not enough gold to bid %dg."):format(favoriteData.link, bidAmount))
        return
    end

    print(("|cff99ff99[GDKPT]|r Auto-bidding %dg on %s..."):format(bidAmount, favoriteData.link))
    -- TODO: UNCOMMENT THIS and replace with your comms function
    -- GDKPT.Comms.SendBid(auctionID, bidAmount)
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











-- Old code

--[[

GDKPT.AuctionFavorites = {}


-------------------------------------------------------------------
-- Function that updates the layout of the auction content frame
-- based on the amount of active auctions at a time.
-- This function also handles filtering by favorites.
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
        GDKPT.AuctionFavorites.FilterByFavorites()
    end
)




-------------------------------------------------------------------
-- Favorite Item UI
-------------------------------------------------------------------


GDKPT.FavoritesUI = {}

local FAV_ROW_HEIGHT = 28
local favoriteFramePool = {}
local favoriteListFrame


]]

--[[


-- Utility function to create a single entry in the list
local function CreateFavoriteEntry(parent, index)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FAV_ROW_HEIGHT)
    frame:EnableMouse(true)
    frame.index = index
    frame:SetClampedToScreen(true)

    -- Row background to distinguish items
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
    bg:SetAllPoints(frame)
    frame.bg = bg

    -- Item Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", 5, 0)
    frame.icon = icon

    -- Item Link Text (shows the colored link)
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetPoint("RIGHT", -80, 0) -- Make room for the remove button
    nameText:SetJustifyH("LEFT")
    frame.nameText = nameText
    
    -- Remove Button
    local removeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    removeButton:SetSize(60, 20)
    removeButton:SetText("Remove")
    removeButton:SetPoint("RIGHT", -5, 0)

    -- OnClick handler for Remove Button
    removeButton:SetScript("OnClick", function()
        -- Use the core toggle function to remove it
        if frame.itemLink then
            GDKPT.Core.ToggleFavorite(frame.itemLink) 
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


-- Main function to update the list display (called when opened or when a favorite is added/removed)
function GDKPT.FavoritesUI.Update()
    if not favoriteListFrame or not favoriteListFrame.ScrollContent then return end
    
    local ScrollFrame = favoriteListFrame.ScrollFrame
    local ScrollContent = favoriteListFrame.ScrollContent
    
    -- Hide all existing entries
    for _, entry in ipairs(favoriteFramePool) do
        entry:Hide()
    end

    local totalHeight = 0
    local favoriteLinks = {}
    
    -- Get all favorite links from the core table
    for link in pairs(GDKPT.Core.PlayerFavorites) do
        table.insert(favoriteLinks, link)
    end
    
    -- Sort them alphabetically for stable display
    table.sort(favoriteLinks)
    
    for i, itemLink in ipairs(favoriteLinks) do
        local entry = favoriteFramePool[i]
        if not entry then
            entry = CreateFavoriteEntry(ScrollContent, i)
            table.insert(favoriteFramePool, entry)
        end

        -- Set data
        entry.itemLink = itemLink
        
        -- Get item info for icon and name
        local itemName, itemLinkColored, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, texture = GetItemInfo(itemLink)
        
        entry.nameText:SetText(itemLinkColored or itemName or "Unknown Item") 
        entry.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        
        -- Set background color alternating for readability
        if i % 2 == 0 then
            entry.bg:SetVertexColor(0.15, 0.15, 0.15, 0.5)
        else
            entry.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
        end
        
        -- Position
        local yPosition = -5 - ((i - 1) * FAV_ROW_HEIGHT)
        entry:ClearAllPoints()
        entry:SetPoint("TOPLEFT", ScrollContent, "TOPLEFT", 0, yPosition)
        entry:SetWidth(ScrollContent:GetWidth())
        entry:Show()
        
        totalHeight = totalHeight + FAV_ROW_HEIGHT
    end

    -- Adjust ScrollContent height
    local contentHeight = math.max(ScrollFrame:GetHeight() - 10, totalHeight + 10) -- Add a bit of padding
    ScrollContent:SetHeight(contentHeight)

    if ScrollFrame.ScrollBar then
        ScrollFrame.ScrollBar:SetValue(0) -- Scroll to top on refresh
    end
end

]]





-------------------------------------------------------------------
-- Favorite row frame within the main favorite window
-------------------------------------------------------------------


--[[



local function CreateFavoriteFrame()
    -- Use a standard frame template for styling
    local frame = CreateFrame("Frame", "GDKPT_FavoriteListFrame", UIParent) 
    frame:SetSize(380, 480)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    

    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 12,
        insets = {left = 11, right = 11, top = 12, bottom = 11}
    })
    frame:SetBackdropColor(0.05, 0.05, 0.1, 0.95) -- Slightly blue background
    frame:Hide()
    
    -- Title Bar
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetText("|cff33ccffFavorite Items|r")
    title:SetPoint("TOP", 0, -16)
    
    -- Close Button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Scroll Frame for the list
    local scrollFrame = CreateFrame("ScrollFrame", "GDKPT_FavoriteListScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 10) 
    scrollFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    frame.ScrollFrame = scrollFrame
    
    -- Scroll Content
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(scrollFrame:GetWidth() - 2) 
    scrollFrame:SetScrollChild(scrollContent)
    frame.ScrollContent = scrollContent
    
    favoriteListFrame = frame
    
    -- Link the update function to the frame's OnShow event
    frame:SetScript("OnShow", function() GDKPT.FavoritesUI.Update() end)
    
    return frame
end

]]

--[[
-- Initialize the frame once
GDKPT.FavoritesUI.Frame = GDKPT.FavoritesUI.CreateFrame()




-- Function to toggle visibility (for the new button on the main auction frame)
function GDKPT.FavoritesUI.ToggleVisibility()
    if GDKPT.FavoritesUI.Frame:IsShown() then
        GDKPT.FavoritesUI.Frame:Hide()
    else
        GDKPT.FavoritesUI.Frame:Show()
        GDKPT.FavoritesUI.Update()
    end
end
]]



























-------------------------------------------------------------------
-- Favorite Item Management 
-------------------------------------------------------------------

-- Function to check if an item link is a favorite (Used by Auction Row)

--[[
function GDKPT.AuctionFavorites.IsItemFavorite(itemLink)
    if not itemLink then return false end
    
    return GDKPT.Core.PlayerFavorites[itemLink] == true
end

]]


--[[

-- Function to toggle favorite status (Used by Slash Command and UI)
function GDKPT.AuctionFavorites.ToggleFavorite(itemLink)

    if not itemLink then return end
    
    
    if GDKPT.Core.PlayerFavorites[itemLink] then
        GDKPT.Core.PlayerFavorites[itemLink] = nil
        print(string.format("|cffcccccc[GDKPT]|r Removed favorite: %s", itemLink))
    else
        GDKPT.Core.PlayerFavorites[itemLink] = true
        print(string.format("|cff00ff00[GDKPT]|r Added favorite: %s", itemLink))
    end

    
    
    -- If the Favorites UI is open, refresh it.
    if GDKPT.AuctionFavorites.FavoritesUI and GDKPT.AuctionFavorites.FavoritesUI.Update then
        GDKPT.AuctionFavorites.FavoritesUI.Update()
    end

    -- Call the auction layout function to ensure row highlights update immediately
    if GDKPT.AuctionFavorites and GDKPT.AuctionFavorites.FilterByFavorites then
        GDKPT.AuctionFavorites.FilterByFavorites()
    end

    
end

]]





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
