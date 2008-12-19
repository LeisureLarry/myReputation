----------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------

-- Basic Addon Variables
MYREP_NAME = "myReputation";
MYREP_VERSION = "30000 R.1 Beta2.1";
MYREP_MSG_FORMAT = "%s |cffffff00%s|r";
MYREP_REGEXP_CHANGED = string.gsub( FACTION_STANDING_CHANGED, "'?%%[1|2]$s'?", "%(.+)" ); 
MYREP_REGEXP_DECREASED = string.gsub( FACTION_STANDING_DECREASED, "'?%%[s|d]'?", "%(.+)" ); 
MYREP_REGEXP_DECREASED_GENERIC = string.gsub( FACTION_STANDING_DECREASED_GENERIC, "'?%%[s|d]'?", "%(.+)" ); 
MYREP_REGEXP_INCREASED = string.gsub( FACTION_STANDING_INCREASED, "'?%%[s|d]'?", "%(.+)" );
MYREP_REGEXP_INCREASED_GENERIC = string.gsub( FACTION_STANDING_INCREASED_GENERIC, "'?%%[s|d]'?", "%(.+)" );
MYREP_TPL_COUNT = 7; 

-- Configuration Variables and their Standard Values
myReputation_Config = { };
myReputation_Config.Enabled = true;
myReputation_Config.More = true;
myReputation_Config.Blizz = false;
myReputation_Config.Splash = true;
myReputation_Config.Percent = true;
myReputation_Config.Debug = false;
myReputation_Config.Frame = 1;
myReputation_Config.Tpl = 1;

-- Temp Variables and Arrays
myReputations = { };
mySessionReputations = { };
myReputation_Var = { };
myReputation_Var.InWorld = false;
myReputation_Var.Help = {
    MYREP_HELP_TEXT0,
    MYREP_HELP_TEXT1,
    MYREP_HELP_TEXT2,
    MYREP_HELP_TEXT3,
    MYREP_HELP_TEXT4,
    MYREP_HELP_TEXT5,
    MYREP_HELP_TEXT6,
    MYREP_HELP_TEXT7,
    MYREP_HELP_TEXT8
};

-- Function Hooks
local lOriginal_ReputationFrame_Update;
local lOriginal_CFAddMessage_Allgemein;
local lOriginal_CFAddMessage_Kampflog;

----------------------------------------------------------------------
-- OnFoo
----------------------------------------------------------------------

function myReputation_OnLoad()
    --Slash command
    SlashCmdList["MYREPCOMMAND"] = myReputation_SlashHandler;
    SLASH_MYREPCOMMAND1 = "/reputation";
    SLASH_MYREPCOMMAND2 = "/rep";

    -- Register Default Events
    this:RegisterEvent("PLAYER_LOGIN");
    this:RegisterEvent("PLAYER_ENTERING_WORLD");
    this:RegisterEvent("UNIT_AURA");
	this:RegisterEvent("PLAYER_TARGET_CHANGED");
    this:RegisterEvent("PLAYER_LEAVING_WORLD");

    if (DEFAULT_CHAT_FRAME) then
        myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_NAME,MYREP_VERSION));
    end
end

function myReputation_OnEvent(event, arg1)
    -- Fired just before PLAYER_ENTERING_WORLD on login and UI Reload
    if (event == "PLAYER_LOGIN") then
        if (
            (myReputation_Config.Frame > 0) and
            (myReputation_Config.Frame <= FCF_GetNumActiveChatFrames())
        ) then
            REPUTATIONS_CHAT_FRAME = getglobal("ChatFrame"..myReputation_Config.Frame);
        else
            REPUTATIONS_CHAT_FRAME = DEFAULT_CHAT_FRAME;
        end
        myReputation_Toggle(myReputation_Config.Enabled,true);
	end

    -- Register Ingame Events
    if (event == "PLAYER_ENTERING_WORLD") then
        this:RegisterEvent("UPDATE_FACTION");
	end

    -- Unregister Ingame Events
    if (event == "PLAYER_LEAVING_WORLD") then
        this:UnregisterEvent("UPDATE_FACTION");
    end

    -- Event UPDATE_FACTION
    if (
        (event == "UPDATE_FACTION") and
        (myReputation_Config.Enabled == true)
    ) then
        myReputation_Factions_Update();
    end

    -- Events which are usable to get numFactions > 0
    if ((event == "UNIT_AURA") or (event == "PLAYER_TARGET_CHANGED")) then

		-- Save Session StartRep
		if (not mySessionReputations["Darnassus"]) then
			
	        local numFactions = GetNumFactions();
			local factionIndex;
	        local name, standingID, barMin, barMax, barValue, isHeader;
	        
	        for factionIndex=1, numFactions, 1 do
				name, _, standingID, barMin, barMax, barValue, _, _, isHeader, _, _ = GetFactionInfo(factionIndex);

	            if (not isHeader) then
	                barMax = barMax - barMin;
	                barValue = barValue - barMin;
	                barMin = 0;
	                mySessionReputations[name] = { };
	                mySessionReputations[name].standingID = standingID;
	                mySessionReputations[name].barValue = barValue;
	                mySessionReputations[name].barMax = barMax;
					
	            end
	        end
		end

        this:UnregisterEvent("UNIT_AURA");
        this:UnregisterEvent("PLAYER_TARGET_CHANGED");
	end
end

----------------------------------------------------------------------
-- Other Functions
----------------------------------------------------------------------

-- Send Message to Chat Frame
function myReputation_ChatMsg(message)
    DEFAULT_CHAT_FRAME:AddMessage(message);
end

-- Send Message to Reputation Chat Frame
function myReputation_RepMsg(message,r,g,b)
    REPUTATIONS_CHAT_FRAME:AddMessage(message,r,g,b);
end

-- Send Message to Splash Frame
function myReputation_SplashMessage(message,r,g,b)
    myReputation_SplashFrame:AddMessage(message, r,g,b, 1.0, UIERRORS_HOLD_TIME);
end

-- SlashHandler
function myReputation_SlashHandler(msg)
	local Cmd, SubCmd = myReputation_GetCmd(msg); --call to above function
	if (Cmd == MYREP_CMD_ON) then
		myReputation_Toggle(true,false);
	elseif (Cmd == MYREP_CMD_OFF) then
		myReputation_Toggle(false,false);
	elseif (Cmd == MYREP_CMD_BLIZZ) then
		myReputation_Toggle_Options("Blizz");
	elseif (Cmd == MYREP_CMD_MORE) then
		myReputation_Toggle_Options("More");
	elseif (Cmd == MYREP_CMD_SPLASH) then
		myReputation_Toggle_Options("Splash");
	elseif (Cmd == MYREP_CMD_PERCENT) then
		myReputation_Toggle_Options("Percent");
	elseif (Cmd == MYREP_CMD_FRAME) then
 		local Argument, Answer = myReputation_GetArgument(SubCmd); --call to above function
 		if (Argument == MYREP_SUBCMD) then
			myReputation_ChatFrame_Change(0,Answer);
		else
			myReputation_ChatMsg(format(MYREP_MSG_INVALID_SUBCMD,Argument,MYREP_SUBCMD));
		end
	elseif (Cmd == MYREP_CMD_TPL) then
 		local Argument, Answer = myReputation_GetArgument(SubCmd); --call to above function
 		if (Argument == MYREP_SUBCMD) then
			myReputation_Change_Value("Tpl",MYREP_MSG_TPL,Answer,MYREP_TPL_COUNT);
		else
			myReputation_ChatMsg(format(MYREP_MSG_INVALID_SUBCMD,Argument,MYREP_SUBCMD));
		end
	elseif (Cmd == MYREP_CMD_DEBUG) then
		myReputation_Toggle_Options("Debug");
	elseif (Cmd == MYREP_CMD_STATUS) then
		myReputation_DisplayStatus();
	else
		myReputation_DisplayHelp();
	end;
end

function myReputation_GetCmd(msg)
 	if msg then
 		local a,b,c=strfind(msg, "(%S+)"); --contiguous string of non-space characters
 		if a then
 			return c, strsub(msg, b+2);
 		else	
 			return "";
 		end
 	end
end

function myReputation_GetArgument(msg)
 	if msg then
 		local a,b=strfind(msg, "=");
 		if a then
 			return strsub(msg,1,a-1), strsub(msg, b+1);
 		else	
 			return "";
 		end
 	end
end

function myReputation_DisplayHelp()
    local index, value;
	for index, value in pairs(myReputation_Var.Help) do
		myReputation_ChatMsg(value);
	end
end


function myReputation_DisplayStatus()
	if (myReputation_Config.Enabled == true) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_NAME,MYREP_MSG_ON,"."));
	else
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_NAME,MYREP_MSG_OFF,"."));
	end
	if (myReputation_Config.Blizz == true) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_BLIZZ,MYREP_MSG_ON,"."));
	else
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_BLIZZ,MYREP_MSG_OFF,"."));
	end
	if (myReputation_Config.More == true) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_MORE,MYREP_MSG_ON,"."));
	else
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_MORE,MYREP_MSG_OFF,"."));
	end
	if (myReputation_Config.Splash == true) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_SPLASH,MYREP_MSG_ON,"."));
	else
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_SPLASH,MYREP_MSG_OFF,"."));
	end
	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_DEBUG,MYREP_MSG_ON,"."));
	end
	myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_FRAME,myReputation_Config.Frame,"."));
	myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_TPL,myReputation_Config.Tpl,"."));
end

-- Toggles
function myReputation_Toggle(toggle,init)
    myReputation_Config.Enabled = toggle;

    if (toggle == true) then
        --Hook
        if (not lOriginal_ReputationFrame_Update) then
            if (init ~= true) then
                myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_NAME,MYREP_MSG_ON,"."));
            end
            lOriginal_ReputationFrame_Update = ReputationFrame_Update;
            ReputationFrame_Update = myReputation_Frame_Update_New;
        end
        if (not lOriginal_CFAddMessage_Allgemein) then
            lOriginal_CFAddMessage_Allgemein = getglobal("ChatFrame1").AddMessage;
            getglobal("ChatFrame1").AddMessage = myReputation_CFAddMessage_Allgemein;
        end
        if (not lOriginal_CFAddMessage_Kampflog) then
            lOriginal_CFAddMessage_Kampflog = getglobal("ChatFrame2").AddMessage;
            getglobal("ChatFrame2").AddMessage = myReputation_CFAddMessage_Kampflog;
        end

	else
        --Unhook
        if (lOriginal_ReputationFrame_Update) then
            if (init ~= true) then
                myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_NAME,MYREP_MSG_OFF,"."));
            end
            ReputationFrame_Update = lOriginal_ReputationFrame_Update;
            lOriginal_ReputationFrame_Update = nil;
        end
        if (lOriginal_CFAddMessage_Allgemein) then
            getglobal("ChatFrame1").AddMessage = lOriginal_CFAddMessage_Allgemein;
            lOriginal_CFAddMessage_Allgemein = nil;
        end
        if (lOriginal_CFAddMessage_Kampflog) then
            getglobal("ChatFrame2").AddMessage = lOriginal_CFAddMessage_Kampflog;
            lOriginal_CFAddMessage_Kampflog = nil;
        end
    end
end

function myReputation_Toggle_Options(option)
    if (myReputation_Config[option] == true) then
        myReputation_Config[option] = false;
        myReputation_ChatMsg(format(MYREP_MSG_FORMAT,getglobal("MYREP_MSG_"..string.upper(option)),MYREP_MSG_OFF,"."));
    else
        myReputation_Config[option] = true;
        myReputation_ChatMsg(format(MYREP_MSG_FORMAT,getglobal("MYREP_MSG_"..string.upper(option)),MYREP_MSG_ON,"."));
    end
end

function myReputation_ChatFrame_Change(checked,value)  --Checked will always be 0
	local number = tonumber(value);
	if (
		(value ~= nil) and
		(number > 0) and
		(number <= FCF_GetNumActiveChatFrames())
	) then
		myReputation_Config.Frame = number;
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_FRAME,myReputation_Config.Frame,"."));
		REPUTATIONS_CHAT_FRAME = getglobal("ChatFrame"..myReputation_Config.Frame);
		myReputation_RepMsg(MYREP_MSG_NOTIFY,1.0,1.0,0.0);
	else
		myReputation_ChatMsg(format(MYREP_MSG_INVALID_FRAME,FCF_GetNumActiveChatFrames()));
	end
end

function myReputation_Change_Value(option,name,value,valid)
	local number = tonumber(value);
	if (
		(value ~= nil) and
		(number ~= nil) and
		(number > 0) and
		(number <= valid)
	) then
		myReputation_Config[option] = number;
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,name,myReputation_Config[option],"."));
	else
		myReputation_ChatMsg(format(MYREP_MSG_INVALID_VALUE,value,name,valid));
	end
end

-- Hooked Functions
function myReputation_CFAddMessage_Allgemein(self, msg, ...)
    if (
		(myReputation_Config.Blizz == false) and
        (msg ~= nil) and
        (
            string.find(msg, MYREP_REGEXP_CHANGED) or
            string.find(msg, MYREP_REGEXP_DECREASED) or
            string.find(msg, MYREP_REGEXP_DECREASED_GENERIC) or
            string.find(msg, MYREP_REGEXP_INCREASED) or
            string.find(msg, MYREP_REGEXP_INCREASED_GENERIC)
        )
    ) then
		if (myReputation_Config.Debug == true) then
			myReputation_RepMsg("Blizzard Meldung in Frame 1 abgefangen");
        end
    else
        lOriginal_CFAddMessage_Allgemein(self, msg, ...);
    end
end

function myReputation_CFAddMessage_Kampflog(self, msg, ...)
    if (
		(myReputation_Config.Blizz == false) and
        (msg ~= nil) and
        (
            string.find(msg, MYREP_REGEXP_CHANGED) or
            string.find(msg, MYREP_REGEXP_DECREASED) or
            string.find(msg, MYREP_REGEXP_DECREASED_GENERIC) or
            string.find(msg, MYREP_REGEXP_INCREASED) or
            string.find(msg, MYREP_REGEXP_INCREASED_GENERIC)
        )
    ) then
		if (myReputation_Config.Debug == true) then
			myReputation_RepMsg("Blizzard Meldung in Frame 2 abgefangen");
        end
    else
        lOriginal_CFAddMessage_Kampflog(self, msg, ...);
    end
end

function myReputation_Frame_Update_New()
    lOriginal_ReputationFrame_Update();
	local numFactions = GetNumFactions();
	local factionIndex, factionRow, factionTitle, factionStanding, factionBar, factionButton, factionLeftLine, factionBottomLine, factionBackground, color, tooltipStanding;
	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, isWatched, isChild;
	local atWarIndicator, rightBarTexture;
    local factionCompleteInfo, factionTooltip, difference;

	local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame);

	local gender = UnitSex("player");
	
	local i;
	
    for i=1, NUM_FACTIONS_DISPLAYED, 1 do
        factionIndex = factionOffset + i;
		factionRow = getglobal("ReputationBar"..i);
		factionBar = getglobal("ReputationBar"..i.."ReputationBar");
		factionTitle = getglobal("ReputationBar"..i.."FactionName");
		factionButton = getglobal("ReputationBar"..i.."ExpandOrCollapseButton");
		factionLeftLine = getglobal("ReputationBar"..i.."LeftLine");
		factionBottomLine = getglobal("ReputationBar"..i.."BottomLine");
		factionStanding = getglobal("ReputationBar"..i.."ReputationBarFactionStanding");
		factionBackground = getglobal("ReputationBar"..i.."Background");

		if (factionIndex <= numFactions) then
			name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(factionIndex);
			factionTitle:SetText(name);

			local factionStandingtext = GetText("FACTION_STANDING_LABEL"..standingID, gender);

			--Normalize Values
			barMax = barMax - barMin;
			barValue = barValue - barMin;
			barMin = 0;

			if (
				(not isHeader) and
				(factionStanding:GetText() ~= nil)
			) then
                local difference = 0;
				
				if (mySessionReputations[name]) then
                    -- No change in standing
                    if (mySessionReputations[name].standingID == standingID) then
						difference = barValue - mySessionReputations[name].barValue;

                    -- Reputation went up and reached next standing
                    elseif (mySessionReputations[name].standingID < standingID) then
						difference = barValue + mySessionReputations[name].barMax - mySessionReputations[name].barValue;

                    -- Reputation went down and reached next standing
                    else
						difference = barMax - barValue + mySessionReputations[name].barValue;
                    end
                end
				
                if (myReputation_Config.Tpl == 2) then
                    factionCompleteInfo = factionStandingtext.." - "..format("%.1f%%",barValue/barMax*100);
                    factionTooltip = barValue.."/"..barMax;
                elseif (myReputation_Config.Tpl == 3) then
                    factionCompleteInfo = string.sub(factionStandingtext, 0, 1).." "..barValue.."/"..barMax;
                    factionTooltip = format("%.1f%%",barValue/barMax*100).." ("..difference..")";
                elseif (myReputation_Config.Tpl == 4) then
                    factionCompleteInfo = string.sub(factionStandingtext, 0, 1).." "..format("%.1f%%",barValue/barMax*100).." ("..difference..")";
                    factionTooltip = barValue.."/"..barMax;
                elseif (myReputation_Config.Tpl == 5) then
                    factionCompleteInfo = format("%.1f%%",barValue/barMax*100).." ("..difference..")";
                    factionTooltip = barValue.."/"..barMax;
                elseif (myReputation_Config.Tpl == 6) then
                    factionCompleteInfo = barValue.."/"..barMax;
                    factionTooltip = format("%.1f%%",barValue/barMax*100).." ("..difference..")";
                elseif (myReputation_Config.Tpl == 7) then
                    factionCompleteInfo = factionStandingtext.." - "..format("%.1f%%",barValue/barMax*100);
                    factionTooltip = barValue.."/"..barMax.." ("..difference..")";
				else
                    factionCompleteInfo = factionStandingtext;
                    factionTooltip = barValue.." / "..barMax;
                end

				factionStanding:SetText(factionCompleteInfo);
				factionRow.standingText = factionCompleteInfo;
				factionRow.tooltip = HIGHLIGHT_FONT_COLOR_CODE.." "..factionTooltip..FONT_COLOR_CODE_CLOSE;
			end
		end
	end
end

-- Event UPDATE_FACTION
function myReputation_Factions_Update()
    local numFactions = GetNumFactions();
    local factionIndex, factionStanding, factionBar, factionHeader, color;
    local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild;
    local barMax, barMin, barValue;
    local RepRemains, RepRepeats, RepBefore, RepActual, RepNext;

    for factionIndex=1, numFactions, 1 do
	    name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(factionIndex);

	    if (not isHeader) then
		    barMax = barMax - barMin;
		    barValue = barValue - barMin;
		    barMin = 0;

		    if (myReputations[name]) then
			    if (standingID ~= 1) then
					RepBefore = getglobal("FACTION_STANDING_LABEL"..standingID-1);
			    end

			    RepActual = getglobal("FACTION_STANDING_LABEL"..standingID);

			    if (standingID ~= 8) then
					RepNext = getglobal("FACTION_STANDING_LABEL"..standingID+1);
			    end

			    local RawTotal = 0;

			    -- No change in standing
			    if (myReputations[name].standingID == standingID) then
				    local difference = barValue - myReputations[name].barValue;

				    -- Reputation went up
				    if ((difference > 0) and (myReputations[name].standingID == standingID)) then
						myReputation_RepMsg(format(MYREP_NOTIFICATION_GAINED,name,difference,barValue,barMax), 0.5, 0.5, 1.0);
					    if (standingID ~= 8) then
						    RepRemains = barMax - barValue;
						    RepRepeats = RepRemains / difference;
						    if (RepRepeats > floor(RepRepeats)) then
								RepRepeats = ceil(RepRepeats);
						    end
						    if (myReputation_Config.More == true) then
								myReputation_RepMsg(format(MYREP_NOTIFICATION_NEEDED,RepRemains,RepRepeats,RepNext), 1.0, 1.0, 0.0);
						    end
					    end

				    -- Reputation went down
				    elseif ((difference < 0) and (myReputations[name].standingID == standingID)) then
					    difference = abs(difference);
					    myReputation_RepMsg(format(MYREP_NOTIFICATION_LOST,name,difference,barValue,barMax), 0.5, 0.5, 1.0);
					    if (standingID ~= 1) then
						    RepRemains = barValue;
						    RepRepeats = RepRemains / difference;
						    if (RepRepeats > floor(RepRepeats)) then
								RepRepeats = ceil(RepRepeats);
						    end
						    if (myReputation_Config.More == true) then
								myReputation_RepMsg(format(MYREP_NOTIFICATION_LEFT,RepRemains,RepRepeats,RepBefore), 1.0, 1.0, 0.0);
						    end
					    end
				    end

			    -- Reputation went up and reached next standing
			    elseif (myReputations[name].standingID < standingID) then
				    RepRemains = barMax - barValue;
				    RawTotal = barValue + myReputations[name].barMax - myReputations[name].barValue;
				    myReputation_RepMsg(format(MYREP_NOTIFICATION_GAINED,name,RawTotal,barValue,barMax), 0.5, 0.5, 1.0);
				    myReputation_RepMsg(format(MYREP_NOTIFICATION_REACHED,RepActual,name), 1.0, 1.0, 0.0);
				    if (standingID ~= 8) then
						RepRepeats = RepRemains / RawTotal;
					    if (RepRepeats > floor(RepRepeats)) then
							RepRepeats = ceil(RepRepeats);
					    end
					    if (myReputation_Config.More == true) then
							myReputation_RepMsg(format(MYREP_NOTIFICATION_NEEDED,RepRemains,RepRepeats,RepNext), 1.0, 1.0, 0.0);
					    end
				    end

				    if (myReputation_Config.Splash == true) then
						myReputation_SplashMessage(name.." - "..RepActual.."!", 1.0, 1.0, 0.0);
				    end

			    -- Reputation went down and reached next standing
			    else
				    RepRemains = barValue;
				    RawTotal = barMax - barValue + myReputations[name].barValue;
				    myReputation_RepMsg(format(MYREP_NOTIFICATION_LOST,name,RawTotal,barValue,barMax), 0.5, 0.5, 1.0);
				    myReputation_RepMsg(format(MYREP_NOTIFICATION_REACHED,RepActual,name), 1.0, 1.0, 0.0);
				    if (standingID ~= 1) then
					    RepRepeats = RepRemains / RawTotal;
					    if (RepRepeats > floor(RepRepeats)) then
							RepRepeats = ceil(RepRepeats);
					    end
					    if (myReputation_Config.More == true) then
							myReputation_RepMsg(format(MYREP_NOTIFICATION_LEFT,RepRemains,RepRepeats,RepBefore), 1.0, 1.0, 0.0);
					    end
				    end

				    if (myReputation_Config.Splash == true) then
						myReputation_SplashMessage(name.." - "..RepActual.."!", 1.0, 1.0, 0.0);
				    end
			    end

		    else
				myReputations[name] = { };
		    end

		    myReputations[name].standingID = standingID;
		    myReputations[name].barValue = barValue;
		    myReputations[name].barMax = barMax;
		    myReputations[name].atWarWith = atWarWith;
	    end
    end
end