--[[--
While I wasn't the first to want the addon, I decided to write one that worked 
the way I wanted.  I credit the Livestock (Recompense - Uldum(US)) and 
BlazzingSaddles (Alestane) authors for the help they provided in understanding
the new functions, even if they don't know.
--]]--

BINDING_HEADER_MOUNTTHIS = "MountThis";
BINDING_NAME_MOUNTRANDOM = "Random Mount";

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
				unShapeshift =
				{
					order = 3,
					type = 'toggle',
					name = 'Cancel Shapeshift',
					desc = 'Make MountThis cancel a shapeshift form',
					get = function() return MountThisSettings.unShapeshift end,
					set = function(info, value) MountThisSettings.unShapeshift = value end,
					width = 'full',
				},
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
				mounts = 
				{
					order = 6,
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
					max = 4,
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
              getglobal("chatFrame"..i):AddMessage("This is chatFrame"..i, 255, 255, 255, 0);
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
				}
			}
		}
	}
}

MountThis = LibStub("AceAddon-3.0"):NewAddon("MountThis", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0");
MountThis.version = 0.94;
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
	unShapeshift = true,
	mountLand = true;
    mountLandKey = 0;
};
MountThisSettingsDefaults = MountThisSettings;
MountThisVariablesLoaded = false;
MountThis.lastMountUsed = nil;
MountThis.PlayerAlive = false;

--MountThis.SwiftFlightFormButton = CreateFrame("Button", "SwiftFlightFormButton", UIParent, "SecureActionButtonTemplate");
--MountThis.SwiftFlightFormButton:setAttribute('type*', 'spell');
--MountThis.SwiftFlightFormButton:setAttribute('spell', 'Swift Flight Form');

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

	--[[--
	We need a frame we can abuse to read the tooltips.
	There is no easy way to determine flying, or speed otherwise.
	Hopefully this will be created once and we'll be okay...
	--]]--
	CreateFrame("GameTooltip","MountThisTooltip",UIParent,"GameTooltipTemplate");

	self:RegisterChatCommand("mountrandom", "MountRandom");
	self:RegisterChatCommand("mount", "Mount");
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("COMPANION_LEARNED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD"); -- Good for everything except variable speed mounts like DK Gryphon or Big Blizzard Bear
	-- The event we should be looking into using is SKILL_LINES_CHANGED (it's after ADDON_LOADED and VARIABLES_LOADED)
	self:RegisterEvent("PLAYER_ALIVE");
	self:RegisterEvent("UNIT_SPELLCAST_FAILED");
	self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET");
end


function MountThis:UNIT_SPELLCAST_FAILED(...)
	local event, unit_casting, spell_name, spell_rank = ...;
	if MountThisSettings.debug >= 3 then self:Communicate("EVENT: UNIT_SPELLCAST_FAILED - "..unit_casting.." "..spell_name.." "..spell_rank); end
	MountThis.mountSuccess = false;
end
function MountThis:UNIT_SPELLCAST_FAILED_QUIET(...)
	local event, unit_casting, spell_name, spell_rank = ...;
	if MountThisSettings.debug >= 3 then self:Communicate("EVENT: UNIT_SPELLCAST_FAILED_QUIET - "..unit_casting.." "..spell_name.." "..spell_rank); end
	MountThis.mountSuccess = false;
end


function MountThis:VARIABLES_LOADED()
	if MountThisSettings.debug >= 3 then self:Communicate("EVENT: VARIABLES_LOADED"); end
	MountThisVariablesLoaded = true;
	if MountThisSettings.debug >=1 then self:Communicate("Variables loaded"); end
end

function MountThis:COMPANION_LEARNED()
	if MountThisSettings.debug >= 3 then self:Communicate("EVENT: COMPANION_LEARNED"); end
	MountThis:UpdateMounts(true);
end

function MountThis:PLAYER_ENTERING_WORLD()
	-- I do this to make sure variables get assigned correctly.  I don't know of another way at this point besides deleting old variables.
	if MountThisSettings.debug >= 3 then self:Communicate("EVENT: PLAYER_ENTERING_WORLD"); end
	if MountThisVariablesLoaded then
		if tonumber(MountThisSettings.version) == nil or tonumber(MountThisSettings.version) < tonumber(MountThis.version) then
			MountThisSettings.version = MountThis.version;
			if MountThisSettings.mountLand == nil then MountThisSettings.mountLand = MountThisSettingsDefaults.mountLand; end
			if MountThisSettings.mountLandKey == nil then MountThisSettings.mountLandKey = MountThisSettingsDefaults.mountLandKey; end
			if MountThisSettings.exitVehicle == nil then MountThisSettings.exitVehicle = MountThisSettingsDefaults.exitVehicle; end
			if MountThisSettings.unShapeshift == nil then MountThisSettings.unShapeshift = MountThisSettingsDefaults.unShapeshift; end
			if MountThisSettings.dontUseLastMount == nil then MountThisSettings.dontUseLastMount = MountThisSettingsDefaults.dontUseLastMount; end
		end
		-- MountThis:UpdateMounts(true);  -- Moved to PLAYER_ALIVE
	end
end

--[[--
Variable speed mounts like Death Knight Ebon Gryphon or Big Blizzard Bear don't get properly set at PLAYER_ENTERING_WORLD since 
the player doesn't have any skills loaded yet.  When the first PLAYER_ALIVE event fires on load, the riding skill has been loaded, so we can check
to see what our riding skill is an set variable speed mounts appropriately.

A flag is set to indicate that we've updated the mounts once and don't want to do it every time someone "comes alive"
--]]--
function MountThis:PLAYER_ALIVE()
	if MountThisSettings.debug >= 3 then self:Communicate("EVENT: PLAYER_ALIVE"); end
	if not MountThis.PlayerAlive then MountThis:UpdateMounts(true); MountThis.PlayerAlive = true; end
  --[[-- Variable speed mounts like Death Knight Ebon Gryphon or Big Blizzard Bear don't get properly set at PLAYER_ENTERING_WORLD since 
      the player doesn't have any skills loaded yet.  When the first PLAYER_ALIVE event fires on load, the riding skill has been loaded, so we can check
      to see what our riding skill is and set variable speed mounts appropriately. --]]--
  MountThis:UpdateMounts(true);
end

function MountThis:UpdateMounts(force_update)
	if(force_update == nil) then force_update = false; end
	if force_update and MountThisSettings.debug >= 1 then self:Communicate("Force updating mount information");
	elseif MountThisSettings.debug >= 1 then self:Communicate("Using cached information from saved variables when possible");
	end

	-- Loop through all the mounts (yes, mounts are "companions" now)
	for companion_index = 1, GetNumCompanions("MOUNT") do
		local _,mount_name,spellID = GetCompanionInfo("MOUNT",companion_index);
		-- For some reason, GetCompanionInfo can return a nil mount name.  This tries to stop that
		if mount_name == nil then return end;
		if MountThisSettings.debug >= 2 then self:Communicate("Found mount: "..mount_name.." at index "..companion_index); end

		-- Set up a temporary mount object
		local current_mount =
		{
			name = mount_name;
			index = companion_index;
			speed = 0;
			flying = false;
			swimming = false;
			require_skill = "";
			require_skill_level = 0;
			riding_skill_based = false;
			passengers = 0;
			use_mount = true;
			ahnqiraj = false;
		}

		-- Set up our local frame for reading
		GameTooltip_SetDefaultAnchor(MountThisTooltip, UIParent);
		MountThisTooltip:SetHyperlink("spell:"..spellID);
		if type(MountThisSettings.Mounts) ~= "table" then MountThisSettings.Mounts = {} end;
		-- We make an assumption that the tooltip isn't changing
		-- TODO: Add override to allow reinitialization (will help if they change text)
		if force_update or not(type(MountThisSettings.Mounts[mount_name]) == "table") then
			if force_update and MountThisSettings.debug >= 1 then self:Communicate("Forcing Mount: "..mount_name.." into mounts table"); end

			local outland, northrend, ahnqiraj, extremely, very, require_skill, riding_skill_based, passengers;
			-- Cycle through the lines of our tooltip to figure out the kind of mount
			for tt_line = 1, MountThisTooltip:NumLines() do
				local text = _G["MountThisTooltipTextLeft"..tt_line]:GetText();

				--[[--
				Flying mounts typically mention "This mount can only be summoned in Outland or Northrend"
				There are variable speed mounts like "Big Blizzard Bear" and skill mounts like the Flying Machine and Flying Carpet
				Swimming mounts usually explicitly state that.
				--]]--
				for word in string.gmatch(text, "%a+") do
					if word == "Outland" then outland = true;
					elseif word == "Northrend" then northrend = true;
					elseif word == "extremely" then extremely = true;
					elseif word == "very" then very = true
					elseif word == "swim" then current_mount.swimming = true;
					end
				end

				-- Profession skill seems to come in more than one form
				local skill_level, skill_type = string.match(text, "Requires (%d+) skill in (%a+)");
				if skill_type ~= nil then
					current_mount.require_skill = skill_type;
					current_mount.require_skill_level = skill_level;
				end
				skill_level, skill_type = string.match(text, "Requires (%d+) (%a+) skill");
				if skill_type ~= nil then
					current_mount.require_skill = skill_type;
					current_mount.require_skill_level = skill_level;
				end

				-- Let's see how many passengers we can take
				passengers = string.match(text, "carry (%d+) passengers");
				if passengers ~= nil then current_mount.passengers = 0 end;

				-- Set the mount's flying ability
				if northrend or outland then current_mount.flying = true end;
				
				-- Set up the speed of the mount
				if current_mount.flying then
					if extremely then current_mount.speed = 310;
					elseif very then current_mount.speed = 280;
					else current_mount.speed = 150;
					end
				else
					if very then current_mount.speed = 100;
					-- This may not be the case. I don't know about the turtle or other mounts that let you 'mount' at run speed
					else current_mount.speed = 60;
					end
				end
				-- Ahn'Qiraj mounts are unique in that they do not use the normal "speed" keywords
				if string.match(text, "Ahn'Qiraj") ~= nil then
					current_mount.ahnqiraj = true;
					current_mount.speed = 100;
				end

				-- Not a huge stretch anymore, but I realized earlier versions did not catch all possibilities
				if string.match(text, "depending on your Riding skill") ~= nil then
					current_mount.riding_skill_based = true
					--skill_level = MountThis:CheckSkill("Riding");
					skill_level = MountThis:GetSkillLevel("Riding");
					if MountThisSettings.debug >= 2 then self:Communicate("Variable speed mount "..mount_name.." and skill level "..tostring(skill_level)); end
					--MountThis:Communicate(tostring(skill_level));
					if current_mount.flying then
						-- Tell me again how you learned a flying mount but I don't see you having the skill...
						if skill_level == nil or skill_level == 0 then current_mount.speed = 0;
						elseif skill_level >= 300 then current_mount.speed = 280;
						elseif skill_level <= 225 then current_mount.speed = 150;
						end
					else
						-- I believe even the normal land mounts have a riding skill requirement...
						if skill_level == nil or skill_level == 0 then current_mount.speed = 0;
						elseif skill_level == 75 then current_mount.speed = 60;
						elseif skill_level >= 150 then current_mount.speed = 100;
						end
					end
				end
			end

			-- We have the mount in the table already. Use the saved use_mount value (check for nils, just in case)
			if MountThisSettings.Mounts[mount_name] ~= nil then
				if MountThisSettings.Mounts[mount_name].use_mount ~= nil then
					current_mount.use_mount = MountThisSettings.Mounts[mount_name].use_mount;
				end
			end

			-- I can't say I always know what the pattern matches will return...
			--if MountThisSettings.debug >=1 and not force_update then
			if MountThisSettings.debug >=3 then
				self:Communicate("Mount flags...");
				self:Communicate("- northrend: "..tostring(northrend));
				self:Communicate("- outland: "..tostring(outland));
				self:Communicate("- ahn'qiraj: "..tostring(ahnqiraj));
				self:Communicate("- swimming: "..tostring(swimming));
				self:Communicate("- extremely: "..tostring(extremely));
				self:Communicate("- very: "..tostring(very));
				self:Communicate("- require_skill: "..tostring(require_skill));
				self:Communicate("- require_skill_level: "..tostring(require_skill_level));
				self:Communicate("- riding_skill_based: "..tostring(riding_skill_based));
				self:Communicate("- passengers: "..tostring(passengers));
				self:Communicate("- use_mount: "..tostring(current_mount.use_mount));
			end

			if MountThisSettings.debug >=4 then
				self:Communicate("Current mount info..."..tostring(mount_name));
				self:Communicate("- name: "..tostring(current_mount.name));
				self:Communicate("- index: "..tostring(current_mount.index));
				self:Communicate("- speed: "..tostring(current_mount.speed));
				self:Communicate("- flying: "..tostring(current_mount.flying));
				self:Communicate("- require_skill: "..tostring(current_mount.require_skill));
				self:Communicate("- require_skill_level: "..tostring(current_mount.require_skill_level));
				self:Communicate("- riding_skill_based: "..tostring(current_mount.riding_skill_based));
				self:Communicate("- passengers: "..tostring(current_mount.passengers));
				self:Communicate("- use_mount: "..tostring(current_mount.use_mount));
				self:Communicate("- ahn'qiraj: "..tostring(current_mount.ahnqiraj));
			end

			-- Most errors indicating this line are tooltip parse errors or logic errors for skill/speed
			MountThisSettings.Mounts[mount_name] = current_mount;
		end
		if MountThisSettings.debug >=2 then self:Communicate("Setting the index for mount: "..mount_name.." to "..companion_index); end
		MountThisSettings.Mounts[mount_name].index = companion_index;
		--end -- Nil mount name???
	end
	-- TODO: Check to see if we can hide the tooltip by default without affecting the information OR make it appear off-screen
	if MountThisSettings.debug >=2 then self:Communicate("Hiding the tooltip frame.  All done here."); end
	MountThisTooltip:Hide();
end

function MountThis:ListMounts(request_short)
	self:Communicate("ListMounts:");
	for name, data in pairs(MountThisSettings.Mounts) do
		self:Communicate("- "..name.." - fly: "..tostring(data.flying)..
						" - "..tostring(data.speed).."%"..
						" - prof: "..tostring(data.require_skill).."@"..tostring(data.require_skill_level)..
						" - skill: "..tostring(data.riding_skill_based)..
						" - pass: "..tostring(data.passengers));
	end
end


--[[
There is a bug that I can't get around with Krasus' Landing.
If you receive an error of "You can't use that here", leave the subzone and return.
]]--
--[[
IsFlyableArea() handles most of the info we need to know including Krasus's Landing, the exit tunnel from Dalaran Sewers, and non-battle Wintergrasp.
Also adding in Cold Weather Flying check will help most cases
]]--
function MountThis:Flyable()
	local flyable, target = SecureCmdOptionParse("[flyable] true; false");
	--The parser does not take into account Dalaran, Wintergrasp, or if you have Cold Weather Flying
	if flyable == "true" and IsFlyableArea() then
		if GetCurrentMapContinent() == 4 and GetSpellInfo("Cold Weather Flying") ~= nil then
			return true;
		end
		return true;
	end
	return false;
end

-- Find the fastest random mount you can use (flying first)
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
	-- elseif UnitClass("player") == "GetShapeshiftForm() ~= 0 and MountThisSettings.unShapeshift then
		-- if MountThisSettings.debug >= 3 then MountThis:Communicate('Is Shapeshifted: Dismounting'); end
		-- return MountThis:Dismount()
	end

	-- Try to summon a flying mount first, unless asked not to do so
	summon_flying = true;
	
	-- This is where we add the ability for modifier buttons to choose flying/slow mounts
	if MountThisSettings.mountLand == true then
		if MountThisSettings.debug >= 2 then
			MountThis:Communicate('MountLand option enabled');
			MountThis:Communicate('MountLandKey set to '..tostring(MountThisSettings.mountLandKey));
			MountThis:Communicate('Alt: '..tostring(IsAltKeyDown()));
			MountThis:Communicate('Control: '..tostring(IsControlKeyDown()));
			MountThis:Communicate('Shift: '..tostring(IsShiftKeyDown()));
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
		if MountThisSettings.debug >= 2 then
			MountThis:Communicate('You\'re swimming, so we must select a land mount.');
		end
		summon_flying = false;
	end
	
	if MountThis:Flyable() and summon_flying then
		if MountThis:Mount(MountThis:Random(true,310)) then return true; 
		elseif MountThis:Mount(MountThis:Random(true,280)) then return true; 
		elseif MountThis:Mount(MountThis:Random(true,150)) then return true; 
		end
	end
	if MountThis:Mount(MountThis:Random(false,100)) then return true;
	elseif MountThis:Mount(MountThis:Random(false,60)) then return true; 
	end
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
	-- elseif GetShapeshiftForm() ~= 0 and MountThisSettings.unShapeshift then
		-- if MountThisSettings.debug >= 3 then MountThis:Communicate('Is Shapeshifted: Dismounting'); end
		-- return MountThis:Dismount()
	end
	
	if companionID ~= nil and companionID ~= "" then
		MountThis.mountSuccess = true;
		CallCompanion(MOUNT, companionID);
		MountThis.lastMountUsed = companionID;
		if MountThisSettings.debug >= 4 then MountThis:Communicate("Testing if mount failed for "..tostring(companionID)); end
		if MountThis.mountSuccess == false then
			if MountThisSettings.debug >= 4 then MountThis:Communicate("Failed to mount "..tostring(companionID)); end
			return false;
		end
		if MountThisSettings.debug >= 4 then MountThis:Communicate("Mounting succeeded for "..tostring(companionID)); end
		return true;
	end
	if MountThisSettings.debug >= 4 then MountThis:Communicate("companionID not supplied"); end
	return false;
end

-- Why bother with this one?  I don't know either.
function MountThis:Dismount()
	-- Can't depend on DismissCompanion because of Druids ;)
	--DismissCompanion(MOUNT);
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
- rSpeed: 0/60/100/280/310
- rRequireSkill: Engineering/Tailoring
- rRidingSkill: true/false
- rPassengers: # of passengers
--]]--
function MountThis:Random(rFlying, rSpeed, rRequireSkill, rRidingSkill, rPassengers)
	if MountThisSettings.debug > 1 then
		self:Communicate("Random mount flags: "..tostring(rFlying).." "..tostring(rSpeed).." "..tostring(rRequireSkill).." "..tostring(rRidingSkill))
	end

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
	if MountThis:CheckSkill("Cold Weather Flying") ~= nil then canFlyInNorthrend = true; end
	
	-- Yes, I decided to go through the whole list of mounts and do the checking that way...
	mount_table = MountThisSettings.Mounts;
	-- Create a temporary table that uses an integer index rather than dictionary
	-- This already makes me think I should rewrite the table structures...
	local possible_mounts = {};
	for mount_name in pairs(mount_table) do
		if MountThisSettings.debug >= 3 then self:Communicate("Checking "..mount_name.." for use"); end
		-- If we have it set to not use a mount, don't do anything else
		if mount_table[mount_name].use_mount then
			-- Easier to say it is valid and then invalidate it (coding-wise anyway)
			local matches_requirements = true;

			-- Check each of the requirements to see if they're valid for this random search
			-- If it's nil, then we don't care.  Otherwise, check the value
			if rFlying ~= nil and rFlying ~= mount_table[mount_name].flying then 
				if MountThisSettings.debug >= 4 then 
					self:Communicate("Flying "..tostring(rFlying).." and "..tostring(mount_table[mount_name].flying)); 
				end
				matches_requirements = false
			elseif rSpeed ~= nil and rSpeed ~= mount_table[mount_name].speed then
				if MountThisSettings.debug >= 4 then 
					self:Communicate("Speed "..tostring(rSpeed).." and "..tostring(mount_table[mount_name].speed)); 
				end
				matches_requirements = false
			elseif rRequireSkill ~= nil and rRequireSkill ~= mount_table[mount_name].required_skill then
				if MountThisSettings.debug >= 4 then 
					self:Communicate("RequireSkill "..tostring(rRequireSkill).." and "..tostring(mount_table[mount_name].required_skill)); 
				end
			matches_requirements = false
			elseif rRidingSkill ~= nil and rRidingSkill ~= mount_table[mount_name].riding_skill_based then
				if MountThisSettings.debug >= 4 then 
					self:Communicate("RidingSkill "..tostring(rRidingSkill).." and "..tostring(mount_table[mount_name].riding_skill_based)); 
				end
				matches_requirements = false
			elseif rPassengers ~= nil and rPassengers ~= mount_table[mount_name].passengers then
				if MountThisSettings.debug >= 4 then 
					self:Communicate("Passengers "..tostring(rPassengers).." and "..tostring(mount_table[mount_name].passengers)); 
				end
				matches_requirements = false 
			            
			-- Cold Weather Flying yet?
			elseif inNorthrend and not canFlyInNorthrend and rFlying then
				matches_requirements = false
			-- Will this fix the AQ problem I've had?
			elseif mount_table[mount_name].ahnqiraj == true and not inAhnQiraj then
				matches_requirements = false 
			-- TODO: Debug this skill checking section
			elseif mount_table[mount_name].required_skill ~= nil 
				and MountThis:CheckSkill() < mount_table[mount_name].required_skill then
				if MountThisSettings.debug >= 3 then self:Communicate("This mount needs a profession skill!"); end
				matches_requirements = false 
			end

			if matches_requirements then
				if MountThisSettings.debug >= 2 then MountThis:Communicate(" - Added "..mount_name.." to potential mounts"); end
					tinsert(possible_mounts, mount_table[mount_name].index);
			--else
				--if MountThisSettings.debug then self:Communicate(" - "..mount_name.." did not match requirements"); end
			end
		end
	end

	-- If we don't have any possible mounts, the result is nil
	-- Hopefully anyone asking for a mount knows for what they're asking
	if #possible_mounts == 0 then
		if MountThisSettings.debug > 1 then self:Communicate("Your random mount query failed"); end
		return nil;
	end

--[[DEBUGGING CODE]]--

--MountThis.SwiftFlightFormButton = CreateFrame("Button", "SwiftFlightFormButton", UIParent, "SecureActionButtonTemplate");
--MountThis.SwiftFlightFormButton:setAttribute('type*', 'spell');
--MountThis.SwiftFlightFormButton:setAttribute('spell', 'Swift Flight Form');

--local shapeshift_form = "Path of Frost";
--if random(1) > 0 then shapeshift_form = "Horn of Winter"; end
--
--MountThisSecureButton:SetAttribute('type', 'spell');
--MountThisSecureButton:SetAttribute('spell', shapeshift_form);
--MountThisFrameText:SetText(shapeshift_form);

	--[[END DEBUGGING CODE]]--

	-- Allow the user to say they don't want the last used mount
  if MountThisSettings.debug >= 3 then self:Communicate("dontUseLastMount: "..tostring(MountThisSettings.dontUseLastMount)..", lastMountUsed: "..tostring(MountThis.lastMountUsed)); end
	if #possible_mounts > 1 and MountThisSettings.dontUseLastMount and MountThis.lastMountUsed ~= nil then
		for poss_index, mount_index in pairs(possible_mounts) do
			if possible_mounts[poss_index] == MountThis.lastMountUsed then tremove(possible_mounts, poss_index) end
		end
	end
  
  local pmindex = random(#possible_mounts)
	local chosen_mount = possible_mounts[pmindex];
  if MountThisSettings.debug >= 3 then self:Communicate("PMIndex: "..tostring(pmindex)..", MountIndex: "..tostring(chosen_mount)); end
	local _,chosen_mount_name = GetCompanionInfo("MOUNT",chosen_mount);
    if MountThisSettings.debug >= 1 then 
      self:Communicate("Choosing mount "..chosen_mount_name.." from "..tostring(#possible_mounts).." possible mounts."); 
			end
    return chosen_mount;

	--return possible_mounts[random(#possible_mounts)];
end

-- Return the value of a specific skill, nil if you don't have it
function MountThis:CheckSkill(check_skill_name)
	if MountThisSettings.debug >= 2 then MountThis:Communicate("Checking skill "..check_skill_name); end
	local spellName = GetSpellInfo(check_skill_name);
	if spellName ~= nil then return true; end
	if MountThisSettings.debug > 1 then self:Communicate("Skill: "..check_skill_name.." - not found"); end
	return nil;
end
function MountThis:GetSkillLevel(check_skill_name)
	for skillIndex = 1, GetNumSkillLines() do
		local skillName, _, _, skillRank = GetSkillLineInfo(skillIndex);
		if string.lower(skillName) == string.lower(check_skill_name) then
			if MountThisSettings.debug >= 2 then self:Communicate("Skill: "..skillName.." - "..skillRank); end
			return skillRank;
		end
	end
	return nil;
end

-- Use this to debug a tooltip
function MountThis:ToolTipDebug(spellID)
	-- If you don't specify a spell on the command line, we'll use this one
	if spellID == nil then spellID = 44151; end
	GameTooltip_SetDefaultAnchor(MountThisTooltip, UIParent);
	MountThisTooltip:SetHyperlink("spell:"..spellID);

	for i = 1, MountThisTooltip:NumLines() do
		local text = _G["MountThisTooltipTextLeft"..i]:GetText();
		MountThis:Communicate(text);
	end
	MountThisTooltip:Hide();
end