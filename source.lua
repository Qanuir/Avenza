local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local setClipboard = setclipboard or toclipboard or writeclipboard or write_clipboard
	or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

----------------------------------------------------------------------
-- Singleton guard (no duplicate execution)
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
-- Theme  (visionOS-inspired frosted glass)
----------------------------------------------------------------------
local Theme = {
	Background = Color3.fromRGB(18, 18, 22),
	Secondary  = Color3.fromRGB(26, 26, 31),
	Element    = Color3.fromRGB(255, 255, 255), -- glass fills (used with GLASS_T)
	ElementHover = Color3.fromRGB(255, 255, 255),
	Off        = Color3.fromRGB(255, 255, 255),
	Stroke     = Color3.fromRGB(255, 255, 255),
	Text       = Color3.fromRGB(255, 255, 255),
	SubText    = Color3.fromRGB(170, 170, 182),
	Warning    = Color3.fromRGB(255, 205, 110),
	Accent     = Color3.fromRGB(88, 142, 255),
}

-- glass opacity levels
local GLASS_T  = 0.94 -- resting card fill
local GLASS_HT = 0.89 -- hovered card fill
local CHIP_T   = 0.88 -- chips / small controls
local STROKE_T = 0.90 -- hairline strokes

local BUILDER_ICONS = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"
local FONT_TITLE = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_MAIN  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

local TI    = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_S  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

----------------------------------------------------------------------
-- Connection tracking (for proper destroy)
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
	return create("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = parent })
end

local function stroke(parent, color, trans, thick)
	return create("UIStroke", {
		Color = color or Theme.Stroke,
		Transparency = trans or 0.5,
		Thickness = thick or 1,
		Parent = parent,
	})
end

local function addShadow(parent, blur, trans)
	local ok, shadow = pcall(function()
		return create("UIShadow", {
			BlurRadius = UDim.new(0, blur or 16),
			Transparency = trans or 0.5,
			Parent = parent,
		})
	end)
	return ok and shadow or nil
end

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info or TI, props)
	t:Play()
	return t
end

local function icon(name, size, filled, color)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Text = name or "",
		FontFace = Font.new(BUILDER_ICONS, filled and Enum.FontWeight.Bold or Enum.FontWeight.Regular),
		TextColor3 = color or Theme.Text,
		TextScaled = true,
		Size = UDim2.fromOffset(size or 18, size or 18),
	})
end

local function makeDraggable(frame, handle)
	local dragging, dragInput, startPos, startFramePos
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = inp.Position
			startFramePos = frame.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			dragInput = inp
		end
	end)
	track(UserInputService.InputChanged:Connect(function(inp)
		if inp == dragInput and dragging then
			local delta = inp.Position - startPos
			frame.Position = UDim2.new(
				startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
				startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y)
		end
	end))
end

local function bindDrag(region, onUpdate)
	local dragging = false
	local function upd(inp)
		local ap, sz = region.AbsolutePosition, region.AbsoluteSize
		local ax = math.clamp((inp.Position.X - ap.X) / sz.X, 0, 1)
		local ay = math.clamp((inp.Position.Y - ap.Y) / sz.Y, 0, 1)
		onUpdate(ax, ay)
	end
	region.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; upd(inp)
		end
	end)
	region.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	track(UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			upd(inp)
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

-- kill any stale gui left over from a previous run / older build
local GuiParent = getGuiParent()
do
	local stale = GuiParent:FindFirstChild("VaehzUI")
	if stale then pcall(function() stale:Destroy() end) end
end

local ScreenGui = create("ScreenGui", {
	Name = "VaehzUI",
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
	pcall(function() ScreenGui:Destroy() end)
	if ENV[REG_KEY] == Library then
		ENV[REG_KEY] = nil
	end
end

-- register as the active singleton instance
ENV[REG_KEY] = Library

local NotifHolder = create("Frame", {
	Name = "Notifications",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 260, 1, -32),
	Parent = ScreenGui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

function Library:Notify(cfg)
	if Library._destroyed then return end
	cfg = cfg or {}
	local dur = cfg.Duration or 4

	local card = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(22, 22, 27),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 260, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = NotifHolder,
	})
	corner(card, 14)
	local st = stroke(card, Theme.Stroke, 1)

	local accent = create("Frame", {
		BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
		Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, Parent = card,
	})

	local content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -26, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, Parent = card,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }),
	})

	local titleLbl = create("TextLabel", {
		BackgroundTransparency = 1, Text = cfg.Title or "Notification", TextTransparency = 1,
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1, Parent = content,
	})
	local bodyLbl
	if cfg.Content then
		bodyLbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = cfg.Content, TextTransparency = 1,
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2, Parent = content,
		})
	end

	card.Position = UDim2.new(0, 26, 0, 0)
	tween(card, TI_S, { BackgroundTransparency = 0.06, Position = UDim2.new(0, 0, 0, 0) })
	tween(st, TI_S, { Transparency = 0.88 })
	tween(accent, TI_S, { BackgroundTransparency = 0 })
	tween(titleLbl, TI_S, { TextTransparency = 0 })
	if bodyLbl then tween(bodyLbl, TI_S, { TextTransparency = 0 }) end

	task.delay(dur, function()
		if Library._destroyed or not card.Parent then return end
		tween(card, TI, { BackgroundTransparency = 1, Position = UDim2.new(0, 26, 0, 0) })
		tween(st, TI, { Transparency = 1 })
		tween(accent, TI, { BackgroundTransparency = 1 })
		tween(titleLbl, TI, { TextTransparency = 1 })
		if bodyLbl then tween(bodyLbl, TI, { TextTransparency = 1 }) end
		task.wait(0.2)
		if card.Parent then card:Destroy() end
	end)
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	if cfg.Accent then Theme.Accent = cfg.Accent end

	local scale = cfg.Scale or 1

	local WIN_W = 580 * scale
	local WIN_H = 400 * scale
	local TOP_H = 56 * scale
	local SIDE_W = 66 * scale
	local ROW_H = 44 * scale
	local WIN_R = 22 * scale
	local CARD_R = 14 * scale
	local FONT_TITLE_SZ = 17 * scale
	local FONT_MAIN_SZ = 14 * scale
	local FONT_SUB_SZ = 12 * scale
	local PAD_SMALL = 8 * scale
	local PAD_MED = 12 * scale
	local PAD_LARGE = 14 * scale

	local Window = { Tabs = {}, _current = nil }

	local BG = create("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.12, 0),
		Size = UDim2.fromOffset(WIN_W, WIN_H),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = ScreenGui,
	})
	corner(BG, WIN_R)
	stroke(BG, Theme.Stroke, 0.78)
	addShadow(BG, 28 * scale, 0.55)

	local winScale = create("UIScale", { Scale = 0.96, Parent = BG })
	tween(BG, TI_S, { GroupTransparency = 0 })
	tween(winScale, TI_S, { Scale = 1 })

	------------------------------------------------------------
	-- Top bar (transparent, floats on the glass)
	------------------------------------------------------------
	local TopBar = create("Frame", {
		Name = "TopBar",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, SIDE_W, 0, 0),
		Size = UDim2.new(1, -SIDE_W, 0, TOP_H),
		Active = true,
		ZIndex = 5,
		Parent = BG,
	})

	local titleWrap = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, PAD_LARGE + 2 * scale, 0.5, 0),
		Size = UDim2.new(1, -(150 * scale), 0, 24 * scale),
		Parent = TopBar,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8 * scale),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	create("TextLabel", {
		Name = "Title", Text = cfg.Title or "Lib Name",
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = FONT_TITLE_SZ,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 1,
		Parent = titleWrap,
	})

	local tabLbl = create("TextLabel", {
		Name = "CurrentTab", Text = "",
		FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = FONT_MAIN_SZ,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 2,
		Parent = titleWrap,
	})

	local function ctrlBtn(iconName, offsetX, hoverColor)
		local b = create("TextButton", {
			Text = "", AutoButtonColor = false,
			BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offsetX * scale, 0.5, 0),
			Size = UDim2.fromOffset(32 * scale, 32 * scale),
			Parent = TopBar,
		})
		corner(b, 16 * scale)
		local ic = icon(iconName, 15 * scale, false, Theme.SubText)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
		ic.Parent = b
		b.MouseEnter:Connect(function()
			tween(b, TI, { BackgroundTransparency = CHIP_T })
			tween(ic, TI, { TextColor3 = hoverColor or Theme.Text })
		end)
		b.MouseLeave:Connect(function()
			tween(b, TI, { BackgroundTransparency = 1 })
			tween(ic, TI, { TextColor3 = Theme.SubText })
		end)
		return b
	end

	local MinBtn = ctrlBtn("minus", -14, Theme.Text)
	local YtBtn  = ctrlBtn("youtube", -52, Color3.fromRGB(255, 80, 80))
	local DcBtn  = ctrlBtn("discord", -90, Color3.fromRGB(114, 137, 248))

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

	------------------------------------------------------------
	-- Icon rail (left, full height) + power button
	------------------------------------------------------------
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
		Position = UDim2.new(0, 0, 0, 8 * scale),
		Size = UDim2.new(1, 0, 1, -(62 * scale)),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		Parent = Rail,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 8 * scale),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	create("Frame", {
		Name = "RailDivider",
		BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0, 14 * scale),
		Size = UDim2.new(0, 1, 1, -(28 * scale)),
		ZIndex = 2, Parent = Rail,
	})

	local PowerBtn = create("TextButton", {
		Text = "", AutoButtonColor = false,
		BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10 * scale),
		Size = UDim2.fromOffset(42 * scale, 42 * scale),
		Parent = Rail,
	})
	corner(PowerBtn, 14 * scale)
	local powerIc = icon("frame-collapsed", 17 * scale, false, Theme.SubText)
	powerIc.AnchorPoint = Vector2.new(0.5, 0.5)
	powerIc.Position = UDim2.new(0.5, 0, 0.5, 0)
	powerIc.Parent = PowerBtn
	PowerBtn.MouseEnter:Connect(function()
		tween(PowerBtn, TI, { BackgroundTransparency = 0.82, BackgroundColor3 = Color3.fromRGB(255, 85, 85) })
		tween(powerIc, TI, { TextColor3 = Theme.Text })
	end)
	PowerBtn.MouseLeave:Connect(function()
		tween(PowerBtn, TI, { BackgroundTransparency = 1, BackgroundColor3 = Theme.Element })
		tween(powerIc, TI, { TextColor3 = Theme.SubText })
	end)

	local Content = create("Frame", {
		Name = "Content", BackgroundTransparency = 1,
		Position = UDim2.new(0, SIDE_W, 0, TOP_H),
		Size = UDim2.new(1, -SIDE_W, 1, -TOP_H),
		Parent = BG,
	})

	makeDraggable(BG, TopBar)

	PowerBtn.Activated:Connect(function()
		tween(winScale, TI, { Scale = 0.96 })
		tween(BG, TI, { GroupTransparency = 1 })
		task.delay(0.18, function()
			Library:Destroy()
		end)
	end)

	local minimized = false
	MinBtn.Activated:Connect(function()
		minimized = not minimized
		if minimized then
			Rail.Visible = false
			Content.Visible = false
			tween(TopBar, TI_S, { Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, TOP_H) })
			tween(BG, TI_S, { Size = UDim2.fromOffset(WIN_W, TOP_H) })
		else
			tween(BG, TI_S, { Size = UDim2.fromOffset(WIN_W, WIN_H) })
			tween(TopBar, TI_S, { Position = UDim2.new(0, SIDE_W, 0, 0), Size = UDim2.new(1, -SIDE_W, 0, TOP_H) })
			task.delay(0.12, function()
				if Library._destroyed or not minimized then return end
				Rail.Visible = true
				Content.Visible = true
			end)
		end
	end)

	local hidden = false
	track(UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == (cfg.ToggleKey or Enum.KeyCode.RightShift) then
			hidden = not hidden
			BG.Visible = not hidden
		end
	end))

	----------------------------------------------------------------
	-- Tabs
	----------------------------------------------------------------
	function Window:CreateTab(tcfg)
		tcfg = tcfg or {}
		local Tab = { _order = 0 }

		local btn = create("TextButton", {
			Text = "", AutoButtonColor = false,
			BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
			Size = UDim2.fromOffset(42 * scale, 42 * scale),
			Parent = TabList,
		})
		corner(btn, 14 * scale)

		local ic = icon(tcfg.Icon or "circle", 19 * scale, false, Theme.SubText)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
		ic.Parent = btn

		local pageWrap = create("CanvasGroup", {
			Name = "Page", BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), Visible = false, GroupTransparency = 0,
			Parent = Content,
		})
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3 * scale,
			ScrollBarImageColor3 = Theme.Stroke, ScrollBarImageTransparency = 0.6,
			Parent = pageWrap,
		}, {
			create("UIListLayout", { Padding = UDim.new(0, 10 * scale), SortOrder = Enum.SortOrder.LayoutOrder }),
			create("UIPadding", {
				PaddingTop = UDim.new(0, 2 * scale),
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
				tween(t._icon, TI, { TextColor3 = Theme.SubText })
			end
			Window._current = Tab
			tabLbl.Text = "/  " .. (tcfg.Name or "Tab")
			pageWrap.Visible = true
			pageWrap.GroupTransparency = 1
			pageWrap.Position = UDim2.new(0.03, 0, 0, 0)
			tween(pageWrap, TI_S, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
			tween(btn, TI, { BackgroundTransparency = 0.85 })
			tween(ic, TI, { TextColor3 = Theme.Text })
		end

		btn.MouseEnter:Connect(function()
			if Window._current ~= Tab then tween(btn, TI, { BackgroundTransparency = 0.93 }) end
		end)
		btn.MouseLeave:Connect(function()
			if Window._current ~= Tab then tween(btn, TI, { BackgroundTransparency = 1 }) end
		end)
		btn.Activated:Connect(select)

		Tab._btn, Tab._icon, Tab._page, Tab._wrap, Tab._select = btn, ic, page, pageWrap, select
		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then select() end

		local function newRow(height)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundColor3 = Theme.Element,
				BackgroundTransparency = GLASS_T,
				Size = UDim2.new(1, 0, 0, height or ROW_H),
				LayoutOrder = Tab._order,
				BorderSizePixel = 0, Parent = page,
			})
			corner(row, CARD_R)
			stroke(row, Theme.Stroke, STROKE_T)
			return row
		end

		------------------------------------------------------------
		-- 1. Label
		------------------------------------------------------------
		function Tab:CreateLabel(text)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = Tab._order,
				BorderSizePixel = 0, Parent = page,
			})
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = text or "Label",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = FONT_SUB_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -PAD_SMALL, 0, 0),
				Position = UDim2.new(0, 4 * scale, 0, 0), Parent = row,
			})
			create("UIPadding", { PaddingTop = UDim.new(0, 2 * scale), PaddingBottom = UDim.new(0, 2 * scale), Parent = row })
			return { Set = function(_, t) lbl.Text = t end, Instance = row }
		end

		------------------------------------------------------------
		-- 2. Warning
		------------------------------------------------------------
		function Tab:CreateWarning(text)
			local row = newRow(0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			row.BackgroundColor3 = Theme.Warning
			row.BackgroundTransparency = 0.92
			for _, s in row:GetChildren() do
				if s:IsA("UIStroke") then
					s.Color = Theme.Warning
					s.Transparency = 0.55
				end
			end
			create("UIPadding", {
				PaddingTop = UDim.new(0, 10 * scale),
				PaddingBottom = UDim.new(0, 10 * scale),
				PaddingLeft = UDim.new(0, PAD_MED),
				PaddingRight = UDim.new(0, PAD_MED),
				Parent = row,
			})
			local ico = icon("triangle-exclamation", 17 * scale, false, Theme.Warning)
			ico.AnchorPoint = Vector2.new(0, 0.5)
			ico.Position = UDim2.new(0, 0, 0.5, 0)
			ico.Parent = row
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = text or "Warning",
				FontFace = FONT_MAIN, TextColor3 = Theme.Warning, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, -28 * scale, 0, 0), Position = UDim2.new(0, 28 * scale, 0, 0), Parent = row,
			})
			return { Set = function(_, t) lbl.Text = t end, Instance = row }
		end

		------------------------------------------------------------
		-- 3. Button  (label left, circular action chip right)
		------------------------------------------------------------
		function Tab:CreateButton(bcfg)
			bcfg = bcfg or {}
			Tab._order += 1
			local btnEl = create("TextButton", {
				Text = "", AutoButtonColor = false,
				BackgroundColor3 = Theme.Element, BackgroundTransparency = GLASS_T,
				Size = UDim2.new(1, 0, 0, ROW_H), LayoutOrder = Tab._order,
				BorderSizePixel = 0, Parent = page,
			})
			corner(btnEl, CARD_R)
			stroke(btnEl, Theme.Stroke, STROKE_T)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = bcfg.Name or "Button",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0),
				Size = UDim2.new(1, -(64 * scale), 1, 0), Parent = btnEl,
			})
			local chip = create("Frame", {
				BackgroundColor3 = Theme.Element, BackgroundTransparency = CHIP_T,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_SMALL, 0.5, 0),
				Size = UDim2.fromOffset(28 * scale, 28 * scale),
				BorderSizePixel = 0, Parent = btnEl,
			})
			corner(chip, 14 * scale)
			local chipIc = icon("chevron-right", 13 * scale, false, Theme.SubText)
			chipIc.AnchorPoint = Vector2.new(0.5, 0.5)
			chipIc.Position = UDim2.new(0.5, 0, 0.5, 0)
			chipIc.Parent = chip

			btnEl.MouseEnter:Connect(function()
				tween(btnEl, TI, { BackgroundTransparency = GLASS_HT })
				tween(chip, TI, { BackgroundTransparency = 0.8 })
				tween(chipIc, TI, { TextColor3 = Theme.Text })
			end)
			btnEl.MouseLeave:Connect(function()
				tween(btnEl, TI, { BackgroundTransparency = GLASS_T })
				tween(chip, TI, { BackgroundTransparency = CHIP_T })
				tween(chipIc, TI, { TextColor3 = Theme.SubText })
			end)
			btnEl.Activated:Connect(function()
				tween(chip, TI, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.15 })
				tween(chipIc, TI, { TextColor3 = Theme.Text })
				task.delay(0.14, function()
					if Library._destroyed or not chip.Parent then return end
					tween(chip, TI, { BackgroundColor3 = Theme.Element, BackgroundTransparency = CHIP_T })
					tween(chipIc, TI, { TextColor3 = Theme.SubText })
				end)
				if bcfg.Callback then task.spawn(bcfg.Callback) end
			end)
			return { Instance = btnEl }
		end

		------------------------------------------------------------
		-- 4. Toggle  (iOS-style pill)
		------------------------------------------------------------
		function Tab:CreateToggle(tocfg)
			tocfg = tocfg or {}
			local state = tocfg.Default or false
			local row = newRow(ROW_H)
			local btnEl = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = row })
			create("TextLabel", {
				BackgroundTransparency = 1, Text = tocfg.Name or "Toggle",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), Size = UDim2.new(1, -(80 * scale), 1, 0), Parent = btnEl,
			})
			local track_ = create("Frame", {
				BackgroundColor3 = state and Theme.Accent or Theme.Off,
				BackgroundTransparency = state and 0 or 0.85,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -PAD_MED, 0.5, 0),
				Size = UDim2.fromOffset(46 * scale, 26 * scale), BorderSizePixel = 0, Parent = btnEl,
			})
			corner(track_, 13 * scale)
			local knob = create("Frame", {
				BackgroundColor3 = Theme.Text, AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -(23 * scale), 0.5, 0) or UDim2.new(0, 3 * scale, 0.5, 0),
				Size = UDim2.fromOffset(20 * scale, 20 * scale), BorderSizePixel = 0, Parent = track_,
			})
			corner(knob, 10 * scale)
			addShadow(knob, 6 * scale, 0.6)

			btnEl.MouseEnter:Connect(function() tween(row, TI, { BackgroundTransparency = GLASS_HT }) end)
			btnEl.MouseLeave:Connect(function() tween(row, TI, { BackgroundTransparency = GLASS_T }) end)

			local api = {}
			function api:Set(v)
				state = v
				tween(track_, TI, {
					BackgroundColor3 = state and Theme.Accent or Theme.Off,
					BackgroundTransparency = state and 0 or 0.85,
				})
				tween(knob, TI, { Position = state and UDim2.new(1, -(23 * scale), 0.5, 0) or UDim2.new(0, 3 * scale, 0.5, 0) })
				if tocfg.Callback then task.spawn(tocfg.Callback, state) end
			end
			function api:Get() return state end
			btnEl.Activated:Connect(function() api:Set(not state) end)
			if state and tocfg.Callback then task.spawn(tocfg.Callback, true) end
			api.Instance = row
			return api
		end

		------------------------------------------------------------
		-- 5. Stat / Status
		------------------------------------------------------------
		function Tab:CreateStat(scfg)
			scfg = scfg or {}
			local row = newRow(40 * scale)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = scfg.Name or "Stat",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), Size = UDim2.new(0.5, -PAD_MED, 1, 0), Parent = row,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(scfg.Value or "-"),
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -PAD_MED, 0.5, 0),
				Size = UDim2.new(0.5, -PAD_MED, 1, 0), Parent = row,
			})
			return { Set = function(_, v) valLbl.Text = tostring(v) end, Instance = row }
		end

		------------------------------------------------------------
		-- 6. Slider
		------------------------------------------------------------
		function Tab:CreateSlider(slcfg)
			slcfg = slcfg or {}
			local min, max = slcfg.Min or 0, slcfg.Max or 100
			local inc = slcfg.Increment or 1
			local value = math.clamp(slcfg.Default or min, min, max)
			local row = newRow(56 * scale)

			create("TextLabel", {
				BackgroundTransparency = 1, Text = slcfg.Name or "Slider",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, PAD_MED, 0, 9 * scale),
				Size = UDim2.new(1, -(80 * scale), 0, 16 * scale), Parent = row,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(value),
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -PAD_MED, 0, 9 * scale),
				Size = UDim2.new(0, 60 * scale, 0, 16 * scale), Parent = row,
			})
			local trackBar = create("Frame", {
				BackgroundColor3 = Theme.Off, BackgroundTransparency = 0.85,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, PAD_MED, 1, -12 * scale),
				Size = UDim2.new(1, -(2 * PAD_MED), 0, 6 * scale),
				BorderSizePixel = 0, Parent = row,
			})
			corner(trackBar, 3 * scale)
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
				BorderSizePixel = 0, Parent = trackBar,
			})
			corner(fill, 3 * scale)
			local knob = create("Frame", {
				BackgroundColor3 = Theme.Text, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
				Size = UDim2.fromOffset(16 * scale, 16 * scale), BorderSizePixel = 0, ZIndex = 2, Parent = trackBar,
			})
			corner(knob, 8 * scale)
			addShadow(knob, 6 * scale, 0.6)

			local api = {}
			local function apply(alpha, fire)
				local raw = min + (max - min) * alpha
				value = math.clamp(math.floor(raw / inc + 0.5) * inc, min, max)
				local a = (max - min) == 0 and 0 or (value - min) / (max - min)
				fill.Size = UDim2.new(a, 0, 1, 0)
				knob.Position = UDim2.new(a, 0, 0.5, 0)
				valLbl.Text = tostring(value)
				if fire and slcfg.Callback then task.spawn(slcfg.Callback, value) end
			end
			bindDrag(trackBar, function(ax) apply(ax, true) end)
			function api:Set(v) apply((math.clamp(v, min, max) - min) / (max - min), true) end
			function api:Get() return value end
			api.Instance = row
			return api
		end

		------------------------------------------------------------
		-- 7. Textbox
		------------------------------------------------------------
		function Tab:CreateTextbox(txcfg)
			txcfg = txcfg or {}
			local row = newRow(ROW_H)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = txcfg.Name or "Textbox",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), Size = UDim2.new(0.42, -PAD_MED, 1, 0), Parent = row,
			})
			local boxWrap = create("Frame", {
				BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.92,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_SMALL, 0.5, 0),
				Size = UDim2.new(0, 0, 0, 28 * scale),
				AutomaticSize = Enum.AutomaticSize.X, ClipsDescendants = true,
				BorderSizePixel = 0, Parent = row,
			}, {
				create("UIPadding", { PaddingLeft = UDim.new(0, 10 * scale), PaddingRight = UDim.new(0, 10 * scale) }),
			})
			corner(boxWrap, 9 * scale)
			local tbStroke = stroke(boxWrap, Theme.Stroke, STROKE_T)
			local tb = create("TextBox", {
				BackgroundTransparency = 1, Text = txcfg.Default or "",
				PlaceholderText = txcfg.Placeholder or "...", PlaceholderColor3 = Theme.SubText,
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 13 * scale,
				ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Parent = boxWrap,
			}, {
				create("UISizeConstraint", {
					MinSize = Vector2.new((txcfg.MinWidth or 64) * scale, 0),
					MaxSize = Vector2.new((txcfg.MaxWidth or 200) * scale, math.huge),
				}),
			})
			tb.Focused:Connect(function() tween(tbStroke, TI, { Color = Theme.Accent, Transparency = 0.25 }) end)
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

		------------------------------------------------------------
		-- 8. Color Picker
		------------------------------------------------------------
		function Tab:CreateColorPicker(ccfg)
			ccfg = ccfg or {}
			local color = ccfg.Default or Color3.fromRGB(255, 0, 0)
			local h, s, v = color:ToHSV()

			local row = newRow(ROW_H)
			row.ClipsDescendants = true
			local header = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, ROW_H), Parent = row })
			create("TextLabel", {
				BackgroundTransparency = 1, Text = ccfg.Name or "Color",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), Size = UDim2.new(1, -(70 * scale), 1, 0), Parent = header,
			})
			local swatch = create("Frame", {
				BackgroundColor3 = color, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_MED, 0.5, 0), Size = UDim2.fromOffset(38 * scale, 20 * scale),
				BorderSizePixel = 0, Parent = header,
			})
			corner(swatch, 7 * scale)
			stroke(swatch, Theme.Stroke, 0.5)

			local body = create("Frame", {
				BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, ROW_H),
				Size = UDim2.new(1, 0, 0, 140 * scale), Visible = false, Parent = row,
			})
			create("UIPadding", {
				PaddingLeft = UDim.new(0, PAD_MED),
				PaddingRight = UDim.new(0, PAD_MED),
				PaddingBottom = UDim.new(0, PAD_MED),
				Parent = body,
			})

			local sv = create("Frame", {
				BackgroundColor3 = Color3.fromHSV(h, 1, 1), Size = UDim2.new(1, -(36 * scale), 1, 0),
				BorderSizePixel = 0, Parent = body,
			})
			corner(sv, 10 * scale)
			create("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, Parent = sv }, {
				create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }),
				create("UICorner", { CornerRadius = UDim.new(0, 10 * scale) }),
			})
			create("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, Parent = sv }, {
				create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0, 0, 0)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }),
				create("UICorner", { CornerRadius = UDim.new(0, 10 * scale) }),
			})
			local svCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0), Size = UDim2.fromOffset(10 * scale, 10 * scale),
				BorderSizePixel = 0, ZIndex = 5, Parent = sv,
			})
			corner(svCursor, 5 * scale)
			stroke(svCursor, Color3.new(0, 0, 0), 0.25)

			local hue = create("Frame", {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 24 * scale, 1, 0), BorderSizePixel = 0, Parent = body,
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
				BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, h, 0), Size = UDim2.new(1, 4 * scale, 0, 5 * scale),
				BorderSizePixel = 0, ZIndex = 5, Parent = hue,
			})
			corner(hueCursor, 2 * scale)
			stroke(hueCursor, Color3.new(0, 0, 0), 0.25)

			local function refresh(fire)
				color = Color3.fromHSV(h, s, v)
				sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				hueCursor.Position = UDim2.new(0.5, 0, h, 0)
				swatch.BackgroundColor3 = color
				if fire and ccfg.Callback then task.spawn(ccfg.Callback, color) end
			end
			bindDrag(sv, function(ax, ay) s = ax; v = 1 - ay; refresh(true) end)
			bindDrag(hue, function(_, ay) h = ay; refresh(true) end)

			header.MouseEnter:Connect(function() tween(row, TI, { BackgroundTransparency = GLASS_HT }) end)
			header.MouseLeave:Connect(function() tween(row, TI, { BackgroundTransparency = GLASS_T }) end)

			local open = false
			header.Activated:Connect(function()
				open = not open
				if open then body.Visible = true end
				tween(row, TI_S, { Size = UDim2.new(1, 0, 0, open and (ROW_H + 140 * scale) or ROW_H) })
				if not open then
					task.delay(0.12, function()
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

		------------------------------------------------------------
		-- 9. Dropdown
		------------------------------------------------------------
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
			local header = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, ROW_H), Parent = row })
			create("TextLabel", {
				BackgroundTransparency = 1, Text = dcfg.Name or "Dropdown",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), Size = UDim2.new(0.45, 0, 1, 0), Parent = header,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = "",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = FONT_SUB_SZ,
				TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(36 * scale), 0.5, 0),
				Size = UDim2.new(0.45, -(10 * scale), 1, 0), Parent = header,
			})
			local chev = icon("chevron-down", 15 * scale, false, Theme.SubText)
			chev.AnchorPoint = Vector2.new(1, 0.5)
			chev.Position = UDim2.new(1, -PAD_MED, 0.5, 0)
			chev.Parent = header

			local list = create("Frame", {
				BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, ROW_H),
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false, Parent = row,
			}, {
				create("UIListLayout", { Padding = UDim.new(0, 3 * scale), SortOrder = Enum.SortOrder.LayoutOrder }),
				create("UIPadding", {
					PaddingTop = UDim.new(0, 2 * scale),
					PaddingLeft = UDim.new(0, PAD_SMALL),
					PaddingRight = UDim.new(0, PAD_SMALL),
					PaddingBottom = UDim.new(0, 10 * scale),
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
						Text = "", AutoButtonColor = false,
						BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.95,
						Size = UDim2.new(1, 0, 0, 30 * scale), LayoutOrder = i, BorderSizePixel = 0, Parent = list,
					})
					corner(ob, 9 * scale)
					local txt = create("TextLabel", {
						BackgroundTransparency = 1, Text = opt, FontFace = FONT_MAIN,
						TextColor3 = selected[opt] and Theme.Accent or Theme.SubText, TextSize = FONT_SUB_SZ,
						TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, PAD_MED, 0, 0),
						Size = UDim2.new(1, -(34 * scale), 1, 0), Parent = ob,
					})
					local check = icon("check", 13 * scale, false, Theme.Accent)
					check.AnchorPoint = Vector2.new(1, 0.5)
					check.Position = UDim2.new(1, -PAD_MED, 0.5, 0)
					check.Visible = selected[opt] == true
					check.Parent = ob

					ob.MouseEnter:Connect(function() tween(ob, TI, { BackgroundTransparency = 0.9 }) end)
					ob.MouseLeave:Connect(function() tween(ob, TI, { BackgroundTransparency = 0.95 }) end)
					ob.Activated:Connect(function()
						if multi then
							selected[opt] = not selected[opt]
						else
							table.clear(selected)
							selected[opt] = true
						end
						for _, b in optionBtns do
							local on = selected[b.opt] == true
							b.check.Visible = on
							tween(b.txt, TI, { TextColor3 = on and Theme.Accent or Theme.SubText })
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
							task.wait(0.05)
							api._toggle(false)
						end
					end)
					table.insert(optionBtns, { btn = ob, opt = opt, txt = txt, check = check })
				end
				updateValLabel()
			end

			local function openHeight()
				local n = #options
				if n == 0 then return ROW_H + 16 * scale end
				return ROW_H + (12 * scale) + (n * 30 * scale) + ((n - 1) * 3 * scale)
			end

			local open = false
			function api._toggle(force)
				if Library._destroyed then return end
				if force ~= nil then open = force else open = not open end
				if open then list.Visible = true end
				tween(row, TI_S, { Size = UDim2.new(1, 0, 0, open and openHeight() or ROW_H) })
				tween(chev, TI, { Rotation = open and 180 or 0 })
				if not open then
					task.delay(0.12, function()
						if not open and not Library._destroyed then list.Visible = false end
					end)
				end
			end
			header.Activated:Connect(function() api._toggle() end)

			header.MouseEnter:Connect(function() tween(row, TI, { BackgroundTransparency = GLASS_HT }) end)
			header.MouseLeave:Connect(function() tween(row, TI, { BackgroundTransparency = GLASS_T }) end)

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
