--------------------------------------------------------------------------------------------------
-- Localized messages and options in English
--------------------------------------------------------------------------------------------------

--Messages
MYREP_MSG_ON = "On";
MYREP_MSG_OFF = "Off";
MYREP_MSG_MORE = "Additional Infos";
MYREP_MSG_BLIZZ = "Blizzard-Message";
MYREP_MSG_SPLASH = "Splash-Screen";
MYREP_MSG_PERCENT = "Percent";
MYREP_MSG_FRAME = "Chatframe";
MYREP_MSG_TPL = "Template";
MYREP_MSG_DEBUG = "Debug";

MYREP_MSG_NOTIFY = "Reputation notification now set to this frame.";
MYREP_MSG_INVALID_SUBCMD = "%s is invalid. Valid is %s.";
MYREP_MSG_INVALID_FRAME = MYREP_MSG_FRAME.." is invalid. Valid values: 1-%d.";
MYREP_MSG_INVALID_VALUE = "%s for %s is invalid. Valid values: 1-%d.";

--Slash Commands
MYREP_CMD_ON = "on";
MYREP_CMD_OFF = "off";
MYREP_CMD_MORE = "more";
MYREP_CMD_BLIZZ = "blizz";
MYREP_CMD_SPLASH = "splash";
MYREP_CMD_PERCENT = "percent";
MYREP_CMD_FRAME = "frame";
MYREP_CMD_TPL = "template";
MYREP_SUBCMD = "value";
MYREP_CMD_DEBUG = "debug";
MYREP_CMD_STATUS = "status";

--Help Text
MYREP_HELP_TEXT0 = "myReputation help:";
MYREP_HELP_TEXT1 = "/reputation <command> or /rep <command> to perform the following commands:";
MYREP_HELP_TEXT2 = "|cff00ff00"..MYREP_CMD_ON.."|r / |cff00ff00"..MYREP_CMD_OFF.."|r: turns myReputation on / off.";
MYREP_HELP_TEXT3 = "|cff00ff00"..MYREP_CMD_MORE.."|r: toggles additional chat messages .";
MYREP_HELP_TEXT4 = "|cff00ff00"..MYREP_CMD_BLIZZ.."|r: toggles blizzards reputation messages.";
MYREP_HELP_TEXT5 = "|cff00ff00"..MYREP_CMD_SPLASH.."|r: toggles splash screen on reaching next standing.";
MYREP_HELP_TEXT6 = "|cff00ff00"..MYREP_CMD_PERCENT.."|r: toggle between percentage and raw values.";
MYREP_HELP_TEXT7 = "|cff00ff00"..MYREP_CMD_FRAME.." "..MYREP_SUBCMD.."=<number>|r: selects which chat window for reputation messages.";
MYREP_HELP_TEXT8 = "|cff00ff00"..MYREP_CMD_TPL.." "..MYREP_SUBCMD.."=<number>|r: selects template for blizzards reputation frame.";
MYREP_HELP_TEXT9 = "|cff00ff00"..MYREP_CMD_STATUS.."|r: shows addon settings.";

--Notifications
MYREP_NOTIFICATION_GAINED = "Your reputation with %s has increased by %d (%d/%d).";
MYREP_NOTIFICATION_LOST = "Your reputation with %s has decreased by %d (%d/%d).";
MYREP_NOTIFICATION_NEEDED = "%d reputation (%d repetitions) needed until %s.";
MYREP_NOTIFICATION_LEFT = "%d reputation (%d repetitions) left until %s.";
MYREP_NOTIFICATION_REACHED = "%s reputation reached with %s.";