-- General Utility Helper Functions

GDKPT.Utils = {}


-------------------------------------------------------------------
-- Split currency into gold,silver,copper and add icons
-------------------------------------------------------------------


function GDKPT.Utils.FormatGold(amount)
    if amount == 0 then
        return "|cffb4b4b40|r"
    end
    local sign = ""
    if amount < 0 then
        sign = "-"
        amount = -amount
    end

    local absAmount = math.abs(amount)
    local gold = math.floor(absAmount / 10000)
    local silver = math.floor((absAmount % 10000) / 100)
    local copper = absAmount % 100

    local parts = {}
    if gold > 0 then
        table.insert(parts, format("|cffffd700%dg|r", gold))
    end
    if silver > 0 or (gold > 0 and (silver > 0 or copper > 0)) then
        table.insert(parts, format("|cffc7c7cfl%ds|r", silver))
    end
    if copper > 0 or (#parts == 0 and copper >= 0) then
        table.insert(parts, format("|cffeda55f%dc|r", copper))
    end

    if #parts == 0 then
        return "|cffb4b4b40c|r"
    end

    return sign .. table.concat(parts, " ")
end



function GDKPT.Utils.FormatMoney(copper)
    copper = tonumber(copper) or 0

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local remainingCopper = copper % 100

    local goldIcon = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:0:0|t"
    local silverIcon = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:0:0|t"
    local copperIcon = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:0:0|t"

    return string.format("%d%s %d%s %d%s", gold, goldIcon, silver, silverIcon, remainingCopper, copperIcon)
end


-------------------------------------------------------------------
-- Function for returning the name of the raid leader
-------------------------------------------------------------------

function GDKPT.Utils.GetRaidLeaderName()
    if not IsInRaid() then
        return nil 
    end

    for i = 1, GetNumRaidMembers() do
        local name, rank = GetRaidRosterInfo(i)
        if rank == 2 then
            return name
        end
    end

    return nil 
end



-------------------------------------------------------------------
-- Calculate the total amount of gold a player needs to pay for all
-- won auctions
-------------------------------------------------------------------

function GDKPT.Utils.CalculateTotalPaid()
    local total = 0
    for _, item in pairs(GDKPT.Core.PlayerWonItems) do
        total = total + item.bid
    end
    return total * 10000
end


-------------------------------------------------------------------
-- Helper function to bring newest opened frames to foreground
-------------------------------------------------------------------

GDKPT.Utils.MaxFrameLevel = GDKPT.Utils.MaxFrameLevel or 10

function GDKPT.Utils.BringToFront(frame)

    GDKPT.Utils.MaxFrameLevel = GDKPT.Utils.MaxFrameLevel + 2
   
    frame:SetFrameLevel(GDKPT.Utils.MaxFrameLevel)

    if GDKPT.Utils.MaxFrameLevel > 20 then
        GDKPT.Utils.MaxFrameLevel = 10 
    end
end