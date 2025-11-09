GDKPT.AuctionStart = {}



-------------------------------------------------------------------
-- Function that gets called when the raidleader uses
-- /gdkpleader auction [itemlink] through the eventFrame trigger.

-- If that item is already cached by the member, then proceed to 
-- update the row visuals in the FinalizeInitialAuctionRow function.

-- If that item is NOT cached, then we use the hidden AuctionReceiverFrame
-- with the GET_ITEM_INFO_RECEIVED event to cache it 
-------------------------------------------------------------------


        
local AuctionReceiverFrame = CreateFrame("Frame", "GDKPT_AuctionReceiverFrame")
AuctionReceiverFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")

PendingAuctions = PendingAuctions or {}





local function FinalizeInitialAuctionRow(auctionId, row)
    if not row then
        print(string.format("|cffff0000[GDKPT]|r Error: No row found for auction %d", auctionId))
        return
    end

    local name, itemLink, quality, iLevel, minLevel, itemType, itemSubType, stackCount, equipSlot, icon

    if row.itemID then
        name, itemLink, quality, iLevel, minLevel, itemType, itemSubType, stackCount, equipSlot, icon =
            GetItemInfo(row.itemID)
    end
    
    if not name and row.itemLink then
        name, itemLink, quality, iLevel, minLevel, itemType, itemSubType, stackCount, equipSlot, icon =
            GetItemInfo(row.itemLink)
    end

    if not name then
        print(string.format("|cffff0000[GDKPT]|r Error: Failed to get item info for auction %d after cache event.", auctionId))
        return
    end

    row.itemName = name
    row.itemQuality = quality

    local r, g, b = GetItemQualityColor(quality)
    row.icon:SetTexture(icon)

    row.itemLinkText:SetText(itemLink)
    row.itemLinkText:SetTextColor(r, g, b)

    if row.stackCount and row.stackCount > 1 then
        row.stackText:SetText(row.stackCount)
        row.stackText:Show()
    else
        row.stackText:Hide()
    end

    row.bidText:SetText(string.format("Starting Bid: |cffffd700%d|r", row.startBid))
    row.topBidderText:SetText("No bids yet")
    row.topBidderText:SetTextColor(1, 1, 1)

    local minNextBid = row.startBid
    row.bidBox:SetText("")
    row.bidButton:SetText(minNextBid .. " G")

    row:Show()
    --GDKPT.Favorites.FilterByFavorites()

    if GDKPT.Favorites and GDKPT.Favorites.UpdateAuctionRowVisuals then
        GDKPT.Favorites.UpdateAuctionRowVisuals(row.itemID)
    end

end






function GDKPT.AuctionStart.HandleAuctionStart(auctionId, itemID, startBid, minIncrement, duration, itemLink, stackCount)
    
    stackCount = stackCount or 1    

    local row = GDKPT.Core.AuctionFrames[auctionId] or GDKPT.AuctionRow.CreateAuctionRow() 
    GDKPT.Core.AuctionFrames[auctionId] = row

    local currentTime = GetTime()
    local endTime = currentTime + duration

    row.auctionId = auctionId
    row.itemID = itemID
    row.itemLink = itemLink
    row.startBid = startBid
    row.minIncrement = minIncrement
    row.endTime = endTime 
    row.duration = duration
    row.originalDuration = duration  -- Also store as originalDuration for clarity
    row.stackCount = stackCount
    row.clientSideEnded = false

    if row.duration == 0 then
        GDKPT.Utils.DisableAllBidding()
    end


    GDKPT.Favorites.UpdateAuctionRowVisuals(row.itemID)
    row.auctionNumber:SetText(auctionId)

    -- Reset the countdown timer for new auctions
    row.timeAccumulator = 0
    row.timerText:SetText("Time Left: |cffaaaaaa--:--|r")
    row:SetScript("OnUpdate", GDKPT.AuctionRow.UpdateRowTimer)

    row.currentBid = 0
    row.topBidder = ""
    row.bidButton.auctionId = auctionId
    
    -- Disable bidding if settings not synced yet
    if not GDKPT.Core.leaderSettings.isSet then
        if row.bidButton then
            row.bidButton:Disable()
            row.bidButton:SetText("Awaiting Sync...")
        end
        if row.bidBox then
            row.bidBox:Disable()
        end
    end

    -- Force request the item info from server
    local function ForceItemRequest()
        local link = itemLink or ("item:" .. itemID)
        if not link:find("item:") then
            link = "item:" .. tostring(itemID)
        end
        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Hide()
    end

    -- Try to get item info immediately
    local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(itemLink)

    if name then
        FinalizeInitialAuctionRow(auctionId, row)
        if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
            GDKPT.AuctionLayout.RepositionAllAuctions()
        end
    else
        -- Item not cached - setup retry logic
        local key = tostring(itemID)
        PendingAuctions[key] = PendingAuctions[key] or {}
        PendingAuctions[key][auctionId] = row

        row:Show()

        if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
            GDKPT.AuctionLayout.RepositionAllAuctions()
        end
        
        -- Set placeholder visuals
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        row.itemLinkText:SetText("|cffaaaaaa[Loading...]|r")
        row.itemLinkText:SetTextColor(0.7, 0.7, 0.7)
        row.bidText:SetText(string.format("Starting Bid: |cffffd700%d|r", startBid))
        row.topBidderText:SetText("No bids yet")
        row.topBidderText:SetTextColor(1, 1, 1)
        
        local minNextBid = startBid
        row.bidBox:SetText("")
        row.bidButton:SetText(minNextBid .. " G")

        if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
            GDKPT.AuctionLayout.RepositionAllAuctions()
        end

        ForceItemRequest()

        local retries = 0
        local maxRetries = 8
        local retryDelay = 0.5

        local function RetryItemCache()
            local checkLink = itemLink or ("item:" .. itemID)
            local cachedName = GetItemInfo(checkLink)

            if cachedName then
                FinalizeInitialAuctionRow(auctionId, row)
                
                if PendingAuctions[key] then
                    PendingAuctions[key][auctionId] = nil
                    if not next(PendingAuctions[key]) then
                        PendingAuctions[key] = nil
                    end
                end
              

                if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
                    GDKPT.AuctionLayout.RepositionAllAuctions()
                end

                return
            end

            retries = retries + 1

            if retries <= maxRetries then
                ForceItemRequest()
                local nextDelay = math.min(retryDelay * math.pow(2, retries - 1), 4)
                C_Timer.After(nextDelay, RetryItemCache)
            else
                print(string.format("|cffff0000[GDKPT]|r Failed to load item info for auction %d after %d attempts.", auctionId, maxRetries))
                row.itemLinkText:SetText("|cffff0000[Failed to load]|r")
                row.itemLinkText:SetTextColor(1, 0, 0)
            end
        end

        C_Timer.After(retryDelay, RetryItemCache)
    end
end
