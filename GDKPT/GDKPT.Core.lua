GDKPT.Core = GDKPT.Core or {}

GDKPT.Core.addonPrefix = "GDKP" 

GDKPT.Core.version = 0.30


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
-- Default addon settings
-------------------------------------------------------------------

local defaultAddonSettings = {
    HideToggleButton = 0,                             -- Hide auction toggle button
    AutoFillTradeGold = 0,                            -- Auto-fill button enabler
    AutoFillTradeAccept = 0,                          -- Shall the auto fill button also accept trades?
    LimitBidsToGold = 1,                              -- Limit bids to total gold
    ConfirmBid = 1,                                   -- Confirm popup for bid button
    ConfirmBidBox = 1,                                -- Confirm popup for bid box
    ConfirmAutoBid = 1,                               -- Confirm popup for setting autobid
    PreventSelfOutbid = 1,                            -- Prevents yourself from bidding on auctions if you are the highest bidder
    NewAuctionsOnTop = 1,                             -- 0 = bottom (default), 1 = top
    SortBidsToTop = 0,                                -- 0 = no sorting, 1 = outbid > bids > regular sorting based on NewAuctionsOnTop
    GreenBidRows = 1,                                 -- show rows in green on bid
    RedOutbidRows = 1,                                -- show rows in red on outbid
    Fav_ShowGoldenRows = 1,                           -- Show favorite item auctions in golden rows
    Fav_ChatAlert = 1,                                -- Chat alert for favorite loot
    Fav_PopupAlert = 1,                               -- Popup frame alert for favorite loot
    Fav_AudioAlert = 1,                               -- Audio alert for favorite loot
    Fav_RemoveItemOnWin = 1,                           -- Remove item from favorite list when auction won
    OutbidAudioAlert = 1,                             -- Play sound when outbid on any auction
}




-------------------------------------------------------------------
-- Initialize all saved variables
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

GDKPT_Core_TradingData = GDKPT_Core_TradingData or {}
GDKPT.Core.TradingData = GDKPT_Core_TradingData



function GDKPT.Core.InitData()
    
    local savedSettings = GDKPT_Core_Settings or {}
    local savedFavorites = GDKPT_Core_PlayerFavorites or {}
    local savedHistory = GDKPT_Core_History or {}
    local savedTrading = GDKPT_Core_TradingData or {}

   
    GDKPT.Core.Settings = GDKPT_Core_Settings
    GDKPT.Core.PlayerFavorites = GDKPT_Core_PlayerFavorites 
    GDKPT.Core.History = savedHistory
    GDKPT.Core.TradingData = savedTrading

    for settingName, defaultValue in pairs(defaultAddonSettings) do
        if GDKPT.Core.Settings[settingName] == nil then
            GDKPT.Core.Settings[settingName] = defaultValue
        end
    end

    if GDKPT.Core.TradingData.totalPaid == nil then
        GDKPT.Core.TradingData.totalPaid = 0
    end
    if GDKPT.Core.TradingData.totalOwed == nil then
        GDKPT.Core.TradingData.totalOwed = 0
    end
end

-------------------------------------------------------------------
-- Total gold pot
-------------------------------------------------------------------

GDKPT.Core.GDKP_Pot = 0
GDKPT.Core.PlayerCut = 0


GDKPT.Core.PotSplitStarted = 0




-------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------

SLASH_GDKPT1 = "/gdkp"
SlashCmdList["GDKPT"] = function(message)
    local cmd, args = message:match("^(%S+)%s*(.*)$")

    if cmd == "help" then
        print("|cff00ff00[GDKPT]|r Commands:")
        print("check - shows how much gold you still need to pay for your won auctions")
        print("favorite [itemLink] - adds/removes an item to/from the favorite list")
        print("favoritelist - show the favorite list")
        print("history - show the general auction history")
        print("macro - opens a new frame where you can generate and copy GDKPT related macros")
        print("personalhistory - show your personal auction history")
        print("resync - resynchronize current auctions with the raidleader (10 sec cooldown)")
        print("settings - opens the settings menu")
        print("show - shows the main auction window")
        print("syncsettings - resync auction settings (10 sec cooldown)")
        print("wins - show your won auctions")
    elseif cmd == "check" or cmd == "c" then
        GDKPT.Trading.CheckRemainingOwed()
    elseif cmd == "favorite" or cmd == "fav" or cmd == "f" or cmd == "favorites" then 
        local itemLink = args:match("^%s*(|cff[0-9a-fA-F]+.*|r)")
        if not itemLink then
            print("|cffff8800[GDKPT]|r Usage: /gdkp favorite [shift-click an item].")
            return
        end
        GDKPT.Favorites.ToggleFavorite(itemLink)
    elseif cmd == "favoritelist" or cmd == "favlist" then
        GDKPT.Favorites.FavoriteFrameButton:Click()
    elseif cmd == "history" or cmd == "h" then
        GDKPT.UI.GeneralHistoryButton:Click()
    elseif cmd == "macro" or cmd == "macros" or cmd == "m" then
        GDKPT.Macros.Show()
    elseif cmd == "personalhistory" or cmd == "phistory" then
        GDKPT.UI.PlayerHistoryButton:Click()
    elseif cmd == "resync" or cmd == "sync" or cmd == "r" or cmd == "syncauctions" then
        GDKPT.UI.HandleInfoButtonClick("RightButton")
    elseif cmd == "settings" then
        GDKPT.UI.SettingsFrameButton:Click()
    elseif cmd == "show" or cmd == "s" or cmd == "auction" or cmd == "auctions" then
        GDKPT.UI.ShowAuctionWindow()
    elseif cmd == "syncsettings" or cmd == "leftsync" then
        GDKPT.UI.HandleInfoButtonClick("LeftButton")
    elseif cmd == "wins" or cmd == "win" or cmd == "w" then
        GDKPT.UI.WonAuctionsButton:Click()
    end
end
