-- Parallelized GDKP Addon for 3.3.5 servers
-- RaidMember Version
-- Version: 0.1
-- Made by @Tehnix

local version = 0.1

local stolenGold = 1  -- meme














---------------------------------------------------------------------------------------------------------------
--------------------------------Main Auction Window------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------


local AuctionWindow = CreateFrame("Frame","GDKP_Auction_Window",UIParent)

    AuctionWindow:SetSize(600,600)
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
    AuctionWindowTitleText:SetText("|cffFFC125GDKP Auctions|r")
    AuctionWindowTitleText:SetPoint("CENTER", 0, 0)





-- Scroll Frame
local AuctionScrollFrame = CreateFrame("ScrollFrame", "GDKP_Auction_ScrollFrame", AuctionWindow, "UIPanelScrollFrameTemplate")
AuctionScrollFrame:SetPoint("TOPLEFT", 10, -40)     -- leave space for title bar
AuctionScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10) -- leave space for scrollbar
AuctionScrollFrame:SetFrameLevel(AuctionWindow:GetFrameLevel() + 1)

-- Content Frame (holds all your future small frames)
local AuctionContentFrame = CreateFrame("Frame", "GDKP_Auction_ContentFrame", AuctionScrollFrame)
AuctionContentFrame:SetSize(560, 1000)  -- width = scroll area, height large enough for all items
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
        print("gold - steals 1 gold from Tehnix")
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