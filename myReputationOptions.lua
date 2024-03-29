-- Temporary Configuration Variable
local myReputation_TmpInWorld = false;
local myReputation_TmpInit = false;
local myReputation_TmpOptions = { };

----------------------------------------------------------------------
-- OnFoo
----------------------------------------------------------------------

function myReputation_OptionsOnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	
	self.name = MYREP_NAME;
	self.refresh = myReputation_OptionsRefresh;
	self.okay = myReputation_OptionsOkay;
	InterfaceOptions_AddCategory(self);
	
	myReputation_OptionsPanelTitle:SetText(format(MYREP_MSG_FORMAT,MYREP_NAME,MYREP_VERSION));
end

function myReputation_OptionsOnEvent(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		if (myReputation_Config.Debug == true) then
			myReputation_ChatMsg('OnEvent');
		end
		myReputation_TmpInWorld = true;
	end
end
	
function myReputation_OptionsOnShow()
	-- Copy the values to the temporary options
	if (myReputation_TmpInWorld == true) then
		myReputation_TmpInit = true;
		myReputation_TmpOptions.Info = myReputation_Explode(myReputation_Config.Info, ',');
		myReputation_TmpOptions.Tooltip = myReputation_Explode(myReputation_Config.Tooltip, ',');
		myReputation_OptionsPanelFrame:SetValue(myReputation_Config.Frame);
		if (myReputation_Config.Debug == true) then
			myReputation_ChatMsg('Copy of tmp options');
		end
	end

	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg('OnShow');
		myReputation_DisplayStatus();
		myReputation_ChatMsg(format(
			MYREP_MSG_FORMAT,
			'tmpInfo',
			myReputation_TableImplode(myReputation_TmpOptions.Info, ',')
		));
		myReputation_ChatMsg(format(
			MYREP_MSG_FORMAT,
			'tmpTooltip',
			myReputation_TableImplode(myReputation_TmpOptions.Tooltip, ',')
		));
	end
end

function myReputation_OptionsOnHide()
	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg('OnHide');
		myReputation_DisplayStatus();
		myReputation_ChatMsg(format(
			MYREP_MSG_FORMAT,
			'tmpInfo',
			myReputation_TableImplode(myReputation_TmpOptions.Info, ',')
		));
		myReputation_ChatMsg(format(
			MYREP_MSG_FORMAT,
			'tmpTooltip',
			myReputation_TableImplode(myReputation_TmpOptions.Tooltip, ',')
		));
	end
end

----------------------------------------------------------------------
-- Config Functions
----------------------------------------------------------------------

function myReputation_OptionsInitSlider(slider, low, high, step)
    local lowText = getglobal(slider:GetName().."Low");
    local highText = getglobal(slider:GetName().."High");
    
    if (myReputation_Config.Debug == true) then
        myReputation_ChatMsg("MyRep: Slider-Init, ChatFrames: "..high);
    end

    lowText:SetText(low);
    highText:SetText(high);
    slider:SetMinMaxValues(low, high);
    slider:SetValueStep(step);
end

function myReputation_OptionsUpdateSlider(slider, text)
	local val = math.floor(slider:GetValue());
	getglobal(slider:GetName().."Text"):SetText("|cffffd200"..text.." ("..val..")");
end

function myReputation_OptionsChangeText(option)
	local parent = option:GetParent():GetParent();
	local name = string.gsub( option:GetName(), parent:GetName(), '' );
	local bar, setting = myReputation_Strip(name, "_");
	local status = (option:GetChecked() and true) or false;
	
	-- Only change the temporary options
	if (status) then
		myReputation_TableAddVal(
			myReputation_TmpOptions[bar], setting
		);
	else
		myReputation_TableRemoveVal(
			myReputation_TmpOptions[bar], setting
		);
	end

	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg(format(
			MYREP_MSG_FORMAT,
			'tmp'..bar,
			myReputation_TableImplode(myReputation_TmpOptions[bar], ',')
		));
	end
end

----------------------------------------------------------------------
-- Other Functions
----------------------------------------------------------------------

function myReputation_Strip(text, delimiter)
 	if text then
 		local a, b = strfind(text, delimiter);
 		if a then
 			return strsub(text, 1, a - 1), strsub(text, b + 1);
 		else	
 			return text, '';
 		end
 	end
end

function myReputation_Explode(text, delimiter)
	local result = { };
    
	if (type(text) == 'string' and text ~= '' and text ~= nil) then
		local from = 1;
		local delim_from, delim_to = string.find(text, delimiter, from);
		while delim_from do
			table.insert(result, string.sub(text, from , delim_from - 1));
			from = delim_to + 1;
			delim_from, delim_to = string.find(text, delimiter, from);
		end
		if (string.sub(text, from) ~= '') then
			table.insert(result, string.sub(text, from));
		end
	end
    
	return result;
end

function myReputation_TableImplode(t, delimiter)
	local text = '';
    
	if (type(t) == 'table') then
		text = table.concat(t, delimiter);
	end
    
	return text;
end

function myReputation_TableSearchVal(t, val)
	local found = false;
	
	if (t == nil) then
		t = { };
	end
	
	for i,v in ipairs(t) do
		if (v == val) then
			found = i;
		end
	end
	
	return found;
end

function myReputation_TableAddVal(t, val)
	if (t == nil) then
		t = { };
	end
	
	local found = myReputation_TableSearchVal(t, val);

	if (found == false) then
		if (myReputation_Config.Debug == true) then
			myReputation_ChatMsg('add '..val);
		end
		table.insert(t, val);
	end
end

function myReputation_TableReplacePos(t, pos, val)
	if (t == nil) then
		t = { };
	end
	
	local found = myReputation_TableSearchVal(t, val);

	if (found == false) then
		if (myReputation_Config.Debug == true) then
			myReputation_ChatMsg('replace '..pos..' '..val);
		end
		if (pos > 0) then
			table.insert(t, tonumber(pos), val);
		end
	end
end

function myReputation_TableMoveVal(t, val)
	myReputation_TableRemoveVal(t, val);
	myReputation_TableAddVal(t, val);
end

function myReputation_TableRemoveVal(t, val)
	if (t == nil) then
		t = { };
	end
	
	local found = myReputation_TableSearchVal(t, val);

	if (found ~= false) then
		if (myReputation_Config.Debug == true) then
			myReputation_ChatMsg('remove '..val);
		end
		table.remove(t, found);
	end
end

----------------------------------------------------------------------
-- Panel Functions
----------------------------------------------------------------------

function myReputation_OptionsRefresh(self)
	local name = self:GetName();
	local info = myReputation_Explode(myReputation_Config.Info, ',');
	local tooltip = myReputation_Explode(myReputation_Config.Tooltip, ',');

	getglobal(name..'Enabled'):SetChecked(myReputation_Config.Enabled == true);
	getglobal(name..'Splash'):SetChecked(myReputation_Config.Splash == true);
	getglobal(name..'Blizz'):SetChecked(myReputation_Config.Blizz == true);
	getglobal(name..'More'):SetChecked(myReputation_Config.More == true);
	getglobal(name..'Frame'):SetValue(myReputation_Config.Frame);
	
	getglobal(name..'Info_Text'):SetChecked(
		myReputation_TableSearchVal(info, 'Text') ~= false
	);
	getglobal(name..'Info_Percent'):SetChecked(
		myReputation_TableSearchVal(info, 'Percent') ~= false
	);
	getglobal(name..'Info_Absolute'):SetChecked(
		myReputation_TableSearchVal(info, 'Absolute') ~= false
	);
	getglobal(name..'Info_Difference'):SetChecked(
		myReputation_TableSearchVal(info, 'Difference') ~= false
	);

	getglobal(name..'Tooltip_Text'):SetChecked(
		myReputation_TableSearchVal(tooltip, 'Text') ~= false
	);
	getglobal(name..'Tooltip_Percent'):SetChecked(
		myReputation_TableSearchVal(tooltip, 'Percent') ~= false
	);
	getglobal(name..'Tooltip_Absolute'):SetChecked(
		myReputation_TableSearchVal(tooltip, 'Absolute') ~= false
	);
	getglobal(name..'Tooltip_Difference'):SetChecked(
		myReputation_TableSearchVal(tooltip, 'Difference') ~= false
	);
		
	-- SHADOWLANDS-FIX
	local infoFrame = getglobal(name..'Info');
	infoFrame.backdropInfo = {
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		edgeSize = 16,
	};
	infoFrame:ApplyBackdrop();
	local tooltipFrame = getglobal(name..'Tooltip');
	tooltipFrame.backdropInfo = {
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		edgeSize = 16,
	};
	tooltipFrame:ApplyBackdrop();
end

function myReputation_OptionsOkay(self)
	-- Fired for all options not only of this addon
	if (myReputation_Config.Debug == true) then
		myReputation_ChatMsg('Okay clicked');
	end
	
	if (myReputation_TmpInWorld == true and myReputation_TmpInit == true) then
		local name = self:GetName();

		myReputation_Toggle((getglobal(name..'Enabled'):GetChecked() and true) or false);
		myReputation_Config.Splash = ((getglobal(name..'Splash'):GetChecked() and true) or false);
		myReputation_Config.Blizz = ((getglobal(name..'Blizz'):GetChecked() and true) or false);
		myReputation_Config.More = ((getglobal(name..'More'):GetChecked() and true) or false);
		
		local frame = getglobal(name..'Frame'):GetValue();
		if (myReputation_Config.Frame ~= frame and frame > 0) then
			myReputation_ChatMsg(frame);
			myReputation_ChatFrame_Change(0, frame);
		end
		
		-- Save the temporary options
		local option, status;
		
		local info = { };
		for i,v in ipairs(myReputation_TmpOptions.Info) do
			if (myReputation_Config.Debug == true) then
				myReputation_ChatMsg(name..'Info_'..v);
			end
			
			option = getglobal(name..'Info_'..v);
			status = (option:GetChecked() and true) or false;
			if (status) then
				myReputation_TableReplacePos(info, i, v);
			end
		end
		myReputation_Config.Info = myReputation_TableImplode(info, ',');
		
		local tooltip = { };
		for i,v in ipairs(myReputation_TmpOptions.Tooltip) do
			if (myReputation_Config.Debug == true) then
				myReputation_ChatMsg(name..'Tooltip_'..v);
			end
			
			option = getglobal(name..'Tooltip_'..v);
			status = (option:GetChecked() and true) or false;
			if (status) then
				myReputation_TableReplacePos(tooltip, i, v);
			end
		end
		myReputation_Config.Tooltip = myReputation_TableImplode(tooltip, ',');
	end
end