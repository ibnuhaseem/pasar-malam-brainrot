-- BuyAndCarry: the "place what you are carrying" input.
-- Buying itself is a server ClickDetector on each lane character (click it,
-- pay, carry it). This module only handles the E key: when the player stands
-- inside their own stall and presses E, the carried character is placed on
-- the first free pedestal.

local UserInputService = game:GetService("UserInputService")

local BuyAndCarry = {}

-- Wire the E key to the server's PlaceCharacter remote.
function BuyAndCarry.init(remotes)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.E then
			remotes.PlaceCharacter:FireServer()
		end
	end)
end

return BuyAndCarry
