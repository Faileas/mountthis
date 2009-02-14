--[[--
While I wasn't the first to want the addon, I decided to write one that worked 
the way I wanted.  I credit the Livestock (Recompense - Uldum(US)) and 
BlazzingSaddles (Alestane) authors for the help they provided in understanding
the new functions, even if they don't know.
--]]--

local options =
{
	name = 'MountThis',
    type = 'group',
    args =
    {
		General = {
			type = 'group',
			name = 'General',
			desc--[[--
While I wasn't the first to want the addon, I decided to write one that worked 
the way I wanted.  I credit the Livestock (Recompense - Uldum(US)) and 
BlazzingSaddles (Alestane) authors for the help they provided in understanding
the new functions, even if they don't know.
--]]--

local options =
{
	name = 'MountThis',
    type = 'group',
    args =
    {
		General = {
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
				},
				mounts = 
				{
					type = 'multiselect',
					name = 'Mounts',
					desc = '',
					--[--
					values = function(info)
						local mount_names = {};
						--local use_mounts = {};
						for mount_name in pairs(MountThisSettings.Mounts) do
							mount_names[mount_name] = mount_name;
							--use_mounts[mount_name] = MountThisSettings.Mounts[mount_name].use_mount;
						end
						--return mount_names, nil, use_mounts;
						return mount_names;
					end,
					--]--
					get = function(info, key)
						return MountThisSettings.Mounts[key].use_mount;
					end,
					set = function(info, key, value)
						--MountThis:Communicate("Set: "..key.." - "..tostring(value));
						MountThisSettings.Mounts[key].use_mount = value;
						return MountThisSettings.Mounts[key].use_mount;
					end,
					width = 'full',
				},
			},
		},
		Debugging =
		{
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
				},
				version =
				{
					type = 'execute',
					name = 'Version',
					desc = 'Show MountThis version',
					order = 2,
					func = function() MountThis:Print("You are using MountThis version " .. MountThis.version) end,
					--hidden = guiHidden,
				},
				list = 
				{
					type = 'execute',
					name = 'List',
					desc = 'List all mounts known to MountThis',
					order = 3,
					func = function() MountThis:ListMounts(true) end,
					--hidden = guiHidden,
				},
				update = 
				{
					type = 'execute',
					name = 'Update',
					desc = 'Force update all mounts',
					order = 4,
					func = function() MountThis:UpdateMounts(true) end,
					--hidden = guiHidden,
				}
			}
		}
    }
}
MountThis = LibStub("AceAddon-3.0"):NewAddon("MountThis", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0");
MountThis.version = "Beta 2";
MountThis.reqVersion = MountThis.version;
MountThis.optionsFrames = {};
MountThisSettings =
{
	Mounts = {},
	--coldweatherflying = 0,
	debug = 0,
	dismountIfMounted = true,
};
MountThisSettingsDefaults = MountThisSettings;
MountThisVariablesLoaded = false;

--MountThis.SwiftFlightFormButton = CreateFrame("Button", "SwiftFlightFormButton", UIParent, "SecureAnchorButtonTemplate");
--MountThis.SwiftFlightFormButton:setAttribute('type*', 'spell');
--MountThis.SwiftFlightFormButton:setAttribute('spell', 'Swift Flight Form');


function MountThis:Init()
	if not MountThisSettings then
		self:Communicate("No MountThisSettings found");
		MountThisSettings = MountThisSettingsDefaults;
	end
        MountThisVariablesLoaded = true;
	-- Important to only set this when trying to debug
	--MountThisSettings.debug = 0;
	--if not MountThisSettings.coldweatherflying then MountThisSettings.coldweatherflying = defaults.coldweatherflying; end
	--if not MountThisSettings.Mounts then MountThisSettings.Mounts = defaults.Mounts; end

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
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("COMPANION_LEARNED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function MountThis:VARIABLES_LOADED()
	--self:Init();
	--self:UpdateMounts(true);
        MountThisVariablesLoaded = true;
	if MountThisSettings.debug >=1 then self:Print("Variables loaded"); end
end

function MountThis:COMPANION_LEARNED()
	self:UpdateMounts(true);
	--self:Print("Updated mount data");
end
function MountThis:PLAYER_ENTERING_WORLD()
        if MountThisVariablesLoaded then
                MountThis:UpdateMounts();
        end
	--self:Print("Updated mount data");
end

function MountThis:UpdateMounts(force_update)
	if(force_update == nil) then force_update = false; end
	if force_update and MountThisSettings.debug >= 1 then self:Communicate("Force updating mount information");
	elseif MountThisSettings.debug >= 1 then self:Communicate("Using cached information from saved variables when possible");
	end

	-- Loop through all the mounts (yes, mounts are "companions" now)
	for i = 1, GetNumCompanions("MOUNT") do
		local _,mount_name,spellID = GetCompanionInfo("MOUNT",i);
		if MountThisSettings.debug >= 1 then self:Communicate("Found mount: "..mount_name.." at index "..i); end

		-- Set up a temporary mount object
		local current_mount =
		{
			name = mount_name;
			index = i;
			speed = 0;
			flying = false;
			require_skill = false;
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
		if force_update or not type(MountThisSettings.Mounts[mount_name]) == "table" then
			if force_update then self:Communicate("Forcing Mount: "..mount_name.." into mounts table"); end

			local outland, northrend, ahnqiraj, extremely, very, require_skill, riding_skill_based, passengers;
			-- Cycle through the lines of our tooltip to figure out the kind of mount
			for i = 1, MountThisTooltip:NumLines() do
				local text = _G["MountThisTooltipTextLeft"..i]:GetText();

				--[[--
				Flying mounts typically mention "This mount can only be summoned in Outland or Northrend"
				There are variable speed mounts like "Big Blizzard Bear" and skill mounts like the
				Flying Machine and Flying Carpet
				--]]--
				for word in string.gmatch(text, "%a+") do
					if word == "Outland" then outland = true;
					elseif word == "Northrend" then northrend = true;
					elseif word == "Ahn'Qiraj" then ahnqiraj = true;
					elseif word == "extremely" then extremely = true;
					elseif word == "very" then very = true;
					--elseif word == "Requires" then require_skill = true;
					--elseif word == "Riding" then riding_skill_based = true;
					--elseif word == "passengers" then passengers = 1;
					end
				end

				-- Profession skill seems to come in more than one form
				local skill_level, skill_type = string.match(text, "Requires (%d+) skill in (%a+)");
				if skill_type ~= nil then require_skill = skill_type end
				skill_level, skill_type = string.match(text, "Requires (%d+) (%a+) skill");
				if skill_type ~= nil then require_skill = skill_type end

				-- Let's see how many passengers we can take
				passengers = string.match(text, "carry (%d+) passengers");
				if passengers ~= nil then passengers = 0 end;

				-- Set the mount's flying ability
				if northrend or outland then current_mount.flying = true end;
				if string.match(text, "Ahn'Qiraj") ~= nil then current_mount.ahnqiraj = true end;
				
				-- Set up the speed of the mount
				if current_mount.flying then
					if extremely then current_mount.speed = 310;
					elseif very then current_mount.speed = 280;
					else current_mount.speed = 60;
					end
				else
					if very then current_mount.speed = 100;
					else current_mount.speed = 60;
					end
				end

				-- This is a huge stretch because I have no real data to work with
				if string.match(text, "depending on your Riding skill") ~= nil then
					current_mount.riding_skill_based = true
					skill_level = self:CheckSkill("Riding");
					if current_mount.flying then
						if skill_level == nil or skill_level == 0 then current_mount.speed = 0;
						elseif skill_level >= 300 then current_mount.speed = 280;
						elseif skill_level <= 225 then current_mount.speed = 60;
						end
					else
						if skill_level == nil or skill_level == 0 then current_mount.speed = 0;
						elseif skill_level == 75 then current_mount.speed = 60;
						elseif skill_level >= 150 then current_mount.speed = 100;
						end
					end
				end


			end

			-- Don't override the use_mount settings
			if MountThisSettings.Mounts[mount_name] ~= nil then
				-- We have the mount in the table already. Use the saved value (check for nils, just in case)
				if MountThisSettings.Mounts[mount_name].use_mount ~= nil then
					current_mount.use_mount = MountThisSettings.Mounts[mount_name].use_mount;
				end
			end

			-- I can't say I always know what the pattern matches will return...
			if MountThisSettings.debug >=1 and not force_update then
				self:Communicate("Mount flags...");
				self:Communicate("- northrend: "..tostring(northrend));
				self:Communicate("- outland: "..tostring(outland));
				self:Communicate("- ahn'qiraj: "..tostring(ahnqiraj));
				self:Communicate("- extremely: "..tostring(extremely));
				self:Communicate("- very: "..tostring(very));
				self:Communicate("- require_skill: "..tostring(require_skill));
				self:Communicate("- riding_skill_based: "..tostring(riding_skill_based));
				self:Communicate("- passengers: "..tostring(passengers));
				self:Communicate("- use_mount: "..tostring(current_mount.use_mount));
			end
			
			-- Add it to the global mounts table
                        --MountThis:Communicate(mount_name);
			MountThisSettings.Mounts[mount_name] = current_mount;
		end
		MountThisSettings.Mounts[mount_name].index = i;
		if MountThisSettings.debug >=1 then self:Communicate("Set the index for mount: "..mount_name.." to "..i); end
	end
	MountThisTooltip:Hide();
end

function MountThis:Communicate(str)
	-- This function could be used to make comments when summoning if I was so inclined
	self:Print(str);
end

function MountThis:ListMounts(request_short)
	self:Communicate("ListMounts:");
	for name, data in pairs(MountThisSettings.Mounts) do
		self:Communicate("- "..name.." - flying: "..tostring(data.flying)..
						" - "..tostring(data.speed).."%"..
						" - req_skill: "..tostring(data.require_skill)..
						" - riding_skill: "..tostring(data.riding_skill_based)..
						" - passengers: "..tostring(data.passengers));
	end
end

function MountThis:FlyableArea()
	-- Continents 3 (Outland) and 4 (Northrend) are flyable
        local currentZone = GetZoneText();
        local subZone = GetSubZoneText();
        local cold_weather_flying = MountThis:CheckSkill("Cold Weather Flying")
	if currentZone == "Wintergrasp" then return false end
	if currentZone == "Dalaran" and subZone ~= "Krasus' Landing" then return false end;
        -- or subZone == "The Underbelly") then return false end;
	for continent_index = 3, 4 do
		local ZoneNames = { GetMapZones(continent_index) } ;
		-- At some point we need to know exact spellings/areas for the "No Fly" zones
		for index, zoneName in pairs(ZoneNames) do
			if zoneName == currentZone then
				if cold_weather_flying == nil and continent_index == 4 then return false; end
				return true;
			end
		end
	end
	return false;
end

-- Find the fastest random mount you can use (flying first)
-- The druid shapeshift form isn't counted in the random at this time
function MountThis:MountRandom()
	local player_class = UnitClass("player");
	player_class = '';
        
        -- This is where we add the ability for modifier buttons to choose flying/slow mounts
        
	if MountThis:FlyableArea() then
		--self:Communicate("Take the high road...");
		if MountThis:Mount(MountThis:Random(true,310)) then return true; end
		if MountThis:Mount(MountThis:Random(true,280)) then return true; end
		-- Check to see if you're a fast druid (this should work if you're moving)
		if player_class == 'Druid' then
			--if MountThis:CheckSkill('Swift Flight Form') and CastSpellByName('Swift Flight Form') then return true; end
			SwiftFlightFormButton.click()
		end
		if MountThis:Mount(MountThis:Random(true,60)) then return true; end
		-- Slow flying druid
		if player_class == 'Druid' then
			if MountThis:CheckSkill('Flight Form') and CastSpellByName('Flight Form') then return true; end
		end
	end
	--self:Communicate("You can't fly here. Travelling by land...");
	if MountThis:Mount(MountThis:Random(false,100)) then return true; end
	if MountThis:Mount(MountThis:Random(false,60)) then return true; end
	-- Druid travel form
	if player_class == 'Druid' then
		if MountThis:CheckSkill('Travel Form') and CastSpellByName('Travel Form') then return true; end
	end
	if player_class == 'Shaman' then
		if MountThis:CheckSkill('Ghost Wolf') and CastSpellByName('Ghost Wolf') then return true; end
	end
	return false;
end


-- Give a mount name and I'll use it, otherwise, it's a random mount
function MountThis:Mount(companionID)
	if IsMounted() then
		if MountThisSettings.debug >=1 then self:Communicate("Already mounted"); end
		-- I'll have to figure out how to get this initialized on startup, but it's here to make sure
		if MountThisSettings.dismountIfMounted == nil then MountThisSettings.dismountIfMounted = false; end
		if MountThisSettings.dismountIfMounted then
			if MountThisSettings.debug >=1 then self:Communicate("Dismounting only"); end
			return self:Dismount();
		end
	end
	
	if companionID ~= nil then
                CallCompanion(MOUNT, companionID);
                --local spell, _, _, _, _, endTime = UnitCastingInfo("player");
                -- We assume that if you're casting, you are successfully summoning your mount
                --if spell ~= nil then return true end;

                return true;
        end
        
	-- DON'T DO THIS UNLESS YOU CHANGE MountRandom(). Stack overflow if no appropriate mount found
	--else return self:MountRandom(); end
	return false;
end

-- Why bother with this one?  I don't know either.
function MountThis:Dismount()
	-- Can't depend on DismissCompanion because of Druids ;)
	--DismissCompanion(MOUNT);
        -- If you're in a vehicle, leave the vehicle instead
        if IsUsingVehicleControls() then VehicleExit() end;
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
	
	if MountThisSettings.debug > 1 and false then
		self:Communicate("Random mount flags: "..tostring(rFlying).." "..tostring(rSpeed)..
						" "..tostring(rRequireSkill).." "..tostring(rRidingSkill))
	end

	local ZoneNames = { GetMapZones(4) } ;
	local canFlyInNorthrend = false
	local inNorthrend = false;
        local inAhnQiraj = GetZoneText() == "Ahn'Qiraj";
	for index, zoneName in pairs(ZoneNames) do if zoneName == GetZoneText() then inNorthrend = true; end end
	if MountThis:CheckSkill("Cold Weather Flying") ~= nil then canFlyInNorthrend = true; end
	
	-- Yes, I decided to go through the whole list of mounts and do the checking that way...
	mount_table = MountThisSettings.Mounts;
	-- Create a temporary table that uses an integer index rather than dictionary
	-- This already makes me think I should rewrite the table structures...
	local possible_mounts = {};
	for mount_name in pairs(mount_table) do
		if MountThisSettings.debug >= 1 then self:Communicate("Checking "..mount_name.." for use"); end
		--self:Communicate("Debug setting: "..MountThisSettings.debug);
		
		-- If we have it set to not use a mount, don't do anything else
		if mount_table[mount_name].use_mount then
			-- Easier to say it is valid and then invalidate it (coding-wise anyway)
			local matches_requirements = true;

			-- Check each of the requirements to see if they're valid for this random search
			-- If it's nil, then we don't care.  Otherwise, check the value
			if rFlying ~= nil then
				if rFlying ~= mount_table[mount_name].flying then matches_requirements = false end
			end
			if rSpeed ~= nil then
				if rSpeed ~= mount_table[mount_name].speed then matches_requirements = false end
			end
			if rRequireSkill ~= nil then 
				if rRequireSkill ~= mount_table[mount_name].required_skill then matches_requirements = false end
			end
			if rRidingSkill ~= nil then 
				if rRidingSkill ~= mount_table[mount_name].riding_skill_based then matches_requirements = false end
			end
			if rPassengers ~= nil then 
				if rPassengers ~= mount_table[mount_name].passengers then matches_requirements = false end
			end
			
			-- Cold Weather Flying yet?
			if inNorthrend and not canFlyInNorthrend and rFlying then
				matches_requirements = false
			end
			if mount_table[mount_name].ahnqiraj and not inAhnQiraj then
				matches_requirements = false
			end
			
			if matches_requirements then
				if MountThisSettings.debug > 1 then self:Communicate(" - Added "..mount_name.." to potential mounts"); end
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
	
	return possible_mounts[random(#possible_mounts)];
end

-- Return the value of a specific skill, nil if you don't have it
function MountThis:CheckSkill(check_skill_name)
	for skillIndex = 1, GetNumSkillLines() do
	  local skillName, _, _, skillRank = GetSkillLineInfo(skillIndex);
	  --self:Communicate(skillName..": "..tostring(skillRank));
	  if string.lower(skillName) == string.lower(check_skill_name) then
		 if MountThisSettings.debug > 1 then self:Communicate("Skill: "..skillName.." - "..skillRank); end
		 return skillRank;
	  end
	end
	local spellName = GetSpellInfo(check_skill_name);
	--self:Communicate(spellName);
	if spellName ~= nil then return true end
	if MountThisSettings.debug > 1 then self:Communicate("Skill: "..check_skill_name.." - not found"); end
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
		self:Communicate(text);

		--[[--
		local skill_level, skill_type = string.match(text, "Requires (%d+) skill in (%a+)");
		if skill_type ~= nil then 
			self:Communicate("Found: "..skill_level.." "..skill_type);
			self:CheckSkill(skill_type);
		end
		local skill_level, skill_type = string.match(text, "Requires (%d+) (%a+) skill");
		if skill_type ~= nil then
			self:Communicate("Found: "..skill_level.." "..skill_type);
			self:CheckSkill(skill_type);
		end
		--]]--
	end
	MountThisTooltip:Hide();
end
 = 'General',
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
				},
				mounts = 
				{
					type = 'multiselect',
					name = 'Mounts',
					desc = '',
					--[--
					values = function(info)
						local mount_names = {};
						--local use_mounts = {};
						for mount_name in pairs(MountThisSettings.Mounts) do
							mount_names[mount_name] = mount_name;
							--use_mounts[mount_name] = MountThisSettings.Mounts[mount_name].use_mount;
						end
						--return mount_names, nil, use_mounts;
						return mount_names;
					end,
					--]--
					get = function(info, key)
						return MountThisSettings.Mounts[key].use_mount;
					end,
					set = function(info, key, value)
						--MountThis:Communicate("Set: "..key.." - "..tostring(value));
						MountThisSettings.Mounts[key].use_mount = value;
						return MountThisSettings.Mounts[key].use_mount;
					end,
					width = 'full',
				},
			},
		},
		Debugging =
		{
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
				},
				version =
				{
					type = 'execute',
					name = 'Version',
					desc = 'Show MountThis version',
					order = 2,
					func = function() MountThis:Print("You are using MountThis version " .. MountThis.version) end,
					--hidden = guiHidden,
				},
				list = 
				{
					type = 'execute',
					name = 'List',
					desc = 'List all mounts known to MountThis',
					order = 3,
					func = function() MountThis:ListMounts(true) end,
					--hidden = guiHidden,
				}
			}
		}
    }
}
MountThis = LibStub("AceAddon-3.0"):NewAddon("MountThis", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0");
MountThis.version = "Beta 2";
MountThis.reqVersion = MountThis.version;
MountThis.optionsFrames = {};
MountThisSettings =
{
	Mounts = {},
	--coldweatherflying = 0,
	debug = 0,
	dismountIfMounted = true,
};
MountThisSettingsDefaults = MountThisSettings;

--MountThis.SwiftFlightFormButton = CreateFrame("Button", "SwiftFlightFormButton", UIParent, "SecureAnchorButtonTemplate");
--MountThis.SwiftFlightFormButton:setAttribute('type*', 'spell');
--MountThis.SwiftFlightFormButton:setAttribute('spell', 'Swift Flight Form');


function MountThis:Init()
	if not MountThisSettings then
		self:Communicate("No MountThisSettings found");
		MountThisSettings = MountThisSettingsDefaults;
	end

	-- Important to only set this when trying to debug
	--MountThisSettings.debug = 0;
	--if not MountThisSettings.coldweatherflying then MountThisSettings.coldweatherflying = defaults.coldweatherflying; end
	--if not MountThisSettings.Mounts then MountThisSettings.Mounts = defaults.Mounts; end

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
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("COMPANION_LEARNED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function MountThis:VARIABLES_LOADED()
	self:Init();
	self:UpdateMounts();
	if MountThisSettings.debug >=1 then self:Print("Variables loaded"); end
end

function MountThis:COMPANION_LEARNED()
	self:UpdateMounts();
	--self:Print("Updated mount data");
end
function MountThis:PLAYER_ENTERING_WORLD()
	self:UpdateMounts(true);
	--self:Print("Updated mount data");
end

function MountThis:UpdateMounts(force_update)
	if force_update and MountThisSettings.debug >= 1 then self:Communicate("Force updating mount information");
	elseif MountThisSettings.debug >= 1 then self:Communicate("Using cached information from saved variables when possible");
	end

	-- Loop through all the mounts (yes, mounts are "companions" now)
	for i = 1, GetNumCompanions("MOUNT") do
		local _,mount_name,spellID = GetCompanionInfo("MOUNT",i);
		if MountThisSettings.debug >= 1 then self:Communicate("Found mount: "..mount_name.." at index "..i); end

		-- Set up a temporary mount object
		local current_mount =
		{
			name = mount_name;
			index = i;
			speed = 0;
			flying = false;
			require_skill = false;
			riding_skill_based = false;
			passengers = 0;
			use_mount = true;
		}

		-- Set up our local frame for reading
		GameTooltip_SetDefaultAnchor(MountThisTooltip, UIParent);
		MountThisTooltip:SetHyperlink("spell:"..spellID);
		if type(MountThisSettings.Mounts) ~= "table" then MountThisSettings.Mounts = {} end;
		-- We make an assumption that the tooltip isn't changing
		-- TODO: Add override to allow reinitialization (will help if they change text)
		if force_update or not MountThisSettings.Mounts[mount_name] then
			if not force_update then self:Communicate("Mount: "..mount_name.." not in mounts table"); end

			local outland, northrend, ahnqiraj, extremely, very, require_skill, riding_skill_based, passengers;
			-- Cycle through the lines of our tooltip to figure out the kind of mount
			for i = 1, MountThisTooltip:NumLines() do
				local text = _G["MountThisTooltipTextLeft"..i]:GetText();

				--[[--
				Flying mounts typically mention "This mount can only be summoned in Outland or Northrend"
				There are variable speed mounts like "Big Blizzard Bear" and skill mounts like the
				Flying Machine and Flying Carpet
				--]]--
				for word in string.gmatch(text, "%a+") do
					if word == "Outland" then outland = true;
					elseif word == "Northrend" then northrend = true;
					elseif word == "Ahn'Qiraj" then ahnqiraj = true;
					elseif word == "extremely" then extremely = true;
					elseif word == "very" then very = true;
					--elseif word == "Requires" then require_skill = true;
					--elseif word == "Riding" then riding_skill_based = true;
					--elseif word == "passengers" then passengers = 1;
					end
				end

				-- Profession skill seems to come in more than one form
				local skill_level, skill_type = string.match(text, "Requires (%d+) skill in (%a+)");
				if skill_type ~= nil then require_skill = skill_type end
				skill_level, skill_type = string.match(text, "Requires (%d+) (%a+) skill");
				if skill_type ~= nil then require_skill = skill_type end

				-- Let's see how many passengers we can take
				passengers = string.match(text, "carry (%d+) passengers");
				if passengers ~= nil then passengers = 0 end

				-- Set the mount's flying ability
				if northrend or outland then current_mount.flying = true end
				
				-- Set up the speed of the mount
				if current_mount.flying then
					if extremely then current_mount.speed = 310;
					elseif very then current_mount.speed = 280;
					else current_mount.speed = 60;
					end
				else
					if very then current_mount.speed = 100;
					else current_mount.speed = 60;
					end
				end

				-- This is a huge stretch because I have no real data to work with
				if string.match(text, "depending on your Riding skill") ~= nil then
					current_mount.riding_skill_based = true
					skill_level = self:CheckSkill("Riding");
					if not current_mount.flying then
						if skill_level == nil or skill_level == 0 then current_mount.speed = 0;
						elseif skill_level == 75 then current_mount.speed = 60;
						elseif skill_level >= 150 then current_mount.speed = 100;
						end
					else
						if skill_level == nil or skill_level < 225 then current_mount.speed = 0;
						elseif skill_level == 225 then current_mount.speed = 60;
						elseif skill_level >= 300 then current_mount.speed = 280;
						end
					end
				end


			end

			-- Don't override the use_mount settings
			if MountThisSettings.Mounts[mount_name] then
				-- We have the mount in the table already. Use the saved value (check for nils, just in case)
				if MountThisSettings.Mounts[mount_name].use_mount ~= nil then
					current_mount.use_mount = MountThisSettings.Mounts[mount_name].use_mount;
				end
			end

			-- I can't say I always know what the pattern matches will return...
			if MountThisSettings.debug >=1 and not force_update then
				self:Communicate("Mount flags...");
				self:Communicate("- northrend: "..tostring(northrend));
				self:Communicate("- outland: "..tostring(outland));
				self:Communicate("- extremely: "..tostring(extremely));
				self:Communicate("- very: "..tostring(very));
				self:Communicate("- require_skill: "..tostring(require_skill));
				self:Communicate("- riding_skill_based: "..tostring(riding_skill_based));
				self:Communicate("- passengers: "..tostring(passengers));
				self:Communicate("- use_mount: "..tostring(current_mount.use_mount));
			end
			
			-- Add it to the global mounts table
			MountThisSettings.Mounts[mount_name] = current_mount;
		end
		MountThisSettings.Mounts[mount_name].index = i;
		if MountThisSettings.debug >=1 then self:Communicate("Set the index for mount: "..mount_name.." to "..i); end
	end
	MountThisTooltip:Hide();
end

function MountThis:Communicate(str)
	-- This function could be used to make comments when summoning if I was so inclined
	self:Print(str);
end

function MountThis:ListMounts(request_short)
	self:Communicate("ListMounts:");
	for name, data in pairs(MountThisSettings.Mounts) do
		self:Communicate("- "..name.." - flying: "..tostring(data.flying)..
						" - "..tostring(data.speed).."%"..
						" - req_skill: "..tostring(data.require_skill)..
						" - riding_skill: "..tostring(data.riding_skill_based)..
						" - passengers: "..tostring(data.passengers));
	end
end

function MountThis:FlyableArea()
	-- Continents 3 (Outland) and 4 (Northrend) are flyable
	for continent_index = 3, 4 do
		local ZoneNames = { GetMapZones(continent_index) } ;
		-- At some point we need to know exact spellings/areas for the "No Fly" zones
		for index, zoneName in pairs(ZoneNames) do
			--if zoneName ~= "Lake Wintergrasp" and zoneName ~= "Dalaran" then return false end
			if zoneName == GetZoneText() then
				if self:CheckSkill("Cold Weather Flying") == nil and continent_index == 4 then return false; end
				return true;
			end
		end
	end
	return false;
end

-- Find the fastest random mount you can use (flying first)
-- The druid shapeshift form isn't counted in the random at this time
function MountThis:MountRandom()
	local player_class = UnitClass("player");
	player_class = '';
	if self:FlyableArea() then
		--self:Communicate("Take the high road...");
		if self:Mount(self:Random(true,310)) then return true; end
		if self:Mount(self:Random(true,280)) then return true; end
		-- Check to see if you're a fast druid (this should work if you're moving)
		if player_class == 'Druid' then
			--if MountThis:CheckSkill('Swift Flight Form') and CastSpellByName('Swift Flight Form') then return true; end
			SwiftFlightFormButton.click()
		end
		if self:Mount(self:Random(true,60)) then return true; end
		-- Slow flying druid
		if player_class == 'Druid' then
			if MountThis:CheckSkill('Flight Form') and CastSpellByName('Flight Form') then return true; end
		end
	end
	--self:Communicate("You can't fly here. Travelling by land...");
	if self:Mount(self:Random(false,100)) then return true; end
	if self:Mount(self:Random(false,60)) then return true; end
	-- Druid travel form
	if player_class == 'Druid' then
		if MountThis:CheckSkill('Travel Form') and CastSpellByName('Travel Form') then return true; end
	end
	if player_class == 'Shaman' then
		if MountThis:CheckSkill('Ghost Wolf') and CastSpellByName('Ghost Wolf') then return true; end
	end
	return false;
end


-- Give a mount name and I'll use it, otherwise, it's a random mount
function MountThis:Mount(companionID)
	if IsMounted() then
		if MountThisSettings.debug >=1 then self:Communicate("Already mounted"); end
		-- I'll have to figure out how to get this initialized on startup, but it's here to make sure
		if MountThisSettings.dismountIfMounted == nil then MountThisSettings.dismountIfMounted = false; end
		if MountThisSettings.dismountIfMounted then
			if MountThisSettings.debug >=1 then self:Communicate("Dismounting only"); end
			return self:Dismount();
		end
	end
	
	if companionID ~= nil then CallCompanion(MOUNT, companionID); return true; end
	-- DON'T DO THIS UNLESS YOU CHANGE MountRandom(). Stack overflow if no appropriate mount found
	--else return self:MountRandom(); end
	return false;
end

-- Why bother with this one?  I don't know either.
function MountThis:Dismount()
	-- Can't depend on DismissCompanion because of Druids ;)
	--DismissCompanion(MOUNT);
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
	
	if MountThisSettings.debug > 1 and false then
		self:Communicate("Random mount flags: "..tostring(rFlying).." "..tostring(rSpeed)..
						" "..tostring(rRequireSkill).." "..tostring(rRidingSkill))
	end

	local ZoneNames = { GetMapZones(4) } ;
	local canFlyInNorthrend = false
	local inNorthrend = false;
	for index, zoneName in pairs(ZoneNames) do if zoneName == GetZoneText() then inNorthrend = true; end end
	if self:CheckSkill("Cold Weather Flying") ~= nil then canFlyInNorthrend = true; end
	
	-- Yes, I decided to go through the whole list of mounts and do the checking that way...
	mount_table = MountThisSettings.Mounts;
	-- Create a temporary table that uses an integer index rather than dictionary
	-- This already makes me think I should rewrite the table structures...
	local possible_mounts = {};
	for mount_name in pairs(mount_table) do
		if MountThisSettings.debug >= 1 then self:Communicate("Checking "..mount_name.." for use"); end
		--self:Communicate("Debug setting: "..MountThisSettings.debug);
		
		-- If we have it set to not use a mount, don't do anything else
		if mount_table[mount_name].use_mount then
			-- Easier to say it is valid and then invalidate it (coding-wise anyway)
			local matches_requirements = true;

			-- Check each of the requirements to see if they're valid for this random search
			-- If it's nil, then we don't care.  Otherwise, check the value
			if rFlying ~= nil then
				if rFlying ~= mount_table[mount_name].flying then matches_requirements = false end
			end
			if rSpeed ~= nil then
				if rSpeed ~= mount_table[mount_name].speed then matches_requirements = false end
			end
			if rRequireSkill ~= nil then 
				if rRequireSkill ~= mount_table[mount_name].required_skill then matches_requirements = false end
			end
			if rRidingSkill ~= nil then 
				if rRidingSkill ~= mount_table[mount_name].riding_skill_based then matches_requirements = false end
			end
			if rPassengers ~= nil then 
				if rPassengers ~= mount_table[mount_name].passengers then matches_requirements = false end
			end
			
			-- Cold Weather Flying yet?
			if inNorthrend and not canFlyInNorthrend and mount_table[mount_name].flying then
				matches_requirements = false
			end
			
			if matches_requirements then
				if MountThisSettings.debug > 1 then self:Communicate(" - Added "..mount_name.." to potential mounts"); end
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
	
	return possible_mounts[random(#possible_mounts)];
end

-- Return the value of a specific skill, nil if you don't have it
function MountThis:CheckSkill(check_skill_name)
	for skillIndex = 1, GetNumSkillLines() do
	  local skillName, _, _, skillRank = GetSkillLineInfo(skillIndex);
	  --self:Communicate(skillName..": "..tostring(skillRank));
	  if string.lower(skillName) == string.lower(check_skill_name) then
		 if MountThisSettings.debug > 1 then self:Communicate("Skill: "..skillName.." - "..skillRank); end
		 return skillRank;
	  end
	end
	local spellName = GetSpellInfo(check_skill_name);
	--self:Communicate(spellName);
	if spellName ~= nil then return true end
	if MountThisSettings.debug > 1 then self:Communicate("Skill: "..check_skill_name.." - not found"); end
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
		self:Communicate(text);

		--[[--
		local skill_level, skill_type = string.match(text, "Requires (%d+) skill in (%a+)");
		if skill_type ~= nil then 
			self:Communicate("Found: "..skill_level.." "..skill_type);
			self:CheckSkill(skill_type);
		end
		local skill_level, skill_type = string.match(text, "Requires (%d+) (%a+) skill");
		if skill_type ~= nil then
			self:Communicate("Found: "..skill_level.." "..skill_type);
			self:CheckSkill(skill_type);
		end
		--]]--
	end
	MountThisTooltip:Hide();
end
