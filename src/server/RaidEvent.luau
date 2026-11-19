-- RaidEvent: Razia Satpol PP. Every few minutes a siren sounds and every
-- player has 20 seconds to dash home to their stall. When the raid hits,
-- anyone still carrying a character outside their own stall loses it —
-- the officers confiscate it. Standing inside your stall keeps you safe.

local RunService = game:GetService("RunService")

local GameState = require(script.Parent.GameState)
local WorldConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WorldConfig"))

local RaidEvent = {}

-- Is a player standing inside their own stall's footprint?
local function isPlayerHome(player, state)
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local stall = WorldConfig.STALLS[state.stallIndex]
	if not stall then
		return false
	end
	return WorldConfig.isInsideStall(stall, root.Position)
end

-- The raid hits: confiscate every carried character held outside its stall.
function RaidEvent.confiscateCarriedCharacters()
	local confiscated = 0
	for player, state in pairs(GameState.players) do
		if state.carrying and not isPlayerHome(player, state) then
			local model = state.carrying.model
			if model then
				model:Destroy()
			end
			local name = state.carrying.charId
			state.carrying = nil
			confiscated += 1
			GameState.notifyPlayer(player, "RAZIA! " .. name .. " disita Satpol PP!", Color3.fromRGB(255, 60, 60))
			GameState.broadcastState(player)
		elseif state.carrying then
			GameState.notifyPlayer(player, "Selamat! Kamu di dalam kios saat razia.", Color3.fromRGB(90, 255, 130))
		end
	end
	return confiscated
end

-- Move the raid clock one step: calm -> warning (siren) -> active (confiscate)
-- -> calm again. Returns the phase and seconds left for the HUD.
function RaidEvent.tickRaidClock(dt)
	local raid = GameState.raid
	raid.secondsLeft -= dt
	if raid.phase == "calm" and raid.secondsLeft <= 0 then
		raid.phase = "warning"
		raid.secondsLeft = WorldConfig.RAID_WARNING
	elseif raid.phase == "warning" and raid.secondsLeft <= 0 then
		raid.phase = "active"
		raid.secondsLeft = WorldConfig.RAID_DURATION
		RaidEvent.confiscateCarriedCharacters()
	elseif raid.phase == "active" and raid.secondsLeft <= 0 then
		raid.phase = "calm"
		raid.secondsLeft = WorldConfig.RAID_INTERVAL
	end
	return raid.phase, math.max(0, math.ceil(raid.secondsLeft))
end

-- Start the raid clock. The income loop in init.server.luau calls
-- tickRaidClock every second; this loop only drives the siren lights.
function RaidEvent.init()
	-- Flash the market lamps red while a raid is warning or active.
	local lamps = {}
	local workspace = game:GetService("Workspace")
	local market = workspace:FindFirstChild("MarketLights")
	if market then
		for _, light in ipairs(market:GetDescendants()) do
			if light:IsA("PointLight") then
				table.insert(lamps, light)
			end
		end
	end
	RunService.Heartbeat:Connect(function()
		local raid = GameState.raid
		local flashing = raid.phase == "warning" or raid.phase == "active"
		for _, light in ipairs(lamps) do
			if flashing then
				light.Color = Color3.fromRGB(255, 40, 40)
				light.Brightness = 2 + math.sin(os.clock() * 10) * 1.5
			else
				light.Color = Color3.fromRGB(255, 200, 120)
				light.Brightness = 2
			end
		end
	end)
end

return RaidEvent
