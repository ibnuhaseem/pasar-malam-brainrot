-- ShopAndIndex: the two panels the player opens from the HUD.
-- BUKU MENU is the index of all 18 characters: owned ones are lit, the rest
-- are greyed out, each with its rarity and money per second.
-- PESANAN is the mission list: progress, reward, and a claim button when done.
-- Game.client.luau calls ShopAndIndex.init(remotes) once, then
-- ShopAndIndex.update(state) on every StateUpdate.

local Characters = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Characters"))
local Rarities = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Rarities"))
local CharacterFactory = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CharacterFactory"))

local ShopAndIndex = {}

local remotes = nil
local panel = nil
local menuList = nil
local missionList = nil
local lastState = nil
local showing = nil -- "menu" | "missions" | nil

local function makePanel(parent, name)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.fromOffset(620, 460)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 34)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	return frame
end

local function makeTitle(parent, text)
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 0, 40)
	title.Position = UDim2.new(0, 16, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = text
	title.TextSize = 26
	title.Font = Enum.Font.SourceSansBold
	title.TextColor3 = Color3.fromRGB(255, 220, 90)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = parent
	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.fromOffset(40, 40)
	close.Position = UDim2.new(1, -48, 0, 8)
	close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	close.Text = "X"
	close.TextSize = 22
	close.Font = Enum.Font.SourceSansBold
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.Parent = parent
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = close
	close.MouseButton1Click:Connect(function()
		ShopAndIndex.hide()
	end)
	return title
end

local function makeList(parent)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.Size = UDim2.new(1, -32, 1, -60)
	scroll.Position = UDim2.new(0, 16, 0, 52)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = scroll
	return scroll
end

local function makeRow(parent, text, textColor)
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	row.BorderSizePixel = 0
	row.Text = text
	row.TextSize = 20
	row.Font = Enum.Font.SourceSansBold
	row.TextColor3 = textColor or Color3.fromRGB(230, 230, 230)
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = row
	return row
end

-- Build both panels once.
function ShopAndIndex.init(serverRemotes)
	remotes = serverRemotes
	local player = game:GetService("Players").LocalPlayer
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("PasarGui")
	panel = makePanel(gui, "ShopPanel")
	makeTitle(panel, "BUKU MENU")
	menuList = makeList(panel)
	missionList = makeList(panel)
	missionList.Visible = false
end

-- Show the index panel.
function ShopAndIndex.showMenu()
	if not panel then
		return
	end
	showing = "menu"
	panel.Visible = true
	menuList.Visible = true
	missionList.Visible = false
	panel:FindFirstChild("Title").Text = "BUKU MENU — Koleksi Karakter"
	if lastState then
		ShopAndIndex.update(lastState)
	end
end

-- Show the missions panel.
function ShopAndIndex.showMissions()
	if not panel then
		return
	end
	showing = "missions"
	panel.Visible = true
	menuList.Visible = false
	missionList.Visible = true
	panel:FindFirstChild("Title").Text = "PESANAN — Misi Berhadiah"
	if lastState then
		ShopAndIndex.update(lastState)
	end
end

-- Hide whichever panel is open.
function ShopAndIndex.hide()
	if panel then
		panel.Visible = false
	end
	showing = nil
end

-- Rebuild the open panel from a fresh server snapshot.
function ShopAndIndex.update(state)
	lastState = state
	if showing == "menu" then
		for _, child in ipairs(menuList:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		for _, entry in ipairs(state.collection) do
			local char = Characters.findById(entry.id)
			local owned = entry.owned
			local text = (owned and "[PUNYA] " or "[BELUM] ") .. entry.name .. "  •  " .. entry.rarity:upper()
				.. "  •  $" .. CharacterFactory.formatMoney(entry.rate) .. "/s"
			if not owned then
				text = text .. "  •  $" .. CharacterFactory.formatMoney(entry.price)
			end
			local color = owned and Rarities.colorOfRarity(entry.rarity) or Color3.fromRGB(120, 120, 130)
			makeRow(menuList, text, color)
		end
	elseif showing == "missions" then
		for _, child in ipairs(missionList:GetChildren()) do
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for _, mission in ipairs(state.missions) do
			local done = mission.progress >= mission.target
			local text = mission.name .. "  —  " .. mission.description
				.. "  (" .. math.min(mission.progress, mission.target) .. "/" .. mission.target .. ")"
				.. "  •  $" .. CharacterFactory.formatMoney(mission.reward)
			local row = makeRow(missionList, text, done and Color3.fromRGB(120, 255, 140) or Color3.fromRGB(230, 230, 230))
			if done and not mission.claimed then
				local claim = Instance.new("TextButton")
				claim.Name = "Claim"
				claim.Size = UDim2.fromOffset(90, 34)
				claim.Position = UDim2.new(1, -96, 0, 0)
				claim.BackgroundColor3 = Color3.fromRGB(40, 170, 70)
				claim.Text = "KLAIM"
				claim.TextSize = 18
				claim.Font = Enum.Font.SourceSansBold
				claim.TextColor3 = Color3.fromRGB(255, 255, 255)
				claim.Parent = row
				local claimCorner = Instance.new("UICorner")
				claimCorner.CornerRadius = UDim.new(0, 6)
				claimCorner.Parent = claim
				claim.MouseButton1Click:Connect(function()
					remotes.ClaimMission:FireServer(mission.id)
				end)
			elseif mission.claimed then
				row.Text = text .. "  [DIKLAIM]"
			end
		end
	end
end

return ShopAndIndex
