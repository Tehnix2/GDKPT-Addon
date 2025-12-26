GDKPT_RaidReset_LastResetCheck = GDKPT_RaidReset_LastResetCheck or 0




-------------------------------------------------------------------
-- Function to get current week number 
--(used to track if we've reset this week)
-------------------------------------------------------------------


local function GetCurrentWeekNumber()
    local currentTime = time()
    -- Week starts on Sunday (0), but we want Wednesday (4) to be reset day
    local weekday = tonumber(date("%w", currentTime)) -- 0=Sunday, 1=Monday, ..., 6=Saturday
    local dayOfYear = tonumber(date("%j", currentTime))
    
    -- Adjust to make Wednesday the start of the week
    local adjustedDay = dayOfYear - ((weekday + 4) % 7)
    return math.floor(adjustedDay / 7)
end

-------------------------------------------------------------------
-- Function to check if today is Wednesday
-------------------------------------------------------------------

local function IsWednesday()
    local weekday = tonumber(date("%w", time()))
    return weekday == 3 -- Wednesday = 3
end


-------------------------------------------------------------------
-- Function to perform the raid reset 
-------------------------------------------------------------------


local function PerformRaidReset()
    if ResetInstances then ResetInstances() end    
    if ResetRaids then ResetRaids() end
    if ResetDungeons then ResetDungeons() end
    
    if C_Instance and C_Instance.GetSavedMapAndDifficulty then
        for _, lockout in ipairs(C_Instance:GetSavedMapAndDifficulty()) do
            if C_LootLockout and C_LootLockout.ResetInstanceDifficulty then
                C_LootLockout.ResetInstanceDifficulty(lockout.mapID, lockout.difficultyID)
            end
        end
    end
    
    if C_LootLockout and C_LootLockout.QueryInstanceBinds then
        C_LootLockout.QueryInstanceBinds()
    end
    
    print(GDKPT.Core.print .. "First Login on a Wednesday detected, all raid lockouts are now reset.")
end



-------------------------------------------------------------------
-- Main check function
-------------------------------------------------------------------

function GDKPT.Core.CheckAndResetRaids()
    local currentWeek = GetCurrentWeekNumber()
    
    -- Check if we've already reset this week
    if GDKPT_RaidReset_LastResetCheck >= currentWeek then
        return 
    end
    
    if IsWednesday() then
        PerformRaidReset()
        -- Update the last reset check
        GDKPT_RaidReset_LastResetCheck = currentWeek
    end
end



-------------------------------------------------------------------
-- frame to check for saved instances on player login
-------------------------------------------------------------------

local resetCheckFrame = CreateFrame("Frame")
resetCheckFrame:RegisterEvent("PLAYER_LOGIN")
resetCheckFrame:RegisterEvent("PLAYER_ENTERING_WORLD")


resetCheckFrame:SetScript("OnEvent", function(self, event)

    if GDKPT.Core.Settings.AutoRaidReset == 1 then 
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            GDKPT.Core.CheckAndResetRaids()
        end
    end
end)
