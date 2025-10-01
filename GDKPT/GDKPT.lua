-- Parallelized GDKP Addon for 3.3.5 servers
-- RaidMember Version
-- Version: 0.1
-- Made by @Tehnix


local addonName = "GDKPT"
local version = 0.1
local addonPrefix = "GDKP"


-- Table to keep track of the UI frames for each active auction
local AuctionFrames = {}
local AuctionFramePool = {} -- To reuse frames instead of creating/destroying them


local totalPot = 1343423420      -- Variables for the bottom info panel
local currentCut = 2000001200


local stolenGold = 1  -- meme

local AuctionTable = {}














---------------------------------------------------------------------------------------------------------------
-------------------------------------------Main Auction Window-------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------


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

    _G["GDKP_Auction_Window"] = AuctionWindow -- add the main GDKP auction window to global variables so that it can be closed with Esc
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



---------------------------------------------------------------------------------------------------------------
-------------------------------------------Bottom Info Panel---------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

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



local function FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local remainingCopper = copper % 100

    local goldIcon = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:0:0|t"
    local silverIcon = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:0:0|t"
    local copperIcon = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:0:0|t"

    return string.format("%d%s %d%s %d%s", gold, goldIcon, silver, silverIcon, remainingCopper, copperIcon)
end


-- Functions to update the data on the bottom info panel

local function UpdateTotalPotAmount(totalPot)
    TotalPotAmountText:SetText(string.format("%s", FormatMoney(totalPot)))
end

local function UpdateCurrentCutAmount(currentCut)
    CurrentCutAmountText:SetText(string.format("%s", FormatMoney(currentCut)))
end

local function UpdateCurrentGoldAmount()
    CurrentGoldAmountText:SetText(FormatMoney(GetMoney()))
end




---------------------------------------------------------------------------------------------------------------
-------------------------------------------Scroll Frame--------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------



local AuctionScrollFrame = CreateFrame("ScrollFrame", "GDKP_Auction_ScrollFrame", AuctionWindow, "UIPanelScrollFrameTemplate")
AuctionScrollFrame:SetPoint("TOPLEFT", 10, -40)
AuctionScrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

local AuctionContentFrame = CreateFrame("Frame", "GDKP_Auction_ContentFrame", AuctionScrollFrame)
AuctionContentFrame:SetSize(760, 100) -- Initial size, will grow as needed
AuctionScrollFrame:SetScrollChild(AuctionContentFrame)





-------------------------------------------------------------------
-- Dynamic Auction Row Creation
-------------------------------------------------------------------
local ROW_HEIGHT = 60



local function CreateAuctionRow()
    local row = CreateFrame("Frame", nil, AuctionContentFrame)
    row:SetSize(750, 55)
    row:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    row:Hide()

    -- 1. Item Icon
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(40, 40)
    row.icon:SetPoint("LEFT", 10, 0)

    -- 2. Item Name (as a clickable button for tooltip)
    row.itemButton = CreateFrame("Button", nil, row)
    row.itemButton:SetSize(250, 20)
    row.itemButton:SetPoint("LEFT", row.icon, "RIGHT", 10, 8)
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

    -- 4. Current Bid Text
    row.bidText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.bidText:SetPoint("CENTER", -50, 8)
    row.bidText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

    -- 5. Top Bidder Text
    row.topBidderText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.topBidderText:SetPoint("TOP", row.bidText, "BOTTOM", 0, -5)
    row.topBidderText:SetFont("Fonts\\FRIZQT__.TTF", 12)

    -- 6. Bid EditBox
    row.bidBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.bidBox:SetSize(80, 32)
    row.bidBox:SetPoint("RIGHT", -100, 0)
    row.bidBox:SetNumeric(true)
    row.bidBox:SetAutoFocus(false)
    row.bidBox:SetScript("OnEnterPressed", function(self)
        row.bidButton:Click()
    end)
    
    -- 7. Bid Button
    row.bidButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.bidButton:SetSize(80, 25)
    row.bidButton:SetPoint("LEFT", row.bidBox, "RIGHT", 5, 0)
    row.bidButton:SetText("Bid")
    row.bidButton:SetScript("OnClick", function()
        local bidAmount = tonumber(row.bidBox:GetText())
        if bidAmount and bidAmount > 0 then
            local msg = string.format("BID:%d:%d", row.auctionId, bidAmount)
            SendAddonMessage(addonPrefix, msg, "RAID") -- Send bid to the whole raid, leader will pick it up
            row.bidBox:SetText("") -- Clear box after bidding
        end
    end)
    
    -- OnUpdate for the timer
    row:SetScript("OnUpdate", function(self, elapsed)
        if not self.endTime then return end
        local remaining = self.endTime - GetTime()
        if remaining > 0 then
            local minutes = math.floor(remaining / 60)
            local seconds = math.floor(remaining % 60)
            self.timerText:SetText(string.format("Time Left: |cffffffff%02d:%02d|r", minutes, seconds))
        else
            self.timerText:SetText("Time Left: |cffff000000:00|r")
            self:SetScript("OnUpdate", nil) -- Stop updating
        end
    end)
    
    return row
end





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

-- Functions to handle addon messages
local function HandleAuctionStart(auctionId, itemID, startBid, minIncrement, itemLink)
    local row = table.remove(AuctionFramePool) or CreateAuctionRow()
    AuctionFrames[auctionId] = row
    
    row.auctionId = auctionId
    row.itemLink = itemLink
    row.minIncrement = minIncrement

    -- Populate UI
    local _, _, quality, _, _, _, _, _, _, icon = GetItemInfo(itemLink)
    local r, g, b = GetItemQualityColor(quality)
    row.icon:SetTexture(icon)
    row.itemLinkText:SetText(itemLink)
    row.itemLinkText:SetTextColor(r, g, b)
    
    row.bidText:SetText(string.format("Current Bid: |cffffd700%d|r", startBid))
    row.topBidderText:SetText("No bids yet")
    row.topBidderText:SetTextColor(1, 1, 1)

    row.bidBox:SetText(startBid + minIncrement) -- Set a default next bid
    
    row.endTime = nil -- No timer until first update
    row:SetScript("OnUpdate", nil)
    
    row:Show()
    UpdateAuctionLayout()
end

local function HandleAuctionUpdate(auctionId, newBid, topBidder, endTime)
    local row = AuctionFrames[auctionId]
    if not row then return end

    row.bidText:SetText(string.format("Current Bid: |cffffd700%d|r", newBid))
    row.topBidderText:SetText("Top Bidder: " .. topBidder)
    
    if topBidder == UnitName("player") then
        row.topBidderText:SetTextColor(0, 1, 0) -- Green if you are the top bidder
    else
        row.topBidderText:SetTextColor(1, 0, 0) -- Red if not
    end
    
    -- Update timer
    row.endTime = endTime
    row:SetScript("OnUpdate", row.OnUpdate) -- Re-enable the update script
    
    -- Suggest next bid
    row.bidBox:SetText(newBid + row.minIncrement)
end

local function HandleAuctionEnd(auctionId)
    local row = AuctionFrames[auctionId]
    if not row then return end
    
    row:Hide()
    row.auctionId = nil -- Clear data
    table.insert(AuctionFramePool, row) -- Add back to the pool for reuse
    AuctionFrames[auctionId] = nil
    
    UpdateAuctionLayout()
end


-- Event handler for addon messages
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= addonPrefix then return end
    
    local cmd, data = msg:match("([^:]+):(.*)")
    
    if cmd == "AUCTION_START" then
        local id, itemID, startBid, minInc, itemLink = data:match("([^:]+):([^:]+):([^:]+):([^:]+):(.+)")
        HandleAuctionStart(tonumber(id), tonumber(itemID), tonumber(startBid), tonumber(minInc), itemLink)
    elseif cmd == "AUCTION_UPDATE" then
        local id, newBid, topBidder, endTime = data:match("([^:]+):([^:]+):([^:]+):([^:]+)")
        HandleAuctionUpdate(tonumber(id), tonumber(newBid), topBidder, tonumber(endTime))
    elseif cmd == "AUCTION_END" then
        HandleAuctionEnd(tonumber(data))
    end
end)









---------------------------------------------------------------------------------------------------------------
-------------------------------------------Scroll Frame--------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------






--[[

local function CreateAuctionFrames(name,xpos,ypos,text,number,itemID)

    local AuctionFrame = CreateFrame("Frame", name, AuctionContentFrame)
    AuctionFrame:SetSize(750, 50)
    AuctionFrame:SetPoint("TOPLEFT", xpos, ypos)
    AuctionFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    local AuctionNumberText = AuctionFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    AuctionNumberText:SetPoint("LEFT",10,0)
    AuctionNumberText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    AuctionNumberText:SetText(number)

    local AuctionText = AuctionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    AuctionText:SetPoint("CENTER")
    AuctionText:SetText(text)

    -- Item texture frame
    local ItemTextureFrame = CreateFrame("Frame", name.."_ItemTextureFrame", AuctionFrame)
    ItemTextureFrame:SetSize(35, 35)   
    ItemTextureFrame:SetPoint("LEFT",40,0)  
    ItemTextureFrame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    -- Item texture 
    local itemTexture = ItemTextureFrame:CreateTexture(nil, "BACKGROUND")
    itemTexture:SetAllPoints(ItemTextureFrame)


    -- Hidden button underneath the itemlink text to show item tooltip on mouseover
    local ItemLinkButton = CreateFrame("Button", nil, AuctionFrame)
    ItemLinkButton:SetPoint("LEFT", ItemTextureFrame, "RIGHT", 10, 0)
    ItemLinkButton:SetSize(300, 20) 

    
    local ItemLinkText = ItemLinkButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ItemLinkText:SetPoint("LEFT")
    ItemLinkText:SetText("Loading...")
    ItemLinkButton.text = ItemLinkText


local function UpdateItemInfo()
    local itemName, itemLink, _, _, _, _, _, _, _, tex = GetItemInfo(itemID)
    if itemLink then
        itemTexture:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
        ItemLinkText:SetText(itemLink)

        -- Tooltip on link hover
        ItemLinkButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Show()
        end)
        ItemLinkButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Handle clicks (e.g., shift-click to chat)
    ItemLinkButton:SetScript("OnClick", function(self, button)
        if IsShiftKeyDown() and ChatEdit_InsertLink then
            ChatEdit_InsertLink(itemLink) -- puts the item link into the chat box
        end
    end)


        -- Optional: tooltip on texture hover
        ItemTextureFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Show()
        end)
        ItemTextureFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
        ItemLinkText:SetText("Loading...")
    end
end

    -- Initial try
    UpdateItemInfo()

    -- Retry if item not cached yet
    AuctionFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    AuctionFrame:SetScript("OnEvent", function(self, event, arg1)
        if arg1 == itemID then
            UpdateItemInfo()
            self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
        end
    end)
end








local startX, startY = 10, -10  -- starting point inside AuctionContentFrame
local frameHeight = 55           -- height + spacing between frames

for i = 1, 50 do
    local frameName = "Example"..i
    local ypos = startY - ((i-1) * frameHeight)
    local itemID = 200001
    CreateAuctionFrames(frameName, startX, ypos, "Auction "..i, i, itemID)
end


]]













local function ShowAuctionWindow()
    AuctionWindow:Show()
    UpdateCurrentGoldAmount()
end








---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------




---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------




-- Slash Command /gdkp 
-- Commands:
-- version, v, ver: version check
-- show, s, auction: showing the auction frame
-- hide, h: hides the AuctionWindow
-- gold, g: meme text to steal gold from Tehnix

SLASH_GDKPT1 = "/gdkp"
SlashCmdList["GDKPT"] = function(message)
    local cmd = message:match("^(%S+)") or ""          -- cmd is the command after /gdkp

    if cmd == "" or cmd == "help" then
        print("|cff00ff00[GDKPT]|r Commands:")
        print("show - shows the main auction window")
        print("hide - hides the auction window")
        print("version - shows current version")
    end

    if cmd == "show" or cmd == "s" or cmd == "auction" then
        ShowAuctionWindow()
    end

    if cmd == "hide" or cmd == "h" then
        AuctionWindow:Hide()
    end

    if cmd == "version" or cmd == "v" or cmd == "ver" then
        print("Current GDKPT Addon Version: " .. version)
    end

    if cmd == "gold" or cmd == "g" then
        print("You have stolen " .. stolenGold .. " from Tehnix so far.")
        stolenGold = stolenGold + 1
    end


end




---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------




--[[


----------------------------------------------------------

local AuctionSettings = {}
local AuctionTable = {}

local function DeserializeSettings(msg)
    local t = {}
    for k,v in string.gmatch(msg, "([^=;]+)=([^=;]+);") do
        local num = tonumber(v)
        t[k] = num or v
    end
    return t
end

local function DeserializeAuctions(msg)
    local t = {}
    for entry in string.gmatch(msg, "([^|]+)") do
        local id,itemID,qty = string.match(entry, "(%d+),(%d+),(%d+)")
        if id and itemID and qty then
            table.insert(t, {id = tonumber(id), itemID = tonumber(itemID), quantity = tonumber(qty)})
        end
    end
    return t
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= "GDKP" then return end

    if string.sub(msg,1,9) == "SETTINGS:" then
        AuctionSettings = DeserializeSettings(string.sub(msg,10))
        print("Received AuctionSettings:")
        for k,v in pairs(AuctionSettings) do print("  ", k, v) end

    elseif string.sub(msg,1,9) == "AUCTIONS:" then
        AuctionTable = DeserializeAuctions(string.sub(msg,10))
        print("Received AuctionTable:")
        for _,entry in ipairs(AuctionTable) do
            print("  ID:", entry.id, "ItemID:", entry.itemID, "Qty:", entry.quantity)
        end
    end
end)




]]
