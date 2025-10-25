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

    local itemName = GetItemInfo(itemLink)
    if not itemName then
        print("|cffff8800[GDKPT]|r Warning: Item info for " .. itemLink .. " is not cached. Favoriting anyway.")
    end

    if GDKPT.Core.PlayerFavorites[itemID] then
        GDKPT.Core.PlayerFavorites[itemID] = nil
        print(("|cff99ff99[GDKPT]|r Removed %s from favorites."):format(itemLink))
    else
        GDKPT.Core.PlayerFavorites[itemID] = {
            link = itemLink,
            maxBid = 0 
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

    local shouldColorGolden = GDKPT.Core.Settings.Fav_ShowGoldenRows == 1

    for auctionID, frame in pairs(GDKPT.Core.AuctionFrames) do
        if frame.itemID == itemID then
            local isFav = GDKPT.AuctionFavorites.IsFavorite(itemID)
            frame.isFavorite = isFav 

            if frame.favoriteIcon then 
                if isFav then
                    frame.favoriteIcon:SetVertexColor(1, 0.8, 0, 1) 
                else
                    frame.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1) 
                end
            end

            if isFav and shouldColorGolden then
                frame:SetBackdropColor(1,1,0,0.8)
            else
                frame:SetBackdropColor(frame.DEFAULT_R, frame.DEFAULT_G, frame.DEFAULT_B, frame.DEFAULT_A)
            end
        end
    end
end


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
    local allAuctionData = {}

    -- 1. Gather in display order (not hash order)
    for i, frame in ipairs(GDKPT.Core.AuctionOrder or {}) do
        if GDKPT.Core.AuctionFrames[frame] then
            local f = GDKPT.Core.AuctionFrames[frame]
            table.insert(allAuctionData, {id = frame, frame = f, isFavorite = f.isFavorite})
        end
    end

    -- fallback if AuctionOrder not maintained
    if #allAuctionData == 0 then
        for id, frame in pairs(GDKPT.Core.AuctionFrames) do
            table.insert(allAuctionData, {id = id, frame = frame, isFavorite = frame.isFavorite})
        end
        table.sort(allAuctionData, function(a, b) return a.id < b.id end)
    end

    local doSort = false
    local sortFunc

    if GDKPT.Core.isFavoriteFilterActive then
        doSort = true
        sortFunc = function(a, b)
            if a.isFavorite ~= b.isFavorite then
                return a.isFavorite
            end
            return a.id < b.id
        end
    elseif not GDKPT.Core.isFavoriteFilterActive then
        -- Reset sorting to default order (by id)
        doSort = true
        sortFunc = function(a, b)
            return a.id < b.id
        end
    end

    -- Only sort when explicitly requested
    if doSort then
        table.sort(allAuctionData, sortFunc)
    end

    -- 3. Layout
    local visibleCount = 0
    local yPositionOffset = -5
    local rowHeight = 60

    for _, data in ipairs(allAuctionData) do
        local frame = data.frame
        local shouldShow = not GDKPT.Core.isFavoriteFilterActive or data.isFavorite

        if shouldShow then
            local yPosition = yPositionOffset - (visibleCount * rowHeight)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", GDKPT.UI.AuctionContentFrame, "TOPLEFT", 5, yPosition)
            frame:Show()
            visibleCount = visibleCount + 1
        else
            frame:Hide()
        end
    end

    GDKPT.UI.AuctionContentFrame:SetHeight(math.max(100, visibleCount * rowHeight + 10))
end


--[[




function GDKPT.AuctionFavorites.FilterByFavorites()
    local allAuctionData = {}
    
    -- 1. Gather all auction data with favorite status (maintains original, raw iteration order)
    for id, frame in pairs(GDKPT.Core.AuctionFrames) do
        -- Store the original numerical ID and favorite status
        table.insert(allAuctionData, {id = id, frame = frame, isFavorite = frame.isFavorite})
    end

    -- 2. Determine and apply the sort order
    local isAlwaysOnTopEnabled = GDKPT.Core.Settings.Fav_AlwaysOnTop == 1
    local doSort = false
    local sortFunc
    
    if GDKPT.Core.isFavoriteFilterActive and isAlwaysOnTopEnabled then
        -- Case 1: Filter ON, AlwaysOnTop ON -> Custom Favorite Sort
        doSort = true
        sortFunc = function(a, b)
            -- Favorites on top, then sort by original ID
            if a.isFavorite ~= b.isFavorite then
                return a.isFavorite
            end
            return a.id < b.id
        end
    elseif not GDKPT.Core.isFavoriteFilterActive then
        -- Case 2: Filter OFF -> Default Sort (by original ID)
        doSort = true
        sortFunc = function(a, b)
            return a.id < b.id
        end
    end
    -- Case 3: Filter ON, AlwaysOnTop OFF -> NO SORT is applied.
    -- The list remains in the raw order it was collected in, and non-favorites are simply hidden.
    
    if doSort then
        table.sort(allAuctionData, sortFunc)
    end
    
    -- 3. Position and show/hide the auction rows
    local visibleCount = 0
    local yPositionOffset = -5
    local rowHeight = 60 -- Assuming this is the height of an auction row

    for i, data in ipairs(allAuctionData) do
        local frame = data.frame
        
        -- Determine visibility based on filter status
        local shouldShow = true 

        if GDKPT.Core.isFavoriteFilterActive then
            -- When filter is active: Only show if it's a favorite
            shouldShow = data.isFavorite
        end
        
        if shouldShow then
            -- Position only visible frames
            local yPosition = yPositionOffset - (visibleCount * rowHeight)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", GDKPT.UI.AuctionContentFrame, "TOPLEFT", 5, yPosition)
            frame:Show()
            visibleCount = visibleCount + 1
        else
            -- Hide filtered/non-favorite frames
            frame:Hide()
        end
    end

    -- 4. Update the ScrollContent height based on visible items
    GDKPT.UI.AuctionContentFrame:SetHeight(math.max(100, visibleCount * rowHeight + 10))
end

]]



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

local function CreateFavoriteEntry(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(FAV_ROW_HEIGHT)
    frame:SetWidth(parent:GetWidth())
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    frame.bg = bg

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(FAV_ROW_HEIGHT - 4, FAV_ROW_HEIGHT - 4) 
    icon:SetPoint("LEFT", 2, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) 
    frame.icon = icon

    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetPoint("RIGHT", -155, 0) 
    nameText:SetJustifyH("LEFT")
    frame.nameText = nameText
    
    -- Max Bid EditBox
    local eb = CreateFrame("EditBox", nil, frame, "BackdropTemplate")   
    eb:SetSize(80, 20)
    eb:SetPoint("RIGHT", -30, 0) 
    eb:SetNumeric(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontNormalSmall")
    eb:SetTextInsets(5, 5, 0, 0)
    eb.label = eb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    eb.label:SetText("Max Auto Bid:")
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


    -- Helper function to save the max bid value
    local function SaveMaxBidValue(eb, itemID, newValue)
        if GDKPT.Core.PlayerFavorites[itemID] then
            GDKPT.Core.PlayerFavorites[itemID].maxBid = newValue
            eb:SetText(newValue > 0 and tostring(newValue) or "")
            
            -- Print a confirmation message to chat
            local itemLink = GDKPT.Core.PlayerFavorites[itemID].link
            print(("|cff99ff99[GDKPT]|r Max Bid for %s set to |cffFFC125%d Gold|r."):format(itemLink, newValue))
        end
    end


    eb:SetScript("OnEditFocusGained", function(self)
        self.previousText = self:GetText()
    end)







    eb:SetScript("OnEnterPressed", function(self)
        self:ClearFocus() 
    end)
    eb:SetScript("OnEscapePressed", function(self)
        local data = GDKPT.Core.PlayerFavorites[frame.itemID]
        if data then
            self:SetText(data.maxBid > 0 and tostring(data.maxBid) or "")
        end
        self:ClearFocus()
    end)

    eb:SetScript("OnEditFocusLost", function(self)
        local newValue = tonumber(self:GetText()) or 0
        local itemID = frame.itemID
        local itemLink = GDKPT.Core.PlayerFavorites[itemID].link
        
        if newValue < 0 then newValue = 0 end
        
        -- Get the current saved value to see if the user actually changed anything
        local currentSavedValue = GDKPT.Core.PlayerFavorites[itemID].maxBid
        
        if newValue == currentSavedValue then
            -- Value hasn't changed, just update the display text if needed and exit
            self:SetText(newValue > 0 and tostring(newValue) or "") 
            return
        end
        
        
        if GDKPT.Core.Settings.ConfirmAutoBid == 1 and newValue > 0 then
            local confFrame = GDKPT.AuctionRow.ConfirmationFrame
            
            confFrame.Text:SetText(
                string.format("|cffffffffAre you sure you want to set your Max Auto Bid to |cffFFC125%d Gold|cffffffff for %s?|r",
                newValue, itemLink)
            )
            
            local _self = self
            local _itemID = itemID
            local _newValue = newValue
            local _previousText = self.previousText or ""
            
            confFrame.confirmAction = function()
                -- Confirmed: Save the new value
                SaveMaxBidValue(_self, _itemID, _newValue)
            end
            
            confFrame.cancelAction = function()
                -- Canceled: Restore the old value in the EditBox
                _self:SetText(_previousText)
            end
            
            confFrame:Show()
            
            -- Since the action is deferred to the confirmation frame, we return
            return
        end
       
        
        -- If confirmation is disabled or newValue is 0 (clearing the bid), save immediately
        SaveMaxBidValue(self, itemID, newValue)

    end)




    --[[

    eb:SetScript("OnEditFocusLost", function(self)
        local value = tonumber(self:GetText()) or 0
        if value < 0 then value = 0 end
        
        if GDKPT.Core.PlayerFavorites[frame.itemID] then
            GDKPT.Core.PlayerFavorites[frame.itemID].maxBid = value
            self:SetText(value > 0 and tostring(value) or "") 
        end
    end)

    ]]







    frame.maxBidEditBox = eb

    local removeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    removeButton:SetSize(20, 20) 
    removeButton:SetPoint("RIGHT", -5, 0)
    removeButton:SetScript("OnClick", function()
        if frame.itemLink then
            GDKPT.AuctionFavorites.ToggleFavorite(frame.itemLink) 
        end
    end)
    
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

    local ScrollFrame = GDKPT.UI.FavoriteScrollFrame
    local ScrollContent = GDKPT.UI.FavoriteScrollContent
    if not ScrollFrame or not ScrollContent then return end
    

    for _, entry in ipairs(favoriteFramePool) do
        entry:Hide()
    end

    local totalHeight = 0
    local sortedFavorites = {}
    

    for itemID, data in pairs(GDKPT.Core.PlayerFavorites) do

        local name = GetItemInfo(data.link)
        table.insert(sortedFavorites, {id = itemID, link = data.link, maxBid = data.maxBid, name = name or "Unknown"})
    end
    

    table.sort(sortedFavorites, function(a, b) return a.name < b.name end)
    
    for i, data in ipairs(sortedFavorites) do
        local entry = favoriteFramePool[i]
        if not entry then
            entry = CreateFavoriteEntry(ScrollContent)
            table.insert(favoriteFramePool, entry)
        end

 
        entry.itemLink = data.link
        entry.itemID = data.id
        
        local itemName, itemLinkColored, _, _, _, _, _, _, _, texture = GetItemInfo(data.link)
        
        entry.nameText:SetText(itemLinkColored or itemName or "Unknown Item") 
        entry.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        entry.maxBidEditBox:SetText(data.maxBid > 0 and tostring(data.maxBid) or "")
        

        if i % 2 == 0 then
            entry.bg:SetVertexColor(0.15, 0.15, 0.15, 0.5)
        else
            entry.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
        end
        

        local yPosition = -2 - ((i - 1) * FAV_ROW_HEIGHT)
        entry:ClearAllPoints()
        entry:SetPoint("TOPLEFT", ScrollContent, "TOPLEFT", 2, yPosition)
        entry:SetWidth(ScrollContent:GetWidth() - 4)
        entry:Show()
        
        totalHeight = totalHeight + FAV_ROW_HEIGHT
    end

    local contentHeight = math.max(ScrollFrame:GetHeight() - 10, totalHeight + 10)
    ScrollContent:SetHeight(contentHeight)
end


-------------------------------------------------------------------
-- Auto-Bidding and Win-Handling Logic
-- These are stubs for you to call from your other addon files.
-------------------------------------------------------------------




function GDKPT.AuctionFavorites.CheckAutoBid(auctionID, itemID, minNextBid, highBidderName, itemLink)

    local myName = UnitName("player")
    if highBidderName == myName then
        return 
    end

    local favoriteData = GDKPT.AuctionFavorites.GetFavoriteData(itemID)
    
    if not favoriteData or favoriteData.maxBid <= 0 then
        return
    end

    local myMax = favoriteData.maxBid

    if myMax < minNextBid then
        return
    end

    local bidAmount = minNextBid
    local minIncrement = GDKPT.Core.leaderSettings.minIncrement or 1

    if myMax < (minNextBid + minIncrement) then
        bidAmount = myMax
    end
    
    if bidAmount > myMax then
        bidAmount = myMax
    end

    if GDKPT.Core.Settings.LimitBidsToGold == 1 then
        local playerGoldInCopper = GetMoney()
        local bidInCopper = bidAmount * 10000 -- bidAmount is in Gold
        
        if bidInCopper > playerGoldInCopper then
            print(("|cffff8800[GDKPT]|r Auto-bid failed for %s. Not enough gold to bid %dg."):format(itemLink, bidAmount))
            return -- Stop the bid
        end
    end


    print(("|cff99ff99[GDKPT]|r Auto-bidding %dg on %s..."):format(bidAmount, favoriteData.link))

    local msg = string.format("BID:%d:%d", auctionID, bidAmount)
    SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")
    SendChatMessage(string.format("[GDKPT] [Autobid] I'm bidding %d gold on %s !", bidAmount, itemLink), "RAID")
end


function GDKPT.AuctionFavorites.HandleAuctionWon(itemID, winnerName)
    local myName = UnitName("player")
    
    if winnerName == myName then
        local favoriteData = GDKPT.AuctionFavorites.GetFavoriteData(itemID)
        if favoriteData then
            print(("|cff99ff99[GDKPT]|r You won %s! Removing from favorites."):format(favoriteData.link))
            GDKPT.AuctionFavorites.ToggleFavorite(favoriteData.link)
        end
    end
end





-------------------------------------------------------------------
-- Function alerts players when a favorited item has dropped, with 
-- queuing mechanic in case of multiple dropping at once
-------------------------------------------------------------------


local favoriteLootQueue = {} 
local favoriteLootTimer   
local isDisplayingLoot = false 



local function ProcessNextQueuedLoot()
    if #favoriteLootQueue == 0 then
        isDisplayingLoot = false
        return 
    end

    isDisplayingLoot = true
    
    local itemLink = table.remove(favoriteLootQueue, 1)
    local _, linkColored, _, _, _, _, _, _, _, texture = GetItemInfo(itemLink)
    local alertFrame = GDKPT.UI.FavoriteAlertFrame

    if alertFrame then
        
        alertFrame.ItemIcon:SetTexture(texture)
        alertFrame.ItemName:SetText(linkColored)
        
        alertFrame:Show()
        
        if GDKPT.Core.Settings.Fav_PopupAlert == 1 then
            UIFrameFlash(alertFrame, 1, 0.5, 0.5, 0) 
        end

        if GDKPT.Core.Settings.Fav_AudioAlert == 1 then
            PlaySoundFile("Interface\\AddOns\\GDKPT\\Sounds\\FavoriteLoot.ogg","Master")
        end

        favoriteLootTimer = C_Timer.NewTimer(5, function()
            alertFrame:Hide()
            UIFrameFlash(alertFrame, 0) 
            favoriteLootTimer = nil
            
            ProcessNextQueuedLoot() 
        end)
    end
    
    if GDKPT.Core.Settings.Fav_ChatAlert == 1 then
        print(("|cff00ccff[GDKPT - ALERT!]|r Your favorite item, %s, has just been master-looted! (Queued: %d)")
            :format(linkColored or itemLink, #favoriteLootQueue)
        )
    end
end


function GDKPT.AuctionFavorites.CheckLootedItemForFavorite(itemLink)
    if not itemLink then return end

    local itemID = tonumber(itemLink:match("item:(%d+):"))
    if not itemID then return end

    local favoriteData = GDKPT.AuctionFavorites.GetFavoriteData(itemID)

    if favoriteData then
        table.insert(favoriteLootQueue, itemLink)

        if not isDisplayingLoot then
            ProcessNextQueuedLoot()
        end
    end
end



