GDKPT.InfoButton = {}

local lastClickTime = 0



-------------------------------------------------------------------
-- Info Button
-------------------------------------------------------------------


local InfoButton = CreateFrame("Button", "GDKP_InfoButton", GDKPT.UI.AuctionWindow, "UIPanelButtonTemplate")
InfoButton:SetSize(20, 20)
InfoButton:SetPoint("TOPLEFT", GDKPT.UI.AuctionWindow, "TOPLEFT", 0, 5)

local InfoButtonIcon = InfoButton:CreateTexture(nil, "OVERLAY")
InfoButtonIcon:SetSize(16, 16) 
InfoButtonIcon:SetPoint("CENTER")
InfoButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")



function GDKPT.InfoButton.UpdateInfoButtonStatus()
    local isSynced = GDKPT.Core.leaderSettings and GDKPT.Core.leaderSettings.isSet

    if isSynced then
        InfoButtonIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    else
        InfoButtonIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    end
end

GDKPT.InfoButton.UpdateInfoButtonStatus() 



local function CanUseInfoButton()
    local now = GetTime()
    local remaining = 10 - (now - lastClickTime)
    if remaining > 0 then
        print(string.format(GDKPT.Core.errorprint .. "Please wait %.1f seconds before clicking again!", remaining))
        return false
    end
    lastClickTime = now
    return true
end



local function HideAllAuctionRows()
    for _, row in pairs(GDKPT.Core.AuctionFrames) do
        if row then
            row:Hide()
        end
    end
end

local function RequestSettingsSync()
    local msg = "REQUEST_SETTINGS_SYNC"
    SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")
end

local function RequestAuctionSync()
    local msg = "REQUEST_AUCTION_SYNC"
    SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")
end



function GDKPT.InfoButton.HandleInfoButtonClick(button)
    if not CanUseInfoButton() then
        return
    end

    InfoButton:Disable()
    C_Timer.After(10, function()
        InfoButton:Enable()
    end)

    GDKPT.Utils.DisableAllBidding()

    if button == "LeftButton" then
        RequestSettingsSync()
    elseif button == "RightButton" then
        HideAllAuctionRows()
        RequestAuctionSync()
    end
end



InfoButton:SetScript("OnClick", function(self, button)
    GDKPT.InfoButton.HandleInfoButtonClick(button)
end)





InfoButton:SetScript(
    "OnEnter",
    function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        GameTooltip:AddLine("GDKPT Auction Settings", 1, 1, 1)

        if GDKPT.Core.leaderSettings and GDKPT.Core.leaderSettings.isSet then
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("Duration: |cffffd100" .. GDKPT.Core.leaderSettings.duration .. " sec|r", 1, 1, 1)
            GameTooltip:AddLine("Extra Time/Bid: |cffffd100" .. GDKPT.Core.leaderSettings.extraTime .. " sec|r", 1, 1, 1)
            GameTooltip:AddLine("Starting Bid: |cffffd100" .. GDKPT.Core.leaderSettings.startBid .. " gold|r", 1, 1, 1)
            GameTooltip:AddLine("Min Increment: |cffffd100" .. GDKPT.Core.leaderSettings.minIncrement .. " gold|r", 1, 1, 1)
            GameTooltip:AddLine("Split Count: |cffffd100" .. GDKPT.Core.leaderSettings.splitCount .. " players|r", 1, 1, 1)
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cff00ff00Auctions are synced|r", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("|cff00ff00Right click for re-sync (10sec cd)|r", 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cffff0000Settings Not Synced|r", 1, 0, 0)
            GameTooltip:AddLine("Press the Sync request button in the middle", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("or left-click the info button!", 0.8, 0.8, 0.8)
        end

        GameTooltip:Show()
    end
)

InfoButton:SetScript(
    "OnLeave",
    function()
        GameTooltip:Hide()
    end
)


