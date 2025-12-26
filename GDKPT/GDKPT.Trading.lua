GDKPT.Trading = {}

-------------------------------------------------------------------
-- Member Trade State Tracking
-------------------------------------------------------------------
local CurrentTradeSession = {
    isTradingWithLeader = false,
    goldInput = 0
}


-------------------------------------------------------------------
-- Auto Fill Button for raid members
-------------------------------------------------------------------

local MemberAutoFillButton = CreateFrame("Button", "GDKPT_AutoFillButton", TradeFrame, "UIPanelButtonTemplate")
MemberAutoFillButton:SetSize(150, 22)
MemberAutoFillButton:SetPoint("BOTTOM", TradeFrame, "BOTTOM", -75, 56)
MemberAutoFillButton:SetText("AutoFill")
MemberAutoFillButton:Disable()

GDKPT.Trading.MemberAutoFillButton = MemberAutoFillButton




-------------------------------------------------------------------
-- Member AutoFill Button Click Handler
-------------------------------------------------------------------

-- GDKPT.Core.MyBalance is negative if player still needs to pay
-- and positive if the player paid too much or gets gold from pot split

local function OnAutoFillClick()

    if not GDKPT.Core.MyBalance then
        print(GDKPT.Core.errorprint .. "Waiting for balance sync from leader...")
        return
    end

    -- Fully paid up 
    if GDKPT.Core.MyBalance == 0 then
        print(GDKPT.Core.print .. "Fully paid up!")
        return
    end

    -- PotSplit or overpaid, then balance will be positive
    if GDKPT.Core.MyBalance > 0 then
        print(string.format(GDKPT.Core.print .. "Getting %d gold from the leader!",GDKPT.Core.MyBalance))
        AcceptTrade()
        return
    end

    -- Still needs to pay to even the balance, so at this point balance is negative. Take abs
    local remaining = math.abs(GDKPT.Core.MyBalance)
    local playerCopper = GetMoney()                 -- amount of copper the player has
    local requiredCopper = remaining * 10000        -- amount of copper the player needs to pay up

    -- Check if player has enough gold on them
    if playerCopper < requiredCopper then
        local playerGold = floor(playerCopper / 10000)
        print(string.format(GDKPT.Core.errorprint .. "You only have %d gold, but you need %d gold to pay up.",playerGold, remaining))
        return
    end


    if GDKPT.Core.Settings.AutoFillTradeGold == 1 then
        MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, remaining*10000)
        print(string.format(GDKPT.Core.print .. "AutoFilled %d gold.", remaining))
    end

    if GDKPT.Core.Settings.AutoFillTradeAccept == 1 then
        AcceptTrade()
    else print(GDKPT.Core.errorprint .. "AutoFill Trade Accept is currently disabled in Settings.")
    end
end


MemberAutoFillButton:SetScript("OnClick", OnAutoFillClick)



-------------------------------------------------------------------
-- Request balance sync from leader when trade opens
-------------------------------------------------------------------

local function RequestMyBalanceSync()
    local leaderName = GDKPT.Utils.GetRaidLeaderName()
    if not leaderName then return end
    SendAddonMessage(GDKPT.Core.addonPrefix, "REQUEST_MY_BALANCE", "WHISPER", leaderName)
end




-------------------------------------------------------------------
-- When a raidmember opens a trade with the raidleader then update 
-- GDKPT.Core.MyBalance through a sync from the leaders balance
-------------------------------------------------------------------


local function OnTradeOpened()

    -- Check if player is in a GDKP with GDKPT Leader
    if not GDKPT.Core.CheckGDKPRaidStatus() then
        return 
    end

    -- Reset trade session state    
    CurrentTradeSession.isTradingWithLeader = false
    CurrentTradeSession.goldInput = 0



    local partnerName = UnitName("NPC")
    if not partnerName then return end

    if partnerName ~= GDKPT.Utils.GetRaidLeaderName() then
        print(GDKPT.Core.errorprint .. "Careful: You're NOT trading with your raidleader!")
        return
    end

    -- Mark this session as valid for tracking
    CurrentTradeSession.isTradingWithLeader = true

    print(GDKPT.Core.print .. "Fetching your balance data. This might take a moment...")
    -- Update GDKPT.Core.MyBalance based on a synced value from the raidleaders balance sheet
    RequestMyBalanceSync()
end


-------------------------------------------------------------------
-- Track Money Input by Player
-------------------------------------------------------------------

-- Fired when the trade partner has changed gold 
local function OnTradeMoneyChanged()
    if CurrentTradeSession.isTradingWithLeader then
        local copper = GetPlayerTradeMoney()
        CurrentTradeSession.goldInput = copper
    end
end


local function OnTradeAcceptUpdate(playerAccepted, targetAccepted)
    -- Capture the gold amount when player accepts
    if CurrentTradeSession.isTradingWithLeader then
        local copper = GetPlayerTradeMoney()
        if copper > 0 then
            CurrentTradeSession.goldInput = copper
        end
    end
end


-------------------------------------------------------------------
-- Handle Successful Trade Completion
-------------------------------------------------------------------
local function OnTradeCompleted()
    -- Capture one final time to be absolutely sure
    if CurrentTradeSession.isTradingWithLeader then
        local copper = GetPlayerTradeMoney()
        if copper > 0 then
            CurrentTradeSession.goldInput = copper
        end
        
        local goldTraded = math.floor(CurrentTradeSession.goldInput / 10000)
        
        if goldTraded > 0 then
            print(string.format(
                GDKPT.Core.print .. "Trade Complete: You gave %d gold to %s.", 
                goldTraded, 
                GDKPT.Utils.GetRaidLeaderName()
            ))
        end
    end
    
    -- Reset State AFTER we've used the values
    CurrentTradeSession.isTradingWithLeader = false
    CurrentTradeSession.goldInput = 0

    -- Update gold amount in UI 
    C_Timer.After(0.5, function()
        GDKPT.UI.UpdateCurrentGoldAmount()
    end)
end




-------------------------------------------------------------------
-- member trade Frame for Trade Events
-------------------------------------------------------------------
local memberTradeFrame = CreateFrame("Frame")
memberTradeFrame:RegisterEvent("TRADE_SHOW")
memberTradeFrame:RegisterEvent("TRADE_MONEY_CHANGED")
memberTradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
memberTradeFrame:RegisterEvent("UI_INFO_MESSAGE")
memberTradeFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")





-------------------------------------------------------------------
-- Event Handler
-------------------------------------------------------------------
memberTradeFrame:SetScript("OnEvent", function(self, event, ...)

    if event == "TRADE_SHOW" and not GDKPT.Utils.IsPlayerMasterlooterOrRaidleader() then
        OnTradeOpened()
    elseif event == "TRADE_MONEY_CHANGED" then
        OnTradeMoneyChanged()
    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted, targetAccepted = ...
        OnTradeAcceptUpdate(playerAccepted,targetAccepted)
    elseif event == "UI_INFO_MESSAGE" then
        local msg = select(1, ...)
        if msg == ERR_TRADE_COMPLETE then
            OnTradeCompleted()
        end
    end
end)

