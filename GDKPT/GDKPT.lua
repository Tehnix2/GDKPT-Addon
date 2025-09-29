-- Parallelized GDKP Addon for 3.3.5 servers
-- RaidMember Version
-- Version: 0.1
-- Made by @Tehnix

local version = 0.1


--local AceGUI = LibStub and LibStub("AceGUI-3.0", true)











---------------------------------------------------------------------------------------------------------------
----------------------------------Auction Window---------------------------------------------------------------
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

local function ShowAuctionWindow()
    AuctionWindow:Show()
end


--[[


local SkillGemFrame = CreateFrame("Frame", "SkillGemFrame",UIParent)
    
    SkillGemFrame:SetSize(1400, 800)
    SkillGemFrame:SetMovable(true)
    SkillGemFrame:EnableMouse(true)
    SkillGemFrame:RegisterForDrag("LeftButton")
    SkillGemFrame:SetPoint("CENTER")
    SkillGemFrame:SetBackdrop({                           --locale-enUS.MPQ
        bgFile = "Interface/DialogFrame/SkillGems2",    --image file needs to have dimensions with a power of 2, so 512x512 works, maybe 1024x1024 aswell
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 20,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    SkillGemFrame:Hide() 
    SkillGemFrame:SetFrameLevel(8)

    SkillGemFrame:SetScript("OnDragStart", SkillGemFrame.StartMoving)
    SkillGemFrame:SetScript("OnDragStop", SkillGemFrame.StopMovingOrSizing)

    _G["SkillGemFrame"] = SkillGemFrame -- adds the frame via the name to the global variables
    tinsert(UISpecialFrames, "SkillGemFrame") 









local function ShowAuctionWindow()
    print("function called")
    if AceGUI == nil then 
        print("AceGUI-3.0 not found. Check the Libs folder in your GDKPT addon folder for AceGUI-3.0. If its not there then download the GDKPT addon again!") 
        return 
    end

    if not auctionWindow then
        print("auction window doesnt exist yet")

        auctionWindow = AceGUI:Create("Frame")

    end
    
    

end


]]


--[[
local function ShowAuctionWindow()
    if AceGUI == nil then dbg("AceGUI not found. Use /gdkpmember list to see auctions in chat."); return end
    if not guiWindow then
        guiWindow = AceGUI:Create("Frame")
        guiWindow:SetTitle("GDKP Member")
        guiWindow:SetLayout("Fill")
        guiWindow:SetStatusText("Parallel auctions")
        guiWindow:SetCallback("OnClose", function() guiWindow:Hide() end)
    end
    guiWindow:Show()
    RebuildUI()
end

]]

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

SLASH_GDKPT1 = "/gdkp"
SlashCmdList["GDKPT"] = function(message)
    local cmd = message:match("^(%S+)") or ""          -- cmd is the command after /gdkp

    if cmd == "version" or cmd == "v" or cmd == "ver" then
        print("Current GDKPT Version: " .. version)
    end

    if cmd == "show" or cmd == "s" or cmd == "auction" then
        ShowAuctionWindow()
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
-- 1. Add slash command /gdkp 
-- 2. Add Current version output