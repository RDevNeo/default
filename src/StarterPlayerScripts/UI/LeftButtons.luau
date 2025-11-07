-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

-- Dependencies
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)
local React = require(ReplicatedStorage.Packages.React)
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local Net = require(ReplicatedStorage.Packages.Net)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local Humanoid = character.Humanoid :: Humanoid
local HoverSound = ReplicatedStorage:WaitForChild("HoverSound") :: Sound

local createButton = function(props: {
	Name: string,
	Order: number,
	onPress: ((Instance?) -> ())?,
})
	local size, setSize = ReactFlow.useSpring({
		start = UDim2.fromScale(0.9, 0.07),
		target = UDim2.fromScale(0.9, 0.07),
		speed = 18,
		damper = 0.8,
	})

	local function onHover()
		setSize({
			target = UDim2.fromScale(1, 0.08),
		})
		HoverSound:Play()
	end

	local function onUnhover()
		setSize({
			target = UDim2.fromScale(0.9, 0.07),
		})
	end

	return React.createElement("TextButton", {
		Size = size,
		Name = props.Name,
		BackgroundColor3 = Colors.primaryColor,
		TextColor3 = Colors.textColor,
		Font = Enum.Font.FredokaOne,
		Text = props.Name,
		TextScaled = true,
		LayoutOrder = props.Order,

		[React.Event.MouseEnter] = onHover,
		[React.Event.MouseLeave] = onUnhover,

		[React.Event.Activated] = function(rbx)
			if props.onPress then
				props.onPress(rbx)
			end
		end,
	}, {
		UICorner = React.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
		UIStroke = React.createElement("UIStroke", {
			Thickness = 2,
			Color = Colors.accentColor,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		UIPadding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0.02, 0),
			PaddingBottom = UDim.new(0.02, 0),
			PaddingRight = UDim.new(0.02, 0),
			PaddingLeft = UDim.new(0.02, 0),
		}),
	})
end

local function ShopApp()
	local run, setRun = React.useState(false)
	local music, setMusic = React.useState(true)
	local ui = useUIContext()

	local function toggleRun()
		setRun(function(prev)
			return not prev
		end)
	end

	local function toggleMusic()
		setMusic(function(prev)
			return not prev
		end)
	end

	local function onDonate()
		ui.openApp("Donates")
	end

	local function onReset()
		Signals.Reset:FireServer()
	end

	local function onLikes()
		ui.openApp("Likes")
	end

	React.useEffect(function()
		local musicSound: Sound = ReplicatedStorage:WaitForChild("BackgroundSound")
		local soundId: number = Net:Invoke("GetMusicID")

		if not soundId or soundId == 0 then
			return warn("Sound id not configured.")
		end
		if not musicSound then
			return warn("No music sound found in Workspace with the name of: 'BackgroundSound' ")
		end

		musicSound.SoundId = "rbxassetid://" .. tostring(soundId)

		if music then
			musicSound:Resume()
		else
			musicSound:Pause()
		end
		return
	end, { music })

	React.useEffect(function()
		if run then
			Humanoid.WalkSpeed = Net:Invoke("GetRunConfig")
		else
			Humanoid.WalkSpeed = 16
		end
	end, { run })

	React.useEffect(function()
		local connection = UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.LeftShift then
				toggleRun()
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return if ui.activeApp == nil
		then React.createElement("Frame", {
			Name = "RightButtons",
			Size = UDim2.fromScale(0.16, 1),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			BackgroundTransparency = 1,
		}, {
			UIListLayout = React.createElement("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.02, 0),
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			Run = React.createElement(createButton, {
				Name = run and "Walk" or "Run",
				Order = 4,
				onPress = toggleRun,
			}),

			Music = React.createElement(createButton, {
				Name = music and "Music Off" or "Music On",
				Order = 5,
				onPress = toggleMusic,
			}),

			Donate = React.createElement(createButton, { Name = "Donate", Order = 1, onPress = onDonate }),
			Likes = React.createElement(createButton, { Name = "Likes", Order = 2, onPress = onLikes }),
			Reset = React.createElement(createButton, { Name = "Reset", Order = 3, onPress = onReset }),
		})
		else nil
end

return ShopApp
