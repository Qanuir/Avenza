-- ============================================================================
--  Library Load
-- ============================================================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/Avenza/main/source.lua"))()

-- ============================================================================
--  Main Window
-- ============================================================================
local Window = Library:CreateWindow({
    Title = "Avenza UI – Full Example",
    Accent = Color3.fromRGB(100, 160, 255)
})

-- ============================================================================
--  Tab: Main – All Basic Elements
-- ============================================================================
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "gear"
})

-- ----------------------------------------------------------------------------
-- 1. Simple Label
-- ----------------------------------------------------------------------------
MainTab:CreateLabel("This is a plain text label.")

-- ----------------------------------------------------------------------------
-- 2. Warning Box
-- ----------------------------------------------------------------------------
MainTab:CreateWarning("Heads up! This is a warning message.")

-- ----------------------------------------------------------------------------
-- 3. Interactive Button
-- ----------------------------------------------------------------------------
MainTab:CreateButton({
    Name = "Click Me",
    Callback = function()
        print("[Button] Clicked")
        Library:Notify({
            Title = "Button Action",
            Content = "You pressed the button!",
            Duration = 3
        })
    end
})

-- ----------------------------------------------------------------------------
-- 4. Toggle Switch
-- ----------------------------------------------------------------------------
local toggle = MainTab:CreateToggle({
    Name = "Enable Feature",
    Default = false,
    Callback = function(state)
        print("[Toggle] State:", state)
    end
})

-- ----------------------------------------------------------------------------
-- 5. Read‑Only Stat Display
-- ----------------------------------------------------------------------------
local stat = MainTab:CreateStat({
    Name = "Current Score",
    Value = 42
})

-- ----------------------------------------------------------------------------
-- 6. Slider with Increment
-- ----------------------------------------------------------------------------
local slider = MainTab:CreateSlider({
    Name = "Volume",
    Min = 0,
    Max = 100,
    Increment = 5,
    Default = 50,
    Callback = function(value)
        print("[Slider] Value:", value)
    end
})

-- ----------------------------------------------------------------------------
-- 7. Text Input Box
-- ----------------------------------------------------------------------------
local textbox = MainTab:CreateTextbox({
    Name = "Username",
    Default = "Player",
    Placeholder = "Enter your name...",
    Callback = function(text)
        print("[Textbox] Input:", text)
    end
})

-- ----------------------------------------------------------------------------
-- 8. Color Picker (HSV inline)
-- ----------------------------------------------------------------------------
local colorPicker = MainTab:CreateColorPicker({
    Name = "Pick a Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        print("[ColorPicker] Selected:", color)
    end
})

-- ----------------------------------------------------------------------------
-- 9. Single‑Select Dropdown
-- ----------------------------------------------------------------------------
local dropdown = MainTab:CreateDropdown({
    Name = "Choose an Option",
    Options = { "Option A", "Option B", "Option C" },
    Default = "Option A",
    Multi = false,
    Callback = function(selected)
        print("[Dropdown] Selected:", selected)
    end
})

-- ============================================================================
--  Tab: Misc – Extra Features (Multi‑Select & Demo)
-- ============================================================================
local MiscTab = Window:CreateTab({
    Name = "Misc",
    Icon = "nine-dots-grid"
})

-- ----------------------------------------------------------------------------
-- Multi‑Select Dropdown
-- ----------------------------------------------------------------------------
local multiDropdown = MiscTab:CreateDropdown({
    Name = "Multi-Select",
    Options = { "Apple", "Banana", "Cherry", "Date" },
    Default = { "Apple", "Cherry" },
    Multi = true,
    Callback = function(selected)
        print("[MultiDropdown] Selected:", table.concat(selected, ", "))
    end
})

-- ----------------------------------------------------------------------------
-- Demo Button – Updates the Stat from MainTab
-- ----------------------------------------------------------------------------
MiscTab:CreateButton({
    Name = "Update Stat (random)",
    Callback = function()
        local newValue = math.random(1, 100)
        stat:Set(newValue)
        Library:Notify({
            Title = "Stat Updated",
            Content = "New score: " .. tostring(newValue),
            Duration = 3
        })
    end
})

-- ============================================================================
--  Startup Notification
-- ============================================================================
Library:Notify({
    Title = "UI Loaded",
    Content = "All features are ready!",
    Duration = 4
})
