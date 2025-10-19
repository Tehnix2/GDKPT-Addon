GDKPT.Core = {}

GDKPT.Core.addonPrefix = "GDKP" 

GDKPT.Core.version = 0.26



GDKPT.Core.ROW_HEIGHT = 60
GDKPT.Core.PlayerCut = 0
GDKPT.Core.GDKP_Pot = 0


-------------------------------------------------------------------
-- Auction Table to track active auctions
-------------------------------------------------------------------

GDKPT.Core.AuctionFrames = {}    



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
-- Favorites
-------------------------------------------------------------------

GDKPT.Core.isFavoriteFilterActive = false  

GDKPT.Core.PlayerFavorites = nil


-- Initialize the PlayerFavorites table from the SavedVariables, called on ADDON_LOADED or PLAYER_LOGOUT event in loader
function GDKPT.Core.InitPlayerFavorites()
   
    local savedFavorites = GDKPT_Core_PlayerFavorites or {}
    
    if type(savedFavorites) ~= "table" then
        savedFavorites = {}
    end

    -- Link internal table to the saved variable table
    GDKPT_Core_PlayerFavorites = savedFavorites

    -- Ensure the global variable points to the container
    GDKPT.Core.PlayerFavorites = GDKPT_Core_PlayerFavorites
end


-------------------------------------------------------------------
-- Won Items
-------------------------------------------------------------------

GDKPT.Core.PlayerWonItems = {}


-------------------------------------------------------------------
-- History
-------------------------------------------------------------------

GDKPT.Core.History = {}

-- Data saving and loading code
GDKPT.Core.GeneralHistory = nil
GDKPT.Core.PlayerHistory = nil


GDKPT_Core_History = GDKPT_Core_History or {}  -- Saved Variable

-- Initialize the history table from saved variables, called on ADDON_LOADED or PLAYER_LOGOUT event in loader
function GDKPT.Core.InitHistory()
    local savedHistory = GDKPT_Core_History or {}

    -- Ensure the tables exist within the saved data
    if type(savedHistory.GeneralHistory) ~= "table" then
        savedHistory.GeneralHistory = {}
    end
    if type(savedHistory.PlayerHistory) ~= "table" then
        savedHistory.PlayerHistory = {}
    end

    -- Link internal tables to the saved variable table
    GDKPT.Core.GeneralHistory = savedHistory.GeneralHistory
    GDKPT.Core.PlayerHistory = savedHistory.PlayerHistory

    -- Ensure the global variable points to the container
    GDKPT_Core_History = savedHistory
end


-- Runs at logout/addon save time to package the current session data into PlayerHistory
function GDKPT.Core.SaveCurrentRaidSummary()
    -- Only save if the player actually won something or if the pot was non-zero
    if #GDKPT.Core.PlayerWonItems > 0 or GDKPT.Core.GDKP_Pot > 0 then
        local totalPaid = GDKPT.Utils.CalculateTotalPaid()
        local cutReceived = GDKPT.Core.PlayerCut or 0 

        table.insert(
            GDKPT.Core.PlayerHistory,
            {
                timestamp = time(),
                totalPot = GDKPT.Core.GDKP_Pot or 0, 
                totalPaid = totalPaid,
                cutReceived = cutReceived,
                itemsWon = GDKPT.Core.PlayerWonItems 
            }
        )
    end

    GDKPT.Core.PlayerWonItems = {}
    -- GDKPT.Core.PlayerCut = 0 -- You might want to reset other session data here too
end



-------------------------------------------------------------------
-- Player Settings saving and loading
-------------------------------------------------------------------

GDKPT.Core.Settings = {}

-- Data saving and loading code
GDKPT.Core.Settings = nil

function GDKPT.Core.InitPlayerSettings()
   
    local savedSettings = GDKPT_Core_Settings or {}
    
    if type(savedSettings) ~= "table" then
        savedSettings = {}
    end

    -- Link internal table to the saved variable table
    GDKPT_Core_Settings = savedSettings

    -- Ensure the global variable points to the container
    GDKPT.Core.Settings = GDKPT_Core_Settings
end




-------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------

SLASH_GDKPT1 = "/gdkp"
SlashCmdList["GDKPT"] = function(message)
    local cmd, args = message:match("^(%S+)%s*(.*)$")

    if cmd == "help" then
        print("|cff00ff00[GDKPT]|r Commands:")
        print("show - shows the main auction window")
        print("favorite [itemLink] - adds an item to the favorite window")
        print("macro - opens a new frame where you can copy a mouseover favoriting item macro")
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
        GDKPT.UI.ShowMacroFrame()
    end
end
