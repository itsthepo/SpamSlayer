-- Spam Slayer Addon for World of Warcraft
local frame, events = CreateFrame("Frame"), {};
local messageHistory = {}; -- To track messages for repetition and rate
local messageLog = {}; -- To store logs for periodic reports

-- Initialize saved variables if they don't exist
local function initializeVariables()
    SpamSlayer_Blacklist = SpamSlayer_Blacklist or {}
    SpamSlayer_HourlyBlockedCount = SpamSlayer_HourlyBlockedCount or 0
    SpamSlayer_MonthlyBlockedCount = SpamSlayer_MonthlyBlockedCount or 0
    SpamSlayer_MessageLog = SpamSlayer_MessageLog or {} -- To retain message logs between sessions
end

function events:PLAYER_LOGIN()
    initializeVariables()
    -- Set up a timer to report hourly and reset the log
    frame:SetScript("OnUpdate", function(self, elapsed)
        reportAndResetHourly(elapsed)
    end)
end

-- Register a message filter to intercept chat messages
local function ChatMessageFilter(self, event, message, sender, ...)
    -- Normalize and check the message
    local normalizedMessage = message:lower():gsub("[%s%p]", "")
    local keywords = {"boosting", "run", "mythic", "cheap", "%$", "wts", "%(wts%)", "level boost", "mythic%+", "gladiator"}
    for _, keyword in ipairs(keywords) do
        if normalizedMessage:find(keyword) then
            logMessage("keyword", keyword)
            return true -- Filter the message, true here means block it
        end
    end
    return false, message, sender, ... -- Do not filter the message
end

-- Register the filter for chat events
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatMessageFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatMessageFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatMessageFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ChatMessageFilter)

-- Logs messages for reporting instead of printing immediately
function logMessage(reason, detail)
    SpamSlayer_HourlyBlockedCount = SpamSlayer_HourlyBlockedCount + 1
    SpamSlayer_MonthlyBlockedCount = SpamSlayer_MonthlyBlockedCount + 1
    local logEntry = reason .. " - " .. detail
    table.insert(SpamSlayer_MessageLog, logEntry)
end

-- Report and reset logs hourly
function reportAndResetHourly(elapsed)
    frame.totalElapsed = (frame.totalElapsed or 0) + elapsed
    if frame.totalElapsed >= 3600 then
        if #SpamSlayer_MessageLog > 0 then
            print("SpamSlayer: Hourly Report:")
            for _, entry in ipairs(SpamSlayer_MessageLog) do
                print(entry)
            end
            wipe(SpamSlayer_MessageLog)  -- Clear the log
        end
        frame.totalElapsed = 0  -- Reset the timer
    end
end

-- Blacklist and UI toggle commands
SLASH_SpamSlayer1 = "/SpamSlayer"
SLASH_SpamSlayerUI1 = "/SpamSlayerui"
SlashCmdList["SpamSlayer"] = function(msg)
    local command, name = strsplit(" ", msg)
    if command == "add" and name then
        SpamSlayer_Blacklist[name] = true
        print("SpamSlayer: Added to blacklist -", name)
    elseif command == "remove" and name then
        SpamSlayer_Blacklist[name] = nil
        print("SpamSlayer: Removed from blacklist -", name)
    elseif command == "list" then
        if next(SpamSlayer_Blacklist) == nil then
            print("SpamSlayer: Your blacklist is empty.")
        else
            print("SpamSlayer: Blacklisted players:")
            for k, _ in pairs(SpamSlayer_Blacklist) do
                print(k)
            end
        end
    elseif command == "status" then
        print("SpamSlayer: We have blocked " .. SpamSlayer_HourlyBlockedCount + SpamSlayer_MonthlyBlockedCount .. " messages so far.")
    else
        print("Usage: /SpamSlayer add|remove|list|status [characterName]")
    end
end

SlashCmdList["SpamSlayerUI"] = function(msg)
    if msg == "show" then
        SpamSlayerMainFrame:Show();
    elseif msg == "hide" then
        SpamSlayerMainFrame:Hide();
    else
        SpamSlayerMainFrame:SetShown(not SpamSlayerMainFrame:IsShown());
    end
end

-- Register event handler and initialize on login
frame:RegisterEvent("PLAYER_LOGIN")
for k, v in pairs(events) do
    frame:RegisterEvent(k);
end

frame:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...);
end);
