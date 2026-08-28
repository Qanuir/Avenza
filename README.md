# Avenza UI Library

A clean and modern **Roblox UI Library** for exploit environments, designed for both mobile and PC.  
It provides draggable windows, smooth animations, themes, and a full set of UI elements.

---

## Features
- 🖼️ Windows & Tabs
- 🔖 Labels & Warnings
- 🎛️ Buttons, Toggles, Sliders
- 📂 Dropdowns (single & multi‑select)
- 🎨 Color pickers
- 📝 Textboxes
- 📊 Stats
- 🔔 Notifications
- 💡 Tooltips
- 📱 Mobile‑friendly scaling
- 🧩 Badge system for tabs

---

## Installation

Load the library into your script:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/Avenza/main/source.lua"))()
```

---

## Creating Window

```lua
local Window = Library:CreateWindow({
    Title = "Avenza UI",
    Accent = Color3.fromRGB(20, 187, 217),
    Scale = 0.80,                        -- optional, scales the whole UI
    ToggleKey = Enum.KeyCode.RightShift  -- optional, default RightShift
})

--[[
Title     = <string>  - The name of the UI.
Accent    = <color3>  - Accent color used in the UI.
Scale     = <number>  - Overall scale factor (0.5 - 1.5 recommended).
ToggleKey = <keycode> - Key to toggle UI visibility.
]]
```

---

## Creating Tab

```lua
local Tab = Window:CreateTab({
    Name = "Main",
    Icon = "gear"   -- can be a BuilderIcons name or rbxassetid
})

--[[
Name = <string> - The name of the tab.
Icon = <string> - Icon identifier (BuilderIcons name or rbxassetid).
]]
```

---

## Creating Label

```lua
local Label = Tab:CreateLabel("This is a label")
```

Updating:

```lua
Label:Set("New label text")
```

---

## Creating Warning

```lua
local Warning = Tab:CreateWarning("Warning message")
```

Updating:

```lua
Warning:Set("New warning message")
```

---

## Creating Button

```lua
Tab:CreateButton({
    Name = "Click Me",
    Tooltip = "Optional tooltip text",
    Callback = function()
        print("Button pressed")
    end
})
```

---

## Creating Toggle

```lua
local Toggle = Tab:CreateToggle({
    Name = "Enable Feature",
    Default = false,
    Tooltip = "Optional tooltip",
    FireOnInit = false,   -- whether to call Callback when created
    Callback = function(state)
        print("Toggle state:", state)
    end
})
```

Changing value:

```lua
Toggle:Set(true)   -- will also trigger Callback
```

Getting value:

```lua
local current = Toggle:Get()
```

---

## Creating Stat

```lua
local Stat = Tab:CreateStat({
    Name = "Score",
    Value = 100,
    Tooltip = "Current score"
})
```

Updating:

```lua
Stat:Set(150)
```

---

## Creating Slider

```lua
local Slider = Tab:CreateSlider({
    Name = "Speed",
    Min = 0,
    Max = 100,
    Increment = 5,
    Default = 50,
    Suffix = "%",       -- optional
    Live = false,       -- if true, Callback fires while dragging
    Tooltip = "Adjust speed",
    Callback = function(value)
        print("Slider value:", value)
    end
})
```

Changing value:

```lua
Slider:Set(75)
```

Getting value:

```lua
local val = Slider:Get()
```

---

## Creating Textbox

```lua
local Textbox = Tab:CreateTextbox({
    Name = "Username",
    Default = "Player",
    Placeholder = "Enter name...",
    MinWidth = 80,
    MaxWidth = 180,
    Tooltip = "Your name",
    Callback = function(text)
        print("Textbox input:", text)
    end
})
```

Setting text:

```lua
Textbox:Set("NewName")
```

Getting text:

```lua
local text = Textbox:Get()
```

---

## Creating Color Picker

```lua
local ColorPicker = Tab:CreateColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(255, 0, 0),
    Live = false,     -- if true, Callback fires as you drag
    Tooltip = "Pick a color",
    Callback = function(color)
        print("Color selected:", color)
    end
})
```

Setting color:

```lua
ColorPicker:Set(Color3.fromRGB(0, 255, 0))
```

Getting color:

```lua
local currentColor = ColorPicker:Get()
```

---

## Creating Dropdown (Single‑Select)

```lua
local Dropdown = Tab:CreateDropdown({
    Name = "Mode",
    Options = {"Easy", "Normal", "Hard"},
    Default = "Normal",
    Multi = false,      -- optional, default false
    Tooltip = "Select difficulty",
    Callback = function(selected)
        print("Selected:", selected)
    end
})
```

Refreshing options:

```lua
Dropdown:Refresh({"Option 1", "Option 2", "Option 3"})
```

Setting value:

```lua
Dropdown:Set("Hard")
```

Getting selected value:

```lua
local selected = Dropdown:Get()   -- returns string for single‑select
```

---

## Creating Dropdown (Multi‑Select)

```lua
local MultiDropdown = Tab:CreateDropdown({
    Name = "Perks",
    Options = {"Speed", "Health", "Damage"},
    Default = {"Speed", "Health"},
    Multi = true,
    Tooltip = "Choose multiple perks",
    Callback = function(selectedList)
        print("Selected:", table.concat(selectedList, ", "))
    end
})
```

Getting selected values:

```lua
local selectedList = MultiDropdown:Get()   -- returns table
```

---

## Notifications

```lua
Library:Notify({
    Title = "Notification Title",
    Content = "This is the message body.",
    Duration = 4   -- seconds
})
```

---

## Badge on Tab

Show a small dot on a tab to draw attention:

```lua
Tab:SetBadge(true)   -- show badge
Tab:SetBadge(false)  -- hide badge
```

Badge automatically clears when the tab is clicked.

---

## Window Controls

Hide / show the entire UI (same as pressing ToggleKey):

```lua
Window.SetHidden(true)   -- hide
Window.SetHidden(false)  -- show
```

Check if hidden:

```lua
local isHidden = Window.IsHidden()
```

Destroy the UI completely:

```lua
Window:Destroy()
```

---

## Keyboard Shortcut (Optional)

Add custom shortcuts using UserInputService:

```lua
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then
        Window.SetHidden(not Window.IsHidden())
    end
end)
```

---
