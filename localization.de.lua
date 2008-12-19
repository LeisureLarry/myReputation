--------------------------------------------------------------------------------------------------
-- Localized messages and options in German
--------------------------------------------------------------------------------------------------

if ( GetLocale() == "deDE" ) then

--Messages
MYREP_MSG_ON = "An";
MYREP_MSG_OFF = "Aus";
MYREP_MSG_MORE = "Zusatzinfos";
MYREP_MSG_BLIZZ = "Blizzard-Meldung";
MYREP_MSG_SPLASH = "Splash-Meldung";
MYREP_MSG_PERCENT = "Prozent";
MYREP_MSG_FRAME = "Chatfenster";
MYREP_MSG_TPL = "Ansicht";
MYREP_MSG_DEBUG = "Debug";

MYREP_MSG_NOTIFY = "Reputations-Meldungen nun in diesem Chatfenster.";
MYREP_MSG_INVALID_SUBCMD = "%s ist ung\195\188ltig. G\195\188ltig ist %s.";
MYREP_MSG_INVALID_FRAME = MYREP_MSG_FRAME.." ist ung\195\188ltig. G\195\188ltige Werte: 1-%d.";
MYREP_MSG_INVALID_VALUE = "%s f\195\188r %s ist ung\195\188ltig. G\195\188ltige Werte: 1-%d.";

--Slash Commands
MYREP_CMD_ON = "an";
MYREP_CMD_OFF = "aus";
MYREP_CMD_MORE = "mehr";
MYREP_CMD_BLIZZ = "blizz";
MYREP_CMD_SPLASH = "splash";
MYREP_CMD_PERCENT = "prozent";
MYREP_CMD_FRAME = "fenster";
MYREP_CMD_TPL = "ansicht";
MYREP_SUBCMD = "wert";
MYREP_CMD_DEBUG = "debug";
MYREP_CMD_STATUS = "status";

--Help Text
MYREP_HELP_TEXT0 = "myReputation Hilfe:";
MYREP_HELP_TEXT1 = "/reputation <Befehl> oder /rep <Befehl> zum Auszuf\195\188hren:";
MYREP_HELP_TEXT2 = "|cff00ff00"..MYREP_CMD_ON.."|r / |cff00ff00"..MYREP_CMD_OFF.."|r: schaltet Reputation Mod an / aus.";
MYREP_HELP_TEXT3 = "|cff00ff00"..MYREP_CMD_MORE.."|r: aktiviert / deaktiviert zus\195\164tzliche Chatmeldungen.";
MYREP_HELP_TEXT4 = "|cff00ff00"..MYREP_CMD_BLIZZ.."|r: aktiviert / deaktiviert Blizzards Reputationsmeldungen.";
MYREP_HELP_TEXT5 = "|cff00ff00"..MYREP_CMD_SPLASH.."|r: aktiviert / deaktiviert Splash-Meldung bei Stufenwechsel.";
MYREP_HELP_TEXT6 = "|cff00ff00"..MYREP_CMD_PERCENT.."|r: schaltet zwischen Prozent- und absoluter Anzeige um.";
MYREP_HELP_TEXT7 = "|cff00ff00"..MYREP_CMD_FRAME.." "..MYREP_SUBCMD.."=<Zahl>|r: w\195\164hlt Chatfenster f\195\188r Meldungen aus.";
MYREP_HELP_TEXT8 = "|cff00ff00"..MYREP_CMD_TPL.." "..MYREP_SUBCMD.."=<Zahl>|r: w\195\164hlt Ansicht f\195\188r Blizzards Reputationsfenster aus.";
MYREP_HELP_TEXT9 = "|cff00ff00"..MYREP_CMD_STATUS.."|r: zeigt die aktuellen Einstellungen an.";

--Notifications
MYREP_NOTIFICATION_GAINED = "Euer Ruf bei %s ist um %d (%d/%d) gestiegen.";
MYREP_NOTIFICATION_LOST = "Euer Ruf bei %s ist um %d (%d/%d) gesunken.";
MYREP_NOTIFICATION_NEEDED = "Noch %d Ruf (%d Wiederholungen) f\195\188r %s ben\195\182tigt.";
MYREP_NOTIFICATION_LEFT = "Noch %d Ruf (%d Wiederholungen) \195\188brig bevor %s erreicht wird.";
MYREP_NOTIFICATION_REACHED = "%s bei %s erreicht.";

end