-- GameState: the one place the server keeps its state.
-- Per player: cash, pending income, rebirth level, stall, owned characters,
-- the character they are carrying, locks, missions and collection.
-- Per stall: owner, lock timers, steal cooldown. Nothing else holds state.

local WorldConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WorldConfig"))

local GameState = {}

GameState.STARTING_CASH = 200
GameState.MAX_STALL_CHARACTERS = WorldConfig.STALL_SLOTS

-- player -> state table
GameState.players = {}
-- stallIndex -> { owner = player|nil, lockedUntil = number, lockCooldownUntil = number, stealCooldownUntil = number }
GameState.stalls = {}
for _, stall in ipairs(WorldConfig.STALLS) do
	GameState.stalls[stall.index] = {
		owner = nil,
		lockedUntil = 0,
		lockCooldownUntil = 0,
		stealCooldownUntil = 0,
	}
end

-- The raid clock, shared by every player.
GameState.raid = {
	phase = "calm", -- "calm" | "warning" | "active"
	secondsLeft = WorldConfig.RAID_INTERVAL,
}

-- Hooks init.server.luau fills in after the remotes exist. Every server
-- module calls these instead of touching RemoteEvents itself.
GameState.notifyPlayer = function(_player, _text, _color) end
GameState.broadcastState = function(_player) end

-- A fresh state for a player who just joined.
function GameState.newPlayerState(player, stallIndex)
	return {
		player = player,
		stallIndex = stallIndex,
		cash = GameState.STARTING_CASH,
		pending = 0,
		rebirthLevel = 0,
		-- owned: array of { charId, mutation, rate, slot, model }
		owned = {},
		-- carrying: { charId, mutation, rate, price, model } | nil
		carrying = nil,
		locksUsed = 0,
		-- missions: missionId -> { progress, claimed }
		missions = {},
		-- collection: charId -> true (ever owned)
		collection = {},
	}
end

-- The income multiplier of a player's rebirth level.
function GameState.rebirthMultiplier(state)
	local level = WorldConfig.REBIRTH_LEVELS[state.rebirthLevel + 1]
	if level then
		return level.multiplier
	end
	return 1
end

-- The name of a player's rebirth level, e.g. "Gerobak".
function GameState.rebirthName(state)
	local level = WorldConfig.REBIRTH_LEVELS[state.rebirthLevel + 1]
	if level then
		return level.name
	end
	return "Gerobak"
end

-- The money per second of everything a player owns, after the multiplier.
function GameState.incomePerSecond(state)
	local total = 0
	for _, owned in ipairs(state.owned) do
		total += owned.rate
	end
	return total * GameState.rebirthMultiplier(state)
end

-- Free slot numbers in a player's stall (1..8).
function GameState.freeSlots(state)
	local used = {}
	for _, owned in ipairs(state.owned) do
		used[owned.slot] = true
	end
	local free = {}
	for slot = 1, GameState.MAX_STALL_CHARACTERS do
		if not used[slot] then
			table.insert(free, slot)
		end
	end
	return free
end

-- The stall record of a player (or nil when they have none).
function GameState.stallOf(state)
	if not state.stallIndex then
		return nil
	end
	return GameState.stalls[state.stallIndex]
end

-- Is a stall locked right now?
function GameState.isStallLocked(stallIndex)
	local stall = GameState.stalls[stallIndex]
	if not stall then
		return false
	end
	return os.clock() < stall.lockedUntil
end

-- Count how many owned characters of at least a rarity a player has.
function GameState.countOwnedAtLeast(state, rarityId)
	local ladder = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Secret = 6 }
	local want = ladder[rarityId] or 1
	local count = 0
	for _, owned in ipairs(state.owned) do
		-- The rarity is stored on the owned record when the character is placed.
		if (ladder[owned.rarity] or 1) >= want then
			count += 1
		end
	end
	return count
end

return GameState
