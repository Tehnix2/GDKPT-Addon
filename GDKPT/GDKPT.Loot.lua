GDKPT.Loot = GDKPT.Loot or {}

local LOOT_ROW_HEIGHT = 30
local TRADE_DURATION = 7200 -- 2 hours in seconds

-- Saved variables for persistence
GDKPT_Loot_Data = GDKPT_Loot_Data or {}
GDKPT.Loot.LootedItems = GDKPT_Loot_Data

local lootRowPool = {}      -- table that stores all rows for the loot tracker

-- Filter State
GDKPT.Loot.CurrentFilter = "ALL" -- ALL, TRADEABLE, AUCTIONED, WINNER, BULK, UNAUCTIONED

-- Pre-Bid Data (Session only)
GDKPT.Loot.PreBids = {}


--------------------------------------------------------------------------
-- Loot Tracking Frame
--------------------------------------------------------------------------

local LootFrame = CreateFrame("Frame", "GDKPT_LootFrame", UIParent)
LootFrame:SetSize(400, 450)
LootFrame:SetPoint("RIGHT", UIParent, "RIGHT", -50, 0)
LootFrame:SetMovable(true)
LootFrame:EnableMouse(true)
LootFrame:RegisterForDrag("LeftButton")
LootFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
LootFrame:SetBackdropColor(0, 0, 0, 0.8)
LootFrame:Hide()
LootFrame:SetClampedToScreen(true)
LootFrame:SetFrameStrata("MEDIUM")
LootFrame:SetFrameLevel(10)

LootFrame:SetScript("OnDragStart", LootFrame.StartMoving)
LootFrame:SetScript("OnDragStop", LootFrame.StopMovingOrSizing)

_G["GDKPT_LootFrame"] = LootFrame
tinsert(UISpecialFrames, "GDKPT_LootFrame")

-- Title
local LootFrameTitle = LootFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
LootFrameTitle:SetText("Loot Tracker")
LootFrameTitle:SetPoint("TOP", LootFrame, "TOP", 0, -10)
LootFrameTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

-- Close Button
local CloseLootFrameButton = CreateFrame("Button", "", LootFrame, "UIPanelCloseButton")
CloseLootFrameButton:SetPoint("TOPRIGHT", -5, -5)
CloseLootFrameButton:SetSize(30, 30)


--------------------------------------------------------------------------
-- Filter Dropdown
--------------------------------------------------------------------------

GDKPT.Loot.CurrentFilter = "ALL"

local FilterMenu = CreateFrame("Frame", "GDKPT_LootFilterMenu", LootFrame, "UIDropDownMenuTemplate")
FilterMenu:SetPoint("TOPLEFT", LootFrame, "TOPLEFT", -10, -25)

local function OnFilterSelect(self, arg1)
    GDKPT.Loot.CurrentFilter = arg1
    local displayText = arg1
    if arg1 == "ALL" then displayText = "All Items"
    elseif arg1 == "TRADEABLE" then displayText = "Tradeable"
    elseif arg1 == "AUCTIONED" then displayText = "Auctioned"
    elseif arg1 == "WINNER" then displayText = "Has Winner"
    elseif arg1 == "BULK" then displayText = "Bulk"
    elseif arg1 == "UNAUCTIONED" then displayText = "Unauctioned"
    end
    UIDropDownMenu_SetText(FilterMenu, displayText)
    GDKPT.Loot.UpdateLootDisplay()
end

local function InitFilterMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    
    info.text = "All Items"
    info.arg1 = "ALL"
    info.func = OnFilterSelect
    info.checked = (GDKPT.Loot.CurrentFilter == "ALL")
    UIDropDownMenu_AddButton(info, level)

    info.text = "Tradeable"
    info.arg1 = "TRADEABLE"
    info.func = OnFilterSelect
    info.checked = (GDKPT.Loot.CurrentFilter == "TRADEABLE")
    UIDropDownMenu_AddButton(info, level)

    info.text = "Auctioned"
    info.arg1 = "AUCTIONED"
    info.func = OnFilterSelect
    info.checked = (GDKPT.Loot.CurrentFilter == "AUCTIONED")
    UIDropDownMenu_AddButton(info, level)

    info.text = "Has Winner"
    info.arg1 = "WINNER"
    info.func = OnFilterSelect
    info.checked = (GDKPT.Loot.CurrentFilter == "WINNER")
    UIDropDownMenu_AddButton(info, level)

    info.text = "Bulk"
    info.arg1 = "BULK"
    info.func = OnFilterSelect
    info.checked = (GDKPT.Loot.CurrentFilter == "BULK")
    UIDropDownMenu_AddButton(info, level)
    
    info.text = "Unauctioned"
    info.arg1 = "UNAUCTIONED"
    info.func = OnFilterSelect
    info.checked = (GDKPT.Loot.CurrentFilter == "UNAUCTIONED")
    UIDropDownMenu_AddButton(info, level)
end

UIDropDownMenu_Initialize(FilterMenu, InitFilterMenu)
UIDropDownMenu_SetWidth(FilterMenu, 100)
UIDropDownMenu_SetText(FilterMenu, "All Items")



--------------------------------------------------------------------------
-- Manual Add Button
--------------------------------------------------------------------------

local ManualAddBtn = CreateFrame("Button", nil, LootFrame, "UIPanelButtonTemplate")
ManualAddBtn:SetSize(20, 20)
ManualAddBtn:SetPoint("TOPRIGHT", LootFrame, "TOPRIGHT", -35, -10)
ManualAddBtn:SetText("+")
ManualAddBtn:SetScript("OnClick", function()
    StaticPopupDialogs["GDKPT_MANUAL_ADD_LOOT"] = {
        text = "Manually add an item to the loot tracker \nby puting in the itemID.",
        button1 = "Add",
        button2 = "Cancel",
        hasEditBox = true,
        OnShow = function(self)
            self.editBox:SetFocus()
            self.editBox:SetText("")
        end,
        OnAccept = function(self)
            local text = self.editBox:GetText()
            if text and text ~= "" then
                local itemLink = text:match("(|c%x+|Hitem:[^|]+|h%[.-%]|h|r)")
                if not itemLink then
                    local itemID = tonumber(text)
                    if itemID then
                        itemLink = select(2, GetItemInfo(itemID))
                    end
                end
                
                if itemLink then
                    GDKPT.Loot.AddLootedItem(itemLink)
                    print(GDKPT.Core.print .. "Added " .. itemLink .. " to loot tracker")
                else
                    print(GDKPT.Core.errorprint .. "Invalid item. Enter a valid item id.")
                end
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            parent.button1:Click()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("GDKPT_MANUAL_ADD_LOOT")
end)

ManualAddBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Add Item Manually", 1, 1, 1)
    GameTooltip:AddLine("Click to manually add an item to the loot tracker", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)

ManualAddBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


--------------------------------------------------------------------------
-- Pre-Bid System
--------------------------------------------------------------------------

GDKPT.Loot.PreBids = GDKPT.Loot.PreBids or {}

local function ShowPreBidPopup(itemID, itemName, itemLink)
    local currentBid = GDKPT.Loot.PreBids[itemID] or ""
    
    StaticPopupDialogs["GDKPT_SET_PREBID"] = {
        text = "Set Pre-Bid for " .. (itemLink or itemName) .. ":\n\n|cffaaaaaaThis will auto-fill when auction starts|r",
        button1 = "Set",
        button2 = "Clear",
        button3 = "Cancel",
        hasEditBox = true,
        OnShow = function(self)
            self.editBox:SetText(tostring(currentBid))
            self.editBox:SetNumeric(true)
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local amount = tonumber(self.editBox:GetText())
            if amount and amount > 0 then
                GDKPT.Loot.PreBids[itemID] = amount
                print(GDKPT.Core.print .. "Pre-bid set to " .. amount .. "g for " .. (itemLink or itemName))
                GDKPT.Loot.UpdateLootDisplay()
            else
                print(GDKPT.Core.errorprint .. "Invalid bid amount.")
            end
        end,
        OnCancel = function(self)
            GDKPT.Loot.PreBids[itemID] = nil
            print(GDKPT.Core.print .. "Pre-bid cleared for " .. (itemLink or itemName))
            GDKPT.Loot.UpdateLootDisplay()
        end,
        EditBoxOnEnterPressed = function(self)
            self:GetParent().button1:Click()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("GDKPT_SET_PREBID")
end

GDKPT.Loot.ShowPreBidPopup = ShowPreBidPopup




--------------------------------------------------------------------------
-- Scroll Frame
--------------------------------------------------------------------------

local LootScrollFrame = CreateFrame("ScrollFrame", "GDKP_LootScrollFrame", LootFrame, "UIPanelScrollFrameTemplate")
LootScrollFrame:SetPoint("TOPLEFT", 10, -55)
LootScrollFrame:SetPoint("BOTTOMRIGHT", -30, 45)

local LootScrollContent = CreateFrame("Frame", nil, LootScrollFrame)
LootScrollContent:SetWidth(LootScrollFrame:GetWidth())
LootScrollContent:SetHeight(1)
LootScrollFrame:SetScrollChild(LootScrollContent)

GDKPT.Loot.LootFrame = LootFrame
GDKPT.Loot.LootScrollFrame = LootScrollFrame
GDKPT.Loot.LootScrollContent = LootScrollContent


--------------------------------------------------------------------------
-- Loot Frame Scaling
--------------------------------------------------------------------------

local LootResizeGrip = CreateFrame("Button", nil, LootFrame)
LootResizeGrip:SetSize(16, 16)
LootResizeGrip:SetPoint("BOTTOMRIGHT", -4, 4)
LootResizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
LootResizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
LootResizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

local startX, startScale

LootResizeGrip:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        startX = GetCursorPosition()
        startScale = LootFrame:GetScale()
        self:SetButtonState("PUSHED", true)
        self:SetScript("OnUpdate", function()
            local x = GetCursorPosition()
            local delta = (x - startX) / 300  
            local newScale = math.max(0.5, math.min(2.0, startScale + delta))
            LootFrame:SetScale(newScale)
        end)
    end
end)

LootResizeGrip:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
    self:SetButtonState("NORMAL", false)
end)



--------------------------------------------------------------------------
-- Toggle Button (placed on main auction window)
--------------------------------------------------------------------------

local LootFrameToggleButton = CreateFrame("Button", "GDKP_LootFrameButton", GDKPT.UI.AuctionWindow, "UIPanelButtonTemplate")
LootFrameToggleButton:SetSize(120, 22)
LootFrameToggleButton:SetPoint("TOP", GDKPT.UI.AuctionWindow, "TOP", 55, -15)
LootFrameToggleButton:SetText("Loot Tracker")

LootFrameToggleButton:SetScript("OnClick", function(self)
    if LootFrame:IsVisible() then
        LootFrame:Hide()
    else
        GDKPT.Loot.UpdateLootDisplay()
        LootFrame:Show()
    end
end)

GDKPT.Loot.LootFrameToggleButton = LootFrameToggleButton


--------------------------------------------------------------------------
-- Helper: Get item auction status
--------------------------------------------------------------------------

local function GetItemAuctionStatus(itemID)
    local wasAuctioned = false
    local auctionEnded = false
    local auctionWinner = nil
    local auctionBid = nil
    local isBulk = false
    
    -- Check AuctionedItems (current session auctions)
    if GDKPT.Core.AuctionedItems then
        for _, aItem in ipairs(GDKPT.Core.AuctionedItems) do
            if aItem.itemID == itemID then
                wasAuctioned = true
                auctionEnded = aItem.ended or false
                
                -- If auction ended, get winner info from AuctionedItems first
                if auctionEnded then
                    if aItem.winner == "Bulk" then
                        isBulk = true
                    elseif aItem.winner and aItem.winningBid then
                        auctionWinner = aItem.winner
                        auctionBid = aItem.winningBid
                    end
                    
                    -- Fallback: check auction row if winner info not in AuctionedItems
                    if not auctionWinner and not isBulk then
                        for auctionId, row in pairs(GDKPT.Core.AuctionFrames) do
                            if row.itemID == itemID and row.winnerText then
                                local winnerStr = row.winnerText:GetText()
                                if winnerStr then
                                    if winnerStr == "BULK" then
                                        isBulk = true
                                    elseif winnerStr:match("^Winner: ") then
                                        local name, bid = winnerStr:match("^Winner: ([^%(]+) %(([%d,]+)g?%)")
                                        if name then
                                            auctionWinner = name:trim()
                                            auctionBid = tonumber((bid or ""):gsub(",", ""))
                                        end
                                    end
                                end
                                break
                            end
                        end
                    end
                end
                break  -- Found the item, stop searching
            end
        end
    end
    
    return {
        wasAuctioned = wasAuctioned,
        auctionEnded = auctionEnded,
        auctionWinner = auctionWinner,
        auctionBid = auctionBid,
        isBulk = isBulk,
    }
end


--------------------------------------------------------------------------
-- Create Individual Loot Row
--------------------------------------------------------------------------

local function CreateLootRow(parent)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetHeight(LOOT_ROW_HEIGHT)
    frame:SetWidth(parent:GetWidth())
    frame:EnableMouse(true)
    
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    frame.bg = bg
    
    -- Pre-bid button (coin icon)
    frame.preBidButton = CreateFrame("Button", nil, frame)
    frame.preBidButton:SetSize(14, 14)
    frame.preBidButton:SetPoint("LEFT", frame, "LEFT", 2, 0)
    frame.preBidButton:SetNormalTexture("Interface\\Icons\\INV_Misc_Coin_01")
    frame.preBidIcon = frame.preBidButton:GetNormalTexture()
    frame.preBidIcon:SetAllPoints()
    frame.preBidIcon:SetVertexColor(1, 0.84, 0, 0.3)
    
    frame.preBidButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Pre-Bid", 1, 1, 1)
        local preBid = GDKPT.Loot.PreBids[frame.itemID]
        if preBid then
            GameTooltip:AddLine("Current: " .. preBid .. "g", 0, 1, 0)
            GameTooltip:AddLine("Click to change", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("Click to set auto-bid", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    
    frame.preBidButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    frame.preBidButton:SetScript("OnClick", function(self)
        if frame.itemID and frame.itemLink then
            local itemName = GetItemInfo(frame.itemLink)
            ShowPreBidPopup(frame.itemID, itemName or "Unknown Item", frame.itemLink)
        end
    end)

    -- Favorite Star Button
    frame.favoriteButton = CreateFrame("Button", nil, frame)
    frame.favoriteButton:SetSize(14, 14)
    frame.favoriteButton:SetPoint("LEFT", frame.preBidButton, "RIGHT", 2, 0)

    frame.favoriteButton:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    frame.favoriteIcon = frame.favoriteButton:GetNormalTexture()
    frame.favoriteIcon:SetAllPoints()
    frame.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1)

    local highlight = frame.favoriteButton:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetVertexColor(1, 1, 1, 0.5)
    frame.favoriteButton:SetHighlightTexture(highlight)

    frame.favoriteButton:SetScript("OnClick", function(self)
        if frame.itemID then
            GDKPT.Favorites.ToggleFavorite(frame.itemLink)
            GDKPT.Loot.UpdateLootDisplay()
        else
            print(GDKPT.Core.errorprint .. "No itemID found for this loot row.")
        end
    end)
    
    -- Item Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(LOOT_ROW_HEIGHT - 4, LOOT_ROW_HEIGHT - 4)
    icon:SetPoint("LEFT", frame.favoriteButton, "RIGHT", 4, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.icon = icon
    
    -- Item Name
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 6)
    nameText:SetPoint("RIGHT", -70, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    frame.nameText = nameText

    local stackText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stackText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
    stackText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    stackText:SetTextColor(1, 1, 1, 1)
    frame.stackText = stackText
    
    -- Pre-bid indicator text
    local preBidText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    preBidText:SetPoint("LEFT", icon, "RIGHT", 5, -6)
    preBidText:SetTextColor(1, 0.84, 0, 1)
    preBidText:SetFont("Fonts\\FRIZQT__.TTF", 9)
    frame.preBidText = preBidText
    
    -- Timer Text
    local timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerText:SetPoint("RIGHT", -5, 0)
    timerText:SetTextColor(1, 0.82, 0, 1)
    frame.timerText = timerText

    -- Overlay status text (AUCTIONED / WINNER / BULK)
    frame.StatusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.StatusText:SetPoint("CENTER", frame, "CENTER", 20, 0)
    frame.StatusText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    frame.StatusText:SetTextColor(1, 1, 0, 1) 
    frame.StatusText:SetText("")
    frame.StatusText:SetWordWrap(false)
    
    -- Tooltip
    frame:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            
            local status = GetItemAuctionStatus(self.itemID)
            if status.wasAuctioned then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff00ff00This item was auctioned|r", 1, 1, 1)
                if status.isBulk then
                    GameTooltip:AddLine("Result: Went to Bulk", 1, 0.5, 0)
                elseif status.auctionWinner then
                    GameTooltip:AddLine("Winner: " .. status.auctionWinner, 0, 0.8, 1)
                    if status.auctionBid then
                        GameTooltip:AddLine(string.format("Winning Bid: %dg", status.auctionBid), 1, 0.84, 0)
                    end
                elseif not status.auctionEnded then
                    GameTooltip:AddLine("Status: Auction in progress", 1, 1, 0)
                end
            end
            
            local preBid = GDKPT.Loot.PreBids[self.itemID]
            if preBid then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Pre-Bid Set: " .. preBid .. "g", 1, 0.84, 0)
            end
            
            GameTooltip:Show()
        end
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return frame
end

--------------------------------------------------------------------------
-- Format Time Remaining
--------------------------------------------------------------------------

local function FormatTimeRemaining(seconds)
    if seconds <= 0 then
        return "|cffff0000EXPIRED|r"
    end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("|cff00ff00%dh %dm|r", hours, minutes)
    elseif minutes > 0 then
        return string.format("|cffffff00%dm %ds|r", minutes, secs)
    else
        return string.format("|cffff8800%ds|r", secs)
    end
end

--------------------------------------------------------------------------
-- Update Loot Display
--------------------------------------------------------------------------


--------------------------------------------------------------------------
-- Update Loot Display to draw rows inside the LootTracker and update them
--------------------------------------------------------------------------

function GDKPT.Loot.UpdateLootDisplay()

    local ScrollContent = GDKPT.Loot.LootScrollContent
    if not ScrollContent then return end
    
    -- Hide all existing rows
    for _, row in ipairs(lootRowPool) do
        row:Hide()
    end
    
    -- Sort looted items by loot time (newest first)
    local sortedItems = {}
    for _, itemData in ipairs(GDKPT.Loot.LootedItems) do
        table.insert(sortedItems, itemData)
    end
    
    table.sort(sortedItems, function(a, b)
        return a.lootTime > b.lootTime
    end)
    
    -- Count occurrences of each item
    local itemCounts = {}
    for _, itemData in ipairs(sortedItems) do
        local itemID = itemData.itemID
        itemCounts[itemID] = (itemCounts[itemID] or 0) + 1
    end
    

-- Build auction status cache for filtering and display
-- ONLY checks current session auctions, NOT persisted history
-- Build auction status cache for filtering and display
    local auctionStatusCache = {}
    for _, itemData in ipairs(sortedItems) do
        local itemID = itemData.itemID
        if not auctionStatusCache[itemID] then
            local wasAuctioned = false
            local auctionWinner = nil
            local auctionBid = nil
            local auctionEnded = false
            local isBulk = false
        
            -- Check AuctionedItems (current session auctions)
            if GDKPT.Core.AuctionedItems then
                for _, aItem in ipairs(GDKPT.Core.AuctionedItems) do
                    if aItem.itemID == itemID then
                        wasAuctioned = true
                        auctionEnded = aItem.ended or false
                    
                        -- If auction ended, get winner info from AuctionedItems first
                        if auctionEnded then
                            if aItem.winner == "Bulk" then
                                isBulk = true
                            elseif aItem.winner and aItem.winningBid then
                                auctionWinner = aItem.winner
                                auctionBid = aItem.winningBid
                            end
                        
                            -- Fallback: check auction row if winner info not in AuctionedItems
                            if not auctionWinner and not isBulk then
                                for auctionId, row in pairs(GDKPT.Core.AuctionFrames) do
                                    if row.itemID == itemID and row.winnerText then
                                        local winnerStr = row.winnerText:GetText()
                                        if winnerStr then
                                            if winnerStr == "BULK" then
                                                isBulk = true
                                            elseif winnerStr:match("^Winner: ") then
                                                local name, bid = winnerStr:match("^Winner: ([^%(]+) %(([%d,]+)g?%)")
                                                if name then
                                                    auctionWinner = name:trim()
                                                    auctionBid = tonumber((bid or ""):gsub(",", ""))
                                                end
                                            end
                                        end
                                        break
                                    end
                                end
                            end
                        end
                        break  -- Found the item, stop searching
                    end
                end
            end
        
            auctionStatusCache[itemID] = {
                wasAuctioned = wasAuctioned,
                auctionWinner = auctionWinner,
                auctionBid = auctionBid,
                auctionEnded = auctionEnded,
                isBulk = isBulk
            }
        end
    end
    
    -- Apply filter
    local filteredItems = {}
    for _, itemData in ipairs(sortedItems) do
        local shouldShow = false
        local status = auctionStatusCache[itemData.itemID]
        
        if GDKPT.Loot.CurrentFilter == "ALL" then
            shouldShow = true
        elseif GDKPT.Loot.CurrentFilter == "TRADEABLE" then
            shouldShow = itemData.isTradeable
        elseif GDKPT.Loot.CurrentFilter == "AUCTIONED" then
            shouldShow = status.wasAuctioned
        elseif GDKPT.Loot.CurrentFilter == "WINNER" then
            shouldShow = status.auctionWinner and status.auctionWinner ~= "" and not status.isBulk
        elseif GDKPT.Loot.CurrentFilter == "BULK" then
            shouldShow = status.isBulk
        elseif GDKPT.Loot.CurrentFilter == "UNAUCTIONED" then
            shouldShow = not status.wasAuctioned
        end
        
        if shouldShow then
            table.insert(filteredItems, itemData)
        end
    end
    
    -- Display items
    local totalHeight = 0
    local currentTime = time()
    
    -- Display a row for every filtered item
    for i, itemData in ipairs(filteredItems) do
        local row = lootRowPool[i]
        if not row then
            row = CreateLootRow(ScrollContent)
            table.insert(lootRowPool, row)
        end
        
        row.itemLink = itemData.itemLink
        row.itemID = itemData.itemID
        row.lootTime = itemData.lootTime
        
        local itemName, _, itemQuality, _, _, _, _, _, _, texture = GetItemInfo(itemData.itemLink)

        -- Get cached auction status
        local status = auctionStatusCache[itemData.itemID]

        -- Reset status first
        row.StatusText:SetText("")

        if status.wasAuctioned then
            if status.auctionWinner and not status.isBulk then
                row.StatusText:SetText("WINNER: " .. status.auctionWinner .. "  " .. (status.auctionBid or 0))
                row.StatusText:SetTextColor(0, 1, 0, 1) -- Green for winner
            elseif status.isBulk then
                row.StatusText:SetText("BULK")
                row.StatusText:SetTextColor(1, 0.5, 0, 1) -- Orange for bulk
            elseif status.auctionEnded then
                row.StatusText:SetText("BULK")
                row.StatusText:SetTextColor(1, 0.5, 0, 1) -- Orange for bulk
            else
                row.StatusText:SetText("AUCTIONED")
                row.StatusText:SetTextColor(1, 1, 0, 1) -- Yellow for active
            end
        end

        -- Set item name with auction indicator
        if itemName then
            local color = ITEM_QUALITY_COLORS[itemQuality or 1]
            local nameText = itemName
            
            if color then
                row.nameText:SetText(color.hex .. nameText .. "|r")
            else
                row.nameText:SetText(nameText)
            end
        else
            row.nameText:SetText("Unknown Item")
        end

        row.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

        -- Show count
        local count = itemCounts[itemData.itemID]
        if count > 1 then
            row.stackText:SetText(string.format("x%d", count))
        else
            row.stackText:SetText("")
        end

        if itemData.isTradeable then
            row.timerText:SetText("|cff00ff00Tradeable|r")
        else
            local remaining = TRADE_DURATION - (time() - itemData.lootTime)
            if remaining > 0 then
                row.timerText:SetText(FormatTimeRemaining(remaining))
            else
                row.timerText:SetText("|cffff0000Expired|r")
            end
        end

        -- Check if item is favorited
        local isFavorite = false
        if GDKPT.Favorites and GDKPT.Favorites.IsFavorite then
            isFavorite = GDKPT.Favorites.IsFavorite(itemData.itemID)
        end

        -- Update star color
        if row.favoriteIcon then
            if isFavorite then
                row.favoriteIcon:SetVertexColor(1, 0.8, 0, 1)
            else
                row.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1)
            end
        end
        
        -- Update pre-bid icon
        if row.preBidIcon then
            local preBid = GDKPT.Loot.PreBids[itemData.itemID]
            if preBid then
                row.preBidIcon:SetVertexColor(1, 0.84, 0, 1)
            else
                row.preBidIcon:SetVertexColor(1, 0.84, 0, 0.3)
            end
        end
        
        -- Set background color
        if isFavorite then
            row.bg:SetVertexColor(0.8, 0.7, 0.1, 0.6)
        elseif i % 2 == 0 then
            row.bg:SetVertexColor(0.15, 0.15, 0.15, 0.5)
        else
            row.bg:SetVertexColor(0.1, 0.1, 0.1, 0.5)
        end

        -- Update tooltip to show auction info
        row:SetScript("OnEnter", function(self)
            if self.itemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.itemLink)
                
                local st = auctionStatusCache[self.itemID]
                if st and st.wasAuctioned then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cff00ff00This item was auctioned|r", 1, 1, 1)
                    if st.isBulk then
                        GameTooltip:AddLine("Result: Went to Bulk (no bids)", 1, 0.5, 0)
                    elseif st.auctionWinner then
                        GameTooltip:AddLine(string.format("Winner: %s", st.auctionWinner), 0.8, 0.8, 0.8)
                        if st.auctionBid then
                            GameTooltip:AddLine(string.format("Winning Bid: %dg", st.auctionBid), 1, 0.84, 0)
                        end
                    else
                        GameTooltip:AddLine("Status: Auction in progress", 1, 1, 0)
                    end
                end
                
                -- Show pre-bid info
                local preBid = GDKPT.Loot.PreBids[self.itemID]
                if preBid then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(string.format("|cffffd700Pre-Bid Set: %dg|r", preBid), 1, 0.84, 0)
                end
                
                GameTooltip:Show()
            end
        end)
        
        -- Position row
        local yPosition = -2 - ((i - 1) * LOOT_ROW_HEIGHT)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ScrollContent, "TOPLEFT", 2, yPosition)
        row:SetWidth(ScrollContent:GetWidth() - 4)
        row:Show()
        
        totalHeight = totalHeight + LOOT_ROW_HEIGHT
    end
    
    local contentHeight = math.max(LootScrollFrame:GetHeight() - 10, totalHeight + 10)
    ScrollContent:SetHeight(contentHeight)
end



--------------------------------------------------------------------------
-- Add Looted Item (with persistence)
--------------------------------------------------------------------------

function GDKPT.Loot.AddLootedItem(itemLink)
    if not itemLink then return end

    local itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemLink)
    if not itemName then
        print("|cffff0000[GDKPT]|r Invalid item link.")
        return
    end

    local itemID = tonumber(itemLink:match("item:(%d+):"))
    if not itemID then
        print("|cffff0000[GDKPT]|r Could not parse itemID from link.")
        return
    end

    -- Hidden tooltip scan
    local scanTooltip = CreateFrame("GameTooltip", "GDKPT_LootScanTooltip", nil, "GameTooltipTemplate")
    scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTooltip:SetHyperlink(itemLink)
    scanTooltip:Show()

    local isBoP = false
    for i = 1, scanTooltip:NumLines() do
        local line = _G["GDKPT_LootScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and (
                text:find(ITEM_BIND_ON_PICKUP) or
                text:find("Soulbound") or
                text:find("Account Bound") or
                text:find("Binds to realm")
            ) then
                isBoP = true
                break
            end
        end
    end
    scanTooltip:Hide()

    local isTradeable = not isBoP

    local newItem = {
        itemLink = itemLink,
        itemID = itemID,
        itemName = itemName,
        itemRarity = itemRarity,
        itemTexture = itemTexture,
        lootTime = time(),
        isTradeable = isTradeable,
    }
    
    -- Add to both tables for persistence
    table.insert(GDKPT.Loot.LootedItems, newItem)
    
    -- Ensure saved variable is updated
    --if GDKPT_Loot_Data then
    --    table.insert(GDKPT_Loot_Data, newItem)
    --end

    if GDKPT.Loot.LootFrame and GDKPT.Loot.LootFrame:IsVisible() then
        GDKPT.Loot.UpdateLootDisplay()
    end
end


--------------------------------------------------------------------------
-- Timer Update (updates countdown timers once per minute)
--------------------------------------------------------------------------

local timerFrame = CreateFrame("Frame")
local timeSinceLastUpdate = 0
local UPDATE_INTERVAL = 60 

timerFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed

    if timeSinceLastUpdate >= UPDATE_INTERVAL then
        timeSinceLastUpdate = timeSinceLastUpdate - UPDATE_INTERVAL
        
        if GDKPT.Loot.LootFrame and GDKPT.Loot.LootFrame:IsVisible() then
            GDKPT.Loot.UpdateLootDisplay()
        end
        
        local currentTime = time()
        
        -- Remove expired items only once per minute
        for i = #GDKPT.Loot.LootedItems, 1, -1 do
            local itemData = GDKPT.Loot.LootedItems[i]
            if itemData and not itemData.isTradeable then
                if currentTime - itemData.lootTime >= TRADE_DURATION then
                    table.remove(GDKPT.Loot.LootedItems, i)
                    -- Also remove from saved variable
                    if GDKPT_Loot_Data then
                        for j = #GDKPT_Loot_Data, 1, -1 do
                            local savedItem = GDKPT_Loot_Data[j]
                            if savedItem.itemID == itemData.itemID and savedItem.lootTime == itemData.lootTime then
                                table.remove(GDKPT_Loot_Data, j)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)


--------------------------------------------------------------------------
-- Slash Command: /gdkptadd [itemLink]
--------------------------------------------------------------------------

SLASH_GDKPTADD1 = "/gdkptadd"

SlashCmdList["GDKPTADD"] = function(msg)
    local itemLink = msg:match("(|c%x+|Hitem:[^|]+|h%[.-%]|h|r)")
    if not itemLink then
        print("|cffff0000[GDKPT]|r Usage: /gdkptadd [itemLink]")
        print("Example: /gdkptadd [Ashkandi, Greatsword of the Brotherhood]")
        return
    end

    if GDKPT.Loot and GDKPT.Loot.AddLootedItem then
        GDKPT.Loot.AddLootedItem(itemLink)
        print("|cff00ff00[GDKPT]|r Added test item to loot tracker: " .. itemLink)
        if GDKPT.Loot.LootFrame and GDKPT.Loot.LootFrame:IsVisible() then
            GDKPT.Loot.UpdateLootDisplay()
        end
    else
        print("|cffff0000[GDKPT]|r Loot tracker not loaded.")
    end
end



--------------------------------------------------------------------------
-- Clear All Looted Items
--------------------------------------------------------------------------

function GDKPT.Loot.ClearAllLootedItems()
    wipe(GDKPT.Loot.LootedItems)
    if GDKPT_Loot_Data then
        wipe(GDKPT_Loot_Data)
    end
    GDKPT.Loot.UpdateLootDisplay()
    print("|cff00ff00[GDKPT]|r Cleared all looted items.")
end

local ClearButton = CreateFrame("Button", nil, LootFrame, "UIPanelButtonTemplate")
ClearButton:SetSize(80, 20)
ClearButton:SetPoint("BOTTOM", LootFrame, "BOTTOM", 0, 15)
ClearButton:SetText("Clear All")
ClearButton:SetScript("OnClick", function()
    StaticPopupDialogs["GDKPT_CONFIRM_CLEAR_LOOT"] = {
        text = "Clear all looted items from the tracker?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            GDKPT.Loot.ClearAllLootedItems()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("GDKPT_CONFIRM_CLEAR_LOOT")
end)


--------------------------------------------------------------------------
-- Initialize Loot Data from Saved Variables
--------------------------------------------------------------------------

local function InitializeLootData()
    if GDKPT_Loot_Data and #GDKPT_Loot_Data > 0 then
        GDKPT.Loot.LootedItems = GDKPT_Loot_Data
    else
        GDKPT_Loot_Data = GDKPT.Loot.LootedItems
    end
end

-- Register for addon loaded to initialize data
local lootInitFrame = CreateFrame("Frame")
lootInitFrame:RegisterEvent("ADDON_LOADED")
lootInitFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "GDKPT" then
        InitializeLootData()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)





