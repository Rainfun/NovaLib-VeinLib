# VisualLib Documentation
WARNING: THIS LIBRARY WAS SPECIFICALLY MADE FOR "VEIN HUB" IT MAY OR MAY NOT BE PRIVATED
**Version:** 1.0.1  
A modern, feature-rich UI library for Roblox with gradient themes, responsive design, and comprehensive element support.
This is a highly edited version of Orion Library a Discontinued Library, if you like this library go check out Rayfield too!

## Table of Contents
- [Getting Started](#getting-started)
- [Basic Usage](#basic-usage)
- [Window Configuration](#window-configuration)
- [Themes](#themes)
- [Tabs](#tabs)
- [Sections](#sections)
- [Elements](#elements)
- [Configuration System](#configuration-system)
- [Notifications](#notifications)
- [Best Practices](#best-practices)
- [Examples](#examples)

## Getting Started

### Installation
```lua
local VisualLib = loadstring(game:HttpGet("YOUR_SCRIPT_URL"))()
```

### Basic Setup
```lua
local Window = VisualLib:MakeWindow({
    Name = "My Script",
    ConfigFolder = "MyScript",
    SaveConfig = true
})
```

## Basic Usage

### Creating a Simple Interface
```lua
local VisualLib = loadstring(game:HttpGet("URL"))()

-- Create window
local Window = VisualLib:MakeWindow({
    Name = "Example Script",
    ConfigFolder = "ExampleScript",
    SaveConfig = true,
    IntroEnabled = true,
    IntroText = "Loading Example Script..."
})

-- Create tab
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "home"
})

-- Add elements
MainTab:AddButton({
    Name = "Test Button",
    Callback = function()
        print("Button clicked!")
    end
})
```

## Window Configuration

### MakeWindow Parameters
```lua
VisualLib:MakeWindow({
    Name = "Window Title",              -- Window title text
    ConfigFolder = "FolderName",        -- Config save folder name
    SaveConfig = true,                  -- Enable/disable config saving
    HidePremium = false,                -- Hide premium indicator
    IntroEnabled = true,                -- Show intro animation
    IntroText = "Loading...",           -- Intro animation text
    IntroIcon = "rbxassetid://123",     -- Intro animation icon
    ShowIcon = false,                   -- Show window icon
    Icon = "rbxassetid://123",          -- Window icon asset
    CloseCallback = function()          -- Function called when window closes
        print("Window closed")
    end
})
```

### Window Features
- **Draggable Interface**: Click and drag the top bar to move the window
- **Minimize/Maximize**: Click the minimize button to collapse the window
- **Close/Hide**: Click the close button to hide (use RightShift to reopen)
- **Responsive Design**: Automatically scales based on screen size
- **Configuration Persistence**: Automatically saves and loads settings

## Themes

### Default Theme Colors
```lua
VisualLib.Themes.Default = {
    Main = Color3.fromRGB(73, 109, 150),           -- Primary color
    Second = Color3.fromRGB(117, 152, 193),        -- Secondary color
    Stroke = Color3.fromRGB(208, 227, 249),        -- Border color
    Divider = Color3.fromRGB(61, 81, 105),         -- Divider color
    Text = Color3.fromRGB(197, 183, 138),          -- Primary text
    TextDark = Color3.fromRGB(150, 150, 150),      -- Secondary text
    
    -- Gradient colors for enhanced visuals
    MainGradient = {Color3.fromRGB(73, 109, 150), Color3.fromRGB(61, 81, 105)},
    ButtonGradient = {Color3.fromRGB(117, 152, 193), Color3.fromRGB(208, 227, 249)},
    TopBarGradient = {Color3.fromRGB(208, 227, 249), Color3.fromRGB(117, 152, 193)}
}
```

### Accessing Theme System
```lua
-- Current selected theme
local currentTheme = VisualLib.SelectedTheme

-- Get theme color
local mainColor = VisualLib.Themes[VisualLib.SelectedTheme].Main
```

## Tabs

### Creating Tabs
```lua
local Tab = Window:MakeTab({
    Name = "Tab Name",              -- Tab display name
    Icon = "icon-name",             -- Icon name or asset ID
    PremiumOnly = false             -- Restrict to premium users
})
```

### Icon Support
VisualLib supports Feather Icons by name:
```lua
-- Using icon names
Icon = "home"
Icon = "settings" 
Icon = "user"
Icon = "lock"

-- Using asset IDs
Icon = "rbxassetid://1234567890"
```

### Premium-Only Tabs
```lua
local PremiumTab = Window:MakeTab({
    Name = "Premium Features",
    Icon = "star",
    PremiumOnly = true  -- Restricts access and shows premium message
})
```

## Sections

### Creating Sections
```lua
local Section = Tab:AddSection({
    Name = "Section Name"
})

-- Add elements to section
Section:AddButton({
    Name = "Section Button",
    Callback = function() end
})
```

## Elements

### Labels
Display static text information.
```lua
local Label = Tab:AddLabel("Static text display")

-- Update label text
Label:Set("New text content")
```

### Paragraphs
Display multi-line text with title and content.
```lua
local Paragraph = Tab:AddParagraph("Title", "Multi-line content text that can wrap")

-- Update paragraph
Paragraph:Set("Updated content text")
```

### Buttons
Interactive buttons with callbacks.
```lua
local Button = Tab:AddButton({
    Name = "Click Me",
    Icon = "rbxassetid://3944703587",  -- Optional icon
    Callback = function()
        print("Button was clicked!")
        VisualLib:MakeNotification({
            Name = "Button Clicked",
            Content = "The button was successfully clicked!",
            Time = 3
        })
    end
})

-- Update button text
Button:Set("New Button Text")
```

### Toggles
Boolean switches with state persistence.
```lua
local Toggle = Tab:AddToggle({
    Name = "Enable Feature",
    Default = false,                    -- Starting state
    Color = Color3.fromRGB(0, 255, 0), -- Toggle color when active
    Flag = "FeatureToggle",             -- Unique identifier for saving
    Save = true,                        -- Save state to config
    Callback = function(Value)
        print("Toggle is now:", Value)
        if Value then
            -- Enable feature
        else
            -- Disable feature
        end
    end
})

-- Programmatically set toggle
Toggle:Set(true)
```

### Sliders
Numeric input with visual slider control.
```lua
local Slider = Tab:AddSlider({
    Name = "Speed Multiplier",
    Min = 1,                           -- Minimum value
    Max = 10,                          -- Maximum value
    Increment = 0.5,                   -- Step size
    Default = 5,                       -- Starting value
    ValueName = "x",                   -- Unit suffix
    Color = Color3.fromRGB(255, 100, 100),
    Flag = "SpeedSlider",
    Save = true,
    Callback = function(Value)
        print("Speed set to:", Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value * 16
    end
})

-- Set slider value
Slider:Set(7.5)
```

### Dropdowns
Selection lists with multiple options.
```lua
local Dropdown = Tab:AddDropdown({
    Name = "Select Option",
    Options = {"Option 1", "Option 2", "Option 3"},
    Default = "Option 1",
    Flag = "OptionDropdown",
    Save = true,
    Callback = function(Value)
        print("Selected:", Value)
    end
})

-- Update dropdown options
Dropdown:Refresh({"New Option 1", "New Option 2"}, true) -- true = clear existing

-- Set dropdown value
Dropdown:Set("New Option 1")
```

### Keybinds
Key binding system with hold support.
```lua
local Bind = Tab:AddBind({
    Name = "Toggle Fly",
    Default = Enum.KeyCode.F,          -- Default key
    Hold = false,                      -- false = toggle, true = hold
    Flag = "FlyBind", 
    Save = true,
    Callback = function(Pressed)       -- Pressed only matters if Hold = true
        if not Hold then
            print("Fly toggled!")
        else
            print("Fly active:", Pressed)
        end
    end
})

-- Set new keybind
Bind:Set(Enum.KeyCode.G)
```

### Textboxes
Text input fields.
```lua
local Textbox = Tab:AddTextbox({
    Name = "Enter Text",
    Default = "Default text",
    TextDisappear = false,             -- Clear text after losing focus
    Callback = function(Text)
        print("Text entered:", Text)
    end
})
```

### Colorpickers
Color selection with HSV picker.
```lua
local Colorpicker = Tab:AddColorpicker({
    Name = "Choose Color",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "ColorChoice",
    Save = true,
    Callback = function(Color)
        print("Color selected:", Color)
        -- Apply color to something
    end
})

-- Set color programmatically
Colorpicker:Set(Color3.fromRGB(255, 0, 0))
```

## Configuration System

### Automatic Saving
When `SaveConfig = true`, VisualLib automatically saves flagged elements:
```lua
-- Elements with Flag and Save = true are automatically saved
local Toggle = Tab:AddToggle({
    Name = "Auto Save Me",
    Flag = "AutoSaveToggle",    -- Required for saving
    Save = true,                -- Enable saving
    Default = false
})
```

### Manual Configuration Management
```lua
-- Save current configuration
VisualLib.SaveCfg = true
VisualLib.Folder = "MyScript"

-- Access saved flags
local toggleState = VisualLib.Flags["AutoSaveToggle"].Value
```

### Configuration Files
- Saved to: `workspace/[ConfigFolder]/[GameId].txt`
- Format: JSON with flag names as keys
- Loaded automatically on script start if file exists

## Notifications

### Creating Notifications
```lua
VisualLib:MakeNotification({
    Name = "Notification Title",
    Content = "Notification message content",
    Image = "rbxassetid://4384403532",  -- Optional icon
    Time = 5                            -- Display duration in seconds
})
```

### Notification Features
- **Smooth Animations**: Slide in from right, fade out gracefully
- **Auto-positioning**: Stack vertically in bottom-right corner
- **Responsive**: Scale with screen size
- **Themed**: Match current UI theme colors

## Best Practices

### Organization
```lua
-- Group related elements in sections
local MainSection = Tab:AddSection({Name = "Main Features"})
MainSection:AddToggle({...})
MainSection:AddSlider({...})

local SettingsSection = Tab:AddSection({Name = "Settings"})
SettingsSection:AddDropdown({...})
SettingsSection:AddColorpicker({...})
```

### Flag Naming
```lua
-- Use descriptive, unique flag names
Flag = "PlayerSpeed_Slider"      -- Good
Flag = "Toggle1"                 -- Bad

-- Include element type for clarity
Flag = "ESP_Toggle"
Flag = "Aimbot_Keybind"
Flag = "TeamColor_Colorpicker"
```

### Error Handling
```lua
local success, result = pcall(function()
    return Tab:AddSlider({
        Name = "Risky Slider",
        Callback = function(Value)
            -- Potentially erroring code
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    })
end)

if not success then
    VisualLib:MakeNotification({
        Name = "Error",
        Content = "Failed to create slider: " .. result,
        Time = 5
    })
end
```

## Examples

### Complete Script Structure
```lua
local VisualLib = loadstring(game:HttpGet("URL"))()

-- Initialize library
local Window = VisualLib:MakeWindow({
    Name = "Example Script v1.0",
    ConfigFolder = "ExampleScript",
    SaveConfig = true,
    IntroEnabled = true,
    IntroText = "Example Script",
    IntroIcon = "rbxassetid://4483345875"
})

-- Main functionality tab
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "zap"
})

local MainSection = MainTab:AddSection({Name = "Player Modifications"})

-- Speed modification
local SpeedToggle = MainSection:AddToggle({
    Name = "Speed Boost",
    Default = false,
    Flag = "SpeedBoost",
    Save = true,
    Callback = function(Value)
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = Value and 50 or 16
        end
    end
})

local SpeedSlider = MainSection:AddSlider({
    Name = "Speed Amount",
    Min = 16,
    Max = 200,
    Default = 50,
    ValueName = "studs/s",
    Flag = "SpeedAmount",
    Save = true,
    Callback = function(Value)
        if SpeedToggle.Value then
            local character = game.Players.LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.WalkSpeed = Value
            end
        end
    end
})

-- Jump modification
local JumpSlider = MainSection:AddSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 200,
    Default = 50,
    Flag = "JumpPower",
    Save = true,
    Callback = function(Value)
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.JumpPower = Value
        end
    end
})

-- Settings tab
local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "settings"
})

local UISection = SettingsTab:AddSection({Name = "Interface"})

-- UI Color customization
local UIColor = UISection:AddColorpicker({
    Name = "UI Accent Color",
    Default = Color3.fromRGB(0, 162, 255),
    Flag = "UIColor",
    Save = true,
    Callback = function(Color)
        -- Could be used to theme the UI
        print("UI Color changed to:", Color)
    end
})

-- Keybind for toggling UI
local ToggleUI = UISection:AddBind({
    Name = "Toggle Interface",
    Default = Enum.KeyCode.RightShift,
    Callback = function()
        VisualLib:MakeNotification({
            Name = "UI Toggle",
            Content = "Interface visibility toggled!",
            Time = 2
        })
    end
})

-- About section
local AboutSection = SettingsTab:AddSection({Name = "About"})

AboutSection:AddLabel("Example Script v1.0")
AboutSection:AddParagraph("Description", "This is an example script showcasing VisualLib features and capabilities.")

AboutSection:AddButton({
    Name = "Join Discord",
    Icon = "message-circle",
    Callback = function()
        VisualLib:MakeNotification({
            Name = "Discord",
            Content = "Discord link copied to clipboard!",
            Time = 3
        })
    end
})

-- Initialize the library
VisualLib:Init()

VisualLib:MakeNotification({
    Name = "Script Loaded",
    Content = "Example script has been successfully loaded!",
    Time = 4
})
```

### Advanced Element Usage
```lua
-- Dynamic dropdown with refresh
local GameModeDropdown = Tab:AddDropdown({
    Name = "Game Mode",
    Options = {},
    Callback = function(Value)
        print("Game mode:", Value)
    end
})

-- Update options based on game state
spawn(function()
    while wait(5) do
        local newModes = {"Classic", "Ranked", "Custom"}
        if game.PlaceId == 123456 then
            table.insert(newModes, "Special Mode")
        end
        GameModeDropdown:Refresh(newModes, true)
    end
end)

-- Hold-type keybind
local FlyBind = Tab:AddBind({
    Name = "Fly (Hold)",
    Default = Enum.KeyCode.Space,
    Hold = true,
    Callback = function(IsHolding)
        local character = game.Players.LocalPlayer.Character
        if character then
            if IsHolding then
                -- Start flying
                print("Flying started")
            else
                -- Stop flying
                print("Flying stopped")
            end
        end
    end
})
```

## API Reference

### Library Functions
- `VisualLib:MakeWindow(config)` - Creates main window
- `VisualLib:MakeNotification(config)` - Shows notification
- `VisualLib:Init()` - Initializes library (loads configs)
- `VisualLib:IsRunning()` - Returns if UI is active
- `VisualLib:Destroy()` - Destroys UI completely

### Window Functions
- `Window:MakeTab(config)` - Creates new tab

### Tab Functions
- `Tab:AddSection(config)` - Creates section divider
- `Tab:AddLabel(text)` - Creates text label
- `Tab:AddParagraph(title, content)` - Creates paragraph
- `Tab:AddButton(config)` - Creates button
- `Tab:AddToggle(config)` - Creates toggle switch
- `Tab:AddSlider(config)` - Creates slider
- `Tab:AddDropdown(config)` - Creates dropdown
- `Tab:AddBind(config)` - Creates keybind
- `Tab:AddTextbox(config)` - Creates text input
- `Tab:AddColorpicker(config)` - Creates color picker

### Element Methods
- `Element:Set(value)` - Updates element value
- `Dropdown:Refresh(options, clear)` - Updates dropdown options

---

*VisualLib v1.0.1 - Modern Roblox UI Library*
