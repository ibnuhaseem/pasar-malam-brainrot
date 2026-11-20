-- CharacterFactory: builds every brainrot character as a Part-built Model.
-- No meshes, no decals, no uploaded assets: body, head, eyes, mouth and
-- accessory are all Parts, and the name / rarity / money-per-second label is
-- a BillboardGui. The same factory builds lane characters and stall characters.

local Characters = require(script.Parent.Characters)
local Rarities = require(script.Parent.Rarities)

local CharacterFactory = {}

local EYE_SIZE = Vector3.new(0.28, 0.36, 0.1)
local EYE_COLOR = Color3.fromRGB(20, 20, 20)

-- A small Part parented to the model.
local function makePart(name, size, color, position)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true
	part.Position = position
	return part
end

-- The face: two eyes and a mouth on the front of the head.
local function buildFace(model, head, scale, faceKind)
	local front = head.Position + Vector3.new(0, 0, head.Size.Z / 2 + 0.02)
	local eyeY = front.Y + 0.18 * scale
	local eyeX = 0.32 * scale
	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Eye", EYE_SIZE * scale, EYE_COLOR, Vector3.new(front.X + eyeX * side, eyeY, front.Z))
		eye.Parent = model
	end
	local mouthY = front.Y - 0.28 * scale
	local mouthSize
	if faceKind == "angry" then
		mouthSize = Vector3.new(0.7 * scale, 0.12 * scale, 0.1)
	elseif faceKind == "sleepy" then
		mouthSize = Vector3.new(0.3 * scale, 0.3 * scale, 0.1)
	else
		mouthSize = Vector3.new(0.6 * scale, 0.14 * scale, 0.1)
	end
	local mouth = makePart("Mouth", mouthSize, EYE_COLOR, Vector3.new(front.X, mouthY, front.Z))
	mouth.Parent = model
	if faceKind == "angry" then
		-- Angry brows: two slanted bars above the eyes.
		for _, side in ipairs({ -1, 1 }) do
			local brow = makePart("Brow", Vector3.new(0.5 * scale, 0.12 * scale, 0.1), EYE_COLOR,
				Vector3.new(front.X + eyeX * side, eyeY + 0.35 * scale, front.Z))
			brow.Rotation = Vector3.new(0, 0, -20 * side)
			brow.Parent = model
		end
	end
end

-- The accessory on top of the head or body, per the character spec.
local function buildAccessory(model, head, scale, accessory, accent)
	local top = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
	if accessory == "hat" then
		local brim = makePart("Hat", Vector3.new(2.2 * scale, 0.18 * scale, 2.2 * scale), accent, top + Vector3.new(0, 0.1 * scale, 0))
		brim.Parent = model
		local crown = makePart("HatTop", Vector3.new(1.2 * scale, 0.7 * scale, 1.2 * scale), accent, top + Vector3.new(0, 0.45 * scale, 0))
		crown.Parent = model
	elseif accessory == "crown" then
		local band = makePart("Crown", Vector3.new(1.5 * scale, 0.35 * scale, 1.5 * scale), Color3.fromRGB(255, 210, 0), top + Vector3.new(0, 0.15 * scale, 0))
		band.Parent = model
		local spike = makePart("CrownSpike", Vector3.new(0.3 * scale, 0.5 * scale, 0.3 * scale), Color3.fromRGB(255, 210, 0), top + Vector3.new(0, 0.55 * scale, 0))
		spike.Parent = model
	elseif accessory == "glasses" then
		local front = head.Position + Vector3.new(0, 0.18 * scale, head.Size.Z / 2 + 0.03)
		for _, side in ipairs({ -1, 1 }) do
			local lens = makePart("Lens", Vector3.new(0.55 * scale, 0.55 * scale, 0.08), Color3.fromRGB(30, 30, 40), Vector3.new(front.X + 0.35 * scale * side, front.Y, front.Z))
			lens.Parent = model
		end
	elseif accessory == "apron" then
		local body = model:FindFirstChild("Body")
		if body then
			local apron = makePart("Apron", Vector3.new(1.4 * scale, 1.6 * scale, 0.1), Color3.fromRGB(255, 255, 255),
				body.Position + Vector3.new(0, -0.2 * scale, body.Size.Z / 2 + 0.02))
			apron.Parent = model
		end
	elseif accessory == "scarf" then
		local scarf = makePart("Scarf", Vector3.new(2.0 * scale, 0.35 * scale, 1.6 * scale), accent, head.Position + Vector3.new(0, -head.Size.Y / 2 - 0.1 * scale, 0))
		scarf.Parent = model
	end
end

-- The floating label: name, rarity, money per second, and (on the lane) price.
local function buildLabel(model, head, char, mutationId, rate, price)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(220, 92)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0

	local function label(name, text, y, size, color, bold)
		local t = Instance.new("TextLabel")
		t.Name = name
		t.Size = UDim2.new(1, 0, 0, 26)
		t.Position = UDim2.new(0, 0, 0, y)
		t.BackgroundTransparency = 0.35
		t.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
		t.Text = text
		t.TextColor3 = color
		t.TextSize = size
		t.Font = bold and Enum.Font.SourceSansBold or Enum.Font.SourceSans
		t.TextScaled = false
		t.Parent = gui
		return t
	end

	label("NameLabel", Characters.displayName(char.id, mutationId), 0, 22, Color3.fromRGB(255, 255, 255), true)
	local rarityText = char.rarity:upper()
	local mutationLabel = Rarities.mutationLabel(mutationId)
	if mutationLabel ~= "" then
		rarityText = rarityText .. "  " .. mutationLabel
	end
	label("RarityLabel", rarityText, 26, 18, Rarities.colorOfRarity(char.rarity), true)
	label("RateLabel", "$" .. CharacterFactory.formatMoney(rate) .. "/s", 50, 22, Color3.fromRGB(90, 255, 130), true)
	local priceLabel = label("PriceLabel", "", 74, 18, Color3.fromRGB(255, 220, 90), true)
	priceLabel.Visible = false
	if price then
		priceLabel.Text = "BELI $" .. CharacterFactory.formatMoney(price)
		priceLabel.Visible = true
		gui.Size = UDim2.fromOffset(220, 104)
	end
	gui.Parent = model
	return gui
end

-- Short money: 1500 -> "1.5K", 2500000 -> "2.5M".
function CharacterFactory.formatMoney(amount)
	amount = math.floor(amount + 0.5)
	if amount >= 1000000000 then
		return string.format("%.1fB", amount / 1000000000)
	elseif amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	else
		return tostring(amount)
	end
end

-- Build the Model for a character. rate is the final $/s (after mutation),
-- price is the lane price (nil when the model stands in a stall).
function CharacterFactory.buildCharacterModel(charId, mutationId, rate, price)
	local char = Characters.findById(charId)
	if not char then
		return nil
	end
	local scale = char.scale
	local model = Instance.new("Model")
	model.Name = char.name

	local bodySize = Vector3.new(2.2 * scale, 2.4 * scale, 1.5 * scale)
	local body = makePart("Body", bodySize, char.body, Vector3.new(0, 1.2 * scale, 0))
	body.Parent = model
	model.PrimaryPart = body

	local headSize = Vector3.new(1.7 * scale, 1.5 * scale, 1.5 * scale)
	local head = makePart("Head", headSize, char.accent, Vector3.new(0, 3.1 * scale, 0))
	head.Parent = model

	-- Two little feet so the character reads as walking.
	for _, side in ipairs({ -1, 1 }) do
		local foot = makePart("Foot", Vector3.new(0.7 * scale, 0.3 * scale, 1.0 * scale), Color3.fromRGB(40, 40, 50),
			Vector3.new(0.55 * scale * side, 0.15 * scale, 0))
		foot.Parent = model
	end

	buildFace(model, head, scale, char.face)
	buildAccessory(model, head, scale, char.accessory, char.accent)
	buildLabel(model, head, char, mutationId, rate, price)

	-- Identification values the server reads back.
	local idValue = Instance.new("StringValue")
	idValue.Name = "CharId"
	idValue.Value = charId
	idValue.Parent = model
	local mutationValue = Instance.new("StringValue")
	mutationValue.Name = "Mutation"
	mutationValue.Value = mutationId or ""
	mutationValue.Parent = model
	local rateValue = Instance.new("NumberValue")
	rateValue.Name = "Rate"
	rateValue.Value = rate
	rateValue.Parent = model
	-- Body center height above the feet: placing code stands the model on a
	-- surface by putting the body this high above the surface.
	local standValue = Instance.new("NumberValue")
	standValue.Name = "StandHeight"
	standValue.Value = 1.2 * scale
	standValue.Parent = model

	local click = Instance.new("ClickDetector")
	click.Name = "Click"
	click.MaxActivationDistance = 64
	click.Parent = model

	return model
end

-- Stand a model on a surface: groundPos is the surface point (the pad top,
-- the lane top). The body's center ends up StandHeight above it.
function CharacterFactory.placeModelAt(model, groundPos, yaw)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local stand = model:FindFirstChild("StandHeight")
	local height = stand and stand.Value or 1.2
	local target = Vector3.new(groundPos.X, groundPos.Y + height, groundPos.Z)
	local pivot = model:GetPivot()
	local bodyOffset = pivot:Inverse() * root.Position
	local rotation = CFrame.Angles(0, yaw or 0, 0)
	local pivotPos = target - (rotation * bodyOffset)
	model:PivotTo(CFrame.new(pivotPos) * rotation)
end

-- Move a whole model to stand on a surface, facing +Z (the walking direction).
function CharacterFactory.moveModelTo(model, groundPos)
	CharacterFactory.placeModelAt(model, groundPos, 0)
end

return CharacterFactory
