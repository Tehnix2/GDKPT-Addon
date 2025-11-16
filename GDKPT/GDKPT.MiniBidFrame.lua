GDKPT.MiniBidFrame = {}

local miniBidRows = {}
local MINI_ROW_HEIGHT = 30

-------------------------------------------------------------------
-- Create the Mini Bid Frame
-------------------------------------------------------------------

local function CreateMiniBidFrame()
    local frame = CreateFrame("Frame", "GDKPT_MiniBidFrame", UIParent)
    frame:SetSize(350, 400)
    frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -50, -100)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 20,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:SetFrameLevel(5)
    frame:Hide()
    
    _G["GDKPT_MiniBidFrame"] = frame
    tinsert(UISpecialFrames, "GDKPT_MiniBidFrame")
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cffFFC125Quick Bidding|r")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetSize(25, 25)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    frame.scrollChild = scrollChild
    frame.scrollFrame = scrollFrame
    
    return frame
end

-------------------------------------------------------------------
-- Create a mini bid row
-------------------------------------------------------------------

local function CreateMiniBidRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(290, MINI_ROW_HEIGHT)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    
    -- Background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    row.bg = bg
    
    -- Auction number
    row.auctionNum = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.auctionNum:SetPoint("LEFT", 5, 0)
    row.auctionNum:SetWidth(20)
    
    -- Item icon
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(24, 24)
    row.icon:SetPoint("LEFT", 30, 0)
    
    -- Timer
    row.timer = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.timer:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
    row.timer:SetWidth(45)
    row.timer:SetTextColor(1, 1, 0)

    -- Winner name
    row.winner = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.winner:SetPoint("LEFT", row.timer, "RIGHT", 5, 0)
    row.winner:SetWidth(80)
    row.winner:SetTextColor(0.8, 0.8, 0.8, 1)
    row.winner:SetJustifyH("LEFT")
    
    -- Bid box
    row.bidBox = CreateFrame("EditBox", nil, row)
    row.bidBox:SetSize(50, 20)
    row.bidBox:SetPoint("RIGHT", -65, 0)
    row.bidBox:SetNumeric(true)
    row.bidBox:SetAutoFocus(false)
    row.bidBox:SetFont("Fonts\\FRIZQT__.TTF", 12)
    row.bidBox:SetTextInsets(3, 3, 0, 0)
    row.bidBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    row.bidBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    row.bidBox:SetBackdropBorderColor(0.8, 0.6, 0, 1)
    
    row.bidBox:SetScript("OnEnterPressed", function(self)
        local auctionId = self:GetParent().auctionId
        local bidAmount = tonumber(self:GetText())
        
        if not auctionId or not bidAmount or bidAmount <= 0 then
            return
        end

        -- Disable both frames immediately
        local mainRow = GDKPT.Core.AuctionFrames[auctionId]
        if mainRow and mainRow.bidButton then
            mainRow.bidButton:Disable()
            mainRow.bidButton:SetText("Syncing...")
        end
    
        local miniRow = self:GetParent()
        if miniRow.bidBtn then
            miniRow.bidBtn:Disable()
            miniRow.bidBtn:SetText("...")
        end
        
        -- Track this bid
        GDKPT.Core.PlayerActiveBids[auctionId] = bidAmount
        GDKPT.Core.PlayerBidHistory[auctionId] = true

        -- Send bid
        local msg = string.format("BID:%d:%d", auctionId, bidAmount)
        SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")
        
        print(GDKPT.Core.print .. "Bid placed: " .. bidAmount .. "g on Auction #" .. auctionId)
        
        self:SetText("")
        self:ClearFocus()
    end)
    
    row.bidBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    
    -- Bid button
    row.bidBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.bidBtn:SetSize(55, 22)
    row.bidBtn:SetPoint("RIGHT", -5, 0)
    row.bidBtn:SetText("Bid")
    row.bidBtn:SetNormalFontObject("GameFontNormalSmall")
    
    row.bidBtn:SetScript("OnClick", function(self)
        local auctionId = self:GetParent().auctionId
        local mainRow = GDKPT.Core.AuctionFrames[auctionId]
        if not mainRow then return end

        local nextMinBid = mainRow.topBidder == "" and mainRow.startBid or (mainRow.currentBid + mainRow.minIncrement)

        -- Disable both frames immediately
        if mainRow.bidButton then
            mainRow.bidButton:Disable()
            mainRow.bidButton:SetText("Syncing...")
        end
    
        local miniRow = self:GetParent()
        if miniRow.bidBtn then
            miniRow.bidBtn:Disable()
            miniRow.bidBtn:SetText("...")
        end

        -- Track this bid
        GDKPT.Core.PlayerActiveBids[auctionId] = nextMinBid
        GDKPT.Core.PlayerBidHistory[auctionId] = true
        
        -- Send bid
        local msg = string.format("BID:%d:%d", auctionId, nextMinBid)
        SendAddonMessage(GDKPT.Core.addonPrefix, msg, "RAID")
        
        print(GDKPT.Core.print .. "Bid placed: " .. nextMinBid .. "g on Auction #" .. auctionId)
    end)
    
    -- Tooltip
    row:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- OnUpdate for timer - FIXED to not interfere with bid box
    row:SetScript("OnUpdate", function(self)
        if not self.endTime or self.endTime == 0 then
            self.timer:SetText("--:--")
            return
        end
        
        local remaining = self.endTime - GetTime()
        
        local SYNC_BUFFER = 5 -- Match main window behavior
        
        if remaining > SYNC_BUFFER then
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining % 60)
            
            local color
            if remaining < 10 then
                color = "|cffff0000"
            elseif remaining < 30 then
                color = "|cffffaa00"
            else
                color = "|cffffffff"
            end
            
            self.timer:SetText(string.format("%s%d:%02d|r", color, mins, secs))
        elseif remaining > 0 then
            -- Show "Ending Soon..." like main window
            self.timer:SetText("|cffff9900Soon...|r")
        else
            self.timer:SetText("|cffff0000ENDED|r")
        end
    end)
    
    
    return row
end

-------------------------------------------------------------------
-- Update the mini frame
-------------------------------------------------------------------
function GDKPT.MiniBidFrame.Update()
    local frame = GDKPT.MiniBidFrame.Frame
    if not frame or not frame:IsShown() then return end
    
    -- Hide all rows
    for _, row in ipairs(miniBidRows) do
        row:Hide()
    end
    
    -- Get active auctions
    local activeAuctions = {}
    for auctionId, row in pairs(GDKPT.Core.AuctionFrames) do
        if row:IsShown() and not (row.endOverlay and row.endOverlay:IsShown()) then
            table.insert(activeAuctions, {
                id = auctionId,
                row = row
            })
        end
    end
    
    -- Sort by auction ID
    table.sort(activeAuctions, function(a, b)
        return a.id < b.id
    end)
    
    -- Create/update rows
    for i, auctionData in ipairs(activeAuctions) do
        if not miniBidRows[i] then
            miniBidRows[i] = CreateMiniBidRow(frame.scrollChild)
        end
        
        local miniRow = miniBidRows[i]
        local mainRow = auctionData.row
        
        miniRow.auctionId = auctionData.id
        miniRow.itemLink = mainRow.itemLink
        miniRow.endTime = mainRow.endTime
        
        -- Update visuals
        miniRow.auctionNum:SetText(auctionData.id)
        
        if mainRow.icon and mainRow.icon:GetTexture() then
            miniRow.icon:SetTexture(mainRow.icon:GetTexture())
        end
        
        -- Update winner display
        if mainRow.topBidder and mainRow.topBidder ~= "" then
            miniRow.winner:SetText(mainRow.topBidder)
            if mainRow.topBidder == UnitName("player") then
                miniRow.winner:SetTextColor(0, 1, 0)
            else
                miniRow.winner:SetTextColor(0.8, 0.8, 0.8)
            end
        else
            miniRow.winner:SetText("")
        end
        
        -- Update bid button state to match main row
        if mainRow.bidButton then
            if mainRow.bidButton:IsEnabled() then
                miniRow.bidBtn:Enable()
                local nextMinBid = mainRow.topBidder == "" and mainRow.startBid or (mainRow.currentBid + mainRow.minIncrement)
                miniRow.bidBtn:SetText(nextMinBid .. "g")
            else
                miniRow.bidBtn:Disable()
                local btnText = mainRow.bidButton:GetText()
                if btnText == "Syncing..." then
                    miniRow.bidBtn:SetText("...")
                elseif btnText == "Processing..." then
                    miniRow.bidBtn:SetText("...")
                elseif btnText == "ENDED" then
                    miniRow.bidBtn:SetText("END")
                else
                    miniRow.bidBtn:SetText("...")
                end
            end
        end
        
        -- Position
        miniRow:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, -(i-1) * MINI_ROW_HEIGHT)
        miniRow:Show()
        
        -- Color based on bid status
        local hasBid = GDKPT.Core.PlayerBidHistory[auctionData.id]
        local isWinning = (mainRow.topBidder == UnitName("player"))
        
        if isWinning then
            miniRow.bg:SetColorTexture(0, 0.5, 0.3, 0.8)
        elseif hasBid then
            miniRow.bg:SetColorTexture(0.5, 0.1, 0.1, 0.8)
        else
            miniRow.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        end
    end
    
    -- Update scroll height
    local totalHeight = #activeAuctions * MINI_ROW_HEIGHT
    frame.scrollChild:SetHeight(math.max(totalHeight, frame.scrollFrame:GetHeight()))
end

-------------------------------------------------------------------
-- Toggle mini frame
-------------------------------------------------------------------

function GDKPT.MiniBidFrame.Toggle()
    if not GDKPT.MiniBidFrame.Frame then
        GDKPT.MiniBidFrame.Frame = CreateMiniBidFrame()
    end
    
    if GDKPT.MiniBidFrame.Frame:IsShown() then
        GDKPT.MiniBidFrame.Frame:Hide()
    else
        GDKPT.MiniBidFrame.Frame:Show()
        GDKPT.MiniBidFrame.Update()
    end
end

-------------------------------------------------------------------
-- Hook into auction updates to refresh mini frame
-------------------------------------------------------------------

local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 1 then
        self.elapsed = 0
        if GDKPT.MiniBidFrame.Frame and GDKPT.MiniBidFrame.Frame:IsShown() then
            GDKPT.MiniBidFrame.Update()
        end
    end
end)