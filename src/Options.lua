local ADDON_NAME, ns = ...

-- Canvas-style settings panel (Options -> AddOns -> Swampman
-- Enhancements): the account-wide option checkboxes, one section per
-- feature.

local function MakeCheckbox(parent, label, getter, setter)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
    end)
    check:SetScript("OnShow", function(self)
        self:SetChecked(getter())
    end)
    local text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    check.Text = text
    text:SetText(label)
    text:SetPoint("LEFT", check, "RIGHT", 5, 1)
    text:SetScript("OnMouseUp", function()
        check:Click()
    end)
    text:SetScript("OnEnter", function()
        check:LockHighlight()
    end)
    text:SetScript("OnLeave", function()
        check:UnlockHighlight()
    end)
    return check
end

local LEFT_MARGIN = 15

-- Section headers sit below whatever came before, but always at the panel's
-- left margin, so an indented note above doesn't push the next section over
local function MakeSectionHeader(parent, label, anchorTo, yOffset)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOP", anchorTo, "BOTTOM", 0, yOffset)
    header:SetPoint("LEFT", parent, "LEFT", LEFT_MARGIN, 0)
    header:SetText(label)
    return header
end

local function MakeNote(parent, text, anchorTo)
    local note = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 30, -2)
    note:SetWidth(520)
    note:SetJustifyH("LEFT")
    note:SetText(text)
    return note
end

-- A section for one of the CVar toggles in CVars.lua: header, checkbox, and
-- the note under it. The checkbox is greyed out, and the note says why,
-- when this build of the client doesn't have the CVar. Returns the note,
-- for the next section to anchor to.
local function MakeToggleSection(panel, anchorTo, key)
    local toggle = ns.cvarToggles[key]
    local header = MakeSectionHeader(panel, toggle.section, anchorTo, -16)
    local check = MakeCheckbox(panel, toggle.label,
        function() return ns.GetCVarToggle(key) end,
        function(v) ns.SetCVarToggle(key, v) end)
    check:SetPoint("TOPLEFT", header, "BOTTOMLEFT", -4, -6)

    local noteText = toggle.note
    if not ns.HasCVarToggle(key) then
        noteText = noteText .. "\n|cffff8000Not available: this build of the client has no such CVar.|r"
        check:Disable()
        check.Text:SetTextColor(0.5, 0.5, 0.5)
    end
    return MakeNote(panel, noteText, check)
end

-- "2.6" rather than "2.600000" or "2.60", but keeps a typed "2.55"
local function Trim(value)
    return tostring(tonumber(("%.2f"):format(value)))
end

-- The max camera distance slider with a box beside it for an exact value.
-- Both write through ns.SetCameraZoom and then show what the client kept,
-- since it clamps to a limit of its own. The slider's range isn't known
-- until Camera.lua has probed it at login, so it's set up on show. Returns
-- the note under the controls, for the next section to anchor to.
local function MakeCameraControls(panel, anchorTo)
    local slider = CreateFrame("Frame", nil, panel, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -4)
    slider:SetWidth(250)

    local box = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    box:SetSize(50, 20)
    box:SetPoint("LEFT", slider, "RIGHT", 12, 0)
    box:SetAutoFocus(false)
    box:SetMaxLetters(5)

    local note = MakeNote(panel, "", slider)

    local updating = false -- true while the controls are being set, not used

    local function ShowValue(value)
        if not value then
            return
        end
        updating = true
        slider:SetValue(math.max(ns.cameraZoomMin, math.min(value, ns.cameraZoomMax)))
        updating = false
        if not box:HasFocus() then
            box:SetText(Trim(value))
        end
    end

    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if not updating then
            ShowValue(ns.SetCameraZoom(value))
        end
    end, panel)

    box:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            ShowValue(ns.SetCameraZoom(value))
        else
            ShowValue(ns.GetCameraZoom())
        end
        self:ClearFocus()
    end)
    box:HookScript("OnEditFocusLost", function()
        ShowValue(ns.GetCameraZoom())
    end)

    slider:SetScript("OnShow", function(self)
        local available = ns.HasCameraCVar()
        local min, max = ns.cameraZoomMin, ns.cameraZoomMax
        local current = available and ns.GetCameraZoom() or min
        -- Init wants a formatter function per label; this wraps a fixed string
        local Label = MinimalSliderWithSteppersMixin.Label
        local labels = {
            [Label.Min] = CreateMinimalSliderFormatter(Label.Min, Trim(min)),
            [Label.Max] = CreateMinimalSliderFormatter(Label.Max, Trim(max)),
        }
        local steps = math.max(1, math.floor((max - min) / 0.1 + 0.5)) -- 0.1 per step
        updating = true
        self:Init(current, min, max, steps, labels)
        updating = false
        self:SetEnabled(available)
        box:SetEnabled(available)
        if available then
            box:SetText(Trim(current))
            note:SetText(("How far the camera can zoom out (game default %s). The game's own "
                .. "Controls settings stop this at 2.0; this client accepts up to %s. Type a "
                .. "value and press Enter for anything in between."):format(
                Trim(tonumber(C_CVar.GetCVarDefault("cameraDistanceMaxZoomFactor")) or 1),
                Trim(max)))
        else
            box:SetText("")
            note:SetText("|cffff8000Not available: this build of the client has no such CVar.|r")
        end
    end)

    return note
end

-- Called by Core.lua on ADDON_LOADED, after SavedVariables exist
function ns.SetupOptions()
    local opts = ns.opts

    local panel = CreateFrame("Frame")
    panel:Hide()

    local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    header:SetPoint("TOPLEFT", LEFT_MARGIN, -10)
    header:SetText(NORMAL_FONT_COLOR:WrapTextInColorCode("Swampman Enhancements"))

    -- Substituted by the packager at release; raw keyword means a dev copy
    local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    if not version or version:find("@") then
        version = "dev"
    end
    local versionText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    versionText:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
    versionText:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(("Version: %s"):format(version)))

    -- Quests
    local questHeader = MakeSectionHeader(panel, "Quests", versionText, -16)
    local previous = questHeader
    for _, def in ipairs({
        { "Enable auto accept", "accept" },
        { "Enable auto turn in", "turnIn" },
    }) do
        local label, key = def[1], def[2]
        local check = MakeCheckbox(panel, label,
            function() return opts[key] end,
            function(v) opts[key] = v end)
        if previous == questHeader then
            check:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", -4, -6)
        else
            check:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
        end
        previous = check
    end

    local questNote = MakeNote(panel,
        "Hold Shift while talking to an NPC to handle a quest by hand.\n"
        .. "Quests with a choice of rewards always wait for you to pick one.",
        previous)

    -- Navigation
    local navNote = MakeToggleSection(panel, questNote, "navigation")

    -- Camera
    local camHeader = MakeSectionHeader(panel, "Camera", navNote, -16)
    local camLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    camLabel:SetPoint("TOPLEFT", camHeader, "BOTTOMLEFT", 0, -8)
    camLabel:SetText("Max camera distance")
    local camNote = MakeCameraControls(panel, camLabel)

    -- Graphics
    local gfxNote = MakeToggleSection(panel, camNote, "sharpen")

    -- Action bars
    local barsHeader = MakeSectionHeader(panel, "Action bars", gfxNote, -16)
    local castAnimCheck = MakeCheckbox(panel, "Show the cast animation on buttons",
        function() return opts.castAnim end,
        function(v)
            opts.castAnim = v
            ns.ApplyCastAnim()
        end)
    castAnimCheck:SetPoint("TOPLEFT", barsHeader, "BOTTOMLEFT", -4, -6)
    local castAnimNote = MakeNote(panel,
        "The fill that sweeps over a button's icon while its spell is cast or channelled. "
        .. "The game has no setting for this; unticked, the addon hides it as it starts.",
        castAnimCheck)

    local totemCheck = MakeCheckbox(panel, "Align the totem bar's buttons to the right",
        function() return opts.totemBarRight end,
        function(v)
            opts.totemBarRight = v
            ns.ApplyTotemBarAlign()
        end)
    totemCheck:SetPoint("TOPLEFT", castAnimNote, "BOTTOMLEFT", -30, -8)
    local totemNoteText = "The shaman totem bar is a fixed-width box that Edit Mode moves as a whole, and "
        .. "its buttons fill it from the left, leaving a gap on the right until all four totem "
        .. "elements are known. Ticked, they fill it from the right edge instead. Takes effect "
        .. "out of combat."
    if not ns.HasTotemBar() then
        totemNoteText = totemNoteText .. "\n|cffff8000Not available: this build of the client has no totem bar.|r"
        totemCheck:Disable()
        totemCheck.Text:SetTextColor(0.5, 0.5, 0.5)
    end
    MakeNote(panel, totemNoteText, totemCheck)

    -- Required no-op handlers for canvas settings panels
    panel.OnCommit = function() end
    panel.OnDefault = function() end
    panel.OnRefresh = function() end

    local category = Settings.RegisterCanvasLayoutCategory(panel, "Swampman Enhancements")
    ns.settingsCategory = category
    Settings.RegisterAddOnCategory(category)
end

function ns.OpenOptions()
    if ns.settingsCategory then
        Settings.OpenToCategory(ns.settingsCategory:GetID())
    end
end
