GDKPT.ToggleLayout = {}

GDKPT.ToggleLayout.currentLayout = "full"       -- default layout


-------------------------------------------------------------------
-- Toggle Button Setup
-------------------------------------------------------------------

local GDKPToggleButton = CreateFrame("Button", "GDKPToggleButton", UIParent)
GDKPToggleButton:SetSize(40, 40)
GDKPToggleButton:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
GDKPToggleButton:SetMovable(true)
GDKPToggleButton:EnableMouse(true)
GDKPToggleButton:RegisterForDrag("LeftButton")
GDKPToggleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
GDKPToggleButton:SetFrameStrata("MEDIUM") 
GDKPToggleButton:SetClampedToScreen(true)



local toggleIcon = GDKPToggleButton:CreateTexture(nil, "ARTWORK")
toggleIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
toggleIcon:SetAllPoints()

local toggleHighlight = GDKPToggleButton:CreateTexture(nil, "HIGHLIGHT")
toggleHighlight:SetAllPoints()
toggleHighlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
toggleHighlight:SetBlendMode("ADD")

local buttonText = GDKPToggleButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
buttonText:SetPoint("CENTER", 0, 30)
buttonText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
buttonText:SetText("GDKPT")


-------------------------------------------------------------------
-- Button Drag Handling: Save position in settings on stop
-------------------------------------------------------------------

GDKPToggleButton:SetScript("OnDragStart", GDKPToggleButton.StartMoving)

GDKPToggleButton:SetScript("OnDragStop",
    function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        local settings = GDKPT.Core.Settings
        if settings then
            settings.toggleButtonPos = {x = x, y = y, anchor = point}
        end
    end
)



-------------------------------------------------------------------
-- Reload the ToggleButton saved position when the addon is loaded
-------------------------------------------------------------------

function GDKPT.ToggleLayout.LoadToggleButtonPosition()
    local pos = GDKPT.Core.Settings and GDKPT.Core.Settings.toggleButtonPos

    if pos and pos.anchor then
        GDKPToggleButton:ClearAllPoints()
        GDKPToggleButton:SetPoint(pos.anchor, UIParent, pos.anchor, pos.x, pos.y)
    end
end


-------------------------------------------------------------------
-- Function to check the raid status and update visibility
-------------------------------------------------------------------

function GDKPT.ToggleLayout.UpdateToggleButtonVisibility()
    if not IsInRaid() then
        GDKPToggleButton:Hide()
    elseif GDKPT.UI.AuctionWindow:IsVisible() then
        GDKPToggleButton:Hide()
    elseif GDKPT.Core.Settings.HideToggleInCombat == 1 and UnitAffectingCombat("player") then
        GDKPToggleButton:Hide()
    else
        GDKPToggleButton:Show()
    end
end






-------------------------------------------------------------------
-- Mouseover Tooltip for the ToggleButton
-------------------------------------------------------------------

GDKPToggleButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cff00ff00GDKPT Toggle Button|r")
    GameTooltip:AddLine("")
    GameTooltip:AddLine("|cffFFD700Left Click|r: Auction Window in Full Mode")
    GameTooltip:AddLine("|cffFFD700Right Click|r: Auction Window in Compact Mode")
    GameTooltip:AddLine("|cffFFD700Hold & Drag Left Click|r: Move this Button")
    GameTooltip:Show()
end)

GDKPToggleButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)



-------------------------------------------------------------------
-- Function to adjust the auction rows to the current layout mode
-------------------------------------------------------------------

function GDKPT.ToggleLayout.SetRowLayout(row, mode)
    if not row then return end

    if mode == "full" then
        row:SetHeight(55)
        row:SetWidth(GDKPT.UI.AuctionContentFrame:GetWidth())
        
        -- Icon positioning (restore original)
        row.icon:SetSize(40, 40)
        row.iconFrame:SetSize(40, 40)
        row.icon:ClearAllPoints()
        row.icon:SetPoint("LEFT", 40, 0)
        row.iconFrame:ClearAllPoints()
        row.iconFrame:SetPoint("CENTER", row.icon, "CENTER")
        
        -- Stack text (restore original)
        if row.stackText then 
            row.stackText:ClearAllPoints()
            row.stackText:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", -2, 2)
            row.stackText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            if row.stackCount and row.stackCount > 1 then
                row.stackText:Show()
            else
                row.stackText:Hide()
            end
        end
        
        -- Auction number (restore original)
        row.auctionNumber:ClearAllPoints()
        row.auctionNumber:SetPoint("LEFT", 10, 8)
        row.auctionNumber:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
        row.auctionNumber:SetText(row.auctionId or "")
        row.auctionNumber:SetWidth(0)
        row.auctionNumber:Show()
        
        -- Favorite button (restore original)
        row.favoriteButton:SetSize(15, 15)
        row.favoriteButton:ClearAllPoints()
        row.favoriteButton:SetPoint("TOP", row.auctionNumber, "BOTTOM", 0, -5)
        row.favoriteButton:Show()
        
        -- Item button and link text (restore original)
        row.itemButton:SetSize(250, 20)
        row.itemButton:ClearAllPoints()
        row.itemButton:SetPoint("LEFT", row.icon, "RIGHT", 40, 8)
        row.itemLinkText:ClearAllPoints()
        row.itemLinkText:SetAllPoints()
        row.itemLinkText:SetFont("Fonts\\FRIZQT__.TTF", 14)
        row.itemLinkText:SetJustifyH("LEFT")
        -- Restore the item link text if it was hidden in compact mode
        if row.itemLink then
            local itemName, itemLinkColored = GetItemInfo(row.itemLink)
            if itemLinkColored then
                if row.stackCount and row.stackCount > 1 then
                    row.itemLinkText:SetText(itemLinkColored .. " |cffaaaaaa[x" .. row.stackCount .. "]|r")
                else
                    row.itemLinkText:SetText(itemLinkColored)
                end
            end
        end
        
        -- Timer (restore original)
        row.timerText:ClearAllPoints()
        row.timerText:SetPoint("LEFT", row.itemButton, "LEFT", 0, -20)
        row.timerText:SetFont("Fonts\\FRIZQT__.TTF", 12)
        row.timerText:SetWidth(0)  -- Remove width constraint
        
        -- Bid text / Current bid (restore original)
        row.bidText:ClearAllPoints()
        row.bidText:SetPoint("CENTER", 50, 8)
        row.bidText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        row.bidText:SetWidth(0)  -- Remove width constraint

        -- Restore bid text content
        if row.currentBid and row.currentBid > 0 then
            row.bidText:SetText(string.format("Current Bid: |cffffd700%d|r", row.currentBid))
        else
            row.bidText:SetText(string.format("Starting Bid: |cffffd700%d|r", row.startBid or 0))
        end
                
        -- Top bidder text (restore original)
        row.topBidderText:ClearAllPoints()
        row.topBidderText:SetPoint("TOP", row.bidText, "BOTTOM", 0, -5)
        row.topBidderText:SetFont("Fonts\\FRIZQT__.TTF", 12)
        row.topBidderText:SetWidth(0)  -- Remove width constraint
        row.topBidderText:SetJustifyH("CENTER")  -- Restore center alignment

        -- Update text to show current bid in full mode
        if row.currentBid > 0 then
            row.topBidderText:SetText("Top Bidder: " .. row.topBidder)
        else
            row.topBidderText:SetText("")
        end
    
        if row.topBidder == UnitName("player") then
            row.topBidderText:SetTextColor(0, 1, 0) -- green
        else
            row.topBidderText:SetTextColor(1, 0.82, 0) -- gold
        end
        
        -- Bid box (restore original)
        row.bidBox:SetSize(80, 32)
        row.bidBox:ClearAllPoints()
        row.bidBox:SetPoint("RIGHT", -150, 0)
        row.bidBox:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        row.bidBox:Show()
        
        -- Bid button (restore original)
        row.bidButton:SetSize(80, 25)
        row.bidButton:ClearAllPoints()
        row.bidButton:SetPoint("LEFT", row.bidBox, "RIGHT", 30, 0)
        --row.bidButton:SetText("Min Bid")  -- Restore default text if needed
        row.bidButton:SetNormalFontObject("GameFontNormal")  -- Restore normal font
        
        -- Unstuck button (restore original)
        if row.unstuckButton then
            row.unstuckButton:SetSize(30, 25)
            row.unstuckButton:ClearAllPoints()
            row.unstuckButton:SetPoint("LEFT", row.bidButton, "RIGHT", 5, 0)
        end

        -- Restore overlay sizes for full mode
        if row.endOverlay then
            row.winnerText:ClearAllPoints()
            row.winnerText:SetPoint("CENTER")
            row.winnerText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
        end
        if row.manualAdjustmentOverlay then
            row.manualAdjustmentText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
        end
   elseif mode == "compact" then
        row:SetHeight(30)
        row:SetWidth(GDKPT.UI.AuctionContentFrame:GetWidth() - 10)
        row:ClearAllPoints()
        row:SetPoint("LEFT", 5, 0)
        row:SetPoint("RIGHT", -5, 0)
        
        -- Icon positioning (smaller, left side)
        row.icon:SetSize(24, 24)
        row.iconFrame:SetSize(24, 24)
        row.icon:ClearAllPoints()
        row.icon:SetPoint("LEFT", 30, 0)
        row.iconFrame:ClearAllPoints()
        row.iconFrame:SetPoint("CENTER", row.icon, "CENTER")
        
        -- Smaller stack text
        row.stackText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        
        -- Show auction number 
        row.auctionNumber:ClearAllPoints()
        row.auctionNumber:SetPoint("LEFT", 5, 0)
        row.auctionNumber:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        row.auctionNumber:SetText(row.auctionId or "")
        row.auctionNumber:SetWidth(20)
        row.auctionNumber:Show()
        
        -- Hide favorite button in compact
        row.favoriteButton:Hide()
        
        -- Timer (next to icon, matching MiniBidFrame timer position)
        row.timerText:ClearAllPoints()
        row.timerText:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
        row.timerText:SetFont("Fonts\\FRIZQT__.TTF", 10)
        row.timerText:SetWidth(45)
        row.timerText:SetJustifyH("LEFT")
        
        -- Current top bidder text (next to timer, in compact mode)
        row.topBidderText:ClearAllPoints()
        row.topBidderText:SetPoint("LEFT", row.timerText, "RIGHT", 5, 0)
        row.topBidderText:SetFont("Fonts\\FRIZQT__.TTF", 10)
        row.topBidderText:SetWidth(80)
        row.topBidderText:SetJustifyH("LEFT")

        -- Update text to show current bid
        if row.currentBid > 0 then
            row.topBidderText:SetText(row.topBidder)
        else
            row.topBidderText:SetText("")
        end
    
        if row.topBidder == UnitName("player") then
            row.topBidderText:SetTextColor(0, 1, 0) -- green
        else
            row.topBidderText:SetTextColor(1, 0.82, 0) -- gold
        end
        
        -- Hide current bid text (MiniBidFrame didn't show it separately)
        row.bidText:SetText("")
        
        -- Bid box (absolute position from left to fit in 290px width)
        row.bidBox:SetSize(50, 20)
        row.bidBox:ClearAllPoints()
        row.bidBox:SetPoint("LEFT", 175, 0)  -- Absolute position from left
        row.bidBox:SetFont("Fonts\\FRIZQT__.TTF", 12)
        row.bidBox:SetTextInsets(3, 3, 0, 0)
        row.bidBox:Show()
        
        -- Bid button (absolute position from left to fit in 290px width)
        row.bidButton:SetSize(55, 22)
        row.bidButton:ClearAllPoints()
        row.bidButton:SetPoint("LEFT", 230, 0)  -- Absolute position from left (290 - 55 - 5 = 230)
        row.bidButton:SetNormalFontObject("GameFontNormalSmall")
        
        -- Unstuck button (compact positioning)
        if row.unstuckButton then
            row.unstuckButton:SetSize(25, 20)
            row.unstuckButton:ClearAllPoints()
            row.unstuckButton:SetPoint("RIGHT", row.bidButton, "LEFT", -2, 0)
        end

        -- Scale down overlays for compact mode
        if row.endOverlay then
            row.winnerText:ClearAllPoints()
            row.winnerText:SetPoint("CENTER", row.topBidderText, "CENTER", 0, 0)
            row.winnerText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        end
        if row.manualAdjustmentOverlay then
            row.manualAdjustmentText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        end

        
        -- Hide item name text 
        row.itemButton:SetSize(1, 1)
        row.itemButton:ClearAllPoints()
        row.itemButton:SetPoint("LEFT", row.icon, "RIGHT", 0, 0)
        row.itemLinkText:SetText("")

           -- Helper function to show tooltip in compact mode
        local function ShowCompactTooltip(self)
            if GDKPT.ToggleLayout.currentLayout == "compact" and row.itemLink then
                GameTooltip:SetOwner(self, "ANCHOR_NONE")
                GameTooltip:ClearAllPoints()
                GameTooltip:SetPoint("LEFT", GDKPT.UI.AuctionWindow, "RIGHT", 10, 0)
                GameTooltip:SetHyperlink(row.itemLink)
            
                -- Add current bid info
                GameTooltip:AddLine(" ")
                if row.currentBid and row.currentBid > 0 then
                    GameTooltip:AddDoubleLine("Current Bid:", row.currentBid .. " gold", 1, 1, 1, 1, 0.82, 0)
                    if row.topBidder and row.topBidder ~= "" then
                        GameTooltip:AddDoubleLine("Top Bidder:", row.topBidder, 1, 1, 1, 0, 1, 0)
                    end
                else
                    GameTooltip:AddDoubleLine("Starting Bid:", (row.startBid or 0) .. " gold", 1, 1, 1, 1, 0.82, 0)
                    GameTooltip:AddDoubleLine("Top Bidder:", "No bids yet", 1, 1, 1, 0.8, 0.8, 0.8)
                end
            
                GameTooltip:Show()
            end
        end
    
        local function HideCompactTooltip(self)
            if GDKPT.ToggleLayout.currentLayout == "compact" then
                GameTooltip:Hide()
            end
        end

        -- Enable tooltip on entire row in compact mode
        if not row.compactTooltipEnabled then
            row:SetScript("OnEnter", ShowCompactTooltip)
            row:SetScript("OnLeave", HideCompactTooltip)
            row.compactTooltipEnabled = true
        end

        -- Also enable tooltip on bid button in compact mode
        if not row.bidButton.compactTooltipEnabled then
            row.bidButton:SetScript("OnEnter", ShowCompactTooltip)
            row.bidButton:SetScript("OnLeave", HideCompactTooltip)
            row.bidButton.compactTooltipEnabled = true
        end

        -- Also enable tooltip on bid box in compact mode
        if not row.bidBox.compactTooltipEnabled then
            row.bidBox:SetScript("OnEnter", ShowCompactTooltip)
            row.bidBox:SetScript("OnLeave", HideCompactTooltip)
            row.bidBox.compactTooltipEnabled = true
        end

    end
end



-------------------------------------------------------------------
-- Layout switch function to switch between Full and Compact modes
-------------------------------------------------------------------

function GDKPT.ToggleLayout.SetLayout(mode)
    local frame = GDKPT.UI.AuctionWindow
    if not frame then return end

    -- Store the mode
    GDKPT.ToggleLayout.currentLayout = mode
    
    -- Check if we need to show sync elements
    local needsSync = not (GDKPT.Core.leaderSettings and GDKPT.Core.leaderSettings.isSet)

    if mode == "full" then
        frame:SetSize(900, 600)
        frame:SetScale(1.0)

        -- Show title bar
        GDKPT.UI.AuctionWindowTitleBar:Show()
        GDKPT.UI.AuctionWindowTitleText:Show()

        -- Hide compact title if it exists
        if frame.CompactTitle then
            frame.CompactTitle:Hide()
        end

        -- Hide compact bottom panel
        if frame.CompactBottomPanel then
            frame.CompactBottomPanel:Hide()
        end

        -- Show bottom info panel
        GDKPT.UI.BottomInfoPanel:Show()

        -- Show Filters and Buttons on the top 
        GDKPT.AuctionFilters.FilterDropdown:Show()
        GDKPT.Favorites.FavoriteFrameButton:Show()
        GDKPT.Settings.SettingsFrameButton:Show()
        GDKPT.Loot.LootFrameToggleButton:Show()
        GDKPT.MyWonAuctions.WonAuctionsButton:Show()
        GDKPT.UI.GeneralHistoryButton:Show()

        -- Show/hide sync elements based on sync status
        if needsSync then
            GDKPT.UI.SyncButton:Show()
            GDKPT.UI.SyncButton:Enable()
            GDKPT.UI.ArrowFrame:Show()
            GDKPT.UI.ArrowText:Show()
            GDKPT.UI.AuctionScrollFrame:Hide()
        else
            GDKPT.UI.SyncButton:Hide()
            GDKPT.UI.ArrowFrame:Hide()
            GDKPT.UI.ArrowText:Hide()
            GDKPT.UI.AuctionScrollFrame:Show()
        end

        -- Resize scroll frame
        GDKPT.UI.AuctionScrollFrame:ClearAllPoints()
        GDKPT.UI.AuctionScrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -40)
        GDKPT.UI.AuctionScrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 55)

        -- Update all rows to full layout
        for _, row in pairs(GDKPT.Core.AuctionFrames) do
            GDKPT.ToggleLayout.SetRowLayout(row, "full")
        end

    elseif mode == "compact" then
        frame:SetSize(350, 400)
        frame:SetScale(1.0)

        -- Hide title bar
        GDKPT.UI.AuctionWindowTitleBar:Hide()
        GDKPT.UI.AuctionWindowTitleText:Hide()

        -- Create/show compact title
        if not frame.CompactTitle then
            frame.CompactTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            frame.CompactTitle:SetPoint("TOP", 0, -5)
            frame.CompactTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            frame.CompactTitle:SetText("|cffFFC125GDKPT - Compact Mode|r")
        end
        frame.CompactTitle:Show()


        -- Show compact bottom info panel
        if not frame.CompactBottomPanel then
            frame.CompactBottomPanel = CreateFrame("Frame", nil, frame)
            frame.CompactBottomPanel:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
            frame.CompactBottomPanel:SetSize(350, 40)
            frame.CompactBottomPanel:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                edgeSize = 8,
                insets = {left=3,right=3,top=3,bottom=3}
            })
            frame.CompactBottomPanel:SetBackdropColor(0,0,0,0.5)
    
            -- Current Gold
            local goldLabel = frame.CompactBottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            goldLabel:SetPoint("TOPLEFT", 5, -5)
            goldLabel:SetText("Gold:")
    
            frame.CompactBottomPanel.GoldText = frame.CompactBottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.CompactBottomPanel.GoldText:SetPoint("TOPLEFT", goldLabel, "BOTTOMLEFT", 0, -2)
            frame.CompactBottomPanel.GoldText:SetFont("Fonts\\FRIZQT__.TTF", 10)
    
            -- Bid Cap
            local capLabel = frame.CompactBottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            capLabel:SetPoint("TOPLEFT", 120, -5)
            capLabel:SetText("Bid Cap:")
    
            frame.CompactBottomPanel.BidCapInput = CreateFrame("EditBox", nil, frame.CompactBottomPanel)
            frame.CompactBottomPanel.BidCapInput:SetAutoFocus(false)
            frame.CompactBottomPanel.BidCapInput:SetNumeric(true)
            frame.CompactBottomPanel.BidCapInput:SetPoint("TOPLEFT", capLabel, "BOTTOMLEFT", 0, -2)
            frame.CompactBottomPanel.BidCapInput:SetSize(50, 16)
            frame.CompactBottomPanel.BidCapInput:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 8,
                insets = {left=2,right=2,top=2,bottom=2}
            })
            frame.CompactBottomPanel.BidCapInput:SetBackdropColor(0,0,0,0.5)
            frame.CompactBottomPanel.BidCapInput:SetTextInsets(2,2,0,0)
            frame.CompactBottomPanel.BidCapInput:SetFontObject(GameFontHighlightSmall)
            frame.CompactBottomPanel.BidCapInput:SetScript("OnEnterPressed", function(self)
                GDKPT.UI.TotalBidCapInput:SetText(self:GetText())
                GDKPT.UI.TotalBidCapInput:GetScript("OnEnterPressed")(GDKPT.UI.TotalBidCapInput)
                self:ClearFocus()
            end)
            frame.CompactBottomPanel.BidCapInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
            -- My Bids
            local bidsLabel = frame.CompactBottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            bidsLabel:SetPoint("TOPLEFT", 230, -5)
            bidsLabel:SetText("My Bids:")
    
            frame.CompactBottomPanel.MyBidsText = frame.CompactBottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.CompactBottomPanel.MyBidsText:SetPoint("TOPLEFT", bidsLabel, "BOTTOMLEFT", 0, -2)
            frame.CompactBottomPanel.MyBidsText:SetFont("Fonts\\FRIZQT__.TTF", 10)

            -- Initialize with current value
            local currentBids = GDKPT.Utils.GetTotalCommittedGold()
            frame.CompactBottomPanel.MyBidsText:SetText(currentBids)
            GDKPT.UI.MyBidsText:SetText(currentBids)
        end

        -- Update compact panel values
        frame.CompactBottomPanel.GoldText:SetText(GDKPT.Utils.FormatMoney(GetMoney()))
        frame.CompactBottomPanel.BidCapInput:SetText(GDKPT.UI.TotalBidCapInput:GetText())
        local currentBids = GDKPT.Utils.GetTotalCommittedGold()
        frame.CompactBottomPanel.MyBidsText:SetText(currentBids)
        frame.CompactBottomPanel:Show()

        GDKPT.UI.BottomInfoPanel:Hide()

        -- Hide Filters and Buttons on the top
        GDKPT.AuctionFilters.FilterDropdown:Hide()
        GDKPT.Favorites.FavoriteFrameButton:Hide()
        GDKPT.Settings.SettingsFrameButton:Hide()
        GDKPT.Loot.LootFrameToggleButton:Hide()
        GDKPT.MyWonAuctions.WonAuctionsButton:Hide()
        GDKPT.UI.GeneralHistoryButton:Hide()

        -- Show/hide sync elements based on sync status
        if needsSync then
            GDKPT.UI.SyncButton:Show()
            GDKPT.UI.SyncButton:Enable()
            GDKPT.UI.SyncButton:SetSize(200, 35)
            GDKPT.UI.ArrowFrame:Show()
            GDKPT.UI.ArrowText:Show()
            GDKPT.UI.AuctionScrollFrame:Hide()
        else
            GDKPT.UI.SyncButton:Hide()
            GDKPT.UI.ArrowFrame:Hide()
            GDKPT.UI.ArrowText:Hide()
            GDKPT.UI.AuctionScrollFrame:Show()
        end

        -- Resize scroll frame to fill compact frame
        GDKPT.UI.AuctionScrollFrame:ClearAllPoints()
        GDKPT.UI.AuctionScrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -20)
        GDKPT.UI.AuctionScrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 40)

        -- Update all rows to compact layout
        for _, row in pairs(GDKPT.Core.AuctionFrames) do
            GDKPT.ToggleLayout.SetRowLayout(row, "compact")
        end
    end

    -- Reposition all auctions after layout change
    if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
        C_Timer.After(0.1, function()
            GDKPT.AuctionLayout.RepositionAllAuctions()
        end)
    end
end



-------------------------------------------------------------------
-- Click Handling for the ToggleButton 
-- LeftClick: Full mode 
-- RightClick: Compact mode
-------------------------------------------------------------------



GDKPToggleButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if GDKPT.UI.AuctionWindow:IsShown() then
            -- If window is open in compact mode, switch to full
            if GDKPT.ToggleLayout.currentLayout == "compact" then
                GDKPT.ToggleLayout.SetLayout("full")
            else
                -- If already in full mode, just hide it
                GDKPT.UI.AuctionWindow:Hide()
            end
        else
            -- Window is closed, open in full mode
            GDKPT.ToggleLayout.SetLayout("full")
            GDKPT.UI.ShowAuctionWindow()
        end
        
        if GDKPT.Core.Settings.HideToggleButton == 1 and GDKPT.UI.AuctionWindow:IsShown() then
            self:Hide()
        end
        
    elseif button == "RightButton" then
        if GDKPT.UI.AuctionWindow:IsShown() then
            -- If window is open in full mode, switch to compact
            if GDKPT.ToggleLayout.currentLayout == "full" then
                GDKPT.ToggleLayout.SetLayout("compact")
            else
                -- If already in compact mode, just hide it
                GDKPT.UI.AuctionWindow:Hide()
            end
        else
            -- Window is closed, open in compact mode
            GDKPT.ToggleLayout.SetLayout("compact")
            GDKPT.UI.ShowAuctionWindow()
        end
    end
end)


-------------------------------------------------------------------
-- Event Handler for the ToggleButton
-------------------------------------------------------------------

local toggleButtonEventFrame = CreateFrame("Frame")

toggleButtonEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
toggleButtonEventFrame:RegisterEvent("PLAYER_LOGIN")
toggleButtonEventFrame:RegisterEvent("GROUP_JOINED")
toggleButtonEventFrame:RegisterEvent("GROUP_LEFT")
toggleButtonEventFrame:RegisterEvent("GROUP_UNGROUPED")
toggleButtonEventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
toggleButtonEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
toggleButtonEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  


toggleButtonEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_LOGIN" or event == "GROUP_JOINED" or event == "GROUP_LEFT" or event == "GROUP_UNGROUPED" or event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        GDKPT.ToggleLayout.UpdateToggleButtonVisibility()
    end
end)







