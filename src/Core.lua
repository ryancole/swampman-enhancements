local ADDON_NAME, ns = ...

local opts -- SwampmanEnhancementsDB.options (account-wide)

-------------------------------------------------------------------------------
-- SavedVariables
-------------------------------------------------------------------------------
-- Everything is account-wide: none of these tweaks vary between characters.
--
-- SwampmanEnhancementsDB = {
--   version = 1,
--   options = { ... },
-- }

ns.optionDefaults = {
    enabled = true,    -- quest automation master switch; off, no NPC clicks are taken
    accept = true,     -- pick up quests NPCs offer
    turnIn = true,     -- hand in finished quests
    castAnim = true,   -- show the cast animation on action buttons (see ActionBars.lua)
    totemBarRight = false, -- lay the totem bar's buttons out from its right edge (see TotemBar.lua)
    -- CVars.lua adds a default for each of its toggles that has one (the
    -- navigation pin); the rest, and cameraZoom from Camera.lua, are absent
    -- until set, so those CVars are left alone until they're first touched
}

local function InitDB()
    SwampmanEnhancementsDB = SwampmanEnhancementsDB or { version = 1 }
    SwampmanEnhancementsDB.options = SwampmanEnhancementsDB.options or {}
    opts = SwampmanEnhancementsDB.options
    for k, v in next, ns.optionDefaults do
        if opts[k] == nil then
            opts[k] = v
        end
    end
    ns.opts = opts -- shared with the other files
end

-------------------------------------------------------------------------------
-- Quest automation
-------------------------------------------------------------------------------
-- The client walks a quest NPC conversation through a chain of events, and
-- each handler below takes the one step that a click in the default quest
-- frame would:
--
--   GOSSIP_SHOW / QUEST_GREETING  the NPC's list of quests: pick one
--   QUEST_DETAIL                  a quest offer: accept it
--   QUEST_ACCEPT_CONFIRM          a party member started an escort quest:
--                                 confirm joining it
--   QUEST_PROGRESS                a hand-in check: continue if it's done
--   QUEST_COMPLETE                the reward page: take it, unless there's
--                                 a choice to make
--
-- Picking a quest from the list makes the server send the next event, so
-- one quest is handled per list event; when the frame closes the NPC's
-- list comes back and the next quest is picked up. Finished quests are
-- handed in before new ones are taken.
--
-- Holding Shift while talking to an NPC pauses all of this, so a quest can
-- be read, or left alone, without turning the automation off.

local function Active()
    return opts.enabled and not IsShiftKeyDown()
end

-- GOSSIP_SHOW: NPCs with a gossip menu list their quests through
-- C_GossipInfo, keyed by quest ID
local function OnGossipShow()
    if not Active() or not C_GossipInfo then
        return
    end
    if opts.turnIn then
        for _, quest in ipairs(C_GossipInfo.GetActiveQuests()) do
            if quest.isComplete then
                C_GossipInfo.SelectActiveQuest(quest.questID)
                return
            end
        end
    end
    if opts.accept then
        local quest = C_GossipInfo.GetAvailableQuests()[1]
        if quest then
            C_GossipInfo.SelectAvailableQuest(quest.questID)
        end
    end
end

-- QUEST_GREETING: plain quest givers with no gossip menu list their quests
-- by index through the older greeting API
local function OnQuestGreeting()
    if not Active() then
        return
    end
    if opts.turnIn then
        for i = 1, GetNumActiveQuests() do
            local _, isComplete = GetActiveTitle(i)
            if isComplete then
                SelectActiveQuest(i)
                return
            end
        end
    end
    if opts.accept and GetNumAvailableQuests() > 0 then
        SelectAvailableQuest(1)
    end
end

-- QUEST_DETAIL: the offer page. Mirrors the default frame's Accept button:
-- a quest the server has already put in the log only needs acknowledging.
-- Quests that flag you for PvP are left for a deliberate click.
local function OnQuestDetail()
    if not Active() or not opts.accept then
        return
    end
    if QuestFlagsPVP and QuestFlagsPVP() then
        return
    end
    if QuestGetAutoAccept and QuestGetAutoAccept() then
        AcknowledgeAutoAcceptQuest()
    else
        AcceptQuest()
    end
end

-- QUEST_ACCEPT_CONFIRM: a party member has started an escort quest and the
-- client asks whether to join in. There is no offer page for these, just a
-- yes/no popup, so this is the accept step for that kind of quest.
local function OnQuestAcceptConfirm()
    if not Active() or not opts.accept then
        return
    end
    ConfirmAcceptQuest()
end

-- QUEST_PROGRESS: the "are you done yet" page. Continue only when the
-- objectives are met; otherwise the page stays up, as it would by hand.
local function OnQuestProgress()
    if not Active() or not opts.turnIn then
        return
    end
    if IsQuestCompletable() then
        CompleteQuest()
    end
end

-- QUEST_COMPLETE: the reward page. With nothing to choose the quest is
-- handed in; a single offered item isn't a choice either. Two or more
-- choices are left for the player to pick and turn in by hand.
local function OnQuestComplete()
    if not Active() or not opts.turnIn then
        return
    end
    local choices = GetNumQuestChoices()
    if choices == 0 then
        GetQuestReward(0)
    elseif choices == 1 then
        GetQuestReward(1)
    end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("QUEST_GREETING")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
frame:RegisterEvent("QUEST_PROGRESS")
frame:RegisterEvent("QUEST_COMPLETE")

local handlers = {
    GOSSIP_SHOW = OnGossipShow,
    QUEST_GREETING = OnQuestGreeting,
    QUEST_DETAIL = OnQuestDetail,
    QUEST_ACCEPT_CONFIRM = OnQuestAcceptConfirm,
    QUEST_PROGRESS = OnQuestProgress,
    QUEST_COMPLETE = OnQuestComplete,
}

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            InitDB()
            ns.SetupOptions()
            self:UnregisterEvent("ADDON_LOADED")
        end
        return
    end
    if opts then
        handlers[event]()
    end
end)

-------------------------------------------------------------------------------
-- Slash commands
-------------------------------------------------------------------------------

local function Print(msg)
    print("|cff33ff99Swampman:|r " .. msg)
end

local function OnOff(flag)
    return flag and "|cff00ff00on|r" or "|cffff0000off|r"
end

local function PrintStatus()
    Print(("quest automation %s (accept %s, turn in %s), navigation pin %s, always sharpen %s, camera zoom %s, cast animation %s, totem bar aligned %s. Hold Shift to pause quests."):format(
        opts.enabled and "enabled" or "disabled",
        OnOff(opts.accept), OnOff(opts.turnIn),
        OnOff(ns.GetCVarToggle("navigation")), OnOff(ns.GetCVarToggle("sharpen")),
        tostring(ns.GetCameraZoom() or "n/a"), OnOff(opts.castAnim),
        opts.totemBarRight and "right" or "left"))
end

-- The CVar toggle whose slash command this is, if any
local function ToggleForCommand(cmd)
    for key, toggle in pairs(ns.cvarToggles) do
        if toggle.command == cmd then
            return key
        end
    end
end

-- Parses "on"/"off" (or nothing, meaning toggle) into the new value
local function Parse(word, current)
    if word == "on" then
        return true
    elseif word == "off" then
        return false
    end
    return not current
end

SLASH_SWAMPMAN1 = "/sme"
SLASH_SWAMPMAN2 = "/swampman"
SlashCmdList.SWAMPMAN = function(msg)
    local cmd, arg = strsplit(" ", strlower(strtrim(msg or "")), 2)
    if cmd == "on" or cmd == "off" then
        opts.enabled = cmd == "on"
        PrintStatus()
    elseif cmd == "toggle" then
        opts.enabled = not opts.enabled
        PrintStatus()
    elseif cmd == "accept" then
        opts.accept = Parse(arg, opts.accept)
        PrintStatus()
    elseif cmd == "turnin" then
        opts.turnIn = Parse(arg, opts.turnIn)
        PrintStatus()
    elseif ToggleForCommand(cmd) then
        local key = ToggleForCommand(cmd)
        ns.SetCVarToggle(key, Parse(arg, ns.GetCVarToggle(key)))
        PrintStatus()
    elseif cmd == "castanim" then
        opts.castAnim = Parse(arg, opts.castAnim)
        ns.ApplyCastAnim()
        PrintStatus()
    elseif cmd == "totembar" then
        if arg == "left" or arg == "right" then
            opts.totemBarRight = arg == "right"
        elseif arg and arg ~= "" then
            Print("totembar takes left or right")
        else
            opts.totemBarRight = not opts.totemBarRight
        end
        ns.ApplyTotemBarAlign()
        PrintStatus()
    elseif cmd == "zoom" then
        if tonumber(arg) then
            ns.SetCameraZoom(arg)
        elseif arg and arg ~= "" then
            Print("zoom takes a number, e.g. /sme zoom 2.6")
        end
        PrintStatus()
    elseif cmd == "" or cmd == "status" then
        PrintStatus()
    elseif cmd == "options" then
        ns.OpenOptions()
    else
        Print("commands:")
        print("  /sme - show what's on")
        print("  /sme on | off | toggle - quest automation as a whole")
        print("  /sme accept [on|off] - picking up quests")
        print("  /sme turnin [on|off] - handing in quests")
        print("  /sme nav [on|off] - the in-game navigation pin")
        print("  /sme zoom [value] - max camera distance (e.g. 2.6)")
        print("  /sme sharpen [on|off] - always apply resample sharpening")
        print("  /sme castanim [on|off] - the cast animation on action buttons")
        print("  /sme totembar [left|right] - which edge of its box the totem bar fills from")
        print("  /sme options - open the settings panel")
        print("  Hold Shift while talking to an NPC to handle a quest by hand.")
    end
end
