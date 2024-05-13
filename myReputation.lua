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
MYREP_REGEXP_INCREASED_ACH_BONUS = string.gsub( string.gsub( FACTION_STANDING_INCREASED_ACH_BONUS, "%(.+%)", ".+"), "'?+?%%%.?1?[s|d|f]'?", "%(.+)" );

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
		
		-- SHADOWLANDS-FIX
		myReputation_ReputationDetailFrame.backdropInfo = {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 24,
			edgeSize = 24,
			insets = { left = 6, right = 6, top = 6, bottom = 6, },
		};
		myReputation_ReputationDetailFrame:ApplyBackdrop();
	end
	
	-- Fired just before PLAYER_ENTERING_WORLD on login and UI Reload
	if ((event == "PLAYER_LOGIN") or (event == "PLAYER_ENTERING_WORLD")) then
		myReputation_Toggle(myReputation_Config.Enabled,true);
	end

	-- Register Ingame Events
	if (event == "PLAYER_ENTERING_WORLD") then
		self:RegisterEvent("UPDATE_FACTION");
	end

	-- Event UPDATE_FACTION
	if ((event == "UPDATE_FACTION") and (myReputation_Config.Enabled == true)) then
		myReputation_Factions_Update();
	end

	-- Unregister Ingame Events
	if (event == "PLAYER_LEAVING_WORLD") then
		self:UnregisterEvent("UPDATE_FACTION");
	end

	-- Events which are usable to get numFactions > 0
	if ((event == "PLAYER_ENTERING_WORLD") or (event == "UNIT_AURA") or (event == "PLAYER_TARGET_CHANGED")) then
		if (myReputation_Config.Debug == true) then
			myReputation_ChatMsg("MyRep: Entering, ChatFrames: "..myReputation_CountUsableChatFrames()..", NumFactions: "..GetNumFactions());
			myReputation_RepMsg("Current reputation chat frame",1.0,1.0,0.0);
		end

		-- Save Session StartRep
		if (not mySessionReputations["Darnassus"]) then
			local numFactions = GetNumFactions();
			local factionIndex;
			local name, standingID, barMin, barMax, barValue, isHeader, hasRep, factionID, hasBonusRepGain, canBeLFGBonus, _;
			local isParagon, paraRewards, factionStandingText, isFollower, isMajorFaction, renownLevel;
			for factionIndex=1, numFactions, 1 do
				name, _, standingID, barMin, barMax, barValue, _, _, isHeader, _, hasRep, _, _, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex);
				if (not isHeader or hasRep) then
					barMax, barMin, barValue, isParagon, paraRewards, factionStandingText, isFriendshipFaction, isFollower, _, isMajorFaction, renownLevel = myReputation_GetReputationDetails(name, factionID, standingID, barMin, barMax, barValue);
					
					--Normalize Values
					barMax = barMax - barMin;
					barValue = barValue - barMin;
					barMin = 0;
					
					mySessionReputations[name] = { };
					if (isMajorFaction) then
						mySessionReputations[name].standingID = renownLevel;
					else
						mySessionReputations[name].standingID = standingID;
					end
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
	if ((myReputation_Config.Frame > 0) and (myReputation_Config.Frame <= myReputation_CountUsableChatFrames()) ) then
		local usableChatFrame = myReputation_GetUsableChatFrames();
		_G["ChatFrame"..usableChatFrame[myReputation_Config.Frame]]:AddMessage(message, r,g,b);
	else
		DEFAULT_CHAT_FRAME:AddMessage(message, r,g,b);
	end
end

function myReputation_CountUsableChatFrames()
	return table.getn(myReputation_GetUsableChatFrames());
end

-- Not all Chat Frames are usable as Reputation Chat Frame
function myReputation_GetUsableChatFrames()
	local dockedList = { };
	for i=1, NUM_CHAT_WINDOWS do
		local chatFrame = _G["ChatFrame"..i];
		local name, fontSize, r, g, b, a, shown, locked = FCF_GetChatWindowInfo(i);

		if (chatFrame) then
			if (chatFrame.isDocked and (name ~= COMBAT_LOG)) then
				table.insert(dockedList, chatFrame:GetID());
			end
		end
	end
	
	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg(table.concat(dockedList,","));
	end

	return dockedList;
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
	if (myReputation_Config.Debug == true) then
		local toggleText;
		if (toggle) then toggleText = "enabled"; else toggleText = "disabled"; end
		myReputation_ChatMsg("MyRep: Toggle "..toggleText);
	end
		
	myReputation_Config.Enabled = toggle;
	if (toggle == true) then
		--Hook
		if (not lOriginal_ReputationFrame_InitReputationRow) then
			if (init ~= true) then
				myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_NAME,MYREP_MSG_ON,"."));
			end
			lOriginal_ReputationFrame_InitReputationRow = ReputationFrame_InitReputationRow;
			ReputationFrame_InitReputationRow = myReputation_ReputationFrame_InitReputationRow;
		end
		if (not lOriginal_ReputationBarMixin_OnClick) then
			lOriginal_ReputationBarMixin_OnClick = ReputationBarMixin.OnClick;
			ReputationBarMixin.OnClick = myReputation_ReputationBarMixin_OnClick;
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
		
		myReputation_Factions_Update();
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
	if ((value ~= nil) and (number > 0) and (number ~= 2) and (number <= myReputation_CountUsableChatFrames())) then
		myReputation_Config.Frame = math.floor(number);
		myReputation_ChatMsg(format(MYREP_MSG_FORMAT,MYREP_MSG_FRAME,myReputation_Config.Frame,"."));
		myReputation_RepMsg(MYREP_MSG_NOTIFY,1.0,1.0,0.0);
	else
		myReputation_ChatMsg(format(MYREP_MSG_INVALID_FRAME,myReputation_CountUsableChatFrames()));
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
		string.find(msg, MYREP_REGEXP_INCREASED_ACH_BONUS) or
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
		string.find(msg, MYREP_REGEXP_INCREASED_ACH_BONUS) or
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

-- Extra Detail Frame of Reputation Frame
function myReputation_ReputationBarMixin_OnClick(self, down)
	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg("ReputationBarMixin_OnClick Faction "..self.index);
	end
	
	lOriginal_ReputationBarMixin_OnClick(self, down);
	
	if (ReputationDetailFrame:IsShown()) then
		local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID = GetFactionInfo(self.index);
		local isParagon, paraRewards, factionStandingText, isFollower, isMajorFaction, renownLevel;

		if (not isHeader or hasRep) then
			barMax, barMin, barValue, isParagon, paraRewards, factionStandingText, isFriendshipFaction, isFollower, _, isMajorFaction, renownLevel = myReputation_GetReputationDetails(name, factionID, standingID, barMin, barMax, barValue);

			local absolute = barValue.."/"..barMax;
			local percent = format("%.1f%%", barValue / barMax * 100);
			local difference = 0;
			local color = FACTION_BAR_COLORS[standingID];

			if (isMajorFaction) then
				standingID = renownLevel;
			end

			if (mySessionReputations[name]) then
				-- No change in standing
				if (mySessionReputations[name].standingID == standingID) then
					difference = barValue - mySessionReputations[name].barValue;

				-- Reputation went up and reached next standing
				elseif (mySessionReputations[name].standingID < standingID) then
					if (isMajorFaction) then
						difference = barValue + ((standingID - mySessionReputations[name].standingID) * mySessionReputations[name].barMax) - mySessionReputations[name].barValue;
					else
						difference = barValue + mySessionReputations[name].barMax - mySessionReputations[name].barValue;
					end

				-- Reputation went down and reached next standing
				else
					difference = barMax - barValue + mySessionReputations[name].barValue;
				end
			end

			if (not isParagon and barMax == 0) then
				absolute = "-";
				percent = "-";
				difference = "-";
			end
		
			myReputation_ReputationDetailFrameDetails:SetTextColor(color.r, color.g, color.b);
			myReputation_ReputationDetailFrameText:SetText(
				format(MYREP_MSG_FORMAT, MYREP_INFO_TEXT..":", factionStandingText)
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
			if (paraRewards > 0) then
				myReputation_ReputationDetailFrameParagonRewards:SetText(
					format(MYREP_MSG_FORMAT, MYREP_INFO_PARA_REWARDS..":", paraRewards)
				);
			else
				myReputation_ReputationDetailFrameParagonRewards:SetText("");
			end
		end
	end
end

function myReputation_GetReputationDetails(name, factionID, standingID, barMin, barMax, barValue)
	local paraRewards = 0;
	local factionStandingText = "";

	local reputationInfo = C_GossipInfo.GetFriendshipReputation(factionID);
	local rankInfo = C_GossipInfo.GetFriendshipReputationRanks(factionID);
	
	local isFriendshipFaction = reputationInfo.friendshipFactionID > 0;
	
	local isFollower;
	if (rankInfo.maxLevel == 3) then
		isFollower = true;
	else
		isFollower = false;
	end

	-- check if this is a friendship faction 
	if (isFriendshipFaction) then
		standingID = rankInfo.currentLevel;
		if ( reputationInfo.nextThreshold ) then
			barMin, barMax, barValue = reputationInfo.reactionThreshold, reputationInfo.nextThreshold, reputationInfo.standing;
		else
			-- max rank
			barMin, barMax, barValue = reputationInfo.reactionThreshold, reputationInfo.maxRep, reputationInfo.standing;
		end
		
		factionStandingText = reputationInfo.reaction;
	else
		local gender = UnitSex("player");
		factionStandingText = GetText("FACTION_STANDING_LABEL"..standingID, gender);
	end

	local isParagon = C_Reputation.IsFactionParagon(factionID);

	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg(name..' '..tostring(isParagon)..' '..barMin..' '..barMax..' '..barValue);
	end

	if (isParagon and barMin == barMax and barValue == barMax) then
		local paraValue, paraThreshold, paraQuestId, paraRewardPending = C_Reputation.GetFactionParagonInfo(factionID);
		paraRewards = math.floor(paraValue / paraThreshold);
		barMin = 0;
		barMax = paraThreshold;
		barValue = paraValue - (paraRewards * paraThreshold);
		
		if (myReputation_Config.Debug == true) then
			myReputation_ChatMsg(name..' '..paraValue..' '..paraThreshold..' '..paraRewards);
		end

		factionStandingText = "Paragon";
	end

	local isMajorFaction = factionID and C_Reputation.IsMajorFaction(factionID);
	local renownLevel;

	if (isMajorFaction) then
		local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID);
		barMin, barMax = 0, majorFactionData.renownLevelThreshold;
		local isCapped = C_MajorFactions.HasMaximumRenown(factionID);
		barValue = isCapped and majorFactionData.renownLevelThreshold or majorFactionData.renownReputationEarned or 0;
		renownLevel = majorFactionData.renownLevel;

		factionStandingText = "Renown "..renownLevel;
	end

	--Normalize Values
	barMax = barMax - barMin;
	barValue = barValue - barMin;
	barMin = 0;
	local friendTextLevel = reputationInfo.reaction;
	
	return barMax, barMin, barValue, isParagon, paraRewards, factionStandingText, isFriendshipFaction, isFollower, friendTextLevel, isMajorFaction, renownLevel;
end

-- Reputation frame
function myReputation_ReputationFrame_InitReputationRow(factionRow, elementData)
	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg("ReputationFrame_InitReputationRow");
	end
	
	lOriginal_ReputationFrame_InitReputationRow(factionRow, elementData);
	
	local factionIndex = elementData.index;
	local factionContainer = factionRow.Container;
	local factionBar = factionContainer.ReputationBar;
	local factionButton = factionContainer.ExpandOrCollapseButton;
	local factionStanding = factionBar.FactionStanding;
	
	local info = myReputation_Explode(myReputation_Config.Info, ',');
	local tooltip = myReputation_Explode(myReputation_Config.Tooltip, ',');
	
	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex);
	local isParagon, paraRewards, factionStandingText, isFollower, isMajorFaction, renownLevel;
	
	if ((factionStanding:GetText() ~= nil) and (not isHeader or hasRep)) then
		barMax, barMin, barValue, isParagon, paraRewards, factionStandingText, isFriendshipFaction, isFollower, _, isMajorFaction, renownLevel = myReputation_GetReputationDetails(name, factionID, standingID, barMin, barMax, barValue);
		
		--Normalize Values
		barMax = barMax - barMin;
		barValue = barValue - barMin;
		barMin = 0;

		local difference = 0;

		-- guild name was not available on login
		if (mySessionReputations[name] == nil and guildName ~= nil and name == guildName) then
			bakName = name;
			name = GUILD_REPUTATION;
		end

		if (isMajorFaction) then
			standingID = renownLevel;
		end

		if (mySessionReputations[name]) then
			-- No change in standing
			if (mySessionReputations[name].standingID == standingID) then
				difference = barValue - mySessionReputations[name].barValue;
			-- Reputation went up and reached next standing
			elseif (mySessionReputations[name].standingID < standingID) then
				if (isMajorFaction) then
					difference = barValue + ((standingID - mySessionReputations[name].standingID) * mySessionReputations[name].barMax) - mySessionReputations[name].barValue;
				else
					difference = barValue + mySessionReputations[name].barMax - mySessionReputations[name].barValue;
				end
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
				if (barMax > 0) then
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
		factionRow.rolloverText = HIGHLIGHT_FONT_COLOR_CODE..factionTooltip..FONT_COLOR_CODE_CLOSE;
	end
end

-- Chat messages (event UPDATE_FACTION)
function myReputation_Factions_Update()
	local numFactions = GetNumFactions();
	local factionIndex, factionStanding, factionBar, factionHeader, color;
	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus;
	local barMax, barMin, barValue;
	local RepRemains, RepRepeats, RepBefore, RepActual, RepNext;
	local isParagon, paraRewards, factionStandingText, isFollower;
	local friendTextLevel, isMajorFaction, renownLevel;
	local maxRank = 8;

	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg("myReputation_Factions_Update - Factions "..numFactions);
	end
    
	for factionIndex=1, numFactions, 1 do
		name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex);

		if (not isHeader or hasRep) then
			if (myReputation_Config.Debug == true) then
				myReputation_ChatMsg("Checking "..name);
			end
			
			barMax, barMin, barValue, isParagon, paraRewards, factionStandingText, isFriendshipFaction, isFollower, friendTextLevel, isMajorFaction, renownLevel = myReputation_GetReputationDetails(name, factionID, standingID, barMin, barMax, barValue);

			--Normalize Values
			barMax = barMax - barMin;
			barValue = barValue - barMin;
			barMin = 0;

			if (myReputations[name]) then
				if (myReputation_Config.Debug == true) then
					myReputation_ChatMsg("myReputations[name].standingID/standingID: "..myReputations[name].standingID.."/"..standingID);
				end
				
				if (isFriendshipFaction) then
					if isFollower then
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
					if (standingID ~= 1) then
						RepBefore = _G["FACTION_STANDING_LABEL"..standingID-1];
					end
					RepActual = _G["FACTION_STANDING_LABEL"..standingID];
					if (standingID ~= maxRank) then
						RepNext = _G["FACTION_STANDING_LABEL"..standingID+1];
					end
					if (isParagon) then
						-- Starting with Paragon 0 (0 Rewards)
						RepActual = "Paragon "..(paraRewards);
						RepNext = "Paragon "..(paraRewards+1);
						maxRank = standingID + 1;
					elseif (isMajorFaction) then
						RepActual = "Renown "..renownLevel;
						RepNext = "Renown "..(renownLevel+1);
						standingID = renownLevel;
						local isCapped = C_MajorFactions.HasMaximumRenown(factionID);
						maxRank = (isCapped and renownLevel) or (renownLevel + 1);
					end
				end

				local RawTotal = 0;

				-- No change in standing
				if (myReputations[name].standingID == standingID) then
					if (myReputation_Config.Debug == true) then
						myReputation_ChatMsg("No change in standing");
					end
					
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
					if (myReputation_Config.Debug == true) then
						myReputation_ChatMsg("Reputation went up and reached next standing");
					end
					
					RepRemains = barMax - barValue;
					if (isMajorFaction) then
						RawTotal = barValue + ((standingID - myReputations[name].standingID) * myReputations[name].barMax) - myReputations[name].barValue;
					else
						RawTotal = barValue + myReputations[name].barMax - myReputations[name].barValue;
					end
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
					if (myReputation_Config.Debug == true) then
						myReputation_ChatMsg("Reputation went down and reached next standing");
					end
					
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

			if (isMajorFaction) then
				myReputations[name].standingID = renownLevel;
			else
				myReputations[name].standingID = standingID;
			end
			myReputations[name].barValue = barValue;
			myReputations[name].barMax = barMax;
		end
	end
end
