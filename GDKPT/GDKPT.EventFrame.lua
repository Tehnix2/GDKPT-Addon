GDKPT.EventFrame = {}



-------------------------------------------------------------------
-- Event frame that handles incoming messages from the leader Addon
-------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript(
    "OnEvent",
    function(self, event, prefix, msg, channel, sender)
        if prefix ~= GDKPT.Core.addonPrefix or not sender or sender ~= GDKPT.Utils.GetRaidLeaderName() then
            return
        end

        local cmd, data = msg:match("([^:]+):(.*)")

        -- Version Check
        if cmd == "VERSION_CHECK" and IsInRaid() then
            SendChatMessage(string.format("[GDKPT] Version %.2f", GDKPT.Core.version), "RAID")
        end

        -- Receive the synced auction settings from the leader
        if cmd == "SETTINGS" then
            local duration, extraTime, startBid, minIncrement, splitCount =
                data:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
            if duration and extraTime and startBid and minIncrement and splitCount then
                GDKPT.Core.leaderSettings.duration = tonumber(duration)
                GDKPT.Core.leaderSettings.extraTime = tonumber(extraTime)
                GDKPT.Core.leaderSettings.startBid = tonumber(startBid)
                GDKPT.Core.leaderSettings.minIncrement = tonumber(minIncrement)
                GDKPT.Core.leaderSettings.splitCount = tonumber(splitCount)
                GDKPT.Core.leaderSettings.isSet = true
                print(string.format("|cff99ff99[GDKPT]|r Received settings from |cffFFC125%s|r.", sender))

                GDKPT.UI.UpdateInfoButtonStatus()

                if GDKPT.UI.AuctionWindow:IsVisible() then
                    GDKPT.UI.SyncSettingsButton:Hide()
                    GDKPT.UI.AuctionScrollFrame:Show()
                end
            end
        end

        if cmd == "AUCTION_START" then
            local id, itemID, startBid, minInc, endTime, itemLink =
                data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):(.+)")
            if id and itemID and startBid and minInc and endTime and itemLink then
                GDKPT.AuctionStart.HandleAuctionStart(
                    tonumber(id),
                    tonumber(itemID),
                    tonumber(startBid),
                    tonumber(minInc),
                    tonumber(endTime),
                    itemLink
                )
            end
        elseif cmd == "AUCTION_UPDATE" then
            local id, newBid, topBidder, endTime, itemID, itemLink = data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):(.+)")
            if id and newBid and topBidder and endTime and itemID and itemLink then
                GDKPT.AuctionBid.HandleAuctionUpdate(tonumber(id), tonumber(newBid), topBidder, tonumber(endTime))
                GDKPT.AuctionFavorites.CheckAutoBid(tonumber(id), tonumber(itemID), tonumber(newBid) + GDKPT.Core.leaderSettings.minIncrement, topBidder, itemLink)
            end
        elseif cmd == "AUCTION_END" then
            local auctionId, GDKP_Pot, itemID, winningPlayer, finalBid =
                data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")

            if auctionId and GDKP_Pot and itemID and winningPlayer and finalBid then
                GDKPT.AuctionEnd.HandleAuctionEnd(
                    tonumber(auctionId),
                    tonumber(GDKP_Pot),
                    tonumber(itemID),
                    winningPlayer,
                    tonumber(finalBid)
                )
            end
        end
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








  -- Open Issues:


-- small window as UI parent that does /gdkp show
-- frame where people can pre-favorite items before auctions, and then get alerted when that specific auction occurs
-- also have the leader addon alert the player if their favorited item has dropped from a boss
   -- dont have rows disappear constantly, fixed rows and only have them disappear once all auctions are done
    -- 1) reload / logout persistance of global auction settings
    -- 6) limit by goldcap?
    -- 7) /gdkp sync command on member addon for syncing current auctions
    -- 9) /history for saving data and export
    -- 10) small UI button thats dragable for showing gdkp tab
    -- 11) auto bid underneath bid button
    -- 12) timer cap
    -- gdkpd features: auto masterloot everything, screenshotable auctions, export
    -- manually adjusting players won auctions in case someone misbids
    -- confirmation prompt for bid box and manual bids that can be enabled/disabled