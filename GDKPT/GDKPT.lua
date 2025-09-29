-- Parallelized GDKP Addon for 3.3.5 servers
-- RaidMember Version
-- Version: 0.1
-- Made by @Tehnix

local version = 0.1

local totalPot = 1343423420      -- Variables for the bottom info panel
local currentCut = 2000001200


local stolenGold = 1  -- meme
















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





-- Function to update bottom info panel
local function UpdateBottomInfoPanel()
    TotalPotAmountText:SetText(string.format("%s", FormatMoney(totalPot)))
    CurrentCutAmountText:SetText(string.format("%s", FormatMoney(currentCut)))

    local playerMoney = GetMoney()
    CurrentGoldAmountText:SetText(FormatMoney(playerMoney))
end



---------------------------------------------------------------------------------------------------------------
-------------------------------------------Scroll Frame--------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------


local AuctionScrollFrame = CreateFrame("ScrollFrame", "GDKP_Auction_ScrollFrame", AuctionWindow, "UIPanelScrollFrameTemplate")
AuctionScrollFrame:SetPoint("TOPLEFT", 10, -40)     
AuctionScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10) 
AuctionScrollFrame:SetFrameLevel(AuctionWindow:GetFrameLevel() + 1)





-- Content Frame (holds all your future small frames)
local AuctionContentFrame = CreateFrame("Frame", "GDKP_Auction_ContentFrame", AuctionScrollFrame)
AuctionContentFrame:SetSize(560, 3000)  -- width = scroll area, height large enough for all items
AuctionScrollFrame:SetScrollChild(AuctionContentFrame)

-- Example small frame inside the scrollable area
local ExampleFrame = CreateFrame("Frame", "ExampleItemFrame", AuctionContentFrame)
ExampleFrame:SetSize(540, 50)
ExampleFrame:SetPoint("TOPLEFT", 10, -10)
ExampleFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})


local ExampleText = ExampleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ExampleText:SetPoint("CENTER")
ExampleText:SetText("This is a test item frame")












local function ShowAuctionWindow()
    AuctionWindow:Show()
    UpdateBottomInfoPanel()
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
-- gold, g: meme text to steal gold from Tehnix

SLASH_GDKPT1 = "/gdkp"
SlashCmdList["GDKPT"] = function(message)
    local cmd = message:match("^(%S+)") or ""          -- cmd is the command after /gdkp

    if cmd == "" or cmd == "help" then
        print("GDKPT Commands:")
        print("show - shows the main auction frame")
        print("version - shows current version")
    end

    if cmd == "show" or cmd == "s" or cmd == "auction" then
        ShowAuctionWindow()
    end


    if cmd == "version" or cmd == "v" or cmd == "ver" then
        print("Current GDKPT Version: " .. version)
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










-- Feature Timeline
-- 1. Add slash commands
-- 2. Add main AuctionWindow with closebutton and titlebar
-- 3. Add ScrollFrame