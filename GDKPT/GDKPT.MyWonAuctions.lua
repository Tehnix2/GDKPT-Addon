GDKPT.MyWonAuctions = {}


-------------------------------------------------------------------
-- Won Auctions UI Creation: Frame and Button
-------------------------------------------------------------------

local function CreateWonAuctionsFrame()
    local frame = CreateFrame("Frame", "GDKP_WonAuctionsFrame", UIParent)
    frame:SetSize(450, 300)
    frame:SetPoint("BOTTOMRIGHT", GDKPT.UI.AuctionWindow, "BOTTOMRIGHT", -10, 10)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    frame:SetClampedToScreen(true)
    frame:SetBackdropColor(0, 0, 0, 0.6)
    frame:SetFrameLevel(GDKPT.UI.AuctionWindow:GetFrameLevel() + 2)
    frame:Hide()

    -- Enable dragging
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnShow", function(self) GDKPT.Utils.BringToFront(self) end)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetText("My Won Auctions")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetFont("Fonts\\FRIZQT__.TTF", 14)

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetSize(35, 35)

    return frame
end

local function CreateWonAuctionsButton(parent, frameToToggle)
    local btn = CreateFrame("Button", "GDKP_WonAuctionsButton", parent, "UIPanelButtonTemplate")
    btn:SetSize(120, 22)
    btn:SetPoint("TOP", parent, "TOP", 195, -15)
    btn:SetText("Won Auctions")

    btn:SetScript("OnClick", function()
        if frameToToggle:IsVisible() then
            frameToToggle:Hide()
        else
            frameToToggle:Show()
        end
    end)

    return btn
end


-------------------------------------------------------------------
-- Scroll Frame and Content
-------------------------------------------------------------------

local function CreateScrollFrame(parent)
    local scrollFrame = CreateFrame("ScrollFrame", "GDKP_WonItemsScrollFrame", parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", -30, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 80)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(scrollFrame:GetWidth())
    scrollContent:SetHeight(1) -- will grow dynamically
    scrollFrame:SetScrollChild(scrollContent)

    return scrollFrame, scrollContent
end


-------------------------------------------------------------------
-- Summary Panel
-------------------------------------------------------------------

local function CreateSummaryPanel(parent)
    local panel = CreateFrame("Frame", "GDKP_WonItemsSummaryPanel", parent)
    panel:SetSize(450, 80)
    panel:SetPoint("BOTTOM", 0, 10)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    panel:SetBackdropColor(0, 0, 0, 0.4)

    local function createLabel(text, xOffset, yOffset)
        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetText(text)
        label:SetPoint("CENTER", panel, "CENTER", xOffset, yOffset)
        label:SetFont("Fonts\\FRIZQT__.TTF", 12)
        return label
    end

    local function createValue(xOffset, yOffset, default)
        local val = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        val:SetText(default or "0")
        val:SetPoint("CENTER", panel, "CENTER", xOffset, yOffset)
        val:SetFont("Fonts\\FRIZQT__.TTF", 12)
        return val
    end

    panel.amountItemsValue = createValue(-90, 20, 0)
    createLabel("Amount of Items:", -170, 20)

    panel.averageCostValue = createValue(-80, -20, GDKPT.Utils.FormatMoney(0))
    createLabel("Average Cost:", -180, -20)

    panel.totalCostValue = createValue(170, 20, GDKPT.Utils.FormatMoney(0))
    createLabel("Total Cost:", 50, 20)

    panel.goldFromRaidValue = createValue(170, -20, GDKPT.Utils.FormatMoney(0))
    createLabel("Gold from Raid:", 50, -20)

    return panel
end


-------------------------------------------------------------------
-- Won Item Entry Frame Pool
-------------------------------------------------------------------

local wonItemEntryPool = {}
local nextEntryIndex = 1

local function CreateWonItemEntry(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(32)
    frame:EnableMouse(true)

    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", frame, "LEFT", 40, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.icon = icon

    -- Name text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetJustifyH("LEFT")
    frame.nameText = nameText

    -- Bid text
    local bidText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bidText:SetPoint("RIGHT", -5, 0)
    bidText:SetJustifyH("RIGHT")
    frame.bidText = bidText

    -- Adjustment overlay
    local adjOverlay = CreateFrame("Frame", nil, frame)
    adjOverlay:SetPoint("TOPLEFT", frame, "TOPLEFT", 34, -2)
    adjOverlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 2)
    adjOverlay:SetFrameLevel(frame:GetFrameLevel() + 1)
    adjOverlay:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    adjOverlay:SetBackdropColor(0.8, 0.4, 0, 0.7)
    adjOverlay:SetBackdropBorderColor(1, 0.5, 0, 1)
    adjOverlay:Hide()
    frame.adjustmentOverlay = adjOverlay

    local adjText = adjOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    adjText:SetPoint("CENTER")
    adjText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    frame.adjustmentText = adjText

    -- Tooltip
    frame:SetScript("OnEnter", function(self)
        if self.isAdjustment then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Manual Adjustment", 1, 1, 1)
            local typeText = (self.bidAmount > 0) and "Added to your debt" or "Reduced from your debt"
            GameTooltip:AddLine(string.format("%s: %s", typeText, GDKPT.Utils.FormatMoney(math.abs(self.bidAmount) * 10000)))
            GameTooltip:Show()
        elseif self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            if self.amountPaid and self.amountPaid > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(string.format("Paid: %s", GDKPT.Utils.FormatMoney(self.amountPaid * 10000)), 0, 1, 0)
                if self.amountOwed and self.amountOwed > 0 then
                    GameTooltip:AddLine(string.format("Still Owed: %s", GDKPT.Utils.FormatMoney(self.amountOwed * 10000)), 1, 0.5, 0)
                end
            end
            GameTooltip:Show()
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.itemName, 1, 1, 1)
            GameTooltip:AddLine("Won for: " .. self.bidAmount .. " Gold")
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return frame
end


-------------------------------------------------------------------
-- Populate individual entry
-------------------------------------------------------------------

local function PopulateWonEntry(entry, item)
    entry.isAdjustment = item.isAdjustment or false
    entry.itemName = item.name or "Manual Adjustment"
    entry.itemLink = item.link
    entry.bidAmount = item.bid or 0
    entry.amountPaid = item.amountPaid or 0
    entry.amountOwed = (item.bid or 0) - (item.amountPaid or 0)

    if entry.isAdjustment then
        local color = (item.bid > 0) and "|cffff0000" or "|cff00ff00"
        entry.nameText:SetText(color .. "Manual Adjustment|r")
        entry.bidText:SetText(color .. GDKPT.Utils.FormatMoney(item.bid * 10000) .. "|r")
        entry.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
        entry.adjustmentOverlay:Hide()
    else
        local paymentIndicator = ""
        if entry.amountPaid >= entry.bidAmount then
            paymentIndicator = " |cff00ff00[PAID]|r"
        elseif entry.amountPaid > 0 then
            paymentIndicator = string.format(" |cffffaa00[%dg paid]|r", entry.amountPaid)
        end
        entry.nameText:SetText(item.name .. paymentIndicator)

        if entry.amountOwed > 0 then
            entry.bidText:SetText("|cffff3333-" .. GDKPT.Utils.FormatMoney(entry.amountOwed * 10000) .. "|r")
        else
            entry.bidText:SetText("|cff00ff00" .. GDKPT.Utils.FormatMoney(entry.bidAmount * 10000) .. "|r")
        end

        local texture = nil
        if item.link then
            local _, _, _, _, _, _, _, _, _, newTexture = GetItemInfo(item.link)
            texture = newTexture
        end
        entry.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

        if item.wasAdjusted then
            entry.adjustmentOverlay:Show()
            local adjAmount = item.adjustmentAmount or 0
            local adjColor = (adjAmount > 0) and "|cffff0000" or "|cff00ff00"
            entry.adjustmentText:SetText(string.format("ADJUSTED: %s%dg|r", adjColor, math.abs(adjAmount)))
        else
            entry.adjustmentOverlay:Hide()
        end
    end
end


-------------------------------------------------------------------
-- Update Won Items List
-------------------------------------------------------------------

function GDKPT.MyWonAuctions.UpdateWonItemsList(scrollFrame, scrollContent)
    for _, entry in ipairs(wonItemEntryPool) do entry:Hide() end
    nextEntryIndex = 1

    if not scrollContent then
        print(GDKPT.Core.errorprint .. "ScrollContent for My Won Items is missing.")
        return
    end

    local totalHeight = 0
    for i, item in ipairs(GDKPT.Core.PlayerWonItems) do
        local entry = wonItemEntryPool[nextEntryIndex]
        if not entry then
            entry = CreateWonItemEntry(scrollContent)
            wonItemEntryPool[nextEntryIndex] = entry
        end
        PopulateWonEntry(entry, item)

        local prevEntry = wonItemEntryPool[nextEntryIndex - 1]
        if prevEntry then
            entry:SetPoint("TOP", prevEntry, "BOTTOM", 0, -2)
        else
            entry:SetPoint("TOP", scrollContent, "TOP", 0, -2)
        end

        entry:SetWidth(scrollContent:GetWidth())
        entry:Show()
        totalHeight = totalHeight + entry:GetHeight() + 2
        nextEntryIndex = nextEntryIndex + 1
    end

    scrollContent:SetHeight(math.max(scrollFrame:GetHeight() - 10, totalHeight + 2))
    if scrollFrame.ScrollBar then scrollFrame.ScrollBar:SetValue(0) end
end


-------------------------------------------------------------------
-- Update Summary Panel
-------------------------------------------------------------------



local function UpdateSummaryPanel(panel)
    local totalPaid, totalOwed, itemsWon, adjustmentSum = 0, 0, 0, 0
    for _, item in ipairs(GDKPT.Core.PlayerWonItems) do
        if item.isAdjustment then
            adjustmentSum = adjustmentSum + (item.bid or 0)
        else
            if not item.wasAdjusted then
                local itemCost = item.bid or 0
                local amountPaid = item.amountPaid or 0
                totalPaid = totalPaid + amountPaid
                totalOwed = totalOwed + (itemCost - amountPaid)
                itemsWon = itemsWon + 1
            end
        end
    end

    local totalCost = totalPaid + totalOwed
    panel.totalCostValue:SetText(GDKPT.Utils.FormatMoney(totalCost * 10000))
    panel.amountItemsValue:SetText(itemsWon)
    panel.averageCostValue:SetText(GDKPT.Utils.FormatMoney(itemsWon > 0 and math.floor(totalCost * 10000 / itemsWon + 0.5) or 0))

    local playerCutGold = (GDKPT.Core.PlayerCut or 0) / 10000
    local goldLeft = playerCutGold - (totalOwed + adjustmentSum)
    local color = goldLeft > 0 and "|cff33ff33" or (goldLeft < 0 and "|cffff3333" or "|cffcccccc")
    panel.goldFromRaidValue:SetText(color .. GDKPT.Utils.FormatMoney(math.floor(goldLeft * 10000 + 0.5)) .. "|r")
end

-------------------------------------------------------------------
-- Update Won Items Display (list + summary)
-------------------------------------------------------------------

function GDKPT.MyWonAuctions.UpdateWonItemsDisplay(wonAuctionsFrame)
    if wonAuctionsFrame and wonAuctionsFrame.ScrollFrame then
        local scrollFrame = wonAuctionsFrame.ScrollFrame
        local scrollContent = scrollFrame:GetScrollChild()

        if scrollContent then
            GDKPT.MyWonAuctions.UpdateWonItemsList(scrollFrame, scrollContent)
            UpdateSummaryPanel(wonAuctionsFrame.SummaryPanel)
        else
            print(GDKPT.Core.errorprint .. "WonAuctionsFrame UI structure incomplete.")
        end
    end
end


-------------------------------------------------------------------
-- Initialize Won Auctions Module and expose frames
-------------------------------------------------------------------


local wonAuctionsFrame = CreateWonAuctionsFrame()
local wonAuctionsButton = CreateWonAuctionsButton(GDKPT.UI.AuctionWindow, wonAuctionsFrame)
local scrollFrame, scrollContent = CreateScrollFrame(wonAuctionsFrame)
local summaryPanel = CreateSummaryPanel(wonAuctionsFrame)

wonAuctionsFrame.ScrollFrame = scrollFrame
wonAuctionsFrame.SummaryPanel = summaryPanel

GDKPT.MyWonAuctions.WonAuctionsFrame = wonAuctionsFrame
GDKPT.MyWonAuctions.WonAuctionsButton = wonAuctionsButton
