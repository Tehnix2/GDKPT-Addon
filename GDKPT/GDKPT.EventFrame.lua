GDKPT.EventFrame = {}

-- 1. Check if incoming message is valid (GDKPT addon message and from Leader)

local function IsValidAddonMessage(prefix, sender)
    return prefix == GDKPT.Core.addonPrefix and sender == GDKPT.Utils.GetRaidLeaderName()
end




-- 2. Version Check
local function HandleVersionCheck()
    if IsInRaid() then
        SendChatMessage(string.format("[GDKPT] Version %.2f", GDKPT.Core.version), "RAID")
    end
end



-- 3. General Auction Settings 

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

    print(string.format("|cff99ff99[GDKPT]|r Received Auction Settings from |cffFFC125%s|r.", sender))

    GDKPT.UI.UpdateInfoButtonStatus()

    if GDKPT.UI.AuctionWindow:IsVisible() then
        GDKPT.UI.SyncSettingsButton:Hide()
        GDKPT.UI.ArrowFrame:Hide()
        GDKPT.UI.ArrowText:Hide()
        GDKPT.UI.AuctionScrollFrame:Show()
    end

    -- Re-enable all bid buttons
    for _, row in pairs(GDKPT.Core.AuctionFrames) do
        if row.bidButton then
            row.bidButton:Enable()
            local nextMinBid = row.topBidder == "" and row.startBid or (row.currentBid or 0) + GDKPT.Core.leaderSettings.minIncrement
            row.bidButton:SetText(nextMinBid .. " G")
        end
        if row.bidBox then row.bidBox:Enable() end
    end
end


-- 4. Handle Masterloot announcement from Leader

local function HandleMLootItem(data)

    local itemLinks = {strsplit("|", data)}
    for _, link in ipairs(itemLinks) do
        GDKPT.AuctionFavorites.CheckLootedItemForFavorite(link)
    end
end




-- 5. Handle AuctionStart

local function HandleAuctionStart(data)

    local id, itemID, startBid, minInc, remainingDuration, itemLink =
        data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):(.+)")
    if not (id and itemID and startBid and minInc and remainingDuration and itemLink) then return end

    GDKPT.AuctionStart.HandleAuctionStart(
        tonumber(id), tonumber(itemID), tonumber(startBid),
        tonumber(minInc), tonumber(remainingDuration), itemLink
    )
end


-- 6. Handle AuctionUpdate when someone bids on an auction

local function HandleAuctionUpdate(data)

    local id, newBid, topBidder, remainingTime, itemID, itemLink =
        data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):(.+)")
    if not (id and newBid and topBidder and remainingTime and itemID and itemLink) then return end

    GDKPT.AuctionBid.HandleAuctionUpdate(tonumber(id), tonumber(newBid), topBidder, tonumber(remainingTime))
    GDKPT.AuctionFavorites.CheckAutoBid(
        tonumber(id), tonumber(itemID), tonumber(newBid) + GDKPT.Core.leaderSettings.minIncrement, topBidder, itemLink
    )
end


-- 7. Handle AuctionEnd when an auction finishes


local function HandleAuctionEnd(data)

    local auctionId, GDKP_Pot, itemID, winningPlayer, finalBid =
        data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")
    if not (auctionId and GDKP_Pot and itemID and winningPlayer and finalBid) then return end

    GDKPT.AuctionEnd.HandleAuctionEnd(
        tonumber(auctionId), tonumber(GDKP_Pot), tonumber(itemID), winningPlayer, tonumber(finalBid)
    )
end




-- 8. Manual Adjustments in case of misbids


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

    print(string.format("|cff00ff00[GDKPT]|r Manual Adjustment: %s %s %d gold. New Pot: %d",
        playerName, (adjustmentAmount > 0 and "owes" or "receives"), math.abs(adjustmentAmount), newPot))
end






-- 9.1 HandleSyncPot for syncronizing the pot with the Leader again, used after reloads/relog 
local function HandleSyncPot(data)
    local pot, splitCount = data:match("([^:]+):([^:]+)")
    pot, splitCount = tonumber(pot), tonumber(splitCount)
    if not (pot and splitCount) then return end

    GDKPT.Core.GDKP_Pot = pot
    GDKPT.Core.leaderSettings.splitCount = splitCount

    if GDKPT.UI.UpdateTotalPotAmount then
        GDKPT.UI.UpdateTotalPotAmount(pot * 10000)
    end
    if GDKPT.UI.UpdateCurrentCutAmount then
        GDKPT.UI.UpdateCurrentCutAmount((pot * 10000) / splitCount)
    end

    print(string.format("|cff00ff00[GDKPT]|r Pot synced: %d gold, Split: %d players", pot, splitCount))
end



-- 9.2 Handle syncing player balances with the leader again, used after reloads/relog
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

    print(string.format("|cff00ff00[GDKPT]|r Received balance data for %d players.", syncedCount))
end






-- 10. Handle auction reset to reset everything for a new raid
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
    GDKPT.Core.GDKP_Pot = 0
    GDKPT.Core.PlayerCut = 0

    if GDKPT.UI.ResetAuctionWindow then GDKPT.UI.ResetAuctionWindow() end
    if GDKPT.UI.UpdateTotalPotAmount then GDKPT.UI.UpdateTotalPotAmount(0) end
    if GDKPT.UI.UpdateCurrentCutAmount then GDKPT.UI.UpdateCurrentCutAmount(0) end
    if GDKPT.AuctionEnd.UpdateWonItemsDisplay and GDKPT.UI.AuctionWindow.WonAuctionsFrame then
        GDKPT.AuctionEnd.UpdateWonItemsDisplay(GDKPT.UI.AuctionWindow.WonAuctionsFrame)
    end
    if GDKPT.AuctionHistory.UpdateGeneralHistoryList then GDKPT.AuctionHistory.UpdateGeneralHistoryList() end
    if GDKPT.UI.AuctionContentFrame then GDKPT.UI.AuctionContentFrame:SetHeight(100) end
    if GDKPT.Core.isFavoriteFilterActive then
        GDKPT.Core.isFavoriteFilterActive = false
        if GDKPT.UI.UpdateFilterButtonText then GDKPT.UI.UpdateFilterButtonText() end
    end

    print("|cff00ff00[GDKPT]|r All auctions have been reset by the raid leader.")
    if GDKPT.UI.AuctionWindow and GDKPT.UI.AuctionWindow:IsVisible() then
        UIFrameFlash(GDKPT.UI.AuctionWindow, 0.5, 0.5, 1, false, 0, 0)
    end
end




-- 11. Handle payment confirmation from leader (if needed)
local function HandlePaymentConfirmation(data)
    local newBalance = tonumber(data)
    if newBalance then
        print(string.format("|cff00ff00[GDKPT]|r Payment recorded. Remaining balance: %dg", math.abs(newBalance)))
    end
end








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
        PAYMENT_CONFIRM = function() HandlePaymentConfirmation(data) end
    }

    if handlers[cmd] then handlers[cmd]() end
end)





  -- Open Issues:



 
    -- 7) /gdkp sync command on member addon for syncing current auctions
    -- 9) /history for saving data and export
    -- 12) timer cap
    -- gdkpd features:  screenshotable auctions, export
