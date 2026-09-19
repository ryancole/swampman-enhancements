local ADDON_NAME, ns = ...

local opts -- QuestAcceptDB.options (account-wide)

-------------------------------------------------------------------------------
-- SavedVariables
-------------------------------------------------------------------------------
-- Everything is account-wide: whether quests are picked up and handed in
-- automatically doesn't vary between characters.
--
-- QuestAcceptDB = {
--   version = 1,
--   options = { ... },
-- }

ns.optionDefaults = {
    enabled = true,  -- master switch; off, the addon does nothing
    accept = true,   -- pick up quests NPCs offer
    turnIn = true,   -- hand in finished quests
}

local function InitDB()
    QuestAcceptDB = QuestAcceptDB or { version = 1 }
    QuestAcceptDB.options = QuestAcceptDB.options or {}
    opts = QuestAcceptDB.options
    for k, v in next, ns.optionDefaults do
        if opts[k] == nil then
            opts[k] = v
        end
    end
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
-- be read, or left alone, without turning the addon off.

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
frame:RegisterEvent("QUEST_PROGRESS")
frame:RegisterEvent("QUEST_COMPLETE")

local handlers = {
    GOSSIP_SHOW = OnGossipShow,
    QUEST_GREETING = OnQuestGreeting,
    QUEST_DETAIL = OnQuestDetail,
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
    print("|cff33ff99Quest Accept:|r " .. msg)
end

local function OnOff(flag)
    return flag and "|cff00ff00on|r" or "|cffff0000off|r"
end

local function PrintStatus()
    Print(("%s (accept %s, turn in %s). Hold Shift to pause."):format(
        opts.enabled and "enabled" or "disabled",
        OnOff(opts.accept), OnOff(opts.turnIn)))
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

SLASH_QUESTACCEPT1 = "/qa"
SLASH_QUESTACCEPT2 = "/questaccept"
SlashCmdList.QUESTACCEPT = function(msg)
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
    elseif cmd == "" or cmd == "status" then
        PrintStatus()
    elseif cmd == "options" then
        ns.OpenOptions()
    else
        Print("commands:")
        print("  /qa - show what's on")
        print("  /qa on | off | toggle - the whole addon")
        print("  /qa accept [on|off] - picking up quests")
        print("  /qa turnin [on|off] - handing in quests")
        print("  /qa options - open the settings panel")
        print("  Hold Shift while talking to an NPC to do it by hand.")
    end
end
