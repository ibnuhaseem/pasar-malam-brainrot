-- WorldConfig: the single source of truth for where things are in the night market.
-- The place file (default.project.json) is built from these same numbers, so
-- the code and the world never disagree about a stall or the lane.

local WorldConfig = {}

-- The market lane down the middle. Characters spawn at the north gate and
-- walk south until they leave at the far end.
WorldConfig.LANE_X = 0
WorldConfig.LANE_Z_START = -70
WorldConfig.LANE_Z_END = 70
WorldConfig.LANE_WIDTH = 26
WorldConfig.WALK_SPEED = 4 -- studs per second
WorldConfig.SPAWN_INTERVAL = 4 -- seconds between spawns
WorldConfig.MAX_LANE_CHARACTERS = 12

-- 8 stalls, 4 on each side of the lane. Each stall faces the lane.
-- side: -1 = west (x negative), +1 = east. Stall centers sit 26 studs out.
WorldConfig.STALL_COUNT = 8
WorldConfig.STALL_SLOTS = 8
WorldConfig.STALLS = {
	{ index = 1, x = -26, z = -45, side = -1 },
	{ index = 2, x = 26, z = -45, side = 1 },
	{ index = 3, x = -26, z = -15, side = -1 },
	{ index = 4, x = 26, z = -15, side = 1 },
	{ index = 5, x = -26, z = 15, side = -1 },
	{ index = 6, x = 26, z = 15, side = 1 },
	{ index = 7, x = -26, z = 45, side = -1 },
	{ index = 8, x = 26, z = 45, side = 1 },
}

-- A stall's footprint, used for the "are you home" raid check.
WorldConfig.STALL_HALF_WIDTH = 9
WorldConfig.STALL_HALF_DEPTH = 7

-- Pedestal pads inside a stall: 2 rows of 4, measured from the stall center.
-- Row 1 is nearer the lane, row 2 nearer the back wall.
function WorldConfig.slotPosition(stall, slotIndex)
	local col = (slotIndex - 1) % 4 -- 0..3 across
	local row = math.floor((slotIndex - 1) / 4) -- 0..1 back
	local across = -4.5 + col * 3
	local depth = -2 + row * 4
	-- West stalls face +x, east stalls face -x: mirror the across offset.
	local x = stall.x + across * stall.side * -1
	local z = stall.z + depth
	return Vector3.new(x, 1.4, z) -- the pedestal pad top
end

-- The stall's front (lane-side) edge, where the place pad sits.
function WorldConfig.placePadPosition(stall)
	return Vector3.new(stall.x + 9 * stall.side * -1, 1.1, stall.z)
end

-- Is a world position inside a stall's footprint (the raid safe zone)?
function WorldConfig.isInsideStall(stall, position)
	return math.abs(position.X - stall.x) <= WorldConfig.STALL_HALF_WIDTH
		and math.abs(position.Z - stall.z) <= WorldConfig.STALL_HALF_DEPTH
end

-- Where new players spawn, by the north gate.
WorldConfig.SPAWN_POSITION = Vector3.new(0, 3, -58)

-- The raid: how often, how long the warning lasts, how long the raid lasts.
WorldConfig.RAID_INTERVAL = 150 -- seconds between raids
WorldConfig.RAID_WARNING = 20 -- seconds of siren before the raid hits
WorldConfig.RAID_DURATION = 10 -- seconds the raid stays active

-- Steal rules.
WorldConfig.STEAL_COOLDOWN = 15 -- seconds before the same stall can be stolen from again

-- Lock rules.
WorldConfig.LOCK_DURATION = 30 -- seconds a lock lasts
WorldConfig.LOCK_COOLDOWN = 20 -- seconds before the same stall can lock again

-- Naik Kelas (rebirth): level -> { name, cost, multiplier }.
WorldConfig.REBIRTH_LEVELS = {
	{ name = "Gerobak", cost = 0, multiplier = 1 },
	{ name = "Kios", cost = 25000, multiplier = 2 },
	{ name = "Ruko", cost = 250000, multiplier = 4 },
	{ name = "Mall", cost = 2500000, multiplier = 8 },
}

-- Pesanan (missions): id -> { name, description, target, reward }.
-- progress is counted in GameState; see Economy.claimMission.
WorldConfig.MISSIONS = {
	{ id = "own-3", name = "Kolektor Pemula", description = "Punya 3 karakter di kios", target = 3, reward = 500 },
	{ id = "own-rare", name = "Rasa Langka", description = "Punya 1 karakter Rare atau lebih", target = 1, reward = 1500 },
	{ id = "own-3-legendary", name = "Tiga Legenda", description = "Punya 3 karakter Legendary", target = 3, reward = 25000 },
	{ id = "lock-3", name = "Penjaga Kios", description = "Kunci kiosmu 3 kali", target = 3, reward = 2000 },
	{ id = "rebirth-1", name = "Naik Kelas", description = "Naik Kelas sekali", target = 1, reward = 10000 },
}

return WorldConfig
