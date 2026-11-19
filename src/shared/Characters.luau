-- Characters: the cast of Pasar Malam Brainrot. 18 absurd Indonesian night-market
-- characters on a rarity ladder. Every character is Part-built (see
-- CharacterFactory): no meshes, no decals, no uploaded assets.
--
-- Fields per character:
--   id        unique key, e.g. "tukang-gorengan"
--   name      the name shown on the label
--   rarity    one of Rarities.LADDER ids
--   rate      base money per second
--   price     what a player pays to buy it off the lane
--   body      Body part color (Color3)
--   accent    head / accessory color
--   scale     body size multiplier (0.8 small, 1.4 huge)
--   accessory "hat" | "glasses" | "apron" | "crown" | "scarf" | "none"
--   face      "happy" | "mischief" | "sleepy" | "angry"

local Characters = {}

Characters.LIST = {
	-- Common
	{ id = "tukang-gorengan", name = "Tukang Gorengan", rarity = "Common", rate = 2, price = 150,
		body = Color3.fromRGB(210, 140, 60), accent = Color3.fromRGB(255, 255, 255), scale = 1.0, accessory = "apron", face = "happy" },
	{ id = "siomay-keliling", name = "Siomay Keliling", rarity = "Common", rate = 3, price = 200,
		body = Color3.fromRGB(240, 220, 180), accent = Color3.fromRGB(120, 200, 120), scale = 0.9, accessory = "hat", face = "happy" },
	{ id = "es-teh-manis", name = "Es Teh Manis", rarity = "Common", rate = 4, price = 250,
		body = Color3.fromRGB(170, 90, 40), accent = Color3.fromRGB(180, 230, 255), scale = 1.0, accessory = "none", face = "sleepy" },
	{ id = "kaki-lima", name = "Kaki Lima", rarity = "Common", rate = 5, price = 300,
		body = Color3.fromRGB(90, 90, 110), accent = Color3.fromRGB(255, 200, 60), scale = 1.1, accessory = "scarf", face = "mischief" },
	-- Rare
	{ id = "odong-odong", name = "Odong-Odong", rarity = "Rare", rate = 10, price = 600,
		body = Color3.fromRGB(255, 80, 120), accent = Color3.fromRGB(255, 230, 80), scale = 1.1, accessory = "hat", face = "happy" },
	{ id = "martabak-man", name = "Martabak Man", rarity = "Rare", rate = 15, price = 900,
		body = Color3.fromRGB(150, 90, 40), accent = Color3.fromRGB(255, 210, 120), scale = 1.2, accessory = "apron", face = "mischief" },
	{ id = "klepon-manis", name = "Klepon Manis", rarity = "Rare", rate = 20, price = 1200,
		body = Color3.fromRGB(60, 180, 90), accent = Color3.fromRGB(255, 255, 255), scale = 0.9, accessory = "none", face = "happy" },
	{ id = "cilok-sakti", name = "Cilok Sakti", rarity = "Rare", rate = 30, price = 1800,
		body = Color3.fromRGB(235, 225, 200), accent = Color3.fromRGB(200, 60, 60), scale = 0.9, accessory = "glasses", face = "angry" },
	-- Epic
	{ id = "ondel-ondel", name = "Ondel-Ondel", rarity = "Epic", rate = 50, price = 3000,
		body = Color3.fromRGB(230, 40, 60), accent = Color3.fromRGB(255, 215, 0), scale = 1.3, accessory = "crown", face = "happy" },
	{ id = "kuda-lumping", name = "Kuda Lumping", rarity = "Epic", rate = 70, price = 4200,
		body = Color3.fromRGB(120, 70, 180), accent = Color3.fromRGB(255, 120, 180), scale = 1.2, accessory = "scarf", face = "mischief" },
	{ id = "barongsai-mini", name = "Barongsai Mini", rarity = "Epic", rate = 100, price = 6000,
		body = Color3.fromRGB(255, 60, 40), accent = Color3.fromRGB(255, 215, 0), scale = 1.0, accessory = "hat", face = "angry" },
	{ id = "topeng-monyet", name = "Topeng Monyet", rarity = "Epic", rate = 140, price = 8400,
		body = Color3.fromRGB(150, 100, 60), accent = Color3.fromRGB(255, 80, 80), scale = 1.0, accessory = "glasses", face = "mischief" },
	-- Legendary
	{ id = "kuntilanak-cantik", name = "Kuntilanak Cantik", rarity = "Legendary", rate = 250, price = 15000,
		body = Color3.fromRGB(240, 240, 240), accent = Color3.fromRGB(40, 40, 40), scale = 1.2, accessory = "scarf", face = "sleepy" },
	{ id = "pocong-loncat", name = "Pocong Loncat", rarity = "Legendary", rate = 400, price = 24000,
		body = Color3.fromRGB(245, 245, 235), accent = Color3.fromRGB(60, 180, 90), scale = 1.1, accessory = "none", face = "angry" },
	{ id = "genderuwo-gede", name = "Genderuwo Gede", rarity = "Legendary", rate = 600, price = 36000,
		body = Color3.fromRGB(60, 40, 90), accent = Color3.fromRGB(255, 60, 60), scale = 1.4, accessory = "crown", face = "angry" },
	{ id = "tuyul-cepat", name = "Tuyul Cepat", rarity = "Legendary", rate = 900, price = 54000,
		body = Color3.fromRGB(220, 190, 140), accent = Color3.fromRGB(255, 215, 0), scale = 0.8, accessory = "none", face = "mischief" },
	-- Mythic
	{ id = "tung-tung-sahur", name = "Tung Tung Sahur", rarity = "Mythic", rate = 1500, price = 90000,
		body = Color3.fromRGB(140, 90, 50), accent = Color3.fromRGB(255, 230, 150), scale = 1.3, accessory = "hat", face = "happy" },
	{ id = "nenek-gayung", name = "Nenek Gayung", rarity = "Mythic", rate = 2500, price = 150000,
		body = Color3.fromRGB(100, 100, 140), accent = Color3.fromRGB(200, 200, 220), scale = 1.1, accessory = "scarf", face = "sleepy" },
	-- Secret
	{ id = "raja-pasar-malam", name = "Raja Pasar Malam", rarity = "Secret", rate = 25000, price = 1250000,
		body = Color3.fromRGB(255, 190, 0), accent = Color3.fromRGB(160, 40, 220), scale = 1.4, accessory = "crown", face = "mischief" },
}

-- Find a character spec by its id.
function Characters.findById(charId)
	for _, char in ipairs(Characters.LIST) do
		if char.id == charId then
			return char
		end
	end
	return nil
end

-- All characters of one rarity, in list order.
function Characters.ofRarity(rarityId)
	local out = {}
	for _, char in ipairs(Characters.LIST) do
		if char.rarity == rarityId then
			table.insert(out, char)
		end
	end
	return out
end

-- Pick a random character of a rarity (uniform inside the rarity).
function Characters.randomOfRarity(rarityId)
	local pool = Characters.ofRarity(rarityId)
	if #pool == 0 then
		return Characters.LIST[1]
	end
	return pool[math.random(#pool)]
end

-- The display name of a character, with its mutation when it has one.
function Characters.displayName(charId, mutationId)
	local char = Characters.findById(charId)
	if not char then
		return charId
	end
	if mutationId then
		return mutationId .. " " .. char.name
	end
	return char.name
end

return Characters
