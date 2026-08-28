local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local setClipboard = setclipboard or toclipboard or writeclipboard or write_clipboard
	or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

----------------------------------------------------------------------
-- Singleton guard
----------------------------------------------------------------------
local ENV = (getgenv and getgenv()) or shared or _G
local REG_KEY = "__VaehzUI_Instance"

do
	local prev = ENV[REG_KEY]
	if type(prev) == "table" and prev.Destroy then
		pcall(function() prev:Destroy() end)
	end
	ENV[REG_KEY] = nil
end

----------------------------------------------------------------------
-- iOS Design System
----------------------------------------------------------------------
local Theme = {
	-- iOS System Backgrounds (layered depth)
	Background = Color3.fromRGB(0, 0, 0),           -- System background
	Secondary  = Color3.fromRGB(28, 28, 30),       -- Secondary system fill
	Tertiary   = Color3.fromRGB(44, 44, 46),         -- Tertiary system fill
	-- iOS System Materials
	Element    = Color3.fromRGB(120, 120, 128),      -- System gray
	ElementHover = Color3.fromRGB(174, 174, 178),    -- System gray 2
	-- iOS Semantic Colors
	Off        = Color3.fromRGB(120, 120, 128),      -- System gray (inactive)
	On         = Color3.fromRGB(255, 255, 255),      -- Pure white for active states
	-- Borders and dividers
	Stroke     = Color3.fromRGB(56, 56, 58),         -- Separator color
	StrokeLight = Color3.fromRGB(72, 72, 74),        -- Light separator
	-- Text hierarchy
	Text       = Color3.fromRGB(255, 255, 255),       -- Primary label
	SubText    = Color3.fromRGB(152, 152, 157),      -- Secondary label
	TertiaryText = Color3.fromRGB(118, 118, 124),    -- Tertiary label
	-- Accent and semantic
	Accent     = Color3.fromRGB(10, 132, 255),       -- iOS system blue
	AccentLight = Color3.fromRGB(48, 209, 88),       -- iOS system green
	Warning    = Color3.fromRGB(255, 159, 10),       -- iOS system orange
	Danger     = Color3.fromRGB(255, 69, 58),        -- iOS system red
}

-- iOS Material Transparencies
local MATERIAL_THICK = 0.72      -- Thick material (elevated surfaces)
local MATERIAL_REGULAR = 0.82    -- Regular material (cards, rows)
local MATERIAL_THIN = 0.88       -- Thin material (subtle backgrounds)
local CHIP_MATERIAL = 0.85       -- Chip/button backgrounds
local STROKE_T = 0.76            -- Border transparency
local DIVIDER_T = 0.86           -- Divider transparency

-- iOS Corner Radii (dynamic based on context)
local RADIUS_LARGE = 20          -- Window, sheets
local RADIUS_MED = 12            -- Cards, sections
local RADIUS_SMALL = 8           -- Buttons, inputs
local RADIUS_PILL = 1000         -- Toggle track, pills

-- iOS Typography (Roblox FontWeight enums)
local FONT_TITLE = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_HEADLINE = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FONT_BODY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular)
local FONT_BODY_MED = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

-- Legacy fallback for FontFace compatibility
local function safeFont(weight)
	local weights = {
		Regular = Enum.FontWeight.Regular,
		Medium = Enum.FontWeight.Medium,
		Bold = Enum.FontWeight.Bold,
	}
	return weights[weight] or Enum.FontWeight.Regular
end

-- Animation curves (iOS-style spring and ease)
local TI    = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_S  = TweenInfo.new(0.32, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TI_R  = TweenInfo.new(0.50, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_SPRING = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local BUILDER_ICONS = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"

----------------------------------------------------------------------
-- Connection tracking
----------------------------------------------------------------------
local Connections = {}

local function track(conn)
	table.insert(Connections, conn)
	return conn
end

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then inst[k] = v end
	end
	if children then
		for _, c in children do c.Parent = inst end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function corner(parent, r)
	return create("UICorner", { CornerRadius = UDim.new(0, r or RADIUS_SMALL), Parent = parent })
end

local function stroke(parent, color, trans, thick)
	return create("UIStroke", {
		Color = color or Theme.Stroke,
		Transparency = trans or 0.5,
		Thickness = thick or 0.5,
		Parent = parent,
	})
end

local function divider(parent, vertical)
	return create("Frame", {
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = DIVIDER_T,
		BorderSizePixel = 0,
		Size = vertical and UDim2.new(0, 0.5, 1, 0) or UDim2.new(1, 0, 0, 0.5),
		Parent = parent,
	})
end

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info or TI, props)
	t:Play()
	return t
end

local function ripple(host, color)
	if host.ClipsDescendants == false then host.ClipsDescendants = true end
	local d = math.max(host.AbsoluteSize.X, host.AbsoluteSize.Y) * 2.2
	local r = create("Frame", {
		BackgroundColor3 = color or Theme.Text,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 0),
		ZIndex = host.ZIndex + 5,
		Parent = host,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = r })
	tween(r, TI_R, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 })
	task.delay(0.5, function() if r.Parent then r:Destroy() end end)
end

local function icon(name, size, filled, color)
	if type(name) == "string" and (name:match("^rbxassetid://") or name:match("^%d+$")) then
		return create("ImageLabel", {
			BackgroundTransparency = 1,
			Image = name:match("^%d+$") and ("rbxassetid://" .. name) or name,
			ImageColor3 = color or Theme.Text,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(size or 18, size or 18),
		})
	end
	-- Use Font.fromEnum for maximum compatibility
	local fallbackFont = filled and Enum.Font.GothamBold or Enum.Font.GothamMedium
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Text = name or "",
		FontFace = Font.fromEnum(fallbackFont),
		TextColor3 = color or Theme.Text,
		TextScaled = true,
		Size = UDim2.fromOffset(size or 18, size or 18),
	})
end

local function tintIcon(ic, color)
	if ic:IsA("ImageLabel") or ic:IsA("ImageButton") then
		return tween(ic, TI, { ImageColor3 = color })
	end
	return tween(ic, TI, { TextColor3 = color })
end

local function makeDraggable(frame, handle)
	local dragging, dragInput, startPos, startFramePos
	track(handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = inp.Position
			startFramePos = frame.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end))
	track(handle.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			dragInput = inp
		end
	end))
	track(UserInputService.InputChanged:Connect(function(inp)
		if inp == dragInput and dragging then
			local delta = inp.Position - startPos
			frame.Position = UDim2.new(
				startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
				startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
			)
		end
	end))
end

local function bindDrag(region, onUpdate)
	local dragging = false
	local function upd(inp, ended)
		local ap, sz = region.AbsolutePosition, region.AbsoluteSize
		local ax = math.clamp((inp.Position.X - ap.X) / sz.X, 0, 1)
		local ay = math.clamp((inp.Position.Y - ap.Y) / sz.Y, 0, 1)
		onUpdate(ax, ay, ended == true)
	end
	track(region.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; upd(inp, false)
		end
	end))
	track(region.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			if dragging then upd(inp, true) end
			dragging = false
		end
	end))
	track(UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			upd(inp, false)
		end
	end))
end

local function getGuiParent()
	if gethui then return gethui() end
	local ok, cg = pcall(function()
		return (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
	end)
	return ok and cg or game:GetService("CoreGui")
end

local function copyToClipboard(str)
	if not setClipboard then return false end
	return pcall(setClipboard, str)
end

local function openDiscordInvite(code)
	if not httpRequest then return false end
	return pcall(function()
		httpRequest({
			Url = "http://127.0.0.1:6463/rpc?v=1",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
			Body = HttpService:JSONEncode({
				cmd = "INVITE_BROWSER",
				nonce = HttpService:GenerateGUID(false),
				args = { code = code },
			}),
		})
	end)
end

----------------------------------------------------------------------
-- Library root
----------------------------------------------------------------------
local Library = {}
Library.__index = Library
Library._destroyed = false
Library._scale = 1
Library._cleanups = {}

local GuiParent = getGuiParent()
do
	local stale = GuiParent:FindFirstChild("VaehzUI")
	if stale then pcall(function() stale:Destroy() end) end
end

local ScreenGui = create("ScreenGui", {
	Name = "AvenzaUI",
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
})
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
ScreenGui.Parent = GuiParent

function Library:Destroy()
	if Library._destroyed then return end
	Library._destroyed = true
	for _, conn in Connections do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(Connections)
	for _, fn in Library._cleanups do
		pcall(fn)
	end
	table.clear(Library._cleanups)
	pcall(function() ScreenGui:Destroy() end)
	if ENV[REG_KEY] == Library then
		ENV[REG_KEY] = nil
	end
end

ENV[REG_KEY] = Library

-- iOS-style notification stack (bottom-right with padding)
local NotifHolder = create("Frame", {
	Name = "Notifications",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -20),
	Size = UDim2.new(0, 300, 1, -40),
	Parent = ScreenGui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

----------------------------------------------------------------------
-- Tooltip manager (iOS-style subtle tooltip)
----------------------------------------------------------------------
local Tooltip = {}
do
	local tip = create("Frame", {
		Name = "Tooltip",
		BackgroundColor3 = Color3.fromRGB(44, 44, 46),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = false,
		ZIndex = 50,
		Parent = ScreenGui,
	})
	corner(tip, RADIUS_SMALL)
	local tipStroke = stroke(tip, Theme.Stroke, 1, 0.5)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = tip,
	})
	local tipLbl = create("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = FONT_BODY_MED,
		TextColor3 = Theme.Text,
		TextSize = 13,
		TextTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = 51,
		Parent = tip,
	})

	local hoverObj, token = nil, 0
	local function hide()
		token += 1
		hoverObj = nil
		tween(tip, TI, { BackgroundTransparency = 1 })
		tween(tipStroke, TI, { Transparency = 1 })
		tween(tipLbl, TI, { TextTransparency = 1 })
		task.delay(0.2, function()
			if not hoverObj and not Library._destroyed then tip.Visible = false end
		end)
	end
	track(UserInputService.InputChanged:Connect(function(inp)
		if hoverObj and tip.Visible and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local mp = UserInputService:GetMouseLocation()
			local maxX = tip.Parent.AbsoluteSize.X
			local x = mp.X + 16
			if tip.AbsoluteSize.X > 0 and x + tip.AbsoluteSize.X > maxX - 12 then
				x = maxX - tip.AbsoluteSize.X - 12
			end
			tip.Position = UDim2.fromOffset(x, mp.Y + 14)
		end
	end))

	function Tooltip.Attach(obj, text)
		if type(text) ~= "string" or text == "" then return end
		track(obj.MouseEnter:Connect(function()
			hoverObj = obj
			token += 1
			local my = token
			task.delay(0.5, function()
				if Library._destroyed or hoverObj ~= obj or token ~= my then return end
				tipLbl.Text = text
				local mp = UserInputService:GetMouseLocation()
				tip.Position = UDim2.fromOffset(mp.X + 16, mp.Y + 14)
				tip.Visible = true
				tween(tip, TI, { BackgroundTransparency = 0.08 })
				tween(tipStroke, TI, { Transparency = STROKE_T })
				tween(tipLbl, TI, { TextTransparency = 0 })
			end)
		end))
		track(obj.MouseLeave:Connect(hide))
		pcall(function() track(obj.MouseButton1Down:Connect(hide)) end)
	end
end

function Library:Notify(cfg)
	if Library._destroyed then return end
	cfg = cfg or {}
	local dur = cfg.Duration or 4
	local nscale = Library._scale or 1

	-- iOS-style notification card with layered materials
	local card = create("Frame", {
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 300 * nscale, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = NotifHolder,
	})
	corner(card, RADIUS_MED * nscale)
	local st = stroke(card, Theme.Stroke, 1, 0.5)

	-- Subtle left accent bar (iOS-style)
	local accent = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 3, 1, 0),
		BorderSizePixel = 0,
		Parent = card,
	})

	-- Content with generous iOS padding
	local content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 0),
		Size = UDim2.new(1, -32, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 14),
			PaddingBottom = UDim.new(0, 14),
		}),
	})

	local titleLbl = create("TextLabel", {
		BackgroundTransparency = 1,
		Text = cfg.Title or "Notification",
		TextTransparency = 1,
		FontFace = FONT_TITLE,
		TextColor3 = Theme.Text,
		TextSize = 15 * nscale,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = content,
	})
	local bodyLbl
	if cfg.Content then
		bodyLbl = create("TextLabel", {
			BackgroundTransparency = 1,
			Text = cfg.Content,
			TextTransparency = 1,
			FontFace = FONT_BODY,
			TextColor3 = Theme.SubText,
			TextSize = 13 * nscale,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = content,
		})
	end

	-- iOS spring-like entrance
	local pop = create("UIScale", { Scale = 0.92, Parent = card })
	tween(pop, TI_SPRING, { Scale = 1 })
	tween(card, TI_S, { BackgroundTransparency = 0.04 })
	tween(st, TI_S, { Transparency = STROKE_T })
	tween(accent, TI_S, { BackgroundTransparency = 0 })
	tween(titleLbl, TI_S, { TextTransparency = 0 })
	if bodyLbl then tween(bodyLbl, TI_S, { TextTransparency = 0 }) end

	task.delay(dur, function()
		if Library._destroyed or not card.Parent then return end
		-- Graceful exit
		tween(pop, TI, { Scale = 0.96 })
		tween(card, TI, { BackgroundTransparency = 1 })
		tween(st, TI, { Transparency = 1 })
		tween(accent, TI, { BackgroundTransparency = 1 })
		tween(titleLbl, TI, { TextTransparency = 1 })
		if bodyLbl then tween(bodyLbl, TI, { TextTransparency = 1 }) end
		task.wait(0.22)
		if card.Parent then card:Destroy() end
	end)
end

----------------------------------------------------------------------
-- Window (iOS-style sheet presentation)
----------------------------------------------------------------------
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	if cfg.Accent then Theme.Accent = cfg.Accent end

	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local vpW, vpH = vp.X, vp.Y

	-- iOS-optimized base dimensions (taller, more spacious)
	local BASE_W, BASE_H = 520, 460
	local scale = cfg.Scale or 0.85
	Library._scale = scale

	local WIN_W = BASE_W * scale
	local WIN_H = BASE_H * scale
	local TOP_H = 52 * scale        -- Compact but readable top bar
	local SIDE_W = 72 * scale       -- Slightly wider rail for touch
	local ROW_H = 48 * scale        -- iOS standard row height (44pt + breathing room)
	local WIN_R = RADIUS_LARGE * scale
	local CARD_R = RADIUS_MED * scale
	local FONT_TITLE_SZ = 16 * scale   -- iOS headline
	local FONT_MAIN_SZ = 14 * scale    -- iOS body
	local FONT_SUB_SZ = 12 * scale     -- iOS footnote
	local PAD_SMALL = 6 * scale
	local PAD_MED = 10 * scale
	local PAD_LARGE = 16 * scale

	local Window = { Tabs = {}, _current = nil }

	-- Centered with iOS-safe positioning
	local startX = vpW * 0.5 - WIN_W * 0.5
	local startY = vpH * 0.10

	-- Main window with iOS sheet styling
	local BG = create("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(startX, startY),
		Size = UDim2.fromOffset(WIN_W, WIN_H),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		Active = true,
		GroupTransparency = 1,
		Parent = ScreenGui,
	})
	corner(BG, WIN_R)
	-- iOS-style subtle shadow via stroke
	stroke(BG, Theme.Stroke, 0.82, 0.5)

	local winScale = create("UIScale", { Scale = 0.94, Parent = BG })
	tween(BG, TI_S, { GroupTransparency = 0 })
	tween(winScale, TI_SPRING, { Scale = 1 })

	----------------------------------------------------------------------
	-- Top bar (iOS navigation bar style)
	----------------------------------------------------------------------
	local TopBar = create("Frame", {
		Name = "TopBar",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, SIDE_W, 0, 0),
		Size = UDim2.new(1, -SIDE_W, 0, TOP_H),
		Active = true,
		ZIndex = 5,
		Parent = BG,
	})

	-- iOS-style control buttons (compact, circular)
	local CTRL_SZ = 28 * scale
	local CTRL_GAP = CTRL_SZ + 8 * scale
	local ctrlReserve = CTRL_GAP * 3 + 12 * scale

	-- Title area with proper iOS hierarchy
	local titleWrap = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, PAD_LARGE, 0.5, 0),
		Size = UDim2.new(1, -ctrlReserve, 0, 22 * scale),
		Parent = TopBar,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6 * scale),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- iOS large title style
	create("TextLabel", {
		Name = "Title",
		Text = cfg.Title or "Lib Name",
		FontFace = FONT_TITLE,
		TextColor3 = Theme.Text,
		TextSize = FONT_TITLE_SZ,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 1,
		Parent = titleWrap,
	})

	-- Subtle tab indicator with iOS-style separator
	local tabLbl = create("TextLabel", {
		Name = "CurrentTab",
		Text = "",
		FontFace = FONT_BODY,
		TextColor3 = Theme.TertiaryText,
		TextSize = FONT_SUB_SZ,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 2,
		Parent = titleWrap,
	})

	local function ctrlBtn(iconName, slotIndex, hoverColor)
		local offsetX = -(slotIndex - 1) * CTRL_GAP - CTRL_SZ * 0.5 - 4 * scale
		local b = create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Selectable = true,
			BackgroundColor3 = Theme.Tertiary,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offsetX, 0.5, 0),
			Size = UDim2.fromOffset(CTRL_SZ, CTRL_SZ),
			Parent = TopBar,
		})
		corner(b, CTRL_SZ * 0.5)
		local bScale = create("UIScale", { Scale = 1, Parent = b })
		b.MouseButton1Down:Connect(function() tween(bScale, TI, { Scale = 0.85 }) end)
		b.MouseButton1Up:Connect(function() tween(bScale, TI_S, { Scale = 1 }) end)
		local ic = icon(iconName, 13 * scale, false, Theme.TertiaryText)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
		ic.Parent = b
		b.MouseEnter:Connect(function()
			tween(b, TI, { BackgroundTransparency = CHIP_MATERIAL })
			tintIcon(ic, hoverColor or Theme.Text)
		end)
		b.MouseLeave:Connect(function()
			tween(b, TI, { BackgroundTransparency = 1 })
			tintIcon(ic, Theme.TertiaryText)
			tween(bScale, TI, { Scale = 1 })
		end)
		return b
	end

	local MinBtn = ctrlBtn("minus", 1, Theme.Text)
	local YtBtn  = ctrlBtn("youtube", 2, Color3.fromRGB(255, 80, 80))
	local DcBtn  = ctrlBtn("discord", 3, Color3.fromRGB(114, 137, 248))
	Tooltip.Attach(MinBtn, "Minimize")
	Tooltip.Attach(YtBtn, "YouTube channel")
	Tooltip.Attach(DcBtn, "Discord server")

	local YT_LINK = "https://youtube.com/@Qanuir"
	local DC_LINK = "https://discord.gg/Qanuir"
	local DC_CODE = "Qanuir"

	YtBtn.Activated:Connect(function()
		local copied = copyToClipboard(YT_LINK)
		Library:Notify({
			Title = "YouTube",
			Content = copied and "Channel link copied to clipboard" or "Clipboard unavailable: " .. YT_LINK,
			Duration = 3,
		})
	end)

	DcBtn.Activated:Connect(function()
		local copied = copyToClipboard(DC_LINK)
		local opened = openDiscordInvite(DC_CODE)
		local msg
		if opened and copied then msg = "Opening invite - link also copied"
		elseif opened then msg = "Opening invite in Discord"
		elseif copied then msg = "Invite link copied to clipboard"
		else msg = "Clipboard unavailable: " .. DC_LINK end
		Library:Notify({ Title = "Discord", Content = msg, Duration = 3 })
	end)

	----------------------------------------------------------------------
	-- Icon rail (iOS-style tab bar on left)
	----------------------------------------------------------------------
	local Rail = create("Frame", {
		Name = "Rail",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, SIDE_W, 1, 0),
		Parent = BG,
	})

	local TabList = create("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 10 * scale),
		Size = UDim2.new(1, 0, 1, -(70 * scale)),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		Selectable = true,
		Parent = Rail,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 6 * scale),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- iOS-style hairline divider
	create("Frame", {
		Name = "RailDivider",
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0, 16 * scale),
		Size = UDim2.new(0, 0.5, 1, -(32 * scale)),
		ZIndex = 2,
		Parent = Rail,
	})

	-- iOS-style destructive action button (power)
	local PWR_SZ = 36 * scale
	local PowerBtn = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Selectable = true,
		BackgroundColor3 = Theme.Tertiary,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12 * scale),
		Size = UDim2.fromOffset(PWR_SZ, PWR_SZ),
		Parent = Rail,
	})
	corner(PowerBtn, 10 * scale)
	Tooltip.Attach(PowerBtn, "Unload UI")
	local powerIc = icon("x", 15 * scale, false, Theme.TertiaryText)
	powerIc.AnchorPoint = Vector2.new(0.5, 0.5)
	powerIc.Position = UDim2.new(0.5, 0, 0.5, 0)
	powerIc.Parent = PowerBtn
	PowerBtn.MouseEnter:Connect(function()
		tween(PowerBtn, TI, {
			BackgroundTransparency = CHIP_MATERIAL,
			BackgroundColor3 = Color3.fromRGB(255, 69, 58)
		})
		tintIcon(powerIc, Theme.Text)
	end)
	PowerBtn.MouseLeave:Connect(function()
		tween(PowerBtn, TI, {
			BackgroundTransparency = 1,
			BackgroundColor3 = Theme.Tertiary
		})
		tintIcon(powerIc, Theme.TertiaryText)
	end)

	local Content = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, SIDE_W, 0, TOP_H),
		Size = UDim2.new(1, -SIDE_W, 1, -TOP_H),
		Parent = BG,
	})

	makeDraggable(BG, TopBar)

	PowerBtn.Activated:Connect(function()
		tween(winScale, TI, { Scale = 0.96 })
		tween(BG, TI, { GroupTransparency = 1 })
		task.delay(0.2, function()
			Library:Destroy()
		end)
	end)

	----------------------------------------------------------------------
	-- Minimize / restore (iOS sheet dismiss style)
	----------------------------------------------------------------------
	local minimized = false
	local fullSize = UDim2.fromOffset(WIN_W, WIN_H)
	MinBtn.Activated:Connect(function()
		minimized = not minimized
		if minimized then
			Rail.Visible = false
			Content.Visible = false
			tween(TopBar, TI_S, {
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, TOP_H)
			})
			tween(BG, TI_S, { Size = UDim2.fromOffset(fullSize.X.Offset, TOP_H) })
		else
			tween(BG, TI_S, { Size = fullSize })
			tween(TopBar, TI_S, {
				Position = UDim2.new(0, SIDE_W, 0, 0),
				Size = UDim2.new(1, -SIDE_W, 0, TOP_H)
			})
			task.delay(0.14, function()
				if Library._destroyed or minimized then return end
				Rail.Visible = true
				Content.Visible = true
			end)
		end
	end)

	----------------------------------------------------------------------
	-- Hide / show (iOS modal presentation)
	----------------------------------------------------------------------
	local hidden = false

	local function setHidden(h)
		if hidden == h then return end
		hidden = h
		if h then
			tween(winScale, TI, { Scale = 0.97 })
			tween(BG, TI, { GroupTransparency = 1 })
			task.delay(0.2, function()
				if hidden and not Library._destroyed then BG.Visible = false end
			end)
		else
			BG.Visible = true
			tween(winScale, TI_SPRING, { Scale = 1 })
			tween(BG, TI_S, { GroupTransparency = 0 })
		end
	end
	Window.SetHidden = setHidden
	Window.IsHidden = function() return hidden end

	track(UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == (cfg.ToggleKey or Enum.KeyCode.RightShift) then
			setHidden(not hidden)
		end
	end))

	----------------------------------------------------------------------
	-- Tabs (iOS-style sidebar selection)
	----------------------------------------------------------------------
	function Window:CreateTab(tcfg)
		tcfg = tcfg or {}
		local Tab = { _order = 0 }

		local TAB_BTN_SZ = 44 * scale
		local btn = create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Selectable = true,
			BackgroundColor3 = Theme.Tertiary,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(TAB_BTN_SZ, TAB_BTN_SZ),
			Parent = TabList,
		})
		corner(btn, 12 * scale)
		if tcfg.Name then Tooltip.Attach(btn, tcfg.Name) end

		local ic = icon(tcfg.Icon or "circle", 20 * scale, false, Theme.TertiaryText)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
		ic.Parent = btn

		-- iOS-style unread badge
		local badge = create("Frame", {
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -5 * scale, 0, 5 * scale),
			Size = UDim2.fromOffset(8 * scale, 8 * scale),
			Visible = false,
			ZIndex = 3,
			Parent = btn,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badge })

		-- Page container with iOS-style presentation
		local pageWrap = create("CanvasGroup", {
			Name = "Page",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			GroupTransparency = 0,
			Parent = Content,
		})
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2 * scale,
			ScrollBarImageColor3 = Theme.Stroke,
			ScrollBarImageTransparency = 0.7,
			Selectable = true,
			Parent = pageWrap,
		}, {
			create("UIListLayout", {
				Padding = UDim.new(0, 8 * scale),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			create("UIPadding", {
				PaddingTop = UDim.new(0, 4 * scale),
				PaddingBottom = UDim.new(0, PAD_LARGE),
				PaddingLeft = UDim.new(0, PAD_LARGE),
				PaddingRight = UDim.new(0, PAD_LARGE),
			}),
		})

		local function select()
			if Window._current == Tab then return end
			for _, t in Window.Tabs do
				if t ~= Tab then t._wrap.Visible = false end
				tween(t._btn, TI, { BackgroundTransparency = 1 })
				tintIcon(t._icon, Theme.TertiaryText)
			end
			Window._current = Tab
			badge.Visible = false
			tabLbl.Text = "/  " .. (tcfg.Name or "Tab")
			pageWrap.Visible = true
			pageWrap.GroupTransparency = 1
			pageWrap.Position = UDim2.new(0.02, 0, 0, 0)
			tween(pageWrap, TI_S, {
				GroupTransparency = 0,
				Position = UDim2.new(0, 0, 0, 0)
			})
			tween(btn, TI, { BackgroundTransparency = CHIP_MATERIAL })
			tintIcon(ic, Theme.Accent)
		end

		btn.MouseEnter:Connect(function()
			if Window._current ~= Tab then
				tween(btn, TI, { BackgroundTransparency = 0.92 })
			end
		end)
		btn.MouseLeave:Connect(function()
			if Window._current ~= Tab then
				tween(btn, TI, { BackgroundTransparency = 1 })
			end
		end)
		btn.Activated:Connect(function()
			ripple(btn, Theme.Accent)
			select()
		end)

		Tab._btn, Tab._icon, Tab._page, Tab._wrap, Tab._select = btn, ic, page, pageWrap, select
		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then select() end

		function Tab:SetBadge(v)
			badge.Visible = (v == true) and Window._current ~= Tab
		end

		-- iOS-style sectioned row creation
		local function newRow(height)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundColor3 = Theme.Secondary,
				BackgroundTransparency = MATERIAL_REGULAR,
				Size = UDim2.new(1, 0, 0, height or ROW_H),
				LayoutOrder = Tab._order,
				BorderSizePixel = 0,
				Parent = page,
			})
			corner(row, CARD_R)
			stroke(row, Theme.Stroke, STROKE_T, 0.5)
			return row
		end

		local function rowHover(row, rowStroke)
			return function()
				tween(row, TI, { BackgroundTransparency = MATERIAL_THICK })
				if rowStroke then
					tween(rowStroke, TI, { Color = Theme.Accent, Transparency = 0.5 })
				end
			end, function()
				tween(row, TI, { BackgroundTransparency = MATERIAL_REGULAR })
				if rowStroke then
					tween(rowStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				end
			end
		end

		----------------------------------------------------------------------
		-- 1. Label (iOS-style section header)
		----------------------------------------------------------------------
		function Tab:CreateLabel(text)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = Tab._order,
				BorderSizePixel = 0,
				Parent = page,
			})
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1,
				Text = text or "Label",
				FontFace = FONT_BODY,
				TextColor3 = Theme.TertiaryText,
				TextSize = FONT_SUB_SZ,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, -PAD_SMALL, 0, 0),
				Position = UDim2.new(0, PAD_SMALL, 0, 0),
				Parent = row,
			})
			create("UIPadding", {
				PaddingTop = UDim.new(0, 4 * scale),
				PaddingBottom = UDim.new(0, 4 * scale),
				Parent = row,
			})
			return {
				Set = function(_, t) lbl.Text = t end,
				Instance = row,
			}
		end

		----------------------------------------------------------------------
		-- 2. Warning (iOS-style alert banner)
		----------------------------------------------------------------------
		function Tab:CreateWarning(text)
			local row = newRow(0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			row.BackgroundColor3 = Theme.Warning
			row.BackgroundTransparency = 0.94
			for _, s in row:GetChildren() do
				if s:IsA("UIStroke") then
					s.Color = Theme.Warning
					s.Transparency = 0.5
				end
			end
			create("UIPadding", {
				PaddingTop = UDim.new(0, 12 * scale),
				PaddingBottom = UDim.new(0, 12 * scale),
				PaddingLeft = UDim.new(0, PAD_MED),
				PaddingRight = UDim.new(0, PAD_MED),
				Parent = row,
			})
			local ico = icon("triangle-exclamation", 16 * scale, false, Theme.Warning)
			ico.AnchorPoint = Vector2.new(0, 0.5)
			ico.Position = UDim2.new(0, 0, 0.5, 0)
			ico.Parent = row
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1,
				Text = text or "Warning",
				FontFace = FONT_BODY_MED,
				TextColor3 = Theme.Warning,
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, -26 * scale, 0, 0),
				Position = UDim2.new(0, 26 * scale, 0, 0),
				Parent = row,
			})
			return {
				Set = function(_, t) lbl.Text = t end,
				Instance = row,
			}
		end

		----------------------------------------------------------------------
		-- 3. Button (iOS-style cell with chevron)
		----------------------------------------------------------------------
		function Tab:CreateButton(bcfg)
			bcfg = bcfg or {}
			Tab._order += 1
			local btnEl = create("TextButton", {
				Text = "",
				AutoButtonColor = false,
				Selectable = true,
				BackgroundColor3 = Theme.Secondary,
				BackgroundTransparency = MATERIAL_REGULAR,
				Size = UDim2.new(1, 0, 0, ROW_H),
				LayoutOrder = Tab._order,
				BorderSizePixel = 0,
				Parent = page,
			})
			corner(btnEl, CARD_R)
			local btnStroke = stroke(btnEl, Theme.Stroke, STROKE_T, 0.5)
			if bcfg.Tooltip then Tooltip.Attach(btnEl, bcfg.Tooltip) end

			-- iOS-style cell label
			create("TextLabel", {
				BackgroundTransparency = 1,
				Text = bcfg.Name or "Button",
				FontFace = FONT_BODY_MED,
				TextColor3 = Theme.Text,
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0),
				Size = UDim2.new(1, -(72 * scale), 1, 0),
				Parent = btnEl,
			})

			-- iOS-style disclosure indicator
			local chip = create("Frame", {
				BackgroundColor3 = Theme.Tertiary,
				BackgroundTransparency = CHIP_MATERIAL,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_SMALL, 0.5, 0),
				Size = UDim2.fromOffset(26 * scale, 26 * scale),
				BorderSizePixel = 0,
				Parent = btnEl,
			})
			corner(chip, 13 * scale)
			local chipIc = icon("chevron-right", 11 * scale, false, Theme.TertiaryText)
			chipIc.AnchorPoint = Vector2.new(0.5, 0.5)
			chipIc.Position = UDim2.new(0.5, 0, 0.5, 0)
			chipIc.Parent = chip

			btnEl.MouseEnter:Connect(function()
				tween(btnEl, TI, { BackgroundTransparency = MATERIAL_THICK })
				tween(btnStroke, TI, { Color = Theme.Accent, Transparency = 0.45 })
				tween(chip, TI, { BackgroundTransparency = 0.75 })
				tintIcon(chipIc, Theme.Text)
			end)
			btnEl.MouseLeave:Connect(function()
				tween(btnEl, TI, { BackgroundTransparency = MATERIAL_REGULAR })
				tween(btnStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				tween(chip, TI, { BackgroundTransparency = CHIP_MATERIAL })
				tintIcon(chipIc, Theme.TertiaryText)
			end)
			btnEl.Activated:Connect(function()
				ripple(btnEl, Theme.Accent)
				tween(chip, TI, {
					BackgroundColor3 = Theme.Accent,
					BackgroundTransparency = 0.12
				})
				tintIcon(chipIc, Theme.Text)
				task.delay(0.16, function()
					if Library._destroyed or not chip.Parent then return end
					tween(chip, TI, {
						BackgroundColor3 = Theme.Tertiary,
						BackgroundTransparency = CHIP_MATERIAL
					})
					tintIcon(chipIc, Theme.TertiaryText)
				end)
				if bcfg.Callback then task.spawn(bcfg.Callback) end
			end)
			return { Instance = btnEl }
		end

		----------------------------------------------------------------------
		-- 4. Toggle (iOS-style switch)
		----------------------------------------------------------------------
		function Tab:CreateToggle(tocfg)
			tocfg = tocfg or {}
			local state = tocfg.Default or false
			local row = newRow(ROW_H)
			local rowStroke = row:FindFirstChildOfClass("UIStroke")
			local btnEl = create("TextButton", {
				Text = "",
				BackgroundTransparency = 1,
				Selectable = true,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = row,
			})
			if tocfg.Tooltip then Tooltip.Attach(btnEl, tocfg.Tooltip) end

			create("TextLabel", {
				BackgroundTransparency = 1,
				Text = tocfg.Name or "Toggle",
				FontFace = FONT_BODY_MED,
				TextColor3 = Theme.Text,
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0),
				Size = UDim2.new(1, -(84 * scale), 1, 0),
				Parent = btnEl,
			})

			-- iOS-style switch (pill track with spring animation)
			local track_ = create("Frame", {
				BackgroundColor3 = state and Theme.Accent or Theme.Element,
				BackgroundTransparency = state and 0 or 0.6,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_MED, 0.5, 0),
				Size = UDim2.fromOffset(50 * scale, 28 * scale),
				BorderSizePixel = 0,
				Parent = btnEl,
			})
			corner(track_, RADIUS_PILL)
			local knob = create("Frame", {
				BackgroundColor3 = Theme.On,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -(25 * scale), 0.5, 0) or UDim2.new(0, 2 * scale, 0.5, 0),
				Size = UDim2.fromOffset(24 * scale, 24 * scale),
				BorderSizePixel = 0,
				Parent = track_,
			})
			corner(knob, RADIUS_PILL)
			-- iOS-style subtle shadow on knob
			stroke(knob, Color3.new(0, 0, 0), 0.85, 0.5)

			local enter, leave = rowHover(row, rowStroke)
			btnEl.MouseEnter:Connect(enter)
			btnEl.MouseLeave:Connect(leave)

			local api = {}
			function api:Set(v)
				state = v
				tween(track_, TI, {
					BackgroundColor3 = state and Theme.Accent or Theme.Element,
					BackgroundTransparency = state and 0 or 0.6,
				})
				tween(knob, TI_SPRING, {
					Position = state and UDim2.new(1, -(25 * scale), 0.5, 0) or UDim2.new(0, 2 * scale, 0.5, 0)
				})
				if tocfg.Callback then task.spawn(tocfg.Callback, state) end
			end
			function api:Get() return state end
			btnEl.Activated:Connect(function() api:Set(not state) end)
			if state and tocfg.Callback and tocfg.FireOnInit ~= false then
				task.spawn(tocfg.Callback, true)
			end
			api.Instance = row
			return api
		end

		----------------------------------------------------------------------
		-- 5. Stat (iOS-style key-value cell)
		----------------------------------------------------------------------
		function Tab:CreateStat(scfg)
			scfg = scfg or {}
			local row = newRow(42 * scale)
			if scfg.Tooltip then Tooltip.Attach(row, scfg.Tooltip) end

			create("TextLabel", {
				BackgroundTransparency = 1,
				Text = scfg.Name or "Stat",
				FontFace = FONT_BODY,
				TextColor3 = Theme.TertiaryText,
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0),
				Size = UDim2.new(0.5, -PAD_MED, 1, 0),
				Parent = row,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1,
				Text = tostring(scfg.Value or "-"),
				FontFace = FONT_TITLE,
				TextColor3 = Theme.Accent,
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_MED, 0.5, 0),
				Size = UDim2.new(0.5, -PAD_MED, 1, 0),
				Parent = row,
			})
			return {
				Set = function(_, v) valLbl.Text = tostring(v) end,
				Instance = row,
			}
		end

		----------------------------------------------------------------------
		-- 6. Slider (iOS-style value adjuster)
		----------------------------------------------------------------------
		function Tab:CreateSlider(slcfg)
			slcfg = slcfg or {}
			local min, max = slcfg.Min or 0, slcfg.Max or 100
			local inc = slcfg.Increment or 1
			local value = math.clamp(slcfg.Default or min, min, max)
			local row = newRow(60 * scale)
			local rowStroke = row:FindFirstChildOfClass("UIStroke")
			if slcfg.Tooltip then Tooltip.Attach(row, slcfg.Tooltip) end

			-- iOS-style compact label
			create("TextLabel", {
				BackgroundTransparency = 1,
				Text = slcfg.Name or "Slider",
				FontFace = FONT_BODY_MED,
				TextColor3 = Theme.Text,
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, PAD_MED, 0, 10 * scale),
				Size = UDim2.new(1, -(152 * scale), 0, 16 * scale),
				Parent = row,
			})

			local suffix = slcfg.Suffix or ""
			local function fmtVal(v) return tostring(v) .. suffix end
			local api = {}

			-- iOS-style stepper control
			local valWrap = create("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -PAD_MED, 0, 8 * scale),
				Size = UDim2.fromOffset(132 * scale, 22 * scale),
				Parent = row,
			}, {
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 4 * scale),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			})

			local function stepBtn(txt, delta, order)
				local b = create("TextButton", {
					Text = "",
					AutoButtonColor = false,
					Selectable = true,
					BackgroundColor3 = Theme.Tertiary,
					BackgroundTransparency = CHIP_MATERIAL,
					Size = UDim2.fromOffset(22 * scale, 22 * scale),
					LayoutOrder = order,
					BorderSizePixel = 0,
					Parent = valWrap,
				})
				corner(b, 6 * scale)
				local lbl = create("TextLabel", {
					BackgroundTransparency = 1,
					Text = txt,
					FontFace = FONT_TITLE,
					TextColor3 = Theme.TertiaryText,
					TextSize = FONT_SUB_SZ,
					Size = UDim2.new(1, 0, 1, 0),
					Parent = b,
				})
				b.MouseEnter:Connect(function()
					tween(lbl, TI, { TextColor3 = Theme.Text })
				end)
				b.MouseLeave:Connect(function()
					tween(lbl, TI, { TextColor3 = Theme.TertiaryText })
				end)
				b.Activated:Connect(function()
					ripple(b, Theme.Accent)
					api:Set(value + delta)
				end)
			end

			-- iOS-style value field
			local valBox = create("TextBox", {
				BackgroundColor3 = Theme.Tertiary,
				BackgroundTransparency = 0.88,
				Text = fmtVal(value),
				ClearTextOnFocus = false,
				FontFace = FONT_TITLE,
				TextColor3 = Theme.Accent,
				TextSize = FONT_MAIN_SZ,
				LayoutOrder = 2,
				Size = UDim2.fromOffset(56 * scale, 22 * scale),
				Parent = valWrap,
			})
			corner(valBox, 6 * scale)
			local vbStroke = stroke(valBox, Theme.Stroke, STROKE_T, 0.5)
			valBox.Focused:Connect(function()
				tween(vbStroke, TI, { Color = Theme.Accent, Transparency = 0.2 })
			end)

			stepBtn("-", -inc, 1)
			stepBtn("+", inc, 3)

			-- iOS-style track with refined proportions
			local TRACK_H = 4 * scale
			local trackBar = create("Frame", {
				BackgroundColor3 = Theme.Element,
				BackgroundTransparency = 0.7,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, PAD_MED, 1, -14 * scale),
				Size = UDim2.new(1, -(2 * PAD_MED), 0, TRACK_H),
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(trackBar, 2 * scale)
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
				BorderSizePixel = 0,
				Parent = trackBar,
			})
			corner(fill, 2 * scale)
			local KNOB_SZ = 18 * scale
			local knob = create("Frame", {
				BackgroundColor3 = Theme.On,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
				Size = UDim2.fromOffset(KNOB_SZ, KNOB_SZ),
				BorderSizePixel = 0,
				ZIndex = 2,
				Parent = trackBar,
			})
			corner(knob, RADIUS_PILL)
			stroke(knob, Color3.new(0, 0, 0), 0.82, 0.5)

			local function apply(alpha, fire)
				local raw = min + (max - min) * alpha
				value = math.clamp(math.floor(raw / inc + 0.5) * inc, min, max)
				local a = (max - min) == 0 and 0 or (value - min) / (max - min)
				fill.Size = UDim2.new(a, 0, 1, 0)
				knob.Position = UDim2.new(a, 0, 0.5, 0)
				valBox.Text = fmtVal(value)
				if fire and slcfg.Callback then task.spawn(slcfg.Callback, value) end
			end

			bindDrag(trackBar, function(ax, _, ended)
				if ended then
					apply(ax, true)
				elseif slcfg.Live then
					apply(ax, true)
				else
					apply(ax, false)
				end
			end)

			valBox.FocusLost:Connect(function(enterPressed)
				tween(vbStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				if not enterPressed then
					valBox.Text = fmtVal(value)
					return
				end
				local n = tonumber((valBox.Text:gsub("[^%d%.%-]", "")))
				if n then
					api:Set(n)
				else
					valBox.Text = fmtVal(value)
				end
			end)

			local enter, leave = rowHover(row, rowStroke)
			row.MouseEnter:Connect(enter)
			row.MouseLeave:Connect(leave)

			function api:Set(v)
				v = math.clamp(tonumber(v) or min, min, max)
				apply((max - min) == 0 and 0 or (v - min) / (max - min), true)
			end
			function api:Get() return value end
			api.Instance = row
			return api
		end

		----------------------------------------------------------------------
		-- 7. Textbox (iOS-style text field)
		----------------------------------------------------------------------
		function Tab:CreateTextbox(txcfg)
			txcfg = txcfg or {}
			local row = newRow(ROW_H)
			if txcfg.Tooltip then Tooltip.Attach(row, txcfg.Tooltip) end

			create("TextLabel", {
				BackgroundTransparency = 1,
				Text = txcfg.Name or "Textbox",
				FontFace = FONT_BODY_MED,
				TextColor3 = Theme.Text,
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0),
				Size = UDim2.new(0.4, -PAD_MED, 1, 0),
				Parent = row,
			})

			-- iOS-style text field with inner shadow feel
			local boxWrap = create("Frame", {
				BackgroundColor3 = Theme.Tertiary,
				BackgroundTransparency = 0.88,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_SMALL, 0.5, 0),
				Size = UDim2.new(0, 0, 0, 30 * scale),
				AutomaticSize = Enum.AutomaticSize.X,
				ClipsDescendants = true,
				BorderSizePixel = 0,
				Parent = row,
			}, {
				create("UIPadding", {
					PaddingLeft = UDim.new(0, 12 * scale),
					PaddingRight = UDim.new(0, 12 * scale),
				}),
			})
			corner(boxWrap, RADIUS_SMALL * scale)
			local tbStroke = stroke(boxWrap, Theme.Stroke, STROKE_T, 0.5)
			local tb = create("TextBox", {
				BackgroundTransparency = 1,
				Text = txcfg.Default or "",
				PlaceholderText = txcfg.Placeholder or "...",
				PlaceholderColor3 = Theme.TertiaryText,
				FontFace = FONT_BODY_MED,
				TextColor3 = Theme.Text,
				TextSize = 13 * scale,
				ClearTextOnFocus = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				Parent = boxWrap,
			}, {
				create("UISizeConstraint", {
					MinSize = Vector2.new((txcfg.MinWidth or 72) * scale, 0),
					MaxSize = Vector2.new((txcfg.MaxWidth or 200) * scale, math.huge),
				}),
			})
			tb.Focused:Connect(function()
				tween(tbStroke, TI, { Color = Theme.Accent, Transparency = 0.18 })
			end)
			tb.FocusLost:Connect(function()
				tween(tbStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				if txcfg.Callback then task.spawn(txcfg.Callback, tb.Text) end
			end)
			return {
				Set = function(_, t) tb.Text = t end,
				Get = function() return tb.Text end,
				Instance = row,
			}
		end

		----------------------------------------------------------------------
		-- 8. Color Picker (iOS-style expanded cell)
		----------------------------------------------------------------------
		function Tab:CreateColorPicker(ccfg)
			ccfg = ccfg or {}
			local color = ccfg.Default or Color3.fromRGB(255, 0, 0)
			local h, s, v = color:ToHSV()

			local row = newRow(ROW_H)
			row.ClipsDescendants = true
			local rowStroke = row:FindFirstChildOfClass("UIStroke")
			local header = create("TextButton", {
				Text = "",
				BackgroundTransparency = 1,
				Selectable = true,
				Size = UDim2.new(1, 0, 0, ROW_H),
				Parent = row,
			})
			if ccfg.Tooltip then Tooltip.Attach(header, ccfg.Tooltip) end

			create("TextLabel", {
				BackgroundTransparency = 1,
				Text = ccfg.Name or "Color",
				FontFace = FONT_BODY_MED,
				TextColor3 = Theme.Text,
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0),
				Size = UDim2.new(1, -(76 * scale), 1, 0),
				Parent = header,
			})

			-- iOS-style color swatch (rounded rectangle)
			local swatch = create("Frame", {
				BackgroundColor3 = color,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_MED, 0.5, 0),
				Size = UDim2.fromOffset(36 * scale, 22 * scale),
				BorderSizePixel = 0,
				Parent = header,
			})
			corner(swatch, 6 * scale)
			stroke(swatch, Theme.Stroke, 0.45, 0.5)

			-- Expanded picker body
			local body = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, ROW_H),
				Size = UDim2.new(1, 0, 0, 150 * scale),
				Visible = false,
				Parent = row,
			})
			create("UIPadding", {
				PaddingLeft = UDim.new(0, PAD_MED),
				PaddingRight = UDim.new(0, PAD_MED),
				PaddingBottom = UDim.new(0, PAD_MED),
				Parent = body,
			})

			-- iOS-style color square
			local sv = create("Frame", {
				BackgroundColor3 = Color3.fromHSV(h, 1, 1),
				Size = UDim2.new(1, -(40 * scale), 1, 0),
				BorderSizePixel = 0,
				Parent = body,
			})
			corner(sv, 10 * scale)
			create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(1, 0, 1, 0),
				BorderSizePixel = 0,
				Parent = sv,
			}, {
				create("UIGradient", {
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1)
					}),
				}),
				create("UICorner", { CornerRadius = UDim.new(0, 10 * scale) }),
			})
			create("Frame", {
				BackgroundColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				BorderSizePixel = 0,
				Parent = sv,
			}, {
				create("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new(Color3.new(0, 0, 0)),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0)
					}),
				}),
				create("UICorner", { CornerRadius = UDim.new(0, 10 * scale) }),
			})

			local svCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0),
				Size = UDim2.fromOffset(10 * scale, 10 * scale),
				BorderSizePixel = 0,
				ZIndex = 5,
				Parent = sv,
			})
			corner(svCursor, 5 * scale)
			stroke(svCursor, Color3.new(0, 0, 0), 0.22, 0.5)

			-- iOS-style hue slider
			local hue = create("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 28 * scale, 1, 0),
				BorderSizePixel = 0,
				Parent = body,
			})
			corner(hue, 10 * scale)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
				}),
				Parent = hue,
			})
			local hueCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, h, 0),
				Size = UDim2.new(1, 4 * scale, 0, 5 * scale),
				BorderSizePixel = 0,
				ZIndex = 5,
				Parent = hue,
			})
			corner(hueCursor, 2 * scale)
			stroke(hueCursor, Color3.new(0, 0, 0), 0.22, 0.5)

			local function refresh(fire)
				color = Color3.fromHSV(h, s, v)
				sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				hueCursor.Position = UDim2.new(0.5, 0, h, 0)
				swatch.BackgroundColor3 = color
				if fire and ccfg.Callback then task.spawn(ccfg.Callback, color) end
			end

			bindDrag(sv, function(ax, ay, ended)
				s = ax; v = 1 - ay
				refresh(ccfg.Live == true or ended)
			end)
			bindDrag(hue, function(_, ay, ended)
				h = ay
				refresh(ccfg.Live == true or ended)
			end)

			local enter, leave = rowHover(row, rowStroke)
			header.MouseEnter:Connect(enter)
			header.MouseLeave:Connect(leave)

			local open = false
			header.Activated:Connect(function()
				open = not open
				if open then body.Visible = true end
				tween(row, TI_S, {
					Size = UDim2.new(1, 0, 0, open and (ROW_H + 150 * scale) or ROW_H)
				})
				if not open then
					task.delay(0.14, function()
						if not open and not Library._destroyed then body.Visible = false end
					end)
				end
			end)

			local api = {}
			function api:Set(c) h, s, v = c:ToHSV(); refresh(true) end
			function api:Get() return color end
			api.Instance = row
			return api
		end

		----------------------------------------------------------------------
		-- 9. Dropdown (iOS-style disclosure with expanded list)
		----------------------------------------------------------------------
		function Tab:CreateDropdown(dcfg)
			dcfg = dcfg or {}
			local options = dcfg.Options or {}
			local multi = dcfg.Multi or false
			local selected = {}
			if dcfg.Default then
				if type(dcfg.Default) == "table" then
					for _, d in dcfg.Default do selected[d] = true end
				else
					selected[dcfg.Default] = true
				end
			end

			local row = newRow(ROW_H)
			row.ClipsDescendants = true
			local rowStroke = row:FindFirstChildOfClass("UIStroke")
			local header = create("TextButton", {
				Text = "",
				BackgroundTransparency = 1,
				Selectable = true,
				Size = UDim2.new(1, 0, 0, ROW_H),
				Parent = row,
			})
			if dcfg.Tooltip then Tooltip.Attach(header, dcfg.Tooltip) end

			create("TextLabel", {
				BackgroundTransparency = 1,
				Text = dcfg.Name or "Dropdown",
				FontFace = FONT_BODY_MED,
				TextColor3 = Theme.Text,
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0),
				Size = UDim2.new(0.45, 0, 1, 0),
				Parent = header,
			})

			-- iOS-style value display with chevron
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1,
				Text = "",
				FontFace = FONT_BODY,
				TextColor3 = Theme.TertiaryText,
				TextSize = FONT_SUB_SZ,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -(38 * scale), 0.5, 0),
				Size = UDim2.new(0.45, -(10 * scale), 1, 0),
				Parent = header,
			})
			local chev = icon("chevron-down", 14 * scale, false, Theme.TertiaryText)
			chev.AnchorPoint = Vector2.new(1, 0.5)
			chev.Position = UDim2.new(1, -PAD_MED, 0.5, 0)
			chev.Parent = header

			-- iOS-style expanded list
			local list = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, ROW_H),
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false,
				Parent = row,
			}, {
				create("UIListLayout", {
					Padding = UDim.new(0, 2 * scale),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				create("UIPadding", {
					PaddingTop = UDim.new(0, 4 * scale),
					PaddingLeft = UDim.new(0, PAD_SMALL),
					PaddingRight = UDim.new(0, PAD_SMALL),
					PaddingBottom = UDim.new(0, 12 * scale),
				}),
			})

			local function updateValLabel()
				local picked = {}
				for _, o in options do if selected[o] then table.insert(picked, o) end end
				valLbl.Text = #picked == 0 and "None" or table.concat(picked, ", ")
			end

			local api = {}
			local optionBtns = {}

			local function rebuild()
				for _, b in optionBtns do b.btn:Destroy() end
				table.clear(optionBtns)
				for i, opt in options do
					local ob = create("TextButton", {
						Text = "",
						AutoButtonColor = false,
						Selectable = true,
						BackgroundColor3 = Theme.Tertiary,
						BackgroundTransparency = 0.94,
						Size = UDim2.new(1, 0, 0, 32 * scale),
						LayoutOrder = i,
						BorderSizePixel = 0,
						Parent = list,
					})
					corner(ob, 8 * scale)
					local txt = create("TextLabel", {
						BackgroundTransparency = 1,
						Text = opt,
						FontFace = FONT_BODY_MED,
						TextColor3 = selected[opt] and Theme.Accent or Theme.TertiaryText,
						TextSize = FONT_SUB_SZ,
						TextXAlignment = Enum.TextXAlignment.Left,
						Position = UDim2.new(0, PAD_MED, 0, 0),
						Size = UDim2.new(1, -(36 * scale), 1, 0),
						Parent = ob,
					})
					local check = icon("check", 12 * scale, false, Theme.Accent)
					check.AnchorPoint = Vector2.new(1, 0.5)
					check.Position = UDim2.new(1, -PAD_MED, 0.5, 0)
					check.Visible = selected[opt] == true
					check.Parent = ob

					ob.MouseEnter:Connect(function()
						tween(ob, TI, { BackgroundTransparency = 0.88 })
					end)
					ob.MouseLeave:Connect(function()
						tween(ob, TI, { BackgroundTransparency = 0.94 })
					end)
					ob.Activated:Connect(function()
						ripple(ob, Theme.Accent)
						if multi then
							selected[opt] = not selected[opt]
						else
							table.clear(selected)
							selected[opt] = true
						end
						for _, b in optionBtns do
							local on = selected[b.opt] == true
							b.check.Visible = on
							tween(b.txt, TI, {
								TextColor3 = on and Theme.Accent or Theme.TertiaryText
							})
						end
						updateValLabel()
						if dcfg.Callback then
							if multi then
								local out = {}
								for _, o in options do if selected[o] then table.insert(out, o) end end
								task.spawn(dcfg.Callback, out)
							else
								task.spawn(dcfg.Callback, opt)
							end
						end
						if not multi then
							task.wait(0.06)
							api._toggle(false)
						end
					end)
					table.insert(optionBtns, {
						btn = ob,
						opt = opt,
						txt = txt,
						check = check,
					})
				end
				updateValLabel()
			end

			local function openHeight()
				local n = #options
				if n == 0 then return ROW_H + 18 * scale end
				return ROW_H + (12 * scale) + (n * 32 * scale) + ((n - 1) * 2 * scale)
			end

			local open = false
			function api._toggle(force)
				if Library._destroyed then return end
				if force ~= nil then open = force else open = not open end
				if open then list.Visible = true end
				tween(row, TI_S, {
					Size = UDim2.new(1, 0, 0, open and openHeight() or ROW_H)
				})
				tween(chev, TI, { Rotation = open and 180 or 0 })
				if not open then
					task.delay(0.14, function()
						if not open and not Library._destroyed then list.Visible = false end
					end)
				end
			end
			header.Activated:Connect(function()
				ripple(header, Theme.Accent)
				api._toggle()
			end)

			local enter, leave = rowHover(row, rowStroke)
			header.MouseEnter:Connect(enter)
			header.MouseLeave:Connect(leave)

			function api:Refresh(newOpts)
				options = newOpts or options
				rebuild()
				if open then api._toggle(true) end
			end
			function api:Set(val)
				table.clear(selected)
				if type(val) == "table" then
					for _, x in val do selected[x] = true end
				else
					selected[val] = true
				end
				rebuild()
			end
			function api:Get()
				local out = {}
				for _, o in options do if selected[o] then table.insert(out, o) end end
				return multi and out or out[1]
			end
			api.Instance = row
			rebuild()
			return api
		end

		return Tab
	end

	function Window:Destroy()
		Library:Destroy()
	end

	Window.Instance = BG
	return Window
end

return Library
