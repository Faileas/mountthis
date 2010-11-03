MountParser = LibStub("LibMounts-1.0")
if MountParser == nil then MountParser = {} end

function MountParser:ParseMount(companion_index)
	local _,mount_name,spellID = GetCompanionInfo("MOUNT",companion_index);
	
	-- For some reason, GetCompanionInfo can return a nil mount name.  This tries to stop that
	if mount_name == nil then return end;

	-- Set up a temporary mount object
	local current_mount =
	{
		name = mount_name;
		spellID = spellID;
		index = companion_index;
		flying = nil;
		swimming = nil;
		land = true;	-- assume all mounts are at least land mounts
		require_skill = "";
		require_skill_level = 0;
		passengers = 0;
		use_mount = true;
		zone = nil;
	}

	-- If we have the GetMountInfo function from LibMount, use it
	if MountParser.GetMountInfo then 
		current_mount.land, current_mount.flying, current_mount.swimming, _, current_mount.zone, current_mount.passengers = LibStub("LibMounts-1.0"):GetMountInfo(spellID)
		return current_mount
	end
	
	-- No LibMount, so we do our own bastardized parsing
	local outland, northrend, ahnqiraj, require_skill, riding_skill_based, passengers;
	local text = GetSpellDescription(spellID);

	--[[--
	Flying mounts typically mention "This mount can only be summoned in Outland or Northrend"
	Swimming mounts usually explicitly state that.
	--]]--
	for word in string.gmatch(text, "%a+") do
		if word == "Outland" then outland = true;
		elseif word == "Northrend" then northrend = true;
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

	-- Ahn'Qiraj mounts are unique in that they do not use the normal "speed" keywords
	if string.match(text, "Ahn'Qiraj") ~= nil then
		--current_mount.ahnqiraj = true;
		current_mount.zone = "Temple of Ahn'Qiraj";
	end

	-- Set the mount's flying ability
	if northrend or outland then current_mount.flying = true end;

	return current_mount
end

function MountParser:ParseMountBuff()
	if not IsMounted() then return nil end
	for i = 1, 10 do
		local n,r,it,c,dt,d,et,s,is,sc,si = UnitBuff("player",i);
		if n ~= nil then
			ChatFrame1:AddMessage(n.." "..tostring(si))
		end
	end
	return nil
end