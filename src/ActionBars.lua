local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Action button cast animation
-------------------------------------------------------------------------------
-- While a spell is cast or channelled, its action button plays a fill
-- animation over the icon. Nothing in the game's settings or CVars turns
-- that off: each button's PlaySpellCastAnim runs whenever the cast events
-- fire. This hooks that method on every action bar button and, when the
-- option is off, hides the animation frame the moment it's shown. The
-- frame's own OnHide puts the cooldown swipe back, so the button is
-- otherwise untouched. The hooks are permanent (that's how hooksecurefunc
-- works) and read the option live, so toggling needs no reload.

local BUTTONS_PER_BAR = 12

-- Blizzard keeps the list of bar button prefixes; the literal list is the
-- same set, for a build where the util table is missing
local BAR_PREFIXES = ActionButtonUtil and ActionButtonUtil.ActionBarButtonNames or {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarLeftButton",
    "MultiBarRightButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
}

local hooked = {}

local function EachButton(fn)
    for _, prefix in ipairs(BAR_PREFIXES) do
        for i = 1, BUTTONS_PER_BAR do
            local button = _G[prefix .. i]
            if button then
                fn(button)
            end
        end
    end
end

local function OnPlaySpellCastAnim(button)
    if ns.opts and not ns.opts.castAnim and button.SpellCastAnimFrame then
        button.SpellCastAnimFrame:Hide()
    end
end

local function HookButtons()
    EachButton(function(button)
        if not hooked[button] and button.PlaySpellCastAnim then
            hooksecurefunc(button, "PlaySpellCastAnim", OnPlaySpellCastAnim)
            hooked[button] = true
        end
    end)
end

-- Called when the option changes: an animation already playing is hidden
-- straight away rather than at the next cast
function ns.ApplyCastAnim()
    if ns.opts and not ns.opts.castAnim then
        EachButton(function(button)
            if button.SpellCastAnimFrame and button.SpellCastAnimFrame:IsShown() then
                button.SpellCastAnimFrame:Hide()
            end
        end)
    end
end

-- The bars exist once the UI is up; PLAYER_LOGIN is after every addon and
-- Blizzard frame has loaded
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", HookButtons)
