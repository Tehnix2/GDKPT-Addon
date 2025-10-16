-- Parallelized GDKP Addon for 3.3.5 servers
-- RaidMember Version


local version = 0.24

local addonPrefix = "GDKP"   -- Variable for addon communication to leader addon

-- default values for leader settings, will be overwritten by a settings sync from leader
local leaderSettings = {
    duration = 30,
    extraTime = 5,
    startBid = 50,
    minIncrement = 10,
    splitCount = 25,
    isSet = false, -- Flag to indicate if settings have been successfully received once
}




local AuctionFrames = {}    -- Table to keep track of the UI frames for each active auction
local AuctionFramePool = {} -- To reuse frames instead of creating/destroying them
local PendingAuctions = {}  -- Table that stores auctions that are waiting for item data to load


local PlayerWonItems = {}
local PlayerCut = 0
local GDKP_Pot = 0

local isFavoriteFilterActive = false  



-------------------------------------------------------------------
-- Main Auction Frame
-------------------------------------------------------------------

   local AuctionWindow = CreateFrame("Frame","GDKP_Auction_Window",UIParent)

    AuctionWindow:SetSize(800,600)
    AuctionWindow:SetMovable(true)
    AuctionWindow:EnableMouse(true)
    AuctionWindow:RegisterForDrag("LeftButton")
    AuctionWindow:SetPoint("CENTER")
    AuctionWindow:Hide()
    AuctionWindow:SetFrameLevel(8)
    AuctionWindow:SetBackdrop({                           
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",     
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 20,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })


    AuctionWindow:SetScript("OnDragStart", AuctionWindow.StartMoving)
    AuctionWindow:SetScript("OnDragStop", AuctionWindow.StopMovingOrSizing)

    _G["GDKP_Auction_Window"] = AuctionWindow 
    tinsert(UISpecialFrames,"GDKP_Auction_Window")

    local CloseAuctionWindowButton = CreateFrame("Button", "CloseAuctionWindowButton", AuctionWindow, "UIPanelCloseButton")
    CloseAuctionWindowButton:SetPoint("TOPRIGHT", -5, -5)
    CloseAuctionWindowButton:SetSize(35, 35)



    local AuctionWindowTitleBar = CreateFrame("Frame", "", AuctionWindow, nil)
    AuctionWindowTitleBar:SetSize(180, 25)
    AuctionWindowTitleBar:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        edgeSize = 16,
        tileSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    AuctionWindowTitleBar:SetPoint("TOP", 0, 0)


    local AuctionWindowTitleText = AuctionWindowTitleBar:CreateFontString("")
    AuctionWindowTitleText:SetFont("Fonts\\FRIZQT__.TTF", 14)
    AuctionWindowTitleText:SetText("|cffFFC125GDKPT " .. "- v " .. version .. "|r")
    AuctionWindowTitleText:SetPoint("CENTER", 0, 0)




-------------------------------------------------------------------
-- Bottom Info Panel
-------------------------------------------------------------------


    local function FormatGold(amount)
        if amount == 0 then return "|cffb4b4b40|r" end
        local sign = ""
        if amount < 0 then
            sign = "-"
            amount = -amount
        end

        local absAmount = math.abs(amount)
        local gold = math.floor(absAmount / 10000)
        local silver = math.floor((absAmount % 10000) / 100)
        local copper = absAmount % 100

        local parts = {}
        if gold > 0 then table.insert(parts, format("|cffffd700%dg|r", gold)) end
        if silver > 0 or (gold > 0 and (silver > 0 or copper > 0)) then table.insert(parts, format("|cffc7c7cfl%ds|r", silver)) end
        if copper > 0 or (#parts == 0 and copper >= 0) then table.insert(parts, format("|cffeda55f%dc|r", copper)) end
    
        -- Ensure we display 0g 0s 0c if the amount is exactly zero
        if #parts == 0 then return "|cffb4b4b40c|r" end

        return sign .. table.concat(parts, " ")
    end



 
    
    -- Function to show gold, silver and copper coins on the bottom info panel
    local function FormatMoney(copper)

        copper = tonumber(copper) or 0 

        local gold = math.floor(copper / 10000)
        local silver = math.floor((copper % 10000) / 100)
        local remainingCopper = copper % 100

        local goldIcon = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:0:0|t"
        local silverIcon = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:0:0|t"
        local copperIcon = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:0:0|t"

        return string.format("%d%s %d%s %d%s", gold, goldIcon, silver, silverIcon, remainingCopper, copperIcon)
    end
 


    local TotalPotText = AuctionWindow:CreateFontString("TotalPotText", "OVERLAY", "GameFontNormal")
    TotalPotText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    TotalPotText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", -350, 10)
    TotalPotText:SetText("Total Pot: ")


    local TotalPotAmountText = AuctionWindow:CreateFontString("TotalPotAmountText", "OVERLAY", "GameFontNormal")
    TotalPotAmountText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    TotalPotAmountText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", -240, 10)


    local CurrentCutText = AuctionWindow:CreateFontString("CurrentCutText", "OVERLAY", "GameFontNormal")
    CurrentCutText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    CurrentCutText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", -100, 10)
    CurrentCutText:SetText("Current Cut: ")


    local CurrentCutAmountText = AuctionWindow:CreateFontString("CurrentCutAmountText", "OVERLAY", "GameFontNormal")
    CurrentCutAmountText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    CurrentCutAmountText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", 20, 10)


    local CurrentGoldText = AuctionWindow:CreateFontString("CurrentGoldText", "OVERLAY", "GameFontNormal")
    CurrentGoldText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    CurrentGoldText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", 165, 10)
    CurrentGoldText:SetText("Current Gold: ")

    local CurrentGoldAmountText = AuctionWindow:CreateFontString("CurrentGoldAmountText", "OVERLAY", "GameFontNormal")
    CurrentGoldAmountText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    CurrentGoldAmountText:SetPoint("BOTTOM", AuctionWindow, "BOTTOM", 290, 10)



-------------------------------------------------------------------
-- Functions to update the data on the bottom info panel
-------------------------------------------------------------------

    local function UpdateTotalPotAmount(totalPotValue)
        currentPot = tonumber(totalPotValue) or 0 
        TotalPotAmountText:SetText(string.format("%s", FormatMoney(currentPot)))
    end

    local function UpdateCurrentCutAmount(currentCutValue) -- Accept the synced value
        currentCut = tonumber(currentCutValue) or 0
        PlayerCut = currentCut
        CurrentCutAmountText:SetText(string.format("%s", FormatMoney(currentCut)))
    end

    local function UpdateCurrentGoldAmount()
        CurrentGoldAmountText:SetText(FormatMoney(GetMoney()))
    end




-------------------------------------------------------------------
-- Info Button on the top left that players can hover over to see global auction settings
-------------------------------------------------------------------


    local InfoButton = CreateFrame("Button", "GDKP_InfoButton", AuctionWindow, "UIPanelButtonTemplate")
    InfoButton:SetSize(20, 20)
    InfoButton:SetPoint("TOPLEFT", AuctionWindow, "TOPLEFT", 0, 0)
    InfoButton:SetText("i") 

    -- Tooltip Handlers for the Info Button
    InfoButton:SetScript("OnEnter", function(self)
        -- Set up the tooltip anchored to the button
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        
        GameTooltip:AddLine("GDKPT Auction Settings", 1, 1, 1)

        if leaderSettings and leaderSettings.isSet then
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("Duration: |cffffd100" .. leaderSettings.duration .. " sec|r", 1, 1, 1)
            GameTooltip:AddLine("Extra Time/Bid: |cffffd100" .. leaderSettings.extraTime .. " sec|r", 1, 1, 1)
            GameTooltip:AddLine("Starting Bid: |cffffd100" .. leaderSettings.startBid .. " gold|r", 1, 1, 1)
            GameTooltip:AddLine("Min Increment: |cffffd100" .. leaderSettings.minIncrement .. " gold|r", 1, 1, 1)
            GameTooltip:AddLine("Split Count: |cffffd100" .. leaderSettings.splitCount .. " players|r", 1, 1, 1)
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cff00ff00Settings successfully synced.|r", 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine("---", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cffff0000Settings Not Synced|r", 1, 0, 0)
            GameTooltip:AddLine("Ask the raid leader to sync settings.", 0.8, 0.8, 0.8)
        end
        
        GameTooltip:Show()
    end)
    
    InfoButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)



-------------------------------------------------------------------
-- Function for returning the name of the raid leader
-------------------------------------------------------------------


    local function GetRaidLeaderName()
        if not IsInRaid() then
            return nil -- not in a raid
        end

        for i = 1, GetNumRaidMembers() do
            local name, rank = GetRaidRosterInfo(i)
            -- rank: 2 = leader, 1 = assistant, 0 = member
            if rank == 2 then
                return name
            end
        end

        return nil -- fallback if no leader found
    end




-------------------------------------------------------------------
-- Leader Settings sync button thats visible until settings are received and synced
-------------------------------------------------------------------


    local SyncSettingsButton = CreateFrame("Button", "GDKP_SyncSettingsButton", AuctionWindow, "UIPanelButtonTemplate")
    SyncSettingsButton:SetSize(250, 40)
    SyncSettingsButton:SetPoint("CENTER", 0, 0)
    SyncSettingsButton:SetText("Request Leader Settings Sync")
    SyncSettingsButton:Show() -- Show by default

    local function RequestSettingsSync(self)
        local leaderName = GetRaidLeaderName()

        if IsInRaid() and leaderName then
            -- Send a specific message to the leader's addon asking for settings
            local msg = "REQUEST_SETTINGS_SYNC"
            SendAddonMessage(addonPrefix, msg, "RAID")
            
            self:SetText("Request Sent...")
            self:Disable()
            
            -- Implement a temporary frame to re-enable the button after a delay
            local frame = CreateFrame("Frame")
            local elapsed = 0
            frame:SetScript("OnUpdate", function(self, delta)
                elapsed = elapsed + delta
                if elapsed >= 5.0 then
                    self:SetScript("OnUpdate", nil)
                    -- Only re-enable if settings were NOT received during the delay
                    if not leaderSettings.isSet then
                        SyncSettingsButton:Enable()
                        SyncSettingsButton:SetText("Request Leader Settings Sync")
                    end
                end
            end)
            print("|cff99ff99[GDKPT]|r Requesting settings from leader |cffFFC125" .. leaderName .. "|r...")
        else
            print("|cffff8800[GDKPT]|r Error: You must be in a raid with a leader to request settings.")
        end
    end

    SyncSettingsButton:SetScript("OnClick", RequestSettingsSync)






-------------------------------------------------------------------
-- Scroll Frame that will hold all of the auctions
-------------------------------------------------------------------

    local AuctionScrollFrame = CreateFrame("ScrollFrame", "GDKP_Auction_ScrollFrame", AuctionWindow, "UIPanelScrollFrameTemplate")
    AuctionScrollFrame:SetPoint("TOPLEFT", 10, -40)
    AuctionScrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
    AuctionScrollFrame:Hide() -- Hide until leader settings have been synced, then show

    local AuctionContentFrame = CreateFrame("Frame", "GDKP_Auction_ContentFrame", AuctionScrollFrame)
    AuctionContentFrame:SetSize(760, 100) 
    AuctionScrollFrame:SetScrollChild(AuctionContentFrame)








-------------------------------------------------------------------
-- Function for updating the timer underneath the itemlink on a row
-------------------------------------------------------------------

    local function UpdateRowTimer(self,elapsed)

        -- Accumulate time elapsed since the last frame
        self.timeAccumulator = (self.timeAccumulator or 0) + elapsed
        
        -- Only proceed if at least 1 second has accumulated
        if self.timeAccumulator < 1.0 then
            return
        end
        
        -- Reset the accumulator, subtracting full seconds that passed
        -- Using math.floor ensures we handle cases where elapsed is slightly > 1.0
        self.timeAccumulator = self.timeAccumulator - math.floor(self.timeAccumulator)

        if not self.endTime or self.endTime == 0 then
            self.timerText:SetText("Time Left: |cffaaaaaa--:--|r")
            -- Stop the OnUpdate script if the timer is invalid/finished
            self:SetScript("OnUpdate", nil)
            return
        end

        -- Recalculate remaining time using the system time
        local remaining = self.endTime - GetTime()
        
        if remaining > 0 then
            -- Floor the remaining time to get clean second counts for display
            local minutes = math.floor(remaining / 60)
            local seconds = math.floor(remaining % 60)
            
            -- Determine color code
            local colorCode = (remaining < 10) and "|cffff2222" or "|cffffffff"
            
            self.timerText:SetText(string.format("Time Left: %s%02d:%02d|r", colorCode, minutes, seconds))
        else
            -- Auction is officially over
            self.timerText:SetText("Time Left: |cffff000000:00|r")
            -- Stop the OnUpdate script as the auction is finished
            self.timeAccumulator = 0
            self:SetScript("OnUpdate", nil)
        end
    end





-------------------------------------------------------------------
-- Function that gets called when a player clicks the bidButton
-- bidButton makes the player always bid the least possible amount
-------------------------------------------------------------------

    local function ClickBidButton(self)
    
        -- auctionId is set by the HandleAuctionStart() function
        local auctionId = self.auctionId
        local row = AuctionFrames[auctionId]

        if not row then
            print("|cffff8800[GDKPT]|r Error: Could not find auction data.")
            return
        end


        local currentBid = row.currentBid or 0 -- Default to 0 if no bids yet
        local minInc = row.minIncrement

        local bidAmount
 
        if row.topBidder == "" then
            -- If no top bidder exists, the first bid must be at least the starting bid
            bidAmount = row.startBid
        else
            -- If a top bidder exists, the next allowed bid is currentBid + minInc
            bidAmount = currentBid + minInc
        end

    
        -- Send the bid to the leader addon
        if bidAmount and bidAmount > 0 then
    
            local msg = string.format("BID:%d:%d", auctionId, bidAmount)
            SendAddonMessage(addonPrefix, msg, "RAID")
        
            -- Lock the UI while waiting for the leader's response
            row.bidButton:Disable()
            row.bidButton:SetText("Syncing...")
        
            SendChatMessage(string.format("[GDKPT] I'm bidding %d gold on %s !", bidAmount, row.itemLink), "RAID")
        end
    end



-------------------------------------------------------------------
-- Function that gets called when a player enters a manual bid into 
-- the bidBox
-------------------------------------------------------------------


local function HandleBidBoxEnter(self)
    
    local row = self:GetParent() -- Get the parent row frame
    local bidAmount = tonumber(self:GetText())
    local auctionId = row.auctionId

    self:ClearFocus() -- Clear focus immediately upon pressing Enter

    if not auctionId or not row then
        print("|cffff8800[GDKPT]|r Error: There is no auction data for this bidBox.")
        return
    end

    local currentBid = row.currentBid or 0
    local minInc = row.minIncrement
    local nextMinBid = currentBid > 0 and (currentBid + minInc) or row.startBid

    -- Validation 1: Check if the input is a valid positive number
    if not bidAmount or bidAmount <= 0 then
        print("|cffff8800[GDKPT]|r Invalid bid amount. Please enter a positive number.")
        self:SetText("")
        --self:SetText(tostring(nextMinBid)) -- Reset to the minimum allowed bid
        return
    end

    -- Validation 2: Check if the bid meets the minimum required bid
    if bidAmount < nextMinBid then
        print(string.format("|cffff8800[GDKPT]|r Bid must be at least %d gold.", nextMinBid))
        self:SetText("")
        --self:SetText(tostring(nextMinBid)) -- Reset to the minimum allowed bid
        return
    end

    -- Send the validated bid to the leader addon
    local msg = string.format("BID:%d:%d", auctionId, bidAmount)
    SendAddonMessage(addonPrefix, msg, "RAID")

    -- Lock the UI while waiting for the leader's response
    row.bidButton:Disable()
    row.bidButton:SetText("Syncing...")
    
    -- Update the chat announcement
    SendChatMessage(string.format("[GDKPT] I'm manually bidding %d gold on %s !", bidAmount, row.itemLink), "RAID")

    -- Clear the bidBox after sending the bid
    self:SetText("")

end
    




-- =================================================================
-- Additional frame on the bottom right for the items a player has won
-- =================================================================

    local WonAuctionsFrame = CreateFrame("Frame", "GDKP_WonAuctionsFrame", UIParent)
    WonAuctionsFrame:SetSize(400, 300)
    WonAuctionsFrame:SetPoint("BOTTOMRIGHT", AuctionWindow, "BOTTOMRIGHT", -10, 10) 
    WonAuctionsFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    WonAuctionsFrame:SetBackdropColor(0, 0, 0, 0.6)
    WonAuctionsFrame:SetFrameLevel(AuctionWindow:GetFrameLevel() + 1)
    WonAuctionsFrame:Hide()

    WonAuctionsFrame:SetMovable(true)
    WonAuctionsFrame:EnableMouse(true)
    WonAuctionsFrame:RegisterForDrag("LeftButton")
   


    WonAuctionsFrame:SetScript("OnDragStart", WonAuctionsFrame.StartMoving)
    WonAuctionsFrame:SetScript("OnDragStop", WonAuctionsFrame.StopMovingOrSizing)

    AuctionWindow.WonAuctionsFrame = WonAuctionsFrame -- Attach to main window for easy access

    
    local WonAuctionsTitle = WonAuctionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    WonAuctionsTitle:SetText("Won Auctions")
    WonAuctionsTitle:SetPoint("TOP", WonAuctionsFrame, "TOP", 0, -10)


    local CloseWonAuctionsButton = CreateFrame("Button", "", WonAuctionsFrame, "UIPanelCloseButton")
       CloseWonAuctionsButton:SetPoint("TOPRIGHT", -5, -5)
       CloseWonAuctionsButton:SetSize(35, 35)

       -- Button in AuctionWindow to show/hide the WonAuctionsFrame


     local WonItemsButton = CreateFrame("Button", "GDKP_WonItemsButton", AuctionWindow, "UIPanelButtonTemplate")
     WonItemsButton:SetSize(120, 22)
     WonItemsButton:SetPoint("TOPRIGHT", AuctionWindow, "TOPRIGHT", -170, -15)
    
    -- Set initial text based on the frame's initial hidden state
    WonItemsButton:SetText("Won Auctions")

       WonItemsButton:SetScript("OnClick", function(self)
            if WonAuctionsFrame:IsVisible() then
                WonAuctionsFrame:Hide()
                self:SetText("Won Auctions")
            else
                WonAuctionsFrame:Show()
                self:SetText("Won Auctions")
            end
       end)


       -- ScrollFrame container
       local WonAuctionsScrollFrame = CreateFrame("ScrollFrame", "GDKP_WonItemsScrollFrame", WonAuctionsFrame, "UIPanelScrollFrameTemplate")
       WonAuctionsScrollFrame:SetPoint("TOPLEFT", -30, -35)
       WonAuctionsScrollFrame:SetPoint("BOTTOMRIGHT", -30, 80) 
    
       WonAuctionsFrame.ScrollFrame = WonAuctionsScrollFrame

       -- Scroll Content
       local WonAuctionsScrollContent = CreateFrame("Frame", nil, WonAuctionsScrollFrame)
       WonAuctionsScrollContent:SetWidth(WonAuctionsScrollFrame:GetWidth()) 
       WonAuctionsScrollContent:SetHeight(1) -- Will be adjusted dynamically
       WonAuctionsScrollFrame:SetScrollChild(WonAuctionsScrollContent)

        -- Summary Panel
       local WonAuctionsSummaryPanel = CreateFrame("Frame", "GDKP_WonItemsSummaryPanel", WonAuctionsFrame)
       WonAuctionsSummaryPanel:SetSize(WonAuctionsFrame:GetWidth() - 20, 72)
       WonAuctionsSummaryPanel:SetPoint("BOTTOM", 0, 10)
       WonAuctionsSummaryPanel:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
       })
       WonAuctionsSummaryPanel:SetBackdropColor(0, 0, 0, 0.4)
    
       WonAuctionsFrame.SummaryPanel = WonAuctionsSummaryPanel

    
   
       -- Total Cost
       local totalCostLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
       totalCostLabel:SetText("Total Won Auctions Cost:")
       totalCostLabel:SetPoint("TOPLEFT", 5, -5)

       local totalCostValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
       totalCostValue:SetText(FormatMoney(0))
       totalCostValue:SetPoint("TOPRIGHT", -5, -5)
   
       WonAuctionsSummaryPanel.totalCostValue = totalCostValue

       -- Need to Pay Up
       local payUpLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
       payUpLabel:SetText("Need to Pay Up:")
       payUpLabel:SetPoint("TOPLEFT", 5, -29)

        local payUpValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        payUpValue:SetText(FormatMoney(0))
        payUpValue:SetPoint("TOPRIGHT", -5, -29)
    
        WonAuctionsSummaryPanel.payUpValue = payUpValue

        -- Gold Left After Raid (PlayerCut is a placeholder until pot split is done)
        local goldLeftLabel = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        goldLeftLabel:SetText("Gold After Raid:")
        goldLeftLabel:SetPoint("TOPLEFT", 5, -53)

        local goldLeftValue = WonAuctionsSummaryPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        goldLeftValue:SetText(FormatMoney(GetMoney()))
        goldLeftValue:SetPoint("TOPRIGHT", -5, -53)
    
        WonAuctionsSummaryPanel.goldLeftValue = goldLeftValue



-------------------------------------------------------------------
-- Filling the Won Auctions Frame
-------------------------------------------------------------------

    

    local function CalculateTotalPaid()
        local total = 0
        for _, item in pairs(PlayerWonItems) do
            total = total + item.bid
        end
        return total * 10000
    end


    local WonItemEntryPool = {}
    local WonItemEntryID = 1


    -- Function to create a single entry in the won items list
    local function CreateWonAuctionEntry(parent)
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetHeight(32) -- Standard icon height
        frame:EnableMouse(true)
    
        -- Icon
        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(28, 28)
        icon:SetPoint("LEFT", frame, "LEFT", 40, 0)
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        frame.icon = icon

        -- Item Name (Text)
        local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        nameText:SetJustifyH("LEFT")
        frame.nameText = nameText

        -- Bid Amount (Text)
        local bidText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        bidText:SetPoint("RIGHT", -5, 0)
        bidText:SetJustifyH("RIGHT")
        frame.bidText = bidText

        -- Mouseover for tooltip (shows item link if available)
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.itemLink then
                GameTooltip:SetHyperlink(self.itemLink)
            else
                GameTooltip:SetText(self.itemName, 1, 1, 1)
                GameTooltip:AddLine("Won for: " .. self.bidAmount .. " Gold")
                GameTooltip:Show()
            end
        end)
        frame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        return frame
    end




local function UpdateWonItemsList(WonAuctionsScrollFrame, WonAuctionsScrollContent)
    -- Clear existing entries and reset pool index
    for i, entry in ipairs(WonItemEntryPool) do
        entry:Hide()
    end
    WonItemEntryID = 1

    local totalHeight = 0
    
    -- Add a safeguard here: if WonAuctionsScrollContent is nil, we cannot proceed with positioning.
    if not WonAuctionsScrollContent then 
        print("|cffff3333[GDKPT]|r Error: ScrollContent for My Won Items is missing. UI not fully initialized.")
        return 
    end
    
    for i, item in ipairs(PlayerWonItems) do
        local entry = WonItemEntryPool[WonItemEntryID]
        if not entry then
            entry = CreateWonAuctionEntry(WonAuctionsScrollContent)
            WonItemEntryPool[WonItemEntryID] = entry
        end
        WonItemEntryID = WonItemEntryID + 1

        -- Set data
        entry.itemName = item.name
        entry.itemLink = item.link
        entry.bidAmount = item.bid
        
        entry.nameText:SetText(item.name)
        entry.bidText:SetText(FormatMoney(item.bid*10000))
        
        -- Get texture from item link (requires item info to be loaded)
        -- NOTE: GetItemInfo expects itemID or itemLink, using item.link is correct here.
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(item.link)
        if texture then
            entry.icon:SetTexture(texture)
        else
             entry.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        -- Position and Show
        local prevEntry = WonItemEntryPool[WonItemEntryID - 2]
        if not prevEntry then
            entry:SetPoint("TOP", WonAuctionsScrollContent, "TOP", 0, -2) -- 2 pixel margin from top
        else
            entry:SetPoint("TOP", prevEntry, "BOTTOM", 0, -2) -- 2 pixel spacing
        end

        entry:SetWidth(WonAuctionsScrollContent:GetWidth())
        entry:Show()

        totalHeight = totalHeight + entry:GetHeight() + 2
    end

    -- Adjust ScrollContent height to accommodate all entries
    local contentHeight = math.max(WonAuctionsScrollFrame:GetHeight() - 10, totalHeight + 2) -- Ensure minimum scroll area
    WonAuctionsScrollContent:SetHeight(contentHeight)
    
    if WonAuctionsScrollFrame.ScrollBar then
        WonAuctionsScrollFrame.ScrollBar:SetValue(0) -- Scroll to top on refresh
    end
end



-- Function to update the gold summary panel
local function UpdateSummaryPanel(WonAuctionsSummaryPanel)
    local totalPaid = CalculateTotalPaid()
    
    WonAuctionsSummaryPanel.totalCostValue:SetText(FormatMoney(totalPaid))
    WonAuctionsSummaryPanel.payUpValue:SetText(FormatMoney(totalPaid))
    
    -- Calculate how much gold the player is leaving the raid with
    local goldLeft = PlayerCut - totalPaid
    
    -- Format Gold Left with color-coding
    local color
    if goldLeft > 0 then
        color = "|cff33ff33" -- Green
    elseif goldLeft < 0 then
        color = "|cffff3333" -- Red
    else
        color = "|cffcccccc" -- Gray/White
    end
    
    -- Use simple gold string if GOLD_AMOUNT_TEMPLATE isn't guaranteed to be defined
    WonAuctionsSummaryPanel.goldLeftValue:SetText(color .. FormatMoney(goldLeft) .. "|r")
    --WonAuctionsSummaryPanel.goldLeftValue:SetText(color .. format("%d G", goldLeft) .. "|r")
end


local function UpdateWonItemsDisplay(WonAuctionsFrame)
    if WonAuctionsFrame and WonAuctionsFrame.ScrollFrame then
        local ScrollFrame = WonAuctionsFrame.ScrollFrame
        -- Use the standard API method GetScrollChild to retrieve the content frame
        local ScrollContent = WonAuctionsScrollFrame:GetScrollChild()
        
        -- We only proceed if we successfully retrieved the content frame
        if ScrollContent then
            UpdateWonItemsList(ScrollFrame, ScrollContent)
            UpdateSummaryPanel(WonAuctionsFrame.SummaryPanel)
        else
            print("|cffff3333[GDKPT]|r Error: MyWonItemsFrame UI component structure is incomplete (missing ScrollChild).")
        end
    end
end

















-------------------------------------------------------------------
-- Dynamic Auction Row Creation
-------------------------------------------------------------------

    local ROW_HEIGHT = 60

    local function CreateAuctionRow()

        -- row frame setup
    
        local row = CreateFrame("Frame", nil, AuctionContentFrame)
        row:SetSize(750, 55)
        row:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        row:Hide()

        -- Variable needed for the auction timer
        row.timeAccumulator = 0

        -- 1. Item Icon
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(40, 40)
        row.icon:SetPoint("LEFT", 40, 0)


        -- 2. Item Link with a hidden button behind it for mouseover tooltip
        row.itemButton = CreateFrame("Button", nil, row)
        row.itemButton:SetSize(250, 20)
        row.itemButton:SetPoint("LEFT", row.icon, "RIGHT", 40, 8)
        row.itemLinkText = row.itemButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.itemLinkText:SetFont("Fonts\\FRIZQT__.TTF", 14)
        row.itemLinkText:SetAllPoints()
        row.itemLinkText:SetJustifyH("LEFT")
        row.itemButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(row.itemLink)
            GameTooltip:Show()
        end)
        row.itemButton:SetScript("OnLeave", function() GameTooltip:Hide() end)


        -- 3. Timer Text
        row.timerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.timerText:SetPoint("LEFT", row.itemButton, "LEFT", 0, -20)
        row.timerText:SetFont("Fonts\\FRIZQT__.TTF", 12)

        --Countdown timer underneath the itemLink on each row, triggered on frame update

        row:SetScript("OnUpdate",UpdateRowTimer)


        -- 4. Current Bid Text
        row.bidText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.bidText:SetPoint("CENTER", 50, 8)
        row.bidText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

        -- 5. Top Bidder Text
        row.topBidderText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.topBidderText:SetPoint("TOP", row.bidText, "BOTTOM", 0, -5)
        row.topBidderText:SetFont("Fonts\\FRIZQT__.TTF", 12)

        -- 6. Bid EditBox
        row.bidBox = CreateFrame("EditBox", nil, row) 
        row.bidBox:SetSize(80, 32)
        row.bidBox:SetPoint("RIGHT", -150, 0)
        row.bidBox:SetNumeric(true)
        row.bidBox:SetAutoFocus(false)
        row.bidBox:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

        row.bidBox:SetTextInsets(4, 4, 0, 0) 
    

        row.bidBox:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background", -- A light gray background
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",    -- Standard WoW border texture
            tile = true,
            tileSize = 16,
            edgeSize = 8,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        -- Set the backdrop color to make it visually distinct
        row.bidBox:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
        row.bidBox:SetBackdropBorderColor(0.8, 0.6, 0, 1) -- Gold-ish border color


        --TODO: Add a seperate function for the bidBox
        row.bidBox:SetScript("OnEnterPressed", HandleBidBoxEnter)

    

        row.bidBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)


        -- 7. Bid Button
        row.bidButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.bidButton:SetSize(80, 25)
        row.bidButton:SetPoint("LEFT", row.bidBox, "RIGHT", 30, 0)
        row.bidButton:SetText("Min Bid")

    
        row.bidButton:SetScript("OnClick", ClickBidButton)   


        -- 8. Auction Id on top left
        row.auctionNumber = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.auctionNumber:SetPoint("LEFT", 10, 8)
        row.auctionNumber:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
        
        row.auctionNumber:SetText(row.auctionId or "")


        -- 9. Favourite star icon below

        row.favoriteButton = CreateFrame("Button", nil, row)
        row.favoriteButton:SetSize(15, 15)
        -- Anchor directly below the auction number (Element 8)
        row.favoriteButton:SetPoint("TOP", row.auctionNumber, "BOTTOM", 0, -5) 
    
        row.favoriteButton:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        row.favoriteIcon = row.favoriteButton:GetNormalTexture()
    
        -- Ensure the retrieved texture object exists before trying to manipulate it
        if row.favoriteIcon then
            row.favoriteIcon:SetAllPoints()
            row.favoriteIcon:SetVertexColor(1, 0.8, 0, 1) -- Gold color for the 'favorite' placeholder
        end


        -- Add a highlight texture for visual feedback on mouseover
        local highlight = row.favoriteButton:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight") -- A common highlight texture
        highlight:SetVertexColor(1, 1, 1, 0.5) -- White transparency
        row.favoriteButton:SetHighlightTexture(highlight)

        row.isFavorite = false
        row.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Grayed out
    
        row.favoriteButton:SetScript("OnClick", function(self)
            row.isFavorite = not row.isFavorite -- Toggle favorite state
        
            -- Visual feedback update (setting color based on new state)
            if row.isFavorite then
                 row.favoriteIcon:SetVertexColor(1, 0.8, 0, 1) -- Gold/Yellow
            else
                 row.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Grayed out
            end
        
            -- Re-run the layout/visibility function to ensure correct stacking
            --UpdateAuctionLayout() 
        end)




    -- 10. Auction End Overlay Frame (NEW)
    row.endOverlay = CreateFrame("Frame", nil, row)
    row.endOverlay:SetAllPoints(row)
    row.endOverlay:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    -- Semi-transparent black background
    row.endOverlay:SetBackdropColor(0.1, 0.1, 0.1, 0.8) 
    row.endOverlay:SetFrameLevel(row:GetFrameLevel() + 2) -- Ensure it covers other elements

    row.winnerText = row.endOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    row.winnerText:SetPoint("CENTER")
    row.winnerText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    row.winnerText:SetTextColor(1, 1, 0, 1) -- Default Gold/Yellow color

    row.endOverlay:Hide() -- Start hidden



    return row



    end

 
   





-------------------------------------------------------------------
-- Function that updates the layout of the auction content frame
-- based on the amount of active auctions at a time
-------------------------------------------------------------------

    local function UpdateAuctionLayout()
        local count = 0
        for id, frame in pairs(AuctionFrames) do
            if frame:IsShown() then
                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", AuctionContentFrame, "TOPLEFT", 5, -5 - (count * ROW_HEIGHT))
                count = count + 1
            end
        end
        -- Adjust the content frame height to fit all rows
        AuctionContentFrame:SetHeight(math.max(100, count * ROW_HEIGHT))
    end




-------------------------------------------------------------------
-- Function that updates the layout of the auction content frame
-- based on the amount of active auctions at a time.
-- This function also handles filtering by favorites.
-------------------------------------------------------------------

    local function FilterByFavourites()
        -- To ensure a consistent order, we'll sort the auction IDs.
        local sortedAuctionIDs = {}
        for id in pairs(AuctionFrames) do
            table.insert(sortedAuctionIDs, id)
        end
        table.sort(sortedAuctionIDs)

        -- Loop through the sorted list to assign a fixed position to each row
        for i, id in ipairs(sortedAuctionIDs) do
            local frame = AuctionFrames[id]
            if frame then
                -- Step 1: Set a permanent position for the row based on its sorted index.
                -- This ensures that rows don't shift up when others are hidden.
                local yPosition = -5 - ((i - 1) * ROW_HEIGHT)
                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", AuctionContentFrame, "TOPLEFT", 5, yPosition)

                -- Step 2: Determine visibility based on the favorite filter.
                if isFavoriteFilterActive then
                    if frame.isFavorite then
                        frame:Show()
                    else
                        frame:Hide()
                    end
                else
                    -- If the filter is off, ensure all frames are visible.
                    frame:Show()
                end
            end
        end

        -- Step 3: Adjust the content frame height to fit ALL rows, visible or not,
        -- to maintain the layout structure.
        AuctionContentFrame:SetHeight(math.max(100, #sortedAuctionIDs * ROW_HEIGHT))
    end




-------------------------------------------------------------------
-- Filter auction rows by favourites
-------------------------------------------------------------------

  local FavoriteFilterButton = CreateFrame("Button", "GDKP_FavoriteFilterButton", AuctionWindow, "UIPanelButtonTemplate")
    FavoriteFilterButton:SetSize(120, 22)
    FavoriteFilterButton:SetPoint("TOPLEFT", AuctionWindow, "TOPLEFT", 50, -15)

    local function UpdateFilterButtonText()
        if not isFavoriteFilterActive then
            FavoriteFilterButton:SetText("Favourites only")
        else
            FavoriteFilterButton:SetText("All Auctions")
        end
    end

    UpdateFilterButtonText() -- Set initial text

     FavoriteFilterButton:SetScript("OnClick", function(self)
        isFavoriteFilterActive = not isFavoriteFilterActive
        UpdateFilterButtonText()
        FilterByFavourites()
    end)



    
    
    

    

   -- local function UpdateAuctionLayout() end 

   

    
   








-------------------------------------------------------------------
-- Function that gets called when the raidleader uses
-- /gdkpleader auction [itemlink] through the eventFrame trigger.

-- If that item is already cached by the member, then proceed to 
-- update the row visuals in the FinalizeInitialAuctionRow function.

-- If that item is NOT cached, then we use the hidden AuctionReceiverFrame
-- with the GET_ITEM_INFO_RECEIVED event to cache it 
-------------------------------------------------------------------


        
    -- Hidden frame that handles the GET_ITEM_INFO_RECEIVED event
    local AuctionReceiverFrame = CreateFrame("Frame", "GDKPT_AuctionReceiverFrame")


    -- If the item is already cached, then finalize the row UI update
    local function FinalizeInitialAuctionRow(auctionId, row)
        
    local name, itemLink, quality, iLevel, minLevel, itemType, itemSubType, stackCount, equipSlot, icon

    
        -- Attempt GetItemInfo one last time, this should now succeed thanks to the event trigger.

        if row.itemID then
            name, itemLink, quality, iLevel, minLevel, itemType, itemSubType, stackCount, equipSlot, icon =
                GetItemInfo(row.itemID)
        else
            name, itemLink, quality, iLevel, minLevel, itemType, itemSubType, stackCount, equipSlot, icon =
                GetItemInfo(row.itemLink)
        end


        if not name then
            print(string.format("|cffff0000Error: Failed to get item info for auction %d after cache event. |r", auctionId))
            return
        end

        local r, g, b = GetItemQualityColor(quality)
    
        row.icon:SetTexture(icon)
        row.itemLinkText:SetText(itemLink)
        row.itemLinkText:SetTextColor(r, g, b)

    
        row.bidText:SetText(string.format("Starting Bid: |cffffd700%d|r", row.startBid))
        row.topBidderText:SetText("No bids yet")
        row.topBidderText:SetTextColor(1, 1, 1)

        local minNextBid = row.startBid

        row.bidBox:SetText("")
        row.bidButton:SetText(minNextBid .. " G")

        row:Show()
        UpdateAuctionLayout()
    end


    AuctionReceiverFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "GET_ITEM_INFO_RECEIVED" then
            local itemID, success = ...
            local key = tostring(itemID)
        
            -- Check if any pending auction is waiting for this specific itemID
            if PendingAuctions[key] and success then
                local pendingList = PendingAuctions[key]
            
                -- Process all auctions waiting for this item
                for auctionId, row in pairs(pendingList) do
                    FinalizeInitialAuctionRow(auctionId, row)
                end
            
                -- Clear the list for this item
                PendingAuctions[key] = nil
            end
        end
    end)
    AuctionReceiverFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")



local function HandleAuctionStart(auctionId, itemID, startBid, minIncrement, endTime, itemLink)

    -- Check if the leader settings have been synced. If not, do not start auctions
    if not leaderSettings.isSet then
        print("|cffff8800[GDKPT]|r Cannot start auction: Leader settings not yet synced. Use /gdkp show and click the sync button.")
        return
    end

    local row = table.remove(AuctionFramePool) or CreateAuctionRow()
    AuctionFrames[auctionId] = row

    -- Store core auction data on the row

    row.auctionId = auctionId
    row.itemID = itemID
    row.itemLink = itemLink
    row.startBid = startBid
    row.minIncrement = minIncrement
    row.endTime = tonumber(endTime)

    row.auctionNumber:SetText(auctionId)

    -- Reset the countdown timer for new auctions
    row.timeAccumulator = 0 
    row.timerText:SetText("Time Left: |cffaaaaaa--:--|r") 
    
    -- Re-enable the OnUpdate script, which was set to nil in HandleAuctionEnd for pooled frames.
    row:SetScript("OnUpdate", UpdateRowTimer)



    -- At the start of an auction there is no bidder 

    row.currentBid = 0
    row.topBidder = ""

    -- Also store the auctionId on the bidButton of that row
    row.bidButton.auctionId = auctionId

    

    local function ForceItemRequest(source)
      
        local link = itemLink or ("item:" .. itemID)
      
        if not link:find("item:") then
            link = "item:" .. tostring(itemID)
        end

        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Hide()
    end


    local retries = 0
    local maxRetries = 5
    local retryDelay = 2.0  -- seconds

    local function RetryItemCache()

        local checkLink = itemLink or ("item:" .. itemID)
        local name, link, quality, _, _, _, _, _, _, icon = GetItemInfo(checkLink)
        
        if name then
            FinalizeInitialAuctionRow(auctionId, row)
            return
        end

        retries = retries + 1
        
        if retries <= maxRetries then
            ForceItemRequest("RetryItemCache")

            local frame = CreateFrame("Frame")
            local elapsed = 0
            frame:SetScript("OnUpdate", function(self, delta)
                elapsed = elapsed + delta
                if elapsed >= retryDelay then
                    self:SetScript("OnUpdate", nil)
                    RetryItemCache()
                end
            end)   
        end
    end

    local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(itemLink)

    if name then
        FinalizeInitialAuctionRow(auctionId, row)
    else
        local key = tostring(itemID)
        PendingAuctions[key] = PendingAuctions[key] or {}
        PendingAuctions[key][auctionId] = row

        row:Hide()

        ForceItemRequest("Initial Load")
        RetryItemCache()
    end

end



-------------------------------------------------------------------
-- Function that gets called whenever anyone has bid on any auction
-------------------------------------------------------------------



    local function HandleAuctionUpdate(auctionId, newBid, topBidder, endTime)
        local row = AuctionFrames[auctionId]
        if not row then return end

        -- Update internal data
        row.currentBid = newBid
        row.topBidder = topBidder
        row.endTime = tonumber(endTime)

        -- Update UI Text
        row.bidText:SetText(string.format("Current Bid: |cffffd700%d|r", newBid))
        row.topBidderText:SetText("Top Bidder: " .. topBidder)
    
        -- Set bidder text color
        if topBidder == UnitName("player") then
            row.topBidderText:SetTextColor(0, 1, 0) -- Green if you are the top bidder
        else
            row.topBidderText:SetTextColor(1, 1, 1) -- White otherwise
        end
    
        -- Calculate and display the next minimum bid on the bidBox
        local nextMinBid = newBid + row.minIncrement
        row.bidBox:SetText("")
    
        -- Re-enable the button and set its new text
        row.bidButton:Enable()
        row.bidButton:SetText(nextMinBid .. "G")
    end






-------------------------------------------------------------------
-- Function that gets called whenever an auction ends
-------------------------------------------------------------------

local function HandleAuctionEnd(auctionId, GDKP_Pot, itemID, winningPlayer, finalBid)

    local row = AuctionFrames[auctionId]
    if not row then return end


    row:SetScript("OnUpdate", nil) -- Stop the timer

    -- Disable interaction elements
    if row.bidBox then
        row.bidBox:EnableMouse(false)
        row.bidBox:SetText("")
        -- Change border to gray for disabled state
        row.bidBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) 
    end

    if row.bidButton then
        row.bidButton:Disable()
        row.bidButton:SetText("ENDED")
    end

    -- Set the winner text and show the overlay
    if winningPlayer == "Bulk" then
        row.winnerText:SetText("BULK")
        row.winnerText:SetTextColor(1, 0, 0, 1) -- Red for Bulk
        row.endOverlay:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) -- Red border
    else
        row.winnerText:SetText("Winner: " .. winningPlayer .. " (" .. FormatMoney(finalBid*10000) .. ")")
        row.winnerText:SetTextColor(0, 1, 0, 1) -- Green text for winner
        row.endOverlay:SetBackdropBorderColor(0.2, 0.8, 0.2, 1) -- Green border
    end
    
    row.endOverlay:Show()



    
    -- Hide the row and move it to the pool for reuse
    --row:Hide()
    
    --row.auctionId = nil 
    --table.insert(AuctionFramePool, row) 
    --AuctionFrames[auctionId] = nil

    --UpdateAuctionLayout()
    UpdateTotalPotAmount(GDKP_Pot*10000)
    UpdateCurrentCutAmount(GDKP_Pot*10000/leaderSettings.splitCount)

    
    if winningPlayer == UnitName("player") and finalBid > 0 then
        
        local itemName, itemLink = GetItemInfo(itemID)
               
        -- Adding won items to PlayerWonItems table
        table.insert(PlayerWonItems, { 
            name = itemName, 
            link = itemLink, 
            bid = finalBid 
        })
        
        print(string.format("|cff00ff00[GDKPT]|r Congratulations! You won %s for %d G.", itemName, finalBid))
        
        UpdateWonItemsDisplay(AuctionWindow.WonAuctionsFrame)
    end
    

    

end



-------------------------------------------------------------------
-- Event frame that handles incoming messages from the leader Addon
-------------------------------------------------------------------


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")


eventFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)

    if prefix ~= addonPrefix or not sender or sender ~= GetRaidLeaderName() then return end
    
    local cmd, data = msg:match("([^:]+):(.*)")


    -- Version Check
    if cmd == "VERSION_CHECK" and IsInRaid() then
        SendChatMessage(string.format("[GDKPT] Version %.2f", version),"RAID")  
    end


    -- Receive the synced auction settings from the leader
    if cmd == "SETTINGS" then
        local duration, extraTime, startBid, minIncrement, splitCount = data:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        if duration and extraTime and startBid and minIncrement and splitCount then
            leaderSettings.duration = tonumber(duration)
            leaderSettings.extraTime = tonumber(extraTime)
            leaderSettings.startBid = tonumber(startBid)
            leaderSettings.minIncrement = tonumber(minIncrement)
            leaderSettings.splitCount = tonumber(splitCount)
            leaderSettings.isSet = true
            print(string.format("|cff99ff99[GDKPT]|r Received settings from |cffFFC125%s|r.", sender))


            if AuctionWindow:IsVisible() then
                SyncSettingsButton:Hide()
                AuctionScrollFrame:Show()
            end
        end
    end

 

    if cmd == "AUCTION_START" then
        local id, itemID, startBid, minInc, endTime, itemLink = data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):(.+)")
        if id and itemID and startBid and minInc and endTime and itemLink then 
           HandleAuctionStart(tonumber(id), tonumber(itemID), tonumber(startBid), tonumber(minInc), tonumber(endTime), itemLink)
        end
    elseif cmd == "AUCTION_UPDATE" then
        local id, newBid, topBidder, endTime = data:match("([^:]+):([^:]+):([^:]+):([^:]+)")
        if id and newBid and topBidder and endTime then
            HandleAuctionUpdate(tonumber(id), tonumber(newBid), topBidder, tonumber(endTime))
        end
    elseif cmd == "AUCTION_END" then

        local auctionId, GDKP_Pot, itemID, winningPlayer, finalBid = data:match("([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")
      
        if auctionId and GDKP_Pot and itemID and winningPlayer and finalBid then
            HandleAuctionEnd(tonumber(auctionId), tonumber(GDKP_Pot), tonumber(itemID), winningPlayer, tonumber(finalBid))
        end
    end

end)







-------------------------------------------------------------------
-- Toggle Button to show the main window
-------------------------------------------------------------------

local GDKPToggleButton = CreateFrame("Button", "GDKPToggleButton", UIParent)
GDKPToggleButton:SetSize(40, 40)
GDKPToggleButton:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
GDKPToggleButton:SetMovable(true)
GDKPToggleButton:EnableMouse(true)
GDKPToggleButton:RegisterForDrag("LeftButton")
GDKPToggleButton:SetFrameStrata("MEDIUM") -- Keep it above most things but below menus

-- Set the button's texture to a gold coin icon
local toggleIcon = GDKPToggleButton:CreateTexture(nil, "ARTWORK")
toggleIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
toggleIcon:SetAllPoints()

-- Add a highlight texture for when you mouse over
local toggleHighlight = GDKPToggleButton:CreateTexture(nil, "HIGHLIGHT")
toggleHighlight:SetAllPoints()
toggleHighlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
toggleHighlight:SetBlendMode("ADD")

-- Create a FontString to display the text over the icon
local buttonText = GDKPToggleButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
buttonText:SetPoint("CENTER", 0, 0)
buttonText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
buttonText:SetText("GDKPT")


-- Scripts to allow the button to be dragged around
GDKPToggleButton:SetScript("OnDragStart", GDKPToggleButton.StartMoving)
GDKPToggleButton:SetScript("OnDragStop", GDKPToggleButton.StopMovingOrSizing)

-- Click functionality: Show the main window and hide this button
GDKPToggleButton:SetScript("OnClick", function(self)
    AuctionWindow:Show()
    self:Hide()
end)

-- Hook into the main window's OnHide event to show the toggle button again
AuctionWindow:SetScript("OnHide", function()
    GDKPToggleButton:Show()
end)

-- Also ensure the toggle button is hidden when the main window is shown by any method
-- by hooking the original Show function
local originalShowFunction = AuctionWindow.Show
function AuctionWindow:Show(...)
    originalShowFunction(self, ...) -- Call the original function to show the window
    GDKPToggleButton:Hide()     -- Then, hide our toggle button
end

-- By default, the main window is hidden, so we should show the toggle button initially.
GDKPToggleButton:Show()



















-------------------------------------------------------------------
-- Function to show the auction window, called through /gdkp show
-------------------------------------------------------------------

local function ShowAuctionWindow()
    AuctionWindow:Show()
    UpdateCurrentGoldAmount()
end







-------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------


    SLASH_GDKPT1 = "/gdkp"
    SlashCmdList["GDKPT"] = function(message)
        local cmd = message:match("^(%S+)") or ""          

        if cmd == "" or cmd == "help" then
            print("|cff00ff00[GDKPT]|r Commands:")
            print("hide - hides the auction window")
            print("show - shows the main auction window")
            print("version - shows current version")
        elseif cmd == "show" or cmd == "s" or cmd == "auction" then
             ShowAuctionWindow()
        elseif cmd == "hide" or cmd == "h" then
            AuctionWindow:Hide()
        elseif cmd == "version" or cmd == "v" or cmd == "ver" then
            print("Current GDKPT Addon Version: " .. version)
        elseif cmd == "gold" or cmd == "g" then
            print("You have stolen " .. stolenGold .. " from Tehnix so far.")
            stolenGold = stolenGold + 1
        end
    end





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
 