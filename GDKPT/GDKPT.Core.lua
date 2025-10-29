GDKPT.Core = GDKPT.Core or {}

GDKPT.Core.addonPrefix = "GDKP" 

GDKPT.Core.version = 0.29


GDKPT.Core.PlayerCut = 0
GDKPT.Core.GDKP_Pot = 0
GDKPT.Core.PotSplitStarted = 0

-------------------------------------------------------------------
-- Auction Table to track active auctions
-------------------------------------------------------------------

GDKPT.Core.AuctionFrames = {}    

-------------------------------------------------------------------
-- Table to track bid history
-------------------------------------------------------------------

GDKPT.Core.PlayerBidHistory = {}


-------------------------------------------------------------------
-- Filter states
-------------------------------------------------------------------


GDKPT.Core.FilterMyBidsActive = false
GDKPT.Core.FilterOutbidActive = false


-------------------------------------------------------------------
-- Default Auction Settings
-------------------------------------------------------------------


GDKPT.Core.leaderSettings = {
    duration = 30,
    extraTime = 5,
    startBid = 50,
    minIncrement = 10,
    splitCount = 25,
    isSet = false
}


-------------------------------------------------------------------
-- Default general addon settings
-------------------------------------------------------------------

local defaultAddonSettings = {
    HideToggleButton = 0,                             -- Hide auction toggle button
    AutoFillTradeGold = 0,                            -- Auto-fill button enabler
    LimitBidsToGold = 1,                              -- Limit bids to total gold
    ConfirmBid = 1,                                   -- Confirm popup for bid button
    ConfirmBidBox = 1,                                -- Confirm popup for bid box
    ConfirmAutoBid = 1,                               -- Confirm popup for setting autobid
    PreventSelfOutbid = 1,                            -- Prevents yourself from bidding on auctions if you are the highest bidder
    NewAuctionsOnTop = 0,                             -- 0 = bottom (default), 1 = top
    OutbidAudioAlert = 0,
    Fav_ShowGoldenRows = 1,                           -- Show favorite item auctions in golden rows
    Fav_ChatAlert = 0,                                -- Chat alert for favorite loot
    Fav_PopupAlert = 0,                               -- Popup frame alert for favorite loot
    Fav_AudioAlert = 0,                               -- Audio alert for favorite loot
}




-------------------------------------------------------------------
-- Initialize all saved variables
-- SavedVariables Data Tables: 
-- GDKPT_Core_PlayerFavorites
-- GDKPT_Core_PlayerWonItems
-- GDKPT_Core_History
-------------------------------------------------------------------

GDKPT.Core.isFavoriteFilterActive = false  


GDKPT_Core_PlayerFavorites = GDKPT_Core_PlayerFavorites or {}
GDKPT.Core.PlayerFavorites = GDKPT_Core_PlayerFavorites

GDKPT_Core_PlayerWonItems = GDKPT_Core_PlayerWonItems or {}
GDKPT.Core.PlayerWonItems = GDKPT_Core_PlayerWonItems

GDKPT_Core_History = GDKPT_Core_History or {}
GDKPT.Core.History = GDKPT_Core_History

GDKPT_Core_Settings = GDKPT_Core_Settings or {}
GDKPT.Core.Settings = GDKPT_Core_Settings



function GDKPT.Core.InitData()
    
    local savedSettings = GDKPT_Core_Settings or {}
    local savedFavorites = GDKPT_Core_PlayerFavorites or {}
    local savedHistory = GDKPT_Core_History or {}

   
    GDKPT.Core.Settings = GDKPT_Core_Settings


    GDKPT.Core.PlayerFavorites = GDKPT_Core_PlayerFavorites 
    
    GDKPT.Core.History = savedHistory

    for settingName, defaultValue in pairs(defaultAddonSettings) do
        if GDKPT.Core.Settings[settingName] == nil then
            GDKPT.Core.Settings[settingName] = defaultValue
        end
    end
end





-------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------

SLASH_GDKPT1 = "/gdkp"
SlashCmdList["GDKPT"] = function(message)
    local cmd, args = message:match("^(%S+)%s*(.*)$")

    if cmd == "help" then
        print("|cff00ff00[GDKPT]|r Commands:")
        print("favorite [itemLink] - adds an item to the favorite window")
        print("macro - opens a new frame where you can copy GDKP related macros")
        print("settings - opens the settings menu")
        print("show - shows the main auction window")
    elseif cmd == "show" or cmd == "s" or cmd == "auction" then
        GDKPT.UI.ShowAuctionWindow()
    elseif cmd == "favorite" or cmd == "fav" or cmd == "f" then 
        local itemLink = args:match("^%s*(|cff[0-9a-fA-F]+.*|r)")
        
        if not itemLink then
            print("|cffff8800[GDKPT]|r Usage: /gdkp favorite [shift-click an item].")
            return
        end
        GDKPT.AuctionFavorites.ToggleFavorite(itemLink)
    elseif cmd == "macro" then
        GDKPT.UI.MacroSelectWindow:Show()
    elseif cmd == "settings" then
        GDKPT.UI.SettingsFrameButton:Click()
    end
end



-- TODO



-- 11. mark bulk auction as bulk in the very end






