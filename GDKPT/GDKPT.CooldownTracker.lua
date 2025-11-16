GDKPT.CooldownTracker = GDKPT.CooldownTracker or {}

GDKPT.CooldownTracker.ActiveCooldowns = {}          
GDKPT.CooldownTracker.MemberFrame = nil             
GDKPT.CooldownTracker.MemberCooldowns = {}          



-------------------------------------------------------------------
-- List of tracked raid cooldowns with their cooldowns
-- (fallback cd values)
-------------------------------------------------------------------

GDKPT.CooldownTracker.TrackedSpells = {
    ["Innervate"]            = { cd = 360, class = "DRUID", icon = "Spell_Nature_Lightning" },
    ["Efflorescence"]        = { cd = 60,  class = "DRUID", icon = "inv_misc_herb_talandrasrose" },
    ["Rebirth"]              = { cd = 600, class = "DRUID", icon = "spell_nature_reincarnation"},
    ["Tranquility"]          = { cd = 480, class = "DRUID", icon = "spell_nature_tranquility"},

    ["Ice Block"]            = { cd = 300, class = "MAGE", icon = "spell_frost_frost"}, 
    ["Mass Invisibility"]    = { cd = 180, class = "MAGE", icon = "ability_mage_massinvisibility"},

    ["Misdirection"]         = { cd = 30, class = "HUNTER", icon = "ability_hunter_misdirection" },

    ["Divine Sacrifice"]     = { cd = 120, class = "PALADIN", icon = "Spell_Holy_PowerWordBarrier" },
    ["Hand of Salvation"]    = { cd = 60,  class = "PALADIN", icon = "spell_holy_sealofsalvation" },
    ["Hand of Protection"]   = { cd = 300, class = "PALADIN", icon = "Spell_Holy_SealOfProtection" },

    ["Divine Hymn"]          = { cd = 480, class = "PRIEST", icon = "Spell_Holy_DivineHymn" },
    ["Hymn of Hope"]         = { cd = 360, class = "PRIEST", icon = "spell_holy_symbolofhope" },
    ["Pain Suppression"]     = { cd = 180, class = "PRIEST", icon = "Spell_Holy_PainSupression" },
    ["Guardian Spirit"]      = { cd = 180, class = "PRIEST", icon = "spell_holy_guardianspirit" },
    ["Halo"]                 = { cd = 45,  class = "PRIEST", icon = "ability_priest_halo" },
    ["Power Word: Barrier"]  = { cd = 120, class = "PRIEST", icon = "spell_holy_powerwordbarrier" },

    ["Tricks of the Trade"]  = { cd = 30,  class = "ROGUE", icon = "ability_rogue_tricksofthetrade" },
    ["Smoke Bomb"]           = { cd = 180, class = "ROGUE", icon = "ability_rogue_smoke" },

    ["Earth Elemental Totem"]= { cd = 600, class = "SHAMAN", icon = "Spell_Nature_EarthElemental_Totem" },
    ["Mana Tide Totem"]      = { cd = 300, class = "SHAMAN", icon = "Spell_Frost_SummonWaterElemental" },
    ["Bloodlust"]            = { cd = 300, class = "SHAMAN", icon = "spell_nature_bloodlust" },

    ["Shield Wall"]          = { cd = 300, class = "WARRIOR", icon = "Ability_Warrior_ShieldWall" },
    ["Disarm"]               = { cd = 60,  class = "WARRIOR", icon = "Ability_Warrior_Disarm" },
}


-------------------------------------------------------------------
-- Cooldown Bar Layout parameters
-------------------------------------------------------------------

local cooldownBarWidth = 200
local cooldownBarHeight = 20
local cooldownIconSize = 20


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
    enabled = true, -- Enable/disable cooldown tracker feature
    trackAll = true,
}

-------------------------------------------------------------------
-- Function that creates checkboxes in config
-------------------------------------------------------------------


function GDKPT.CooldownTracker.CreateConfigCheckboxes()
    local config = GDKPT.CooldownTracker.ConfigFrame
    local scrollChild = config.scrollChild
    
    -- Sort spells by class then name
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
        -- Class header
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
        
        -- Checkbox
        local checkbox = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 10, yOffset)
        checkbox:SetSize(20, 20)
        checkbox.spellName = spell.name
        checkbox:SetScript("OnClick", function(self)
            -- If trackAll is currently true, we need to populate trackedSpells with all spells first
            if GDKPT_CooldownTracker_Settings.trackAll then
                GDKPT_CooldownTracker_Settings.trackAll = false
                -- Add all spells to trackedSpells
                for spellName, _ in pairs(GDKPT.CooldownTracker.TrackedSpells) do
                    GDKPT_CooldownTracker_Settings.trackedSpells[spellName] = true
                end
            end
    
            -- Now toggle this specific spell
            if self:GetChecked() then
                GDKPT_CooldownTracker_Settings.trackedSpells[self.spellName] = true
            else
                GDKPT_CooldownTracker_Settings.trackedSpells[self.spellName] = nil
            end

            -- Refresh the display immediately
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


-------------------------------------------------------------------
-- Update which spells are getting tracked
-------------------------------------------------------------------





function GDKPT.CooldownTracker.UpdateConfigCheckboxes()
    local config = GDKPT.CooldownTracker.ConfigFrame
    if not config then return end

    for _, checkbox in ipairs(config.checkboxes) do
        if checkbox.spellName then
            -- Check if trackAll is true OR if spell is explicitly tracked
            if GDKPT_CooldownTracker_Settings.trackAll then
                checkbox:SetChecked(true)
            else
                checkbox:SetChecked(GDKPT_CooldownTracker_Settings.trackedSpells[checkbox.spellName] == true)
            end
        end
    end
end



-------------------------------------------------------------------
-- Function that gets called when clicking the Config button
-------------------------------------------------------------------



function GDKPT.CooldownTracker.ShowConfigWindow()
    -- Hide Config frame when clicking the Config button while that frame is visible
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
        
        -- Select All / Deselect All buttons
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
        
        -- Scroll frame
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
-- Function that creates the Config button with click handler
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
-- Function that handles incoming cooldown used message from other 
-- raid members
-------------------------------------------------------------------



function GDKPT.CooldownTracker.OnMemberCooldownReceived(msg)
    -- Parse the same way as raid leader
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
-- Function that creates Cooldown Tracker Main Frame for Players
-------------------------------------------------------------------

function GDKPT.CooldownTracker.CreateMainFrame()
    local frame = CreateFrame("Frame", "GDKPTMemberCooldownFrame", UIParent)
    frame:SetSize(280, 400)
    frame:SetPoint("TOPLEFT", 10, -100)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cff00ff00Raid Cooldowns|r")
    
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetSize(20, 20)
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    
    CreateConfigButton(frame)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 10)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)
    frame.content = content
    
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
end




-------------------------------------------------------------------
-- Function that creates a cooldown bar for each used cooldown and 
-- returns the bar and position of the next bar
-------------------------------------------------------------------

local function CreateCooldownBar(parent, playerName, spellName, cdData, yOffset)
    local spellData = GDKPT.CooldownTracker.TrackedSpells[spellName]
    if not spellData then return nil, yOffset end
    
    local barWidth = cooldownBarWidth
    local barHeight = cooldownBarHeight
    local iconSize = cooldownIconSize
    
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
    
    -- Progress bar background
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetPoint("LEFT", icon, "RIGHT", 3, 0)
    barBg:SetSize(barWidth, barHeight)
    barBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    barBg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    
    -- Progress bar
    local barFill = bar:CreateTexture(nil, "BORDER")
    barFill:SetPoint("LEFT", barBg, "LEFT", 0, 0)
    barFill:SetSize(1, barHeight)
    barFill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    barFill:SetVertexColor(0.3, 0.7, 0.3, 0.9)
    
    -- Player name
    local nameText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", barBg, "LEFT", 3, 0)
    nameText:SetText(playerName)
    nameText:SetTextColor(1, 1, 1)
    nameText:SetJustifyH("LEFT")
    
    -- Timer text
    local timerText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerText:SetPoint("RIGHT", barBg, "RIGHT", -3, 0)
    timerText:SetTextColor(1, 1, 1)
    timerText:SetJustifyH("RIGHT")
    
    -- Expose bar attributes
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
   
    -- Update function to update this bar every second
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
-- Function to check if the cooldown for this specific spell shall 
-- be tracked
-------------------------------------------------------------------


local function IsSpellTracked(spellName)
    if GDKPT_CooldownTracker_Settings.trackAll then
        return true
    end
    return GDKPT_CooldownTracker_Settings.trackedSpells[spellName] == true
end





-------------------------------------------------------------------
-- Function to Update the Cooldown bar display, auto sort by 
-- Ready / lowest remaining cooldown
-------------------------------------------------------------------




function GDKPT.CooldownTracker.UpdateMemberDisplay()
    local frame = GDKPT.CooldownTracker.MemberFrame
    if not frame then
        GDKPT.CooldownTracker.CreateMainFrame()  -- Create if missing
        frame = GDKPT.CooldownTracker.MemberFrame
    end
    
    local content = frame.content
    
    -- Clear old bars
    if content.bars then
        for _, bar in ipairs(content.bars) do
            bar:Hide()
        end
    end
    content.bars = {}
    
    -- Collect all cooldowns (filtered by tracked spells)
    local allCooldowns = {}
    for playerName, spells in pairs(GDKPT.CooldownTracker.MemberCooldowns) do
        for spellName, cdData in pairs(spells) do
            if IsSpellTracked(spellName) then
                table.insert(allCooldowns, {
                    playerName = playerName,
                    spellName = spellName,
                    cdData = cdData,
                })
            end
        end
    end
    
    -- Sort: ready first, then by remaining time
    table.sort(allCooldowns, function(a, b)
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
    
    -- Create bars
    local yOffset = -5
    for _, cd in ipairs(allCooldowns) do
        local bar, newY = CreateCooldownBar(content, cd.playerName, cd.spellName, cd.cdData, yOffset)
        if bar then
            table.insert(content.bars, bar)
            yOffset = newY
        end
    end
    
    content:SetHeight(math.max(1, math.abs(yOffset) + 20))
end



-------------------------------------------------------------------
-- Function to toggle the MemberFrame
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
-- Function to send an addon message to other raid members when 
-- a tracked cooldown spell is used
-------------------------------------------------------------------

function GDKPT.CooldownTracker.OnCooldownUsed(spellName)
    local spellData = GDKPT.CooldownTracker.TrackedSpells[spellName]
    if not spellData then return end

    -- Delay briefly to let the cooldown register
    C_Timer.After(0.5, function()
        local start, duration, enabled = GetSpellCooldown(spellName)
        
        -- Use actual cooldown if available, otherwise fall back to our tracked value
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
        if event == "UNIT_SPELLCAST_SENT" and unit == "player" then
            if GDKPT.CooldownTracker.TrackedSpells[spellName] then
                GDKPT.CooldownTracker.OnCooldownUsed(spellName)
            end
        end
    end)
end
