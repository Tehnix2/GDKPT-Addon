GDKPT.AuctionFilters = {}

-------------------------------------------------------------------
-- Auction Filters
-------------------------------------------------------------------

GDKPT.AuctionFilters = GDKPT.AuctionFilters or {}

GDKPT.Core.FilterMyBidsActive = false
GDKPT.Core.FilterOutbidActive = false
GDKPT.Core.isFavoriteFilterActive = false

-- Item Type Filter table
GDKPT.Core.ActiveTypeFilters = {}

-- Binding Filter table (1 = BoP/Soulbound, 2 = BoE/Tradeable)
GDKPT.Core.ActiveBindingFilters = {} 

-------------------------------------------------------------------
-- Tooltip Scanner Setup
-------------------------------------------------------------------

-- Create a dedicated hidden tooltip for scanning BoP item tooltips
local ScanTooltip = CreateFrame("GameTooltip", "GDKPT_ScanTooltip", nil, "GameTooltipTemplate")
ScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- Helper function to detect if an item is BoP/Soulbound/Account Bound
local function IsItemRestricted(itemLink)
    if not itemLink then return false end
    
    ScanTooltip:ClearLines()
    ScanTooltip:SetHyperlink(itemLink)
    
    for i = 1, ScanTooltip:NumLines() do
        local line = _G["GDKPT_ScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                -- Check for standard Bind strings
                if text:find(ITEM_BIND_ON_PICKUP) or 
                   text:find("Soulbound") or 
                   text:find("Account Bound") or 
                   text:find("Binds to realm") or
                   text:find(ITEM_BIND_TO_ACCOUNT or "Binds to account") then
                    return true
                end
            end
        end
    end
    
    return false
end

-------------------------------------------------------------------
-- Auction Filter Dropdown
-------------------------------------------------------------------

local FilterDropdown = CreateFrame("Frame", "GDKPT_FilterDropdown", GDKPT.UI.AuctionWindow, "UIDropDownMenuTemplate")
FilterDropdown:SetPoint("TOP", GDKPT.UI.AuctionWindow, "TOP", -400, -15)
UIDropDownMenu_SetWidth(FilterDropdown, 100)
UIDropDownMenu_SetButtonWidth(FilterDropdown, 100)


-------------------------------------------------------------------
-- Function to apply the selected filter
-------------------------------------------------------------------

function GDKPT.AuctionFilters.ApplyAllFilters()
    local playerName = UnitName("player")

    -- 1. Check if Status Filters are active
    local anyStatusFilterActive = GDKPT.Core.FilterMyBidsActive or 
                                  GDKPT.Core.FilterOutbidActive or 
                                  GDKPT.Core.isFavoriteFilterActive

    -- 2. Check if Type Filters are active
    local anyTypeFilterActive = false
    for k, v in pairs(GDKPT.Core.ActiveTypeFilters) do
        if v then anyTypeFilterActive = true break end
    end

    -- 3. Check if Binding Filters are active
    local anyBindingFilterActive = false
    for k, v in pairs(GDKPT.Core.ActiveBindingFilters) do
        if v then anyBindingFilterActive = true break end
    end

    for auctionId, row in pairs(GDKPT.Core.AuctionFrames) do
        if row and (row:IsShown() or true) then -- Loop all relevant frames
            
            -- ==================================================
            -- STEP 1: Status Check (OR Logic)
            -- ==================================================
            local statusMatch = false
            
            if not anyStatusFilterActive then
                statusMatch = true
            else
                if GDKPT.Core.FilterMyBidsActive and GDKPT.Core.PlayerBidHistory[auctionId] then
                    statusMatch = true
                end
                
                if GDKPT.Core.FilterOutbidActive then
                    local hasBid = GDKPT.Core.PlayerBidHistory[auctionId]
                    local isWinning = (row.topBidder == playerName)
                    if hasBid and not isWinning and row.topBidder ~= "" then
                        statusMatch = true
                    end
                end
                
                if GDKPT.Core.isFavoriteFilterActive and row.isFavorite then
                    statusMatch = true
                end
            end

            -- ==================================================
            -- STEP 2: Item Type Check
            -- ==================================================
            local typeMatch = false
            local itemClass, itemSubClass
            
            if row.itemLink then
                local _, _, _, _, _, iClass, iSubClass = GetItemInfo(row.itemLink)
                itemClass = iClass
                itemSubClass = iSubClass
            end

            if not anyTypeFilterActive then
                typeMatch = true
            elseif itemClass then
                if itemSubClass and GDKPT.Core.ActiveTypeFilters[itemSubClass] then
                    typeMatch = true
                elseif itemClass and GDKPT.Core.ActiveTypeFilters[itemClass] then
                    typeMatch = true
                end
            end

            -- ==================================================
            -- STEP 3: Binding Check (Tooltip Scan)
            -- ==================================================
            local bindingMatch = false

            if not anyBindingFilterActive then
                bindingMatch = true
            elseif row.itemLink then
                local isRestricted = IsItemRestricted(row.itemLink)
                
                -- Filter ID 1: "Bind on Pickup" (Includes Soulbound, Account Bound)
                if GDKPT.Core.ActiveBindingFilters[1] and isRestricted then
                    bindingMatch = true
                end

                -- Filter ID 2: "Bind on Equip" (Includes Tradeable, Mats, etc - anything NOT restricted)
                if GDKPT.Core.ActiveBindingFilters[2] and not isRestricted then
                    bindingMatch = true
                end
            end

            -- ==================================================
            -- STEP 4: Combine Results (AND Logic)
            -- ==================================================
            if statusMatch and typeMatch and bindingMatch then
                row:Show()
            else
                row:Hide()
            end
        end
    end

    -- Reposition all visible auctions
    if GDKPT.AuctionLayout and GDKPT.AuctionLayout.RepositionAllAuctions then
        GDKPT.AuctionLayout.RepositionAllAuctions()
    end

    -- Update the dropdown text
    GDKPT.UI.UpdateFilterDropdownText()
end


-------------------------------------------------------------------
-- Function that updates the text on the filter dropdown
-------------------------------------------------------------------

function GDKPT.UI.UpdateFilterDropdownText()
    local filters = {}
    
    -- Status Filters
    if GDKPT.Core.FilterMyBidsActive then table.insert(filters, "Bids") end
    if GDKPT.Core.FilterOutbidActive then table.insert(filters, "Outbid") end
    if GDKPT.Core.isFavoriteFilterActive then table.insert(filters, "Favs") end
    
    -- Type Filters
    local typeCount = 0
    for k, v in pairs(GDKPT.Core.ActiveTypeFilters) do
        if v then typeCount = typeCount + 1 end
    end
    if typeCount > 0 then
        table.insert(filters, "Type ("..typeCount..")")
    end

    -- Binding Filters
    local bindCount = 0
    for k, v in pairs(GDKPT.Core.ActiveBindingFilters) do
        if v then bindCount = bindCount + 1 end
    end
    if bindCount > 0 then
        table.insert(filters, "Bind ("..bindCount..")")
    end
    
    -- Set Text
    if #filters == 0 then
        UIDropDownMenu_SetText(FilterDropdown, "All")
    elseif #filters == 1 then
        UIDropDownMenu_SetText(FilterDropdown, filters[1])
    else
        UIDropDownMenu_SetText(FilterDropdown, filters[1] .. " +")
    end
end


-------------------------------------------------------------------
-- Function to initialize the Filter Dropdown menu
-------------------------------------------------------------------

local function FilterDropdown_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()

    if level == 1 then
        -- LEVEL 1: Main Options 

        -- "Show All" Reset Button
        info.text = "Show All"
        info.notCheckable = true
        info.func = function()
            GDKPT.Core.FilterMyBidsActive = false
            GDKPT.Core.FilterOutbidActive = false
            GDKPT.Core.isFavoriteFilterActive = false
            GDKPT.Core.ActiveTypeFilters = {} 
            GDKPT.Core.ActiveBindingFilters = {} -- Clear bindings
            GDKPT.AuctionFilters.ApplyAllFilters()
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)

        local sep = UIDropDownMenu_CreateInfo()
        sep.text = ""
        sep.disabled = true
        sep.notCheckable = true
        UIDropDownMenu_AddButton(sep, level)

        -- Status Filters
        info = UIDropDownMenu_CreateInfo()
        info.text = "My Bids"
        info.keepShownOnClick = true
        info.isNotRadio = true
        info.checked = GDKPT.Core.FilterMyBidsActive
        info.func = function()
            GDKPT.Core.FilterMyBidsActive = not GDKPT.Core.FilterMyBidsActive
            GDKPT.AuctionFilters.ApplyAllFilters()
        end
        UIDropDownMenu_AddButton(info, level)

        info.text = "Outbid"
        info.checked = GDKPT.Core.FilterOutbidActive
        info.func = function()
            GDKPT.Core.FilterOutbidActive = not GDKPT.Core.FilterOutbidActive
            GDKPT.AuctionFilters.ApplyAllFilters()
        end
        UIDropDownMenu_AddButton(info, level)

        info.text = "Favorites"
        info.checked = GDKPT.Core.isFavoriteFilterActive
        info.func = function()
            GDKPT.Core.isFavoriteFilterActive = not GDKPT.Core.isFavoriteFilterActive
            GDKPT.AuctionFilters.ApplyAllFilters()
        end
        UIDropDownMenu_AddButton(info, level)

        local sep = UIDropDownMenu_CreateInfo()
        sep.text = ""
        sep.disabled = true
        sep.notCheckable = true
        UIDropDownMenu_AddButton(sep, level)

        -- Category Submenus
        info = UIDropDownMenu_CreateInfo()
        info.text = "Armor"
        info.notCheckable = true
        info.hasArrow = true 
        info.value = "ARMOR_MENU"
        UIDropDownMenu_AddButton(info, level)

        info.text = "Weapon"
        info.notCheckable = true
        info.hasArrow = true
        info.value = "WEAPON_MENU"
        UIDropDownMenu_AddButton(info, level)
        
        info.text = "Jewelry & Misc"
        info.notCheckable = true
        info.hasArrow = true
        info.value = "MISC_MENU"
        UIDropDownMenu_AddButton(info, level)

        -- Binding Submenu
        info.text = "BoP/BoE"
        info.notCheckable = true
        info.hasArrow = true
        info.value = "BINDING_MENU"
        UIDropDownMenu_AddButton(info, level)

    elseif level == 2 then
        -- LEVEL 2: Submenus
        local menuValue = UIDROPDOWNMENU_MENU_VALUE

        -- Helper for Type buttons
        local function AddTypeButton(textLabel)
            local subInfo = UIDropDownMenu_CreateInfo()
            subInfo.text = textLabel
            subInfo.keepShownOnClick = true
            subInfo.isNotRadio = true
            subInfo.checked = GDKPT.Core.ActiveTypeFilters[textLabel]
            subInfo.func = function()
                if GDKPT.Core.ActiveTypeFilters[textLabel] then
                    GDKPT.Core.ActiveTypeFilters[textLabel] = nil
                else
                    GDKPT.Core.ActiveTypeFilters[textLabel] = true
                end
                GDKPT.AuctionFilters.ApplyAllFilters()
            end
            UIDropDownMenu_AddButton(subInfo, level)
        end

        -- Helper for Binding buttons
        local function AddBindingButton(textLabel, bindID)
            local subInfo = UIDropDownMenu_CreateInfo()
            subInfo.text = textLabel
            subInfo.keepShownOnClick = true
            subInfo.isNotRadio = true
            subInfo.checked = GDKPT.Core.ActiveBindingFilters[bindID]
            subInfo.func = function()
                if GDKPT.Core.ActiveBindingFilters[bindID] then
                    GDKPT.Core.ActiveBindingFilters[bindID] = nil
                else
                    GDKPT.Core.ActiveBindingFilters[bindID] = true
                end
                GDKPT.AuctionFilters.ApplyAllFilters()
            end
            UIDropDownMenu_AddButton(subInfo, level)
        end

        if menuValue == "ARMOR_MENU" then
            AddTypeButton("Cloth")
            AddTypeButton("Leather")
            AddTypeButton("Mail")
            AddTypeButton("Plate")
            AddTypeButton("Shields")
            
        elseif menuValue == "WEAPON_MENU" then
            AddTypeButton("One-Handed Axes")
            AddTypeButton("Two-Handed Axes")
            AddTypeButton("One-Handed Swords")
            AddTypeButton("Two-Handed Swords")
            AddTypeButton("One-Handed Maces")
            AddTypeButton("Two-Handed Maces")
            AddTypeButton("Daggers")
            AddTypeButton("Bows")
            AddTypeButton("Guns")
            AddTypeButton("Crossbows")
            AddTypeButton("Staves")
            AddTypeButton("Wands")
            
        elseif menuValue == "MISC_MENU" then
            AddTypeButton("Miscellaneous") 
            AddTypeButton("Cloak") 
            AddTypeButton("Idols")
            AddTypeButton("Totems")
            AddTypeButton("Librams")

        elseif menuValue == "BINDING_MENU" then
            -- Matches scan for BoP/Soulbound strings
            AddBindingButton("Bind on Pickup", 1)
            -- Matches anything that does NOT have BoP/Soulbound strings
            AddBindingButton("Bind on Equip", 2)
        end
    end
end


-- Initialize the dropdown
UIDropDownMenu_Initialize(FilterDropdown, FilterDropdown_Initialize)
GDKPT.UI.UpdateFilterDropdownText()
FilterDropdown:SetScale(0.9)  

GDKPT.AuctionFilters.FilterDropdown = FilterDropdown
