-- Main.server: the server bootstrap for Pasar Malam Brainrot (simple version).
-- Pick (buy off the lane), bring (carry), drop (place in your stall), and
-- the money system (income per second + collect). Nothing else.
-- Creates the remotes, assigns stalls, runs the income tick, and wires every
-- RemoteEvent to the module that owns it. State lives in GameState; this file
-- only connects things.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CharacterSpawner = require(script.Parent.CharacterSpawner)
local Economy = require(script.Parent.Economy)
local GameState = require(script.Parent.GameState)
local SaveData = require(script.Parent.SaveData)
local WorldConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WorldConfig"))

-- The remotes, created once at startup.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

local Remotes = {
	PlaceCharacter = makeRemote("PlaceCharacter"),
	CollectCash = makeRemote("CollectCash"),
	StateUpdate = makeRemote("StateUpdate"),
	Notify = makeRemote("Notify"),
}

-- The state snapshot the client HUD renders.
local function buildStateSnapshot(state)
	local owned = {}
	for _, record in ipairs(state.owned) do
		table.insert(owned, {
			charId = record.charId,
			mutation = record.mutation,
			rarity = record.rarity,
			rate = record.rate,
			slot = record.slot,
		})
	end
	local carrying = nil
	if state.carrying then
		carrying = {
			charId = state.carrying.charId,
			mutation = state.carrying.mutation,
			rate = state.carrying.rate,
		}
	end
	return {
		cash = math.floor(state.cash),
		pending = math.floor(state.pending),
		income = GameState.incomePerSecond(state),
		carrying = carrying,
		owned = owned,
		ownedCount = #state.owned,
		ownedSlots = GameState.MAX_STALL_CHARACTERS,
		stallIndex = state.stallIndex,
		nextSpawnIn = math.max(0, math.ceil(CharacterSpawner.nextSpawnIn)),
		nextSpawn = CharacterSpawner.nextPreview,
	}
end

-- Send one player their fresh snapshot.
local function broadcastState(player)
	local state = GameState.players[player]
	if not state then
		return
	end
	Remotes.StateUpdate:FireClient(player, buildStateSnapshot(state))
end

-- Send one player a toast message.
local function notifyPlayer(player, text, color)
	Remotes.Notify:FireClient(player, text, color)
end

GameState.broadcastState = broadcastState
GameState.notifyPlayer = notifyPlayer

-- The lowest free stall, or nil when all 8 are taken.
local function claimFreeStall(player)
	for _, stall in ipairs(WorldConfig.STALLS) do
		local record = GameState.stalls[stall.index]
		if record.owner == nil then
			record.owner = player
			return stall.index
		end
	end
	return nil
end

-- Write the owner's name on the stall sign, or "KIOS KOSONG" when free.
local function updateStallSign(stallIndex)
	local folder = Workspace:FindFirstChild("Stall" .. stallIndex)
	if not folder then
		return
	end
	local sign = folder:FindFirstChild("Sign")
	local gui = sign and sign:FindFirstChild("SignGui")
	local label = gui and gui:FindFirstChild("SignText")
	if not label then
		return
	end
	local record = GameState.stalls[stallIndex]
	if record.owner then
		label.Text = "KIOS " .. string.upper(record.owner.DisplayName)
	else
		label.Text = "KIOS KOSONG"
	end
end

-- A player joins: claim a stall, load their save, send the first snapshot.
local function onPlayerAdded(player)
	local stallIndex = claimFreeStall(player)
	if not stallIndex then
		player:Kick("Pasar sudah penuh! Coba lagi nanti.")
		return
	end
	local state = GameState.newPlayerState(player, stallIndex)
	GameState.players[player] = state
	SaveData.loadPlayerData(player, state)
	updateStallSign(stallIndex)
	-- The character spawns at the gate; teleport them to their stall door.
	local function teleportToStall(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root then
			local stall = WorldConfig.STALLS[stallIndex]
			root.CFrame = CFrame.new(stall.x + 12 * stall.side * -1, 3, stall.z)
		end
	end
	player.CharacterAdded:Connect(teleportToStall)
	if player.Character then
		task.spawn(teleportToStall, player.Character)
	end
	broadcastState(player)
	notifyPlayer(player, "Selamat datang di Pasar Malam! Beli karakter di lorong, bawa ke kiosmu.", Color3.fromRGB(255, 220, 90))
end

-- A player leaves: free the stall, clear their models, save.
local function onPlayerRemoving(player)
	local state = GameState.players[player]
	if not state then
		return
	end
	for _, owned in ipairs(state.owned) do
		if owned.model then
			owned.model:Destroy()
		end
	end
	if state.carrying and state.carrying.model then
		state.carrying.model:Destroy()
	end
	local record = GameState.stalls[state.stallIndex]
	if record and record.owner == player then
		record.owner = nil
		updateStallSign(state.stallIndex)
	end
	GameState.players[player] = nil
end

-- Wire the place pads: clicking your own stall's pad places what you carry.
local function wirePlacePads()
	for _, stall in ipairs(WorldConfig.STALLS) do
		local folder = Workspace:FindFirstChild("Stall" .. stall.index)
		if folder then
			local pad = folder:FindFirstChild("PlacePad")
			local click = pad and pad:FindFirstChild("PlaceClick")
			if click then
				click.MouseClick:Connect(function(player)
					local state = GameState.players[player]
					if not state or state.stallIndex ~= stall.index then
						notifyPlayer(player, "Itu bukan kiosmu!", Color3.fromRGB(255, 80, 80))
						return
					end
					local ok, result = CharacterSpawner.placeCarriedCharacter(player)
					if ok then
						notifyPlayer(player, "Karakter ditaruh di kios! Slot " .. result .. ".", Color3.fromRGB(90, 255, 130))
					else
						notifyPlayer(player, result, Color3.fromRGB(255, 80, 80))
					end
					broadcastState(player)
				end)
			end
		end
	end
end

-- Remote handlers.
Remotes.PlaceCharacter.OnServerEvent:Connect(function(player)
	local state = GameState.players[player]
	if not state then
		return
	end
	-- Only when the player is standing near their own stall.
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local stall = WorldConfig.STALLS[state.stallIndex]
	if root and stall and WorldConfig.isInsideStall(stall, root.Position) then
		local ok, result = CharacterSpawner.placeCarriedCharacter(player)
		if ok then
			notifyPlayer(player, "Karakter ditaruh di kios! Slot " .. result .. ".", Color3.fromRGB(90, 255, 130))
		else
			notifyPlayer(player, result, Color3.fromRGB(255, 80, 80))
		end
		broadcastState(player)
	else
		notifyPlayer(player, "Masuk dulu ke kiosmu untuk menaruh karakter.", Color3.fromRGB(255, 180, 60))
	end
end)

Remotes.CollectCash.OnServerEvent:Connect(function(player)
	local state = GameState.players[player]
	if not state then
		return
	end
	local amount = Economy.collectPendingCash(state)
	if amount > 0 then
		notifyPlayer(player, "Dikumpulkan $" .. amount .. "!", Color3.fromRGB(90, 255, 130))
	end
	broadcastState(player)
end)

-- The income tick: every second, pending income grows and every player gets
-- a fresh snapshot.
task.spawn(function()
	while true do
		task.wait(1)
		for player, state in pairs(GameState.players) do
			state.pending += GameState.incomePerSecond(state)
			broadcastState(player)
		end
	end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

wirePlacePads()
CharacterSpawner.init()
SaveData.init(GameState.players)

print("Pasar Malam Brainrot: server siap.")
