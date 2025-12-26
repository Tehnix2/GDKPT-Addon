GDKPT.CooldownTracker = GDKPT.CooldownTracker or {}

GDKPT.CooldownTracker.ActiveCooldowns = {}          
GDKPT.CooldownTracker.MemberFrame = nil             
GDKPT.CooldownTracker.MemberCooldowns = {}   

GDKPT.CooldownTracker.CombatLogMode = false        

-------------------------------------------------------------------
-- List of tracked raid cooldowns with categories
-------------------------------------------------------------------

GDKPT.CooldownTracker.TrackedSpells = {
    ["Innervate"]            = { cd = 180, class = "DRUID", icon = "Spell_Nature_Lightning", category = "D" },
    ["Efflorescence"]        = { cd = 60,  class = "DRUID", icon = "inv_misc_herb_talandrasrose", category = "C" },
    ["Rebirth"]              = { cd = 600, class = "DRUID", icon = "spell_nature_reincarnation", category = "E" },
    ["Tranquility"]          = { cd = 480, class = "DRUID", icon = "spell_nature_tranquility", category = "C" },
    ["Barkskin"]             = { cd = 60,  class = "DRUID", icon = "spell_nature_stoneclawtotem", category = "B"},
    ["Survival Instincts"]   = { cd = 180, class = "DRUID", icon = "ability_druid_tigersroar", category = "B"},
    ["Frenzied Regeneration"]= { cd = 180, class = "DRUID", icon = "ability_bullrush", category = "B"},
    ["Flow of Life"]         = { cd = 48,  class = "DRUID", icon = "custom_t_nhance_rpg_icons_tranquilityorb_border", category = "C"}, 

    ["Ice Block"]            = { cd = 300, class = "MAGE", icon = "spell_frost_frost", category = "B" }, 
    ["Mass Invisibility"]    = { cd = 180, class = "MAGE", icon = "ability_mage_massinvisibility", category = "E" },

    ["Misdirection"]         = { cd = 30, class = "HUNTER", icon = "ability_hunter_misdirection", category = "E" },

    ["Divine Sacrifice"]     = { cd = 120, class = "PALADIN", icon = "Spell_Holy_PowerWordBarrier", category = "B" },
    ["Hand of Salvation"]    = { cd = 60,  class = "PALADIN", icon = "spell_holy_sealofsalvation", category = "E" },
    ["Hand of Protection"]   = { cd = 300, class = "PALADIN", icon = "Spell_Holy_SealOfProtection", category = "B" },
    ["Holy Shield"]          = { cd = 30,  class = "PALADIN", icon = "spell_holy_blessingofprotection", category = "B"},
    ["Aura Mastery"]         = { cd = 120, class = "PALADIN", icon = "spell_holy_auramastery", category = "E"},

    ["Divine Hymn"]          = { cd = 480, class = "PRIEST", icon = "Spell_Holy_DivineHymn", category = "C" },
    ["Hymn of Hope"]         = { cd = 360, class = "PRIEST", icon = "spell_holy_symbolofhope", category = "D" },
    ["Pain Suppression"]     = { cd = 180, class = "PRIEST", icon = "Spell_Holy_PainSupression", category = "B" },
    ["Guardian Spirit"]      = { cd = 180, class = "PRIEST", icon = "spell_holy_guardianspirit", category = "B" },
    ["Halo"]                 = { cd = 45,  class = "PRIEST", icon = "ability_priest_halo", category = "C" },
    ["Power Word: Barrier"]  = { cd = 120, class = "PRIEST", icon = "spell_holy_powerwordbarrier", category = "B" },
    ["Psychic Horror"]       = { cd = 120, class = "PRIEST", icon = "spell_shadow_psychichorrors", category = "E"},

    ["Tricks of the Trade"]  = { cd = 30,  class = "ROGUE", icon = "ability_rogue_tricksofthetrade", category = "A" },
    ["Smoke Bomb"]           = { cd = 180, class = "ROGUE", icon = "ability_rogue_smoke", category = "E" },
    ["Dismantle"]            = { cd = 60,  class = "ROGUE", icon = "ability_rogue_dismantle", category = "E"},

    ["Earth Elemental Totem"]= { cd = 600, class = "SHAMAN", icon = "Spell_Nature_EarthElemental_Totem", category = "B" },
    ["Mana Tide Totem"]      = { cd = 180, class = "SHAMAN", icon = "Spell_Frost_SummonWaterElemental", category = "D" },
    ["Bloodlust"]            = { cd = 300, class = "SHAMAN", icon = "spell_nature_bloodlust", category = "A" },
    ["Heroism"]              = { cd = 300, class = "SHAMAN", icon = "ability_shaman_heroism", category = "A"},
    ["Astral Plane"]         = { cd = 120, class = "SHAMAN", icon = "_EnslaveSpell_Astral", category = "B"},

    ["Shield Wall"]          = { cd = 300, class = "WARRIOR", icon = "Ability_Warrior_ShieldWall", category = "B" },
    ["Disarm"]               = { cd = 60,  class = "WARRIOR", icon = "Ability_Warrior_Disarm", category = "E" },
    ["Last Stand"]           = { cd = 120, class = "WARRIOR", icon = "spell_holy_ashestoashes", category = "B"},
}

-------------------------------------------------------------------
-- Category definitions and display order
-------------------------------------------------------------------

-- Default Categories
-- A: Offensive 
-- B: Defensive 
-- C: Healing 
-- D: Mana 
-- E: Utility

GDKPT.CooldownTracker.Categories = {
    { key = "A", name = "A", color = {r = 1.0, g = 0.3, b = 0.3} },
    { key = "B", name = "B", color = {r = 0.3, g = 0.5, b = 1.0} },
    { key = "C", name = "C", color = {r = 0.3, g = 1.0, b = 0.3} },
    { key = "D", name = "D", color = {r = 0.4, g = 0.7, b = 1.0} },
    { key = "E", name = "E", color = {r = 0.9, g = 0.9, b = 0.3} },
}


-------------------------------------------------------------------
-- Mapping of spell IDs to spell names for combat log tracking
-------------------------------------------------------------------

GDKPT.CooldownTracker.SpellIDMap = {
    [1129166] = "Innervate",
    [1186384] = "Efflorescence",
    [1120748] = "Rebirth",
    [1109863] = "Tranquility",
    [1586139] = "Flow of Life",
    [1122812] = "Barkskin",
    [1161336] = "Survival Instincts",
    [1122842] = "Frenzied Regenaration",
    [1145438] = "Ice Block",
    [1398175] = "Mass Invisibility",
    [1134477] = "Misdirection",
    [1164205] = "Divine Sacrifice",
    [1101038] = "Hand of Salvation",
    [1110278] = "Hand of Protection",
    [1120925] = "Holy Shield",
    [1164843] = "Divine Hymn",
    [1164901] = "Hymn of Hope",
    [1133206] = "Pain Suppression",
    [1147788] = "Guardian Spirit",
    [2304897] = "Halo",
    [1180520] = "Power Word: Barrier",
    [1157934] = "Tricks of the Trade",
    [1398189] = "Smoke Bomb",
    [1102062] = "Earth Elemental Totem",
    [1116190] = "Mana Tide Totem",
    [1102825] = "Bloodlust",
    [1132182] = "Heroism",
    [1182049] = "Astral Plane", 
    [1100871] = "Shield Wall",
    [1100676] = "Disarm",
    [1112975] = "Last Stand",
    [1164044] = "Psychic Horror",
    [1151722] = "Dismantle",
    [1131821] = "Aura Mastery,"
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
GDKPT_CooldownTracker_Settings = GDKPT_CooldownTracker_Settings or {}

if not GDKPT_CooldownTracker_Settings.trackedSpells then
    GDKPT_CooldownTracker_Settings.trackedSpells = {}
end

if GDKPT_CooldownTracker_Settings.enabled == nil then
    GDKPT_CooldownTracker_Settings.enabled = true
end

if GDKPT_CooldownTracker_Settings.trackAll == nil then
    GDKPT_CooldownTracker_Settings.trackAll = true
end

if not GDKPT_CooldownTracker_Settings.customCategories then
    GDKPT_CooldownTracker_Settings.customCategories = {}
end

if GDKPT_CooldownTracker_Settings.combatLogMode == nil then
    GDKPT_CooldownTracker_Settings.combatLogMode = false
end

if not GDKPT_CooldownTracker_Settings.barAlpha then
    GDKPT_CooldownTracker_Settings.barAlpha = 0.9
end

if not GDKPT_CooldownTracker_Settings.requestDelay then
    GDKPT_CooldownTracker_Settings.requestDelay = 5
end

if not GDKPT_CooldownTracker_Settings.categoryFrames then
    GDKPT_CooldownTracker_Settings.categoryFrames = {
        A = { scale = 1, x = 0, y = -100, width = 200, height = 200 },
        B = { scale = 1, x = 150, y = -100, width = 200, height = 200 },
        C = { scale = 1, x = 300, y = -100, width = 200, height = 200 },
        D = { scale = 1, x = 450, y = -100, width = 200, height = 200 },
        E = { scale = 1, x = 600, y = -100, width = 200, height = 200 },
    }
end


-------------------------------------------------------------------
-- Function to get the category for a spell (custom or default)
-------------------------------------------------------------------

local function GetSpellCategory(spellName)
    local spellData = GDKPT.CooldownTracker.TrackedSpells[spellName]
    if not spellData then return nil end
    
    -- Check for custom category first
    if GDKPT_CooldownTracker_Settings.customCategories[spellName] then
        return GDKPT_CooldownTracker_Settings.customCategories[spellName]
    end
    
    -- Return default category
    return spellData.category
end



-------------------------------------------------------------------
-- Function for disabling all mouse interactions on cd bars
-------------------------------------------------------------------

local function DisableMouseForFrameRecursively(frame)
    frame:EnableMouse(false)
    if frame.GetChildren then
        for _, child in ipairs({frame:GetChildren()}) do
            DisableMouseForFrameRecursively(child)
        end
    end
end


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
    menu:SetSize(300, 650)
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
    if not GDKPT.CooldownTracker.CategoryFrames then
        GDKPT.CooldownTracker.CreateMainFrame()
    end

    if not GDKPT.CooldownTracker.isEditMode then
        -- Enter edit mode
        GDKPT.CooldownTracker.isEditMode = true
    
        -- Show all category frames with edit UI
        for categoryKey, frame in pairs(GDKPT.CooldownTracker.CategoryFrames) do
            -- Reload saved position first, before any other operations
            local settings = GDKPT_CooldownTracker_Settings.categoryFrames[categoryKey]
            if settings then
                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", settings.x or 0, settings.y or -100)
                frame:SetSize(settings.width or 200, settings.height or 200)
                frame:SetScale(settings.scale or 1)
            end
            
            -- Show and configure the frame
            frame:Show()
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
            frame:SetMovable(true)
            frame:EnableMouse(true)
            frame:RegisterForDrag("LeftButton") 
            frame.resizeButton:Show()
            frame.header:Show()
        end
    
        self:SetText("Save Position & Hide Background")
        print(GDKPT.Core.print .. "Cooldown Tracker: Edit mode enabled. Drag to reposition.")
    else
        -- Exit edit mode
        GDKPT.CooldownTracker.isEditMode = false
    
        for categoryKey, frame in pairs(GDKPT.CooldownTracker.CategoryFrames) do
            frame:SetBackdrop(nil)
            frame:SetMovable(false)
            frame:EnableMouse(false)
            frame.resizeButton:Hide()
            frame.header:Hide()
        end
    
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
        if GDKPT.CooldownTracker.CategoryFrames then
            for _, frame in pairs(GDKPT.CooldownTracker.CategoryFrames) do
                frame:Hide()
            end
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

    -- Reset to Ready Button
    local resetReadyBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    resetReadyBtn:SetSize(buttonWidth, buttonHeight)
    resetReadyBtn:SetPoint("TOP", testBtn, "BOTTOM", 0, -spacing)
    resetReadyBtn:SetText("Reset All to Ready")
    resetReadyBtn:SetScript("OnClick", function()
        GDKPT.CooldownTracker.ResetAllToReady()
        print(GDKPT.Core.print .. "All cooldowns set to READY.")
    end)
    
    -- Clear Data Button
    local clearBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    clearBtn:SetSize(buttonWidth, buttonHeight)
    clearBtn:SetPoint("TOP", resetReadyBtn, "BOTTOM", 0, -15*spacing - 200)
    clearBtn:SetText("Clear All Cooldowns")
    clearBtn:SetScript("OnClick", function()
        wipe(GDKPT.CooldownTracker.MemberCooldowns)
        if GDKPT.CooldownTracker.MemberFrame then
            GDKPT.CooldownTracker.UpdateMemberDisplay()
        end
        print(GDKPT.Core.print .. "Cleared all cooldown data.")
    end)


    -- alpha bar slider

    local alphaLabel = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    alphaLabel:SetPoint("BOTTOM", resetReadyBtn, "BOTTOM", -65 , -30)
    alphaLabel:SetText("Cooldown Bar Opacity:")

    local alphaSlider = CreateFrame("Slider", "GDKPTCooldownAlphaSlider", menu, "OptionsSliderTemplate")
    alphaSlider:SetPoint("LEFT", alphaLabel, "RIGHT", 30, 0)
    alphaSlider:SetMinMaxValues(0.1, 1.0)
    alphaSlider:SetValue(GDKPT_CooldownTracker_Settings.barAlpha or 0.9)
    alphaSlider:SetValueStep(0.1)
    alphaSlider:SetWidth(100)
    _G[alphaSlider:GetName().."Low"]:SetText("10%")
    _G[alphaSlider:GetName().."High"]:SetText("100%")
    _G[alphaSlider:GetName().."Text"]:SetText(string.format("%.0f%%", (GDKPT_CooldownTracker_Settings.barAlpha or 0.9) * 100))

    alphaSlider:SetScript("OnValueChanged", function(self, value)
        GDKPT_CooldownTracker_Settings.barAlpha = value
        _G[self:GetName().."Text"]:SetText(string.format("%.0f%%", value * 100))
        if GDKPT.CooldownTracker.MemberFrame and GDKPT.CooldownTracker.MemberFrame:IsVisible() then
            GDKPT.CooldownTracker.UpdateMemberDisplay()
        end
    end)


    --  Request Delay Slider
    local delayLabel = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    delayLabel:SetPoint("TOPLEFT", alphaLabel, "BOTTOMLEFT", 0, -30)
    delayLabel:SetText("Request Countdown:")

    local delaySlider = CreateFrame("Slider", "GDKPTCooldownDelaySlider", menu, "OptionsSliderTemplate")
    delaySlider:SetPoint("LEFT", delayLabel, "RIGHT", 40, 0)
    delaySlider:SetMinMaxValues(1, 30)
    delaySlider:SetValue(GDKPT_CooldownTracker_Settings.requestDelay or 5)
    delaySlider:SetValueStep(1)
    delaySlider:SetWidth(100)
    _G[delaySlider:GetName().."Low"]:SetText("1")
    _G[delaySlider:GetName().."High"]:SetText("30")
    _G[delaySlider:GetName().."Text"]:SetText(string.format("%d", GDKPT_CooldownTracker_Settings.requestDelay or 5))

    delaySlider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value + 0.5)
        GDKPT_CooldownTracker_Settings.requestDelay = val
        _G[self:GetName().."Text"]:SetText(val)
    end)


    
    -- Combat Log Mode Checkbox 
    local combatLogCheckbox = CreateFrame("CheckButton", nil, menu, "UICheckButtonTemplate")
    combatLogCheckbox:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 30, 75)
    combatLogCheckbox:SetSize(20, 20)
    combatLogCheckbox:SetChecked(GDKPT_CooldownTracker_Settings.combatLogMode or false)
    
    local combatLogLabel = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    combatLogLabel:SetPoint("LEFT", combatLogCheckbox, "RIGHT", 5, 0)
    combatLogLabel:SetText("Combat Log Mode")
    
    combatLogCheckbox:SetScript("OnClick", function(self)
        GDKPT_CooldownTracker_Settings.combatLogMode = self:GetChecked()
        GDKPT.CooldownTracker.CombatLogMode = self:GetChecked()
        
        if self:GetChecked() then
            print(GDKPT.Core.print .. "Combat Log tracking enabled. Cooldowns will be tracked from combat log.")
        else
            print(GDKPT.Core.print .. "Combat Log tracking disabled. Using addon messages only.")
        end

        GDKPT.CooldownTracker.Init()
    end)


    local scaleLabel = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("CENTER", menu, "CENTER", 0, -30)
    scaleLabel:SetText("Category Size Scale:")

    local yPos = -10
    for _, category in ipairs(GDKPT.CooldownTracker.Categories) do
        if not GDKPT_CooldownTracker_Settings.categoryFrames then
            GDKPT_CooldownTracker_Settings.categoryFrames = {}
        end
        if not GDKPT_CooldownTracker_Settings.categoryFrames[category.key] then
            GDKPT_CooldownTracker_Settings.categoryFrames[category.key] = { 
                scale = 1, 
                x = (string.byte(category.key) - string.byte("A")) * 150, 
                y = -100, 
                width = 200, 
                height = 200 
            }
        end

        local catLabel = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        catLabel:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 10, yPos-10)
        catLabel:SetText(category.name .. ":")
        catLabel:SetTextColor(category.color.r, category.color.g, category.color.b)

        local slider = CreateFrame("Slider", "GDKPTCooldownScale"..category.key, menu, "OptionsSliderTemplate")
        slider:SetPoint("LEFT", catLabel, "RIGHT", 10, 0)
        slider:SetMinMaxValues(0.5, 2.0)
        slider:SetValueStep(0.1)
        slider:SetWidth(80)
    
        -- Set up the text labels FIRST before setting value
        local sliderName = slider:GetName()
        _G[sliderName.."Low"]:SetText("0.5")
        _G[sliderName.."High"]:SetText("2.0")
        _G[sliderName.."Text"]:SetText(string.format("%.1f", GDKPT_CooldownTracker_Settings.categoryFrames[category.key].scale or 1))
        _G[sliderName.."Value"]:Hide()
    
        -- NOW set the value (after text elements exist)
        slider:SetValue(GDKPT_CooldownTracker_Settings.categoryFrames[category.key].scale or 1)

        slider.categoryKey = category.key  -- Store reference
        slider:SetScript("OnValueChanged", function(self, value)
            -- Update the text display
            local name = self:GetName()
            if name and _G[name.."Text"] then
               _G[name.."Text"]:SetText(string.format("%.1f", value))
            end
        
            -- Double check the table still exists
            if not GDKPT_CooldownTracker_Settings.categoryFrames then
                GDKPT_CooldownTracker_Settings.categoryFrames = {}
            end
            if not GDKPT_CooldownTracker_Settings.categoryFrames[self.categoryKey] then
                GDKPT_CooldownTracker_Settings.categoryFrames[self.categoryKey] = { 
                    scale = 1, 
                    x = 0, 
                    y = -100, 
                    width = 200, 
                    height = 200 
                }
            end
    
            GDKPT_CooldownTracker_Settings.categoryFrames[self.categoryKey].scale = value
            if GDKPT.CooldownTracker.CategoryFrames and GDKPT.CooldownTracker.CategoryFrames[self.categoryKey] then
                GDKPT.CooldownTracker.CategoryFrames[self.categoryKey]:SetScale(value)
            end
        end)

        yPos = yPos - 35
    end

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
-- Function to create config check boxes
-------------------------------------------------------------------

function GDKPT.CooldownTracker.CreateConfigCheckboxes()

    local config = GDKPT.CooldownTracker.ConfigFrame
    local scrollChild = config.scrollChild
    
    -- Clear existing children
    if config.checkboxes then
        for _, child in ipairs({scrollChild:GetChildren()}) do
            child:Hide()
        end
    end
    config.checkboxes = {}


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

        -- Category Dropdown
        local categoryDropdown = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
        categoryDropdown:SetSize(80, 20)
        categoryDropdown:SetPoint("LEFT", checkbox, "RIGHT", 200,0)
        categoryDropdown:SetNormalFontObject("GameFontNormalSmall")
        categoryDropdown.spellName = spell.name

        -- Function to update dropdown text
        local function UpdateDropdownText()
            local currentCategory = GetSpellCategory(spell.name)
            if currentCategory then
                categoryDropdown:SetText(currentCategory)
            end
        end

        UpdateDropdownText()
        categoryDropdown.UpdateText = UpdateDropdownText
        
        categoryDropdown:SetScript("OnClick", function(self)
            -- Create dropdown menu
            local menu = CreateFrame("Frame", "CategoryDropdownMenu", UIParent, "UIDropDownMenuTemplate")
            local menuList = {}
            
            for _, category in ipairs(GDKPT.CooldownTracker.Categories) do
                table.insert(menuList, {
                    text = category.name,
                    func = function()
                        GDKPT_CooldownTracker_Settings.customCategories[self.spellName] = category.key
                        self:SetText(category.name)
                        
                        if GDKPT.CooldownTracker.MemberFrame and GDKPT.CooldownTracker.MemberFrame:IsVisible() then
                            GDKPT.CooldownTracker.UpdateMemberDisplay()
                        end
                    end
                })
            end
            
            EasyMenu(menuList, menu, "cursor", 0, 0, "MENU")
        end)


        
        table.insert(config.checkboxes, checkbox)

        -- Store dropdown reference so we can update it later
        categoryDropdown.checkbox = checkbox
        table.insert(config.checkboxes, categoryDropdown)
        yOffset = yOffset - 25
    end
    
    scrollChild:SetHeight(math.abs(yOffset))
end


-------------------------------------------------------------------
-- Function to update config check boxes
-------------------------------------------------------------------


function GDKPT.CooldownTracker.UpdateConfigCheckboxes()
    local config = GDKPT.CooldownTracker.ConfigFrame
    if not config then return end

    for _, item in ipairs(config.checkboxes) do
        if item.spellName then
            -- Check if this is a checkbox (has SetChecked method)
            if item.SetChecked then
                -- Update checkbox state
                if GDKPT_CooldownTracker_Settings.trackAll then
                    item:SetChecked(true)
                else
                    item:SetChecked(GDKPT_CooldownTracker_Settings.trackedSpells[item.spellName] == true)
                end
            end
            
            -- Update dropdown text if it has the function
            if item.UpdateText then
                item:UpdateText()
            end
        end
    end
end


-------------------------------------------------------------------
-- Function that shows the config menu
-------------------------------------------------------------------


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
            if GDKPT.CooldownTracker.MemberFrame and GDKPT.CooldownTracker.MemberFrame:IsVisible() then
                GDKPT.CooldownTracker.UpdateMemberDisplay()
            end
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
            if GDKPT.CooldownTracker.MemberFrame and GDKPT.CooldownTracker.MemberFrame:IsVisible() then
                GDKPT.CooldownTracker.UpdateMemberDisplay()
            end
        end)


        local resetCatsBtn = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
        resetCatsBtn:SetSize(120, 22)
        resetCatsBtn:SetPoint("TOPRIGHT", -15, -60)
        resetCatsBtn:SetText("Reset Categories")
        resetCatsBtn:SetNormalFontObject("GameFontNormalSmall")
        resetCatsBtn:SetScript("OnClick", function()
             -- Reset the table
            GDKPT_CooldownTracker_Settings.customCategories = {}
            print("|cff00ff00GDKPT|r Custom categories reset to default.")
            
            -- Re-draw the checkboxes to update the dropdown text
            GDKPT.CooldownTracker.CreateConfigCheckboxes()
            GDKPT.CooldownTracker.UpdateConfigCheckboxes()
            
            -- Update main display
            if GDKPT.CooldownTracker.MemberFrame and GDKPT.CooldownTracker.MemberFrame:IsVisible() then
                GDKPT.CooldownTracker.UpdateMemberDisplay()
            end
        end)


        local categoryText = config:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        categoryText:SetText("Category")
        categoryText:SetPoint("TOPLEFT",250,-60)

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


-------------------------------------------------------------------
-- Config Functions 
-------------------------------------------------------------------


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


    if cmd == "COOLDOWN_USED" then 

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
    elseif cmd == "COOLDOWN_REQUEST" then
        local requester, rest = raw:match("([^:]+):(.+)")
        if requester and rest then
            local spellName, delayStr = rest:match("([^:]+):(%d+)")
            local delay = tonumber(delayStr) or 0
            GDKPT.CooldownTracker.OnSpellRequestReceived(requester, spellName, delay)
        end
    end
end

-------------------------------------------------------------------
-- Create Main Frame with Column Layout
-------------------------------------------------------------------

function GDKPT.CooldownTracker.CreateMainFrame()
    -- Instead of one big frame, create individual frames for each category
    GDKPT.CooldownTracker.CategoryFrames = {}
    
    for _, category in ipairs(GDKPT.CooldownTracker.Categories) do
        local categoryKey = category.key
        local settings = GDKPT_CooldownTracker_Settings.categoryFrames[categoryKey]
        
        -- Create independent frame for this category
        local frame = CreateFrame("Frame", "GDKPTCooldown_"..categoryKey, UIParent)
        frame:SetSize(settings.width or 200, settings.height or 200)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", settings.x or 0, settings.y or -100)
        frame:SetScale(settings.scale or 1)
        frame:EnableMouse(false)
        frame:SetMovable(false)
        frame:RegisterForDrag("LeftButton")
        frame:SetClampedToScreen(true)
        frame:Hide()
        
        frame.categoryKey = categoryKey
        frame.category = category
        
        -- Create scrollable content
        local content = CreateFrame("Frame", nil, frame)
        content:SetPoint("TOPLEFT", 10, -25)
        content:SetPoint("BOTTOMRIGHT", -10, 10)
        content:EnableMouseWheel(true)
        content.scrollOffset = 0
        content:SetScript("OnMouseWheel", function(self, delta)
            local maxScroll = math.max(0, self.contentHeight - self:GetHeight())
            self.scrollOffset = math.max(0, math.min(maxScroll, self.scrollOffset - (delta * 20)))
            GDKPT.CooldownTracker.UpdateMemberDisplay()
        end)
        
        frame.content = content
        frame.bars = {}
        
        -- Category header
        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOP", 0, -5)
        header:SetText(category.name)
        header:SetTextColor(category.color.r, category.color.g, category.color.b)
        frame.header = header
        
        -- Add resize grip (similar to your existing code)
        frame:SetResizable(true)
        frame:SetMinResize(150, 100)
        frame:SetMaxResize(600, 1200)
        
        local resizeButton = CreateFrame("Button", nil, frame)
        resizeButton:SetSize(16, 16)
        resizeButton:SetPoint("BOTTOMRIGHT", -2, 2)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:Hide()
        
        resizeButton:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                frame:StartSizing("BOTTOMRIGHT")
            end
        end)
        
        resizeButton:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                frame:StopMovingOrSizing()
                local width, height = frame:GetWidth(), frame:GetHeight()
                GDKPT_CooldownTracker_Settings.categoryFrames[categoryKey].width = width
                GDKPT_CooldownTracker_Settings.categoryFrames[categoryKey].height = height
                GDKPT.CooldownTracker.UpdateMemberDisplay()
            end
        end)
        
        frame.resizeButton = resizeButton
        
        -- Drag script for moving
        frame:SetScript("OnDragStart", function(self)
            if GDKPT.CooldownTracker.isEditMode then
                self:StartMoving()
            end
        end)
        
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()

            local x = self:GetLeft()
            local y = self:GetTop() - UIParent:GetTop()
            
            -- Save these normalized coordinates
            GDKPT_CooldownTracker_Settings.categoryFrames[categoryKey].x = x
            GDKPT_CooldownTracker_Settings.categoryFrames[categoryKey].y = y

        end)
        
        GDKPT.CooldownTracker.CategoryFrames[categoryKey] = frame
    end
    
    -- Compatibility: use first frame as "MemberFrame" reference
    GDKPT.CooldownTracker.MemberFrame = GDKPT.CooldownTracker.CategoryFrames["A"]
    
    -- Listener for cooldown broadcasts
    local listener = CreateFrame("Frame")
    listener:RegisterEvent("CHAT_MSG_ADDON")
    listener:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
        if prefix ~= GDKPT.Core.addonPrefix then return end
        if msg:match("^COOLDOWN_USED:") or msg:match("^COOLDOWN_REQUEST:") then
            GDKPT.CooldownTracker.OnMemberCooldownReceived(msg)
        end
    end)
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
    --barFill:SetVertexColor(0.3, 0.7, 0.3, 0.9)
    barFill:SetVertexColor(classColor.r, classColor.g, classColor.b, 1.0)

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

    --Store the class color on the bar object so we can access it in the script
    bar.classColor = classColor

    bar:SetScript("OnUpdate", function(self)
        local cdData = GDKPT.CooldownTracker.MemberCooldowns[self.playerName]
        if not cdData or not cdData[self.spellName] then return end
        -- Get current alpha setting dynamically
        local currentAlpha = GDKPT_CooldownTracker_Settings.barAlpha or 0.9
    
        local remaining = cdData[self.spellName].expiresAt - GetTime()
        local totalCD = cdData[self.spellName].cooldown
    
        if remaining > 0 then
            -- Cooldown active: dim the background, fill overlay from left to right
        
            -- Dim the background to half opacity
            self.barBg:SetVertexColor(self.classColor.r, self.classColor.g, self.classColor.b, currentAlpha * 0.5)
        
            -- Fill bar progresses from left to right with FULL opacity
            local progress = 1 - (remaining / totalCD)  -- 0.0 = just used, 1.0 = almost ready
            self.barFill:SetWidth(math.max(1, self.maxWidth * progress))
            self.barFill:SetVertexColor(self.classColor.r, self.classColor.g, self.classColor.b, currentAlpha)
        
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining % 60)
            if mins > 0 then
                self.timerText:SetText(string.format("%d:%02d", mins, secs))
            else
                self.timerText:SetText(string.format("%ds", math.ceil(secs)))
            end
            self.timerText:SetTextColor(1, 1, 1, currentAlpha)
            self.notifiedReady = false
        else
            -- Cooldown ready: background at full opacity, hide fill overlay
            self.barBg:SetVertexColor(self.classColor.r, self.classColor.g, self.classColor.b, currentAlpha)
            self.barFill:SetWidth(0)  -- Hide the fill overlay
        
            self.timerText:SetText("READY")
            self.timerText:SetTextColor(0, 1, 0)
        
            if not self.notifiedReady then
                self.notifiedReady = true
            end
        end
    end)


    bar:EnableMouse(true)
    bar:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            -- Request NOW
            GDKPT.CooldownTracker.SendSpellRequest(self.playerName, self.spellName, 0)
        elseif button == "RightButton" then
            -- Request in X seconds
            local delay = GDKPT_CooldownTracker_Settings.requestDelay or 5
            GDKPT.CooldownTracker.SendSpellRequest(self.playerName, self.spellName, delay)
        end
    end)

    bar:SetScript("OnEnter", function(self)
        local delay = GDKPT_CooldownTracker_Settings.requestDelay or 5
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.spellName, 1, 1, 1)
        GameTooltip:AddLine("Left-click: Request NOW", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: Request in ".. delay .." seconds", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    bar:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)


    -- Apply alpha to bar elements:
    local alpha = GDKPT_CooldownTracker_Settings.barAlpha or 0.9
    barBg:SetAlpha(alpha)
    barFill:SetAlpha(alpha)
    icon:SetAlpha(alpha)
    iconBorder:SetAlpha(alpha)
    nameText:SetAlpha(alpha)
    timerText:SetAlpha(alpha)


    return bar, yOffset - (barHeight + 3)
end


-------------------------------------------------------------------
-- Function to reset all tracked spells to READY
-------------------------------------------------------------------

function GDKPT.CooldownTracker.ResetAllToReady()
    local now = GetTime()
    for playerName, spells in pairs(GDKPT.CooldownTracker.MemberCooldowns) do
        for spellName, data in pairs(spells) do
            -- Set expiration to now, effectively making it ready
            data.expiresAt = now
        end
    end
    GDKPT.CooldownTracker.UpdateMemberDisplay()
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
    if not GDKPT.CooldownTracker.CategoryFrames then
        GDKPT.CooldownTracker.CreateMainFrame()
    end
    
    -- Clear old bars from all category frames
    for categoryKey, frame in pairs(GDKPT.CooldownTracker.CategoryFrames) do
        if frame.bars then
            for _, bar in ipairs(frame.bars) do
                bar:Hide()
            end
        end
        frame.bars = {}
    end
    
    -- Organize cooldowns by category (keep your existing logic)
    local cooldownsByCategory = {}
    for _, category in ipairs(GDKPT.CooldownTracker.Categories) do
        cooldownsByCategory[category.key] = {}
    end
    
    for playerName, spells in pairs(GDKPT.CooldownTracker.MemberCooldowns) do
        for spellName, cdData in pairs(spells) do
            if IsSpellTracked(spellName) then
                local category = GetSpellCategory(spellName)
                if category and cooldownsByCategory[category] then
                    table.insert(cooldownsByCategory[category], {
                        playerName = playerName,
                        spellName = spellName,
                        cdData = cdData,
                    })
                end
            end
        end
    end
    
    -- Sort each category (keep your existing sort logic)
    for category, cooldowns in pairs(cooldownsByCategory) do
        table.sort(cooldowns, function(a, b)
            local aRemaining = a.cdData.expiresAt - GetTime()
            local bRemaining = b.cdData.expiresAt - GetTime()
            local aReady = aRemaining <= 0
            local bReady = bRemaining <= 0
            
            if aReady ~= bReady then return aReady end
            if math.abs(aRemaining - bRemaining) > 0.1 then
                return aRemaining < bRemaining
            end
            return a.playerName < b.playerName
        end)
    end
    
    -- Create bars for each category frame
    for categoryKey, frame in pairs(GDKPT.CooldownTracker.CategoryFrames) do
        local cooldowns = cooldownsByCategory[categoryKey]
        local yOffset = -30 + frame.content.scrollOffset  -- Start below header
        
        for _, cd in ipairs(cooldowns) do
            local bar, newY = CreateCooldownBar(frame.content, cd.playerName, cd.spellName, cd.cdData, yOffset)
            if bar then
                table.insert(frame.bars, bar)
                local scale = GDKPT_CooldownTracker_Settings.categoryFrames[categoryKey].scale or 1
                yOffset = newY - (3 * scale)
            end
        end
        
        frame.content.contentHeight = math.abs(yOffset) + 30
    end
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

    -- Remove any active request overlays for this spell
    if GDKPT.CooldownTracker.FulfillRequest then
        GDKPT.CooldownTracker.FulfillRequest(spellName)
    end

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


GDKPT.CooldownTracker.SpellCastFrame = nil
GDKPT.CooldownTracker.CombatLogFrame = nil



function GDKPT.CooldownTracker.Init()

    -- Create or reuse the spell cast frame (for addon message mode)
    if not GDKPT.CooldownTracker.SpellCastFrame then
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("UNIT_SPELLCAST_SENT")
        
        frame:SetScript("OnEvent", function(self, event, unit, spellName)
            if GDKPT.Core.Settings.SendCooldownMessages ~= 1 then return end    -- Check if spell tracking is allowed
            if GDKPT.CooldownTracker.CombatLogMode then return end              -- Skip if in combat log mode
            
            if event == "UNIT_SPELLCAST_SENT" and unit == "player" then
                if GDKPT.CooldownTracker.TrackedSpells[spellName] then
                    GDKPT.CooldownTracker.OnCooldownUsed(spellName)
                end
            end
        end)  
        GDKPT.CooldownTracker.SpellCastFrame = frame
    end

    -- Create or reuse the combat log frame
    if not GDKPT.CooldownTracker.CombatLogFrame then
        local combatLogFrame = CreateFrame("Frame")
        
        combatLogFrame:SetScript("OnEvent", function(self, event, timestamp, subEvent, _, playerName, _, _, _, _, spellID, spellName, _, _, _, _)

            -- Only track SPELL_CAST_SUCCESS subEvents for cooldown tracker spells
            if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then return end
            if not GDKPT.CooldownTracker.CombatLogMode then return end
            if subEvent ~= "SPELL_CAST_SUCCESS" then return end                 
            if not playerName or not spellID or not spellName then return end 

            -- Check if this is a tracked cooldown spell
            local trackedSpellName = GDKPT.CooldownTracker.SpellIDMap[spellID]
            if not trackedSpellName then return end 
            -- Check if data for this spell exists
            local spellData = GDKPT.CooldownTracker.TrackedSpells[trackedSpellName]
            if not spellData then return end

            -- Create table for this player if it does not exist yet
            if not GDKPT.CooldownTracker.MemberCooldowns[playerName] then
                GDKPT.CooldownTracker.MemberCooldowns[playerName] = {}
            end

            -- Fill the table
            local now = GetTime()
            GDKPT.CooldownTracker.MemberCooldowns[playerName][trackedSpellName] = {
                spellName = trackedSpellName,
                usedAt = now,
                expiresAt = now + spellData.cd,
                cooldown = spellData.cd,
                icon = spellData.icon,
            }

            -- Show the combat-log tracked spell in CooldownTracker
            GDKPT.CooldownTracker.UpdateMemberDisplay()
        end)
        
        GDKPT.CooldownTracker.CombatLogFrame = combatLogFrame
    end

    -- Register or unregister combat log events based on mode
    if GDKPT.CooldownTracker.CombatLogMode then
        GDKPT.CooldownTracker.CombatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        GDKPT.CooldownTracker.CombatLogFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end



-------------------------------------------------------------------
-- Test Command to Fill Cooldown Tracker with Simulated Cooldowns
-------------------------------------------------------------------


function GDKPT.CooldownTracker.SimulateRandomCooldown()
    -- Random player names
    local playerNames = {
        "JoreBear", "MoksTheRat", "Jahjahjah", "Onamia", "Despresso",
        "90gGuy", "Tekknix", "GDKPgirl", "TreahHealGod", "DomoSuicider",
        "Dutch", "Marshy", "MC=dead", "GDKPTnerd", "OoggaDPSMonkey",
        "Nuss", "QTnever100", "SkankyMitchee", "McDoublez", "WorldchatHatesGDKP",
        "PrincessLaura", "KirmithTheFrog", "GDKPT=Ban", "BestICanDo", "YkraMissU",
        "PeeWeeDee", "GigaCheapBro", "Larz2Gorehowl", "ApiBrazil", "FrixMyBINDING",
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










-------------------------------------------------------------------
-- Spell Request System 
-- Adds visual indicators directly on raid frames
-------------------------------------------------------------------

GDKPT.CooldownTracker.RequestFrame = nil
GDKPT.CooldownTracker.ActiveRequests = {}

-- Helper to find which Raid ID a player belongs to
local function GetRaidUnitID(playerName)
    if not IsInRaid() then 
        if UnitName("player") == playerName then return "player" end
        return nil
    end
    
    for i = 1, 40 do
        local unit = "raid"..i
        if UnitName(unit) == playerName then
            return unit
        end
    end
    return nil
end


-------------------------------------------------------------------
-- Find Raid Frame for Unit
-------------------------------------------------------------------
local function FindRaidFrame(unitID)
    if not unitID then return nil end
    
    -- Blizzard Compact Raid Frames
    if CompactRaidFrameContainer then
        for i = 1, 40 do
            local frame = _G["CompactRaidFrame"..i]
            if frame and frame.unit == unitID then
                return frame
            end
        end
    end
    
    -- Blizzard Party Frames
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame"..i]
        if frame and frame.unit == unitID then
            return frame
        end
    end
    
    -- Player frame for self-cast
    if unitID == "player" and PlayerFrame then
        return PlayerFrame
    end
    
    -- Grid/Grid2 
    if Grid2 then
        -- Grid2 frames are in Grid2Layout
        for _, frame in pairs(Grid2:GetModule("Grid2Frame").registeredFrames or {}) do
            if frame.unit == unitID then
                return frame
            end
        end
    end
    
    -- VuhDo
    if VuhDoFrame1 then
        for i = 1, 40 do
            local frame = _G["Vd1H"..i]
            if frame and UnitName(frame.unit) == UnitName(unitID) then
                return frame
            end
        end
    end
    
    -- ElvUI 
    if ElvUF then
        for _, frame in pairs(ElvUF.objects or {}) do
            if type(frame) == "table" and frame.unit == unitID then
                return frame
            end
        end
    end
    
    -- Check for ElvUI raid/raid40 frames directly
    if _G.ElvUF_Raid then
        for i = 1, 40 do
            for j = 1, 5 do
                local frame = _G["ElvUF_RaidGroup"..i.."UnitButton"..j]
                if frame and type(frame) == "table" and frame.unit == unitID then
                    return frame
                end
            end
        end
    end
    
    if _G.ElvUF_Raid40 then
        for i = 1, 8 do
            for j = 1, 5 do
                local frame = _G["ElvUF_Raid40Group"..i.."UnitButton"..j]
                if frame and type(frame) == "table" and frame.unit == unitID then
                    return frame
                end
            end
        end
    end

    -- Shadowed Unit Frames (SUF)
    if ShadowUF then
        for _, frame in pairs(ShadowUF.Units.frameList) do
            if type(frame) == "table" and frame.unit == unitID then
                return frame
            end
        end
    end
    
    -- oUF-based addons (includes SUF and others)
    if oUF then
        for _, frame in pairs(oUF.objects) do
            if frame.unit == unitID then
                return frame
            end
        end
    end

    -- X-Perl
    if XPerl_Raid_Grp1Unit1 then
        for i = 1, 9 do -- Groups 1-9
            for j = 1, 5 do -- Units 1-5
                local frameName = "XPerl_Raid_Grp"..i.."Unit"..j
                local frame = _G[frameName]
                if frame and frame:IsVisible() then
                    -- X-Perl usually stores the unit in .partyid or attribute
                    local fUnit = frame.partyid or frame:GetAttribute("unit")
                    if fUnit == unitID then return frame end
                    
                    -- Fallback: check name if unitIDs are messed up
                    if UnitName(fUnit) == UnitName(unitID) then return frame end
                end
            end
        end
    end

    return nil
end


-------------------------------------------------------------------
-- Create Overlay on Raid Frame
-------------------------------------------------------------------
local function CreateRaidFrameOverlay(raidFrame, spellName, spellIcon, requester, delay)
    if not raidFrame then return nil end
    
    -- Remove old overlay if exists
    if raidFrame.GDKPTSpellRequest then
        raidFrame.GDKPTSpellRequest:Hide()
        raidFrame.GDKPTSpellRequest = nil
    end
    
    -- Create overlay frame
    local overlay = CreateFrame("Frame", nil, raidFrame)
    overlay:SetAllPoints(raidFrame)
    overlay:SetFrameStrata("HIGH")
    overlay:SetFrameLevel(raidFrame:GetFrameLevel() + 20)
    
    -- Spell icon (large, centered)
    local icon = overlay:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\" .. spellIcon)
    
    -- Spell name text (top)
    local spellText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    spellText:SetPoint("BOTTOM", icon, "TOP", 0, 2)
    spellText:SetText(spellName)
    spellText:SetTextColor(0, 1, 0)
    spellText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    
    -- Timer bar background
    local timerBarBg = overlay:CreateTexture(nil, "BORDER")
    timerBarBg:SetSize(60, 8)
    timerBarBg:SetPoint("TOP", icon, "BOTTOM", 0, -2)
    timerBarBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    timerBarBg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    
    -- Timer bar fill
    local timerBar = overlay:CreateTexture(nil, "ARTWORK")
    timerBar:SetSize(60, 8)
    timerBar:SetPoint("LEFT", timerBarBg, "LEFT", 0, 0)
    timerBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    timerBar:SetVertexColor(1, 0.8, 0, 1)
    
    -- Timer text
    local timerText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerText:SetPoint("TOP", timerBarBg, "BOTTOM", 0, -2)
    timerText:SetTextColor(1, 1, 0)
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
   
    

    -- Pulsing animation
    local pulseTime = 0
    overlay:SetScript("OnUpdate", function(self, elapsed)
        pulseTime = pulseTime + elapsed
        
        -- Pulse the glow
        local alpha = 0.3 + (math.sin(pulseTime * 3) * 0.2)
        
        -- Pulse icon border
        local scale = 1 + (math.sin(pulseTime * 4) * 0.1)
        
        -- Update timer
        if delay > 0 then
            local remaining = (self.startTime + delay) - GetTime()
            if remaining > 0 then
                timerText:SetText(string.format("%.1fs", remaining))
                -- Update bar width
                local progress = remaining / delay
                timerBar:SetWidth(60 * progress)
            else
                timerText:SetText("NOW!")
                timerBar:SetWidth(60)
                timerBar:SetVertexColor(0, 1, 0, 1)
            end
        else
            timerText:SetText("NOW!")
            timerBar:SetWidth(60)
        end
    end)


    
    overlay.startTime = GetTime()
    overlay:Show()
    
    -- Store reference
    raidFrame.GDKPTSpellRequest = overlay
    
    return overlay
end

-------------------------------------------------------------------
-- Create Alert Text (Top of Screen)
-------------------------------------------------------------------
local function CreateAlertText()
    if GDKPT.CooldownTracker.AlertFrame then
        return GDKPT.CooldownTracker.AlertFrame
    end
    
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(400, 60)
    frame:SetFrameStrata("HIGH")

    -- Load Saved Position or Default
    if GDKPT_CooldownTracker_Settings.alertFramePos then
        local pos = GDKPT_CooldownTracker_Settings.alertFramePos
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    end

    frame:Hide()
    
    -- Make Moveable & Save Position on Stop
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        -- Save to SavedVariables
        GDKPT_CooldownTracker_Settings.alertFramePos = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y
        }
    end)
    frame:SetClampedToScreen(true)

    -- Text
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    frame.text:SetPoint("CENTER", 0, 0)
    frame.text:SetTextColor(0, 1, 0)


    -- Dynamic Timer Logic
    frame:SetScript("OnUpdate", function(self, elapsed)
        if self.activeRequest then
            local remaining = self.activeRequest.endTime - GetTime()
            if remaining > 0 then
                -- Countdown Mode
                self.text:SetText(string.format("%s wants %s in %ds", self.activeRequest.requester, self.activeRequest.spell, math.ceil(remaining)))
                self.text:SetTextColor(1, 1, 0) -- Yellow
            else
                -- NOW Mode
                self.text:SetText(string.format("%s wants %s NOW!", self.activeRequest.requester, self.activeRequest.spell))
                self.text:SetTextColor(0, 1, 0) -- Green
            end
        end
    end)

    
    GDKPT.CooldownTracker.AlertFrame = frame
    return frame
end

-------------------------------------------------------------------
-- Handle Spell Request
-------------------------------------------------------------------

function GDKPT.CooldownTracker.OnSpellRequestReceived(requester, spellName, delay)
    if GDKPT.Core.Settings.AcceptSpellRequests ~= 1 then return end
    delay = delay or 0
    
    -- Validate spell
    local spellData = GDKPT.CooldownTracker.TrackedSpells[spellName]
    if not spellData then return end
    
    -- Check class match
    local _, playerClass = UnitClass("player")
    if spellData.class ~= playerClass then return end
    
    -- Find unit
    local unitID = GetRaidUnitID(requester)
    if not unitID then return end
    
    -- Find raid frame and apply overlay
    local raidFrame = FindRaidFrame(unitID)
    local overlay = nil
    if raidFrame then
        overlay = CreateRaidFrameOverlay(raidFrame, spellName, spellData.icon, requester, delay)
    end
    
    -- Show Alert Text (with data for dynamic timer)
    local alertFrame = CreateAlertText()
    alertFrame.activeRequest = {
        requester = requester,
        spell = spellName,
        endTime = GetTime() + delay
    }
    alertFrame:Show()
    
    -- Auto-hide Alert fallback (prevents it sticking forever if you never cast)
    -- We use a timestamp to ensure we don't hide a NEW request if it overwrote the OLD one
    local requestTimestamp = GetTime()
    alertFrame.lastRequestTime = requestTimestamp

    C_Timer.After(delay + 5, function()
        if alertFrame and alertFrame:IsShown() and alertFrame.lastRequestTime == requestTimestamp then
            alertFrame:Hide()
        end
    end)
    
    -- Auto-hide Overlay fallback
    if overlay then
        C_Timer.After(delay + 5, function()
            if overlay then overlay:Hide() end
        end)
    end
    
    
    -- Store active request for cleanup
    table.insert(GDKPT.CooldownTracker.ActiveRequests, {
        requester = requester,
        spell = spellName,
        unitID = unitID,
        time = GetTime(),
        delay = delay
    })
end



-------------------------------------------------------------------
-- Send Request
-------------------------------------------------------------------
function GDKPT.CooldownTracker.SendSpellRequest(targetPlayer, spellName, delay)
    delay = delay or 0
    local msg = string.format("COOLDOWN_REQUEST:%s:%s:%d", UnitName("player"), spellName, delay)
    SendAddonMessage(GDKPT.Core.addonPrefix, msg, "WHISPER", targetPlayer)

    if delay == 0 then 
        SendChatMessage(string.format("%s NOW please!",spellName), "WHISPER", nil, targetPlayer)
    else 
        SendChatMessage(string.format("%s in %d seconds please!",spellName, delay), "WHISPER", nil, targetPlayer)
    end


end


-------------------------------------------------------------------
-- When a requested spell is cast kill the overlay
-------------------------------------------------------------------


function GDKPT.CooldownTracker.FulfillRequest(spellName)
    -- Iterate active requests, if spell matches, find that unit's frame and kill the overlay.
    for i = #GDKPT.CooldownTracker.ActiveRequests, 1, -1 do
        local req = GDKPT.CooldownTracker.ActiveRequests[i]
        if req.spell == spellName then
            -- Find frame
            local raidFrame = FindRaidFrame(req.unitID)
            if raidFrame and raidFrame.GDKPTSpellRequest then
                raidFrame.GDKPTSpellRequest:Hide()
                raidFrame.GDKPTSpellRequest = nil
            end
            -- Remove from table
            table.remove(GDKPT.CooldownTracker.ActiveRequests, i)
        end
    end

    -- Remove Alert Frame Text if it matches the cast spell
    local alertFrame = GDKPT.CooldownTracker.AlertFrame
    if alertFrame and alertFrame:IsShown() and alertFrame.activeRequest then
        if alertFrame.activeRequest.spell == spellName then
            alertFrame:Hide()
            alertFrame.activeRequest = nil
        end
    end
end