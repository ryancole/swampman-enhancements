local ADDON_NAME, ns = ...

-- Canvas-style settings panel (Options -> AddOns -> Quest Accept): the two
-- account-wide option checkboxes.

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

-- Called by Core.lua on ADDON_LOADED, after SavedVariables exist
function ns.SetupOptions()
    local opts = QuestAcceptDB.options

    local panel = CreateFrame("Frame")
    panel:Hide()

    local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    header:SetPoint("TOPLEFT", 15, -10)
    header:SetText(NORMAL_FONT_COLOR:WrapTextInColorCode("Quest Accept"))

    -- Substituted by the packager at release; raw keyword means a dev copy
    local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    if not version or version:find("@") then
        version = "dev"
    end
    local versionText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    versionText:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
    versionText:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(("Version: %s"):format(version)))

    local defs = {
        { "Enable auto accept", "accept" },
        { "Enable auto turn in", "turnIn" },
    }
    local previous = versionText
    for _, def in ipairs(defs) do
        local label, key = def[1], def[2]
        local check = MakeCheckbox(panel, label,
            function() return opts[key] end,
            function(v) opts[key] = v end)
        if previous == versionText then
            check:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", -4, -10)
        else
            check:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
        end
        previous = check
    end

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    hint:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 4, -16)
    hint:SetJustifyH("LEFT")
    hint:SetText("Hold Shift while talking to an NPC to handle a quest by hand.\n"
        .. "Quests with a choice of rewards always wait for you to pick one.\n"
        .. "Slash commands: /qa on, /qa off, /qa accept, /qa turnin")

    -- Required no-op handlers for canvas settings panels
    panel.OnCommit = function() end
    panel.OnDefault = function() end
    panel.OnRefresh = function() end

    local category = Settings.RegisterCanvasLayoutCategory(panel, "Quest Accept")
    ns.settingsCategory = category
    Settings.RegisterAddOnCategory(category)
end

function ns.OpenOptions()
    if ns.settingsCategory then
        Settings.OpenToCategory(ns.settingsCategory:GetID())
    end
end
