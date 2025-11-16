-------------------------------------------------------------------
-- Message Receiving Handlers to react to raidleader addon messages
-------------------------------------------------------------------

GDKPT.EventFrame = {}

-------------------------------------------------------------------
-- 1. Function to check if incoming message is valid
-- (GDKPT addon message and from current RaidLeader)
-------------------------------------------------------------------

local function IsValidAddonMessage(prefix, sender)
    return prefix == GDKPT.Core.addonPrefix and sender == GDKPT.Utils.GetRaidLeaderName()
end


-------------------------------------------------------------------
-- 2. Version Check to print current GDKPT Version in raidchat
-------------------------------------------------------------------

local function HandleVersionCheck()
    if IsInRaid() then
        SendChatMessage(string.format("[GDKPT] Version %.2f", GDKPT.Core.version), "RAID")
    end
end



-------------------------------------------------------------------
-- 3. Receive auction parameters re-enable bidding if auction did
-- not end yet
-------------------------------------------------------------------


local function HandleSettings(data, sender)
    local duration, extraTime, startBid, minIncrement, splitCount =
        data:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
    if not (duration and extraTime and startBid and minIncrement and splitCount) then return end

    GDKPT.Core.leaderSettings.duration = tonumber(duration)
    GDKPT.Core.leaderSettings.extraTime = tonumber(extraTime)
    GDKPT.Core.leaderSettings.startBid = tonumber(startBid)
    GDKPT.Core.leaderSettings.minIncrement = tonumber(minIncrement)
    GDKPT.Core.leaderSettings.splitCount = tonumber(splitCount)
    GDKPT.Core.leaderSettings.isSet = true

    print(string.format(GDKPT.Core.print .. "Received Auction Settings from |cffFFC125%s|r.", sender))

    GDKPT.InfoButton.UpdateInfoButtonStatus()

    if GDKPT.UI.AuctionWindow:IsVisible() then
        GDKPT.UI.SyncButton:Hide()
        GDKPT.UI.ArrowFrame:Hide()
        GDKPT.UI.ArrowText:Hide()
        GDKPT.UI.AuctionScrollFrame:Show()
    end

    -- Re-enable all bid buttons for auctions that did NOT end yet
    for auctionId, row in pairs(GDKPT.Core.AuctionFrames) do
        if not row.clientSideEnded and not (row.endOverlay and row.endOverlay:IsShown()) then
            if row.bidButton then
                row.bidButton:Enable()
                local nextMinBid = row.topBidder == "" and row.startBid or (row.currentBid or 0) + GDKPT.Core.leaderSettings.minIncrement
                row.bidButton:SetText(nextMinBid .. " G")
            end
            if row.bidBox then
                row.bidBox:Enable()
                row.bidBox:EnableMouse(true)
            end
        end
    end
end



-------------------------------------------------------------------
-- 4. When the Masterlooter AutoMasterloots an item, this function
-- handles favorite alerts and adding to loot tracker
-------------------------------------------------------------------

local function HandleMLootItem(data)
    if not data or data == "" then return end
    
    -- Extract all valid item links from the data string
    -- Item links follow the pattern: |cXXXXXXXX|Hitem:...|h[...]|h|r
    local itemLinks = {}
    for link in data:gmatch("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r)") do
        table.insert(itemLinks, link)
    end
    
    -- If no valid item links found, try treating entire data as single link
    if #itemLinks == 0 and data:match("|Hitem:") then
        table.insert(itemLinks, data)
    end
    
    -- Process each valid item link
    for _, link in ipairs(itemLinks) do
        local itemID = tonumber(link:match("item:(%d+)"))
        if itemID then
            -- Validate item exists before processing
            local itemName = GetItemInfo(itemID)
            if itemName or GetItemInfo(link) then
                GDKPT.Favorites.CheckLootedItemForFavorite(link)
                if GDKPT.Loot and GDKPT.Loot.AddLootedItem then
                    GDKPT.Loot.AddLootedItem(link)
                end
            end
        end
    end
end



-------------------------------------------------------------------
-- 5. When the leader starts an auction, this function handles 
-- adding a new auction row
-------------------------------------------------------------------

local function HandleAuctionStart(data)

    local id, itemID, startBid, minInc, remainingDuration, stackCount, itemLink =
        data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):(.+)")
    if not (id and itemID and startBid and minInc and remainingDuration and itemLink) then return end

    GDKPT.AuctionStart.HandleAuctionStart(
        tonumber(id), tonumber(itemID), tonumber(startBid),
        tonumber(minInc), tonumber(remainingDuration), itemLink, tonumber(stackCount)
    )

    -- Re-enable bid button if auction is still active and settings are synced
    local auctionId = tonumber(id)
    local duration = tonumber(remainingDuration)
    
    if duration > 0 and GDKPT.Core.leaderSettings and GDKPT.Core.leaderSettings.isSet then
        C_Timer.After(1, function()
            local row = GDKPT.Core.AuctionFrames[auctionId]
            if row and not row.clientSideEnded and not (row.endOverlay and row.endOverlay:IsShown()) then
                if row.bidButton then
                    row.bidButton:Enable()
                    local nextMinBid = row.topBidder == "" and row.startBid or (row.currentBid or 0) + GDKPT.Core.leaderSettings.minIncrement
                    row.bidButton:SetText(nextMinBid .. " G")
                end
                if row.bidBox then
                    row.bidBox:Enable()
                    row.bidBox:EnableMouse(true)
                end
            end
        end)
    end

end


-------------------------------------------------------------------
-- 6. When a player is bidding on any item, the raidleader verifies
-- the bid and sends an auction update to members. This function 
-- handles the auction updates on member side.
-------------------------------------------------------------------

local function HandleAuctionUpdate(data)

    local id, newBid, topBidder, remainingTime, itemID, itemLink =
        data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):(.+)")
    if not (id and newBid and topBidder and remainingTime and itemID and itemLink) then return end

    if topBidder == UnitName("player") then
        SendChatMessage(string.format("[GDKPT] I'm bidding %d gold on %s !", newBid, itemLink), "RAID")
    end

    GDKPT.AuctionBid.HandleAuctionUpdate(tonumber(id), tonumber(newBid), topBidder, tonumber(remainingTime))

    -- Update mini bid frame if visible
    if GDKPT.MiniBidFrame and GDKPT.MiniBidFrame.Frame and GDKPT.MiniBidFrame.Frame:IsShown() then
        GDKPT.MiniBidFrame.Update()
    end


    GDKPT.Favorites.CheckAutoBid(
        tonumber(id), tonumber(itemID), tonumber(newBid) + GDKPT.Core.leaderSettings.minIncrement, topBidder, itemLink
    )

    local row = GDKPT.Core.AuctionFrames[tonumber(id)]
    GDKPT.AuctionRow.UpdateRowColor(row)
end


-------------------------------------------------------------------
-- 7. Handler for ending an auction on member side
-------------------------------------------------------------------

local function HandleAuctionEnd(data)

    local auctionId, GDKP_Pot, itemID, winningPlayer, finalBid =
        data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")
    if not (auctionId and GDKP_Pot and itemID and winningPlayer and finalBid) then return end

    GDKPT.AuctionEnd.HandleAuctionEnd(
        tonumber(auctionId), tonumber(GDKP_Pot), tonumber(itemID), winningPlayer, tonumber(finalBid)
    )
end


-------------------------------------------------------------------
-- 8. Handler for manual adjustments on member side
-------------------------------------------------------------------

local function HandleManualAdjustment(data)

    local playerName, adjustmentAmountStr, newPotStr, newBalanceStr, auctionIndexStr =
        data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")

    if not (playerName and newPotStr and newBalanceStr) then return end

    local newPot = tonumber(newPotStr)
    local newPlayerBalance = tonumber(newBalanceStr)
    local adjustmentAmount = tonumber(adjustmentAmountStr)
    local auctionIndex = tonumber(auctionIndexStr) or -1

    local row = GDKPT.Core.AuctionFrames[auctionIndex]
    if row then row.manualAdjustmentOverlay:Show() end

    GDKPT.Core.GDKP_Pot = newPot
    GDKPT.UI.UpdateTotalPotAmount(newPot * 10000)
    GDKPT.UI.UpdateCurrentCutAmount(newPot * 10000 / GDKPT.Core.leaderSettings.splitCount)

    if playerName == UnitName("player") and auctionIndex > 0 then
        for _, item in ipairs(GDKPT.Core.PlayerWonItems) do
            if item.auctionId == auctionIndex and not item.isAdjustment then
                item.wasAdjusted = true
                item.adjustmentAmount = adjustmentAmount
                break
            end
        end
    end

    table.insert(GDKPT.Core.PlayerWonItems, {
        name = "Manual Adjustment",
        link = nil,
        bid = adjustmentAmount,
        isAdjustment = true,
        relatedAuctionId = auctionIndex > 0 and auctionIndex or nil,
        timestamp = time()
    })

    table.insert(GDKPT.Core.History, {
        winner = playerName,
        bid = adjustmentAmount,
        link = nil,
        isAdjustment = true,
        relatedAuctionId = auctionIndex > 0 and auctionIndex or nil,
        timestamp = time()
    })

    print(string.format(GDKPT.Core.print .. "Manual Adjustment: %s %s %d gold. New Pot: %d",
        playerName, (adjustmentAmount > 0 and "owes" or "receives"), math.abs(adjustmentAmount), newPot))
end



-------------------------------------------------------------------
-- 9. Handler for syncing the pot with the leader again, used after 
-- reloads and relogs
-------------------------------------------------------------------

local function HandleSyncPot(data)
    local pot, splitCount = data:match("([^:]+):([^:]+)")
    pot, splitCount = tonumber(pot), tonumber(splitCount)
    if not (pot and splitCount) then return end

    GDKPT.Core.GDKP_Pot = pot
    GDKPT.Core.leaderSettings.splitCount = splitCount

    if GDKPT.UI.UpdateTotalPotAmount then
        GDKPT.UI.UpdateTotalPotAmount(pot * 10000)
    end

    -- Always recalculate cut based on current raid size if available
    local actualSplitCount = (IsInRaid() and GetNumRaidMembers()) or splitCount
    if actualSplitCount > 0 then
        if GDKPT.UI.UpdateCurrentCutAmount then
            GDKPT.UI.UpdateCurrentCutAmount((pot * 10000) / actualSplitCount)
        end
    end
end



-------------------------------------------------------------------
-- 10. Handler for syncing up player balance data, used after reload
-- and relog, might not be needed anymore?
-- does not do anything but RepositionAllAuctions currently
-------------------------------------------------------------------

local function HandleSyncBalances(data)
    local balancePairs = {strsplit(",", data)}
    local syncedCount = 0

    for _, pair in ipairs(balancePairs) do
        local playerName, balance = strsplit(":", pair)
        if playerName and balance then
            local balanceNum = tonumber(balance)
            if balanceNum and playerName == UnitName("player") then
                syncedCount = syncedCount + 1
            end
        end
    end
    GDKPT.AuctionLayout.RepositionAllAuctions()
end


-------------------------------------------------------------------
-- 11. Handler for resetting everything on member side
-------------------------------------------------------------------

local function HandleAuctionReset()
    for _, row in pairs(GDKPT.Core.AuctionFrames) do
        if row then
            row:SetScript("OnUpdate", nil)
            row:Hide()
            row:SetParent(nil)
        end
    end
    wipe(GDKPT.Core.AuctionFrames)
    wipe(GDKPT.Core.PlayerWonItems)
    wipe(GDKPT.Core.PlayerBidHistory)
    wipe(GDKPT.AuctionStart.PendingAuctions)
    GDKPT.Core.GDKP_Pot = 0
    GDKPT.Core.PlayerCut = 0

    if GDKPT.UI.ResetAuctionWindow then GDKPT.UI.ResetAuctionWindow() end
    if GDKPT.UI.UpdateTotalPotAmount then GDKPT.UI.UpdateTotalPotAmount(0) end
    if GDKPT.UI.UpdateCurrentCutAmount then GDKPT.UI.UpdateCurrentCutAmount(0) end
    if GDKPT.MyWonAuctions.UpdateWonItemsDisplay and GDKPT.MyWonAuctions.WonAuctionsFrame then
        GDKPT.MyWonAuctions.UpdateWonItemsDisplay(GDKPT.MyWonAuctions.WonAuctionsFrame)
    end
    if GDKPT.AuctionHistory.UpdateGeneralHistoryList then GDKPT.AuctionHistory.UpdateGeneralHistoryList() end
    if GDKPT.UI.AuctionContentFrame then GDKPT.UI.AuctionContentFrame:SetHeight(100) end
    if GDKPT.Core.isFavoriteFilterActive then
        GDKPT.Core.isFavoriteFilterActive = false
        if GDKPT.UI.UpdateFilterButtonText then GDKPT.UI.UpdateFilterButtonText() end
    end

    -- Force UI refresh after short delay to ensure clean state
    C_Timer.After(0.5, function()
        if GDKPT.UI.AuctionWindow and GDKPT.UI.AuctionWindow:IsVisible() then
            -- Force scroll to top
            if GDKPT.UI.AuctionScrollFrame and GDKPT.UI.AuctionScrollFrame.ScrollBar then
                GDKPT.UI.AuctionScrollFrame.ScrollBar:SetValue(0)
            end
            
            -- Flash the window to indicate reset
            UIFrameFlash(GDKPT.UI.AuctionWindow, 0.5, 0.5, 1, false, 0, 0)
        end
        
        -- Request fresh sync to ensure everyone is in sync
        C_Timer.After(1, function()
            if IsInRaid() then
                local msg = "REQUEST_AUCTION_SYNC"
                SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")
            end
        end)
    end)

    GDKPT.Trading.totalPaid = 0
    GDKPT.Trading.totalOwed = 0
    GDKPT.Core.TradingData.totalPaid = 0
    GDKPT.Core.TradingData.totalOwed = 0

    wipe(GDKPT.Core.PlayerActiveBids)
    GDKPT.UI.MyBidsText:SetText("")

    print(GDKPT.Core.print .. "Everything has been reset by the raid leader.")

end


-------------------------------------------------------------------
-- 12. Old handler for hiding AutoFill during pot split phase, 
-- probably obsolete now
-------------------------------------------------------------------

local function StartPotSplit()
    GDKPT.Core.PotSplitStarted = 1    
end


-------------------------------------------------------------------
-- 13. Handler for un-bugging players who have done an invalid bid
-------------------------------------------------------------------

local function HandleAuctionBidReenable(data)
    local auctionId = tonumber(data)
    if not auctionId then return end
    local row = GDKPT.Core.AuctionFrames[auctionId]
    if row and row.bidButton and not row.clientSideEnded and not (row.endOverlay and row.endOverlay:IsShown()) then
        row.bidButton:Enable()
        local nextMinBid = row.topBidder == "" and row.startBid or (row.currentBid or 0) + GDKPT.Core.leaderSettings.minIncrement
        row.bidButton:SetText(nextMinBid .. " G")
    end
    -- Also re-enable mini bid frame button
    if GDKPT.MiniBidFrame and GDKPT.MiniBidFrame.Frame and GDKPT.MiniBidFrame.Frame:IsShown() then
        GDKPT.MiniBidFrame.Update()
    end
    print(GDKPT.Core.errorprint .. "This bid was invalid since another player placed a bid on this auction shortly before, your bid button has been re-enabled.")
end



-------------------------------------------------------------------
-- 14. Leader addon periodically sends out addon messages to members 
-- which then sets GDKPT.Core.IsInGDKPRaid to true, which then 
-- enables GDKPT addon functionalities
-------------------------------------------------------------------

local function HandleLeaderHeartbeat()
    GDKPT.Core.LastLeaderHeartbeat = GetTime()
    GDKPT.Core.IsInGDKPRaid = true
end




-------------------------------------------------------------------
-- 15. Handler for receiving own player balance on trades with 
-- leader and then update AutoFill button accordingly
-------------------------------------------------------------------

local function UpdateMyBalance(data)
    local balance = tonumber(data)
    if balance then
        GDKPT.Core.MyBalance = balance
    end

    if balance == 0 then
        print(string.format(GDKPT.Core.print .. "Balance: %d gold, all paid up.",balance))
        GDKPT.Trading.MemberAutoFillButton:SetText("All Paid Up")
        GDKPT.Trading.MemberAutoFillButton:Disable()
    elseif balance > 0 then
        print(string.format(GDKPT.Core.print .. "Balance: %d gold, you will get %d gold from the Leader",balance,balance))
        GDKPT.Trading.MemberAutoFillButton:SetText("Get Cut")
        GDKPT.Trading.MemberAutoFillButton:Enable()
    elseif balance < 0 then
        print(string.format(GDKPT.Core.print .. "Balance: %d gold, you need to pay up %d gold.",balance,math.abs(balance)))
        GDKPT.Trading.MemberAutoFillButton:Enable()
        GDKPT.Trading.MemberAutoFillButton:SetText(string.format("AutoFill: %d G",math.abs(balance)))
    end
    
end



-------------------------------------------------------------------
-- Event frame for receiving leader messages
-------------------------------------------------------------------



local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if not IsValidAddonMessage(prefix, sender) then return end
    local cmd, data = msg:match("([^:]+):(.*)")
    if not cmd then return end

    local handlers = {
        VERSION_CHECK = HandleVersionCheck,
        SETTINGS = function() HandleSettings(data, sender) end,
        MLOOT_ITEM = function() HandleMLootItem(data) end,
        AUCTION_START = function() HandleAuctionStart(data) end,
        AUCTION_UPDATE = function() HandleAuctionUpdate(data) end,
        AUCTION_END = function() HandleAuctionEnd(data) end,
        MANUAL_ADJUSTMENT = function() HandleManualAdjustment(data) end,
        SYNC_POT = function() HandleSyncPot(data) end,
        SYNC_BALANCES = function() HandleSyncBalances(data) end,
        AUCTION_RESET = function() HandleAuctionReset() end,
        POT_SPLIT_START = function() StartPotSplit() end,
        AUCTION_BID_REENABLE = function() HandleAuctionBidReenable(data) end,
        LEADER_HEARTBEAT = HandleLeaderHeartbeat(),
        SYNC_MY_BALANCE = function() UpdateMyBalance(data) end
    }

    if handlers[cmd] then handlers[cmd]() end
end)


