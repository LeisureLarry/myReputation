----------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------

-- Basic Addon Variables
MYREP_NAME = "myReputation";
MYREP_VERSION = GetAddOnMetadata("myReputation", "Version");
MYREP_MSG_FORMAT = "%s |cffffff00%s|r";
MYREP_REGEXP_CHANGED = string.gsub( FACTION_STANDING_CHANGED, "'?%%[1|2]$s'?", "%(.+)" );
MYREP_REGEXP_DECREASED = string.gsub( FACTION_STANDING_DECREASED, "'?%%[s|d]'?", "%(.+)" );
MYREP_REGEXP_DECREASED_GENERIC = string.gsub( FACTION_STANDING_DECREASED_GENERIC, "'?%%[s|d]'?", "%(.+)" );
MYREP_REGEXP_INCREASED = string.gsub( FACTION_STANDING_INCREASED, "'?%%[s|d]'?", "%(.+)" );
MYREP_REGEXP_INCREASED_GENERIC = string.gsub( FACTION_STANDING_INCREASED_GENERIC, "'?%%[s|d]'?", "%(.+)" );

-- Configuration Variables and their Standard Values
myReputation_Config = { };

myReputation_DefaultConfig = { };
myReputation_DefaultConfig.Enabled = true;
myReputation_DefaultConfig.More = true;
myReputation_DefaultConfig.Blizz = false;
myReputation_DefaultConfig.Splash = true;
myReputation_DefaultConfig.Debug = false;
myReputation_DefaultConfig.Frame = 1;
myReputation_DefaultConfig.Info = 'Text';
myReputation_DefaultConfig.Tooltip = 'Absolute';

-- Temp Variables and Arrays
myReputations = { };
mySessionReputations = { };
myReputation_Var = { };
myReputation_Friend_Level = {MYREP_FRIEND_LEVEL_STRANGER, MYREP_FRIEND_LEVEL_ACQUAINTANCE, MYREP_FRIEND_LEVEL_BUDDY, MYREP_FRIEND_LEVEL_FRIEND, MYREP_FRIEND_LEVEL_GOODFRIEND, MYREP_FRIEND_LEVEL_BESTFRIEND};
myReputation_Follower_Level = {MYREP_FOLLOWER_LEVEL_BODYGUARD, MYREP_FOLLOWER_LEVEL_TRUSTED_BODYGUARD, MYREP_FOLLOWER_LEVEL_PERSONAL_WINGMAN};
myReputation_Var.InWorld = false;

-- Function Hooks
local lOriginal_ReputationFrame_Update;
local lOriginal_ReputationBar_OnClick;
local lOriginal_CFAddMessage_Allgemein;
local lOriginal_CFAddMessage_Kampflog;

-- A local speeds up access to _G slightly
-- http://www.wowwiki.com/API_getglobal
local _G = _G;

----------------------------------------------------------------------
-- OnFoo
----------------------------------------------------------------------

function myReputation_OnLoad(self)
	--Slash command
	SlashCmdList["MYREPCOMMAND"] = myReputation_SlashHandler;
	SLASH_MYREPCOMMAND1 = "/myreputation";
	SLASH_MYREPCOMMAND2 = "/myrep";

	-- Register Default Events
	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("PLAYER_LOGIN");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("UNIT_AURA");
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	self:RegisterEvent("PLAYER_LEAVING_WORLD");

	if (DEFAULT_CHAT_FRAME) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_NAME,MYREP_VERSION));
	end
end

function myReputation_OnEvent(self, event, ...)
	local arg1 = ...;
	if (event == "ADDON_LOADED" and arg1 == "myReputation") then
		myReputation_AddOptionMt(myReputation_Config, myReputation_DefaultConfig);

		-- Delete Unused Config Values
		for i,v in pairs(myReputation_Config) do
			if (myReputation_DefaultConfig[i] == nil) then
				if (myReputation_Config.Debug == true) then
					myReputation_ChatMsg('Clean Up Config '..i);
				end
				myReputation_Config[i] = nil;
			end
		end
	end
	
	-- Fired just before PLAYER_ENTERING_WORLD on login and UI Reload
	if (event == "PLAYER_LOGIN") then
		if ((myReputation_Config.Frame > 0) and (myReputation_Config.Frame <= FCF_GetNumActiveChatFrames()) ) then
			REPUTATIONS_CHAT_FRAME = _G["ChatFrame"..myReputation_Config.Frame];
		else
			REPUTATIONS_CHAT_FRAME = DEFAULT_CHAT_FRAME;
		end
		myReputation_Toggle(myReputation_Config.Enabled,true);
	end

	-- Register Ingame Events
	if (event == "PLAYER_ENTERING_WORLD") then
		self:RegisterEvent("UPDATE_FACTION");
	end

	-- Unregister Ingame Events
	if (event == "PLAYER_LEAVING_WORLD") then
		self:UnregisterEvent("UPDATE_FACTION");
	end

	-- Event UPDATE_FACTION
	if ((event == "UPDATE_FACTION") and (myReputation_Config.Enabled == true)) then
		myReputation_Factions_Update();
	end

	-- Events which are usable to get numFactions > 0
	if ((event == "UNIT_AURA") or (event == "PLAYER_TARGET_CHANGED")) then
		-- Save Session StartRep
		if (not mySessionReputations["Darnassus"]) then
			local numFactions = GetNumFactions();
			local factionIndex;
			local name, standingID, barMin, barMax, barValue, isHeader, hasRep, factionID, _;
			for factionIndex=1, numFactions, 1 do
				name, _, standingID, barMin, barMax, barValue, _, _, isHeader, _, hasRep, _, _, factionID = GetFactionInfo(factionIndex);
				if (not isHeader or hasRep) then
					-- check if this is a friendship faction 
					local friendID, friendRep, friendMaxRep, _, _, _, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID);
					local currentRank = GetFriendshipReputationRanks(factionID);
					if (friendID ~= nil) then
						standingID = currentRank;
						if ( nextFriendThreshold ) then
							barMin, barMax, barValue = friendThreshold, nextFriendThreshold, friendRep;
						else
							-- max rank
							barMin, barMax, barValue = friendThreshold, friendMaxRep, friendRep;
						end
					end
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
		self:UnregisterEvent("UNIT_AURA");
		self:UnregisterEvent("PLAYER_TARGET_CHANGED");
	end
end

----------------------------------------------------------------------
-- Metatable Functions
----------------------------------------------------------------------

function myReputation_AddOptionMt(options, defaults)
	setmetatable(options, { __index = defaults });
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
	if (msg == MYREP_CMD_STATUS) then
		myReputation_DisplayStatus();
	elseif (msg == MYREP_CMD_DEBUG) then
		myReputation_Toggle_Options("Debug");
	else
		InterfaceOptionsFrame_OpenToCategory(MYREP_NAME);
	end;
end

function myReputation_DisplayStatus()
	if (myReputation_Config.Enabled == true) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_NAME,MYREP_MSG_ON));
	else
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_NAME,MYREP_MSG_OFF));
	end
	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_DEBUG,MYREP_MSG_ON));
	end
	if (myReputation_Config.Blizz == true) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_BLIZZ,MYREP_MSG_ON));
	else
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_BLIZZ,MYREP_MSG_OFF));
	end
	if (myReputation_Config.More == true) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_MORE,MYREP_MSG_ON));
	else
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_MORE,MYREP_MSG_OFF));
	end
	if (myReputation_Config.Splash == true) then
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_SPLASH,MYREP_MSG_ON));
	else
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_SPLASH,MYREP_MSG_OFF));
	end
	myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_FRAME,myReputation_Config.Frame));
	myReputation_ChatMsg(format(MYREP_MSG_FORMAT,'Info',myReputation_Config.Info));
	myReputation_ChatMsg(format(MYREP_MSG_FORMAT,'Tooltip',myReputation_Config.Tooltip));
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
		if (not lOriginal_ReputationBar_OnClick) then
			lOriginal_ReputationBar_OnClick = ReputationBar_OnClick;
			ReputationBar_OnClick = myReputation_ReputationBar_OnClick;
		end
		if (not lOriginal_CFAddMessage_Allgemein) then
			lOriginal_CFAddMessage_Allgemein = _G["ChatFrame1"].AddMessage;
			_G["ChatFrame1"].AddMessage = myReputation_CFAddMessage_Allgemein;
		end
		if (not lOriginal_CFAddMessage_Kampflog) then
			lOriginal_CFAddMessage_Kampflog = _G["ChatFrame2"].AddMessage;
			_G["ChatFrame2"].AddMessage = myReputation_CFAddMessage_Kampflog;
		end
		if (ReputationDetailFrame:GetScript("OnShow") == nil) then
			ReputationDetailFrame:HookScript("OnShow", function(self, event)
				if (myReputation_Config.Enabled) then
					myReputation_ReputationDetailFrame:Show();
				end
			end)
		end
		if (ReputationDetailFrame:GetScript("OnHide") == nil) then
			ReputationDetailFrame:HookScript("OnHide", function(self, event)
				myReputation_ReputationDetailFrame:Hide();
			end)
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
			_G["ChatFrame1"].AddMessage = lOriginal_CFAddMessage_Allgemein;
			lOriginal_CFAddMessage_Allgemein = nil;
		end
		if (lOriginal_CFAddMessage_Kampflog) then
			_G["ChatFrame2"].AddMessage = lOriginal_CFAddMessage_Kampflog;
			lOriginal_CFAddMessage_Kampflog = nil;
		end
	end
end

function myReputation_Toggle_Options(option)
	if (myReputation_Config[option] == true) then
		myReputation_Config[option] = false;
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,_G["MYREP_MSG_"..string.upper(option)],MYREP_MSG_OFF,"."));
	else
		myReputation_Config[option] = true;
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,_G["MYREP_MSG_"..string.upper(option)],MYREP_MSG_ON,"."));
	end
end

function myReputation_ChatFrame_Change(checked,value)  --Checked will always be 0
	local number = tonumber(value);
	if ((value ~= nil) and (number > 0) and (number ~= 2) and (number <= FCF_GetNumActiveChatFrames())) then
		myReputation_Config.Frame = number;
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_FRAME,myReputation_Config.Frame,"."));
		REPUTATIONS_CHAT_FRAME = _G["ChatFrame"..myReputation_Config.Frame];
		myReputation_RepMsg(MYREP_MSG_NOTIFY,1.0,1.0,0.0);
	else
		myReputation_ChatMsg(format(MYREP_MSG_INVALID_FRAME,FCF_GetNumActiveChatFrames()));
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

function myReputation_ReputationBar_OnClick(self)
	local gender = UnitSex("player");
	lOriginal_ReputationBar_OnClick(self);
	
	if (myReputation_Config.Debug == true) then
		myReputation_RepMsg("ReputationBar_OnClick Faction "..self.index);
	end
	
	if (ReputationDetailFrame:IsVisible()) then
		local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID = GetFactionInfo(self.index);
		local color = FACTION_BAR_COLORS[standingID];
		local text;

		-- check if this is a friendship faction 
		local friendID, friendRep, friendMaxRep, _, _, _, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID);
		local currentRank = GetFriendshipReputationRanks(factionID);
		if (friendID ~= nil) then
			text = friendTextLevel;
			standingID = currentRank;
			if ( nextFriendThreshold ) then
				barMin, barMax, barValue = friendThreshold, nextFriendThreshold, friendRep;
			else
				-- max rank
				barMin, barMax, barValue = friendThreshold, friendMaxRep, friendRep;
			end
		else
			text = GetText("FACTION_STANDING_LABEL"..standingID, gender);
		end

		--Normalize Values
		barMax = barMax - barMin;
		barValue = barValue - barMin;
		barMin = 0;

		local absolute = barValue.."/"..barMax;
		local percent = format("%.1f%%", barValue / barMax * 100);
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

		myReputation_ReputationDetailFrameDetails:SetTextColor(color.r, color.g, color.b);
		myReputation_ReputationDetailFrameText:SetText(
			format(MYREP_MSG_FORMAT, MYREP_INFO_TEXT..":", text)
		);
		myReputation_ReputationDetailFrameAbsolute:SetText(
			format(MYREP_MSG_FORMAT, MYREP_INFO_ABSOLUTE..":", absolute)
		);
		myReputation_ReputationDetailFramePercent:SetText(
			format(MYREP_MSG_FORMAT, MYREP_INFO_PERCENT..":", percent)
		);
		myReputation_ReputationDetailFrameDifference:SetText(
			format(MYREP_MSG_FORMAT, MYREP_INFO_DIFFERENCE..":", difference)
		);
	end
end

function myReputation_Frame_Update_New()
	lOriginal_ReputationFrame_Update();
	
	local info = myReputation_Explode(myReputation_Config.Info, ',');
	local tooltip = myReputation_Explode(myReputation_Config.Tooltip, ',');
	
	local numFactions = GetNumFactions();
	local factionIndex, factionRow, factionTitle, factionStanding, factionBar, factionButton, factionLeftLine, factionBottomLine, factionBackground, color, tooltipStanding;
	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID;
	local atWarIndicator, rightBarTexture;
	local factionCompleteInfo, factionTooltip, difference, factionStandingText;

	local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame);

	local gender = UnitSex("player");
	local guildName = GetGuildInfo("player");
	
	local i;
	
	for i=1, NUM_FACTIONS_DISPLAYED, 1 do
		factionIndex = factionOffset + i;
		factionRow = _G["ReputationBar"..i];
		factionBar = _G["ReputationBar"..i.."ReputationBar"];
		factionTitle = _G["ReputationBar"..i.."FactionName"];
		factionButton = _G["ReputationBar"..i.."ExpandOrCollapseButton"];
		factionLeftLine = _G["ReputationBar"..i.."LeftLine"];
		factionBottomLine = _G["ReputationBar"..i.."BottomLine"];
		factionStanding = _G["ReputationBar"..i.."ReputationBarFactionStanding"];
		factionBackground = _G["ReputationBar"..i.."Background"];

		if (factionIndex <= numFactions) then
			name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID = GetFactionInfo(factionIndex);
			factionTitle:SetText(name);

			-- check if this is a friendship faction 
			local friendID, friendRep, friendMaxRep, _, _, _, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID);
			local currentRank = GetFriendshipReputationRanks(factionID);
			if (friendID ~= nil) then
				factionStandingText = friendTextLevel;
				standingID = currentRank;
				if ( nextFriendThreshold ) then
					barMin, barMax, barValue = friendThreshold, nextFriendThreshold, friendRep;
				else
					-- max rank
					barMin, barMax, barValue = friendThreshold, friendMaxRep, friendRep;
				end
			else
				factionStandingText = GetText("FACTION_STANDING_LABEL"..standingID, gender);
			end

			--Normalize Values
			barMax = barMax - barMin;
			barValue = barValue - barMin;
			barMin = 0;

			if ((not isHeader or hasRep) and (factionStanding:GetText() ~= nil)) then
				local difference = 0;
				
				-- guild name was not available on login
				if (mySessionReputations[name] == nil and guildName ~= nil and name == guildName) then
					bakName = name;
					name = GUILD_REPUTATION;
				end
				
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
				local join;
				-- guild name should be displayed
				if (bakName ~= nil) then
					name = bakName;
				end
				factionCompleteInfo = factionStandingText;
				if (type(info) == 'table') then
					factionCompleteInfo = '';
					join = '';
					for i,v in ipairs(info) do
						if (v == 'Text') then
							factionCompleteInfo = factionCompleteInfo..join..factionStandingText;
						end
						if (v == 'Percent') then
							factionCompleteInfo = factionCompleteInfo..join..format("%.1f%%", barValue / barMax * 100);
						end
						if (v == 'Absolute') then
							factionCompleteInfo = factionCompleteInfo..join..barValue.."/"..barMax;
						end
						if (v == 'Difference') then
							if (join ~= '') then
								factionCompleteInfo = factionCompleteInfo..join..'('..difference..')';
							else
								factionCompleteInfo = factionCompleteInfo..join..difference;
							end
						end
						join = ' ';
					end
				end
				factionTooltip = barValue.."/"..barMax;
				if (type(tooltip) == 'table') then
					factionTooltip = '';
					join = '';
					for i,v in ipairs(tooltip) do
						if (v == 'Text') then
							factionTooltip = factionTooltip..join..factionStandingText;
						end
						if (v == 'Percent') then
							factionTooltip = factionTooltip..join..format("%.1f%%", barValue / barMax * 100);
						end
						if (v == 'Absolute') then
							factionTooltip = factionTooltip..join..barValue.."/"..barMax;
						end
						if (v == 'Difference') then
							if (join ~= '') then
								factionTooltip = factionTooltip..join..'('..difference..')';
							else
								factionTooltip = factionTooltip..join..difference;
							end
						end
						join = ' ';
					end
				end
				factionStanding:SetText(factionCompleteInfo);
				factionRow.standingText = factionCompleteInfo;
				factionRow.tooltip = HIGHLIGHT_FONT_COLOR_CODE..factionTooltip..FONT_COLOR_CODE_CLOSE;
			end
		end
	end
end

-- Event UPDATE_FACTION
function myReputation_Factions_Update()
	local numFactions = GetNumFactions();
	local factionIndex, factionStanding, factionBar, factionHeader, color;
	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID;
	local barMax, barMin, barValue;
	local RepRemains, RepRepeats, RepBefore, RepActual, RepNext;

	for factionIndex=1, numFactions, 1 do
		name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID = GetFactionInfo(factionIndex);

		if (not isHeader or hasRep) then
			-- check if this is a friendship faction 
			local friendID, friendRep, friendMaxRep, _, _, _, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID);
			local currentRank, maxRank = GetFriendshipReputationRanks(factionID);
			local IsFollower = maxRank and 3;
			if (friendID ~= nil) then
				--DEFAULT_CHAT_FRAME:AddMessage("factionID/friendID/IsFollower: " .. name .. " - " .. factionID .. "/" .. friendID .. "/" .. IsFollower)
				standingID = currentRank;
				if ( nextFriendThreshold ) then
					barMin, barMax, barValue = friendThreshold, nextFriendThreshold, friendRep;
				else
					-- max rank
					barMin, barMax, barValue = friendThreshold, friendMaxRep, friendRep;
				end
			end

			barMax = barMax - barMin;
			barValue = barValue - barMin;
			barMin = 0;

			if (myReputations[name]) then
				if (friendID ~= nil) then
					if IsFollower then
						if (standingID ~= 1) then
							RepBefore = myReputation_Follower_Level[standingID-1];
						end
						RepActual = friendTextLevel;
						if (standingID ~= maxRank) then
							RepNext = myReputation_Follower_Level[standingID+1];
						end
					else
						if (standingID ~= 1) then
							RepBefore = myReputation_Friend_Level[standingID-1];
						end
						RepActual = friendTextLevel;
						if (standingID ~= maxRank) then
							RepNext = myReputation_Friend_Level[standingID+1];
						end
						if (factionID == 1358 and standingID == 1) then
							RepNext = MYREP_FRIEND_LEVEL_PAL;
						end
					end 
				else
					maxRank = 8;
					if (standingID ~= 1) then
						RepBefore = _G["FACTION_STANDING_LABEL"..standingID-1];
					end
					RepActual = _G["FACTION_STANDING_LABEL"..standingID];
					if (standingID ~= maxRank) then
						RepNext = _G["FACTION_STANDING_LABEL"..standingID+1];
					end
				end

				local RawTotal = 0;

				-- No change in standing
				if (myReputations[name].standingID == standingID) then
					local difference = barValue - myReputations[name].barValue;

					-- Reputation went up
					if ((difference > 0) and (myReputations[name].standingID == standingID)) then
						myReputation_RepMsg(format(MYREP_NOTIFICATION_GAINED,name,difference,barValue,barMax), 0.5, 0.5, 1.0);
						if (standingID ~= maxRank) then
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
					if (standingID ~= maxRank) then
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
