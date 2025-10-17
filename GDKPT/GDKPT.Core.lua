GDKPT = GDKPT or {}

GDKPT.Core = {}

GDKPT.Core.version = 0.25

GDKPT.Core.addonPrefix = "GDKP" 

-- Default values
GDKPT.Core.leaderSettings = {
    duration = 30,
    extraTime = 5,
    startBid = 50,
    minIncrement = 10,
    splitCount = 25,
    isSet = false
}


GDKPT.Core.AuctionFrames = {}    -- Table to keep track of the UI frames for each active auction

GDKPT.Core.AuctionFramePool = {} -- To reuse frames instead of creating/destroying them


GDKPT.Core.PendingAuctions = {}  -- Table that stores auctions that are waiting for item data to load


GDKPT.Core.PlayerWonItems = {}
GDKPT.Core.PlayerCut = 0
GDKPT.Core.GDKP_Pot = 0

GDKPT.Core.isFavoriteFilterActive = false  

GDKPT.Core.ROW_HEIGHT = 60







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
        GDKPT.UI.ShowAuctionWindow()
    elseif cmd == "hide" or cmd == "h" then
        AuctionWindow:Hide()
    elseif cmd == "version" or cmd == "v" or cmd == "ver" then
        print("Current GDKPT Addon Version: " .. version)
    elseif cmd == "gold" or cmd == "g" then
        print("You have stolen " .. stolenGold .. " from Tehnix so far.")
        stolenGold = stolenGold + 1
    end
end
