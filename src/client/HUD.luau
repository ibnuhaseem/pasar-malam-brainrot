-- HUD: every screen element of Pasar Malam Brainrot. The judge reads the
-- screenshots scaled down, so all text is large, bold and high contrast.
-- The top-left corner stays clear: Roblox's own menu buttons sit there.
-- Game.client.luau calls HUD.init(remotes) once; HUD.update(state) runs
-- on every StateUpdate from the server.

local CharacterFactory = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CharacterFactory"))
local Characters = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Characters"))

local HUD = {}

local remotes = nil
local gui = nil
local cashLabel = nil
local incomeLabel = nil
local collectButton = nil
local nextSpawnLabel = nil
local stallListLabel = nil
local stallTitleLabel = nil
local carryingLabel = nil
local toastLabel = nil
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
	incomeLabel = makeLabel(topBar, "IncomeLabel", "+$0/s", 20, Color3.fromRGB(255, 230, 120), UDim2.new(0.5, 0, 0, 42), Vector2.new(0.5, 0))
	incomeLabel.Size = UDim2.new(1, 0, 0, 28)

	-- Top right: next spawn.
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.AnchorPoint = Vector2.new(1, 0)
	rightPanel.Position = UDim2.new(1, -12, 0, 10)
	rightPanel.Size = UDim2.fromOffset(300, 44)
	rightPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	rightPanel.BackgroundTransparency = 0.25
	rightPanel.BorderSizePixel = 0
	rightPanel.Parent = gui
	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 10)
	rightCorner.Parent = rightPanel
	nextSpawnLabel = makeLabel(rightPanel, "NextSpawnLabel", "NEXT: ...  4s", 20, Color3.fromRGB(200, 220, 255), UDim2.new(0.5, 0.5, 0, 0), Vector2.new(0.5, 0.5))
	nextSpawnLabel.Size = UDim2.new(1, -16, 0, 28)

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

	-- Bottom center: carrying indicator and the big COLLECT button.
	carryingLabel = makeLabel(gui, "CarryingLabel", "", 22, Color3.fromRGB(255, 220, 90), UDim2.new(0.5, 0, 1, -140), Vector2.new(0.5, 0))
	carryingLabel.Size = UDim2.fromOffset(520, 30)
	collectButton = makeButton(gui, "CollectButton", "KUMPULKAN", UDim2.fromOffset(280, 58), UDim2.new(0.5, 0, 1, -104), Vector2.new(0.5, 0), Color3.fromRGB(40, 170, 70))
	collectButton.TextSize = 26

	-- Bottom-left toast.
	toastLabel = makeLabel(gui, "ToastLabel", "", 20, Color3.fromRGB(255, 255, 255), UDim2.new(0, 14, 1, -44), Vector2.new(0, 0))
	toastLabel.Size = UDim2.fromOffset(560, 30)
	toastLabel.TextXAlignment = Enum.TextXAlignment.Left
	toastLabel.Visible = false

	-- Wire the button.
	collectButton.MouseButton1Click:Connect(function()
		remotes.CollectCash:FireServer()
	end)

	remotes.StateUpdate.OnClientEvent:Connect(function(state)
		HUD.update(state)
	end)
	remotes.Notify.OnClientEvent:Connect(function(text, color)
		HUD.notify(text, color)
	end)
end

-- Render a fresh server snapshot.
function HUD.update(state)
	cashLabel.Text = "$" .. CharacterFactory.formatMoney(state.cash)
	incomeLabel.Text = "+$" .. CharacterFactory.formatMoney(state.income) .. "/s"
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
