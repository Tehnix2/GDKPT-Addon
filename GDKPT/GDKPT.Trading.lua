GDKPT.Trading = {
    totalOwed = GDKPT.Core.TradingData and GDKPT.Core.TradingData.totalOwed or 0,
    totalPaid = GDKPT.Core.TradingData and GDKPT.Core.TradingData.totalPaid or 0,
}

local lastTradeMoney = 0




-------------------------------------------------------------------
-- Auto Fill Button for raid members
-------------------------------------------------------------------
local MemberAutoFillButton = CreateFrame("Button", "GDKPT_AutoFillButton", TradeFrame, "UIPanelButtonTemplate")
MemberAutoFillButton:SetSize(100, 22)
MemberAutoFillButton:SetPoint("BOTTOM", TradeFrame, "BOTTOM", -60, 56)
MemberAutoFillButton:SetText("AutoFill")




-------------------------------------------------------------------
-- Check the PlayerWonItems table and return the sum of all won auctions
-------------------------------------------------------------------

local function CalculateTotalOwed()
    local totalOwed = 0
    
    for _, item in ipairs(GDKPT.Core.PlayerWonItems) do
        if item.isAdjustment then
            -- Add adjustment to total (can be positive or negative)
            totalOwed = totalOwed + (item.bid or 0)
        elseif not item.wasAdjusted then
            -- Only add items that weren't manually adjusted
            totalOwed = totalOwed + (item.bid or 0)
        end
    end
    
    GDKPT.Trading.totalOwed = totalOwed
    GDKPT.Core.TradingData.totalOwed = GDKPT.Trading.totalOwed
    return totalOwed
end




-------------------------------------------------------------------
-- Function to self-check how much gold still need to be paid  
-------------------------------------------------------------------

function GDKPT.Trading.CheckRemainingOwed()
    local totalOwed = CalculateTotalOwed()
    local alreadyPaid = GDKPT.Trading.totalPaid or 0
    local remaining = totalOwed - alreadyPaid

    if remaining == 0 then
        print(GDKPT.Core.print .. "You have already fully paid up.")
    else
        print(string.format("You still need to trade %d out of %d gold to the raidleader.", remaining, totalOwed))
    end
end


-------------------------------------------------------------------
-- Member AutoFill Button Click Handler
-------------------------------------------------------------------
local function OnAutoFillClick()
    
    -- Check if player is in a GDKP raid with GDKPT addon
    if not GDKPT.Core.CheckGDKPRaidStatus() then
        return
    end

    if GDKPT.Core.Settings.AutoFillTradeGold == 0 then
        print(GDKPT.Core.errorprint .. "Autofill button is not enabled!")
        return
    end

    local totalOwed = CalculateTotalOwed()
    local alreadyPaid = GDKPT.Trading.totalPaid or 0
    local remaining = totalOwed - alreadyPaid

    if remaining <= 0 then
        print(GDKPT.Core.print .. "You have already paid up!")
        return
    end

    MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, remaining * 10000)

    print(string.format(GDKPT.Core.print .. "You owe %d gold total, already paid %d gold. Autofilled the remaining %d gold.",
        totalOwed, alreadyPaid, remaining))

    if GDKPT.Core.Settings.AutoFillTradeAccept == 1 then
        AcceptTrade()
    end
end

MemberAutoFillButton:SetScript("OnClick", OnAutoFillClick)





-------------------------------------------------------------------
-- After a reload there is no auction data, so player needs a quick
-- resync if they trade the leader and they did not sync up yet
-------------------------------------------------------------------

local function RequestQuickSyncOnTrade()

    -- Check if player is in a GDKP raid with GDKPT addon
    if not GDKPT.Core.CheckGDKPRaidStatus() then
        return
    end

    local leaderName = GDKPT.Utils.GetRaidLeaderName()
    if not IsInRaid() or not leaderName then return end

    print(GDKPT.Core.errorprint .. "Auction data not found, requesting auction sync from |cffFFC125" .. leaderName .. "|r...")
    SendAddonMessage(GDKPT.Core.addonPrefix, "REQUEST_SETTINGS_SYNC", "RAID")

    C_Timer.After(0.5, function()
        SendAddonMessage(GDKPT.Core.addonPrefix, "REQUEST_AUCTION_SYNC", "RAID")
    end)
end


local function UpdateAutoFillButton()

    -- Check if player is in a GDKP raid with GDKPT addon
    if not GDKPT.Core.CheckGDKPRaidStatus() then
        return
    end

    local totalOwed = CalculateTotalOwed()
    if totalOwed > 0 then
        MemberAutoFillButton:Show()
        print(string.format(GDKPT.Core.print .. " Total Cost of all Won Auctions: %d gold. You have already paid %d gold.",
            totalOwed, GDKPT.Trading.totalPaid))
    else
        -- Only hide if there is truly no data
        if #GDKPT.Core.PlayerWonItems == 0 then
            MemberAutoFillButton:Hide()
            print(GDKPT.Core.errorprint .. "No auction data available. Please wait for leader sync.")
        end
    end
    MemberAutoFillButton:Show()
end



local function OnTradeOpened()

    -- Check if player is in a GDKP with GDKPT Leader
    if not GDKPT.Core.CheckGDKPRaidStatus() then
        return 
    end

    local partnerName = UnitName("NPC")
    if not partnerName then return end

    if partnerName ~= GDKPT.Utils.GetRaidLeaderName() then
        print(GDKPT.Core.errorprint .. "Careful: You're NOT trading with your raidleader!")
        return
    end

    -- Check if data is missing or stale
    local hasAuctions = #GDKPT.Core.PlayerWonItems > 0
    local potValue = GDKPT.Core.GDKP_Pot or 0
    if not hasAuctions or potValue == 0 then
        -- Request quick sync
        RequestQuickSyncOnTrade()

        -- Wait briefly for data to populate, then update button
        C_Timer.After(5, UpdateAutoFillButton)
    else
        -- Normal behavior
        UpdateAutoFillButton()
    end

end






-------------------------------------------------------------------
-- On Trade accept update
-------------------------------------------------------------------

local function OnTradeAcceptUpdate(playerAccepted, targetAccepted)
    -- Check if player is in a GDKP with GDKPT Leader
    if not GDKPT.Core.CheckGDKPRaidStatus() then
        return 
    end

    if playerAccepted == 1 then
        lastTradeMoney = GetPlayerTradeMoney() or 0
    end
end


-------------------------------------------------------------------
-- On Trade Completion
-------------------------------------------------------------------


local function OnTradeComplete()
    -- Check if player is in a GDKP with GDKPT Leader
    if not GDKPT.Core.CheckGDKPRaidStatus() then
        return 
    end

    if lastTradeMoney > 0 then
        local tradedGold = lastTradeMoney / 10000
        GDKPT.Trading.totalPaid = GDKPT.Trading.totalPaid + tradedGold
        print(string.format("|cff00ff00[GDKPT]|r You traded %d gold to the raid leader. Total paid so far: %d gold.",
            tradedGold, GDKPT.Trading.totalPaid))
        lastTradeMoney = 0
    end
end










-------------------------------------------------------------------
-- member trade Frame for Trade Events
-------------------------------------------------------------------
local memberTradeFrame = CreateFrame("Frame")
memberTradeFrame:RegisterEvent("TRADE_SHOW")
memberTradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
memberTradeFrame:RegisterEvent("UI_INFO_MESSAGE")



-------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------
memberTradeFrame:SetScript("OnEvent", function(self, event, ...)

    local isInRaid = IsInRaid()
    local lootMethod = select(1, GetLootMethod())

    if event == "TRADE_SHOW" and not GDKPT.Utils.IsPlayerMasterlooterOrRaidleader() then
        OnTradeOpened()
    elseif event == "TRADE_ACCEPT_UPDATE" then
        OnTradeAcceptUpdate(...)
    elseif event == "UI_INFO_MESSAGE" then
        local msg = select(1, ...)
        if msg == ERR_TRADE_COMPLETE then
            OnTradeComplete()
        end
    end
end)


