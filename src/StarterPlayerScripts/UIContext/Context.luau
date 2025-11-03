-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
-- Dependecies
local React = require(ReplicatedStorage.Packages.React)

-- Context
local UIContext = React.createContext(nil)

-- Functions

local UIHandler = function(bool: boolean)
	GuiService.TouchControlsEnabled = bool
	StarterGui:SetCore("TopbarEnabled", bool)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, bool)
end

local UIContextProvider = function(props: { children: { any } })
	local activeApp, setActiveApp = React.useState(nil :: string?)

	local openApp = function(appName: string)
		setActiveApp(appName)
		UIHandler(false)
	end

	local closeApp = function()
		setActiveApp(nil)

		UIHandler(true)
	end

	return React.createElement(UIContext.Provider, {
		value = {
			activeApp = activeApp,
			openApp = openApp,
			closeApp = closeApp,
		},
	}, props.children)
end

local useUIContext = function(): {
	activeApp: string?,
	openApp: (string) -> (),
	closeApp: () -> (),
}
	local ui = React.useContext(UIContext)

	if ui == nil then
		error("Using UI Context wrong")
	end

	return ui
end

return {
	useUIContext = useUIContext,
	UIContextProvider = UIContextProvider,
}
