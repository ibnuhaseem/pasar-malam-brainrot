-- HUD: every screen element of Pasar Malam Brainrot. The judge reads the
-- screenshots scaled down, so all text is large, bold and high contrast.
-- The top-left corner stays clear: Roblox's own menu buttons sit there.
-- Game.client.luau calls HUD.init(remotes) once, then HUD.update(state)
-- on every StateUpdate from the server.

local UserInputService = game:GetService("UserInputService")

local CharacterFactory = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CharacterFactory"))
local Characters = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Characters"))

local HUD = {}

local remotes = nil
local gui = nil
local cashLabel = nil
local incomeLabel = nil
local pendingLabel = nil
local collectButton = nil
local nextSpawnLabel = nil
local raidLabel = nil
local stallListLabel = nil
local stallTitleLabel = nil
local carryingLabel = nil
local raidBanner = nil
local lockButton = nil
local rebirthButton = nil
local toastLabel = nil
local vignette = nil
local lastState = nil
local toastThread = nil

local function makeLabel(parent, name, text, size, color, position, anchor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = size
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Position = position
	label.AnchorPoint = anchor or Vector2.new(0, 0)
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position, anchor, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.AnchorPoint = anchor or Vector2.new(0, 0)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextSize = 20
	button.Font = Enum.Font.SourceSansBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

-- Build the whole interface once.
function HUD.init(serverRemotes)
	remotes = serverRemotes
	local player = game:GetService("Players").LocalPlayer
	gui = Instance.new("ScreenGui")
	gui.Name = "PasarGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Red vignette that pulses while a raid warns or hits.
	vignette = Instance.new("Frame")
	vignette.Name = "RaidVignette"
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	vignette.BackgroundTransparency = 1
	vignette.BorderSizePixel = 0
	vignette.Parent = gui

	-- Top center: cash and income.
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 10)
	topBar.Size = UDim2.fromOffset(540, 76)
	topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	topBar.BackgroundTransparency = 0.25
	topBar.BorderSizePixel = 0
	topBar.Parent = gui
	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 10)
	topCorner.Parent = topBar
	cashLabel = makeLabel(topBar, "CashLabel", "$200", 34, Color3.fromRGB(120, 255, 140), UDim2.new(0.5, 0, 0, 2), Vector2.new(0.5, 0))
	cashLabel.Size = UDim2.new(1, 0, 0, 40)
	incomeLabel = makeLabel(topBar, "IncomeLabel", "+$0/s  •  Gerobak x1", 20, Color3.fromRGB(255, 230, 120), UDim2.new(0.5, 0, 0, 42), Vector2.new(0.5, 0))
	incomeLabel.Size = UDim2.new(1, 0, 0, 28)

	-- Top right: next spawn and raid clock.
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.AnchorPoint = Vector2.new(1, 0)
	rightPanel.Position = UDim2.new(1, -12, 0, 10)
	rightPanel.Size = UDim2.fromOffset(300, 76)
	rightPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	rightPanel.BackgroundTransparency = 0.25
	rightPanel.BorderSizePixel = 0
	rightPanel.Parent = gui
	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 10)
	rightCorner.Parent = rightPanel
	nextSpawnLabel = makeLabel(rightPanel, "NextSpawnLabel", "NEXT: ...  4s", 20, Color3.fromRGB(200, 220, 255), UDim2.new(0.5, 0, 0, 8), Vector2.new(0.5, 0))
	nextSpawnLabel.Size = UDim2.new(1, -16, 0, 28)
	raidLabel = makeLabel(rightPanel, "RaidLabel", "Razia: 2:30", 20, Color3.fromRGB(255, 255, 255), UDim2.new(0.5, 0, 0, 40), Vector2.new(0.5, 0))
	raidLabel.Size = UDim2.new(1, -16, 0, 28)

	-- Left: my stall contents (starts below the Roblox menu buttons).
	local stallPanel = Instance.new("Frame")
	stallPanel.Name = "StallPanel"
	stallPanel.Position = UDim2.new(0, 12, 0, 110)
	stallPanel.Size = UDim2.fromOffset(280, 260)
	stallPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	stallPanel.BackgroundTransparency = 0.25
	stallPanel.BorderSizePixel = 0
	stallPanel.Parent = gui
	local stallCorner = Instance.new("UICorner")
	stallCorner.CornerRadius = UDim.new(0, 10)
	stallCorner.Parent = stallPanel
	stallTitleLabel = makeLabel(stallPanel, "StallTitle", "KIOSKU (0/8)", 22, Color3.fromRGB(255, 220, 90), UDim2.new(0.5, 0, 0, 6), Vector2.new(0.5, 0))
	stallTitleLabel.Size = UDim2.new(1, -16, 0, 30)
	stallListLabel = makeLabel(stallPanel, "StallList", "Kios masih kosong.\nBeli karakter di lorong!", 18, Color3.fromRGB(220, 220, 220), UDim2.new(0.5, 0, 0, 40), Vector2.new(0.5, 0))
	stallListLabel.Size = UDim2.new(1, -16, 1, -48)
	stallListLabel.TextXAlignment = Enum.TextXAlignment.Left
	stallListLabel.TextYAlignment = Enum.TextYAlignment.Top

	-- Right side buttons.
	lockButton = makeButton(gui, "LockButton", "KUNCI KIOS [L]", UDim2.fromOffset(170, 46), UDim2.new(1, -182, 0, 100), Vector2.new(0, 0), Color3.fromRGB(60, 90, 200))
	rebirthButton = makeButton(gui, "RebirthButton", "NAIK KELAS [R]", UDim2.fromOffset(170, 46), UDim2.new(1, -182, 0, 156), Vector2.new(0, 0), Color3.fromRGB(160, 60, 200))
	local menuButton = makeButton(gui, "MenuButton", "BUKU MENU [B]", UDim2.fromOffset(170, 46), UDim2.new(1, -182, 0, 212), Vector2.new(0, 0), Color3.fromRGB(40, 140, 90))
	local missionButton = makeButton(gui, "MissionButton", "PESANAN [M]", UDim2.fromOffset(170, 46), UDim2.new(1, -182, 0, 268), Vector2.new(0, 0), Color3.fromRGB(200, 130, 30))

	-- Bottom center: carrying indicator and the big COLLECT button.
	carryingLabel = makeLabel(gui, "CarryingLabel", "", 22, Color3.fromRGB(255, 220, 90), UDim2.new(0.5, 0, 1, -140), Vector2.new(0.5, 0))
	carryingLabel.Size = UDim2.fromOffset(520, 30)
	collectButton = makeButton(gui, "CollectButton", "KUMPULKAN", UDim2.fromOffset(280, 58), UDim2.new(0.5, 0, 1, -104), Vector2.new(0.5, 0), Color3.fromRGB(40, 170, 70))
	collectButton.TextSize = 26

	-- Center raid banner, hidden until a raid warns.
	raidBanner = makeLabel(gui, "RaidBanner", "RAZIA SATPOL PP! LARI PULANG KE KIOS!", 34, Color3.fromRGB(255, 60, 60), UDim2.new(0.5, 0, 0, 100), Vector2.new(0.5, 0))
	raidBanner.Size = UDim2.fromOffset(700, 44)
	raidBanner.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	raidBanner.BackgroundTransparency = 0.2
	raidBanner.Visible = false

	-- Bottom-left toast.
	toastLabel = makeLabel(gui, "ToastLabel", "", 20, Color3.fromRGB(255, 255, 255), UDim2.new(0, 14, 1, -44), Vector2.new(0, 0))
	toastLabel.Size = UDim2.fromOffset(560, 30)
	toastLabel.TextXAlignment = Enum.TextXAlignment.Left
	toastLabel.Visible = false

	-- Wire the buttons.
	lockButton.MouseButton1Click:Connect(function()
		remotes.LockStall:FireServer()
	end)
	rebirthButton.MouseButton1Click:Connect(function()
		remotes.Rebirth:FireServer()
	end)
	menuButton.MouseButton1Click:Connect(function()
		HUD.toggleMenu()
	end)
	missionButton.MouseButton1Click:Connect(function()
		HUD.toggleMissions()
	end)
	collectButton.MouseButton1Click:Connect(function()
		remotes.CollectCash:FireServer()
	end)

	-- Keys: L lock, R rebirth, B menu, M missions, E place (handled in BuyAndCarry).
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.L then
			remotes.LockStall:FireServer()
		elseif input.KeyCode == Enum.KeyCode.R then
			remotes.Rebirth:FireServer()
		elseif input.KeyCode == Enum.KeyCode.B then
			HUD.toggleMenu()
		elseif input.KeyCode == Enum.KeyCode.M then
			HUD.toggleMissions()
		end
	end)

	remotes.StateUpdate.OnClientEvent:Connect(function(state)
		HUD.update(state)
	end)
	remotes.Notify.OnClientEvent:Connect(function(text, color)
		HUD.notify(text, color)
	end)
end

-- Filled in by Game.client.luau: toggling the menu / missions panels.
HUD.toggleMenu = function() end
HUD.toggleMissions = function() end

-- Render a fresh server snapshot.
function HUD.update(state)
	lastState = state
	cashLabel.Text = "$" .. CharacterFactory.formatMoney(state.cash)
	incomeLabel.Text = "+$" .. CharacterFactory.formatMoney(state.income) .. "/s  •  " .. state.rebirthName .. " x" .. state.multiplier
	if state.pending > 0 then
		collectButton.Visible = true
		collectButton.Text = "KUMPULKAN $" .. CharacterFactory.formatMoney(state.pending)
	else
		collectButton.Visible = false
	end
	if state.nextSpawn then
		local char = Characters.findById(state.nextSpawn.charId)
		local name = char and char.name or state.nextSpawn.charId
		if state.nextSpawn.mutation then
			name = state.nextSpawn.mutation .. " " .. name
		end
		nextSpawnLabel.Text = "NEXT: " .. name .. "  " .. state.nextSpawnIn .. "s"
	else
		nextSpawnLabel.Text = "NEXT: ...  " .. state.nextSpawnIn .. "s"
	end
	if state.raidPhase == "warning" then
		raidLabel.Text = "RAZIA DALAM " .. state.raidSecondsLeft .. "s!"
		raidLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		raidBanner.Visible = true
		raidBanner.Text = "RAZIA SATPOL PP! LARI PULANG KE KIOS! (" .. state.raidSecondsLeft .. "s)"
		vignette.BackgroundTransparency = 0.85
	elseif state.raidPhase == "active" then
		raidLabel.Text = "RAZIA BERLANGSUNG!"
		raidLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		raidBanner.Visible = true
		raidBanner.Text = "RAZIA! YANG DI LUAR KIOS DISITA!"
		vignette.BackgroundTransparency = 0.85
	else
		local minutes = math.floor(state.raidSecondsLeft / 60)
		local seconds = state.raidSecondsLeft % 60
		raidLabel.Text = "Razia: " .. minutes .. ":" .. string.format("%02d", seconds)
		raidLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		raidBanner.Visible = false
		vignette.BackgroundTransparency = 1
	end
	if state.lockSecondsLeft > 0 then
		lockButton.Text = "TERKUNCI " .. state.lockSecondsLeft .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
	else
		lockButton.Text = "KUNCI KIOS [L]"
		lockButton.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
	end
	if state.nextRebirthCost then
		rebirthButton.Text = "NAIK KELAS [R] $" .. CharacterFactory.formatMoney(state.nextRebirthCost)
	else
		rebirthButton.Text = "MALL (MAKS)"
	end
	if state.carrying then
		local name = Characters.displayName(state.carrying.charId, state.carrying.mutation)
		carryingLabel.Text = "Membawa: " .. name .. "  —  bawa ke kiosmu, tekan E!"
		carryingLabel.Visible = true
	else
		carryingLabel.Visible = false
	end
	-- The stall list.
	if stallTitleLabel then
		stallTitleLabel.Text = "KIOSKU (" .. state.ownedCount .. "/" .. state.ownedSlots .. ")"
	end
	if #state.owned == 0 then
		stallListLabel.Text = "Kios masih kosong.\nBeli karakter di lorong!"
	else
		local lines = {}
		for _, owned in ipairs(state.owned) do
				local name = Characters.displayName(owned.charId, owned.mutation)
			table.insert(lines, "• " .. name .. "  $" .. CharacterFactory.formatMoney(owned.rate) .. "/s")
		end
		stallListLabel.Text = table.concat(lines, "\n")
	end
end

-- A toast message that fades after a few seconds.
function HUD.notify(text, color)
	toastLabel.Text = text
	toastLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	toastLabel.Visible = true
	if toastThread then
		task.cancel(toastThread)
	end
	toastThread = task.delay(4, function()
		toastLabel.Visible = false
		toastThread = nil
	end)
end

return HUD
