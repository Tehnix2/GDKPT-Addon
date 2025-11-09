GDKPT.Loot = {}

local LOOT_ROW_HEIGHT = 30
local TRADE_DURATION = 7200 -- 2 hours in seconds

-- Table to store looted items with their trade timer data
GDKPT.Loot.LootedItems = GDKPT.Loot.LootedItems or {}
local lootRowPool = {}

--------------------------------------------------------------------------
-- Loot Tracking Frame
--------------------------------------------------------------------------

local LootFrame = CreateFrame("Frame", "GDKPT_LootFrame", UIParent)
LootFrame:SetSize(350, 400)
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
LootFrameTitle:SetText("Looted Items")
LootFrameTitle:SetPoint("TOP", LootFrame, "TOP", 0, -10)
LootFrameTitle:SetFont("Fonts\\FRIZQT__.TTF", 14)

-- Close Button
local CloseLootFrameButton = CreateFrame("Button", "", LootFrame, "UIPanelCloseButton")
CloseLootFrameButton:SetPoint("TOPRIGHT", -5, -5)
CloseLootFrameButton:SetSize(30, 30)

-- Scroll Frame
local LootScrollFrame = CreateFrame("ScrollFrame", "GDKP_LootScrollFrame", LootFrame, "UIPanelScrollFrameTemplate")
LootScrollFrame:SetPoint("TOPLEFT", 10, -35)
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
LootFrameToggleButton:SetSize(100, 22)
LootFrameToggleButton:SetPoint("TOP", GDKPT.UI.AuctionWindow, "TOP", 130, -15)
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
    
    -- Item Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(LOOT_ROW_HEIGHT - 4, LOOT_ROW_HEIGHT - 4)
    icon:SetPoint("LEFT", 15, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.icon = icon
    
    -- Item Name
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 8)
    nameText:SetPoint("RIGHT", -60, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    frame.nameText = nameText
    
    -- Stack Count (shows how many times this item was looted)
    local stackText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stackText:SetPoint("LEFT", icon, "RIGHT", 5, -8)
    stackText:SetTextColor(0.8, 0.8, 0.8, 1)
    frame.stackText = stackText
    
    -- Timer Text
    local timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerText:SetPoint("RIGHT", -5, 0)
    timerText:SetTextColor(1, 0.82, 0, 1)
    frame.timerText = timerText
    
    -- Tooltip
    frame:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)


    -- Favorite Star Button
    frame.favoriteButton = CreateFrame("Button", nil, frame)
    frame.favoriteButton:SetSize(16, 16)
    frame.favoriteButton:SetPoint("LEFT", frame.icon, "LEFT", -20, 0)

    frame.favoriteButton:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    frame.favoriteIcon = frame.favoriteButton:GetNormalTexture()
    frame.favoriteIcon:SetAllPoints()
    frame.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- gray when not favorited

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
            print("|cffff8800[GDKPT]|r Error: No itemID found for this loot row.")
        end
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
    
    -- Display items
    local totalHeight = 0
    local currentTime = time()
    
    for i, itemData in ipairs(sortedItems) do
        local row = lootRowPool[i]
        if not row then
            row = CreateLootRow(ScrollContent)
            table.insert(lootRowPool, row)
        end
        
        row.itemLink = itemData.itemLink
        row.itemID = itemData.itemID
        row.lootTime = itemData.lootTime
        
        local itemName, _, itemQuality, _, _, _, _, _, _, texture = GetItemInfo(itemData.itemLink)

        -- Set item name color by quality
        if itemName then
            local color = ITEM_QUALITY_COLORS[itemQuality or 1]
            if color then
                row.nameText:SetText(color.hex .. itemName .. "|r")
            else
                row.nameText:SetText(itemName)
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
        
        -- Calculate and show remaining time
        local elapsed = currentTime - itemData.lootTime
        local remaining = TRADE_DURATION - elapsed
        row.timerText:SetText(FormatTimeRemaining(remaining))
        
        -- Check if item is favorited
        local isFavorite = false
        if GDKPT.Favorites and GDKPT.Favorites.IsFavorite then
            isFavorite = GDKPT.Favorites.IsFavorite(itemData.itemID)
        end

        -- Update star color
        if row.favoriteIcon then
            if isFavorite then
                row.favoriteIcon:SetVertexColor(1, 0.8, 0, 1) -- gold
            else
                row.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1) -- gray
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
-- Add Looted Item
--------------------------------------------------------------------------

function GDKPT.Loot.AddLootedItem(itemLink)
    if not itemLink then return end
    
    local itemID = tonumber(itemLink:match("item:(%d+):"))
    if not itemID then return end
    
    table.insert(GDKPT.Loot.LootedItems, {
        itemLink = itemLink,
        itemID = itemID,
        lootTime = time()
    })
    
    if LootFrame:IsVisible() then
        GDKPT.Loot.UpdateLootDisplay()
    end
end

--------------------------------------------------------------------------
-- Timer Update (updates countdown timers)
--------------------------------------------------------------------------

local timerFrame = CreateFrame("Frame")
local timeSinceLastUpdate = 0

timerFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    
    if timeSinceLastUpdate >= 1 then
        timeSinceLastUpdate = 0
        
        if LootFrame:IsVisible() then
            GDKPT.Loot.UpdateLootDisplay()
        end
        
        local currentTime = time()
        for i = #GDKPT.Loot.LootedItems, 1, -1 do
            local itemData = GDKPT.Loot.LootedItems[i]
            local elapsed = currentTime - itemData.lootTime
            if elapsed >= TRADE_DURATION then
                table.remove(GDKPT.Loot.LootedItems, i)
            end
        end
    end
end)

--------------------------------------------------------------------------
-- Clear All Looted Items
--------------------------------------------------------------------------

function GDKPT.Loot.ClearAllLootedItems()
    wipe(GDKPT.Loot.LootedItems)
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
-- Slash Command: /gdkptadd [itemLink]
-- Example usage: /gdkptadd [Ashkandi, Greatsword of the Brotherhood]
--------------------------------------------------------------------------

SLASH_GDKPTADD1 = "/gdkptadd"

SlashCmdList["GDKPTADD"] = function(msg)
    local itemLink = msg:match("|c%x+|Hitem:.-|h%[.-%]|h|r")
    if not itemLink then
        print("|cffff8800[GDKPT]|r Usage: Shift-click an item link after /gdkptadd")
        return
    end

    GDKPT.Loot.AddLootedItem(itemLink)
    print("|cff00ff00[GDKPT]|r Added " .. itemLink .. " to loot tracker.")
end