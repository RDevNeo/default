-- Services
local AvatarEditorService = game:GetService("AvatarEditorService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

local function SaveConfirm(props: {
	onClose: () -> (),
	onBackButton: () -> (),
	action: string,
	setAction: (string) -> (),
})
	return React.createElement("Frame", {
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(0.35, 0.14),
		BackgroundColor3 = Colors.primaryColor,
		Name = "SaveConfirm",
	}, {
		React.createElement("UICorner", {
			CornerRadius = UDim.new(0.05, 0),
		}),

		React.createElement("UIStroke", {
			Thickness = 4,
			Color = Colors.secondaryColor,
		}),

		saveEquip = React.createElement("TextButton", {
			BackgroundColor3 = Colors.accentColor,
			Text = "Equip Avatar",
			AnchorPoint = Vector2.new(0.5, 0),
			TextScaled = true,
			Font = Enum.Font.FredokaOne,
			TextColor3 = Colors.textColor,
			Position = UDim2.fromScale(0.25, 0.32),
			Size = UDim2.fromScale(0.4, 0.44),

			[React.Event.Activated] = function(rbx)
				props.setAction("Equip")
				props.onClose()
				AvatarEditorService:PromptAllowInventoryReadAccess()
			end,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0.1, 0),
			}),
		}),

		saveOutfit = React.createElement("TextButton", {
			BackgroundColor3 = Colors.secondaryColor,
			Text = "Save to Inventory",
			AnchorPoint = Vector2.new(0.5, 0),
			TextScaled = true,
			Font = Enum.Font.FredokaOne,
			TextColor3 = Colors.textColor,
			Position = UDim2.fromScale(0.75, 0.32),
			Size = UDim2.fromScale(0.4, 0.44),

			[React.Event.Activated] = function(rbx)
				props.setAction("Save")
				props.onClose()
				AvatarEditorService:PromptAllowInventoryReadAccess()
			end,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0.1, 0),
			}),
		}),

		backButton = React.createElement("ImageButton", {
			Image = "rbxassetid://109813459380067",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.08, 0.3),
			Position = UDim2.fromScale(0.05, 0.15),

			[React.Event.Activated] = function(rbx)
				props.onBackButton()
			end,
		}),

		CloseButton = React.createElement("TextButton", {
			Name = "CloseButton",
			Size = UDim2.fromScale(0.2, 0.2),
			Position = UDim2.fromScale(0.98, 0.03),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Colors.destructiveColor,
			Text = "X",
			TextColor3 = Colors.textColor,
			TextScaled = true,
			Font = Enum.Font.FredokaOne,

			[React.Event.Activated] = props.onClose,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0.1, 0),
			}),
			React.createElement("UIStroke", {
				Thickness = 3,
				Color = Color3.new(
					math.clamp(Colors.destructiveColor.R * 0.5, 0, 1),
					math.clamp(Colors.destructiveColor.G * 0.5, 0, 1),
					math.clamp(Colors.destructiveColor.B * 0.5, 0, 1)
				),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			React.createElement("UIAspectRatioConstraint"),
		}),
	})
end

local function SaveConfirmApp()
	local ui = useUIContext()
	local action, setAction = React.useState(nil)
	local APP_NAME = "Save Confirm"

	React.useEffect(function()
		AvatarEditorService.PromptAllowInventoryReadAccessCompleted:Connect(function(result: Enum.AvatarPromptResult)
			if result ~= Enum.AvatarPromptResult.Success or not action then
				return
			end

			local Humanoid = Players.LocalPlayer.Character.Humanoid :: Humanoid
			if not Humanoid then
				return
			end

			if action == "Equip" then
				AvatarEditorService:PromptSaveAvatar(Humanoid:GetAppliedDescription(), Humanoid.RigType)
			else
				AvatarEditorService:PromptCreateOutfit(Humanoid:GetAppliedDescription(), Humanoid.RigType)
			end
		end)
	end)

	return if ui.activeApp == APP_NAME
		then React.createElement(SaveConfirm, {
			onClose = function()
				ui.closeApp()
			end,
			onBackButton = function()
				ui.openApp("Save To Roblox")
			end,
			action = action,
			setAction = setAction,
		})
		else nil
end

return SaveConfirmApp
