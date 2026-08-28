-- ----------------------------------------------------------------------------
-- SECTION 1: Library Load
-- ----------------------------------------------------------------------------
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/Avenza/main/source.lua"))()

-- ----------------------------------------------------------------------------
-- SECTION 2: Window Creation
-- ----------------------------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "Avenza UI Example",
    Accent = Color3.fromRGB(20, 187, 217),
    Scale = 0.80,
    ToggleKey = Enum.KeyCode.RightShift,
})

-- ----------------------------------------------------------------------------
-- SECTION 3: Tab Creation
-- ----------------------------------------------------------------------------
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "gear",
})

local MiscTab = Window:CreateTab({
    Name = "Misc",
    Icon = "nine-dots-grid",
})

-- ----------------------------------------------------------------------------
-- SECTION 4: Main Tab Elements
-- ----------------------------------------------------------------------------

-- Label
MainTab:CreateLabel("This is a plain text label.")

-- Warning
MainTab:CreateWarning("Heads up! This is a warning message.")

-- Button
MainTab:CreateButton({
    Name = "Click Me",
    Tooltip = "Press to trigger the action",
    Callback = function()
        print("[Button] Clicked")
        Library:Notify({
            Title = "Button Action",
            Content = "You pressed the button!",
            Duration = 3,
        })
    end,
})

-- Toggle
local toggle = MainTab:CreateToggle({
    Name = "Enable Feature",
    Default = false,
    Tooltip = "Turns the feature on or off",
    FireOnInit = false,
    Callback = function(state)
        print("[Toggle] State:", state)
    end,
})

-- Stat
local stat = MainTab:CreateStat({
    Name = "Current Score",
    Value = 42,
    Tooltip = "Updates when the demo button is pressed",
})

-- Slider
local slider = MainTab:CreateSlider({
    Name = "Volume",
    Min = 0,
    Max = 100,
    Increment = 5,
    Default = 50,
    Suffix = "%",
    Live = false,
    Tooltip = "Drag or use ± buttons to adjust",
    Callback = function(value)
        print("[Slider] Value:", value)
    end,
})

-- Textbox
local textbox = MainTab:CreateTextbox({
    Name = "Username",
    Default = "Player",
    Placeholder = "Enter your name...",
    MinWidth = 80,
    MaxWidth = 180,
    Tooltip = "Your display name",
    Callback = function(text)
        print("[Textbox] Input:", text)
    end,
})

-- Color Picker
local colorPicker = MainTab:CreateColorPicker({
    Name = "Pick a Color",
    Default = Color3.fromRGB(255, 0, 0),
    Live = false,
    Tooltip = "Click to expand the HSV picker",
    Callback = function(color)
        print("[ColorPicker] Selected:", color)
    end,
})

-- Dropdown (Single-Select)
local dropdown = MainTab:CreateDropdown({
    Name = "Choose an Option",
    Options = { "Option A", "Option B", "Option C" },
    Default = "Option A",
    Multi = false,
    Tooltip = "Pick one from the list",
    Callback = function(selected)
        print("[Dropdown] Selected:", selected)
    end,
})

-- ----------------------------------------------------------------------------
-- SECTION 5: Misc Tab Elements
-- ----------------------------------------------------------------------------

-- Badge on Misc tab
MiscTab:SetBadge(true)

-- Multi-Select Dropdown
local multiDropdown = MiscTab:CreateDropdown({
    Name = "Multi-Select",
    Options = { "Apple", "Banana", "Cherry", "Date" },
    Default = { "Apple", "Cherry" },
    Multi = true,
    Tooltip = "Select as many as you like",
    Callback = function(selected)
        print("[MultiDropdown] Selected:", table.concat(selected, ", "))
    end,
})

-- Button to update stat
MiscTab:CreateButton({
    Name = "Update Stat (random)",
    Tooltip = "Picks a random score and updates the Main tab stat",
    Callback = function()
        local newValue = math.random(1, 100)
        stat:Set(newValue)
        Library:Notify({
            Title = "Stat Updated",
            Content = "New score: " .. tostring(newValue),
            Duration = 3,
        })
    end,
})

-- Button to toggle feature from Misc tab
MiscTab:CreateButton({
    Name = "Toggle Feature",
    Tooltip = "Toggles the Main tab toggle",
    Callback = function()
        toggle:Set(not toggle:Get())
    end,
})

-- Button to show notification
MiscTab:CreateButton({
    Name = "Show Notification",
    Tooltip = "Displays a custom notification",
    Callback = function()
        Library:Notify({
            Title = "Custom Notification",
            Content = "This is a notification with custom content!",
            Duration = 5,
        })
    end,
})

-- Button to reset slider
MiscTab:CreateButton({
    Name = "Reset Slider to 50",
    Tooltip = "Sets the slider back to 50",
    Callback = function()
        slider:Set(50)
    end,
})

-- Button to set random color
MiscTab:CreateButton({
    Name = "Random Color",
    Tooltip = "Sets a random color in the color picker",
    Callback = function()
        colorPicker:Set(Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
    end,
})

-- Button to change dropdown options
MiscTab:CreateButton({
    Name = "Change Dropdown Options",
    Tooltip = "Replaces dropdown options with new ones",
    Callback = function()
        dropdown:Refresh({ "New Option 1", "New Option 2", "New Option 3", "New Option 4" })
    end,
})

-- ----------------------------------------------------------------------------
-- SECTION 6: Startup Notification
-- ----------------------------------------------------------------------------
Library:Notify({
    Title = "UI Loaded",
    Content = "All features ready — check the Misc tab!",
    Duration = 4,
})

print("Example UI Loaded Successfully!")
