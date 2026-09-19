-- Check against WoW's Lua dialect: 5.1 syntax and stdlib. luacheck itself
-- may run on any Lua version; this is what it validates *against*.
std = "lua51"

max_line_length = false

ignore = {
    "211/ADDON_NAME", -- every file destructures ...; not all use the name
    "211/_",          -- discarded values
    "212",            -- unused arguments (self in handlers, etc.)
    "213/_",          -- discarded loop variables
}

-- Globals this addon is allowed to create or assign
globals = {
    "QuestAcceptDB", -- SavedVariables
    "SLASH_QUESTACCEPT1",
    "SLASH_QUESTACCEPT2",
    "SlashCmdList",
}

-- WoW-provided API, read-only
read_globals = {
    -- Lua extensions in the WoW environment
    "strlower", "strsplit", "strtrim",
    -- API functions
    "AcceptQuest", "AcknowledgeAutoAcceptQuest", "CompleteQuest",
    "CreateFrame", "GetActiveTitle", "GetAvailableTitle",
    "GetNumActiveQuests", "GetNumAvailableQuests", "GetNumQuestChoices",
    "GetQuestReward", "GetTitleText", "IsQuestCompletable", "IsShiftKeyDown",
    "QuestFlagsPVP", "QuestGetAutoAccept", "SelectActiveQuest",
    "SelectAvailableQuest",
    -- Namespaces
    "C_AddOns", "C_GossipInfo",
}
