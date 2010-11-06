--[[--
While I wasn't the first to want the addon, I decided to write one that worked 
the way I wanted.  I credit the Livestock (Recompense - Uldum(US)) and 
BlazzingSaddles (Alestane) authors for the help they provided in understanding
the new functions, even if they don't know.
--]]--

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
			name = MOUNTTHIS_OPTION_LIST,
			desc = MOUNTTHIS_OPTION_LIST_DESC,
			func = function() MountThis:ListMounts(true) end,
		},
		update = 
		{
			type = 'execute',
			name = MOUNTTHIS_OPTION_FORCE_UPDATE,
			desc = MOUNTTHIS_OPTION_FORCE_UPDATE_DESC,
			func = function() MountThis:UpdateMounts(true) end,
			width = 'full',
		},
		version =
		{
			type = 'execute',
			name = MOUNTTHIS_OPTION_SHOW_VERSION,
			desc = MOUNTTHIS_OPTION_SHOW_VERSION_DESC,
			order = 2,
			func = function() MountThis:Communicate(MOUNTTHIS_OPTION_VERSION_STRING.." "..tostring(MountThis.version)) end,
			--hidden = guiHidden,
			width = 'full',
		},
		dismountIfMounted =
		{
			order = 1,
			type = 'toggle',
			name = MOUNTTHIS_OPTION_DISMOUNT_IF_MOUNTED,
			desc = MOUNTTHIS_OPTION_DISMOUNT_IF_MOUNTED_DESC,
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
			name = MOUNTTHIS_OPTION_OPEN_CONFIG,
			desc = MOUNTTHIS_OPTION_OPEN_CONFIG_DESC,
			func = function() InterfaceOptionsFrame_OpenToCategory(MountThis.optionsFrames.General) end
		},
		debug =
		{
			type = 'execute',
			name = MOUNTTHIS_OPTION_OPEN_CONFIG,
			desc = MOUNTTHIS_OPTION_OPEN_CONFIG_DEBUG_DESC,
			func = function()
				if MountThis.optionsFrames.Debugging ~= nil then
					InterfaceOptionsFrame_OpenToCategory(MountThis.optionsFrames.Debugging)
				else
					--MountThis:Communicate("Debugging not enabled. Modify OnInitialize() to enable.")
					DEFAULT_CHAT_FRAME:AddMessage("Debugging not enabled. Modify OnInitialize() to enable.")
				end
			end
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
					name = MOUNTTHIS_OPTION_DISMOUNT_IF_MOUNTED,
					desc = MOUNTTHIS_OPTION_DISMOUNT_IF_MOUNTED_DESC,
					get = function() return MountThisSettings.dismountIfMounted end,
					set = function(info, value) MountThisSettings.dismountIfMounted = value end,
					width = 'full',
				},
				exitVehicle =
				{
					order = 2,
					type = 'toggle',
					name = MOUNTTHIS_OPTION_EXIT_VEHICLE,
					desc = MOUNTTHIS_OPTION_EXIT_VEHICLE_DESC,
					get = function() return MountThisSettings.exitVehicle end,
					set = function(info, value) MountThisSettings.exitVehicle = value end,
					width = 'full',
				},
				mountLand =
				{
					order = 4,
					type = 'toggle',
					name = MOUNTTHIS_OPTION_MOUNT_LAND,
					desc = MOUNTTHIS_OPTION_MOUNT_LAND_DESC,
					get = function() return MountThisSettings.mountLand end,
					set = function(info, value) MountThisSettings.mountLand = value end,
					width = 'full'
				},
				dontUseLastMount =
				{
					order = 5,
					type = 'toggle',
					name = MOUNTTHIS_OPTION_DONT_USE_LAST_MOUNT,
					desc = MOUNTTHIS_OPTION_DONT_USE_LAST_MOUNT_DESC,
					get = function() return MountThisSettings.dontUseLastMount end,
					set = function(info, value) MountThisSettings.dontUseLastMount = value end,
					width = 'full'
				},
				mountLandKey =
				{
					order = 6,
					type = 'select',
					name = MOUNTTHIS_OPTION_MOUNT_LAND_KEY,
					desc = '',
                                        values = function(info)
                                            local mount_land_keys = {};
                                            mount_land_keys[0] = MOUNTTHIS_ALT;
                                            mount_land_keys[1] = MOUNTTHIS_CONTROL;
                                            mount_land_keys[2] = MOUNTTHIS_SHIFT;
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
			},
		},
		Debugging =
		{
			cmdHidden = true,
			type = 'group',
			name = MOUNTTHIS_OPTION_DEBUG_HEADER,
			desc = 'Debugging commands for MountThis',
			order = -1,
			args =
			{
				debug =
				{
					order = 1,
					type = 'range',
					name = MOUNTTHIS_OPTION_DEBUG_LEVEL,
					desc = MOUNTTHIS_OPTION_DEBUG_LEVEL_DESC,
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
					name = MOUNTTHIS_OPTION_CHATFRAME,
					desc = MOUNTTHIS_OPTION_CHATFRAME_DESC,
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
					name = MOUNTTHIS_OPTION_CHATFRAME_IDENTIFY,
					desc = MOUNTTHIS_OPTION_CHATFRAME_IDENTIFY_DESC,
					order = 3,
					func = function() 
						for i = 1, NUM_CHAT_WINDOWS do
							getglobal("ChatFrame"..i):AddMessage(MOUNTTHIS_OPTION_CHATFRAME_IDENTIFY_STRING..i, 255, 255, 255, 0);
						end 
					end,
					--hidden = guiHidden,
					width = 'full',
				},
				version =
				{
					type = 'execute',
					name = MOUNTTHIS_OPTION_SHOW_VERSION,
					desc = MOUNTTHIS_OPTION_SHOW_VERSION_DESC,
					order = 4,
					func = function() MountThis:Communicate(MOUNTTHIS_OPTION_VERSION_STRING.." " .. MountThis.version) end,
					--hidden = guiHidden,
					width = 'full',
				},
				list = 
				{
					type = 'execute',
					name = MOUNTTHIS_OPTION_LIST,
					desc = MOUNTTHIS_OPTION_LIST_DESC,
					order = 5,
					func = function() MountThis:ListMounts(true) end,
					--hidden = guiHidden,
					width = 'full',
				},
				update = 
				{
					type = 'execute',
					name = MOUNTTHIS_OPTION_FORCE_UPDATE,
					desc = MOUNTTHIS_OPTION_FORCE_UPDATE_DESC,
					order = 6,
					func = function() MountThis:UpdateMounts(true) end,
					--hidden = guiHidden,
					width = 'full',
				},
				mounts = 
				{
					order = 7,
					type = 'multiselect',
					name = MOUNTTHIS_OPTION_MOUNTS_HEADER,
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

function MountThis:Communicate(str)
	if MountThisSettings.chatFrame == nil then MountThisSettings.chatFrame = MountThisSettingsDefaults.chatFrame; end
	self:Print(getglobal("ChatFrame"..MountThisSettings.chatFrame), str);
end

function MountThis:OnInitialize()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("MountThis", options, {"MountThis"});
	local ACD3 = LibStub("AceConfigDialog-3.0");
	MountThis.optionsFrames.General = ACD3:AddToBlizOptions('MountThis', nil, nil, 'General');
	--MountThis.optionsFrames.Debugging = ACD3:AddToBlizOptions('MountThis', 'Debugging', 'MountThis', 'Debugging');

	MountThis:RegisterChatCommand("mountrandom", "MountRandom");
	MountThis:RegisterChatCommand("mount", "Mount");
	MountThis:RegisterEvent("VARIABLES_LOADED");
	MountThis:RegisterEvent("COMPANION_LEARNED");
	MountThis:RegisterEvent("PLAYER_ENTERING_WORLD");
	MountThis:RegisterEvent("PLAYER_ALIVE");
	MountThis:RegisterEvent("UNIT_AURA");
	MountThis:RegisterEvent("PLAYER_REGEN_ENABLED");
	MountThis:RegisterEvent("PLAYER_REGEN_DISABLED");
	MountThis:SpellBookMountCheckboxes()
end

function MountThis:VARIABLES_LOADED(addon_name)
	if addon_name == "MountThis" then MountThisVariablesLoaded = true; end
end

function MountThis:COMPANION_LEARNED()
	MountThis:UpdateMounts(true);
end
function MountThis:PLAYER_REGEN_ENABLED()
	MountThis:RegisterEvent("UNIT_AURA");
end
function MountThis:PLAYER_REGEN_DISABLED()
	MountThis:UnregisterEvent("UNIT_AURA");
end
function MountThis:UNIT_AURA()
	spellID = MountParser:ParseMountFromBuff()
	--if spellID ~= nil then MountParser:ParseMount(nil, spellID) end
	if spellID ~= nil then MountThis:UpdateMounts() end
end

function MountThis:PLAYER_ENTERING_WORLD()
	-- I do this to make sure variables get assigned correctly.  I don't know of another way at this point besides deleting old variables.
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
	MountThis:UpdateMounts(true);
end

function MountThis:UpdateMounts(force_update, clear_mounts)
	if clear_mounts ~= nil then MountThisSettings.Mounts = {}; end
	for companion_index = 1, GetNumCompanions("MOUNT") do
		local _,mount_name,spellID = GetCompanionInfo("MOUNT",companion_index);
		local current_mount = MountParser:ParseMount(companion_index)
		-- We have the mount in the table already. Use the saved use_mount value
		if current_mount == nil then MountThis:Communicate("Failed update on "..mount_name); return end
		if MountThisSettings.Mounts[mount_name] ~= nil then
			current_mount.use_mount = MountThisSettings.Mounts[mount_name].use_mount;
		end
		MountThisSettings.Mounts[mount_name] = current_mount
	end
end

function MountThis:ListMounts(request_short)
	MountThis:Communicate(MOUNTTHIS_LIST_MOUNTS_STRING);
	for name, data in pairs(MountThisSettings.Mounts) do
		MountThis:Communicate("- "..name..
			" - "..MOUNTTHIS_LIST_USE_MOUNT..": "..tostring(data.use_mount)..
			" - "..MOUNTTHIS_LIST_FLYING..": "..tostring(data.flying)..
			" - "..MOUNTTHIS_LIST_SWIMMING..": "..tostring(data.swimming)..
			" - "..MOUNTTHIS_LIST_PROFESSION..": "..tostring(data.require_skill).."@"..tostring(data.require_skill_level)..
			" - "..MOUNTTHIS_LIST_PASSENGERS..": "..tostring(data.passengers));
	end
end


--[[
There is a bug that I can't get around with Krasus' Landing.
If you receive an error of "You can't use that here", leave the subzone and return.
]]--
function MountThis:Flyable()
	-- IsFlyableArea does not check if the player can fly, just if the zone is flagged for flying... except Wintergrasp
	if IsFlyableArea() or (GetRealZoneText() == MOUNTTHIS_WINTERGRASP and GetWintergraspWaitTime() ~= nil) then
		if GetCurrentMapContinent() == 4 and GetSpellInfo(MOUNTTHIS_COLD_WEATHER_FLYING) ~= nil then return true; end
		if GetCurrentMapContinent() == 1 or GetCurrentMapContinent() == 2 and GetSpellInfo(MOUNTTHIS_FLIGHT_MASTERS_LICENSE) ~= nil then return true; end
		return true;
	end
	return false;
end

-- The shapeshift forms aren't counted in the random at this time
-- TODO: Figure out how to create/use secure buttons to allow shapeshift forms
function MountThis:MountRandom()
	-- Do the dismount dance if we need to before we even bother with the rest of this stuff
	if IsMounted() and MountThisSettings.dismountIfMounted then
		return MountThis:Dismount() 
	elseif CanExitVehicle() and MountThisSettings.exitVehicle then
		return MountThis:Dismount()
	end

	-- Try to summon a flying mount first, unless asked not to do so
	summon_flying = true;
	
	-- This is where we add the ability for modifier buttons to choose flying/slow mounts
	if MountThisSettings.mountLand == true then
		if MountThisSettings.mountLandKey == 0 and IsAltKeyDown() then summon_flying = false
		elseif MountThisSettings.mountLandKey == 1 and IsControlKeyDown() then summon_flying = false
		elseif MountThisSettings.mountLandKey == 2 and IsShiftKeyDown() then summon_flying = false
		end
	end
	
	if MountThis:Flyable() and summon_flying then
		if MountThis:Mount(MountThis:Random(true)) == true then return true; end
	end
	if MountThis:Mount(MountThis:Random(false)) == true then return true; end
	return false;
end

-- Give a mount ID and I'll use it, otherwise, it's a random mount
function MountThis:Mount(companionID)
	-- Do the dismount dance if we need to before we even bother with the rest of this stuff
	if IsMounted() and MountThisSettings.dismountIfMounted then
		return MountThis:Dismount() 
	elseif CanExitVehicle() and MountThisSettings.exitVehicle then
		return MountThis:Dismount()
	end

	if companionID ~= nil and companionID ~= "" then
		CallCompanion(MOUNT, companionID);
		MountThis.lastMountUsed = companionID;
		return true;
	end

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
	local canFlyInNorthrend = false
	local inNorthrend = false;
	-- TODO: Get this section tested. I'm pretty sure AQ mounts are not functioning
	local inAhnQiraj = nil
	if GetZoneText() == "Ahn'Qiraj" then inAhnQiraj = true end
	local ZoneNames = { GetMapZones(4) } ;
	for index, zoneName in pairs(ZoneNames) do 
		if zoneName == GetZoneText() then inNorthrend = true; end 
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
		-- If we have it set to not use a mount, don't do anything else
		if mount_table[mount_name].use_mount == true then
			-- Easier to say it is valid and then invalidate it (coding-wise anyway)
			local matches_requirements = true;

			-- Check each of the requirements to see if they're valid for this random search
			if IsUsableSpell(mount_table[mount_name].spellID) == nil then	-- This should fix the swimming issue
				matches_requirements = false
			--elseif rFlying ~= true and mount_table[mount_name].flying == true then 
			--	matches_requirements = false
			elseif rFlying == true and mount_table[mount_name].flying ~= true then 
				matches_requirements = false
			elseif rRequireSkill ~= nil and rRequireSkill ~= mount_table[mount_name].required_skill then
				matches_requirements = false
			elseif rRidingSkill ~= nil and rRidingSkill ~= mount_table[mount_name].riding_skill_based then
				matches_requirements = false
			elseif rPassengers ~= nil and rPassengers ~= mount_table[mount_name].passengers then
				matches_requirements = false 
			-- Cold Weather Flying yet?
			elseif inNorthrend and not canFlyInNorthrend and rFlying == true then
				matches_requirements = false
			-- Will this fix the AQ problem I've had?
			elseif mount_table[mount_name].ahnqiraj == true and not inAhnQiraj then
				if MountThisSettings.debug >= 5 then MountThis:Communicate("WTF: Old AQ reference"); end
				if mount_table[mount_name].zone == nil then mount_table[mount_name].zone = MOUNTTHIS_AHNQIRAJ end
				matches_requirements = false
			-- update to "zone restricted" mount determination
			elseif mount_table[mount_name].zone ~= nil then
				if mount_table[mount_name].zone == MOUNTTHIS_AHNQIRAJ and not inAhnQiraj then
					if MountThisSettings.debug >= 5 then MountThis:Communicate("WTF Ahn'Qiraj"); end
					matches_requirements = false
				end
				if mount_table[mount_name].zone == MOUNTTHIS_VASHJIR and not inVashjir then
					if MountThisSettings.debug >= 5 then MountThis:Communicate("WTF Vashj'ir"); end
					matches_requirements = false
				end
			-- TODO: Debug this skill checking section
			elseif mount_table[mount_name].required_skill ~= nil 
				and MountThis:CheckSkill(mount_table[mount_name].required_skill) < mount_table[mount_name].required_skill then
				if MountThisSettings.debug >= 3 then MountThis:Communicate("This mount needs a profession skill!"); end
				matches_requirements = false
			end

			if matches_requirements then tinsert(possible_mounts, mount_table[mount_name].index); end
		end
	end

	-- If we don't have any possible mounts, the result is nil
	-- Hopefully anyone asking for a mount knows for what they're asking
	if #possible_mounts == 0 then return nil; end

	-- Allow the user to say they don't want the last used mount
	if #possible_mounts > 1 and MountThisSettings.dontUseLastMount and MountThis.lastMountUsed ~= nil then
		for poss_index, mount_index in pairs(possible_mounts) do
			if possible_mounts[poss_index] == MountThis.lastMountUsed then tremove(possible_mounts, poss_index) end
		end
	end
  
	local pmindex = random(#possible_mounts)
	local chosen_mount = possible_mounts[pmindex];
	local _,chosen_mount_name = GetCompanionInfo("MOUNT",chosen_mount);
	return chosen_mount;
end

-- Return the value of a specific skill, nil if you don't have it
function MountThis:CheckSkill(check_skill_name)
	local spellName = GetSpellInfo(check_skill_name);
	if spellName ~= nil then return true; end
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
				if MountThisSettings.Mounts[MountName] ~= nil then
					MountThisButton:SetChecked(MountThisSettings.Mounts[MountName].use_mount)
					MountThisButton:Show()
				end
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
	for ButtonNumber = 1, NUM_COMPANIONS_PER_PAGE do
		local frame = CreateFrame("CheckButton", "MountThisCheckButton"..ButtonNumber, _G["SpellBookCompanionButton"..ButtonNumber], "UICheckButtonTemplate")
		frame:ClearAllPoints()
		frame:SetPoint("TOPRIGHT", 0, 0)
		frame:SetScale(.5)
		frame:SetScript("OnClick", MountThis_MountCheckButton)
	end
	MountThis_UpdateCompanionFrame()
end
