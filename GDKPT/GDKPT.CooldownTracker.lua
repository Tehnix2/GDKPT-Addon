GDKPT.CooldownTracker = GDKPT.CooldownTracker or {}

GDKPT.CooldownTracker.ActiveCooldowns = {}          
GDKPT.CooldownTracker.MemberFrame = nil             
GDKPT.CooldownTracker.MemberCooldowns = {}          

-------------------------------------------------------------------
-- List of tracked raid cooldowns with categories
-------------------------------------------------------------------

GDKPT.CooldownTracker.TrackedSpells = {
    ["Innervate"]            = { cd = 360, class = "DRUID", icon = "Spell_Nature_Lightning", category = "Mana" },
    ["Efflorescence"]        = { cd = 60,  class = "DRUID", icon = "inv_misc_herb_talandrasrose", category = "Healing" },
    ["Rebirth"]              = { cd = 600, class = "DRUID", icon = "spell_nature_reincarnation", category = "Utility" },
    ["Tranquility"]          = { cd = 480, class = "DRUID", icon = "spell_nature_tranquility", category = "Healing" },

    ["Ice Block"]            = { cd = 300, class = "MAGE", icon = "spell_frost_frost", category = "Defensive" }, 
    ["Mass Invisibility"]    = { cd = 180, class = "MAGE", icon = "ability_mage_massinvisibility", category = "Utility" },

    ["Misdirection"]         = { cd = 30, class = "HUNTER", icon = "ability_hunter_misdirection", category = "Utility" },

    ["Divine Sacrifice"]     = { cd = 120, class = "PALADIN", icon = "Spell_Holy_PowerWordBarrier", category = "Defensive" },
    ["Hand of Salvation"]    = { cd = 60,  class = "PALADIN", icon = "spell_holy_sealofsalvation", category = "Utility" },
    ["Hand of Protection"]   = { cd = 300, class = "PALADIN", icon = "Spell_Holy_SealOfProtection", category = "Defensive" },

    ["Divine Hymn"]          = { cd = 480, class = "PRIEST", icon = "Spell_Holy_DivineHymn", category = "Healing" },
    ["Hymn of Hope"]         = { cd = 360, class = "PRIEST", icon = "spell_holy_symbolofhope", category = "Mana" },
    ["Pain Suppression"]     = { cd = 180, class = "PRIEST", icon = "Spell_Holy_PainSupression", category = "Defensive" },
    ["Guardian Spirit"]      = { cd = 180, class = "PRIEST", icon = "spell_holy_guardianspirit", category = "Defensive" },
    ["Halo"]                 = { cd = 45,  class = "PRIEST", icon = "ability_priest_halo", category = "Healing" },
    ["Power Word: Barrier"]  = { cd = 120, class = "PRIEST", icon = "spell_holy_powerwordbarrier", category = "Defensive" },

    ["Tricks of the Trade"]  = { cd = 30,  class = "ROGUE", icon = "ability_rogue_tricksofthetrade", category = "Offensive" },
    ["Smoke Bomb"]           = { cd = 180, class = "ROGUE", icon = "ability_rogue_smoke", category = "Utility" },

    ["Earth Elemental Totem"]= { cd = 600, class = "SHAMAN", icon = "Spell_Nature_EarthElemental_Totem", category = "Defensive" },
    ["Mana Tide Totem"]      = { cd = 300, class = "SHAMAN", icon = "Spell_Frost_SummonWaterElemental", category = "Mana" },
    ["Bloodlust"]            = { cd = 300, class = "SHAMAN", icon = "spell_nature_bloodlust", category = "Offensive" },

    ["Shield Wall"]          = { cd = 300, class = "WARRIOR", icon = "Ability_Warrior_ShieldWall", category = "Defensive" },
    ["Disarm"]               = { cd = 60,  class = "WARRIOR", icon = "Ability_Warrior_Disarm", category = "Utility" },
}

-------------------------------------------------------------------
-- Category definitions and display order
-------------------------------------------------------------------

GDKPT.CooldownTracker.Categories = {
    { key = "Offensive", name = "Offensive", color = {r = 1.0, g = 0.3, b = 0.3} },
    { key = "Defensive", name = "Defensive", color = {r = 0.3, g = 0.5, b = 1.0} },
    { key = "Healing", name = "Healing", color = {r = 0.3, g = 1.0, b = 0.3} },
    { key = "Mana", name = "Mana", color = {r = 0.4, g = 0.7, b = 1.0} },
    { key = "Utility", name = "Utility", color = {r = 0.9, g = 0.9, b = 0.3} },
}

-------------------------------------------------------------------
-- Cooldown Bar Layout parameters
-------------------------------------------------------------------

local cooldownBarWidth = 100
local cooldownBarHeight = 15
local cooldownIconSize = 15
local columnWidth = cooldownBarWidth + cooldownIconSize + 15
local columnSpacing = 10

-------------------------------------------------------------------
-- Color Constants
-------------------------------------------------------------------

local CLASS_COLORS = {
    DRUID = {r = 1.00, g = 0.49, b = 0.04},
    HUNTER = {r = 0.67, g = 0.83, b = 0.45},
    MAGE = {r = 0.41, g = 0.80, b = 0.94},
    PALADIN = {r = 0.96, g = 0.55, b = 0.73},
    PRIEST = {r = 1.00, g = 1.00, b = 1.00},
    ROGUE = {r = 1.00, g = 0.96, b = 0.41},
    SHAMAN = {r = 0.00, g = 0.44, b = 0.87},
    WARLOCK = {r = 0.58, g = 0.51, b = 0.79},
    WARRIOR = {r = 0.78, g = 0.61, b = 0.43},
    HERO = {r = 1.00, g = 0.84, b = 0.00},
}

-------------------------------------------------------------------
-- Setting Preferences stored in SavedVariables
-------------------------------------------------------------------

GDKPT_CooldownTracker_Settings = GDKPT_CooldownTracker_Settings or {
    trackedSpells = {}, 
    enabled = true,
    trackAll = true,
}


-------------------------------------------------------------------
-- Cooldown Tracker Menu
-------------------------------------------------------------------

GDKPT.CooldownTracker.MenuFrame = nil
GDKPT.CooldownTracker.isEditMode = false


function GDKPT.CooldownTracker.CreateMenu()
    if GDKPT.CooldownTracker.MenuFrame then
        return GDKPT.CooldownTracker.MenuFrame
    end
    
    local menu = CreateFrame("Frame", "GDKPTCooldownMenu", UIParent)
    menu:SetSize(300, 280)
    menu:SetPoint("CENTER")
    menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    menu:SetBackdropColor(0, 0, 0, 0.95)
    menu:EnableMouse(true)
    menu:SetMovable(true)
    menu:RegisterForDrag("LeftButton")
    menu:SetScript("OnDragStart", menu.StartMoving)
    menu:SetScript("OnDragStop", menu.StopMovingOrSizing)
    menu:SetClampedToScreen(true)
    menu:Hide()
    
    -- Title
    local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff00ff00Cooldown Tracker|r")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, menu, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() menu:Hide() end)
    
    -- Button dimensions
    local buttonWidth = 260
    local buttonHeight = 30
    local startY = -50
    local spacing = 10
    
    -- Show/Edit Tracker Button
    local showTrackerBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    showTrackerBtn:SetSize(buttonWidth, buttonHeight)
    showTrackerBtn:SetPoint("TOP", 0, startY)
    showTrackerBtn:SetText("Show Tracker")
    showTrackerBtn:SetScript("OnClick", function(self)
        if not GDKPT.CooldownTracker.MemberFrame then
            GDKPT.CooldownTracker.CreateMainFrame()
        end
        
        local frame = GDKPT.CooldownTracker.MemberFrame
        
        if not GDKPT.CooldownTracker.isEditMode then
            -- Enter edit mode
            GDKPT.CooldownTracker.isEditMode = true
            frame:Show()
            
            -- Show visible background for editing
            frame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true,
                tileSize = 32,
                edgeSize = 32,
                insets = { left = 8, right = 8, top = 8, bottom = 8 }
            })
            frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
            frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
            
            -- Enable movement
            frame:SetMovable(true)
            frame:EnableMouse(true)
            frame:RegisterForDrag("LeftButton")
            
            self:SetText("Save Position & Hide Background")
            
            print(GDKPT.Core.print .. "Cooldown Tracker: Edit mode enabled. Drag to reposition.")
        else
            -- Exit edit mode / Save position
            GDKPT.CooldownTracker.isEditMode = false
            
            -- Hide the background
            frame:SetBackdrop(nil)
            
            -- Disable movement
            frame:SetMovable(false)

            self:SetText("Show Tracker")
            
            print(GDKPT.Core.print .. "Cooldown Tracker: Position saved.")
        end
    end)
    menu.showTrackerBtn = showTrackerBtn
    
    -- Hide Tracker Button
    local hideTrackerBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    hideTrackerBtn:SetSize(buttonWidth, buttonHeight)
    hideTrackerBtn:SetPoint("TOP", showTrackerBtn, "BOTTOM", 0, -spacing)
    hideTrackerBtn:SetText("Hide Tracker")
    hideTrackerBtn:SetScript("OnClick", function()
        if GDKPT.CooldownTracker.MemberFrame then
            GDKPT.CooldownTracker.MemberFrame:Hide()
            GDKPT.CooldownTracker.isEditMode = false
            showTrackerBtn:SetText("Show Tracker")
            print(GDKPT.Core.print .. "Cooldown Tracker hidden.")
        end
    end)
    
    -- Config Button
    local configBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    configBtn:SetSize(buttonWidth, buttonHeight)
    configBtn:SetPoint("TOP", hideTrackerBtn, "BOTTOM", 0, -spacing)
    configBtn:SetText("Configure Tracked Spells")
    configBtn:SetScript("OnClick", function()
        GDKPT.CooldownTracker.ShowConfigWindow()
    end)
    
    -- Fill Test Data Button
    local testBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    testBtn:SetSize(buttonWidth, buttonHeight)
    testBtn:SetPoint("TOP", configBtn, "BOTTOM", 0, -spacing)
    testBtn:SetText("Fill with Test Data")
    testBtn:SetScript("OnClick", function()
        wipe(GDKPT.CooldownTracker.MemberCooldowns)
        GDKPT.CooldownTracker.FillWithTestData(50)
        print(GDKPT.Core.print .. "Filling cooldown tracker with test data...")
    end)
    
    -- Clear Data Button
    local clearBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    clearBtn:SetSize(buttonWidth, buttonHeight)
    clearBtn:SetPoint("TOP", testBtn, "BOTTOM", 0, -spacing)
    clearBtn:SetText("Clear All Cooldowns")
    clearBtn:SetScript("OnClick", function()
        wipe(GDKPT.CooldownTracker.MemberCooldowns)
        if GDKPT.CooldownTracker.MemberFrame then
            GDKPT.CooldownTracker.UpdateMemberDisplay()
        end
        print(GDKPT.Core.print .. "Cleared all cooldown data.")
    end)
    
    GDKPT.CooldownTracker.MenuFrame = menu
    return menu
end


-------------------------------------------------------------------
-- Function for showing the CooldownTracker Menu
-------------------------------------------------------------------


function GDKPT.CooldownTracker.ShowMenu()
    if not GDKPT.CooldownTracker.MenuFrame then
        GDKPT.CooldownTracker.CreateMenu()
    end
    
    local menu = GDKPT.CooldownTracker.MenuFrame
    
    -- Update button text based on current state
    if GDKPT.CooldownTracker.isEditMode then
        menu.showTrackerBtn:SetText("Save Position")
    else
        menu.showTrackerBtn:SetText("Show Tracker")
    end
    
    menu:Show()
end


-------------------------------------------------------------------
-- Function that is called from /gdkp cd
-------------------------------------------------------------------


function GDKPT.CooldownTracker.ToggleMenu()
    if not GDKPT.CooldownTracker.MenuFrame then
        GDKPT.CooldownTracker.CreateMenu()
    end
    
    if GDKPT.CooldownTracker.MenuFrame:IsVisible() then
        GDKPT.CooldownTracker.MenuFrame:Hide()
    else
        GDKPT.CooldownTracker.ShowMenu()
    end
end



-------------------------------------------------------------------
-- Config Functions 
-------------------------------------------------------------------

function GDKPT.CooldownTracker.CreateConfigCheckboxes()
    local config = GDKPT.CooldownTracker.ConfigFrame
    local scrollChild = config.scrollChild
    
    local sortedSpells = {}
    for spell, data in pairs(GDKPT.CooldownTracker.TrackedSpells) do
        table.insert(sortedSpells, {name = spell, data = data})
    end
    table.sort(sortedSpells, function(a, b)
        if a.data.class ~= b.data.class then
            return a.data.class < b.data.class
        end
        return a.name < b.name
    end)
    
    local yOffset = -5
    local lastClass = nil
    
    for _, spell in ipairs(sortedSpells) do
        if spell.data.class ~= lastClass then
            local header = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header:SetPoint("TOPLEFT", 5, yOffset)
            header:SetText(spell.data.class)
            local color = CLASS_COLORS[spell.data.class] or {r = 1, g = 1, b = 1}
            header:SetTextColor(color.r, color.g, color.b)
            table.insert(config.checkboxes, header)
            yOffset = yOffset - 20
            lastClass = spell.data.class
        end
        
        local checkbox = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 10, yOffset)
        checkbox:SetSize(20, 20)
        checkbox.spellName = spell.name
        checkbox:SetScript("OnClick", function(self)
            if GDKPT_CooldownTracker_Settings.trackAll then
                GDKPT_CooldownTracker_Settings.trackAll = false
                for spellName, _ in pairs(GDKPT.CooldownTracker.TrackedSpells) do
                    GDKPT_CooldownTracker_Settings.trackedSpells[spellName] = true
                end
            end
    
            if self:GetChecked() then
                GDKPT_CooldownTracker_Settings.trackedSpells[self.spellName] = true
            else
                GDKPT_CooldownTracker_Settings.trackedSpells[self.spellName] = nil
            end

            if GDKPT.CooldownTracker.MemberFrame and GDKPT.CooldownTracker.MemberFrame:IsVisible() then
                GDKPT.CooldownTracker.UpdateMemberDisplay()
            end
        end)
        
        local label = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(spell.name)
        
        table.insert(config.checkboxes, checkbox)
        yOffset = yOffset - 25
    end
    
    scrollChild:SetHeight(math.abs(yOffset))
end

function GDKPT.CooldownTracker.UpdateConfigCheckboxes()
    local config = GDKPT.CooldownTracker.ConfigFrame
    if not config then return end

    for _, checkbox in ipairs(config.checkboxes) do
        if checkbox.spellName then
            if GDKPT_CooldownTracker_Settings.trackAll then
                checkbox:SetChecked(true)
            else
                checkbox:SetChecked(GDKPT_CooldownTracker_Settings.trackedSpells[checkbox.spellName] == true)
            end
        end
    end
end

function GDKPT.CooldownTracker.ShowConfigWindow()
    if GDKPT.CooldownTracker.ConfigFrame and GDKPT.CooldownTracker.ConfigFrame:IsVisible() then
        GDKPT.CooldownTracker.ConfigFrame:Hide()
        return
    end
    
    if not GDKPT.CooldownTracker.ConfigFrame then
        local config = CreateFrame("Frame", "GDKPTCooldownConfigFrame", UIParent)
        config:SetSize(350, 500)
        config:SetPoint("CENTER")
        config:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        config:SetBackdropColor(0, 0, 0, 0.95)
        config:EnableMouse(true)
        config:SetMovable(true)
        config:RegisterForDrag("LeftButton")
        config:SetScript("OnDragStart", config.StartMoving)
        config:SetScript("OnDragStop", config.StopMovingOrSizing)
        config:SetClampedToScreen(true)
        
        local title = config:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Configure Tracked Cooldowns")
        
        local closeBtn = CreateFrame("Button", nil, config, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() config:Hide() end)
        
        local instructions = config:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        instructions:SetPoint("TOP", 0, -40)
        instructions:SetText("Check spells to track")
        
        local selectAllBtn = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
        selectAllBtn:SetSize(80, 22)
        selectAllBtn:SetPoint("TOPLEFT", 15, -60)
        selectAllBtn:SetText("Select All")
        selectAllBtn:SetNormalFontObject("GameFontNormalSmall")
        selectAllBtn:SetScript("OnClick", function()
            GDKPT_CooldownTracker_Settings.trackAll = true
            wipe(GDKPT_CooldownTracker_Settings.trackedSpells)
            print("|cff00ff00GDKPT|r Tracking all spells")
            GDKPT.CooldownTracker.UpdateConfigCheckboxes()
        end)
        
        local deselectAllBtn = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
        deselectAllBtn:SetSize(90, 22)
        deselectAllBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 5, 0)
        deselectAllBtn:SetText("Deselect All")
        deselectAllBtn:SetNormalFontObject("GameFontNormalSmall")
        deselectAllBtn:SetScript("OnClick", function()
            GDKPT_CooldownTracker_Settings.trackAll = false
            wipe(GDKPT_CooldownTracker_Settings.trackedSpells)
            print("|cff00ff00GDKPT|r Deselected all spells")
            GDKPT.CooldownTracker.UpdateConfigCheckboxes()
        end)
        
        local scrollFrame = CreateFrame("ScrollFrame", nil, config, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 15, -90)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 15)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(1, 1)
        scrollFrame:SetScrollChild(scrollChild)
        config.scrollChild = scrollChild
        config.checkboxes = {}
        
        GDKPT.CooldownTracker.ConfigFrame = config
        GDKPT.CooldownTracker.CreateConfigCheckboxes()
    end
    
    GDKPT.CooldownTracker.UpdateConfigCheckboxes()
    GDKPT.CooldownTracker.ConfigFrame:Show()
end

GDKPT.CooldownTracker.ShowConfigWindow()
GDKPT.CooldownTracker.ConfigFrame:Hide()

local function CreateConfigButton(parentFrame)
    local configButton = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
    configButton:SetSize(50, 18)
    configButton:SetPoint("TOPRIGHT", -25, 2)
    configButton:SetText("Config")
    configButton:SetNormalFontObject("GameFontNormalSmall")
    configButton:SetScript("OnClick", function()
        GDKPT.CooldownTracker.ShowConfigWindow()
    end)
    return configButton
end

-------------------------------------------------------------------
-- Message Handling
-------------------------------------------------------------------

function GDKPT.CooldownTracker.OnMemberCooldownReceived(msg)
    local cmd, raw = msg:match("^([^:]+):(.*)$")
    if cmd ~= "COOLDOWN_USED" then return end

    local parts = {}
    for p in raw:gmatch("[^:]+") do
        table.insert(parts, p)
    end
    
    if #parts < 4 then return end

    local playerName = parts[1]
    local icon = parts[#parts]
    local cooldown = tonumber(parts[#parts - 1])

    local spellParts = {}
    for i = 2, (#parts - 2) do
        table.insert(spellParts, parts[i])
    end
    local spellName = table.concat(spellParts, ":")

    if not GDKPT.CooldownTracker.MemberCooldowns[playerName] then
        GDKPT.CooldownTracker.MemberCooldowns[playerName] = {}
    end

    local now = GetTime()
    GDKPT.CooldownTracker.MemberCooldowns[playerName][spellName] = {
        spellName = spellName,
        usedAt = now,
        expiresAt = now + cooldown,
        cooldown = cooldown,
        icon = icon,
    }

    GDKPT.CooldownTracker.UpdateMemberDisplay()
end

-------------------------------------------------------------------
-- Create Main Frame with Column Layout
-------------------------------------------------------------------

function GDKPT.CooldownTracker.CreateMainFrame()
    local numColumns = #GDKPT.CooldownTracker.Categories
    local frameWidth = (columnWidth * numColumns) + (columnSpacing * (numColumns + 1))
    
    local frame = CreateFrame("Frame", "GDKPTMemberCooldownFrame", UIParent)
    frame:SetSize(frameWidth, 200)
    frame:SetPoint("TOPLEFT", 10, -100)
    frame:EnableMouse(false)
    frame:SetMovable(false)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Create scrollable content frame (no visible scrollbar)
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 10, 0)
    content:SetPoint("BOTTOMRIGHT", -10, 10)
    content:EnableMouseWheel(true)
    content.scrollOffset = 0
    content:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(0, self.contentHeight - self:GetHeight())
        self.scrollOffset = math.max(0, math.min(maxScroll, self.scrollOffset - (delta * 20)))
        GDKPT.CooldownTracker.UpdateMemberDisplay()
    end)
    
    frame.content = content
    frame.columns = {}
    
    -- Create columns for each category (will be repositioned on scale)
    for i, category in ipairs(GDKPT.CooldownTracker.Categories) do
        local column = CreateFrame("Frame", nil, content)
        column:SetSize(columnWidth, 1)
    
        column.category = category.key
        column.categoryIndex = i
        column.bars = {}
    
        frame.columns[category.key] = column
    end

    -- Function to reposition columns based on scale
    frame.RepositionColumns = function(self)
        local scale = GDKPT_CooldownTracker_Settings.frameScale or 1
        local scaledColumnWidth = columnWidth * scale
        local scaledSpacing = columnSpacing * scale
    
        for _, column in pairs(self.columns) do
            local xPos = (column.categoryIndex - 1) * (scaledColumnWidth + scaledSpacing)
            column:ClearAllPoints()
            column:SetPoint("TOPLEFT", xPos, 0)
        end
    end

    -- Initial positioning
    frame:RepositionColumns()
    
    GDKPT.CooldownTracker.MemberFrame = frame
    
    -- Listen for cooldown broadcasts
    local listener = CreateFrame("Frame")
    listener:RegisterEvent("CHAT_MSG_ADDON")
    listener:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
        if prefix ~= GDKPT.Core.addonPrefix then return end
        if msg:match("^COOLDOWN_USED:") then
            GDKPT.CooldownTracker.OnMemberCooldownReceived(msg)
        end
    end)



    -- Add resize grip
    frame:SetResizable(true)
    frame:SetMinResize(200, 100)
    frame:SetMaxResize(2000, 1200)

    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT", -2, 2)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeButton:SetScript("OnMouseDown", function(self)
        frame:StartSizing("BOTTOMRIGHT")
    end)

    resizeButton:SetScript("OnMouseUp", function(self)
        frame:StopMovingOrSizing()
    
        -- Calculate scale based on frame size
        local baseWidth = (columnWidth * numColumns) + (columnSpacing * (numColumns + 1))
        local currentWidth = frame:GetWidth()
        local scale = currentWidth / baseWidth
    
        -- Save size and scale
        if GDKPT_CooldownTracker_Settings then
            GDKPT_CooldownTracker_Settings.frameWidth = currentWidth
            GDKPT_CooldownTracker_Settings.frameHeight = frame:GetHeight()
            GDKPT_CooldownTracker_Settings.frameScale = scale
        end
    
        -- Reposition columns with new scale
        frame:RepositionColumns()
    
        -- Refresh display
        GDKPT.CooldownTracker.UpdateMemberDisplay()
    end)

    frame.resizeButton = resizeButton

    -- Load saved size if available
    if GDKPT_CooldownTracker_Settings and GDKPT_CooldownTracker_Settings.frameWidth then
        frame:SetSize(GDKPT_CooldownTracker_Settings.frameWidth, GDKPT_CooldownTracker_Settings.frameHeight)
        frame:RepositionColumns()  -- Reposition columns based on saved scale
    end








end

-------------------------------------------------------------------
-- Create Cooldown Bar
-------------------------------------------------------------------

local function CreateCooldownBar(parent, playerName, spellName, cdData, yOffset)
    local spellData = GDKPT.CooldownTracker.TrackedSpells[spellName]
    if not spellData then return nil, yOffset end
    
    local scale = GDKPT_CooldownTracker_Settings.frameScale or 1
    local barWidth = cooldownBarWidth * scale
    local barHeight = cooldownBarHeight * scale
    local iconSize = cooldownIconSize * scale
    
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetSize(barWidth + iconSize + 5, barHeight)
    bar:SetPoint("TOPLEFT", 5, yOffset)
    
    -- Spell icon
    local icon = bar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(iconSize, iconSize)
    icon:SetPoint("LEFT", 0, 0)
    icon:SetTexture("Interface\\Icons\\" .. spellData.icon)
    
    -- Icon border
    local iconBorder = bar:CreateTexture(nil, "OVERLAY")
    iconBorder:SetSize(iconSize, iconSize)
    iconBorder:SetPoint("LEFT", 0, 0)
    iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    iconBorder:SetBlendMode("ADD")
    iconBorder:SetVertexColor(0.5, 0.5, 0.5, 0.8)
    
    -- Progress bar background with class color
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetPoint("LEFT", icon, "RIGHT", 3, 0)
    barBg:SetSize(barWidth, barHeight)
    barBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")

    -- Apply class color to background
    local classColor = CLASS_COLORS[spellData.class] or {r = 0.5, g = 0.5, b = 0.5}
    barBg:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.8)


    
    -- Progress bar
    local barFill = bar:CreateTexture(nil, "BORDER")
    barFill:SetPoint("LEFT", barBg, "LEFT", 0, 0)
    barFill:SetSize(1, barHeight)
    barFill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    barFill:SetVertexColor(0.3, 0.7, 0.3, 0.9)
    
    -- Player name
    local nameText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", barBg, "LEFT", 3 * scale, 0)
    nameText:SetText(playerName)
    nameText:SetTextColor(1, 1, 1)
    nameText:SetJustifyH("LEFT")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")

    -- Timer text
    local timerText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerText:SetPoint("RIGHT", barBg, "RIGHT", -3 * scale, 0)
    timerText:SetTextColor(1, 1, 1)
    timerText:SetJustifyH("RIGHT")
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 10 * scale, "OUTLINE")
    
    bar.icon = icon
    bar.iconBorder = iconBorder
    bar.barBg = barBg
    bar.barFill = barFill
    bar.nameText = nameText
    bar.timerText = timerText
    bar.playerName = playerName
    bar.spellName = spellName
    bar.maxWidth = barWidth
    bar.notifiedReady = false
   
    bar:SetScript("OnUpdate", function(self)
        local cdData = GDKPT.CooldownTracker.MemberCooldowns[self.playerName]
        if not cdData or not cdData[self.spellName] then return end
        
        local remaining = cdData[self.spellName].expiresAt - GetTime()
        local totalCD = cdData[self.spellName].cooldown
        
        if remaining > 0 then
            local progress = 1 - (remaining / totalCD)
            self.barFill:SetWidth(math.max(1, self.maxWidth * progress))
            self.barFill:SetVertexColor(0.8, 0.3, 0.3, 0.9)
            
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining % 60)
            if mins > 0 then
                self.timerText:SetText(string.format("%d:%02d", mins, secs))
            else
                self.timerText:SetText(string.format("%ds", math.ceil(secs)))
            end
            self.timerText:SetTextColor(1, 1, 1)
            self.notifiedReady = false
        else
            self.barFill:SetWidth(self.maxWidth)
            self.barFill:SetVertexColor(0.2, 1.0, 0.2, 0.9)
            self.timerText:SetText("READY")
            self.timerText:SetTextColor(0, 1, 0)
            
            if not self.notifiedReady then
                self.notifiedReady = true
            end
        end
    end)
    
    return bar, yOffset - (barHeight + 3)
end

-------------------------------------------------------------------
-- Check if spell is tracked
-------------------------------------------------------------------

local function IsSpellTracked(spellName)
    if GDKPT_CooldownTracker_Settings.trackAll then
        return true
    end
    return GDKPT_CooldownTracker_Settings.trackedSpells[spellName] == true
end

-------------------------------------------------------------------
-- Update Display with Column Layout
-------------------------------------------------------------------

function GDKPT.CooldownTracker.UpdateMemberDisplay()
    local frame = GDKPT.CooldownTracker.MemberFrame
    if not frame then
        GDKPT.CooldownTracker.CreateMainFrame()
        frame = GDKPT.CooldownTracker.MemberFrame
    end
    
    -- Clear old bars from all columns
    for _, column in pairs(frame.columns) do
        if column.bars then
            for _, bar in ipairs(column.bars) do
                bar:Hide()
            end
        end
        column.bars = {}
    end
    
    -- Organize cooldowns by category
    local cooldownsByCategory = {}
    for _, category in ipairs(GDKPT.CooldownTracker.Categories) do
        cooldownsByCategory[category.key] = {}
    end
    
    for playerName, spells in pairs(GDKPT.CooldownTracker.MemberCooldowns) do
        for spellName, cdData in pairs(spells) do
            if IsSpellTracked(spellName) then
                local spellData = GDKPT.CooldownTracker.TrackedSpells[spellName]
                if spellData and spellData.category then
                    table.insert(cooldownsByCategory[spellData.category], {
                        playerName = playerName,
                        spellName = spellName,
                        cdData = cdData,
                    })
                end
            end
        end
    end
    
    -- Sort each category: ready first, then by remaining time
    for category, cooldowns in pairs(cooldownsByCategory) do
        table.sort(cooldowns, function(a, b)
            local aRemaining = a.cdData.expiresAt - GetTime()
            local bRemaining = b.cdData.expiresAt - GetTime()
            local aReady = aRemaining <= 0
            local bReady = bRemaining <= 0
            
            if aReady ~= bReady then
                return aReady
            end
            if math.abs(aRemaining - bRemaining) > 0.1 then
                return aRemaining < bRemaining
            end
            return a.playerName < b.playerName
        end)
    end
    
    -- Create bars for each column
    local maxHeight = 0
    for categoryKey, column in pairs(frame.columns) do
        local cooldowns = cooldownsByCategory[categoryKey]
        local yOffset = -5 + frame.content.scrollOffset  
        
        for _, cd in ipairs(cooldowns) do
            local bar, newY = CreateCooldownBar(column, cd.playerName, cd.spellName, cd.cdData, yOffset)
            if bar then
                table.insert(column.bars, bar)
                local scale = GDKPT_CooldownTracker_Settings.frameScale or 1
                yOffset = newY - (3 * scale)  -- Adjust spacing based on scale
            end
        end
        
        local columnHeight = math.abs(yOffset) + 30
        if columnHeight > maxHeight then
            maxHeight = columnHeight
        end
    end
    
    frame.content.contentHeight = maxHeight
end

-------------------------------------------------------------------
-- Toggle Frame
-------------------------------------------------------------------

function GDKPT.CooldownTracker.ToggleMemberFrame()
    if not GDKPT.CooldownTracker.MemberFrame then
        GDKPT.CooldownTracker.CreateMainFrame()
    end
    
    if GDKPT.CooldownTracker.MemberFrame:IsVisible() then
        GDKPT.CooldownTracker.MemberFrame:Hide()
    else
        GDKPT.CooldownTracker.MemberFrame:Show()
        GDKPT.CooldownTracker.UpdateMemberDisplay()
    end
end

-------------------------------------------------------------------
-- Send Cooldown Message
-------------------------------------------------------------------

function GDKPT.CooldownTracker.OnCooldownUsed(spellName)
    local spellData = GDKPT.CooldownTracker.TrackedSpells[spellName]
    if not spellData then return end

    C_Timer.After(0.5, function()
        local start, duration, enabled = GetSpellCooldown(spellName)
        
        local actualCooldown = spellData.cd
        if duration and duration > 0 then
            actualCooldown = duration
        end

        local playerName = UnitName("player")
        local msg = string.format(
            "COOLDOWN_USED:%s:%s:%d:%s",  
            playerName,
            spellName,  
            actualCooldown,
            spellData.icon
        )

        SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")
    end)
end

-------------------------------------------------------------------
-- Initialize cooldown tracker
-------------------------------------------------------------------

function GDKPT.CooldownTracker.Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_SPELLCAST_SENT")

    frame:SetScript("OnEvent", function(self, event, unit, spellName)
        if GDKPT.Core.Settings.SendCooldownMessages ~= 1 then return end -- Check if spell tracking is allowed
        if event == "UNIT_SPELLCAST_SENT" and unit == "player" then
            if GDKPT.CooldownTracker.TrackedSpells[spellName] then
                GDKPT.CooldownTracker.OnCooldownUsed(spellName)
            end
        end
    end)
end


-------------------------------------------------------------------
-- Test Command to Fill Cooldown Tracker with Simulated Cooldowns
-------------------------------------------------------------------


function GDKPT.CooldownTracker.SimulateRandomCooldown()
    -- Random player names
    local playerNames = {
        "Healmaster", "Tankzor", "Dpsgod", "Raidlead", "Holypally",
        "Frostmage", "Shadowpri", "Restodruid", "Holypriest", "Discopriest",
        "Beartank", "Rettypally", "Combatrog", "Elemshaman", "Armwar",
        "Boomkin", "Markshunt", "Firemage", "Protpally", "Enhshaman",
        "Affllock", "Demowl", "Destrowl", "Blooddk", "Frostdk",
        "Unholydk", "Mistweav", "Brewmast", "Windwalk", "Guardian",
    }
    
    -- Get all tracked spells
    local allSpells = {}
    for spellName, spellData in pairs(GDKPT.CooldownTracker.TrackedSpells) do
        table.insert(allSpells, spellName)
    end
    
    -- Pick random player and spell
    local playerName = playerNames[math.random(#playerNames)]
    local spellName = allSpells[math.random(#allSpells)]
    local spellData = GDKPT.CooldownTracker.TrackedSpells[spellName]
    
    -- Create the addon message format
    local msg = string.format(
        "COOLDOWN_USED:%s:%s:%d:%s",
        playerName,
        spellName,
        spellData.cd,
        spellData.icon
    )
    
    -- Simulate receiving the message
    GDKPT.CooldownTracker.OnMemberCooldownReceived(msg)
    
    return playerName, spellName
end

function GDKPT.CooldownTracker.FillWithTestData(numEntries)
    numEntries = numEntries or 50
    
    print(GDKPT.Core.print .. "Simulating " .. numEntries .. " cooldown uses...")
    
    -- Show frame first
    if not GDKPT.CooldownTracker.MemberFrame then
        GDKPT.CooldownTracker.CreateMainFrame()
    end
    GDKPT.CooldownTracker.MemberFrame:Show()
    
    -- Simulate cooldowns with small delays to avoid overwhelming the system
    local delay = 0.1
    for i = 1, numEntries do
        C_Timer.After(delay, function()
            local player, spell = GDKPT.CooldownTracker.SimulateRandomCooldown()
            
            -- Print progress every 10 entries
            if i % 10 == 0 then
                print(GDKPT.Core.print .. "Progress: " .. i .. "/" .. numEntries)
            end
            
            -- Final message
            if i == numEntries then
                print(GDKPT.Core.print .. "Test data complete! Filled with " .. numEntries .. " cooldowns.")
            end
        end)
        
        -- Small delay between each simulation (0.05 seconds = 50ms)
        delay = delay + 0.05
    end
end
