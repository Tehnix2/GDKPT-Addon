








GDKPT.Trading = {}




-------------------------------------------------------------------
-- Auto Fill Button for raid members
-------------------------------------------------------------------
local MemberAutoFillButton = CreateFrame("Button", "GDKPT_MemberAutoFillButton", TradeFrame, "UIPanelButtonTemplate")
MemberAutoFillButton:SetSize(100, 22)
MemberAutoFillButton:SetPoint("BOTTOM", TradeFrame, "BOTTOM", -60, 56)
MemberAutoFillButton:SetText("AutoFill")










-------------------------------------------------------------------
-- Calculate Total Amount Owed (needed for reloads)
-------------------------------------------------------------------
local function CalculateTotalOwed()
    local totalOwed = 0
    
    for _, item in ipairs(GDKPT.Core.PlayerWonItems) do
        -- Only count actual auction wins, not adjustments
        if not item.isAdjustment and not item.traded then
            local amountPaid = item.amountPaid or 0
            local totalCost = item.bid or 0
            local stillOwed = totalCost - amountPaid
            
            if stillOwed > 0 then
                totalOwed = totalOwed + stillOwed
            end
        end
    end
    
    return totalOwed
end







-------------------------------------------------------------------
-- Member AutoFill Button Click Handler
-------------------------------------------------------------------
local function OnAutoFillClick()

    if GDKPT.Core.Settings.AutoFillTradeGold == 0 then
        print("|cffff3333[GDKPT]|r Autofill button is not enabled!")
        return
    end

    local totalOwed = CalculateTotalOwed()

    if totalOwed <= 0 then
        print("|cffff3333[GDKPT]|r You have already paid up!")
        return
    end

    -- Convert gold to copper
    local copperAmount = totalOwed * 10000
    MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, copperAmount)
    print(string.format("|cff00ff00[GDKPT]|r Total Cost of all Won Auctions is %d gold. AutoFilled this amount.", totalOwed))
end

MemberAutoFillButton:SetScript("OnClick", OnAutoFillClick)




local function OnTradeOpened()

    local partnerName = UnitName("NPC")
    if not partnerName then return end

    if partnerName ~= GDKPT.Utils.GetRaidLeaderName() then
        print("|cffff3333[GDKPT]|r Careful: You're NOT trading with your raidleader!")
        return
    end

    local totalOwed = CalculateTotalOwed()

    if GDKPT.Core.PotSplitStarted == 0 then  -- still phase 1
        if totalOwed <= 0 then
            print("|cffff3333[GDKPT]|r You have already paid up!")
            MemberAutoFillButton:Hide()  
        else
            MemberAutoFillButton:Show()
            print(string.format("|cff00ff00[GDKPT]|r Total Cost of all Won Auctions is %d gold.", totalOwed))
        end
    elseif GDKPT.Core.PotSplitStarted == 1 then
        print(string.format("Pot Split: You will receive %d gold.",GDKPT.Core.PlayerCut/10000))
    end



end





-------------------------------------------------------------------
-- memer trade Frame for Trade Events
-------------------------------------------------------------------
local memberTradeFrame = CreateFrame("Frame")
memberTradeFrame:RegisterEvent("TRADE_SHOW")



-------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------
memberTradeFrame:SetScript("OnEvent", function(self, event, ...)

    local isInRaid = IsInRaid()
    local lootMethod = select(1, GetLootMethod())



    if event == "TRADE_SHOW" and not GDKPT.Utils.IsPlayerMasterlooterOrRaidleader() then
        OnTradeOpened()
    end
end)


