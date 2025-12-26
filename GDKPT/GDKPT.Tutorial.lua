GDKPT.Tutorial = {}

-- Tutorial State
GDKPT.Tutorial.IsActive = false
GDKPT.Tutorial.CurrentStep = 0
GDKPT.Tutorial.DummyRow = nil

-- Saved progress
GDKPT_Tutorial_Completed = GDKPT_Tutorial_Completed or false

-------------------------------------------------------------------
-- Tutorial Steps Definition
-------------------------------------------------------------------

GDKPT.Tutorial.Steps = {
    {
        name = "welcome",
        title = "Welcome to GDKPT!",
        text = "GDKPT is an addon that fully automates the whole GDKP process and has a ton of additional features.\nThis tutorial will guide you through all of them. You can skip steps or exit anytime.\n\nClick 'Next' to begin!",
        target = nil,
        highlight = "none",
        arrow = "NONE",
        requireWindow = false
    },
    
    {
        name = "toggle_button",
        title = "GDKPT Toggle Button",
        text = "This is your main GDKPT button. It has different functionalities depending on how you click it.\n\nLeft-click: Open Auction Window in Full Mode\nRight-click: Open Auction Window in Compact Mode\nMouse Button 4: Open Cooldown Tracker\nMouse Button 5: Set all tracked cooldowns to Ready\nHold Left click to move the button",
        target = function() return GDKPToggleButton end,
        highlight = "button",
        arrow = "DOWN",
        requireWindow = false
    },
    
    {
        name = "open_window",
        title = "Opening the Auction Window",
        text = "Let's open the main auction window now. The tutorial will open it for you.\n\nClick 'Next' to continue.",
        target = nil,
        highlight = "none",
        arrow = "NONE",
        requireWindow = false,
        onComplete = function()
            if not GDKPT.UI.AuctionWindow:IsShown() then
                GDKPT.ToggleLayout.SetLayout("full")
                GDKPT.UI.ShowAuctionWindow()
            end
        end
    },
    
    {
        name = "info_button",
        title = "Settings Sync Button",
        text = "This button syncs auction settings from the raid leader.\n\n|cffFFD700Left-click:|r Sync settings only\n|cffFFD700Right-click:|r Full resync (settings + all auctions)\n\nGreen checkmark = synced, Red X = not synced",
        target = function() return InfoButton end,
        highlight = "button",
        arrow = "DOWN",
        requireWindow = true
    },
    
    {
        name = "filters",
        title = "Auction Filters",
        text = "Filter auctions by:\n\n|cffFFD700Status:|r My Bids, Outbid, Favorites\n|cffFFD700Type:|r Armor, Weapons, Jewelry\n|cffFFD700Binding:|r BoP or BoE\n\nFilters combine with AND logic!",
        target = function() return GDKPT.AuctionFilters.FilterDropdown end,
        highlight = "frame",
        arrow = "DOWN",
        requireWindow = true
    },
    
    {
        name = "favorites_button",
        title = "Favorites List",
        text = "Click here to open your Favorites list.\n\nYou can:\n- Add items you want\n- Set auto-bid amounts\n- Get alerts when favorite items drop",
        target = function() return GDKPT.Favorites.FavoriteFrameButton end,
        highlight = "button",
        arrow = "DOWN",
        requireWindow = true
    },
    
    {
        name = "settings_button",
        title = "Addon Settings",
        text = "Configure GDKPT here:\n\n- Bid confirmations\n- Audio alerts\n- UI preferences\n- Auto-fill trades\n- Favorite notifications\n- And more!",
        target = function() return GDKPT.Settings.SettingsFrameButton end,
        highlight = "button",
        arrow = "DOWN",
        requireWindow = true
    },
    
    {
        name = "loot_tracker_button",
        title = "Loot Tracker",
        text = "Track all master-looted items:\n\n- See 2-hour trade timers\n- Set pre-bids (auto-fill when auction starts)\n- Filter by tradeable/auctioned/bulk\n- Mark items as favorites",
        target = function() return GDKPT.Loot.LootFrameToggleButton end,
        highlight = "button",
        arrow = "DOWN",
        requireWindow = true
    },
    
    {
        name = "won_auctions_button",
        title = "Won Auctions Tracker",
        text = "View all items you've won:\n\n- Track total spending\n- See what you still owe\n- View payment history\n- Check average cost per item",
        target = function() return GDKPT.MyWonAuctions.WonAuctionsButton end,
        highlight = "button",
        arrow = "DOWN",
        requireWindow = true
    },
    
    {
        name = "history_button",
        title = "Auction History",
        text = "View complete raid auction history:\n\n- See all winners and bids\n- Filter by player or item name\n- Track manual adjustments\n- Review past auctions",
        target = function() return GDKPT.UI.GeneralHistoryButton end,
        highlight = "button",
        arrow = "DOWN",
        requireWindow = true
    },
    
    {
        name = "create_dummy",
        title = "Auction Rows (Demo)",
        text = "Now let's look at how auction rows work.\n\nWe'll create a dummy auction so you can see all the features.\n\nClick 'Next' to spawn a demo auction.",
        target = nil,
        highlight = "none",
        arrow = "NONE",
        requireWindow = true,
        onComplete = function()
            GDKPT.Tutorial.CreateDummyAuction()
        end
    },
    
    {
        name = "auction_number",
        title = "Auction Number",
        text = "This shows the auction ID number.\n\nUseful for referring to specific auctions in raid chat.",
        target = function() return GDKPT.Tutorial.DummyRow and GDKPT.Tutorial.DummyRow.auctionNumber end,
        highlight = "text",
        arrow = "LEFT",
        requireWindow = true,
        requireDummy = true
    },
    
    {
        name = "favorite_star",
        title = "Favorite Star",
        text = "Click the star to add/remove items from favorites.\n\n|cffFFD700Golden star:|r Item is favorited\n|cff808080Gray star:|r Not favorited\n\nYou can also use: /gdkp favorite [item link]",
        target = function() return GDKPT.Tutorial.DummyRow and GDKPT.Tutorial.DummyRow.favoriteButton end,
        highlight = "button",
        arrow = "LEFT",
        requireWindow = true,
        requireDummy = true
    },
    
    {
        name = "item_icon",
        title = "Item Icon & Name",
        text = "Hover over the icon or name to see the full item tooltip.\n\nItem quality is shown by the colored text.",
        target = function() return GDKPT.Tutorial.DummyRow and GDKPT.Tutorial.DummyRow.icon end,
        highlight = "texture",
        arrow = "LEFT",
        requireWindow = true,
        requireDummy = true
    },
    
    {
        name = "timer",
        title = "Auction Timer",
        text = "Shows remaining time for the auction.\n\n|cffFFFFFFWhite:|r More than 30s left\n|cffFFAA22Orange:|r 10-30s left\n|cffFF2222Red:|r Less than 10s left",
        target = function() return GDKPT.Tutorial.DummyRow and GDKPT.Tutorial.DummyRow.timerText end,
        highlight = "text",
        arrow = "LEFT",
        requireWindow = true,
        requireDummy = true
    },
    
    {
        name = "current_bid",
        title = "Current Bid Display",
        text = "Shows the current highest bid.\n\nIf no one has bid yet, it shows the starting bid amount.",
        target = function() return GDKPT.Tutorial.DummyRow and GDKPT.Tutorial.DummyRow.bidText end,
        highlight = "text",
        arrow = "RIGHT",
        requireWindow = true,
        requireDummy = true
    },
    
    {
        name = "top_bidder",
        title = "Top Bidder",
        text = "Shows who currently has the highest bid.\n\n|cff00FF00Green:|r You are winning!\n|cffFFFFFFWhite:|r Someone else is winning",
        target = function() return GDKPT.Tutorial.DummyRow and GDKPT.Tutorial.DummyRow.topBidderText end,
        highlight = "text",
        arrow = "RIGHT",
        requireWindow = true,
        requireDummy = true
    },
    
    {
        name = "bid_box",
        title = "Manual Bid Box",
        text = "Type a custom bid amount here and press Enter.\n\nYou can bid any amount above the minimum required bid.",
        target = function() return GDKPT.Tutorial.DummyRow and GDKPT.Tutorial.DummyRow.bidBox end,
        highlight = "frame",
        arrow = "RIGHT",
        requireWindow = true,
        requireDummy = true
    },
    
    {
        name = "bid_button",
        title = "Minimum Bid Button",
        text = "Click to place the minimum valid bid.\n\nThe button shows how much gold you'll bid.\n\nSettings can add a confirmation popup before bidding.",
        target = function() return GDKPT.Tutorial.DummyRow and GDKPT.Tutorial.DummyRow.bidButton end,
        highlight = "button",
        arrow = "RIGHT",
        requireWindow = true,
        requireDummy = true
    },
    
    {
        name = "row_colors",
        title = "Row Color Coding",
        text = "Auction rows change color based on your bid status:\n\n|cff00FF00Green:|r You are winning\n|cffFF0000Red:|r You were outbid\n|cffCCAA00Golden:|r Favorite item (if enabled in settings)\n|cff444444Default:|r No bid placed",
        target = function() return GDKPT.Tutorial.DummyRow end,
        highlight = "frame",
        arrow = "LEFT",
        requireWindow = true,
        requireDummy = true
    },
    
    {
        name = "bottom_panel",
        title = "Bottom Info Panel",
        text = "|cffFFD700Total Pot:|r Raid's total gold pool\n|cffFFD700Current Cut:|r Your share (pot / raid size)\n|cffFFD700Current Gold:|r Gold on your character\n|cffFFD700Bid Cap:|r Optional spending limit\n|cffFFD700My Bids:|r Total gold currently committed",
        target = function() return GDKPT.UI.BottomInfoPanel end,
        highlight = "frame",
        arrow = "UP",
        requireWindow = true
    },
    
    {
        name = "compact_mode",
        title = "Compact Mode",
        text = "GDKPT has two display modes:\n\n|cffFFD700Full Mode:|r All details visible (current)\n|cffFFD700Compact Mode:|r Minimal space, essential info only\n\nToggle with the GDKPT button or /gdkp show",
        target = nil,
        highlight = "none",
        arrow = "NONE",
        requireWindow = true
    },
    
    {
        name = "slash_commands",
        title = "Useful Slash Commands",
        text = "|cffFFD700/gdkp show|r - Open auction window\n|cffFFD700/gdkp wins|r - View won auctions\n|cffFFD700/gdkp history|r - View auction history\n|cffFFD700/gdkp favorite|r [link] - Add to favorites\n|cffFFD700/gdkp settings|r - Open settings\n|cffFFD700/gdkp loot|r - Open loot tracker\n|cffFFD700/gdkp cd|r - Cooldown tracker menu\n|cffFFD700/gdkp help|r - See all commands",
        target = nil,
        highlight = "none",
        arrow = "NONE",
        requireWindow = true
    },
    
    {
        name = "cooldown_tracker",
        title = "Cooldown Tracker (Advanced)",
        text = "Track raid cooldowns and request spells:\n\n- Tracks combat log or addon messages\n- Click bars to request spells\n- Configurable categories and spells\n- Movable frames per category\n\nType |cffFFD700/gdkp cd|r to configure",
        target = nil,
        highlight = "none",
        arrow = "NONE",
        requireWindow = true
    },
    
    {
        name = "trading",
        title = "AutoFill Trade Button",
        text = "When trading with the raid leader:\n\n1. The addon syncs your balance\n2. AutoFill button appears on trade window\n3. Click to auto-fill owed gold\n4. If enabled, auto-accepts trade\n\nConfigure in Settings!",
        target = nil,
        highlight = "none",
        arrow = "NONE",
        requireWindow = true
    },
    
    {
        name = "complete",
        title = "Tutorial Complete!",
        text = "You now know all the features of GDKPT!\n\n|cffFFD700Tips:|r\n- Hover over items for tooltips\n- Right-click rows to hide them\n- Use filters to find your bids quickly\n- Set bid caps to control spending\n\nGood luck in your GDKP runs!",
        target = nil,
        highlight = "none",
        arrow = "NONE",
        requireWindow = true,
        isFinal = true,
        onComplete = function()
            GDKPT.Tutorial.CleanupDummyAuction()
        end
    }
}

-------------------------------------------------------------------
-- Create Tutorial UI Elements
-------------------------------------------------------------------

function GDKPT.Tutorial.CreateUI()
    local frame = CreateFrame("Frame", "GDKPT_TutorialFrame", UIParent)
    frame:SetSize(400, 250)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 50)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(100)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 32,
        insets = {left = 8, right = 8, top = 8, bottom = 8}
    })
    frame:SetBackdropColor(0, 0, 0, 0.95)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Title
    frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.Title:SetPoint("TOP", 0, -15)
    frame.Title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    frame.Title:SetTextColor(1, 0.84, 0)
    
    -- Step Counter
    frame.StepCounter = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.StepCounter:SetPoint("TOPRIGHT", -15, -15)
    frame.StepCounter:SetTextColor(0.7, 0.7, 0.7)
    
    -- Description Text
    frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.Text:SetPoint("TOPLEFT", 20, -45)
    frame.Text:SetPoint("BOTTOMRIGHT", -20, 50)
    frame.Text:SetJustifyH("LEFT")
    frame.Text:SetJustifyV("TOP")
    frame.Text:SetFont("Fonts\\FRIZQT__.TTF", 13)
    frame.Text:SetSpacing(3)
    
    -- Next Button
    frame.NextButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.NextButton:SetSize(100, 25)
    frame.NextButton:SetPoint("BOTTOMRIGHT", -15, 15)
    frame.NextButton:SetText("Next")
    frame.NextButton:SetScript("OnClick", function()
        GDKPT.Tutorial.NextStep()
    end)
    
    -- Previous Button
    frame.PrevButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.PrevButton:SetSize(100, 25)
    frame.PrevButton:SetPoint("RIGHT", frame.NextButton, "LEFT", -10, 0)
    frame.PrevButton:SetText("Previous")
    frame.PrevButton:SetScript("OnClick", function()
        GDKPT.Tutorial.PreviousStep()
    end)
    
    -- Exit Button
    frame.ExitButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.ExitButton:SetSize(100, 25)
    frame.ExitButton:SetPoint("BOTTOMLEFT", 15, 15)
    frame.ExitButton:SetText("Exit Tutorial")
    frame.ExitButton:SetScript("OnClick", function()
        StaticPopupDialogs["GDKPT_EXIT_TUTORIAL"] = {
            text = "Exit the tutorial?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                GDKPT.Tutorial.Stop()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("GDKPT_EXIT_TUTORIAL")
    end)
    
    GDKPT.Tutorial.Frame = frame
    
    -- Highlight Overlay
    local highlight = CreateFrame("Frame", "GDKPT_TutorialHighlight", UIParent)
    highlight:SetFrameStrata("TOOLTIP")
    highlight:SetFrameLevel(99)
    highlight:Hide()
    
    -- Glowing border effect
    highlight.tex = highlight:CreateTexture(nil, "OVERLAY")
    highlight.tex:SetAllPoints()
    highlight.tex:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    highlight.tex:SetBlendMode("ADD")
    highlight.tex:SetVertexColor(1, 0.84, 0, 0.8)
    
    -- Pulsing animation (WotLK compatible)
    local ag = highlight:CreateAnimationGroup()
    local fade1 = ag:CreateAnimation("Alpha")
    fade1:SetChange(-0.7)  -- Fade from 1.0 to 0.3
    fade1:SetDuration(0.8)
    fade1:SetOrder(1)

    local fade2 = ag:CreateAnimation("Alpha")
    fade2:SetChange(0.7)   -- Fade from 0.3 to 1.0
    fade2:SetDuration(0.8)
    fade2:SetOrder(2)

    ag:SetLooping("REPEAT")
    highlight.animGroup = ag
    
    GDKPT.Tutorial.Highlight = highlight

    -- Arrow Pointer
    local arrow = CreateFrame("Frame", "GDKPT_TutorialArrow", UIParent)
    arrow:SetSize(64, 64)
    arrow:SetFrameStrata("TOOLTIP")
    arrow:SetFrameLevel(99)
    arrow:Hide()
    
    arrow.tex = arrow:CreateTexture(nil, "OVERLAY")
    arrow.tex:SetAllPoints()
    arrow.tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    arrow.tex:SetTexCoord(0.3, 0.7, 0.3, 0.8)
    arrow.tex:SetVertexColor(1, 1, 1) 
    arrow.tex:SetSize(64, 64)
    arrow.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Bobbing animation
    local arrowAg = arrow:CreateAnimationGroup()
    local move1 = arrowAg:CreateAnimation("Translation")
    move1:SetOffset(0, 10)
    move1:SetDuration(0.6)
    move1:SetOrder(1)
    
    local move2 = arrowAg:CreateAnimation("Translation")
    move2:SetOffset(0, -10)
    move2:SetDuration(0.6)
    move2:SetOrder(2)
    
    arrowAg:SetLooping("REPEAT")
    arrow.animGroup = arrowAg
    
    GDKPT.Tutorial.Arrow = arrow





    --[[

    -- Arrow Pointer (custom drawn)
    local arrow = CreateFrame("Frame", "GDKPT_TutorialArrow", UIParent)
    arrow:SetSize(64, 64)
    arrow:SetFrameStrata("TOOLTIP")
    arrow:SetFrameLevel(99)
    arrow:Hide()


    -- Draw arrow shape using textures
    -- Arrow head (triangle)
    arrow.head = arrow:CreateTexture(nil, "OVERLAY")
    arrow.head:SetSize(24, 24)
    arrow.head:SetPoint("CENTER", 0, 0)
    arrow.head:SetColorTexture(1, 0.84, 0, 1)  -- Gold color
    arrow.head:SetVertexColor(1, 0.84, 0, 1)

    -- Arrow shaft (rectangle)
    arrow.shaft = arrow:CreateTexture(nil, "OVERLAY")
    arrow.shaft:SetSize(8, 32)
    arrow.shaft:SetPoint("BOTTOM", arrow.head, "TOP", 0, 0)
    arrow.shaft:SetColorTexture(1, 0.84, 0, 1)
    arrow.shaft:SetVertexColor(1, 0.84, 0, 1)

    -- Create triangle vertices for arrow head using SetTexCoord trick
    -- We'll use a simple approach: 3 thin rectangles rotated to form triangle
    arrow.headParts = {}
    for i = 1, 3 do
        local part = arrow:CreateTexture(nil, "OVERLAY")
        part:SetSize(20, 4)
        part:SetColorTexture(1, 0.84, 0, 1)
        table.insert(arrow.headParts, part)
    end

    -- Position triangle parts to form arrow head pointing down
    arrow.headParts[1]:SetPoint("CENTER", arrow.head, "BOTTOM", 0, 0)  -- Bottom tip
    arrow.headParts[2]:SetPoint("CENTER", arrow.head, "TOPLEFT", 6, -2) -- Left side
    arrow.headParts[3]:SetPoint("CENTER", arrow.head, "TOPRIGHT", -6, -2) -- Right side

    -- Apply rotation to triangle parts
    arrow.headParts[1]:SetRotation(0)
    arrow.headParts[2]:SetRotation(math.rad(60))   -- 60 degrees
    arrow.headParts[3]:SetRotation(math.rad(-60))  -- -60 degrees

    -- Bobbing animation
    local arrowAg = arrow:CreateAnimationGroup()
    local move1 = arrowAg:CreateAnimation("Translation")
    move1:SetOffset(0, 10)
    move1:SetDuration(0.6)
    move1:SetOrder(1)

    local move2 = arrowAg:CreateAnimation("Translation")
    move2:SetOffset(0, -10)
    move2:SetDuration(0.6)
    move2:SetOrder(2)

    arrowAg:SetLooping("REPEAT")
    arrow.animGroup = arrowAg

    GDKPT.Tutorial.Arrow = arrow

    ]]
    

    --[[


    -- Arrow Pointer
    local arrow = CreateFrame("Frame", "GDKPT_TutorialArrow", UIParent)
    arrow:SetSize(64, 64)
    arrow:SetFrameStrata("TOOLTIP")
    arrow:SetFrameLevel(99)
    arrow:Hide()
    
    arrow.tex = arrow:CreateTexture(nil, "OVERLAY")
    arrow.tex:SetAllPoints()
    arrow.tex:SetTexture("Interface\\Icons\\ability_blackhand_marked4death")
    
    -- Bobbing animation
    local arrowAg = arrow:CreateAnimationGroup()
    local move1 = arrowAg:CreateAnimation("Translation")
    move1:SetOffset(0, 10)
    move1:SetDuration(0.6)
    move1:SetOrder(1)
    
    local move2 = arrowAg:CreateAnimation("Translation")
    move2:SetOffset(0, -10)
    move2:SetDuration(0.6)
    move2:SetOrder(2)
    
    arrowAg:SetLooping("REPEAT")
    arrow.animGroup = arrowAg
    
    GDKPT.Tutorial.Arrow = arrow

    ]]
end

-------------------------------------------------------------------
-- Create Dummy Auction Row for Tutorial
-------------------------------------------------------------------

function GDKPT.Tutorial.CreateDummyAuction()
    if GDKPT.Tutorial.DummyRow then
        return -- Already exists
    end
    
    -- Create a real auction row
    local row = GDKPT.AuctionRow.CreateAuctionRow()
    
    -- Set dummy data
    row.auctionId = 999
    row.itemID = 19364 -- Ashkandi
    row.itemLink = "|cffa335ee|Hitem:19364::::::::60:::::|h[Ashkandi, Greatsword of the Brotherhood]|h|r"
    row.startBid = 100
    row.minIncrement = 10
    row.currentBid = 150
    row.topBidder = "DemoPlayer"
    row.endTime = GetTime() + 45
    row.duration = 45
    row.stackCount = 1
    row.isFavorite = false
    
    -- Set visuals
    local itemName, _, itemQuality, _, _, _, _, _, _, texture = GetItemInfo(19364)
    if texture then
        row.icon:SetTexture(texture)
    end
    
    if itemName then
        local r, g, b = GetItemQualityColor(itemQuality)
        row.itemLinkText:SetText(row.itemLink)
        row.itemLinkText:SetTextColor(r, g, b)
    end
    
    row.auctionNumber:SetText("999")
    row.favoriteIcon:SetVertexColor(0.5, 0.5, 0.5, 1)
    
    row.bidText:SetText("Current Bid: |cffffd700150|r")
    row.topBidderText:SetText("Top Bidder: DemoPlayer")
    row.topBidderText:SetTextColor(1, 1, 1)
    
    row.bidButton:SetText("160 G")
    row.bidButton:Enable()
    row.bidBox:Enable()
    
    -- Disable actual bidding
    row.bidButton:SetScript("OnClick", function()
        print(GDKPT.Core.print .. "This is a demo auction for the tutorial!")
    end)
    row.bidBox:SetScript("OnEnterPressed", function()
        print(GDKPT.Core.print .. "This is a demo auction for the tutorial!")
    end)
    
    -- Start timer
    row:SetScript("OnUpdate", GDKPT.AuctionRow.UpdateRowTimer)
    
    -- Position at top
    row:ClearAllPoints()
    row:SetPoint("TOP", GDKPT.UI.AuctionContentFrame, "TOP", 0, -5)
    row:Show()
    
    GDKPT.Tutorial.DummyRow = row
    GDKPT.Core.AuctionFrames[999] = row
    
    print(GDKPT.Core.print .. "Demo auction created for tutorial.")
end

-------------------------------------------------------------------
-- Cleanup Dummy Auction
-------------------------------------------------------------------

function GDKPT.Tutorial.CleanupDummyAuction()
    if GDKPT.Tutorial.DummyRow then
        GDKPT.Tutorial.DummyRow:Hide()
        GDKPT.Tutorial.DummyRow:SetScript("OnUpdate", nil)
        GDKPT.Core.AuctionFrames[999] = nil
        GDKPT.Tutorial.DummyRow = nil
        print(GDKPT.Core.print .. "Demo auction removed.")
    end
end

-------------------------------------------------------------------
-- Position Highlight Around Target
-------------------------------------------------------------------

function GDKPT.Tutorial.PositionHighlight(target, highlightType)
    if not target or highlightType == "none" then
        GDKPT.Tutorial.Highlight:Hide()
        return
    end
    
    local highlight = GDKPT.Tutorial.Highlight
    highlight:ClearAllPoints()
    
    if highlightType == "button" or highlightType == "frame" then
        highlight:SetPoint("TOPLEFT", target, "TOPLEFT", -8, 8)
        highlight:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 8, -8)
    elseif highlightType == "text" then
        highlight:SetPoint("TOPLEFT", target, "TOPLEFT", -4, 4)
        highlight:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 4, -4)
    elseif highlightType == "texture" then
        highlight:SetPoint("TOPLEFT", target:GetParent(), "TOPLEFT", target:GetLeft() - 8, -(target:GetTop() - UIParent:GetHeight()) + 8)
        highlight:SetSize(target:GetWidth() + 16, target:GetHeight() + 16)
    end
    
    highlight:Show()
    highlight.animGroup:Play()
end

-------------------------------------------------------------------
-- Position Arrow Pointing to Target
-------------------------------------------------------------------


-------------------------------------------------------------------
-- Position Arrow Pointing to Target
-------------------------------------------------------------------

--[[

function GDKPT.Tutorial.PositionArrow(target, direction)
    if not target or direction == "NONE" then
        GDKPT.Tutorial.Arrow:Hide()
        return
    end
    
    local arrow = GDKPT.Tutorial.Arrow
    arrow:ClearAllPoints()
    
    -- Reset all rotations first
    arrow.shaft:SetRotation(0)
    for _, part in ipairs(arrow.headParts) do
        part:ClearAllPoints()
    end
    
    if direction == "DOWN" then
        arrow:SetPoint("BOTTOM", target, "TOP", 0, 20)
        
        -- Arrow pointing down (default orientation)
        arrow.shaft:SetSize(8, 32)
        arrow.shaft:SetPoint("BOTTOM", arrow.head, "TOP", 0, 0)
        arrow.shaft:SetRotation(0)
        
        arrow.headParts[1]:SetPoint("CENTER", arrow.head, "BOTTOM", 0, 0)
        arrow.headParts[2]:SetPoint("CENTER", arrow.head, "TOPLEFT", 6, -2)
        arrow.headParts[3]:SetPoint("CENTER", arrow.head, "TOPRIGHT", -6, -2)
        arrow.headParts[1]:SetRotation(0)
        arrow.headParts[2]:SetRotation(math.rad(60))
        arrow.headParts[3]:SetRotation(math.rad(-60))
        
    elseif direction == "UP" then
        arrow:SetPoint("TOP", target, "BOTTOM", 0, -20)
        
        -- Arrow pointing up
        arrow.shaft:SetSize(8, 32)
        arrow.shaft:SetPoint("TOP", arrow.head, "BOTTOM", 0, 0)
        arrow.shaft:SetRotation(0)
        
        arrow.headParts[1]:SetPoint("CENTER", arrow.head, "TOP", 0, 0)
        arrow.headParts[2]:SetPoint("CENTER", arrow.head, "BOTTOMLEFT", 6, 2)
        arrow.headParts[3]:SetPoint("CENTER", arrow.head, "BOTTOMRIGHT", -6, 2)
        arrow.headParts[1]:SetRotation(0)
        arrow.headParts[2]:SetRotation(math.rad(-60))
        arrow.headParts[3]:SetRotation(math.rad(60))
        
    elseif direction == "LEFT" then
        arrow:SetPoint("RIGHT", target, "LEFT", -20, 0)
        
        -- Arrow pointing left
        arrow.shaft:SetSize(32, 8)
        arrow.shaft:SetPoint("RIGHT", arrow.head, "LEFT", 0, 0)
        arrow.shaft:SetRotation(0)
        
        arrow.headParts[1]:SetPoint("CENTER", arrow.head, "LEFT", 0, 0)
        arrow.headParts[2]:SetPoint("CENTER", arrow.head, "TOPRIGHT", -2, -6)
        arrow.headParts[3]:SetPoint("CENTER", arrow.head, "BOTTOMRIGHT", -2, 6)
        arrow.headParts[1]:SetRotation(math.rad(90))
        arrow.headParts[2]:SetRotation(math.rad(30))
        arrow.headParts[3]:SetRotation(math.rad(150))
        
    elseif direction == "RIGHT" then
        arrow:SetPoint("LEFT", target, "RIGHT", 20, 0)
        
        -- Arrow pointing right
        arrow.shaft:SetSize(32, 8)
        arrow.shaft:SetPoint("LEFT", arrow.head, "RIGHT", 0, 0)
        arrow.shaft:SetRotation(0)
        
        arrow.headParts[1]:SetPoint("CENTER", arrow.head, "RIGHT", 0, 0)
        arrow.headParts[2]:SetPoint("CENTER", arrow.head, "TOPLEFT", 2, -6)
        arrow.headParts[3]:SetPoint("CENTER", arrow.head, "BOTTOMLEFT", 2, 6)
        arrow.headParts[1]:SetRotation(math.rad(-90))
        arrow.headParts[2]:SetRotation(math.rad(-150))
        arrow.headParts[3]:SetRotation(math.rad(-30))
    end
    
    arrow:Show()
    arrow.animGroup:Play()
end


]]



function GDKPT.Tutorial.PositionArrow(target, direction)
    if not target or direction == "NONE" then
        GDKPT.Tutorial.Arrow:Hide()
        return
    end
    
    local arrow = GDKPT.Tutorial.Arrow
    arrow:ClearAllPoints()
    
    if direction == "DOWN" then
        arrow:SetPoint("BOTTOM", target, "TOP", 0, 20)
        arrow.tex:SetRotation(0)
    elseif direction == "UP" then
        arrow:SetPoint("TOP", target, "BOTTOM", 0, -20)
        arrow.tex:SetRotation(math.pi)
    elseif direction == "LEFT" then
        arrow:SetPoint("RIGHT", target, "LEFT", -20, 0)
        arrow.tex:SetRotation(math.pi / 2)
    elseif direction == "RIGHT" then
        arrow:SetPoint("LEFT", target, "RIGHT", 20, 0)
        arrow.tex:SetRotation(-math.pi / 2)
    end
    
    arrow:Show()
    arrow.animGroup:Play()
end


-------------------------------------------------------------------
-- Show Specific Tutorial Step
-------------------------------------------------------------------

function GDKPT.Tutorial.ShowStep(stepIndex)
    local step = GDKPT.Tutorial.Steps[stepIndex]
    if not step then return end
    
    -- Check if we need auction window open
    if step.requireWindow and not GDKPT.UI.AuctionWindow:IsShown() then
        GDKPT.ToggleLayout.SetLayout("full")
        GDKPT.UI.ShowAuctionWindow()
    end
    
    -- Check if we need dummy auction
    if step.requireDummy and not GDKPT.Tutorial.DummyRow then
        GDKPT.Tutorial.CreateDummyAuction()
    end
    
    -- Update frame text
    local frame = GDKPT.Tutorial.Frame
    frame.Title:SetText(step.title)
    frame.Text:SetText(step.text)
    frame.StepCounter:SetText(string.format("Step %d / %d", stepIndex, #GDKPT.Tutorial.Steps))
    
    -- Update buttons
    if stepIndex == 1 then
        frame.PrevButton:Disable()
    else
        frame.PrevButton:Enable()
    end
    
    if step.isFinal then
        frame.NextButton:SetText("Finish")
    else
        frame.NextButton:SetText("Next")
    end
    
    -- Position highlight and arrow
    local target = step.target and step.target()
    if target then
        GDKPT.Tutorial.PositionHighlight(target, step.highlight)
        GDKPT.Tutorial.PositionArrow(target, step.arrow)
    else
        GDKPT.Tutorial.Highlight:Hide()
        GDKPT.Tutorial.Arrow:Hide()
    end
    
    frame:Show()
end

-------------------------------------------------------------------
-- Progress to Next Step
-------------------------------------------------------------------

function GDKPT.Tutorial.NextStep()
    local step = GDKPT.Tutorial.Steps[GDKPT.Tutorial.CurrentStep]
    
    -- Run completion callback
    if step and step.onComplete then
        step.onComplete()
    end
    
    GDKPT.Tutorial.CurrentStep = GDKPT.Tutorial.CurrentStep + 1
    
    if GDKPT.Tutorial.CurrentStep > #GDKPT.Tutorial.Steps then
        GDKPT.Tutorial.Complete()
    else
        GDKPT.Tutorial.ShowStep(GDKPT.Tutorial.CurrentStep)
    end
end

-------------------------------------------------------------------
-- Go to Previous Step
-------------------------------------------------------------------

function GDKPT.Tutorial.PreviousStep()
    if GDKPT.Tutorial.CurrentStep > 1 then
        GDKPT.Tutorial.CurrentStep = GDKPT.Tutorial.CurrentStep - 1
        GDKPT.Tutorial.ShowStep(GDKPT.Tutorial.CurrentStep)
    end
end

-------------------------------------------------------------------
-- Start Tutorial
-------------------------------------------------------------------

function GDKPT.Tutorial.Start()
    if GDKPT.Tutorial.IsActive then
        print(GDKPT.Core.print .. "Tutorial is already running!")
        return
    end
    
    GDKPT.Tutorial.IsActive = true
    GDKPT.Tutorial.CurrentStep = 1
    
    if not GDKPT.Tutorial.Frame then
        GDKPT.Tutorial.CreateUI()
    end

    if GDKPToggleButton then
        GDKPToggleButton:Show()
    end
    
    GDKPT.Tutorial.ShowStep(1)
    print(GDKPT.Core.print .. "Tutorial started! Follow the instructions.")
end

-------------------------------------------------------------------
-- Stop Tutorial
-------------------------------------------------------------------

function GDKPT.Tutorial.Stop()
    GDKPT.Tutorial.IsActive = false
    GDKPT.Tutorial.CurrentStep = 0
    
    if GDKPT.Tutorial.Frame then
        GDKPT.Tutorial.Frame:Hide()
    end
    if GDKPT.Tutorial.Highlight then
        GDKPT.Tutorial.Highlight:Hide()
        GDKPT.Tutorial.Highlight.animGroup:Stop()
    end
    if GDKPT.Tutorial.Arrow then
        GDKPT.Tutorial.Arrow:Hide()
        GDKPT.Tutorial.Arrow.animGroup:Stop()
    end
    
    GDKPT.Tutorial.CleanupDummyAuction()

    if GDKPT.ToggleLayout and GDKPT.ToggleLayout.UpdateToggleButtonVisibility then
        GDKPT.ToggleLayout.UpdateToggleButtonVisibility()
    end
    
    print(GDKPT.Core.print .. "Tutorial stopped.")
end

-------------------------------------------------------------------
-- Complete Tutorial
-------------------------------------------------------------------

function GDKPT.Tutorial.Complete()
    GDKPT_Tutorial_Completed = true
    GDKPT.Tutorial.Stop()
    
    StaticPopupDialogs["GDKPT_TUTORIAL_COMPLETE"] = {
        text = "|cff00FF00Tutorial Complete!|r\n\nYou can replay it anytime with |cffFFD700/gdkp tutorial|r\n\nGood luck in your GDKP runs!",
        button1 = "Awesome!",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopup_Show("GDKPT_TUTORIAL_COMPLETE")
end