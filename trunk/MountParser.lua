if (IsAddOnLoaded("LibMounts-1.0")) then MountParser = LibStub("LibMounts-1.0") end
if MountParser == nil then MountParser = {} end

CreateFrame("GameTooltip","MountParserTooltip",UIParent,"GameTooltipTemplate");
MountParserTooltip:Hide()

function MountParser:ParseMount(companion_index, spellID)

	local text = ""
	if companion_index ~= nil then _,mount_name,spellID = GetCompanionInfo("MOUNT",companion_index); end
	
	local buffSpellID, land, air, sea = MountParser:ParseMountFromBuff()
	if spellID == nil then spellID = buffSpellID end
	if spellID == nil then return nil end	-- No spellID? Well, what the hell are we parsing?

	if mount_name == nil then mount_name = GetSpellInfo(spellID) end
	if mount_name == nil then return end;

	if companion_index == nil then companion_index = MountParser:GetCompanionIndex(mount_name) end

	-- Set up a temporary mount object
	local current_mount =
	{
		name = mount_name;
		spellID = spellID;
		index = companion_index;
		land = true;	-- assume all mounts are at least land mounts
		use_mount = true;
	}

	-- If we have the GetMountInfo function from LibMount, use it
	if MountParser.GetMountInfo ~= nil then 
		current_mount.land, current_mount.flying, current_mount.swimming, _, current_mount.zone, current_mount.passengers = MountParser:GetMountInfo(spellID)
		if current_mount.land ~= nil or current_mount.flying ~= nil and current_mount.swimming ~= nil then	-- LibMount must not have found a new mount
			return current_mount
		end
	end

	-- No LibMount or LibMount didn't find the mount, so we do our own bastardized parsing
	local outland, northrend, ahnqiraj, require_skill, riding_skill_based, passengers;
	local text = GetSpellDescription(spellID);

	-- If we parsed from a buff, apply mount capability
	if spellID == buffSpellID then
		if land then current_mount.land = true end
		if air then current_mount.flying = true end
		if sea then current_mount.swimming = true end
	end

	--[[--
	Pre-Cata: Flying mounts typically mention "This mount can only be summoned in Outland or Northrend"
	Swimming mounts usually explicitly state that.
	--]]--
	
	for word in string.gmatch(text, "%a+") do
		if word == "Outland" then outland = true;
		elseif word == "Northrend" then northrend = true;
		elseif word == "Vashj'ir" then current_mount.swimming = true;
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

	passengers = string.match(text, "carry (%d+) passengers");
	if passengers ~= nil then current_mount.passengers = 0 end;

	-- Check for known zone restrictions
	if string.match(text, "Ahn'Qiraj") ~= nil then current_mount.zone = "Temple of Ahn'Qiraj"; end
	if string.match(text, "Vashj'ir") ~= nil then current_mount.zone = "Vashj'ir"; end

	-- Set the mount's flying ability
	if northrend ~= nil or outland ~= nil then current_mount.flying = true end;

	return current_mount
end

function MountParser:ParseMountFromBuff()
	--if not IsMounted() then return nil end
	
	-- Build an array of mount spellIDs from the companion table
	--local mount_ids = newtable()
	local mount_ids = {}
	for companion_index = 1, GetNumCompanions("MOUNT") do
		local _,mount_name,spellID = GetCompanionInfo("MOUNT",companion_index);
		tinsert(mount_ids, spellID)
	end

	GameTooltip_SetDefaultAnchor(MountParserTooltip, UIParent);

	local land = nil
	local flying = nil
	local swimming = nil
	for i = 1, BUFF_MAX_DISPLAY do
		--local n,r,it,c,dt,d,et,s,is,sc,si,extra1 = UnitAura("player",i,"helpful");
		local n,r,it,c,dt,d,et,s,is,sc,si,extra1 = UnitAura("player",i);
		for index, spellID in pairs(mount_ids) do
			if spellID == si then
				MountParserTooltip:SetUnitAura("player", i)
				for tt_line = 1, MountParserTooltip:NumLines() do
					local text = _G["MountParserTooltipTextLeft"..tt_line]:GetText();
					if text ~= n then
						if string.find(text, 'ground') ~= nil then land = true end
						if string.find(text, 'flight') ~= nil then flying = true end
						if string.find(text, 'swim') ~= nil then swimming = true end
					end
				end
				MountParserTooltip:Hide()
				return spellID, land, flying, swimming
			end
		end
	end
	return nil
end

function MountParser:GetCompanionIndex(mount_name)
	if mount_name == nil then return nil end
	for index = 1, GetNumCompanions("MOUNT") do
		local _,name,spellID = GetCompanionInfo("MOUNT",index);
		if mount_name == name then return index end
	end
end