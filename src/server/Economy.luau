-- Economy: money in, money out. Collecting pending income is the only
-- money action: the stall's characters earn $/s into pending, and the
-- player banks it into cash with the collect button.

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

return Economy
