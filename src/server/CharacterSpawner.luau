-- CharacterSpawner: the lane. Characters roll a rarity and a mutation, spawn
-- at the north gate, walk the market lane, and leave at the far end.
-- Clicking a lane character buys it (server-side ClickDetector): the player
-- pays, then carries the character to their stall to place it.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CharacterFactory = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CharacterFactory"))
local Characters = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Characters"))
local GameState = require(script.Parent.GameState)
local Rarities = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Rarities"))
local WorldConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WorldConfig"))

local CharacterSpawner = {}

CharacterSpawner.laneFolder = nil
CharacterSpawner.laneCharacters = {} -- model -> { laneId, charId, mutation, rate, price }
CharacterSpawner.nextSpawnIn = WorldConfig.SPAWN_INTERVAL
CharacterSpawner.nextPreview = nil -- { charId, mutation } pre-rolled for the HUD
CharacterSpawner.nextLaneId = 1

-- Roll one character: rarity, then a character of that rarity, then a mutation.
local function rollCharacter()
	local rarity = Rarities.rollRarity()
	local char = Characters.randomOfRarity(rarity)
	local mutation = Rarities.rollMutation()
	local rate = char.rate * Rarities.multiplierOfMutation(mutation)
	return char, mutation, rate
end

-- Pre-roll the next spawn so the HUD can show "NEXT: ... in 3s".
local function previewNextSpawn()
	local char, mutation, _rate = rollCharacter()
	CharacterSpawner.nextPreview = { charId = char.id, mutation = mutation }
end

-- Spawn one character at the gate and wire its ClickDetector to buy it.
function CharacterSpawner.spawnLaneCharacter()
	local char, mutation, rate = rollCharacter()
	local model = CharacterFactory.buildCharacterModel(char.id, mutation, rate, char.price)
	if not model then
		return
	end
	local laneId = CharacterSpawner.nextLaneId
	CharacterSpawner.nextLaneId += 1
	local spawnPos = Vector3.new(WorldConfig.LANE_X, 1.0, WorldConfig.LANE_Z_START) -- the lane top
	CharacterFactory.moveModelTo(model, spawnPos)
	model.Name = char.name
	model.Parent = CharacterSpawner.laneFolder
	CharacterSpawner.laneCharacters[model] = {
		laneId = laneId,
		charId = char.id,
		mutation = mutation,
		rate = rate,
		price = char.price,
	}
	local click = model:FindFirstChild("Click")
	if click then
		click.MouseClick:Connect(function(player)
			CharacterSpawner.buyLaneCharacter(player, model)
		end)
	end
	previewNextSpawn()
end

-- Buy the lane character a player clicked. The player pays and carries it.
function CharacterSpawner.buyLaneCharacter(player, model)
	local record = CharacterSpawner.laneCharacters[model]
	if not record then
		return
	end
	local state = GameState.players[player]
	if not state then
		return
	end
	if state.carrying then
		GameState.notifyPlayer(player, "Kamu sudah membawa karakter! Taruh dulu di kiosmu.", Color3.fromRGB(255, 180, 60))
		return
	end
	if #GameState.freeSlots(state) == 0 then
		GameState.notifyPlayer(player, "Kiosmu penuh! Jual atau Naik Kelas dulu.", Color3.fromRGB(255, 80, 80))
		return
	end
	if state.cash < record.price then
		GameState.notifyPlayer(player, "Uang tidak cukup! Butuh $" .. record.price .. ".", Color3.fromRGB(255, 80, 80))
		return
	end
	state.cash -= record.price
	CharacterSpawner.laneCharacters[model] = nil
	state.carrying = {
		charId = record.charId,
		mutation = record.mutation,
		rate = record.rate,
		price = record.price,
		model = model,
	}
	-- The carried model stays anchored and hovers above the player's head,
	-- following them in the Heartbeat loop (no physics, no welds).
	model.Parent = Workspace
	GameState.notifyPlayer(player, "Dapat " .. Characters.displayName(record.charId, record.mutation) .. "! Bawa ke kiosmu (tekan E).", Color3.fromRGB(90, 255, 130))
	GameState.broadcastState(player)
end

-- Hover every carried model above its owner's head. Runs every Heartbeat.
function CharacterSpawner.followCarriedModels()
	for player, state in pairs(GameState.players) do
		if state.carrying and state.carrying.model and state.carrying.model.Parent then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				state.carrying.model:PivotTo(root.CFrame * CFrame.new(0, 4.5, 0))
			end
		end
	end
end

-- Place the carried character on the first free pedestal of the player's stall.
-- Returns true + slot, or false + the reason it failed.
function CharacterSpawner.placeCarriedCharacter(player)
	local state = GameState.players[player]
	if not state or not state.carrying then
		return false, "Kamu tidak membawa karakter."
	end
	local free = GameState.freeSlots(state)
	if #free == 0 then
		return false, "Kiosmu penuh!"
	end
	local stall = WorldConfig.STALLS[state.stallIndex]
	local slot = free[1]
	local carried = state.carrying
	local model = carried.model
	local slotPos = WorldConfig.slotPosition(stall, slot)
	-- Face the lane: west stalls look +X, east stalls look -X.
	CharacterFactory.placeModelAt(model, slotPos, math.rad(-90 * stall.side))
	-- Hide the lane price label now that it lives in a stall.
	local label = model:FindFirstChild("Label")
	if label then
		local priceLabel = label:FindFirstChild("PriceLabel")
		if priceLabel then
			priceLabel.Visible = false
		end
	end
	-- The stall character keeps its ClickDetector, but nothing is wired to
	-- it: clicking a placed character does nothing.
	local char = Characters.findById(carried.charId)
	model.Parent = Workspace
	table.insert(state.owned, {
		charId = carried.charId,
		mutation = carried.mutation,
		rarity = char and char.rarity or "Common",
		rate = carried.rate,
		slot = slot,
		model = model,
	})
	state.carrying = nil
	return true, slot
end

-- Walk every lane character one step south; despawn the ones that leave.
local function stepLaneCharacters(dt)
	for model, _record in pairs(CharacterSpawner.laneCharacters) do
		if model.Parent then
			local pivot = model:GetPivot()
			model:PivotTo(CFrame.new(pivot.Position.X, pivot.Position.Y, pivot.Position.Z + WorldConfig.WALK_SPEED * dt))
			if pivot.Position.Z >= WorldConfig.LANE_Z_END then
				CharacterSpawner.laneCharacters[model] = nil
				model:Destroy()
			end
		else
			CharacterSpawner.laneCharacters[model] = nil
		end
	end
end

-- Count the lane characters alive right now.
local function laneCount()
	local count = 0
	for _ in pairs(CharacterSpawner.laneCharacters) do
		count += 1
	end
	return count
end

-- Start the spawner: the folder, the first preview, the spawn timer and the
-- walking loop.
function CharacterSpawner.init()
	local folder = Instance.new("Folder")
	folder.Name = "LaneCharacters"
	folder.Parent = Workspace
	CharacterSpawner.laneFolder = folder
	previewNextSpawn()
	local lastSpawn = os.clock()
	RunService.Heartbeat:Connect(function(dt)
		stepLaneCharacters(dt)
		CharacterSpawner.followCarriedModels()
		CharacterSpawner.nextSpawnIn -= dt
		if os.clock() - lastSpawn >= WorldConfig.SPAWN_INTERVAL and laneCount() < WorldConfig.MAX_LANE_CHARACTERS then
			lastSpawn = os.clock()
			CharacterSpawner.nextSpawnIn = WorldConfig.SPAWN_INTERVAL
			CharacterSpawner.spawnLaneCharacter()
		end
	end)
end

return CharacterSpawner
