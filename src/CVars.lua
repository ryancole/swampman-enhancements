local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- CVar toggles
-------------------------------------------------------------------------------
-- On/off client settings the game keeps out of its menus. Each is an addon
-- option mirrored to a CVar: written at login and whenever the option
-- changes. A toggle with no default stays nil until it's first used, so
-- the CVar is left as the game has it and the checkbox shows the live
-- value.
--
-- Options.lua draws a section with a checkbox per toggle and Core.lua
-- gives each a slash command; both go through ns.SetCVarToggle.

ns.cvarToggles = {
    navigation = {
        cvar = "showInGameNavigation",
        default = true,
        section = "Navigation",
        command = "nav",
        label = "Show the in-game navigation pin",
        note = "The floating marker the game draws over your tracked quest objective, "
            .. "with the distance to it. WoW Forever hides this setting in its own options "
            .. "menu; this toggles the client's showInGameNavigation CVar.",
    },
    sharpen = {
        cvar = "ResampleAlwaysSharpen",
        section = "Graphics",
        command = "sharpen",
        label = "Always sharpen",
        note = "Applies the Resample Sharpness filter from the Graphics settings even when "
            .. "the render scale is 100% and nothing is being upscaled. Toggles the client's "
            .. "ResampleAlwaysSharpen CVar, which has no entry in the settings menu.",
    },
}

-- Core.lua's InitDB runs at ADDON_LOADED, after every file has loaded, so
-- the toggles' defaults can be registered here
for key, toggle in pairs(ns.cvarToggles) do
    if toggle.default ~= nil then
        ns.optionDefaults[key] = toggle.default
    end
end

-- True when this build of the client knows the CVar at all
function ns.HasCVarToggle(key)
    return C_CVar.GetCVar(ns.cvarToggles[key].cvar) ~= nil
end

-- The effective state: the option if it's been set, otherwise what the
-- client has right now
function ns.GetCVarToggle(key)
    if ns.opts and ns.opts[key] ~= nil then
        return ns.opts[key]
    end
    return C_CVar.GetCVarBool(ns.cvarToggles[key].cvar) or false
end

local function Apply(key)
    if ns.opts and ns.opts[key] ~= nil and ns.HasCVarToggle(key) then
        C_CVar.SetCVar(ns.cvarToggles[key].cvar, ns.opts[key] and "1" or "0")
    end
end

function ns.SetCVarToggle(key, value)
    ns.opts[key] = value and true or false
    Apply(key)
end

-- CVars are settled by PLAYER_LOGIN; ADDON_LOADED is too early to rely on
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    for key in pairs(ns.cvarToggles) do
        Apply(key)
    end
end)
