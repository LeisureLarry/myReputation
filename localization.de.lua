--------------------------------------------------------------------------------------------------
-- Localized messages and options in German
--------------------------------------------------------------------------------------------------

if ( GetLocale() == "deDE" ) then

--Slash Commands
MYREP_CMD_STATUS = "status";
MYREP_CMD_DEBUG = "debug";

--Messages
MYREP_MSG_ON = "An";
MYREP_MSG_OFF = "Aus";
MYREP_MSG_MORE = "Zusatzinfos";
MYREP_MSG_BLIZZ = "Blizzard-Meldungen";
MYREP_MSG_SPLASH = "Splash-Meldung";
MYREP_MSG_PERCENT = "Prozent";
MYREP_MSG_FRAME = "Chatfenster";
MYREP_MSG_TPL = "Ansicht";
MYREP_MSG_DEBUG = "Debug";

MYREP_INFO = "Standard-Anzeige";
MYREP_TOOLTIP = "Tooltip-Anzeige";

MYREP_INFO_TEXT = "Stufe";
MYREP_INFO_PERCENT = "Prozent";
MYREP_INFO_ABSOLUTE = "Absolut";
MYREP_INFO_DIFFERENCE = "Session";

MYREP_MSG_NOTIFY = "Reputations-Meldungen erscheinen nun in diesem Chatfenster.";
MYREP_MSG_INVALID_FRAME = MYREP_MSG_FRAME.." ist ung\195\188ltig. G\195\188ltige Werte: 1-%d.";

--Tooltips
MYREP_TOOLTIP_ENABLED = "Aktiviert/deaktiviert myReputation.";
MYREP_TOOLTIP_SPLASH = "Aktiviert/deaktiviert die Splash-Meldung bei Stufenwechsel.";
MYREP_TOOLTIP_BLIZZ = "Aktiviert/deaktiviert Blizzards Reputationsmeldungen.";
MYREP_TOOLTIP_MORE = "Aktiviert/deaktiviert zus\195\164tzliche Chatmeldungen.";

--Notifications
MYREP_NOTIFICATION_GAINED = "Euer Ruf bei %s ist um %d (%d/%d) gestiegen.";
MYREP_NOTIFICATION_LOST = "Euer Ruf bei %s ist um %d (%d/%d) gesunken.";
MYREP_NOTIFICATION_NEEDED = "Noch %d Ruf (%d Wiederholungen) f\195\188r %s ben\195\182tigt.";
MYREP_NOTIFICATION_LEFT = "Noch %d Ruf (%d Wiederholungen) \195\188brig bevor %s erreicht wird.";
MYREP_NOTIFICATION_REACHED = "%s bei %s erreicht.";

--Friend Levels
MYREP_FRIEND_LEVEL_STRANGER = "Stranger";
MYREP_FRIEND_LEVEL_ACQUAINTANCE = "Acquaintance";
MYREP_FRIEND_LEVEL_BUDDY = "Buddy";
MYREP_FRIEND_LEVEL_FRIEND = "Friend";
MYREP_FRIEND_LEVEL_GOODFRIEND = "Good Friend";
MYREP_FRIEND_LEVEL_BESTFRIEND = "Best Friend";
MYREP_FRIEND_LEVEL_PAL = "Pal";
end