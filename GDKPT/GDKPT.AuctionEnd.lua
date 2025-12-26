GDKPT.AuctionEnd = {}


-------------------------------------------------------------------
-- Stop timers and disable controls for the specific auction row
-------------------------------------------------------------------

local function CleanUpAuctionRow(row)
    -- Stop the unstuck check timer when an auction ends
    if row.unstuckCheckTimer then
        row.unstuckCheckTimer:Cancel()
        row.unstuckCheckTimer = nil
    end

    -- Hide and disable unstuck button
    if row.unstuckButton then
        row.unstuckButton:Hide()
        row.unstuckButton:Disable()
    end

    -- Show row if it wasn’t user-hidden
    if not row.userHidden then row:Show() end

    -- Stop any OnUpdate scripts, this auction is done and doesnt need to update anymore
    row:SetScript("OnUpdate", nil) 
    row.clientSideEnded = false

    -- Disable bid box
    if row.bidBox then
        row.bidBox:EnableMouse(false)
        row.bidBox:SetText("")
        row.bidBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        GDKPT.AuctionRow.ClearAndDisableBidBox(row.bidBox)
    end

    -- Disable bid button
    if row.bidButton then
        row.bidButton:Disable()
        row.bidButton:SetText("ENDED")
    end

    -- Update timer text
    if row.timerText then
        row.timerText:SetText("|cffff0000ENDED|r")
    end
end


-------------------------------------------------------------------
-- Show winner and mark the auction visually as ended
-------------------------------------------------------------------

local function DisplayWinner(row, winner, finalBid)
    if winner == "Bulk" then
        row.winnerText:SetText("BULK")
        row.winnerText:SetTextColor(1, 0, 0, 1)
        row.endOverlay:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    else 
        --row.winnerText:SetText("Winner: " .. winner .. " (" .. GDKPT.Utils.FormatMoney(finalBid * 10000) .. ")")
        row.winnerText:SetText("Winner: " .. winner .. " (" .. GDKPT.Utils.FormatGoldOnly(finalBid * 10000) .. ")")
        row.winnerText:SetTextColor(0, 1, 0, 1)
        row.endOverlay:SetBackdropBorderColor(0.2, 0.8, 0.2, 1)
    end

    row:SetBackdropColor(row.DEFAULT_R, row.DEFAULT_G, row.DEFAULT_B, row.DEFAULT_A)
    row.endOverlay:Show()
end



-------------------------------------------------------------------
-- Update overall pot and player cut display
-------------------------------------------------------------------

local function UpdatePotDisplays(GDKP_Pot)
    GDKPT.UI.UpdateTotalPotAmount(GDKP_Pot * 10000)
    local currentSplitCount = GDKPT.Utils.GetCurrentSplitCount()
    GDKPT.UI.UpdateCurrentCutAmount(GDKP_Pot * 10000 / currentSplitCount)
end


-------------------------------------------------------------------
-- Record auction in history if it has a valid winner and bid
------------------------------------------------------------------

local function RecordAuctionHistory(itemID, winner, finalBid)
    local _, itemLink = GetItemInfo(itemID)
    if itemLink and finalBid > 0 then
        table.insert(GDKPT.Core.History, {
            winner = winner,
            bid = finalBid,
            link = itemLink,
            timestamp = time(),
        })
    end
end

-------------------------------------------------------------------
-- Hide completed auctions if the setting is enabled
-------------------------------------------------------------------

local function HideCompletedRowIfNeeded(row)
    if GDKPT.Core.Settings.HideCompletedAuctions == 1 then
        C_Timer.After(5, function()
            row:Hide()
            GDKPT.AuctionLayout.RepositionAllAuctions()
        end)
    end
end


-------------------------------------------------------------------
-- Handle player winning the auction
-------------------------------------------------------------------

local function HandlePlayerWin(row, auctionId, itemID, finalBid, winningPlayer)
    local itemName, itemLink = GetItemInfo(itemID)

    -- Fallback if item info is still missing or not cached
    if not itemName and row and row.itemName then
        itemName = row.itemName
        itemLink = row.itemLink
    end

    if not itemName then
        itemName = "Unknown Item"
        itemLink = string.format("|cffffffff[Item:%d]|r", itemID)
    end

    -- Add to player won items table
    table.insert(GDKPT.Core.PlayerWonItems, {
        name = itemName,
        link = itemLink,
        bid = finalBid,
        auctionId = auctionId,
        amountPaid = 0,
        timestamp = time(),
        winner = winningPlayer,
        itemID = itemID
    })

    print(string.format(GDKPT.Core.print .. "Congratulations! You won %s for %d G.", itemLink, finalBid))
    print(string.format(GDKPT.Core.print .. "Trade |cffFFC125%s|r to receive %s .",GDKPT.Utils.GetRaidLeaderName(), itemLink))
    print(string.format(GDKPT.Core.print .. "Click the AutoFill button on the bottom left to automatically put %d gold into the trade window.",finalBid))

    if GDKPT.Core.Settings.AuctionWonAudioAlert == 1 then
        PlaySoundFile("Interface\\AddOns\\GDKPT\\Sounds\\AuctionWon.mp3", "Master")

    end

    GDKPT.MyWonAuctions.UpdateWonItemsDisplay(GDKPT.MyWonAuctions.WonAuctionsFrame)
    GDKPT.Core.LastKnownTopBidder[auctionId] = nil

    if GDKPT.Core.Settings.Fav_RemoveItemOnWin == 1 then
        GDKPT.Favorites.RemoveFavoriteWhenAuctionWon(itemID, winningPlayer)
    end

    -- Keep committed bid for record
    GDKPT.Core.PlayerActiveBids[auctionId] = finalBid
end




-------------------------------------------------------------------
-- Clean up pending auctions cache
-------------------------------------------------------------------

local function CleanupPendingAuctionsCache(auctionId)
    if GDKPT.AuctionStart.PendingAuctions then
        for itemIDStr, auctions in pairs(GDKPT.AuctionStart.PendingAuctions) do
            if auctions[auctionId] then
                auctions[auctionId] = nil
                if not next(auctions) then
                    GDKPT.AuctionStart.PendingAuctions[itemIDStr] = nil
                end
            end
        end
    end
end



-------------------------------------------------------------------
-- Mark the auctioned item as ended
-------------------------------------------------------------------

local function MarkAuctionItemAsEnded(itemID, winner, finalBid)
    for _, aItem in ipairs(GDKPT.Core.AuctionedItems) do
        if aItem.itemID == itemID then
            aItem.ended = true
            aItem.winner = winner
            aItem.winningBid = finalBid
            break
        end
    end
end




-------------------------------------------------------------------
-- Function that handles the end of an auction
-------------------------------------------------------------------


function GDKPT.AuctionEnd.HandleAuctionEnd(auctionId, GDKP_Pot, itemID, winningPlayer, finalBid)  
    local row = GDKPT.Core.AuctionFrames[auctionId]
    if not row then return end

    -- Stop timers and disable controls for the auction row
    CleanUpAuctionRow(row)

    -- Show winner and mark the auction visually as ended
    DisplayWinner(row, winningPlayer, finalBid)

    -- Handle player winning the auction
    if winningPlayer == UnitName("player") and finalBid > 0 then
        HandlePlayerWin(row, auctionId, itemID, finalBid, winningPlayer)
    else
        -- Player did not win: release committed gold
        GDKPT.Core.PlayerActiveBids[auctionId] = nil
    end

    -- Mark the auctioned item as ended
    MarkAuctionItemAsEnded(itemID, winningPlayer, finalBid)

    -- Update overall pot and player cut display
    UpdatePotDisplays(GDKP_Pot)

    -- Update bid displays
    if GDKPT.Utils.UpdateMyBidsDisplay then
        GDKPT.Utils.UpdateMyBidsDisplay()
    end

    -- Update loot display
    GDKPT.Loot.UpdateLootDisplay()

    -- Hide completed auctions if the setting is enabled
    HideCompletedRowIfNeeded(row)

    -- Record auction in history if it has a valid winner and bid
    RecordAuctionHistory(itemID, winningPlayer, finalBid)

    -- Clean up pending auctions cache
    CleanupPendingAuctionsCache(auctionId)
end


















