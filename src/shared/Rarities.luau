-- Rarities: the rarity ladder and the mutation table for Pasar Malam Brainrot.
-- Every character has one rarity and, rarely, one mutation that multiplies
-- its money-per-second. The server rolls both when a character spawns.

local Rarities = {}

-- Ordered from most common to rarest. weight is the spawn chance out of 100.
Rarities.LADDER = {
	{ id = "Common", display = "COMMON", color = Color3.fromRGB(200, 200, 200), weight = 52 },
	{ id = "Rare", display = "RARE", color = Color3.fromRGB(80, 200, 120), weight = 26 },
	{ id = "Epic", display = "EPIC", color = Color3.fromRGB(180, 100, 255), weight = 13 },
	{ id = "Legendary", display = "LEGENDARY", color = Color3.fromRGB(255, 170, 0), weight = 6.5 },
	{ id = "Mythic", display = "MYTHIC", color = Color3.fromRGB(255, 60, 90), weight = 2.3 },
	{ id = "Secret", display = "SECRET", color = Color3.fromRGB(0, 220, 255), weight = 0.2 },
}

-- mutationId -> { display, multiplier, color }. 15% of spawns get one.
Rarities.MUTATION_CHANCE = 0.15
Rarities.MUTATIONS = {
	{ id = "Pedas", display = "PEDAS", multiplier = 2, color = Color3.fromRGB(230, 40, 40), weight = 30 },
	{ id = "Manis", display = "MANIS", multiplier = 2, color = Color3.fromRGB(255, 130, 200), weight = 30 },
	{ id = "Goreng", display = "GORENG", multiplier = 3, color = Color3.fromRGB(255, 140, 40), weight = 15 },
	{ id = "Es", display = "ES", multiplier = 3, color = Color3.fromRGB(140, 220, 255), weight = 15 },
	{ id = "Pelangi", display = "PELANGI", multiplier = 5, color = Color3.fromRGB(190, 90, 255), weight = 10 },
}

-- Pick one entry from a weighted table (each entry has .weight).
local function pickWeighted(list)
	local total = 0
	for _, entry in ipairs(list) do
		total += entry.weight
	end
	local roll = math.random() * total
	for _, entry in ipairs(list) do
		roll -= entry.weight
		if roll <= 0 then
			return entry
		end
	end
	return list[#list]
end

-- Roll a rarity id, e.g. "Rare".
function Rarities.rollRarity()
	return pickWeighted(Rarities.LADDER).id
end

-- Roll a mutation id, or nil when the spawn has no mutation.
function Rarities.rollMutation()
	if math.random() > Rarities.MUTATION_CHANCE then
		return nil
	end
	return pickWeighted(Rarities.MUTATIONS).id
end

-- The display color of a rarity id.
function Rarities.colorOfRarity(rarityId)
	for _, entry in ipairs(Rarities.LADDER) do
		if entry.id == rarityId then
			return entry.color
		end
	end
	return Color3.fromRGB(200, 200, 200)
end

-- The income multiplier of a mutation id (1 when there is none).
function Rarities.multiplierOfMutation(mutationId)
	if not mutationId then
		return 1
	end
	for _, entry in ipairs(Rarities.MUTATIONS) do
		if entry.id == mutationId then
			return entry.multiplier
		end
	end
	return 1
end

-- The display color of a mutation id.
function Rarities.colorOfMutation(mutationId)
	if not mutationId then
		return Color3.fromRGB(255, 255, 255)
	end
	for _, entry in ipairs(Rarities.MUTATIONS) do
		if entry.id == mutationId then
			return entry.color
		end
	end
	return Color3.fromRGB(255, 255, 255)
end

-- The full label a mutation adds, e.g. "PEDAS x2" or "" when there is none.
function Rarities.mutationLabel(mutationId)
	if not mutationId then
		return ""
	end
	for _, entry in ipairs(Rarities.MUTATIONS) do
		if entry.id == mutationId then
			return entry.display .. " x" .. entry.multiplier
		end
	end
	return ""
end

return Rarities
