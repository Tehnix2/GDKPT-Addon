GDKPT.AuctionStart = {}

GDKPT.AuctionStart.PendingAuctions = GDKPT.AuctionStart.PendingAuctions or {}

-------------------------------------------------------------------
-- Sets placeholder visuals while item info is not cached yet
-------------------------------------------------------------------
local function SetPlaceholderVisuals(row, startBid)
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    row.itemLinkText:SetText("|cffaaaaaa[Loading...]|r")
    row.itemLinkText:SetTextColor(0.7, 0.7, 0.7)

    row.bidText:SetText(string.format("Starting Bid: |cffffd700%d|r", startBid))
    row.topBidderText:SetText("No bids yet")
    row.topBidderText:SetTextColor(1, 1, 1)

    row.bidBox:SetText("")
    row.bidButton:SetText(startBid .. " G")
end


-------------------------------------------------------------------
-- Forces the server to send item info
-- (Used when item is not cached locally)
-------------------------------------------------------------------
local function ForceItemInfoRequest(itemID, itemLink)
    local link = itemLink or ("item:" .. itemID)

    if not link:find("item:") then
        link = "item:" .. tostring(itemID)
    end

    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:SetHyperlink(link)
    GameTooltip:Hide()
end


-------------------------------------------------------------------
-- Attempts to fetch item info using ID or link
-------------------------------------------------------------------

local function FetchItemInfo(row)
    if row.itemID then
        local info = { GetItemInfo(row.itemID) }
        if info[1] then return unpack(info) end
    end

    if row.itemLink then
        return GetItemInfo(row.itemLink)
    end

    return nil
end


-------------------------------------------------------------------
-- Applies core item appearance to the row
-------------------------------------------------------------------

local function ApplyItemVisuals(row, itemLink, quality, icon)
    local r, g, b = GetItemQualityColor(quality)

    row.icon:SetTexture(icon)
    row.itemLinkText:SetText(itemLink)
    row.itemLinkText:SetTextColor(r, g, b)
end


-------------------------------------------------------------------
-- Shows or hides the stack count
-------------------------------------------------------------------

local function UpdateStackVisual(row)
    if row.stackCount and row.stackCount > 1 then
        row.stackText:SetText(row.stackCount)
        row.itemLinkText:SetText(row.itemLink .. " |cffaaaaaa[x" .. row.stackCount .. "]|r")
        row.stackText:Show()
    else
        row.stackText:Hide()
    end
end

-------------------------------------------------------------------
-- Sets default bid text fields
-------------------------------------------------------------------
local function UpdateInitialBidState(row)
    row.bidText:SetText(string.format("Starting Bid: |cffffd700%d|r", row.startBid))
    row.topBidderText:SetText("No bids yet")
    row.topBidderText:SetTextColor(1, 1, 1)

    row.bidBox:SetText("")
    row.bidButton:SetText(row.startBid .. " G")
end


-------------------------------------------------------------------
-- Finalizes the auction row when item info becomes available
-------------------------------------------------------------------


local function FinalizeInitialAuctionRow(auctionId, row)

    if not row then
        print(string.format(GDKPT.Core.errorprint .. "There is no auction row found for auction %d.", auctionId))
        return
    end

    -- Fetch item info to attempt to cache the item one more time
    local name, itemLink, quality, _, _, _, _, _, _, icon = FetchItemInfo(row)

    -- Assign basic row data
    row.itemName = name
    row.itemQuality = quality

    -- Update visuals: colour, stack count, initial state

    ApplyItemVisuals(row, itemLink, quality, icon)
    UpdateStackVisual(row)
    UpdateInitialBidState(row)

    -- Apply current layout mode to the row
    if GDKPT.ToggleLayout.SetRowLayout and GDKPT.ToggleLayout.currentLayout then
        GDKPT.ToggleLayout.SetRowLayout(row, GDKPT.ToggleLayout.currentLayout)
    end
    
    -- Show row now that everything is set and loaded
    row:Show()

    -- Highlight Favorite auctions
    GDKPT.Favorites.UpdateAuctionRowVisuals(row.itemID)

end


-------------------------------------------------------------------
-- Registers this auction as "pending" while waiting for cache
-------------------------------------------------------------------

local function RegisterPendingAuction(itemID, auctionId, row)
    local key = tostring(itemID)

    GDKPT.AuctionStart.PendingAuctions[key] = GDKPT.AuctionStart.PendingAuctions[key] or {}
    GDKPT.AuctionStart.PendingAuctions[key][auctionId] = row
end



-------------------------------------------------------------------
-- Removes an auction from the pending table
-------------------------------------------------------------------
local function ClearPendingAuction(itemID, auctionId)
    local key = tostring(itemID)
    local list = GDKPT.AuctionStart.PendingAuctions[key]

    if not list then return end

    list[auctionId] = nil
    if not next(list) then
        GDKPT.AuctionStart.PendingAuctions[key] = nil
    end
end


---------------------------------------------------------------
-- Retry logic for fetching item info (exponential backoff)
---------------------------------------------------------------
local function StartItemCacheRetry(row, auctionId, itemID, itemLink)
    local retries     = 0
    local maxRetries  = 8
    local retryDelay  = 0.5

    local function Retry()
        local checkLink = itemLink or ("item:" .. itemID)
        local cachedName = GetItemInfo(checkLink)

        if cachedName then
            FinalizeInitialAuctionRow(auctionId, row)
            ClearPendingAuction(itemID, auctionId)

            if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
                GDKPT.AuctionLayout.RepositionAllAuctions()
            end
            return
        end

        retries = retries + 1

        if retries <= maxRetries then
            ForceItemInfoRequest(itemID, itemLink)

            -- exponential backoff: 0.5 -> 1 -> 2 -> 4 (max)
            local nextDelay = math.min(retryDelay * (2 ^ (retries - 1)), 4)
            C_Timer.After(nextDelay, Retry)
        else
            PrintAuctionError(auctionId, "Failed to load item info for auction %d after max retries.")
            row.itemLinkText:SetText("|cffff0000[Failed to load]|r")
            row.itemLinkText:SetTextColor(1, 0, 0)
        end
    end

    C_Timer.After(retryDelay, Retry)
end

-------------------------------------------------------------------
-- Initializes a fresh auction row with base parameters
-------------------------------------------------------------------

local function InitializeAuctionRow(row, auctionId, itemID, itemLink, startBid, minIncrement, duration, stackCount)
    local currentTime = GetTime()
    local endTime     = currentTime + duration

    row.auctionId  = auctionId
    row.itemID     = itemID
    row.itemLink   = itemLink
    row.startBid   = startBid
    row.minIncrement = minIncrement
    row.endTime    = endTime
    row.duration   = duration
    row.stackCount = stackCount
    row.clientSideEnded = false

    row.auctionNumber:SetText(auctionId)

    row.timeAccumulator = 0

    local isCompact = GDKPT.ToggleLayout and GDKPT.ToggleLayout.currentLayout == "compact"

    if isCompact then
        row.timerText:SetText("|cffaaaaaa--:--|r")
    else
        row.timerText:SetText("Time Left: |cffaaaaaa--:--|r")
    end

    
    row:SetScript("OnUpdate", GDKPT.AuctionRow.UpdateRowTimer)

    row.currentBid = 0
    row.topBidder = ""
    row.bidButton.auctionId = auctionId

    -- Force re-enable controls for active auctions (fixes stuck buttons after Info Button Sync)
    if duration > 0 then
        if row.bidButton then
            row.bidButton:Enable()
            -- Reset text immediately so it doesn't say "Syncing..."
            row.bidButton:SetText(startBid .. " G") 
        end
        
        if row.bidBox then
            row.bidBox:Enable()
            row.bidBox:EnableMouse(true)
            row.bidBox:SetBackdropBorderColor(0.8, 0.6, 0, 1) -- Reset gold border
        end
    else
        -- Disable bidding if it's a completed (synced) auction
        GDKPT.Utils.DisableAllBidding()
    end
end


-------------------------------------------------------------------
-- Function to create AuctionRows based on the message from Leader
-------------------------------------------------------------------

function GDKPT.AuctionStart.HandleAuctionStart(auctionId, itemID, startBid, minIncrement, duration, itemLink, stackCount)
    
    -- if stackCount is nil, then set it to 1 as default
    stackCount = stackCount or 1    

    -- Create or reuse row 
    local row = GDKPT.Core.AuctionFrames[auctionId] or GDKPT.AuctionRow.CreateAuctionRow()
    GDKPT.Core.AuctionFrames[auctionId] = row

    -- Initialize a fresh auction row with base parameters
    InitializeAuctionRow(row, auctionId, itemID, itemLink, startBid, minIncrement, duration, stackCount)

    local name = GetItemInfo(itemLink)

    if name then
        -- Item is already cached -> finalize immediately
        FinalizeInitialAuctionRow(auctionId, row)
    else
        -- Not cached -> Register as Pending -> show placeholder -> begin retry logic
        RegisterPendingAuction(itemID, auctionId, row)
        SetPlaceholderVisuals(row, startBid)
        row:Show()

        ForceItemInfoRequest(itemID, itemLink)
        StartItemCacheRetry(row, auctionId, itemID, itemLink)
    end

    -- Keep history of ALL auctioned items, regardless of who wins them
    table.insert(GDKPT.Core.AuctionedItems, {
        itemID = itemID,
        link = itemLink,
        time = time(),
        winner = nil,        -- Will be set when auction ends
        winningBid = nil,    -- Will be set when auction ends
    })

    -- Update LootTracker if its currently visible, label items as AUCTIONED
    if GDKPT.Loot.LootFrame and GDKPT.Loot.LootFrame:IsVisible() then
        GDKPT.Loot.UpdateLootDisplay()
    end
    -- Reposition rows taking the layout settings into account
    if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
        GDKPT.AuctionLayout.RepositionAllAuctions()
    end

-- Handle Pre-Bid features
    if GDKPT.Loot and GDKPT.Loot.PreBids and GDKPT.Loot.PreBids[itemID] then
        local preBid = GDKPT.Loot.PreBids[itemID]
        
        -- Play audio alert if enabled
        if GDKPT.Core.Settings.PreBid_AudioAlert == 1 then
            PlaySoundFile("Interface\\AddOns\\GDKPT\\Sounds\\PreBidAlert.wav", "Master")
        end
        
        -- Auto-fill the bid box after short delay
        C_Timer.After(0.5, function()
            local row = GDKPT.Core.AuctionFrames[auctionId]
            if row and row.bidBox then
                row.bidBox:SetText(tostring(preBid))
                row.bidBox:SetBackdropBorderColor(1, 0.84, 0, 1) -- Gold border
                print(GDKPT.Core.print .. "Pre-bid of " .. preBid .. "g loaded for " .. itemLink)
            end
        end)
        
        -- Auto-send pre-bid if enabled (with random delay to prevent spam)
        if GDKPT.Core.Settings.PreBid_AutoSend == 1 then
            -- Random delay between 1.0 and 3.0 seconds
            -- This staggers bids from multiple players to prevent simultaneous sends
            local randomDelay = 1.0 + (math.random() * 2.0)
            
            C_Timer.After(randomDelay, function()
                local row = GDKPT.Core.AuctionFrames[auctionId]
                if not row then return end
                
                -- Safety checks before auto-sending
                -- 1. Make sure auction hasn't ended
                if row.clientSideEnded then return end
                
                -- 2. Make sure we have time remaining
                local timeRemaining = (row.endTime or 0) - GetTime()
                if timeRemaining <= 0 then return end
                
                -- 3. Check if we're already the top bidder (prevent self-outbid)
                if row.topBidder == UnitName("player") then
                    print(GDKPT.Core.print .. "Pre-bid skipped: You're already the top bidder on " .. itemLink)
                    return
                end
                
                -- 4. Check if current bid already exceeds our pre-bid
                local currentBid = row.currentBid or 0
                local nextMinBid = currentBid + (row.minIncrement or 0)
                
                if preBid < nextMinBid then
                    print(GDKPT.Core.print .. "Pre-bid of " .. preBid .. "g is below minimum (" .. nextMinBid .. "g) for " .. itemLink)
                    return
                end
                
                -- 5. Check gold limit if enabled
                if GDKPT.Core.Settings.LimitBidsToGold == 1 then
                    local playerGold = math.floor(GetMoney() / 10000)
                    local committedGold = GDKPT.Utils.GetCommittedGold and GDKPT.Utils.GetCommittedGold() or 0
                    local availableGold = playerGold - committedGold
                    
                    if preBid > availableGold then
                        print(GDKPT.Core.errorprint .. "Pre-bid auto-send failed: Not enough gold for " .. itemLink)
                        return
                    end
                end
                
                -- Alternative: Simulate pressing enter on the bid box
                if row.bidBox then
                    row.bidBox:SetText(tostring(preBid))
                    -- Trigger the OnEnterPressed handler
                    local script = row.bidBox:GetScript("OnEnterPressed")
                    if script then
                        script(row.bidBox)
                        print(GDKPT.Core.print .. "Auto-sent pre-bid of " .. preBid .. "g for " .. itemLink)
                    end
                end
            end)
        end
    end
end




-------------------------------------------------------------------
-- Bulk Auction handling function
-------------------------------------------------------------------



function GDKPT.AuctionStart.HandleBulkAuctionStart(auctionId, startBid, minIncrement, duration, itemCount, itemListStr)
    -- Parse item list - now only itemID:stackCount
    local bulkItems = {}
    for itemData in string.gmatch(itemListStr, "([^,]+)") do
        local itemID, stackCount = itemData:match("([^:]+):([^:]+)")
        if itemID and stackCount then
            local itemIDNum = tonumber(itemID)
            local stackCountNum = tonumber(stackCount)
            
            -- Generate item link from itemID
            local itemName, itemLink = GetItemInfo(itemIDNum)
            if not itemLink then
                -- If not cached, create basic link - it will update when cached
                itemLink = string.format("|cffffffff|Hitem:%d|h[Item:%d]|h|r", itemIDNum, itemIDNum)
            end
            
            table.insert(bulkItems, {
                itemID = itemIDNum,
                stackCount = stackCountNum,
                itemLink = itemLink
            })
        end
    end
    
    -- Create auction row
    local row = GDKPT.Core.AuctionFrames[auctionId] or GDKPT.AuctionRow.CreateAuctionRow()
    GDKPT.Core.AuctionFrames[auctionId] = row
    
    -- Initialize with bulk auction data
    local currentTime = GetTime()
    local endTime = currentTime + duration
    
    row.auctionId = auctionId
    row.itemID = 6948
    row.itemLink = "|cffffd700[Bulk Auction]|r"
    row.startBid = startBid
    row.minIncrement = minIncrement
    row.endTime = endTime
    row.duration = duration
    row.stackCount = 1
    row.clientSideEnded = false
    row.currentBid = 0
    row.topBidder = ""
    row.bidButton.auctionId = auctionId
    
    row.auctionNumber:SetText(auctionId)
    row.timeAccumulator = 0
    
    -- Set timer text based on layout
    local isCompact = GDKPT.ToggleLayout and GDKPT.ToggleLayout.currentLayout == "compact"
    if isCompact then
        row.timerText:SetText("|cffaaaaaa--:--|r")
    else
        row.timerText:SetText("Time Left: |cffaaaaaa--:--|r")
    end
    
    row:SetScript("OnUpdate", GDKPT.AuctionRow.UpdateRowTimer)
    
    -- Set bulk visuals BEFORE applying layout
    row:SetBulkAuctionVisuals(bulkItems)
    
    -- Update bid display
    row.bidText:SetText(string.format("Starting Bid: |cffffd700%d|r", startBid))
    row.topBidderText:SetText("No bids yet")
    row.topBidderText:SetTextColor(1, 1, 1)
    row.bidBox:SetText("")
    row.bidButton:SetText(startBid .. " G")
    
    -- Apply current layout mode to the row
    if GDKPT.ToggleLayout and GDKPT.ToggleLayout.SetRowLayout and GDKPT.ToggleLayout.currentLayout then
        GDKPT.ToggleLayout.SetRowLayout(row, GDKPT.ToggleLayout.currentLayout)
    end
    
    -- Show and position
    row:Show()
    
    if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
        GDKPT.AuctionLayout.RepositionAllAuctions()
    end
end