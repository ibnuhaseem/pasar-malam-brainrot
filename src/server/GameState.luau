-- GameState: the one place the server keeps its state.
-- Per player: cash, pending income, stall, owned characters, and the
-- character they are carrying. Per stall: owner. Nothing else holds state.

local WorldConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WorldConfig"))

local GameState = {}

GameState.STARTING_CASH = 200
GameState.MAX_STALL_CHARACTERS = WorldConfig.STALL_SLOTS

-- player -> state table
GameState.players = {}
-- stallIndex -> { owner = player|nil }
GameState.stalls = {}
for _, stall in ipairs(WorldConfig.STALLS) do
	GameState.stalls[stall.index] = {
		owner = nil,
	}
end

-- Hooks Main.server.luau fills in after the remotes exist. Every server
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
		-- owned: array of { charId, mutation, rarity, rate, slot, model }
		owned = {},
		-- carrying: { charId, mutation, rate, price, model } | nil
		carrying = nil,
	}
end

-- The money per second of everything a player owns.
function GameState.incomePerSecond(state)
	local total = 0
	for _, owned in ipairs(state.owned) do
		total += owned.rate
	end
	return total
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

return GameState
