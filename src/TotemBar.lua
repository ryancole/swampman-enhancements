local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Totem bar alignment
-------------------------------------------------------------------------------
-- The shaman totem bar (MultiCastActionBarFrame) is a fixed-width box that
-- Edit Mode positions as a whole, and Blizzard lays its buttons out from
-- the box's left edge: the Call of the Elements button, then one slot per
-- totem element known, then Totemic Recall. With fewer than four elements
-- known the right end of the box is empty, so a bar placed against
-- something on its right sits with a gap. This option lays the buttons out
-- from the right edge instead.
--
-- Every button after the first is chained to the one before it, so only
-- the summon button and the first slot (plus the page frames that hold the
-- spell icons over the slots) need moving. Blizzard resets those anchors
-- in MultiCastActionBarFrame_Update, so that is hooked and the layout
-- reapplied afterwards. The summon button is a secure frame, so nothing is
-- moved in combat; a layout due then is applied when combat ends.

local PAD = 3 -- Blizzard's gap between the box edge and the outermost button
local GAP = 8 -- and between neighbouring buttons

local pending = false -- a layout was wanted in combat

-- True when this build of the client has the totem bar at all
function ns.HasTotemBar()
    return MultiCastActionBarFrame ~= nil
end

-- Width of everything shown on the bar, and the summon button's share of
-- it (its width plus the gap after it, or 0 when it isn't shown)
local function ContentWidth(bar)
    local slots = bar.numActiveSlots
    local width = slots * MultiCastSlotButton1:GetWidth() + (slots - 1) * GAP
    local summonWidth = 0
    if MultiCastSummonSpellButton:IsShown() then
        summonWidth = MultiCastSummonSpellButton:GetWidth() + GAP
    end
    if MultiCastRecallSpellButton:IsShown() then
        width = width + GAP + MultiCastRecallSpellButton:GetWidth()
    end
    return summonWidth + width, summonWidth
end

-- Anchors the summon button and the first slot for the chosen alignment.
-- Left is what Blizzard's own update sets, so switching the option off
-- puts the bar back exactly as it was.
local function Layout()
    local bar = MultiCastActionBarFrame
    if not bar or not ns.opts or (bar.numActiveSlots or 0) == 0 then
        return
    end
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false

    local content, summonWidth = ContentWidth(bar)
    local summonX
    if ns.opts.totemBarRight then
        summonX = bar:GetWidth() - PAD - content
    else
        summonX = PAD
    end
    local slotX = summonX + summonWidth

    MultiCastSummonSpellButton:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", summonX, PAD)
    MultiCastSlotButton1:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", slotX, PAD)
    for i = 1, NUM_MULTI_CAST_PAGES or 3 do
        local page = _G["MultiCastActionPage" .. i]
        if page then
            page:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", slotX, PAD)
        end
    end
end

-- Called when the option changes
function ns.ApplyTotemBarAlign()
    Layout()
end

-- After Blizzard's update, which puts the buttons back on the left
local function OnBlizzardUpdate()
    if ns.opts and ns.opts.totemBarRight then
        Layout()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- The bar and its update exist once the UI is up
        if ns.HasTotemBar() and MultiCastActionBarFrame_Update then
            hooksecurefunc("MultiCastActionBarFrame_Update", OnBlizzardUpdate)
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "PLAYER_REGEN_ENABLED" and pending then
        Layout()
    end
end)
