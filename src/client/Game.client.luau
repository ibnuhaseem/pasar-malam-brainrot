-- Game.client: the client bootstrap for Pasar Malam Brainrot.
-- Waits for the server's remotes, builds the HUD and the effects, and wires
-- the E key to place what the player is carrying.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuyAndCarry = require(script.Parent.BuyAndCarry)
local Effects = require(script.Parent.Effects)
local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local remotes = {
	PlaceCharacter = remotesFolder:WaitForChild("PlaceCharacter"),
	CollectCash = remotesFolder:WaitForChild("CollectCash"),
	StateUpdate = remotesFolder:WaitForChild("StateUpdate"),
	Notify = remotesFolder:WaitForChild("Notify"),
}

HUD.init(remotes)
Effects.init()
BuyAndCarry.init(remotes)

-- Flash feedback on the big moments.
remotes.Notify.OnClientEvent:Connect(function(text, _color)
	if string.find(text, "Dikumpulkan") then
		Effects.flashScreen(Color3.fromRGB(60, 220, 100))
	elseif string.find(text, "Dapat") then
		Effects.flashScreen(Color3.fromRGB(255, 220, 90))
	end
end)

print("Pasar Malam Brainrot: client siap.")
