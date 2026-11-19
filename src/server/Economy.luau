-- Economy: money in, money out. Collecting pending income, Naik Kelas
-- (rebirth) and Pesanan (missions) all live here, so every price and reward
-- is decided in one place.

local Characters = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Characters"))
local GameState = require(script.Parent.GameState)
local WorldConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WorldConfig"))

local Economy = {}

-- Move a player's pending income into their cash. Returns the amount moved.
function Economy.collectPendingCash(state)
	local amount = math.floor(state.pending)
	if amount <= 0 then
		return 0
	end
	state.pending -= amount
	state.cash += amount
	return amount
end

-- The cost of the next Naik Kelas, or nil when the player is already a Mall.
function Economy.nextRebirthCost(state)
	local next = WorldConfig.REBIRTH_LEVELS[state.rebirthLevel + 2]
	if not next then
		return nil
	end
	return next.cost
end

-- Naik Kelas: pay the cost, reset cash and the stall, keep the collection
-- and the missions, gain the next income multiplier.
-- Returns true + the new level name, or false + the reason it failed.
function Economy.applyRebirth(state)
	local cost = Economy.nextRebirthCost(state)
	if not cost then
		return false, "Kamu sudah Mall, kelas tertinggi!"
	end
	if state.cash < cost then
		return false, "Butuh $" .. cost .. " untuk Naik Kelas."
	end
	if state.carrying then
		return false, "Taruh dulu karakter yang kamu bawa."
	end
	state.cash = 0 -- rebirth resets the cash; the cost was the entry ticket
	state.pending = 0
	-- The stall is emptied: every owned character model is destroyed.
	for _, owned in ipairs(state.owned) do
		if owned.model then
			owned.model:Destroy()
		end
	end
	state.owned = {}
	state.rebirthLevel += 1
	Economy.bumpMissionProgress(state, "rebirth-1", 1)
	return true, "Naik Kelas jadi " .. GameState.rebirthName(state) .. "! Income x" .. GameState.rebirthMultiplier(state)
end

-- Add progress to one mission and return the mission record.
function Economy.bumpMissionProgress(state, missionId, amount)
	local record = state.missions[missionId]
	if not record then
		record = { progress = 0, claimed = false }
		state.missions[missionId] = record
	end
	record.progress += amount
	return record
end

-- Recompute the count-based missions from what a player owns right now.
function Economy.refreshCountMissions(state)
	local ownedCount = #state.owned
	Economy.setMissionProgress(state, "own-3", ownedCount)
	Economy.setMissionProgress(state, "own-rare", GameState.countOwnedAtLeast(state, "Rare"))
	Economy.setMissionProgress(state, "own-3-legendary", GameState.countOwnedAtLeast(state, "Legendary"))
end

-- Set a mission's progress to an exact value (never backwards).
function Economy.setMissionProgress(state, missionId, value)
	local record = state.missions[missionId]
	if not record then
		record = { progress = 0, claimed = false }
		state.missions[missionId] = record
	end
	if value > record.progress then
		record.progress = value
	end
	return record
end

-- Claim a finished mission's reward. Returns true + reward, or false + reason.
function Economy.claimMission(state, missionId)
	local mission = nil
	for _, m in ipairs(WorldConfig.MISSIONS) do
		if m.id == missionId then
			mission = m
			break
		end
	end
	if not mission then
		return false, "Pesanan tidak ada."
	end
	local record = state.missions[missionId]
	if not record or record.progress < mission.target then
		return false, "Pesanan belum selesai."
	end
	if record.claimed then
		return false, "Pesanan sudah diklaim."
	end
	record.claimed = true
	state.cash += mission.reward
	return true, mission.reward
end

-- The mission list for the client: id, name, description, target, reward,
-- progress and claimed.
function Economy.missionListForClient(state)
	local out = {}
	for _, m in ipairs(WorldConfig.MISSIONS) do
		local record = state.missions[m.id]
		table.insert(out, {
			id = m.id,
			name = m.name,
			description = m.description,
			target = m.target,
			reward = m.reward,
			progress = record and record.progress or 0,
			claimed = record and record.claimed or false,
		})
	end
	return out
end

-- The collection list for the client: every character id, owned or not.
function Economy.collectionForClient(state)
	local out = {}
	for _, char in ipairs(Characters.LIST) do
		table.insert(out, {
			id = char.id,
			name = char.name,
			rarity = char.rarity,
			rate = char.rate,
			price = char.price,
			owned = state.collection[char.id] == true,
		})
	end
	return out
end

return Economy
