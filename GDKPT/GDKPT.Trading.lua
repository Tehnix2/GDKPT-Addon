GDKPT.Trading = GDKPT.Trading or {}
GDKPT.Trading.TotalPaid = GDKPT.Trading.TotalPaid or 0

local paidGoldOnTrade = 0
local tradeHandled = false





-------------------------------------------------------------------
-- Adding an autofill button to the trade window
-------------------------------------------------------------------


local autoPayButton = CreateFrame("Button", "GDKPT_AutoTradeButton", TradeFrame, "UIPanelButtonTemplate")
autoPayButton:SetSize(100, 22)
autoPayButton:SetPoint("TOP", TradeFrame, "TOP", -60, -45)
autoPayButton:SetNormalFontObject("GameFontNormal")
autoPayButton:SetHighlightFontObject("GameFontHighlight")
autoPayButton:SetText("Autofill")
autoPayButton:Hide()








------------------------------------------------------------
-- Hook Trade Events, make sure the frame only exists once
------------------------------------------------------------
if not GDKPTradeFrame then
    GDKPTradeFrame = CreateFrame("Frame")
    GDKPTradeFrame:UnregisterAllEvents()
    GDKPTradeFrame:RegisterEvent("TRADE_SHOW")
    GDKPTradeFrame:RegisterEvent("TRADE_CLOSED")
end


--GDKPTradeFrame:RegisterEvent("UI_INFO_MESSAGE")



------------------------------------------------------------
-- Track gold inserted during this trade
------------------------------------------------------------

GDKPTradeFrame:SetScript("OnUpdate", function(self, elapsed)
    if TradeFrame:IsShown() then
        paidGoldOnTrade = GetPlayerTradeMoney() / 10000
        local tradeHandled = false
    else
        paidGoldOnTrade = 0
    end
end)






------------------------------------------------------------
-- Calculate the total unpaid amount for won auctions
------------------------------------------------------------

local function CalculateUnpaidAmount()
    local totalOwed = 0
    local itemsWithDebt = {}

    for _, item in ipairs(GDKPT.Core.PlayerWonItems or {}) do
        if not item.isAdjustment and not item.wasAdjusted then
            local amountPaid = item.amountPaid or 0
            local totalCost = item.bid or 0
            local amountOwed = totalCost - amountPaid
            
            if amountOwed > 0 then
                totalOwed = totalOwed + amountOwed
                table.insert(itemsWithDebt, item)
            end
        end
    end

    --[[
    for i, item in ipairs(itemsWithDebt) do
        print(string.format("Item %d: %s, total bid: %d, amountPaid: %d", 
            i, item.name or "unknown", item.bid or 0, item.amountPaid or 0))
    end
    ]]

    return totalOwed
end


-------------------------------------------------------------------
-- Calculate remaining amount to pay
-------------------------------------------------------------------
local function GetRemainingOwed()
    local totalOwed = CalculateUnpaidAmount()
    local remaining = totalOwed - GDKPT.Trading.TotalPaid
    if remaining < 0 then
        remaining = 0
    end
    return remaining
end






------------------------------------------------------------
-- Function that gets called when trade is getting closed
------------------------------------------------------------


local function HandleTradeClosed()
    if tradeHandled then return end 
    tradeHandled = true

    if paidGoldOnTrade > 0 then
        -- Distribute payment across items (FIFO)
        local remainingPayment = paidGoldOnTrade
        
        for _, item in ipairs(GDKPT.Core.PlayerWonItems) do
            if remainingPayment <= 0 then break end
            
            if not item.isAdjustment and not item.wasAdjusted then
                local amountPaid = item.amountPaid or 0
                local totalCost = item.bid or 0
                local amountOwed = totalCost - amountPaid
                
                if amountOwed > 0 then
                    local payment = math.min(remainingPayment, amountOwed)
                    item.amountPaid = amountPaid + payment
                    remainingPayment = remainingPayment - payment
                    
                    print(string.format("|cff00ff00[GDKPT]|r Paid %dg towards %s (now %dg/%dg paid)", 
                        payment, item.name or "item", item.amountPaid, totalCost))
                end
            end
        end
        
        GDKPT.Trading.TotalPaid = GDKPT.Trading.TotalPaid + paidGoldOnTrade
        
        -- Update display
        if GDKPT.AuctionEnd.UpdateWonItemsDisplay and GDKPT.UI.AuctionWindow.WonAuctionsFrame then
            GDKPT.AuctionEnd.UpdateWonItemsDisplay(GDKPT.UI.AuctionWindow.WonAuctionsFrame)
        end
    end

    local remaining = GetRemainingOwed()
    if remaining > 0 then
        print(string.format("|cffffcc00[GDKPT]|r You still owe %.0f gold.", remaining))
    else
        print("|cff00ff00[GDKPT]|r All paid up!")
    end

    paidGoldOnTrade = 0
end


--[[

local function HandleTradeClosed()
    if tradeHandled then return end 
    tradeHandled = true

    if paidGoldOnTrade > 0 then
        GDKPT.Trading.TotalPaid = GDKPT.Trading.TotalPaid + paidGoldOnTrade
    end

    local remaining = GetRemainingOwed()
    print(string.format("|cffffcc00[GDKPT]|r You still owe %.0f gold for your auctions.", remaining))

    paidGoldOnTrade = 0
end

]]


-------------------------------------------------------------------
-- Autofill Functionality
-------------------------------------------------------------------

local function AutofillGold()
    local remaining = GetRemainingOwed()
    if remaining <= 0 then
        print("|cffff3333[GDKPT]|r You have already contributed enough to the total gold pot!")
        return
    end

    local copperAmount = remaining * 10000
    MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, copperAmount)
    print(string.format("|cff00ff00[GDKPT]|r Autofilled %.0f gold into the trade window.", remaining))

    AcceptTrade()
end

autoPayButton:SetScript("OnClick", AutofillGold)





GDKPTradeFrame:SetScript("OnEvent", function(self, event, ...)

    if event == "TRADE_SHOW" then
        if not GDKPT.Utils.IsPlayerMasterlooterOrRaidleader() then
            autoPayButton:Show()
        end

        tradeHandled = false

        local remaining = GetRemainingOwed()

        if remaining > 0 then
            print(string.format("|cff00ff00[GDKPT]|r You still need to contribute %d gold to the total gold pot for your won auction.", remaining))
        else
            print("|cffff3333[GDKPT]|r You have already contributed enough to the total gold pot!")
        end

    end
   
    if event == "TRADE_CLOSED" then
        print("trade ended")
        HandleTradeClosed()
    end

    if event == "UI_INFO_MESSAGE" then
        print("ui info message")
        
    end

end)










































--[[










-- Internal state tracking
GDKPT.RaidMember = GDKPT.RaidMember or {}
GDKPT.RaidMember.UnpaidItems = GDKPT.RaidMember.UnpaidItems or {}



------------------------------------------------------------
-- Function: Prepare trade autofill for payment
------------------------------------------------------------

-- Add a variable to store the initial owed amount for the current trade
GDKPT.RaidMember.CurrentTradeTotalOwed = 0


function GDKPT.RaidMember.PrepareAutoPay(partner)
    local totalOwed, itemsWithDebt = CalculateUnpaidAmount()
    GDKPT.CurrentTradeTotalOwed = totalOwed -- Store the total

    if totalOwed <= 0 then
        print("|cffff3333[GDKPT]|r You have no unpaid auctions.")
        autoPayButton:Hide()
        return
    end

    autoPayButton:SetText(string.format("Pay %dg", totalOwed))
    autoPayButton:SetScript("OnClick", function()
        local copperAmount = totalOwed * 10000
        MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, copperAmount)
        print(string.format("|cff00ff00[GDKPT]|r Auto-filled %dg owed to %s.", totalOwed, partner))
        
        if GDKPT.Core.Settings.AutoFillTradeGold == 1 then
            AcceptTrade()
        end
    end)

    autoPayButton:Show()
end

------------------------------------------------------------
-- Function: Record a payment made during trade
------------------------------------------------------------
local function RecordPayment(amountPaidGold)
    if amountPaidGold <= 0 then return end
    
    local remainingPayment = amountPaidGold
    
    -- Distribute payment across unpaid items (FIFO order)
    for _, item in ipairs(GDKPT.Core.PlayerWonItems) do
        if remainingPayment <= 0 then break end
        
        if not item.isAdjustment and not item.wasAdjusted then
            local amountPaid = item.amountPaid or 0
            local totalCost = item.bid or 0
            local amountOwed = totalCost - amountPaid
            
            if amountOwed > 0 then
                local paymentForThisItem = math.min(remainingPayment, amountOwed)
                item.amountPaid = amountPaid + paymentForThisItem
                remainingPayment = remainingPayment - paymentForThisItem
                
                print(string.format("|cff00ff00[GDKPT]|r Paid %dg towards %s (total paid: %dg / %dg)", 
                    paymentForThisItem, item.name or "item", item.amountPaid, totalCost))
            end
        end
    end

    -- Update the display immediately
    GDKPT.AuctionEnd.UpdateWonItemsDisplay(GDKPT.UI.AuctionWindow.WonAuctionsFrame)

    -- Force recalculate the button if trade window is still open (shouldn't be, but just in case)
    local newTotalOwed, _ = CalculateUnpaidAmount()
    if newTotalOwed > 0 then
        autoPayButton:SetText(string.format("Pay %dg", newTotalOwed))
    else
        autoPayButton:Hide()
    end
    
    -- Send payment notification to leader
    local leaderName = GDKPT.Utils.GetRaidLeaderName()
    if leaderName then
        local msg = string.format("PAYMENT:%d", amountPaidGold)
        SendAddonMessage(GDKPT.Core.addonPrefix, msg, "WHISPER", leaderName)
    end
    
    GDKPT.AuctionEnd.UpdateWonItemsDisplay(GDKPT.UI.AuctionWindow.WonAuctionsFrame)
end







-- Track trade gold for detecting payments
local tradeGoldTracking = {
    theirGold = 0,
    myGold = 0
}

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "TRADE_SHOW" then
        local lootMethod, masterLooterPartyID = GetLootMethod()
        local playerName = UnitName("player")
        local inRaid = IsInRaid()
        local isMasterLooter = false

        -- Determine master looter
        if lootMethod == "master" then
            if inRaid and masterLooterPartyID then
                local name = select(1, GetRaidRosterInfo(masterLooterPartyID))
                if name == playerName then
                    isMasterLooter = true
                end
            elseif not inRaid then
                isMasterLooter = true
            end
        end

        local raidLeaderName = GDKPT.Utils.GetRaidLeaderName()
        local isRaidLeader = (raidLeaderName == playerName)

        if isMasterLooter or isRaidLeader then
            autoPayButton:Hide()
            return
        end

        local targetName = GetUnitName("NPC") or GetUnitName("target") or "Raid Leader"
        GDKPT.RaidMember.PrepareAutoPay(targetName)
        
        -- Reset tracking
        tradeGoldTracking.theirGold = 0
        tradeGoldTracking.myGold = 0

    elseif event == "TRADE_ACCEPT_UPDATE" then
        -- Capture the gold being traded when player accepts
        print("trade accept event")
        local myGold = GetPlayerTradeMoney()
        tradeGoldTracking.myGold = math.floor(myGold / 10000) -- Convert copper to gold
        
    elseif event == "UI_INFO_MESSAGE" then
        local msg = select(1, ...)
        if msg == ERR_TRADE_COMPLETE then
            -- Trade completed - record the payment
            if tradeGoldTracking.myGold > 0 then
                RecordPayment(tradeGoldTracking.myGold)
            end
            tradeGoldTracking.myGold = 0
            tradeGoldTracking.theirGold = 0
        end
        
    elseif event == "TRADE_CLOSED" then
        print("trade closed event")
        GDKPT.RaidMember.HideAutoPayButton()
        tradeGoldTracking.myGold = 0
        tradeGoldTracking.theirGold = 0
    end
end)



]]