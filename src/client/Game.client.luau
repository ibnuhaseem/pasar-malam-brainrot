-- Game.client: the client bootstrap for Pasar Malam Brainrot.
-- Waits for the server's remotes, builds the HUD, the shop panels and the
-- effects, then forwards every StateUpdate snapshot to the modules that
-- render it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuyAndCarry = require(script.Parent.BuyAndCarry)
local Effects = require(script.Parent.Effects)
local HUD = require(script.Parent.HUD)
local ShopAndIndex = require(script.Parent.ShopAndIndex)

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local remotes = {
	PlaceCharacter = remotesFolder:WaitForChild("PlaceCharacter"),
	CollectCash = remotesFolder:WaitForChild("CollectCash"),
	LockStall = remotesFolder:WaitForChild("LockStall"),
	Rebirth = remotesFolder:WaitForChild("Rebirth"),
	ClaimMission = remotesFolder:WaitForChild("ClaimMission"),
	StateUpdate = remotesFolder:WaitForChild("StateUpdate"),
	Notify = remotesFolder:WaitForChild("Notify"),
}

HUD.init(remotes)
Effects.init()
ShopAndIndex.init(remotes)
BuyAndCarry.init(remotes)

-- The HUD buttons toggle the panels.
HUD.toggleMenu = function()
	ShopAndIndex.showMenu()
end
HUD.toggleMissions = function()
	ShopAndIndex.showMissions()
end

-- Every snapshot goes to the HUD and to the open shop panel.
remotes.StateUpdate.OnClientEvent:Connect(function(state)
	ShopAndIndex.update(state)
end)

-- Flash feedback on the big moments.
remotes.Notify.OnClientEvent:Connect(function(text, _color)
	if string.find(text, "Dikumpulkan") then
		Effects.flashScreen(Color3.fromRGB(60, 220, 100))
	elseif string.find(text, "Dapat") then
		Effects.flashScreen(Color3.fromRGB(255, 220, 90))
	elseif string.find(text, "disita") then
		Effects.flashScreen(Color3.fromRGB(255, 60, 60))
	end
end)

print("Pasar Malam Brainrot: client siap.")
