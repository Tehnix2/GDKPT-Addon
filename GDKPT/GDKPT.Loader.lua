GDKPT = GDKPT or {}

local MemberLoaderFrame = CreateFrame("Frame", "MemberLoaderFrame")

-------------------------------------------------------------------
-- When addon is loaded initialize favority and history tables
-------------------------------------------------------------------

local function GDKPMemberLoaderFrame_OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "GDKPT" then
            if GDKPT.Core and GDKPT.Core.InitHistory then
                GDKPT.Core.InitHistory()
            end

            if GDKPT.Core and GDKPT.Core.InitPlayerFavorites then
                GDKPT.Core.InitPlayerFavorites()
            end

            if GDKPT.AuctionFavorites and GDKPT.AuctionFavorites.UpdateAllRowsVisuals then
                GDKPT.AuctionFavorites.UpdateAllRowsVisuals()
            end

            if GDKPT.Core and GDKPT.Core.InitPlayerSettings then
                GDKPT.Core.InitPlayerSettings()
            end

            if GDKPT.Core and GDKPT.Core.LoadToggleButtonPosition then
                GDKPT.Core.LoadToggleButtonPosition()
            end

        end
    elseif event == "PLAYER_LOGOUT" or event == "ADDON_SAVED_VARIABLES" then 
        if GDKPT.Core and GDKPT.Core.SaveCurrentRaidSummary then 
            GDKPT.Core.SaveCurrentRaidSummary()
        end
    end
end

MemberLoaderFrame:RegisterEvent("ADDON_LOADED")
MemberLoaderFrame:RegisterEvent("PLAYER_LOGOUT")
MemberLoaderFrame:RegisterEvent("ADDON_SAVED_VARIABLES")

MemberLoaderFrame:SetScript("OnEvent", GDKPMemberLoaderFrame_OnEvent)



GDKPT.MemberLoaderFrame = MemberLoaderFrame
