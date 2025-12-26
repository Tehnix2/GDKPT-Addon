GDKPT.Core = GDKPT.Core or {}

GDKPT.Core.addonPrefix = "GDKP" 

GDKPT.Core.version = 0.38


-------------------------------------------------------------------
-- Auction Table to track active auctions and auctioned items
-------------------------------------------------------------------

GDKPT.Core.AuctionFrames = {}    
GDKPT.Core.AuctionedItems = GDKPT.Core.AuctionedItems or {}

-------------------------------------------------------------------
-- Table to track bid history
-------------------------------------------------------------------

GDKPT.Core.PlayerBidHistory = {}
GDKPT.Core.PlayerActiveBids = {}


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
-- Default Addon Settings
-------------------------------------------------------------------

local defaultAddonSettings = {
    HideToggleButton = 0,                             -- Hide auction toggle button
    HideToggleInCombat = 0,                           -- Hide toggle button in combat
    AutoFillTradeGold = 1,                            -- Auto-fill button enabler
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
    HideCompletedAuctions = 0,                        -- 1 = hide completed auctions automatically
    ShowTooltipHistory = 0,                           -- Auto expand the tooltip of items to see the last price in a GDKPT raid
    Fav_ShowGoldenRows = 1,                           -- Show favorite item auctions in golden rows
    Fav_ChatAlert = 1,                                -- Chat alert for favorite loot
    Fav_PopupAlert = 1,                               -- Popup frame alert for favorite loot
    Fav_AudioAlert = 1,                               -- Audio alert for favorite loot
    Fav_RemoveItemOnWin = 1,                          -- Remove item from favorite list when auction won
    OutbidAudioAlert = 1,                             -- Play sound when outbid on any auction
    AuctionWonAudioAlert = 1,                         -- Play sound when player wins any auction
    SendCooldownMessages = 1,                         -- Enable sending cooldown messages
    AcceptSpellRequests = 1,                          -- Accept Cooldown cast Spell Requests
    PreBid_AudioAlert = 1,                            -- Play sound when auction starts for pre-bid item
    PreBid_AutoSend = 0,                              -- Automatically send pre-bid when auction starts
    AutoRaidReset = 1,                                -- Automatically reset raid lockouts on Wednesday login
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

GDKPT_Loot_Data = GDKPT_Loot_Data or {} 
GDKPT.Core.LootedItems = GDKPT_Loot_Data



function GDKPT.Core.InitData()
    
    local savedSettings = GDKPT_Core_Settings or {}
    local savedFavorites = GDKPT_Core_PlayerFavorites or {}
    local savedHistory = GDKPT_Core_History or {}
    local savedTrading = GDKPT_Core_TradingData or {}
    local savedLoot = GDKPT_Loot_Data or {}


   
    GDKPT.Core.Settings = GDKPT_Core_Settings
    GDKPT.Core.PlayerFavorites = GDKPT_Core_PlayerFavorites 
    GDKPT.Core.History = savedHistory
    GDKPT.Core.TradingData = savedTrading
    GDKPT.Core.LootedItems = savedLoot

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
-- Maximum Bid
-------------------------------------------------------------------

GDKPT.Core.MaxBid = 500000


-------------------------------------------------------------------
-- Standardized [GDKPT] print string
-------------------------------------------------------------------

GDKPT.Core.print = "|cff00ff00[GDKPT]|r "
GDKPT.Core.errorprint = "|cffff0000[GDKPT]|r "



-------------------------------------------------------------------
-- The RaidLeader addon periodically sends out messages to the 
-- raidmember addon which then enables functionalities
-------------------------------------------------------------------

GDKPT.Core.LastLeaderHeartbeat = 0
GDKPT.Core.IsInGDKPRaid = false

function GDKPT.Core.CheckGDKPRaidStatus()
    local currentTime = GetTime()
    -- If we haven't received a heartbeat in 60 seconds, assume not in GDKP raid
    if (currentTime - GDKPT.Core.LastLeaderHeartbeat) > 60 then
        GDKPT.Core.IsInGDKPRaid = false
    else
        GDKPT.Core.IsInGDKPRaid = true
    end
    return GDKPT.Core.IsInGDKPRaid
end



-------------------------------------------------------------------
-- Current gold balance based on leader synced value, adjusted when 
-- player opens trade with leader through a sync
-- starts as nil, so if balance = 0 the player has fully paid up
-------------------------------------------------------------------
GDKPT.Core.MyBalance = nil


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
        print("loot - opens the loot tracker")
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
    elseif cmd == "loot" then
        if GDKPT.Loot and GDKPT.Loot.LootFrame then
            GDKPT.Loot.UpdateLootDisplay()
            GDKPT.Loot.LootFrame:Show()
        end
    elseif cmd == "tutorial" or cmd == "tut" then
        GDKPT.Tutorial.Start()
    elseif cmd == "stuck" then
        local auctionId = tonumber(args)

        local row = GDKPT.Core.AuctionFrames[auctionId]

        -- Simulate stuck state
        if row.bidButton then
            row.bidButton:Disable()
            row.bidButton:SetText("Syncing...")
        end
    elseif cmd == "cd" or cmd == "cooldown" or cmd == "cooldowntracker" or cmd == "cdtracker" then
            GDKPT.CooldownTracker.ToggleMenu()
    end
end





-------------------------------------------------------------------
-- Tooltip History Hook
-------------------------------------------------------------------


GameTooltip:HookScript("OnTooltipSetItem", function(self)
    -- 1. Check setting
    if GDKPT.Core.Settings.ShowTooltipHistory ~= 1 then return end

    -- 2. Get item info
    local _, link = self:GetItem()
    if not link then return end

    local targetID = tonumber(link:match("item:(%d+)"))
    if not targetID then return end

    -- 3. Collect ALL matches from history
    local matches = {}
    if GDKPT.Core.History then
        for _, record in ipairs(GDKPT.Core.History) do
            local recordID = record.link and tonumber(record.link:match("item:(%d+)"))
            if recordID == targetID and record.bid > 0 then
                table.insert(matches, record)
            end
        end
    end

    local count = #matches
    
    if count > 0 then
        self:AddLine(" ")
        self:AddLine("|cff00ff00[GDKP] History:|r")
        
        -- 4. Calculate and Display Average
        local totalBid = 0
        for _, data in ipairs(matches) do
            totalBid = totalBid + (data.bid or 0)
        end
        
        local average = math.floor(totalBid / count)
        
        -- Display Average line (e.g., "Average (3 seen):   500g")
        self:AddDoubleLine("Average (" .. count .. " seen):", GDKPT.Utils.FormatMoney(average * 10000), 1, 0.82, 0, 1, 1, 1)

        -- 5. Sort by timestamp descending (Newest -> Oldest)
        table.sort(matches, function(a, b) 
            return (a.timestamp or 0) > (b.timestamp or 0) 
        end)

        -- 6. Display up to 5 entries
        for i = 1, math.min(count, 5) do
            local data = matches[i]
            local dateStr = data.timestamp and date("%d/%m", data.timestamp) or "??"
            local leftText = string.format("|cffaaaaaa%s|r %s", dateStr, data.winner or "?")
            local rightText = GDKPT.Utils.FormatGoldOnly((data.bid or 0) * 10000)
            
            self:AddDoubleLine(leftText, rightText, 1, 1, 1, 1, 1, 1)
        end
        
        self:Show()
    end
end)