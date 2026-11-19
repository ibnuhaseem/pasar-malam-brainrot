-- StealAndLock: stealing from other stalls and locking your own.
-- A stall character can be stolen only when its stall is unlocked, the thief
-- is not already carrying, the thief has a free slot, and the stall was not
-- stolen from in the last few seconds. Locking a stall blocks all stealing
-- for 30 seconds, then needs a cooldown before it can lock again.

local GameState = require(script.Parent.GameState)
local WorldConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WorldConfig"))

local StealAndLock = {}

-- Try to steal a character out of someone else's stall. The character is
-- lifted into the thief's hands; they still have to carry it to their stall.
function StealAndLock.tryStealCharacter(thief, ownerState, model)
	local thiefState = GameState.players[thief]
	if not thiefState then
		return
	end
	if thiefState == ownerState then
		return -- clicking your own character does nothing
	end
	if thiefState.carrying then
		GameState.notifyPlayer(thief, "Kamu sudah membawa karakter!", Color3.fromRGB(255, 180, 60))
		return
	end
	if #GameState.freeSlots(thiefState) == 0 then
		GameState.notifyPlayer(thief, "Kiosmu penuh!", Color3.fromRGB(255, 80, 80))
		return
	end
	local stall = GameState.stalls[ownerState.stallIndex]
	if not stall then
		return
	end
	if GameState.isStallLocked(ownerState.stallIndex) then
		GameState.notifyPlayer(thief, "Kios itu DIKUNCI! Tidak bisa mencuri.", Color3.fromRGB(255, 80, 80))
		return
	end
	if os.clock() < stall.stealCooldownUntil then
		GameState.notifyPlayer(thief, "Kios itu baru saja dicuri. Tunggu sebentar.", Color3.fromRGB(255, 180, 60))
		return
	end
	-- Find the owned record for this model and lift it out of the stall.
	local ownedIndex = nil
	local ownedRecord = nil
	for i, owned in ipairs(ownerState.owned) do
		if owned.model == model then
			ownedIndex = i
			ownedRecord = owned
			break
		end
	end
	if not ownedRecord then
		return
	end
	table.remove(ownerState.owned, ownedIndex)
	stall.stealCooldownUntil = os.clock() + WorldConfig.STEAL_COOLDOWN
	thiefState.carrying = {
		charId = ownedRecord.charId,
		mutation = ownedRecord.mutation,
		rate = ownedRecord.rate,
		price = 0,
		model = model,
	}
	GameState.notifyPlayer(thief, "Berhasil mencuri! Cepat bawa ke kiosmu!", Color3.fromRGB(255, 200, 60))
	local owner = ownerState.player
	if owner then
		GameState.notifyPlayer(owner, thief.DisplayName .. " mencuri karakter dari kiosmu!", Color3.fromRGB(255, 60, 60))
		GameState.broadcastState(owner)
	end
	GameState.broadcastState(thief)
end

-- Lock your own stall for 30 seconds. Returns true or false + the reason.
function StealAndLock.lockPlayerStall(player)
	local state = GameState.players[player]
	if not state then
		return false, "Tidak ada state pemain."
	end
	local stall = GameState.stalls[state.stallIndex]
	if not stall then
		return false, "Kamu belum punya kios."
	end
	local now = os.clock()
	if now < stall.lockedUntil then
		return false, "Kiosmu sudah dikunci."
	end
	if now < stall.lockCooldownUntil then
		return false, "Kunci masih cooldown, tunggu sebentar."
	end
	stall.lockedUntil = now + WorldConfig.LOCK_DURATION
	stall.lockCooldownUntil = now + WorldConfig.LOCK_DURATION + WorldConfig.LOCK_COOLDOWN
	state.locksUsed += 1
	local Economy = require(script.Parent.Economy)
	Economy.bumpMissionProgress(state, "lock-3", 1)
	return true, "Kios dikunci 30 detik!"
end

-- Seconds of lock left on a stall, for the HUD.
function StealAndLock.lockSecondsLeft(stallIndex)
	local stall = GameState.stalls[stallIndex]
	if not stall then
		return 0
	end
	return math.max(0, math.ceil(stall.lockedUntil - os.clock()))
end

return StealAndLock
