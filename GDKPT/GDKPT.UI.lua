GDKPT.UI = {}

-------------------------------------------------------------------
-- Auction Window Setup
-------------------------------------------------------------------

local AuctionWindow = CreateFrame("Frame", "GDKP_Auction_Window", UIParent)
AuctionWindow:ClearAllPoints()
AuctionWindow:SetSize(900, 600)
AuctionWindow:SetScale(1.0)
AuctionWindow:SetMovable(true)
AuctionWindow:EnableMouse(true)
AuctionWindow:RegisterForDrag("LeftButton")
AuctionWindow:SetPoint("CENTER")
AuctionWindow:Hide()
AuctionWindow:SetFrameLevel(8)
AuctionWindow:SetBackdrop(
    {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 20,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    }
)
AuctionWindow:SetClampedToScreen(true)

AuctionWindow:SetScript("OnDragStart", AuctionWindow.StartMoving)
AuctionWindow:SetScript("OnDragStop", AuctionWindow.StopMovingOrSizing)

_G["GDKP_Auction_Window"] = AuctionWindow
tinsert(UISpecialFrames, "GDKP_Auction_Window")



AuctionWindow:SetScript(
    "OnHide",
    function()
        if IsInGroup() or IsInRaid() then
            GDKPT.ToggleLayout.UpdateToggleButtonVisibility()
        end
    end
)




local CloseAuctionWindowButton = CreateFrame("Button", "CloseAuctionWindowButton", AuctionWindow, "UIPanelCloseButton")
CloseAuctionWindowButton:SetPoint("TOPRIGHT", AuctionWindow, "TOPRIGHT", 5, 5)
CloseAuctionWindowButton:SetSize(30, 30)


local AuctionWindowTitleBar = CreateFrame("Frame", "", AuctionWindow, nil)
AuctionWindowTitleBar:SetSize(150, 25)
AuctionWindowTitleBar:SetBackdrop(
    {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        edgeSize = 16,
        tileSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    }
)
AuctionWindowTitleBar:SetPoint("TOP", AuctionWindow, "TOP", 0, 15)

local AuctionWindowTitleText = AuctionWindowTitleBar:CreateFontString("")
AuctionWindowTitleText:SetFont("Fonts\\FRIZQT__.TTF", 14)
AuctionWindowTitleText:SetText("|cffFFC125GDKPT " .. "- v " .. GDKPT.Core.version .. "|r")
AuctionWindowTitleText:SetPoint("CENTER", 0, 0)








-------------------------------------------------------------------
-- Scroll Frame that holds all auctions
-------------------------------------------------------------------

local AuctionScrollFrame = CreateFrame("ScrollFrame", "GDKP_Auction_ScrollFrame", AuctionWindow, "UIPanelScrollFrameTemplate")
AuctionScrollFrame:SetPoint("TOPLEFT", AuctionWindow, "TOPLEFT", 5, -40)
AuctionScrollFrame:SetPoint("BOTTOMRIGHT", AuctionWindow, "BOTTOMRIGHT", -30, 55)
AuctionScrollFrame:Show()


local AuctionContentFrame = CreateFrame("Frame", "GDKP_Auction_ContentFrame", AuctionScrollFrame)
AuctionContentFrame:SetWidth(AuctionScrollFrame:GetWidth()-5)
AuctionScrollFrame:SetScrollChild(AuctionContentFrame)

------------------------------------------------------------------------------------
-- Sync Button
------------------------------------------------------------------------------------

local SyncButton = CreateFrame("Button", "GDKP_SyncSettingsButton", AuctionWindow, "UIPanelButtonTemplate")
SyncButton:SetSize(250, 40)
SyncButton:SetPoint("CENTER", 0, 0)
SyncButton:SetText("Synchronize Auctions")
SyncButton:Show() 


local ArrowFrame = CreateFrame("Frame", nil, AuctionWindow)
ArrowFrame:SetSize(200, 200) 
ArrowFrame:SetPoint("CENTER", SyncButton, "CENTER", 0, 5)

local ArrowTexture = ArrowFrame:CreateTexture(nil, "OVERLAY")
ArrowTexture:SetTexture("Interface\\Icons\\ability_blackhand_marked4death") 
ArrowTexture:SetVertexColor(1, 1, 1) 
ArrowTexture:SetSize(64, 64)
ArrowTexture:SetPoint("CENTER", ArrowFrame, "CENTER", 0, 60)

local ArrowText = ArrowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
ArrowText:SetText("CLICK THIS BUTTON")
ArrowText:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
ArrowText:SetTextColor(1, 1, 1, 1)
ArrowText:SetPoint("CENTER", ArrowTexture, "CENTER", 0, 80)

local ag = ArrowFrame:CreateAnimationGroup()

local fadeOut = ag:CreateAnimation("Alpha")
fadeOut:SetOrder(1)
fadeOut:SetDuration(0.6)
fadeOut:SetChange(-0.7)
fadeOut:SetSmoothing("IN_OUT")

local fadeIn = ag:CreateAnimation("Alpha")
fadeIn:SetOrder(2)
fadeIn:SetDuration(0.6)
fadeIn:SetChange(0.7)
fadeIn:SetSmoothing("IN_OUT")

ag:SetLooping("REPEAT")
ag:Play()


local function RequestSync(self)
    local leaderName = GDKPT.Utils.GetRaidLeaderName()

    if IsInRaid() and leaderName then

        GDKPT.Utils.DisableAllBidding()

        ArrowTexture:Hide()
        ArrowText:Hide()
        local msg = "REQUEST_SETTINGS_SYNC"
        SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")

        self:SetText("Request Sent...")

        C_Timer.After(1,function()
            local msg2 = "REQUEST_AUCTION_SYNC"
            SendAddonMessage(GDKPT.Core.addonPrefix, msg2, "RAID")
        end)

        self:Disable()

        local frame = CreateFrame("Frame")
        local elapsed = 0
        frame:SetScript(
            "OnUpdate",
            function(self, delta)
                elapsed = elapsed + delta
                if elapsed >= 5.0 then
                    self:SetScript("OnUpdate", nil)
                    if not GDKPT.Core.leaderSettings.isSet then
                        SyncButton:Enable()
                        SyncButton:SetText("Syncing...")
                    end
                end
            end
        )
        print(GDKPT.Core.print .. "Auctions and Auction Parameters are now getting synchronized.")
    else
        print(GDKPT.Core.errorprint .. "You need to be in a raid with a raidleader running the [GDKPT Leader] addon to synchronize auctions.")
    end
end

SyncButton:SetScript("OnClick", RequestSync)




-------------------------------------------------------------------
-- Bottom Info Panel 
-------------------------------------------------------------------

local BottomInfoPanel = CreateFrame("Frame", "GDKP_BottomInfoPanel", AuctionWindow)
BottomInfoPanel:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", 0, 0 )
BottomInfoPanel:SetSize(AuctionWindow:GetWidth(), 50)
BottomInfoPanel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 12,
    insets = {left=5,right=5,top=5,bottom=5}
})
BottomInfoPanel:SetBackdropColor(0,0,0,0.5)


local function CreateInfoPanelEntry(parent, labelText, valueText, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    label:SetText(labelText)

    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    value:SetText(valueText or "")

    return label, value
end


local _, TotalPotAmountText = CreateInfoPanelEntry(BottomInfoPanel, "Total Pot", "", 10, 10)
local CurrentCutLabel, CurrentCutAmountText = CreateInfoPanelEntry(BottomInfoPanel, "Current Cut", "", 220, 10)
local _, CurrentGoldAmountText = CreateInfoPanelEntry(BottomInfoPanel, "Current Gold", "", 430, 10)


-------------------------------------------------------------------
-- Total Bid Cap
-------------------------------------------------------------------

local TotalBidCapLabel, _ = CreateInfoPanelEntry(BottomInfoPanel, "Total Bid Cap", "", 640, 10)


TotalBidCapInput = CreateFrame("EditBox", nil, AuctionWindow)
TotalBidCapInput:SetParent(BottomInfoPanel)
TotalBidCapInput:SetAutoFocus(false)
TotalBidCapInput:SetNumeric(true)
TotalBidCapInput:EnableMouse(true)
TotalBidCapInput:SetPoint("TOPLEFT", TotalBidCapLabel, "BOTTOMLEFT", 0, -2)
TotalBidCapInput:SetSize(80, 20)
TotalBidCapInput:SetText("") 
TotalBidCapInput:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = {left=2,right=2,top=2,bottom=2}
})
TotalBidCapInput:SetBackdropColor(0,0,0,0.5)
TotalBidCapInput:SetTextInsets(4,4,0,0)
TotalBidCapInput:SetFontObject(GameFontHighlight)


TotalBidCapInput:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()

    local cap = tonumber(self:GetText()) or 0
    if cap < 0 then
        print(GDKPT.Core.errorprint .. "This is not a valid bid cap. Must be non-negative.")
        return
    end

    if cap == 0 then 
        print(GDKPT.Core.print .. "Bid Cap disabled")
        return
    end

    if cap == 90 then 
        print(GDKPT.Core.print .. "Is this really the best you can do?") 
        return
    end

    print(string.format(GDKPT.Core.print .. "You can now only bid a total of %d Gold.", cap))
end)

TotalBidCapInput:SetScript(
        "OnEscapePressed",
        function(self)
            self:ClearFocus()
        end
    )



-------------------------------------------------------------------
-- My Bids
-------------------------------------------------------------------

local _, MyBidsText = CreateInfoPanelEntry(BottomInfoPanel, "My Bids", "", 770, 10)

GDKPT.UI.MyBidsText = MyBidsText




-------------------------------------------------------------------
-- Functions to update the data on the bottom info panel
-------------------------------------------------------------------

function GDKPT.UI.UpdateTotalPotAmount(totalPotValue)
    GDKPT.Core.GDKP_Pot = tonumber(totalPotValue) or 0 
    TotalPotAmountText:SetText(string.format("%s", GDKPT.Utils.FormatMoney(GDKPT.Core.GDKP_Pot)))
end

function GDKPT.UI.UpdateCurrentCutAmount(currentCutValue) 
    local cut = tonumber(currentCutValue) or 0
    GDKPT.Core.PlayerCut = cut 
    CurrentCutAmountText:SetText(string.format("%s", GDKPT.Utils.FormatMoney(cut)))

    -- Update the label with current split count
    local splitCount = GDKPT.Utils.GetCurrentSplitCount()
    CurrentCutLabel:SetText(string.format("Current Cut (%d Players)", splitCount))

end

function GDKPT.UI.UpdateCurrentGoldAmount()
    CurrentGoldAmountText:SetText(GDKPT.Utils.FormatMoney(GetMoney()))
end




-------------------------------------------------------------------
-- Function to show the auction window, called through /gdkp show
-- or the toggle button
-------------------------------------------------------------------

function GDKPT.UI.ShowAuctionWindow()
    AuctionWindow:Show()
    GDKPT.UI.UpdateCurrentGoldAmount()

    -- Apply current layout and check sync status
    if GDKPT.ToggleLayout.currentLayout then
        GDKPT.ToggleLayout.SetLayout(GDKPT.ToggleLayout.currentLayout)
    end
end








-------------------------------------------------------------------
-- Dynamically update Current Cut when raid roster changes
-------------------------------------------------------------------

local cutUpdateFrame = CreateFrame("Frame")
cutUpdateFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
cutUpdateFrame:RegisterEvent("RAID_ROSTER_UPDATE")
cutUpdateFrame:SetScript("OnEvent", function(self, event)
    if event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" then
        -- Only update if we have valid pot data and settings
        if GDKPT.Core.GDKP_Pot > 0 and GDKPT.Core.leaderSettings.isSet then
            local splitCount = IsInRaid() and GetNumRaidMembers() or 1
            if splitCount > 0 then
                GDKPT.UI.UpdateCurrentCutAmount((GDKPT.Core.GDKP_Pot * 10000) / splitCount)
            end
        end
    end
end)






-------------------------------------------------------
-- Notification frame 
-------------------------------------------------------


local OutbidMessageFrame = CreateFrame("Frame", "GDKPT_OutbidMessageFrame", AuctionWindow)
OutbidMessageFrame:SetSize(760, 25)
OutbidMessageFrame:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", 0, -35)
OutbidMessageFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets = {left = 2, right = 2, top = 2, bottom = 2}
})
OutbidMessageFrame:SetBackdropColor(0.8, 0.2, 0.2, 0.7)
OutbidMessageFrame:SetBackdropBorderColor(1, 0, 0, 1)
OutbidMessageFrame:Hide()

OutbidMessageFrame.Text = OutbidMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
OutbidMessageFrame.Text:SetPoint("CENTER")
OutbidMessageFrame.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

GDKPT.UI.OutbidMessageFrame = OutbidMessageFrame


function GDKPT.UI.ShowOutbidMessage(auctionId, itemLink, newBidder, newBid)
    local frame = GDKPT.UI.OutbidMessageFrame
    if not frame then return end
    
    local message = string.format("You've been OUTBID on Auction #%d (%s) by %s with %d g!", 
        auctionId, itemLink, newBidder, newBid)
    
    frame.Text:SetText(message)
    frame:Show()
        
    C_Timer.After(10, function()
        frame:Hide()
    end)
end



-------------------------------------------------------------------
-- Function to visually reset the auction window
-------------------------------------------------------------------

function GDKPT.UI.ResetAuctionWindow()
    local children = {GDKPT.UI.AuctionContentFrame:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    
    if GDKPT.UI.AuctionScrollFrame and GDKPT.UI.AuctionScrollFrame.ScrollBar then
        GDKPT.UI.AuctionScrollFrame.ScrollBar:SetValue(0)
    end
    
    GDKPT.UI.AuctionContentFrame:SetHeight(100)
end





-------------------------------------------------------------------
-- Periodically check if player is in a GDKP. If not, just  hide the 
-- Toggle Button
-------------------------------------------------------------------

local statusCheckFrame = CreateFrame("Frame")
statusCheckFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 60 then -- Check every 60 seconds
        self.elapsed = 0
        if GDKPT.Core.CheckGDKPRaidStatus() then
            -- Enable UI Elements
            if not GDKPToggleButton.gdkpEnabled then
                GDKPToggleButton.gdkpEnabled = true
                -- Show relevant UI
                GDKPToggleButton:Show()
            end
        else
            -- Disable UI elements
            if GDKPToggleButton.gdkpEnabled then
                GDKPToggleButton.gdkpEnabled = false
                GDKPToggleButton:Hide()
            end
        end
    end
end)






function GDKPT.UI.UpdateMyBidsDisplay(value)
    GDKPT.UI.MyBidsText:SetText(value)
    
    -- Update compact panel if it exists and is visible
    if GDKPT.UI.AuctionWindow.CompactBottomPanel and GDKPT.UI.AuctionWindow.CompactBottomPanel:IsVisible() then
        GDKPT.UI.AuctionWindow.CompactBottomPanel.MyBidsText:SetText(value)
    end
end













-------------------------------------------------------------------
-- Frame and Function exposing for other files
-------------------------------------------------------------------


GDKPT.UI.AuctionWindow = AuctionWindow
GDKPT.UI.AuctionWindowTitleBar = AuctionWindowTitleBar
GDKPT.UI.AuctionWindowTitleText = AuctionWindowTitleText
GDKPT.UI.AuctionContentFrame = AuctionContentFrame
GDKPT.UI.BottomInfoPanel = BottomInfoPanel

GDKPT.UI.FavoriteFilterButton = FavoriteFilterButton
GDKPT.UI.SyncButton = SyncButton
GDKPT.UI.AuctionScrollFrame = AuctionScrollFrame
GDKPT.UI.WonAuctionsFrame = WonAuctionsFrame
GDKPT.UI.ArrowFrame = ArrowFrame
GDKPT.UI.ArrowText = ArrowText

GDKPT.UI.TotalBidCapInput = TotalBidCapInput

