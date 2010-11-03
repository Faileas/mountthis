--[[--
While I wasn't the first to want the addon, I decided to write one that worked 
the way I wanted.  I credit the Livestock (Recompense - Uldum(US)) and 
BlazzingSaddles (Alestane) authors for the help they provided in understanding
the new functions, even if they don't know.
--]]--

BINDING_HEADER_MOUNTTHIS = "MountThis";
BINDING_NAME_MOUNTRANDOM = "Random Mount";

MountThis = LibStub("AceAddon-3.0"):NewAddon("MountThis", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0");
-- svn:keywords Revision needs to be set, but not easy with TortoiseSVN on Windows
MountThis.version = tonumber(strmatch("$Revision$", "%d+"));
MountThis.reqVersion = MountThis.version;
MountThis.optionsFrames = {};
MountThisSettings =
{
	version = MountThis.version,
	Mounts = {},
	debug = 0,
	chatFrame = 1,
	dontUseLastMount = false,
	dismountIfMounted = true,
	exitVehicle = true,
	mountLand = true;
	mountLandKey = 0;
};
MountThisSettingsDefaults = MountThisSettings;
MountThisVariablesLoaded = false;
MountThis.lastMountUsed = nil;
MountThis.PlayerAlive = false;

local options =
{
	name = 'MountThis',
	type = 'group',
	args =
	{
		list =
		{
			type = 'execute',
			name = 'list',
			desc = 'List all mounts known to MountThis',
			func = function() MountThis:ListMounts(true) end,
		},
		update = 
		{
			type = 'execute',
			name = 'Update',
			desc = 'Force update all mounts',
			func = function() MountThis:UpdateMounts(true) end,
			width = 'full',
		},
		version =
		{
			type = 'execute',
			name = 'Version',
			desc = 'Show MountThis version',
			order = 2,
			func = function() MountThis:Communicate("You are using MountThis version "..tostring(MountThis.version)) end,
			--hidden = guiHidden,
			width = 'full',
		},
		dismountIfMounted =
		{
			order = 1,
			type = 'toggle',
			name = 'Dismount',
			desc = 'Make MountThis dismount if used while mounted instead of attempting to remount',
			get = function() return MountThisSettings.dismountIfMounted end,
			set = function(info, value) MountThisSettings.dismountIfMounted = value end,
			width = 'full',
		},
		options =
		{
			type = 'execute',
			name = 'options',
			desc = 'Open configuration options window',
			func = function() InterfaceOptionsFrame_OpenToCategory(MountThis.optionsFrames.General) end
		},
		config =
		{
			type = 'execute',
			name = 'options',
			desc = 'Open configuration options window',
			func = function() InterfaceOptionsFrame_OpenToCategory(MountThis.optionsFrames.General) end
		},
		debug =
		{
			type = 'execute',
			name = 'options',
			desc = 'Open configuration options window',
			func = function() InterfaceOptionsFrame_OpenToCategory(MountThis.optionsFrames.Debugging) end
		},

		-- These are the options for the Blizzard frames
		General =
		{
			cmdHidden = true,
			type = 'group',
			name = 'General',
			desc = 'General',
			args =
			{
				dismountIfMounted =
				{
					order = 1,
					type = 'toggle',
					name = 'Dismount',
					desc = 'Make MountThis dismount if used while mounted instead of attempting to remount',
					get = function() return MountThisSettings.dismountIfMounted end,
					set = function(info, value) MountThisSettings.dismountIfMounted = value end,
					width = 'full',
				},
				exitVehicle =
				{
					order = 2,
					type = 'toggle',
					name = 'Exit Vehicle',
					desc = 'Make MountThis dismount if used while in a vehicle',
					get = function() return MountThisSettings.exitVehicle end,
					set = function(info, value) MountThisSettings.exitVehicle = value end,
					width = 'full',
				},
				--unShapeshift =
				--{
				--	order = 3,
				--	type = 'toggle',
				--	name = 'Cancel Shapeshift',
				--	desc = 'Make MountThis cancel a shapeshift form',
				--	get = function() return MountThisSettings.unShapeshift end,
				--	set = function(info, value) MountThisSettings.unShapeshift = value end,
				--	width = 'full',
				--},
				mountLand =
				{
					order = 4,
					type = 'toggle',
					name = 'Use modifier for non-flying mount in flyable zone',
					desc = 'Use a modifier to make MountThis use a non-flying mount when a flyable zone',
					get = function() return MountThisSettings.mountLand end,
					set = function(info, value) MountThisSettings.mountLand = value end,
					width = 'full'
				},
				dontUseLastMount =
				{
					order = 5,
					type = 'toggle',
					name = 'Don\'t use last mount',
					desc = 'MountThis will not use the last mount used',
					get = function() return MountThisSettings.dontUseLastMount end,
					set = function(info, value) MountThisSettings.dontUseLastMount = value end,
					width = 'full'
				},
				mountLandKey =
				{
					order = 6,
					type = 'select',
					name = 'Land Mount Key',
					desc = '',
                                        values = function(info)
                                            local mount_land_keys = {};
                                            mount_land_keys[0] = 'Alt';
                                            mount_land_keys[1] = 'Control';
                                            mount_land_keys[2] = 'Shift';
                                            return mount_land_keys end,
                                        get = function() return MountThisSettings.mountLandKey end,
                                        set = function(info, key)
                                            MountThisSettings.mountLandKey = key;
                                            if MountThisSettings.debug >=1 then
                                                MountThis:Communicate('MountLandKey = '..tostring(MountThisSettings.mountLandKey));
                                            end
                                            return MountThisSettings.mountLandKey
                                        end,
				},
				--mounts = 
				--{
				--	order = 6,
				--	type = 'multiselect',
				--	name = 'Mounts',
				--	desc = '',
				--	values = function(info)
				--		local mount_names = {};
				--		for mount_name in pairs(MountThisSettings.Mounts) do
				--			mount_names[mount_name] = mount_name;
				--		end
				--		return mount_names;
				--	end,
				--	get = function(info, key)
				--		return MountThisSettings.Mounts[key].use_mount;
				--	end,
				--	set = function(info, key, value)
				--		MountThisSettings.Mounts[key].use_mount = value;
				--		return MountThisSettings.Mounts[key].use_mount;
				--	end,
				--	width = 'full',
				--},
			},
		},
		Debugging =
		{
			cmdHidden = true,
			type = 'group',
			name = 'Debugging',
			desc = 'Debugging commands for MountThis',
			order = -1,
			args =
			{
				debug =
				{
					order = 1,
					type = 'range',
					name = 'Debug',
					desc = 'Toggle debugging',
					min = 0,
					max = 5,
					step = 1,
					get = function() return MountThisSettings.debug end,
					set = function(info, debugLevel) MountThisSettings.debug = debugLevel end,
					width = 'full',
				},
				chatFrame =
				{
					order = 2,
					type = 'range',
					name = 'Debug Output to Chat Frame #',
					desc = 'Select which chat frame you want to send debug output to.',
					min = 1,
					max = NUM_CHAT_WINDOWS,
					step = 1,
					get = function() return MountThisSettings.chatFrame end,
					set = function(info, chatFrame) MountThisSettings.chatFrame = chatFrame end,
					width = 'full',
				},
				chatFramenum =
				{
					type = 'execute',
					name = 'Chat Frame Number',
					desc = 'Show MountThis version',
					order = 3,
					func = function() 
						for i = 1, NUM_CHAT_WINDOWS do
							getglobal("ChatFrame"..i):AddMessage("This is chatFrame"..i, 255, 255, 255, 0);
						end 
					end,
					--hidden = guiHidden,
					width = 'full',
				},
				version =
				{
					type = 'execute',
					name = 'Version',
					desc = 'Show MountThis version',
					order = 4,
					func = function() MountThis:Communicate("You are using MountThis version " .. MountThis.version) end,
					--hidden = guiHidden,
					width = 'full',
				},
				list = 
				{
					type = 'execute',
					name = 'List',
					desc = 'List all mounts known to MountThis',
					order = 5,
					func = function() MountThis:ListMounts(true) end,
					--hidden = guiHidden,
					width = 'full',
				},
				update = 
				{
					type = 'execute',
					name = 'Update',
					desc = 'Force update all mounts',
					order = 6,
					func = function() MountThis:UpdateMounts(true) end,
					--hidden = guiHidden,
					width = 'full',
				},
				mounts = 
				{
					order = 7,
					type = 'multiselect',
					name = 'Mounts',
					desc = '',
					values = function(info)
						local mount_names = {};
						for mount_name in pairs(MountThisSettings.Mounts) do
							mount_names[mount_name] = mount_name;
						end
						return mount_names;
					end,
					get = function(info, key)
						return MountThisSettings.Mounts[key].use_mount;
					end,
					set = function(info, key, value)
						MountThisSettings.Mounts[key].use_mount = value;
						return MountThisSettings.Mounts[key].use_mount;
					end,
					width = 'full',
				},

			}
		}
	}
}

-- This function could be used to make comments when summoning if I was so inclined
function MountThis:Communicate(str)
	-- Do this because Marinna is a noob
	if MountThisSettings.chatFrame == nil then MountThisSettings.chatFrame = MountThisSettingsDefaults.chatFrame; end
	self:Print(getglobal("ChatFrame"..MountThisSettings.chatFrame), str);
end

function MountThis:OnInitialize()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("MountThis", options, {"MountThis"});
	local ACD3 = LibStub("AceConfigDialog-3.0");
	MountThis.optionsFrames.General = ACD3:AddToBlizOptions('MountThis', nil, nil, 'General');
	MountThis.optionsFrames.Debugging = ACD3:AddToBlizOptions('MountThis', 'Debugging', 'MountThis', 'Debugging');

	MountThis:RegisterChatCommand("mountrandom", "MountRandom");
	MountThis:RegisterChatCommand("mount", "Mount");
	MountThis:RegisterEvent("VARIABLES_LOADED");
	MountThis:RegisterEvent("COMPANION_LEARNED");
	MountThis:RegisterEvent("PLAYER_ENTERING_WORLD");
	MountThis:RegisterEvent("PLAYER_ALIVE");
	MountThis:SpellBookMountCheckboxes()
end

function MountThis:VARIABLES_LOADED(addon_name)
	if addon_name == "MountThis" then
		if MountThisSettings.debug >= 3 then MountThis:Communicate("EVENT: VARIABLES_LOADED"); end
		MountThisVariablesLoaded = true;
		if MountThisSettings.debug >= 1 then MountThis:Communicate("Variables loaded"); end
	end
end

function MountThis:COMPANION_LEARNED()
	if MountThisSettings.debug >= 3 then MountThis:Communicate("EVENT: COMPANION_LEARNED"); end
	MountThis:UpdateMounts(true);
end

function MountThis:PLAYER_ENTERING_WORLD()
	-- I do this to make sure variables get assigned correctly.  I don't know of another way at this point besides deleting old variables.
	if MountThisSettings.debug >= 3 then MountThis:Communicate("EVENT: PLAYER_ENTERING_WORLD"); end
	if MountThisVariablesLoaded == false then return end
	if tonumber(MountThisSettings.version) == nil or tonumber(MountThisSettings.version) ~= tonumber(MountThis.version) then
		MountThisSettings.version = MountThis.version;
		if MountThisSettings.mountLand == nil then MountThisSettings.mountLand = MountThisSettingsDefaults.mountLand; end
		if MountThisSettings.mountLandKey == nil then MountThisSettings.mountLandKey = MountThisSettingsDefaults.mountLandKey; end
		if MountThisSettings.exitVehicle == nil then MountThisSettings.exitVehicle = MountThisSettingsDefaults.exitVehicle; end
		if MountThisSettings.unShapeshift == nil then MountThisSettings.unShapeshift = MountThisSettingsDefaults.unShapeshift; end
		if MountThisSettings.dontUseLastMount == nil then MountThisSettings.dontUseLastMount = MountThisSettingsDefaults.dontUseLastMount; end
	end
MountThis:SpellBookMountCheckboxes()
end

function MountThis:PLAYER_ALIVE()
	if MountThisSettings.debug >= 3 then MountThis:Communicate("EVENT: PLAYER_ALIVE"); end
	MountThis:UpdateMounts(true);
end

function MountThis:UpdateMounts(force_update)
	for companion_index = 1, GetNumCompanions("MOUNT") do
		local _,mount_name,spellID = GetCompanionInfo("MOUNT",companion_index);
		local current_mount = MountParser:ParseMount(companion_index)
		-- We have the mount in the table already. Use the saved use_mount value
		if MountThisSettings.Mounts[mount_name] ~= nil then
			current_mount.use_mount = MountThisSettings.Mounts[mount_name].use_mount;
		end
		MountThisSettings.Mounts[mount_name] = current_mount
	end

end

function MountThis:ListMounts(request_short)
	MountThis:Communicate("ListMounts:");
	for name, data in pairs(MountThisSettings.Mounts) do
		MountThis:Communicate("- "..name..
						" - use: "..tostring(data.use_mount)..
						" - fly: "..tostring(data.flying)..
						" - prof: "..tostring(data.require_skill).."@"..tostring(data.require_skill_level)..
						" - skill: "..tostring(data.riding_skill_based)..
						" - pass: "..tostring(data.passengers));
	end
end


--[[
There is a bug that I can't get around with Krasus' Landing.
If you receive an error of "You can't use that here", leave the subzone and return.
]]--
function MountThis:Flyable()
	-- IsFlyableArea does not check if the player can fly, just if the zone is flagged for flying... except Wintergrasp
	if IsFlyableArea() or (GetRealZoneText() == "Wintergrasp" and GetWintergraspWaitTime() ~= nil) then
		if GetCurrentMapContinent() == 4 and GetSpellInfo("Cold Weather Flying") ~= nil then return true; end
		if GetCurrentMapContinent() == 1 or GetCurrentMapContinent() == 2 and GetSpellInfo("Flight Master's License") ~= nil then return true; end
		return true;
	end
	return false;
end

-- The shapeshift forms aren't counted in the random at this time
-- TODO: Figure out how to create/use secure buttons to allow shapeshift forms
function MountThis:MountRandom()
	-- Do the dismount dance if we need to before we even bother with the rest of this stuff
	if IsMounted() and MountThisSettings.dismountIfMounted then
		if MountThisSettings.debug >= 3 then MountThis:Communicate('Is Mounted: Dismounting'); end
		return MountThis:Dismount() 
	elseif CanExitVehicle() and MountThisSettings.exitVehicle then
		if MountThisSettings.debug >= 3 then MountThis:Communicate('Is in Vehicle: Dismounting'); end
		return MountThis:Dismount()
	end

	-- Try to summon a flying mount first, unless asked not to do so
	summon_flying = true;
	
	-- This is where we add the ability for modifier buttons to choose flying/slow mounts
	if MountThisSettings.mountLand == true then
		if MountThisSettings.debug >= 2 then
			MountThis:Communicate('MountLandKey set to '..tostring(MountThisSettings.mountLandKey));
			MountThis:Communicate("Alt: "..tostring(IsAltKeyDown()).." Control: "..tostring(IsControlKeyDown()).. " Shift: "..tostring(IsShiftKeyDown()));
		end
		if MountThisSettings.mountLandKey == 0 and IsAltKeyDown() then
			summon_flying = false
		elseif MountThisSettings.mountLandKey == 1 and IsControlKeyDown() then
			summon_flying = false
		elseif MountThisSettings.mountLandKey == 2 and IsShiftKeyDown() then
			summon_flying = false
		end
	end
	-- Also can't get on flying mounts when swimming.
	if IsSwimming() then 
		if MountThisSettings.debug >= 2 then MountThis:Communicate("You're swimming, so we must select a land mount."); end
		summon_flying = false;
	end
	
	if MountThis:Flyable() and summon_flying then
		if MountThis:Mount(MountThis:Random(true)) == true then return true; end
	end
	if MountThis:Mount(MountThis:Random(false)) == true then return true; end
	return false;
end

-- Give a mount ID and I'll use it, otherwise, it's a random mount
function MountThis:Mount(companionID)
	if MountThisSettings.debug >= 4 then MountThis:Communicate("Trying to mount "..tostring(companionID)); end

	-- Do the dismount dance if we need to before we even bother with the rest of this stuff
	if IsMounted() and MountThisSettings.dismountIfMounted then
		if MountThisSettings.debug >= 3 then MountThis:Communicate('Is Mounted: Dismounting'); end
		return MountThis:Dismount() 
	elseif CanExitVehicle() and MountThisSettings.exitVehicle then
		if MountThisSettings.debug >= 3 then MountThis:Communicate('Is in Vehicle: Dismounting'); end
		return MountThis:Dismount()
	end
	
	if companionID ~= nil and companionID ~= "" then
		CallCompanion(MOUNT, companionID);
		MountThis.lastMountUsed = companionID;
		return true;
	end

	if MountThisSettings.debug >= 4 then MountThis:Communicate("companionID not supplied"); end
	return false;
end

-- Why bother with this one?  I don't know either.
function MountThis:Dismount()
	-- If you're in a vehicle, leave the vehicle instead
	if IsUsingVehicleControls() then VehicleExit() end;
	if CanExitVehicle() then VehicleExit() end;
	
	-- Dismount evidently doesn't return true if you dismount
	Dismount();
	return true;
end

--[[--
Return the name of random mount, given certain variables
- rFlying: true/false
- rRequireSkill: Engineering/Tailoring
- rRidingSkill: true/false
- rPassengers: # of passengers
--]]--
function MountThis:Random(rFlying, rRequireSkill, rRidingSkill, rPassengers)
	if MountThisSettings.debug > 1 then
		MountThis:Communicate("Random mount flags: "..tostring(rFlying).." "..tostring(rSpeed).." "..tostring(rRequireSkill).." "..tostring(rRidingSkill))
	end

	if rFlying == false then rFlying = nil end
	local ZoneNames = { GetMapZones(4) } ;
	local canFlyInNorthrend = false
	local inNorthrend = false;
	-- TODO: Get this section tested. I'm pretty sure AQ mounts are not functioning
	local inAhnQiraj = GetZoneText() == "Ahn'Qiraj";
	for index, zoneName in pairs(ZoneNames) do 
		if zoneName == GetZoneText() then 
			inNorthrend = true; 
		end 
	end
	if rFlying == true and inNorthrend == true then
		if MountThis:CheckSkill("Cold Weather Flying") ~= nil then canFlyInNorthrend = true; end
	end
	
	-- Yes, I decided to go through the whole list of mounts and do the checking that way...
	mount_table = MountThisSettings.Mounts;
	-- Create a temporary table that uses an integer index rather than dictionary
	-- This already makes me think I should rewrite the table structures...
	local possible_mounts = {};
	for mount_name in pairs(mount_table) do
		if MountThisSettings.debug >= 3 then MountThis:Communicate("Checking "..mount_name.." for use"); end
		-- If we have it set to not use a mount, don't do anything else
		if mount_table[mount_name].use_mount == true then
			-- Easier to say it is valid and then invalidate it (coding-wise anyway)
			local matches_requirements = true;

			-- Check each of the requirements to see if they're valid for this random search
			-- If it's nil, then we don't care.  Otherwise, check the value
			if rFlying ~= true and mount_table[mount_name].flying == true then 
				if MountThisSettings.debug >= 5 then MountThis:Communicate("Flying "..tostring(rFlying).." and "..tostring(mount_table[mount_name].flying)); end
				matches_requirements = false
			elseif rFlying == true and mount_table[mount_name].flying ~= true then 
				if MountThisSettings.debug >= 5 then MountThis:Communicate("Flying "..tostring(rFlying).." and "..tostring(mount_table[mount_name].flying)); end
				matches_requirements = false
			elseif rRequireSkill ~= nil and rRequireSkill ~= mount_table[mount_name].required_skill then
				if MountThisSettings.debug >= 5 then MountThis:Communicate("RequireSkill "..tostring(rRequireSkill).." and "..tostring(mount_table[mount_name].required_skill));  end
				matches_requirements = false
			elseif rRidingSkill ~= nil and rRidingSkill ~= mount_table[mount_name].riding_skill_based then
				if MountThisSettings.debug >= 5 then MountThis:Communicate("RidingSkill "..tostring(rRidingSkill).." and "..tostring(mount_table[mount_name].riding_skill_based)); end
				matches_requirements = false
			elseif rPassengers ~= nil and rPassengers ~= mount_table[mount_name].passengers then
				if MountThisSettings.debug >= 5 then MountThis:Communicate("Passengers "..tostring(rPassengers).." and "..tostring(mount_table[mount_name].passengers)); end
				matches_requirements = false 
			            
			-- Cold Weather Flying yet?
			elseif inNorthrend and not canFlyInNorthrend and rFlying == true then
				if MountThisSettings.debug >= 5 then MountThis:Communicate("Flying requested, but in Northrend without CWF"); end
				matches_requirements = false
			-- Will this fix the AQ problem I've had?
			elseif mount_table[mount_name].ahnqiraj == true and not inAhnQiraj then
				if MountThisSettings.debug >= 5 then MountThis:Communicate("WTF: Old AQ reference"); end
				if mount_table[mount_name].zone == nil then mount_table[mount_name].zone = "Temple of Ahn'Qiraj" end
				matches_requirements = false
			-- update to "zone restricted" mount determination
			elseif mount_table[mount_name].zone ~= nil then
				if mount_table[mount_name].zone == "Temple of Ahn'Qiraj" and not inAhnQiraj then
					if MountThisSettings.debug >= 5 then MountThis:Communicate("WTF Ahn'Qiraj"); end
					matches_requirements = false
				end
				if mount_table[mount_name].zone == "Vashj'ir" and not inVashjir then
					if MountThisSettings.debug >= 5 then MountThis:Communicate("WTF Vashj'ir"); end
					matches_requirements = false
				end
			-- TODO: Debug this skill checking section
			elseif mount_table[mount_name].required_skill ~= nil 
				and MountThis:CheckSkill(mount_table[mount_name].required_skill) < mount_table[mount_name].required_skill then
				if MountThisSettings.debug >= 3 then MountThis:Communicate("This mount needs a profession skill!"); end
				if MountThisSettings.debug >= 5 then MountThis:Communicate("WTF RS"); end
				matches_requirements = false
			end

			if matches_requirements then
				if MountThisSettings.debug >= 2 then MountThis:Communicate(" - Added "..mount_name.." to potential mounts"); end
				tinsert(possible_mounts, mount_table[mount_name].index);
			end
		else
			if MountThisSettings.debug >= 3 then MountThis:Communicate(mount_name.." not selected for use"); end
		end
	end

	-- If we don't have any possible mounts, the result is nil
	-- Hopefully anyone asking for a mount knows for what they're asking
	if #possible_mounts == 0 then
		if MountThisSettings.debug > 1 then MountThis:Communicate("Your random mount query failed"); end
		return nil;
	end

	-- Allow the user to say they don't want the last used mount
	if MountThisSettings.debug >= 3 then MountThis:Communicate("dontUseLastMount: "..tostring(MountThisSettings.dontUseLastMount)..", lastMountUsed: "..tostring(MountThis.lastMountUsed)); end
	if #possible_mounts > 1 and MountThisSettings.dontUseLastMount and MountThis.lastMountUsed ~= nil then
		for poss_index, mount_index in pairs(possible_mounts) do
			if possible_mounts[poss_index] == MountThis.lastMountUsed then tremove(possible_mounts, poss_index) end
		end
	end
  
	local pmindex = random(#possible_mounts)
	local chosen_mount = possible_mounts[pmindex];
	if MountThisSettings.debug >= 3 then MountThis:Communicate("PMIndex: "..tostring(pmindex)..", MountIndex: "..tostring(chosen_mount)); end
	local _,chosen_mount_name = GetCompanionInfo("MOUNT",chosen_mount);
	if MountThisSettings.debug >= 1 then MountThis:Communicate("Choosing mount "..chosen_mount_name.." from "..tostring(#possible_mounts).." possible mounts."); end
	return chosen_mount;

	--return possible_mounts[random(#possible_mounts)];
end

-- Return the value of a specific skill, nil if you don't have it
function MountThis:CheckSkill(check_skill_name)
	if MountThisSettings.debug >= 2 then MountThis:Communicate("Checking skill "..check_skill_name); end
	local spellName = GetSpellInfo(check_skill_name);
	if spellName ~= nil then return true; end
	if MountThisSettings.debug > 1 then MountThis:Communicate("Skill: "..check_skill_name.." - not found"); end
	return nil;
end

function MountThis_MountCheckButton(self, button, down)
	ButtonNumber = strmatch(self:GetName(), "%d+")
	if ButtonNumber ~= nil then
		_, MountName = GetCompanionInfo("MOUNT", ((SpellBook_GetCurrentPage()-1)*NUM_COMPANIONS_PER_PAGE)+ButtonNumber)
		MountThisSettings.Mounts[MountName].use_mount = self:GetChecked()
	end
end

function MountThis_UpdateCompanionFrame(self, event, ...)
	--This if statement is a test to make sure we only show the checkbuttons on the mounts, not the critters
	for ButtonNumber = 1, NUM_COMPANIONS_PER_PAGE do
		local MountThisButton = _G["MountThisCheckButton"..ButtonNumber]
		MountThisButton:Hide()
		if SpellBookCompanionsFrame.mode == "MOUNT" then
			_, MountName = GetCompanionInfo("MOUNT", ((SpellBook_GetCurrentPage()-1)*NUM_COMPANIONS_PER_PAGE)+ButtonNumber)
			if MountName ~= nil then
				MountThisButton:SetChecked(MountThisSettings.Mounts[MountName].use_mount)
				MountThisButton:Show()
			end
		end
	end
end

-- Hooking to tab buttons 3-5 should make sure we know when we've clicked on a companion frame
SpellBookFrameTabButton3:HookScript("OnClick", MountThis_UpdateCompanionFrame)
SpellBookFrameTabButton4:HookScript("OnClick", MountThis_UpdateCompanionFrame)
SpellBookFrameTabButton5:HookScript("OnClick", MountThis_UpdateCompanionFrame)

-- Need to hook to the page buttons too
SpellBookPrevPageButton:HookScript("OnClick", MountThis_UpdateCompanionFrame)
SpellBookNextPageButton:HookScript("OnClick", MountThis_UpdateCompanionFrame)

-- Not sure we need this at the moment, but I'm leaving them for now :P
SpellBookFrame:HookScript("OnShow", MountThis_UpdateCompanionFrame)
SpellBookFrame:HookScript("OnHide", MountThis_UpdateCompanionFrame)


function MountThis:SpellBookMountCheckboxes()
	--MountThis:Communicate("Trying to update: "..tostring(event))
	for ButtonNumber = 1, NUM_COMPANIONS_PER_PAGE do
		local frame = CreateFrame("CheckButton", "MountThisCheckButton"..ButtonNumber, _G["SpellBookCompanionButton"..ButtonNumber], "UICheckButtonTemplate")
		frame:ClearAllPoints()
		frame:SetPoint("TOPRIGHT", 0, 0)
		frame:SetScale(.5)
		frame:SetScript("OnClick", MountThis_MountCheckButton)
	end
	MountThis_UpdateCompanionFrame()
end
