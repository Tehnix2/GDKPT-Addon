GDKPT = GDKPT or {}

local MemberLoaderFrame = CreateFrame("Frame", "MemberLoaderFrame")

-------------------------------------------------------------------
-- Loader frame to reload saved variables
-------------------------------------------------------------------

local function GDKPMemberLoaderFrame_OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "GDKPT" then
            if GDKPT.Core and GDKPT.Core.InitData then  
                GDKPT.Core.InitData()
                GDKPT.Core.LoadToggleButtonPosition()
            end
        end
    end
end

MemberLoaderFrame:RegisterEvent("ADDON_LOADED")
MemberLoaderFrame:RegisterEvent("PLAYER_LOGOUT")
MemberLoaderFrame:RegisterEvent("ADDON_SAVED_VARIABLES")

MemberLoaderFrame:SetScript("OnEvent", GDKPMemberLoaderFrame_OnEvent)



GDKPT.MemberLoaderFrame = MemberLoaderFrame
