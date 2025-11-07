local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	primaryColor = ReplicatedStorage:WaitForChild("Colors"):WaitForChild("PrimaryUI", 15).Value :: Color3Value,
	secondaryColor = ReplicatedStorage:WaitForChild("Colors"):WaitForChild("SecondaryUI").Value :: Color3Value,
	backgroundColor = ReplicatedStorage:WaitForChild("Colors"):WaitForChild("BackgroundUI").Value :: Color3Value,
	foregroundColor = ReplicatedStorage:WaitForChild("Colors"):WaitForChild("ForegroundUI").Value :: Color3Value,
	accentColor = ReplicatedStorage:WaitForChild("Colors"):WaitForChild("AccentUI").Value :: Color3Value,
	destructiveColor = ReplicatedStorage:WaitForChild("Colors"):WaitForChild("DestructiveUI").Value :: Color3Value,
	textColor = ReplicatedStorage:WaitForChild("Colors"):WaitForChild("TextUI").Value :: Color3Value,
	imageColor = ReplicatedStorage:WaitForChild("Colors"):WaitForChild("ImageUI").Value :: Color3Value,
}
