local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Max camera distance
-------------------------------------------------------------------------------
-- cameraDistanceMaxZoomFactor scales how far the camera can zoom out. WoW
-- Forever's own Controls settings offer it as a slider that stops at 2.0,
-- but the client accepts more: the CVar is clamped inside the client, not
-- by the settings menu. This exposes it with a wider slider and a box to
-- type an exact value, and reapplies the chosen value at login.
--
-- The option is nil until the slider or box is used, so the CVar is left
-- alone for anyone who never touches it.

local CVAR = "cameraDistanceMaxZoomFactor"
local SLIDER_MIN = 1.0
local SLIDER_MAX_CAP = 3.4 -- the vanilla-era maximum; the probe below may lower it

ns.cameraZoomMin = SLIDER_MIN
ns.cameraZoomMax = SLIDER_MAX_CAP

-- True when this build of the client knows the CVar at all
function ns.HasCameraCVar()
    return C_CVar.GetCVar(CVAR) ~= nil
end

function ns.GetCameraZoom()
    return tonumber(C_CVar.GetCVar(CVAR))
end

-- Sets the CVar and remembers the value. The client clamps to its own
-- limits, so the value that actually took is returned.
function ns.SetCameraZoom(value)
    value = tonumber(value)
    if not value or not ns.opts or not ns.HasCameraCVar() then
        return ns.GetCameraZoom()
    end
    C_CVar.SetCVar(CVAR, tostring(value))
    local actual = ns.GetCameraZoom()
    ns.opts.cameraZoom = actual
    return actual
end

-- The client clamps the CVar to a limit that isn't exposed anywhere, so
-- find it by asking for far too much and reading back what stuck. The
-- current value is put back straight after; the camera doesn't move.
local function ProbeMax()
    local current = C_CVar.GetCVar(CVAR)
    C_CVar.SetCVar(CVAR, "100")
    local max = ns.GetCameraZoom() or SLIDER_MAX_CAP
    C_CVar.SetCVar(CVAR, current)
    ns.cameraZoomMax = math.max(SLIDER_MIN, math.min(max, SLIDER_MAX_CAP))
end

-- CVars are settled by PLAYER_LOGIN; ADDON_LOADED is too early to rely on
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    if not ns.HasCameraCVar() then
        return
    end
    ProbeMax()
    if ns.opts and ns.opts.cameraZoom then
        ns.SetCameraZoom(ns.opts.cameraZoom)
    end
end)
