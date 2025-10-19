GDKPT.AuctionHistory = GDKPT.AuctionHistory or {}

local HistoryEntryPool = {}
local HistoryEntryID = 1

-- Function to create a single entry for the history list
local function CreateHistoryEntry(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetHeight(32)
	frame:EnableMouse(true)
	
	-- Icon
	local icon = frame:CreateTexture(nil, "ARTWORK")
	icon:SetSize(28, 28)
	icon:SetPoint("LEFT", 5, 0)
	frame.icon = icon

	-- Item Name (Text)
	local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
	nameText:SetJustifyH("LEFT")
	frame.nameText = nameText

	-- Winner Name (Text)
	local winnerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	winnerText:SetPoint("RIGHT", -150, 0)
	winnerText:SetJustifyH("RIGHT")
	frame.winnerText = winnerText

	-- Bid Amount (Text)
	local bidText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	bidText:SetPoint("RIGHT", -5, 0)
	bidText:SetJustifyH("RIGHT")
	frame.bidText = bidText

	-- Mouseover for tooltip
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.itemLink then
			GameTooltip:SetHyperlink(self.itemLink)
		else
			GameTooltip:SetText("Winner: " .. self.winner, 1, 1, 1)
			GameTooltip:AddLine("Won for: " .. self.bidAmount .. " Gold")
			GameTooltip:Show()
		end
	end)
	frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

	return frame
end


function GDKPT.AuctionHistory.UpdateGeneralHistoryList()
	local HistoryFrame = GDKPT.UI.GeneralHistoryFrame
	local ScrollFrame = HistoryFrame.ScrollFrame
	local ScrollContent = HistoryFrame.ScrollFrame:GetScrollChild()

	if not ScrollContent then return end

	-- Get the filter text from the UI (default to empty string)
	local filter = (HistoryFrame.FilterText or ""):lower()

	-- Reset the pool
	for i, entry in ipairs(HistoryEntryPool) do
		entry:Hide()
	end
	HistoryEntryID = 1
	
	local historyTable = GDKPT.Core.GeneralHistory
	local totalHeight = 0
	local count = #historyTable

	-- Loop backwards to show newest items on top
	for i = count, 1, -1 do
		local item = historyTable[i]
		
		-- Get Item Info early so we can use the itemName for filtering
		local itemName, _, _, _, _, _, _, _, _, texture = GetItemInfo(item.link)
		itemName = itemName or "Unknown Item"
		local itemNameLower = itemName:lower() -- Convert item name to lowercase for filtering

		-- *** FILTER LOGIC ***
		local winnerLower = (item.winner or ""):lower()
		
		-- Modification: Check if filter is empty OR if filter matches winner name OR if filter matches item name
		local shouldShow = filter == "" or winnerLower:match(filter) or itemNameLower:match(filter)
		
		if shouldShow then
			-- This block contains all the logic for displaying the item
			
			local entry = HistoryEntryPool[HistoryEntryID]
			if not entry then
				entry = CreateHistoryEntry(ScrollContent)
				HistoryEntryPool[HistoryEntryID] = entry
			end
			HistoryEntryID = HistoryEntryID + 1

			-- Set data
			entry.itemLink = item.link
			entry.bidAmount = item.bid
			entry.winner = item.winner
			
			entry.nameText:SetText(itemName)
			entry.winnerText:SetText(item.winner)
			entry.bidText:SetText(GDKPT.Utils.FormatMoney(item.bid * 10000))
			entry.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

			-- Position and Show
			local prevEntry = HistoryEntryPool[HistoryEntryID - 2]
			if not prevEntry then
				entry:SetPoint("TOP", ScrollContent, "TOP", 0, -2)
			else
				entry:SetPoint("TOP", prevEntry, "BOTTOM", 0, -2)
			end

			entry:SetWidth(ScrollContent:GetWidth())
			entry:Show()
			totalHeight = totalHeight + entry:GetHeight() + 2
		end
		-- *** END FILTER LOGIC ***
	end

	-- Adjust ScrollContent height
	local contentHeight = math.max(ScrollFrame:GetHeight(), totalHeight + 2)
	ScrollContent:SetHeight(contentHeight)
	
	if ScrollFrame.ScrollBar then
		ScrollFrame.ScrollBar:SetValue(0)
	end
end
