﻿AddCSLuaFile("includes/modules/caf_util.lua")
AddCSLuaFile("includes/modules/cache.lua")
require("caf_util")
require("cache")
local meta = FindMetaTable("Entity")

function meta:WaterLevel2()
	local waterlevel = self:WaterLevel()

	if self:GetPhysicsObject():IsValid() and self:GetPhysicsObject():IsMoveable() then
		--Msg("Normal WaterLEvel\n")
		--this doesn't look like it works when ent is welded to world, or not moveable
		return waterlevel
	end
	--Msg("Special WaterLEvel\n") --Broken in Gmod SVN!!!
	if waterlevel ~= 0 then return waterlevel end
	local pos = self:GetPos()
	local tr = util.TraceLine({
		start = pos,
		endpos = pos,
		filter = {self},
		mask = 16432 -- MASK_WATER
	})
	if tr.Hit then return 3 end
	return 0
end