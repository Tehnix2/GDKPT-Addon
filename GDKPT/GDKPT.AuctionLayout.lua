GDKPT.AuctionLayout = {}

function GDKPT.AuctionLayout.RepositionAllAuctions()
    -- Get all auction IDs and sort them
    local auctionIds = {}
    for id, row in pairs(GDKPT.Core.AuctionFrames) do
        if row:IsShown() then  -- Only position visible rows
            table.insert(auctionIds, id)
        end
    end
    
    if #auctionIds == 0 then
        GDKPT.UI.AuctionContentFrame:SetHeight(100)
        return
    end
    
    table.sort(auctionIds)
    
    -- Determine order based on setting
    local showNewOnTop = GDKPT.Core.Settings.NewAuctionsOnTop == 1
    if showNewOnTop then
        -- Reverse the order so newest (highest ID) is first
        local reversed = {}
        for i = #auctionIds, 1, -1 do
            table.insert(reversed, auctionIds[i])
        end
        auctionIds = reversed
    end
    
    -- Position all rows
    local yOffset = -5
    local visibleCount = 0
    for i, auctionId in ipairs(auctionIds) do
        local row = GDKPT.Core.AuctionFrames[auctionId]
        if row and row:IsShown() then
            row:ClearAllPoints()
            row:SetPoint("TOP", GDKPT.UI.AuctionContentFrame, "TOP", 0, yOffset)
            yOffset = yOffset - (row:GetHeight() + 5)
            visibleCount = visibleCount + 1
        end
    end
    
    -- Update content frame height
    local totalHeight = math.max(100, math.abs(yOffset) + 10)
    GDKPT.UI.AuctionContentFrame:SetHeight(totalHeight)
end





--[[


GDKPT.AuctionLayout = {}

function GDKPT.AuctionLayout.RepositionAllAuctions()
    -- Get all auction IDs and sort them
    local auctionIds = {}
    for id, _ in pairs(GDKPT.Core.AuctionFrames) do
        table.insert(auctionIds, id)
    end
    table.sort(auctionIds)
    
    -- Determine order based on setting
    local showNewOnTop = GDKPT.Core.Settings.NewAuctionsOnTop == 1
    if showNewOnTop then
        -- Reverse the order so newest (highest ID) is first
        local reversed = {}
        for i = #auctionIds, 1, -1 do
            table.insert(reversed, auctionIds[i])
        end
        auctionIds = reversed
    end
    
    -- Position all rows
    local yOffset = -5
    for i, auctionId in ipairs(auctionIds) do
        local row = GDKPT.Core.AuctionFrames[auctionId]
        if row then
            row:ClearAllPoints()
            row:SetPoint("TOP", GDKPT.UI.AuctionContentFrame, "TOP", 0, yOffset)
            yOffset = yOffset - (row:GetHeight() + 5)
        end
    end
    
    -- Update content frame height
    local totalHeight = math.abs(yOffset) + 10
    GDKPT.UI.AuctionContentFrame:SetHeight(math.max(totalHeight, 100))
end


]]