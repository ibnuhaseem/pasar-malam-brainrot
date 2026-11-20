-- Effects: client-side feedback that makes actions feel real.
-- A green flash when cash is collected and a gold flash when a character is
-- bought. All of it is UI-only.

local TweenService = game:GetService("TweenService")

local Effects = {}

local flashFrame = nil

-- Build the full-screen flash frame once.
function Effects.init()
	local player = game:GetService("Players").LocalPlayer
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("PasarGui")
	flashFrame = Instance.new("Frame")
	flashFrame.Name = "FlashFrame"
	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flashFrame.BackgroundTransparency = 1
	flashFrame.BorderSizePixel = 0
	flashFrame.ZIndex = 5
	flashFrame.Parent = gui
end

-- Flash the whole screen a color, then fade it out over half a second.
function Effects.flashScreen(color)
	if not flashFrame then
		return
	end
	flashFrame.BackgroundColor3 = color
	flashFrame.BackgroundTransparency = 0.35
	TweenService:Create(flashFrame, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
end

-- Pop an element: grow it briefly, then shrink it back.
function Effects.bounce(element)
	if not element then
		return
	end
	local original = element.Size
	local big = UDim2.new(original.X.Scale, original.X.Offset + 8, original.Y.Scale, original.Y.Offset + 6)
	TweenService:Create(element, TweenInfo.new(0.12), { Size = big }):Play()
	task.delay(0.12, function()
		TweenService:Create(element, TweenInfo.new(0.15), { Size = original }):Play()
	end)
end

return Effects
