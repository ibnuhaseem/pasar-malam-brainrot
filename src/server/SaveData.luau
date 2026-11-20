-- SaveData: persists a player's cash in a DataStore. Every call is wrapped
-- in pcall: in Studio without API access (or when Roblox is unreachable)
-- the game simply keeps playing without saving. Placed characters are
-- session-only and are not saved.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local SaveData = {}

SaveData.STORE_NAME = "PasarMalamBrainrot_v1"
SaveData.AUTOSAVE_INTERVAL = 60

local store = nil
local ok, result = pcall(function()
	return DataStoreService:GetDataStore(SaveData.STORE_NAME)
end)
if ok then
	store = result
end

-- Load a player's saved data into their state. Returns true when a save existed.
function SaveData.loadPlayerData(player, state)
	if not store then
		return false
	end
	local data
	local success, err = pcall(function()
		data = store:GetAsync("player_" .. player.UserId)
	end)
	if not success or type(data) ~= "table" then
		return false
	end
	if type(data.cash) == "number" then
		state.cash = data.cash
	end
	return true
end

-- Save one player's state now.
function SaveData.savePlayerData(player, state)
	if not store or not state then
		return false
	end
	local data = {
		cash = math.floor(state.cash),
	}
	local success, _err = pcall(function()
		store:SetAsync("player_" .. player.UserId, data)
	end)
	return success
end

-- Save every player currently in the game.
function SaveData.saveAllPlayers(players)
	for player, state in pairs(players) do
		SaveData.savePlayerData(player, state)
	end
end

-- Start the autosave loop and the save-on-leave hook.
function SaveData.init(players)
	Players.PlayerRemoving:Connect(function(player)
		local state = players[player]
		if state then
			SaveData.savePlayerData(player, state)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(SaveData.AUTOSAVE_INTERVAL)
			SaveData.saveAllPlayers(players)
		end
	end)
end

return SaveData
