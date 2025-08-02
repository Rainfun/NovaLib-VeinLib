local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")
local ColorInput, HueInput

local NovaUI = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(10, 10, 20),            -- Dark blue background
            Second = Color3.fromRGB(15, 15, 30),           -- Darker blue elements
            Stroke = Color3.fromRGB(255, 105, 180),        -- Neon pink accent
            Divider = Color3.fromRGB(25, 25, 45),          -- Dark blue dividers
            Text = Color3.fromRGB(255, 255, 255),          -- White text
            TextDark = Color3.fromRGB(200, 200, 220),      -- Light gray text
            Accent = Color3.fromRGB(0, 200, 255)           -- Neon blue accent
        }
    },
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false,
    Version = "v1.2.0"
}

-- Gradient creation function
local function CreateGradient(parent, colors, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colors)
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

-- Lucide Icons
local Icons = {}

local Success, Response = pcall(function()
    if game.HttpGetAsync then
        local response = game:HttpGetAsync("https://raw.githubusercontent.com/frappedevs/lucideblox/refs/heads/master/src/modules/util/icons.json")
        Icons = HttpService:JSONDecode(response).icons or {}
    end
end)

if not Success then
    warn("Nova UI - Failed to load Lucide Icons, using fallback")
    Icons = {}
end

local function GetIcon(IconName)
    if Icons and Icons[IconName] then
        return Icons[IconName]
    else
        return IconName -- Return original instead of nil
    end
end   

local Nova = Instance.new("ScreenGui")
Nova.Name = "NovaUI"

-- Better environment detection
if gethui then
    Nova.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(Nova)
    Nova.Parent = game.CoreGui
else
    Nova.Parent = game.CoreGui
end

-- Clean up existing instances
local parentGui = Nova.Parent
if parentGui then
    for _, Interface in ipairs(parentGui:GetChildren()) do
        if Interface.Name == Nova.Name and Interface ~= Nova then
            Interface:Destroy()
        end
    end
end

-- Also check CoreGui as fallback
for _, Interface in ipairs(game.CoreGui:GetChildren()) do
    if Interface.Name == Nova.Name and Interface ~= Nova then
        Interface:Destroy()
    end
end

function NovaUI:IsRunning()
    if not Nova or not Nova.Parent then
        return false
    end
    return Nova.Parent == gethui() or Nova.Parent == game:GetService("CoreGui")
end

local function AddConnection(Signal, Function)
    if (not NovaUI:IsRunning()) then
        return
    end
    local SignalConnect = Signal:Connect(Function)
    table.insert(NovaUI.Connections, SignalConnect)
    return SignalConnect
end

task.spawn(function()
    while (NovaUI:IsRunning()) do
        wait()
    end

    for _, Connection in next, NovaUI.Connections do
        Connection:Disconnect()
    end
end)

local function AddDraggingFunctionality(DragPoint, Main)
    pcall(function()
        local Dragging, MousePos, FramePos = false
        
        DragPoint.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                MousePos = input.Position
                FramePos = Main.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)

        AddConnection(UserInputService.InputChanged, function(input)
            if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local Delta = input.Position - MousePos
                Main.Position = UDim2.new(
                    FramePos.X.Scale, 
                    FramePos.X.Offset + Delta.X, 
                    FramePos.Y.Scale, 
                    FramePos.Y.Offset + Delta.Y
                )
            end
        end)
    end)
end

local function Create(Name, Properties, Children)
    local Object = Instance.new(Name)
    for i, v in next, Properties or {} do
        Object[i] = v
    end
    for i, v in next, Children or {} do
        v.Parent = Object
    end
    return Object
end

local function CreateElement(ElementName, ElementFunction)
    NovaUI.Elements[ElementName] = function(...)
        return ElementFunction(...)
    end
end

local function MakeElement(ElementName, ...)
    local NewElement = NovaUI.Elements[ElementName](...)
    return NewElement
end

local function SetProps(Element, Props)
    table.foreach(Props, function(Property, Value)
        Element[Property] = Value
    end)
    return Element
end

local function SetChildren(Element, Children)
    table.foreach(Children, function(_, Child)
        Child.Parent = Element
    end)
    return Element
end

local function Round(Number, Factor)
    local Result = math.floor(Number/Factor + (math.sign(Number) * 0.5)) * Factor
    if Result < 0 then Result = Result + Factor end
    return Result
end

local function ReturnProperty(Object)
    if Object:IsA("Frame") or Object:IsA("TextButton") then
        return "BackgroundColor3"
    end 
    if Object:IsA("ScrollingFrame") then
        return "ScrollBarImageColor3"
    end 
    if Object:IsA("UIStroke") then
        return "Color"
    end 
    if Object:IsA("TextLabel") or Object:IsA("TextBox") then
        return "TextColor3"
    end   
    if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
        return "ImageColor3"
    end   
end

local function AddThemeObject(Object, Type)
    if not NovaUI.ThemeObjects[Type] then
        NovaUI.ThemeObjects[Type] = {}
    end    
    table.insert(NovaUI.ThemeObjects[Type], Object)
    Object[ReturnProperty(Object)] = NovaUI.Themes[NovaUI.SelectedTheme][Type]
    return Object
end    

local function SetTheme()
    for Name, Type in pairs(NovaUI.ThemeObjects) do
        for _, Object in pairs(Type) do
            Object[ReturnProperty(Object)] = NovaUI.Themes[NovaUI.SelectedTheme][Name]
        end    
    end    
end

local function PackColor(Color)
    return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function UnpackColor(Color)
    return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadCfg(Config)
    pcall(function()
        local Data = HttpService:JSONDecode(Config)
        for a, b in pairs(Data) do
            if NovaUI.Flags[a] then
                spawn(function() 
                    if NovaUI.Flags[a].Type == "Colorpicker" then
                        NovaUI.Flags[a]:Set(UnpackColor(b))
                    else
                        NovaUI.Flags[a]:Set(b)
                    end    
                end)
            else
                warn("Nova UI Config Loader - Could not find flag: " .. tostring(a))
            end
        end
    end)
end

local function SaveCfg(Name)
    if not NovaUI.SaveCfg then return end
    
    pcall(function()
        local Data = {}
        for i,v in pairs(NovaUI.Flags) do
            if v.Save then
                if v.Type == "Colorpicker" then
                    Data[i] = PackColor(v.Value)
                else
                    Data[i] = v.Value
                end
            end    
        end
        
        if writefile and NovaUI.Folder then
            writefile(NovaUI.Folder .. "/" .. Name .. ".txt", HttpService:JSONEncode(Data))
        end
    end)
end

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3}
local BlacklistedKeys = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}

local function CheckKey(Table, Key)
    for _, v in next, Table do
        if v == Key then
            return true
        end
    end
end

CreateElement("Corner", function(Scale, Offset)
    local Corner = Create("UICorner", {
        CornerRadius = UDim.new(Scale or 0, Offset or 8)
    })
    return Corner
end)

CreateElement("Stroke", function(Color, Thickness, Transparency)
    local Stroke = Create("UIStroke", {
        Color = Color or NovaUI.Themes[NovaUI.SelectedTheme].Stroke,
        Thickness = Thickness or 1,
        Transparency = Transparency or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    return Stroke
end)

CreateElement("List", function(Scale, Offset)
    local List = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(Scale or 0, Offset or 5)
    })
    return List
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
    local Padding = Create("UIPadding", {
        PaddingBottom = UDim.new(0, Bottom or 8),
        PaddingLeft = UDim.new(0, Left or 8),
        PaddingRight = UDim.new(0, Right or 8),
        PaddingTop = UDim.new(0, Top or 8)
    })
    return Padding
end)

CreateElement("TFrame", function()
    local TFrame = Create("Frame", {
        BackgroundTransparency = 1
    })
    return TFrame
end)

CreateElement("Frame", function(Color, Transparency)
    local Frame = Create("Frame", {
        BackgroundColor3 = Color or NovaUI.Themes[NovaUI.SelectedTheme].Main,
        BackgroundTransparency = Transparency or 0.3,
        BorderSizePixel = 0
    })
    return Frame
end)

CreateElement("RoundFrame", function(Color, Scale, Offset, Transparency)
    local Frame = Create("Frame", {
        BackgroundColor3 = Color or NovaUI.Themes[NovaUI.SelectedTheme].Second,
        BackgroundTransparency = Transparency or 0.3,
        BorderSizePixel = 0
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(Scale, Offset)
        })
    })
    return Frame
end)

CreateElement("Button", function()
    local Button = Create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })
    return Button
end)

CreateElement("ScrollFrame", function(Color, Width)
    local ScrollFrame = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        ScrollBarImageColor3 = Color or NovaUI.Themes[NovaUI.SelectedTheme].Accent,
        BorderSizePixel = 0,
        ScrollBarThickness = Width or 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarImageTransparency = 0.5
    })
    return ScrollFrame
end)

CreateElement("Image", function(ImageID, Transparency)
    local ImageNew = Create("ImageLabel", {
        Image = ImageID,
        BackgroundTransparency = 1,
        ImageTransparency = Transparency or 0
    })

    if GetIcon(ImageID) ~= nil then
        ImageNew.Image = GetIcon(ImageID)
    end    

    return ImageNew
end)

CreateElement("ImageButton", function(ImageID)
    local Image = Create("ImageButton", {
        Image = ImageID,
        BackgroundTransparency = 1
    })
    return Image
end)

CreateElement("Label", function(Text, TextSize, Transparency)
    local Label = Create("TextLabel", {
        Text = Text or "",
        TextColor3 = NovaUI.Themes[NovaUI.SelectedTheme].Text,
        TextTransparency = Transparency or 0,
        TextSize = TextSize or 14,
        Font = Enum.Font.Gotham,
        RichText = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    return Label
end)

local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
    SetProps(MakeElement("List"), {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 10)
    })
}), {
    Position = UDim2.new(1, -25, 1, -25),
    Size = UDim2.new(0, 300, 1, -25),
    AnchorPoint = Vector2.new(1, 1),
    Parent = Nova
})

function NovaUI:MakeNotification(NotificationConfig)
    spawn(function()
        NotificationConfig.Name = NotificationConfig.Name or "Notification"
        NotificationConfig.Content = NotificationConfig.Content or "Test"
        NotificationConfig.Image = NotificationConfig.Image or "rbxassetid://4384403532"
        NotificationConfig.Time = NotificationConfig.Time or 5

        local NotificationParent = SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = NotificationHolder
        })

        -- Create gradient background for notification
        local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(15, 15, 30), {
            Parent = NotificationParent, 
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(1, -55, 0, 0),
            BackgroundTransparency = 0.2,
            AutomaticSize = Enum.AutomaticSize.Y
        }), {
            MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent, 1.2, 0.7),
            MakeElement("Padding", 12, 12, 12, 12),
            SetProps(MakeElement("Image", NotificationConfig.Image), {
                Size = UDim2.new(0, 20, 0, 20),
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                Name = "Icon"
            }),
            SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
                Size = UDim2.new(1, -30, 0, 20),
                Position = UDim2.new(0, 30, 0, 0),
                Font = Enum.Font.GothamBold,
                Name = "Title"
            }),
            SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 25),
                Font = Enum.Font.GothamSemibold,
                Name = "Content",
                AutomaticSize = Enum.AutomaticSize.Y,
                TextColor3 = Color3.fromRGB(200, 200, 220),
                TextWrapped = true
            })
        })

        -- Add gradient to notification
        CreateGradient(NotificationFrame, {
            Color3.fromRGB(15, 15, 30),
            Color3.fromRGB(25, 15, 40)
        }, 90)

        TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()

        wait(NotificationConfig.Time - 0.88)
        TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
        TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.5}):Play()
        wait(0.3)
        TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
        TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
        TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
        wait(0.05)

        NotificationFrame:TweenPosition(UDim2.new(1, 20, 0, 0), 'In', 'Quint', 0.8, true)
        wait(1.35)
        NotificationFrame:Destroy()
    end)
end    

function NovaUI:Init()
    if NovaUI.SaveCfg then    
        pcall(function()
            if isfile and readfile and NovaUI.Folder then
                local configPath = NovaUI.Folder .. "/" .. game.GameId .. ".txt"
                if isfile(configPath) then
                    local configData = readfile(configPath)
                    LoadCfg(configData)
                    NovaUI:MakeNotification({
                        Name = "Configuration",
                        Content = "Auto-loaded configuration for game " .. game.GameId .. ".",
                        Time = 5
                    })
                end
            end
        end)        
    end    
end    

function NovaUI:MakeWindow(WindowConfig)
    local FirstTab = true
    local Minimized = false
    local Loaded = false
    local UIHidden = false

    WindowConfig = WindowConfig or {}
    WindowConfig.Name = WindowConfig.Name or "NovaLibrary"
    WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
    WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
    WindowConfig.HidePremium = WindowConfig.HidePremium or false
    if WindowConfig.IntroEnabled == nil then
        WindowConfig.IntroEnabled = true
    end
    WindowConfig.IntroText = WindowConfig.IntroText or "Nova Library by eye"
    WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
    WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
    WindowConfig.Icon = WindowConfig.Icon or "rbxassetid://8834748103"
    WindowConfig.IntroIcon = WindowConfig.IntroIcon or "rbxassetid://8834748103"
    WindowConfig.ToggleKey = WindowConfig.ToggleKey or Enum.KeyCode.RightShift
    NovaUI.Folder = WindowConfig.ConfigFolder
    NovaUI.SaveCfg = WindowConfig.SaveConfig

if WindowConfig.SaveConfig then
    pcall(function()
        if makefolder and not isfolder(WindowConfig.ConfigFolder) then
            makefolder(WindowConfig.ConfigFolder)
        end
    end)
end

    local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", NovaUI.Themes[NovaUI.SelectedTheme].Accent, 4), {
        Size = UDim2.new(1, 0, 1, -50)
    }), {
        MakeElement("List"),
        MakeElement("Padding", 8, 0, 0, 8)
    }), "Divider")

    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
    end)

    local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
            Position = UDim2.new(0, 9, 0, 6),
            Size = UDim2.new(0, 18, 0, 18),
            ImageColor3 = Color3.fromRGB(255, 105, 180) -- Pink close button
        }), "Text")
    })

    local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
            Position = UDim2.new(0, 9, 0, 6),
            Size = UDim2.new(0, 18, 0, 18),
            Name = "Ico",
            ImageColor3 = Color3.fromRGB(0, 200, 255) -- Blue minimize button
        }), "Text")
    })

    local DragPoint = SetProps(MakeElement("TFrame"), {
        Size = UDim2.new(1, 0, 0, 50)
    })

    local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(15, 15, 30), 0, 10), {
        Size = UDim2.new(0, 150, 1, -50),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundTransparency = 0.2
    }), {
        TabHolder,
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 50),
            Position = UDim2.new(0, 0, 1, -50)
        }), {
            AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0, 10, 0.5, 0)
            }), {
                SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=".. LocalPlayer.UserId .."&width=420&height=420&format=png"), {
                    Size = UDim2.new(1, 0, 1, 0)
                }),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {
                    Size = UDim2.new(1, 0, 1, 0),
                }), "Divider"),
                MakeElement("Corner", 1)
            }), "Divider"),
            AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, WindowConfig.HidePremium and 14 or 13), {
                Size = UDim2.new(1, -60, 0, 13),
                Position = WindowConfig.HidePremium and UDim2.new(0, 50, 0, 19) or UDim2.new(0, 50, 0, 12),
                Font = Enum.Font.GothamBold,
                ClipsDescendants = true
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", "", 12), {
                Size = UDim2.new(1, -60, 0, 12),
                Position = UDim2.new(0, 50, 1, -25),
                Visible = not WindowConfig.HidePremium
            }), "TextDark"),
            -- Version text with neon effect
            AddThemeObject(SetProps(MakeElement("Label", NovaUI.Version, 10), {
                Size = UDim2.new(0, 100, 0, 12),
                Position = UDim2.new(1, -110, 1, -15),
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTransparency = 0.7,
                TextColor3 = Color3.fromRGB(0, 200, 255) -- Neon blue version text
            }), "TextDark")
        }),
    }), "Second")

    -- Add gradient to the sidebar
    CreateGradient(WindowStuff, {
        Color3.fromRGB(15, 15, 30),
        Color3.fromRGB(25, 15, 40)
    }, 90)

    local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
        Size = UDim2.new(1, -30, 2, 0),
        Position = UDim2.new(0, 25, 0, -24),
        Font = Enum.Font.GothamBlack,
        TextSize = 20,
        TextColor3 = Color3.fromRGB(255, 105, 180) -- Pink title
    }), "Text")

    local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundTransparency = 0.8
    }), "Stroke")

    -- Main window with gradient background
    local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(10, 10, 20)), {
        Parent = Nova,
        Position = UDim2.new(0.5, -307, 0.5, -172),
        Size = UDim2.new(0, 615, 0, 344),
        ClipsDescendants = true,
        BackgroundTransparency = 0.1
    }), {
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 50),
            Name = "TopBar",
            BackgroundTransparency = 0.2
        }), {
            WindowName,
            WindowTopBarLine,
            AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 7), {
                Size = UDim2.new(0, 70, 0, 30),
                Position = UDim2.new(1, -90, 0, 10),
                BackgroundTransparency = 0.2
            }), {
                AddThemeObject(MakeElement("Stroke"), "Stroke"),
                AddThemeObject(SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(0, 1, 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    BackgroundTransparency = 0.8
                }), "Stroke"), 
                CloseBtn,
                MinimizeBtn
            }), "Second"), 
        }),
        DragPoint,
        WindowStuff
    }), "Main")

    -- Add gradient to main window
    CreateGradient(MainWindow, {
        Color3.fromRGB(10, 10, 20),
        Color3.fromRGB(20, 10, 30)
    }, 90)

    -- UI Toggle Key
    local ToggleKey = WindowConfig.ToggleKey
    local ToggleDebounce = false

    -- Toggle UI function
    local function ToggleUI()
        if ToggleDebounce then return end
        ToggleDebounce = true
        
        if UIHidden then
            MainWindow.Visible = true
            TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 615, 0, 344)
            }):Play()
            UIHidden = false
        else
            TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 0, 0, 0)
            }):Play()
            wait(0.3)
            MainWindow.Visible = false
            UIHidden = true
        end
        
        ToggleDebounce = false
    end

    -- Toggle UI with key
 AddConnection(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == ToggleKey then
        pcall(function()
            ToggleUI()
        end)
    end
end)

    -- Mobile toggle button with neon effect
    local MobileToggle = SetProps(MakeElement("ImageButton", "rbxassetid://3926305904"), {
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 10, 0.5, -20),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        ImageRectOffset = Vector2.new(964, 324),
        ImageRectSize = Vector2.new(36, 36),
        Visible = false,
        Parent = Nova,
        ImageColor3 = Color3.fromRGB(0, 200, 255) -- Neon blue
    })

    -- Show mobile toggle on mobile
    if UserInputService.TouchEnabled then
        MobileToggle.Visible = true
        AddConnection(MobileToggle.Activated, function()
            ToggleUI()
        end)
    end

    if WindowConfig.ShowIcon then
        WindowName.Position = UDim2.new(0, 50, 0, -24)
        local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 25, 0, 15),
            ImageColor3 = Color3.fromRGB(255, 105, 180) -- Pink icon
        })
        WindowIcon.Parent = MainWindow.TopBar
    end    

    AddDraggingFunctionality(DragPoint, MainWindow)

    AddConnection(CloseBtn.MouseButton1Up, function()
        ToggleUI()
        NovaUI:MakeNotification({
            Name = "Interface Hidden",
            Content = "Tap " .. tostring(ToggleKey) .. " to reopen the interface",
            Time = 5
        })
        WindowConfig.CloseCallback()
    end)

    AddConnection(MinimizeBtn.MouseButton1Up, function()
        if Minimized then
            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 615, 0, 344)
            }):Play()
            MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
            wait(.02)
            MainWindow.ClipsDescendants = false
            WindowStuff.Visible = true
            WindowTopBarLine.Visible = true
        else
            MainWindow.ClipsDescendants = true
            WindowTopBarLine.Visible = false
            MinimizeBtn.Ico.Image = "rbxassetid://7072720870"

            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)
            }):Play()
            wait(0.1)
            WindowStuff.Visible = false    
        end
        Minimized = not Minimized    
    end)

    local function LoadSequence()
        MainWindow.Visible = false
        local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
            Parent = Nova,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.4, 0),
            Size = UDim2.new(0, 28, 0, 28),
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 1
        })

        local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 14), {
            Parent = Nova,
            Size = UDim2.new(1, 0, 1, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 19, 0.5, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.GothamBold,
            TextTransparency = 1,
            TextColor3 = Color3.fromRGB(255, 105, 180) -- Pink intro text
        })

        TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageTransparency = 0, 
            Position = UDim2.new(0.5, 0, 0.5, 0),
            ImageColor3 = Color3.fromRGB(0, 200, 255) -- Neon blue logo
        }):Play()
        wait(0.8)
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)
        }):Play()
        wait(0.3)
        TweenService:Create(LoadSequenceText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0
        }):Play()
        wait(2)
        TweenService:Create(LoadSequenceText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1
        }):Play()
        MainWindow.Visible = true
        LoadSequenceLogo:Destroy()
        LoadSequenceText:Destroy()
    end 

    if WindowConfig.IntroEnabled then
        LoadSequence()
    end    

    local TabFunction = {}
    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "Tab"
        TabConfig.Icon = TabConfig.Icon or ""
        TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

        local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
            Size = UDim2.new(1, 0, 0, 30),
            Parent = TabHolder,
            BackgroundTransparency = 0.8
        }), {
            AddThemeObject(SetProps(MakeElement("Image", TabConfig.Icon), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 10, 0.5, 0),
                ImageTransparency = 0.4,
                Name = "Ico",
                ImageColor3 = Color3.fromRGB(0, 200, 255) -- Neon blue icon
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
                Size = UDim2.new(1, -35, 1, 0),
                Position = UDim2.new(0, 35, 0, 0),
                Font = Enum.Font.GothamSemibold,
                TextTransparency = 0.4,
                Name = "Title"
            }), "Text")
        })

        if GetIcon(TabConfig.Icon) ~= nil then
            TabFrame.Ico.Image = GetIcon(TabConfig.Icon)
        end    

        local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", NovaUI.Themes[NovaUI.SelectedTheme].Accent, 5), {
            Size = UDim2.new(1, -150, 1, -50),
            Position = UDim2.new(0, 150, 0, 50),
            Parent = MainWindow,
            Visible = false,
            Name = "ItemContainer",
            BackgroundTransparency = 0.2
        }), {
            MakeElement("List", 0, 6),
            MakeElement("Padding", 15, 10, 10, 15)
        }), "Divider")

        -- Add gradient to content area
        CreateGradient(Container, {
            Color3.fromRGB(15, 15, 30),
            Color3.fromRGB(20, 15, 35)
        }, 90)

        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
        end)

        if FirstTab then
            FirstTab = false
            TabFrame.Ico.ImageTransparency = 0
            TabFrame.Title.TextTransparency = 0
            TabFrame.Title.Font = Enum.Font.GothamBlack
            TabFrame.Title.TextColor3 = Color3.fromRGB(255, 105, 180) -- Pink selected tab
            Container.Visible = true
        end    

        AddConnection(TabFrame.MouseButton1Click, function()
            for _, Tab in next, TabHolder:GetChildren() do
                if Tab:IsA("TextButton") then
                    Tab.Title.Font = Enum.Font.GothamSemibold
                    Tab.Title.TextColor3 = NovaUI.Themes[NovaUI.SelectedTheme].Text
                    TweenService:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.4,
                    }):Play()
                    TweenService:Create(Tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.4
                    }):Play()
                end    
            end
            for _, ItemContainer in next, MainWindow:GetChildren() do
                if ItemContainer.Name == "ItemContainer" then
                    ItemContainer.Visible = false
                end    
            end  
            TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                ImageTransparency = 0
            }):Play()
            TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                TextTransparency = 0
            }):Play()
            TabFrame.Title.Font = Enum.Font.GothamBlack
            TabFrame.Title.TextColor3 = Color3.fromRGB(255, 105, 180) -- Pink selected tab
            Container.Visible = true   
        end)

        local function GetElements(ItemParent)
            local ElementFunction = {}
            function ElementFunction:AddLabel(Text)
                local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.5,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke")
                }), "Second")

                -- Add subtle gradient to label
                CreateGradient(LabelFrame, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                local LabelFunction = {}
                function LabelFunction:Set(ToChange)
                    LabelFrame.Content.Text = ToChange
                end
                return LabelFunction
            end
            function ElementFunction:AddParagraph(Text, Content)
                Text = Text or "Text"
                Content = Content or "Content"

                local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.5,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 12, 0, 10),
                        Font = Enum.Font.GothamBold,
                        Name = "Title"
                    }), "Text"),
                    AddThemeObject(SetProps(MakeElement("Label", "", 13), {
                        Size = UDim2.new(1, -24, 0, 0),
                        Position = UDim2.new(0, 12, 0, 26),
                        Font = Enum.Font.GothamSemibold,
                        Name = "Content",
                        TextWrapped = true
                    }), "TextDark"),
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke")
                }), "Second")

                -- Add gradient to paragraph
                CreateGradient(ParagraphFrame, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
                    ParagraphFrame.Content.Size = UDim2.new(1, -24, 0, ParagraphFrame.Content.TextBounds.Y)
                    ParagraphFrame.Size = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 35)
                end)

                ParagraphFrame.Content.Text = Content

                local ParagraphFunction = {}
                function ParagraphFunction:Set(ToChange)
                    ParagraphFrame.Content.Text = ToChange
                end
                return ParagraphFunction
            end    
            function ElementFunction:AddButton(ButtonConfig)
                ButtonConfig = ButtonConfig or {}
                ButtonConfig.Name = ButtonConfig.Name or "Button"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end
                ButtonConfig.Icon = ButtonConfig.Icon or "rbxassetid://3944703587"

                local Button = {}

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0)
                })

                local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 33),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.5
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(SetProps(MakeElement("Image", ButtonConfig.Icon), {
                        Size = UDim2.new(0, 20, 0, 20),
                        Position = UDim2.new(1, -30, 0, 7),
                        ImageColor3 = Color3.fromRGB(0, 200, 255) -- Neon blue icon
                    }), "TextDark"),
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke"),
                    Click
                }), "Second")

                -- Add gradient to button
                CreateGradient(ButtonFrame, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(30, 30, 50)
                    }):Play()
                end)

                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(20, 20, 40)
                    }):Play()
                end)

                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(25, 25, 45)
                    }):Play()
                    spawn(function()
                        ButtonConfig.Callback()
                    end)
                end)

                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(15, 15, 35)
                    }):Play()
                end)

                function Button:Set(ButtonText)
                    ButtonFrame.Content.Text = ButtonText
                end    

                return Button
            end    
            function ElementFunction:AddToggle(ToggleConfig)
                ToggleConfig = ToggleConfig or {}
                ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Callback = ToggleConfig.Callback or function() end
                ToggleConfig.Color = ToggleConfig.Color or NovaUI.Themes[NovaUI.SelectedTheme].Accent
                ToggleConfig.Flag = ToggleConfig.Flag or nil
                ToggleConfig.Save = ToggleConfig.Save or false
                ToggleConfig.Draggable = ToggleConfig.Draggable or false

                local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save}

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0)
                })

                -- Square toggle design with neon effect
                local ToggleBox = SetChildren(SetProps(MakeElement("Frame", ToggleConfig.Color), {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -24, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 0.3
                }), {
                    SetProps(MakeElement("Stroke"), {
                        Color = ToggleConfig.Color,
                        Name = "Stroke",
                        Transparency = 0.5
                    }),
                    SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
                        Size = UDim2.new(0, 20, 0, 20),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        Name = "Ico"
                    }),
                })

                local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.5
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke"),
                    ToggleBox,
                    Click
                }), "Second")

                -- Add gradient to toggle frame
                CreateGradient(ToggleFrame, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                -- Make toggle draggable if enabled
                if ToggleConfig.Draggable then
                    AddDraggingFunctionality(ToggleBox, ToggleFrame)
                end

                function Toggle:Set(Value)
                    Toggle.Value = Value
                    TweenService:Create(ToggleBox, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Toggle.Value and ToggleConfig.Color or Color3.fromRGB(60, 60, 80),
                        BackgroundTransparency = Toggle.Value and 0.3 or 0.7
                    }):Play()
                    TweenService:Create(ToggleBox.Stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Color = Toggle.Value and ToggleConfig.Color or Color3.fromRGB(100, 100, 120)
                    }):Play()
                    TweenService:Create(ToggleBox.Ico, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        ImageTransparency = Toggle.Value and 0 or 1,
                        Size = Toggle.Value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8)
                    }):Play()
                    ToggleConfig.Callback(Toggle.Value)
                end    

                Toggle:Set(Toggle.Value)

                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(30, 30, 50)
                    }):Play()
                end)

                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(20, 20, 40)
                    }):Play()
                end)

                AddConnection(Click.MouseButton1Up, function()
                    Toggle:Set(not Toggle.Value)
                    SaveCfg(game.GameId)
                end)

                if ToggleConfig.Flag then
                    NovaUI.Flags[ToggleConfig.Flag] = Toggle
                end    
                return Toggle
            end  
            function ElementFunction:AddSlider(SliderConfig)
                SliderConfig = SliderConfig or {}
                SliderConfig.Name = SliderConfig.Name or "Slider"
                SliderConfig.Min = SliderConfig.Min or 0
                SliderConfig.Max = SliderConfig.Max or 100
                SliderConfig.Increment = SliderConfig.Increment or 1
                SliderConfig.Default = SliderConfig.Default or 50
                SliderConfig.Callback = SliderConfig.Callback or function() end
                SliderConfig.ValueName = SliderConfig.ValueName or ""
                SliderConfig.Color = SliderConfig.Color or NovaUI.Themes[NovaUI.SelectedTheme].Accent
                SliderConfig.Flag = SliderConfig.Flag or nil
                SliderConfig.Save = SliderConfig.Save or false

                local Slider = {Value = SliderConfig.Default, Save = SliderConfig.Save}
                local Dragging = false

                local SliderDrag = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundTransparency = 0.3,
                    ClipsDescendants = true
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 12, 0, 6),
                        Font = Enum.Font.GothamBold,
                        Name = "Value",
                        TextTransparency = 0
                    }), "Text")
                })

                -- Add gradient to slider drag
                CreateGradient(SliderDrag, {
                    SliderConfig.Color,
                    Color3.fromRGB(math.min(SliderConfig.Color.R * 255 + 30, 255), 
                    math.min(SliderConfig.Color.G * 255 + 30, 255), 
                    math.min(SliderConfig.Color.B * 255 + 30, 255))
                }, 90)

                local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
                    Size = UDim2.new(1, -24, 0, 26),
                    Position = UDim2.new(0, 12, 0, 30),
                    BackgroundTransparency = 0.8
                }), {
                    SetProps(MakeElement("Stroke"), {
                        Color = SliderConfig.Color
                    }),
                    AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 12, 0, 6),
                        Font = Enum.Font.GothamBold,
                        Name = "Value",
                        TextTransparency = 0.8
                    }), "Text"),
                    SliderDrag
                })

                local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 4), {
                    Size = UDim2.new(1, 0, 0, 65),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.5
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 15), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 12, 0, 10),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke"),
                    SliderBar
                }), "Second")

                -- Add gradient to slider frame
                CreateGradient(SliderFrame, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                SliderBar.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
                        Dragging = true 
                    end 
                end)
                SliderBar.InputEnded:Connect(function(Input) 
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
                        Dragging = false 
                    end 
                end)

                UserInputService.InputChanged:Connect(function(Input)
                    if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                        local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                        Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale)) 
                        SaveCfg(game.GameId)
                    end
                end)

                function Slider:Set(Value)
                    self.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                    TweenService:Create(SliderDrag, TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                        Size = UDim2.fromScale((self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1)
                    }):Play()
                    SliderBar.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
                    SliderDrag.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
                    SliderConfig.Callback(self.Value)
                end      

                Slider:Set(Slider.Value)
                if SliderConfig.Flag then                
                    NovaUI.Flags[SliderConfig.Flag] = Slider
                end
                return Slider
            end  
            function ElementFunction:AddDropdown(DropdownConfig)
                DropdownConfig = DropdownConfig or {}
                DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
                DropdownConfig.Options = DropdownConfig.Options or {}
                DropdownConfig.Default = DropdownConfig.Default or ""
                DropdownConfig.Callback = DropdownConfig.Callback or function() end
                DropdownConfig.Flag = DropdownConfig.Flag or nil
                DropdownConfig.Save = DropdownConfig.Save or false

                local Dropdown = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = DropdownConfig.Save}
                local MaxElements = 5

                if not table.find(Dropdown.Options, Dropdown.Value) then
                    Dropdown.Value = "..."
                end

                local DropdownList = MakeElement("List")

                local DropdownContainer = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(30, 30, 50), 4), {
                    DropdownList
                }), {
                    Parent = ItemParent,
                    Position = UDim2.new(0, 0, 0, 38),
                    Size = UDim2.new(1, 0, 1, -38),
                    ClipsDescendants = true,
                    BackgroundTransparency = 0.7
                }), "Divider")

                -- Add gradient to dropdown container
                CreateGradient(DropdownContainer, {
                    Color3.fromRGB(25, 25, 45),
                    Color3.fromRGB(30, 25, 50)
                }, 90)

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0)
                })

                local DropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ItemParent,
                    ClipsDescendants = true,
                    BackgroundTransparency = 0.5
                }), {
                    DropdownContainer,
                    SetProps(SetChildren(MakeElement("TFrame"), {
                        AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 15), {
                            Size = UDim2.new(1, -12, 1, 0),
                            Position = UDim2.new(0, 12, 0, 0),
                            Font = Enum.Font.GothamBold,
                            Name = "Content"
                        }), "Text"),
                        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {
                            Size = UDim2.new(0, 20, 0, 20),
                            AnchorPoint = Vector2.new(0, 0.5),
                            Position = UDim2.new(1, -30, 0.5, 0),
                            ImageColor3 = Color3.fromRGB(0, 200, 255), -- Neon blue icon
                            Name = "Ico"
                        }), "TextDark"),
                        AddThemeObject(SetProps(MakeElement("Label", "Selected", 13), {
                            Size = UDim2.new(1, -40, 1, 0),
                            Font = Enum.Font.Gotham,
                            Name = "Selected",
                            TextXAlignment = Enum.TextXAlignment.Right
                        }), "TextDark"),
                        AddThemeObject(SetProps(MakeElement("Frame"), {
                            Size = UDim2.new(1, 0, 0, 1),
                            Position = UDim2.new(0, 0, 1, -1),
                            Name = "Line",
                            Visible = false
                        }), "Stroke"), 
                        Click
                    }), {
                        Size = UDim2.new(1, 0, 0, 38),
                        ClipsDescendants = true,
                        Name = "F"
                    }),
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke"),
                    MakeElement("Corner")
                }), "Second")

                -- Add gradient to dropdown frame
                CreateGradient(DropdownFrame, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                    DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
                end)  

                local function AddOptions(Options)
                    for _, Option in pairs(Options) do
                        local OptionBtn = AddThemeObject(SetProps(SetChildren(MakeElement("Button", Color3.fromRGB(30, 30, 50)), {
                            MakeElement("Corner", 0, 6),
                            AddThemeObject(SetProps(MakeElement("Label", Option, 13, 0.4), {
                                Position = UDim2.new(0, 8, 0, 0),
                                Size = UDim2.new(1, -8, 1, 0),
                                Name = "Title"
                            }), "Text")
                        }), {
                            Parent = DropdownContainer,
                            Size = UDim2.new(1, 0, 0, 28),
                            BackgroundTransparency = 0.7,
                            ClipsDescendants = true
                        }), "Divider")

                        -- Add gradient to option buttons
                        CreateGradient(OptionBtn, {
                            Color3.fromRGB(30, 30, 50),
                            Color3.fromRGB(35, 30, 55)
                        }, 90)

                        AddConnection(OptionBtn.MouseButton1Click, function()
                            Dropdown:Set(Option)
                            SaveCfg(game.GameId)
                        end)

                        AddConnection(OptionBtn.MouseEnter, function()
                            TweenService:Create(OptionBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                                BackgroundTransparency = 0.5
                            }):Play()
                        end)

                        AddConnection(OptionBtn.MouseLeave, function()
                            TweenService:Create(OptionBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                                BackgroundTransparency = 0.7
                            }):Play()
                        end)

                        Dropdown.Buttons[Option] = OptionBtn
                    end
                end    

                function Dropdown:Refresh(Options, Delete)
                    if Delete then
                        for _,v in pairs(Dropdown.Buttons) do
                            v:Destroy()
                        end    
                        table.clear(Dropdown.Options)
                        table.clear(Dropdown.Buttons)
                    end
                    Dropdown.Options = Options
                    AddOptions(Dropdown.Options)
                end  

                function Dropdown:Set(Value)
                    if not table.find(Dropdown.Options, Value) then
                        Dropdown.Value = "..."
                        DropdownFrame.F.Selected.Text = Dropdown.Value
                        for _, v in pairs(Dropdown.Buttons) do
                            TweenService:Create(v, TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                                BackgroundTransparency = 0.7
                            }):Play()
                            TweenService:Create(v.Title, TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                                TextTransparency = 0.4
                            }):Play()
                        end    
                        return
                    end

                    Dropdown.Value = Value
                    DropdownFrame.F.Selected.Text = Dropdown.Value

                    for _, v in pairs(Dropdown.Buttons) do
                        TweenService:Create(v, TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                            BackgroundTransparency = 0.7
                        }):Play()
                        TweenService:Create(v.Title, TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                            TextTransparency = 0.4
                        }):Play()
                    end    
                    TweenService:Create(Dropdown.Buttons[Value], TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                        BackgroundTransparency = 0.3
                    }):Play()
                    TweenService:Create(Dropdown.Buttons[Value].Title, TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                        TextTransparency = 0
                    }):Play()
                    return DropdownConfig.Callback(Dropdown.Value)
                end

                AddConnection(Click.MouseButton1Click, function()
                    Dropdown.Toggled = not Dropdown.Toggled
                    DropdownFrame.F.Line.Visible = Dropdown.Toggled
                    TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                        Rotation = Dropdown.Toggled and 180 or 0
                    }):Play()
                    if #Dropdown.Options > MaxElements then
                        TweenService:Create(DropdownFrame, TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                            Size = Dropdown.Toggled and UDim2.new(1, 0, 0, 38 + (MaxElements * 28)) or UDim2.new(1, 0, 0, 38)
                        }):Play()
                    else
                        TweenService:Create(DropdownFrame, TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                            Size = Dropdown.Toggled and UDim2.new(1, 0, 0, DropdownList.AbsoluteContentSize.Y + 38) or UDim2.new(1, 0, 0, 38)
                        }):Play()
                    end
                end)

                Dropdown:Refresh(Dropdown.Options, false)
                Dropdown:Set(Dropdown.Value)
                if DropdownConfig.Flag then                
                    NovaUI.Flags[DropdownConfig.Flag] = Dropdown
                end
                return Dropdown
            end
            function ElementFunction:AddBind(BindConfig)
                BindConfig = BindConfig or {}
                BindConfig.Name = BindConfig.Name or "Bind"
                BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
                BindConfig.Hold = BindConfig.Hold or false
                BindConfig.Callback = BindConfig.Callback or function() end
                BindConfig.Flag = BindConfig.Flag or nil
                BindConfig.Save = BindConfig.Save or false

                local Bind = {Value, Binding = false, Type = "Bind", Save = BindConfig.Save}
                local Holding = false

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0)
                })

                local BindBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 4), {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 0.7
                }), {
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke"),
                    AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 14), {
                        Size = UDim2.new(1, 0, 1, 0),
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        Name = "Value"
                    }), "Text")
                })

                -- Add gradient to bind box
                CreateGradient(BindBox, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                local BindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.5
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke"),
                    BindBox,
                    Click
                }), "Second")

                -- Add gradient to bind frame
                CreateGradient(BindFrame, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
                    TweenService:Create(BindBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        Size = UDim2.new(0, BindBox.Value.TextBounds.X + 16, 0, 24)
                    }):Play()
                end)

                AddConnection(Click.InputEnded, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if Bind.Binding then return end
                        Bind.Binding = true
                        BindBox.Value.Text = "..."
                    end
                end)

                AddConnection(UserInputService.InputBegan, function(Input)
                    if UserInputService:GetFocusedTextBox() then return end
                    if (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) and not Bind.Binding then
                        if BindConfig.Hold then
                            Holding = true
                            BindConfig.Callback(Holding)
                        else
                            BindConfig.Callback()
                        end
                    elseif Bind.Binding then
                        local Key
                        pcall(function()
                            if not CheckKey(BlacklistedKeys, Input.KeyCode) then
                                Key = Input.KeyCode
                            end
                        end)
                        pcall(function()
                            if CheckKey(WhitelistedMouse, Input.UserInputType) and not Key then
                                Key = Input.UserInputType
                            end
                        end)
                        Key = Key or Bind.Value
                        Bind:Set(Key)
                        SaveCfg(game.GameId)
                    end
                end)

                AddConnection(UserInputService.InputEnded, function(Input)
                    if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
                        if BindConfig.Hold and Holding then
                            Holding = false
                            BindConfig.Callback(Holding)
                        end
                    end
                end)

                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(BindFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(30, 30, 50)
                    }):Play()
                end)

                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(BindFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(20, 20, 40)
                    }):Play()
                end)

                function Bind:Set(Key)
                    Bind.Binding = false
                    Bind.Value = Key or Bind.Value
                    Bind.Value = Bind.Value.Name or Bind.Value
                    BindBox.Value.Text = Bind.Value
                end

                Bind:Set(BindConfig.Default)
                if BindConfig.Flag then                
                    NovaUI.Flags[BindConfig.Flag] = Bind
                end
                return Bind
            end  
            function ElementFunction:AddTextbox(TextboxConfig)
                TextboxConfig = TextboxConfig or {}
                TextboxConfig.Name = TextboxConfig.Name or "Textbox"
                TextboxConfig.Default = TextboxConfig.Default or ""
                TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
                TextboxConfig.Callback = TextboxConfig.Callback or function() end

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0)
                })

                local TextboxActual = AddThemeObject(Create("TextBox", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    PlaceholderColor3 = Color3.fromRGB(210,210,210),
                    PlaceholderText = "Input",
                    Font = Enum.Font.GothamSemibold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextSize = 14,
                    ClearTextOnFocus = false
                }), "Text")

                local TextContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 4), {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 0.7
                }), {
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke"),
                    TextboxActual
                }), "Main")

                -- Add gradient to text container
                CreateGradient(TextContainer, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.5
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke"),
                    TextContainer,
                    Click
                }), "Second")

                -- Add gradient to textbox frame
                CreateGradient(TextboxFrame, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
                    TweenService:Create(TextContainer, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        Size = UDim2.new(0, TextboxActual.TextBounds.X + 16, 0, 24)
                    }):Play()
                end)

                AddConnection(TextboxActual.FocusLost, function()
                    TextboxConfig.Callback(TextboxActual.Text)
                    if TextboxConfig.TextDisappear then
                        TextboxActual.Text = ""
                    end    
                end)

                TextboxActual.Text = TextboxConfig.Default

                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(TextboxFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(30, 30, 50)
                    }):Play()
                end)

                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(TextboxFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(20, 20, 40)
                    }):Play()
                end)

                AddConnection(Click.MouseButton1Up, function()
                    TextboxActual:CaptureFocus()
                end)
            end 
            function ElementFunction:AddColorpicker(ColorpickerConfig)
                ColorpickerConfig = ColorpickerConfig or {}
                ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
                ColorpickerConfig.Default = ColorpickerConfig.Default or NovaUI.Themes[NovaUI.SelectedTheme].Accent
                ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
                ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
                ColorpickerConfig.Save = ColorpickerConfig.Save or false

                local ColorH, ColorS, ColorV = 1, 1, 1
                local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = ColorpickerConfig.Save}

                local ColorSelection = Create("ImageLabel", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
                    ScaleType = Enum.ScaleType.Fit,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=4805639000"
                })

                local HueSelection = Create("ImageLabel", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0.5, 0, 1 - select(1, Color3.toHSV(Colorpicker.Value))),
                    ScaleType = Enum.ScaleType.Fit,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = "http://www.roblox.com/asset/?id=4805639000"
                })

                local Color = Create("ImageLabel", {
                    Size = UDim2.new(1, -25, 1, 0),
                    Visible = false,
                    Image = "rbxassetid://4155801252"
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
                    ColorSelection
                })

                local Hue = Create("Frame", {
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -20, 0, 0),
                    Visible = false
                }, {
                    Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)), ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)), ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)), ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)), ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))},}),
                    Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
                    HueSelection
                })

                local ColorpickerContainer = Create("Frame", {
                    Position = UDim2.new(0, 0, 0, 32),
                    Size = UDim2.new(1, 0, 1, -32),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true
                }, {
                    Hue,
                    Color,
                    Create("UIPadding", {
                        PaddingLeft = UDim.new(0, 35),
                        PaddingRight = UDim.new(0, 35),
                        PaddingBottom = UDim.new(0, 10),
                        PaddingTop = UDim.new(0, 17)
                    })
                })

                local Click = SetProps(MakeElement("Button"), {
                    Size = UDim2.new(1, 0, 1, 0)
                })

                local ColorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", ColorpickerConfig.Default, 0, 4), {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 0.3
                }), {
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Main")

                -- Add gradient to color picker box
                CreateGradient(ColorpickerBox, {
                    ColorpickerConfig.Default,
                    Color3.fromRGB(math.min(ColorpickerConfig.Default.R * 255 + 30, 255), 
                    math.min(ColorpickerConfig.Default.G * 255 + 30, 255), 
                    math.min(ColorpickerConfig.Default.B * 255 + 30, 255))
                }, 90)

                local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 40), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ItemParent,
                    BackgroundTransparency = 0.5
                }), {
                    SetProps(SetChildren(MakeElement("TFrame"), {
                        AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 15), {
                            Size = UDim2.new(1, -12, 1, 0),
                            Position = UDim2.new(0, 12, 0, 0),
                            Font = Enum.Font.GothamBold,
                            Name = "Content"
                        }), "Text"),
                        ColorpickerBox,
                        Click,
                        AddThemeObject(SetProps(MakeElement("Frame"), {
                            Size = UDim2.new(1, 0, 0, 1),
                            Position = UDim2.new(0, 0, 1, -1),
                            Name = "Line",
                            Visible = false
                        }), "Stroke"), 
                    }), {
                        Size = UDim2.new(1, 0, 0, 38),
                        ClipsDescendants = true,
                        Name = "F"
                    }),
                    ColorpickerContainer,
                    AddThemeObject(MakeElement("Stroke", NovaUI.Themes[NovaUI.SelectedTheme].Accent), "Stroke"),
                }), "Second")

                -- Add gradient to color picker frame
                CreateGradient(ColorpickerFrame, {
                    Color3.fromRGB(20, 20, 40),
                    Color3.fromRGB(25, 20, 45)
                }, 90)

                AddConnection(Click.MouseButton1Click, function()
                    Colorpicker.Toggled = not Colorpicker.Toggled
                    TweenService:Create(ColorpickerFrame, TweenInfo.new(.15, Enum.EasingStyle.Quad), {
                        Size = Colorpicker.Toggled and UDim2.new(1, 0, 0, 148) or UDim2.new(1, 0, 0, 38)
                    }):Play()
                    Color.Visible = Colorpicker.Toggled
                    Hue.Visible = Colorpicker.Toggled
                    ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
                end)

                local function UpdateColorPicker()
                    ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                    Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
                    Colorpicker:Set(ColorpickerBox.BackgroundColor3)
                    ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3)
                    SaveCfg(game.GameId)
                end

                ColorH = 1 - (math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
                ColorS = (math.clamp(ColorSelection.AbsolutePosition.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
                ColorV = 1 - (math.clamp(ColorSelection.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)

                AddConnection(Color.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if ColorInput then
                            ColorInput:Disconnect()
                        end
                        ColorInput = AddConnection(RunService.RenderStepped, function()
                            local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
                            local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
                            ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
                            ColorS = ColorX
                            ColorV = 1 - ColorY
                            UpdateColorPicker()
                        end)
                    end
                end)

                AddConnection(Color.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if ColorInput then
                            ColorInput:Disconnect()
                        end
                    end
                end)

                AddConnection(Hue.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if HueInput then
                            HueInput:Disconnect()
                        end;

                        HueInput = AddConnection(RunService.RenderStepped, function()
                            local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

                            HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
                            ColorH = 1 - HueY

                            UpdateColorPicker()
                        end)
                    end
                end)

                AddConnection(Hue.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if HueInput then
                            HueInput:Disconnect()
                        end
                    end
                end)

                function Colorpicker:Set(Value)
                    Colorpicker.Value = Value
                    ColorpickerBox.BackgroundColor3 = Colorpicker.Value
                    ColorpickerConfig.Callback(Colorpicker.Value)
                end

                Colorpicker:Set(Colorpicker.Value)
                if ColorpickerConfig.Flag then                
                    NovaUI.Flags[ColorpickerConfig.Flag] = Colorpicker
                end
                return Colorpicker
            end  
            return ElementFunction   
        end    

        local ElementFunction = {}

        function ElementFunction:AddSection(SectionConfig)
            SectionConfig = SectionConfig or {}
            SectionConfig.Name = SectionConfig.Name or "Section"

            local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
                Size = UDim2.new(1, 0, 0, 26),
                Parent = Container
            }), {
                AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 14), {
                    Size = UDim2.new(1, -12, 0, 16),
                    Position = UDim2.new(0, 0, 0, 3),
                    Font = Enum.Font.GothamSemibold,
                    TextColor3 = Color3.fromRGB(0, 200, 255) -- Neon blue section title
                }), "TextDark"),
                SetChildren(SetProps(MakeElement("TFrame"), {
                    AnchorPoint = Vector2.new(0, 0),
                    Size = UDim2.new(1, 0, 1, -24),
                    Position = UDim2.new(0, 0, 0, 23),
                    Name = "Holder"
                }), {
                    MakeElement("List", 0, 6)
                }),
            })

            AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
                SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
            end)

            local SectionFunction = {}
            for i, v in next, GetElements(SectionFrame.Holder) do
                SectionFunction[i] = v 
            end
            return SectionFunction
        end    

        for i, v in next, GetElements(Container) do
            ElementFunction[i] = v 
        end

        if TabConfig.PremiumOnly then
            for i, v in next, ElementFunction do
                ElementFunction[i] = function() end
            end    
            Container:FindFirstChild("UIListLayout"):Destroy()
            Container:FindFirstChild("UIPadding"):Destroy()
            SetChildren(SetProps(MakeElement("TFrame"), {
                Size = UDim2.new(1, 0, 1, 0),
                Parent = ItemParent
            }), {
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://3610239960"), {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0, 15, 0, 15),
                    ImageTransparency = 0.4,
                    ImageColor3 = Color3.fromRGB(255, 105, 180) -- Pink icon
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "Unauthorised Access", 14), {
                    Size = UDim2.new(1, -38, 0, 14),
                    Position = UDim2.new(0, 38, 0, 18),
                    TextTransparency = 0.4
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4483345875"), {
                    Size = UDim2.new(0, 56, 0, 56),
                    Position = UDim2.new(0, 84, 0, 110),
                    ImageColor3 = Color3.fromRGB(0, 200, 255) -- Neon blue icon
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "Premium Features", 14), {
                    Size = UDim2.new(1, -150, 0, 14),
                    Position = UDim2.new(0, 150, 0, 112),
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Color3.fromRGB(255, 105, 180) -- Pink text
                }), "Text"),
                AddThemeObject(SetProps(MakeElement("Label", "This part of the script is locked to premium users.", 12), {
                    Size = UDim2.new(1, -200, 0, 14),
                    Position = UDim2.new(0, 150, 0, 138),
                    TextWrapped = true,
                    TextTransparency = 0.4
                }), "Text")
            })
        end
        return ElementFunction   
    end  
    
    return TabFunction
end   

function NovaUI:Destroy()
    Nova:Destroy()
end

return NovaUI
