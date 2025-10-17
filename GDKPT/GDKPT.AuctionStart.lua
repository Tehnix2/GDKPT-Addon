GDKPT.AuctionStart = {}

-------------------------------------------------------------------
-- Function that updates the layout of the auction content frame
-- based on the amount of active auctions at a time
-------------------------------------------------------------------

local function UpdateAuctionLayout()
    local count = 0
    for id, frame in pairs(GDKPT.Core.AuctionFrames) do
        if frame:IsShown() then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", GDKPT.UI.AuctionContentFrame, "TOPLEFT", 5, -5 - (count * GDKPT.Core.ROW_HEIGHT))
            count = count + 1
        end
    end
    -- Adjust the content frame height to fit all rows
    GDKPT.UI.AuctionContentFrame:SetHeight(math.max(100, count * GDKPT.Core.ROW_HEIGHT))
end




-------------------------------------------------------------------
-- Function that gets called when the raidleader uses
-- /gdkpleader auction [itemlink] through the eventFrame trigger.

-- If that item is already cached by the member, then proceed to 
-- update the row visuals in the FinalizeInitialAuctionRow function.

-- If that item is NOT cached, then we use the hidden AuctionReceiverFrame
-- with the GET_ITEM_INFO_RECEIVED event to cache it 
-------------------------------------------------------------------


        
-- Hidden frame that handles the GET_ITEM_INFO_RECEIVED event
local AuctionReceiverFrame = CreateFrame("Frame", "GDKPT_AuctionReceiverFrame")

-- If the item is already cached, then finalize the row UI update
local function FinalizeInitialAuctionRow(auctionId, row)
    local name, itemLink, quality, iLevel, minLevel, itemType, itemSubType, stackCount, equipSlot, icon

    -- Attempt GetItemInfo one last time, this should now succeed thanks to the event trigger.

    if row.itemID then
        name, itemLink, quality, iLevel, minLevel, itemType, itemSubType, stackCount, equipSlot, icon =
            GetItemInfo(row.itemID)
    else
        name, itemLink, quality, iLevel, minLevel, itemType, itemSubType, stackCount, equipSlot, icon =
            GetItemInfo(row.itemLink)
    end

    if not name then
        print(string.format("|cffff0000Error: Failed to get item info for auction %d after cache event. |r", auctionId))
        return
    end

    local r, g, b = GetItemQualityColor(quality)

    row.icon:SetTexture(icon)
    row.itemLinkText:SetText(itemLink)
    row.itemLinkText:SetTextColor(r, g, b)

    row.bidText:SetText(string.format("Starting Bid: |cffffd700%d|r", row.startBid))
    row.topBidderText:SetText("No bids yet")
    row.topBidderText:SetTextColor(1, 1, 1)

    local minNextBid = row.startBid

    row.bidBox:SetText("")
    row.bidButton:SetText(minNextBid .. " G")

    row:Show()
    UpdateAuctionLayout()
end

AuctionReceiverFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if event == "GET_ITEM_INFO_RECEIVED" then
            local itemID, success = ...
            local key = tostring(itemID)

            -- Check if any pending auction is waiting for this specific itemID
            if PendingAuctions[key] and success then
                local pendingList = PendingAuctions[key]

                -- Process all auctions waiting for this item
                for auctionId, row in pairs(pendingList) do
                    FinalizeInitialAuctionRow(auctionId, row)
                end

                -- Clear the list for this item
                PendingAuctions[key] = nil
            end
        end
    end
)
AuctionReceiverFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")

function GDKPT.AuctionStart.HandleAuctionStart(auctionId, itemID, startBid, minIncrement, endTime, itemLink)
    -- Check if the leader settings have been synced. If not, do not start auctions
    if not GDKPT.Core.leaderSettings.isSet then
        print(
            "|cffff8800[GDKPT]|r Cannot start auction: Leader settings not yet synced. Use /gdkp show and click the sync button."
        )
        return
    end

    local row = table.remove(GDKPT.Core.AuctionFramePool) or GDKPT.AuctionRow.CreateAuctionRow()
    GDKPT.Core.AuctionFrames[auctionId] = row

    -- Store core auction data on the row

    row.auctionId = auctionId
    row.itemID = itemID
    row.itemLink = itemLink
    row.startBid = startBid
    row.minIncrement = minIncrement
    row.endTime = tonumber(endTime)

    row.auctionNumber:SetText(auctionId)

    -- Reset the countdown timer for new auctions
    row.timeAccumulator = 0
    row.timerText:SetText("Time Left: |cffaaaaaa--:--|r")

    -- Re-enable the OnUpdate script, which was set to nil in HandleAuctionEnd for pooled frames.
    row:SetScript("OnUpdate", GDKPT.AuctionRow.UpdateRowTimer)

    -- At the start of an auction there is no bidder

    row.currentBid = 0
    row.topBidder = ""

    -- Also store the auctionId on the bidButton of that row
    row.bidButton.auctionId = auctionId

    local function ForceItemRequest(source)
        local link = itemLink or ("item:" .. itemID)

        if not link:find("item:") then
            link = "item:" .. tostring(itemID)
        end

        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Hide()
    end

    local retries = 0
    local maxRetries = 5
    local retryDelay = 2.0 -- seconds

    local function RetryItemCache()
        local checkLink = itemLink or ("item:" .. itemID)
        local name, link, quality, _, _, _, _, _, _, icon = GetItemInfo(checkLink)

        if name then
            FinalizeInitialAuctionRow(auctionId, row)
            return
        end

        retries = retries + 1

        if retries <= maxRetries then
            ForceItemRequest("RetryItemCache")

            local frame = CreateFrame("Frame")
            local elapsed = 0
            frame:SetScript(
                "OnUpdate",
                function(self, delta)
                    elapsed = elapsed + delta
                    if elapsed >= retryDelay then
                        self:SetScript("OnUpdate", nil)
                        RetryItemCache()
                    end
                end
            )
        end
    end

    local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(itemLink)

    if name then
        FinalizeInitialAuctionRow(auctionId, row)
    else
        local key = tostring(itemID)
        PendingAuctions[key] = PendingAuctions[key] or {}
        PendingAuctions[key][auctionId] = row

        row:Hide()

        ForceItemRequest("Initial Load")
        RetryItemCache()
    end
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
