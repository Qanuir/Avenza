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
-- Theme
----------------------------------------------------------------------
local Theme = {
	Background   = Color3.fromRGB(13, 13, 17),
	Secondary    = Color3.fromRGB(20, 20, 26),
	Element      = Color3.fromRGB(255, 255, 255),
	ElementHover = Color3.fromRGB(255, 255, 255),
	Off          = Color3.fromRGB(255, 255, 255),
	Stroke       = Color3.fromRGB(255, 255, 255),
	Text         = Color3.fromRGB(246, 247, 255),
	SubText      = Color3.fromRGB(148, 150, 166),
	Warning      = Color3.fromRGB(255, 205, 110),
	Success      = Color3.fromRGB(120, 220, 150),
	Error        = Color3.fromRGB(255, 100, 105),
	Accent       = Color3.fromRGB(110, 141, 255),
	AccentDark   = Color3.fromRGB(150, 100, 255),
}

local GLASS_T  = 0.955
local GLASS_HT = 0.915
local CHIP_T   = 0.90
local STROKE_T = 0.925

local SHADOW_IMG = "rbxassetid://6014261993"
local BUILDER_ICONS = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"
local FONT_TITLE = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_MAIN  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

local TI    = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_S  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_R  = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

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

local function gradient(parent, c1, c2, rotation)
	return create("UIGradient", {
		Rotation = rotation or 45,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c1),
			ColorSequenceKeypoint.new(1, c2),
		}),
		Parent = parent,
	})
end

local function accentGradient(parent, rotation)
	return gradient(parent, Theme.Accent, Theme.AccentDark, rotation or 45)
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
		BackgroundTransparency = 0.88,
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
	local ok, face = pcall(function()
		return Font.new(BUILDER_ICONS, filled and Enum.FontWeight.Bold or Enum.FontWeight.Regular)
	end)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Text = ok and (name or "") or "?",
		FontFace = (ok and face) or Font.fromEnum(filled and Enum.Font.GothamBold or Enum.Font.GothamMedium),
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
	end
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
	for _, name in { "VaehzUI", "AvenzaUI" } do
		local stale = GuiParent:FindFirstChild(name)
		if stale then pcall(function() stale:Destroy() end) end
	end
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

local NotifHolder = create("Frame", {
	Name = "Notifications",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 280, 1, -32),
	Parent = ScreenGui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

----------------------------------------------------------------------
-- Tooltip manager
----------------------------------------------------------------------
local Tooltip = {}
do
	local tip = create("Frame", {
		Name = "Tooltip",
		BackgroundColor3 = Color3.fromRGB(24, 24, 30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = false,
		ZIndex = 50,
		Parent = ScreenGui,
	})
	corner(tip, 8)
	local tipStroke = stroke(tip, Theme.Stroke, 1)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		Parent = tip,
	})
	local tipDot = create("Frame", {
		BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(4, 4),
		BorderSizePixel = 0, ZIndex = 51, Parent = tip,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = tipDot })
	local tipLbl = create("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 12,
		TextTransparency = 1,
		Position = UDim2.new(0, 9, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = 51, Parent = tip,
	})

	local hoverObj, token = nil, 0
	local function hide()
		token += 1
		hoverObj = nil
		tween(tip, TI, { BackgroundTransparency = 1 })
		tween(tipStroke, TI, { Transparency = 1 })
		tween(tipLbl, TI, { TextTransparency = 1 })
		tween(tipDot, TI, { BackgroundTransparency = 1 })
		task.delay(0.17, function()
			if not hoverObj and not Library._destroyed then tip.Visible = false end
		end)
	end
	track(UserInputService.InputChanged:Connect(function(inp)
		if hoverObj and tip.Visible and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local mp = UserInputService:GetMouseLocation()
			local maxX = tip.Parent.AbsoluteSize.X
			local x = mp.X + 14
			if tip.AbsoluteSize.X > 0 and x + tip.AbsoluteSize.X > maxX - 8 then
				x = maxX - tip.AbsoluteSize.X - 8
			end
			tip.Position = UDim2.fromOffset(x, mp.Y + 12)
		end
	end))

	function Tooltip.Attach(obj, text)
		if type(text) ~= "string" or text == "" then return end
		track(obj.MouseEnter:Connect(function()
			hoverObj = obj
			token += 1
			local my = token
			task.delay(0.4, function()
				if Library._destroyed or hoverObj ~= obj or token ~= my then return end
				tipLbl.Text = text
				local mp = UserInputService:GetMouseLocation()
				tip.Position = UDim2.fromOffset(mp.X + 14, mp.Y + 12)
				tip.Visible = true
				tween(tip, TI, { BackgroundTransparency = 0.04 })
				tween(tipStroke, TI, { Transparency = STROKE_T })
				tween(tipLbl, TI, { TextTransparency = 0 })
				tween(tipDot, TI, { BackgroundTransparency = 0 })
			end)
		end))
		track(obj.MouseLeave:Connect(hide))
		pcall(function() track(obj.MouseButton1Down:Connect(hide)) end)
	end
end

----------------------------------------------------------------------
-- Notifications (typed: info / success / warning / error + progress)
----------------------------------------------------------------------
local NOTIFY_KINDS = {
	info    = { Icon = "circle",               Color = Theme.Accent,  Filled = true  },
	success = { Icon = "check",                Color = Theme.Success, Filled = false },
	warning = { Icon = "triangle-exclamation", Color = Theme.Warning, Filled = false },
	error   = { Icon = "x",                    Color = Theme.Error,   Filled = false },
}

function Library:Notify(cfg)
	if Library._destroyed then return end
	cfg = cfg or {}
	local dur = cfg.Duration or 4
	local nscale = Library._scale or 1
	local kind = NOTIFY_KINDS[string.lower(cfg.Type or "info")] or NOTIFY_KINDS.info

	local card = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(20, 20, 26),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 280 * nscale, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = NotifHolder,
	})
	corner(card, 14 * nscale)
	local st = stroke(card, Theme.Stroke, 1)

	local iconChip = create("Frame", {
		BackgroundColor3 = kind.Color,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 12 * nscale, 0, 12 * nscale),
		Size = UDim2.fromOffset(28 * nscale, 28 * nscale),
		BorderSizePixel = 0,
		Parent = card,
	})
	corner(iconChip, 9 * nscale)
	local chipIc = icon(kind.Icon, 13 * nscale, kind.Filled, kind.Color)
	chipIc.AnchorPoint = Vector2.new(0.5, 0.5)
	chipIc.Position = UDim2.new(0.5, 0, 0.5, 0)
	chipIc.Parent = iconChip

	local content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 50 * nscale, 0, 0),
		Size = UDim2.new(1, -(62 * nscale), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 11 * nscale), PaddingBottom = UDim.new(0, 13 * nscale) }),
	})

	local titleLbl = create("TextLabel", {
		BackgroundTransparency = 1, Text = cfg.Title or "Notification", TextTransparency = 1,
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 13.5 * nscale,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1, Parent = content,
	})
	local bodyLbl
	if cfg.Content then
		bodyLbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = cfg.Content, TextTransparency = 1,
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12 * nscale,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2, Parent = content,
		})
	end

	-- progress bar
	local progTrack = create("Frame", {
		BackgroundColor3 = Theme.Off, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		Parent = card,
	})
	local prog = create("Frame", {
		BackgroundColor3 = kind.Color, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		Parent = progTrack,
	})
	corner(prog, 2)

	local pop = create("UIScale", { Scale = 0.96, Parent = card })
	tween(pop, TI_S, { Scale = 1 })
	tween(card, TI_S, { BackgroundTransparency = 0.04 })
	tween(st, TI_S, { Transparency = 0.9 })
	tween(iconChip, TI_S, { BackgroundTransparency = 0.88 })
	tween(titleLbl, TI_S, { TextTransparency = 0 })
	tween(progTrack, TI_S, { BackgroundTransparency = 0.9 })
	tween(prog, TI_S, { BackgroundTransparency = 0.2 })
	if bodyLbl then tween(bodyLbl, TI_S, { TextTransparency = 0 }) end

	tween(prog, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) })

	task.delay(dur, function()
		if Library._destroyed or not card.Parent then return end
		tween(pop, TI, { Scale = 0.96 })
		tween(card, TI, { BackgroundTransparency = 1 })
		tween(st, TI, { Transparency = 1 })
		tween(iconChip, TI, { BackgroundTransparency = 1 })
		tween(titleLbl, TI, { TextTransparency = 1 })
		tween(progTrack, TI, { BackgroundTransparency = 1 })
		tween(prog, TI, { BackgroundTransparency = 1 })
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
	do -- derive gradient partner from accent
		local h, s, v = Theme.Accent:ToHSV()
		Theme.AccentDark = Color3.fromHSV((h + 0.075) % 1, math.clamp(s * 1.02, 0, 1), math.clamp(v * 0.92, 0, 1))
	end

	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local vpW, vpH = vp.X, vp.Y

	local BASE_W, BASE_H = 580, 400
	local scale = cfg.Scale or 0.8
	Library._scale = scale

	local WIN_W = BASE_W * scale
	local WIN_H = BASE_H * scale
	local TOP_H = 56 * scale
	local SIDE_W = 66 * scale
	local ROW_H = 44 * scale
	local WIN_R = 18 * scale
	local CARD_R = 12 * scale
	local FONT_TITLE_SZ = 16.5 * scale
	local FONT_MAIN_SZ = 14 * scale
	local FONT_SUB_SZ = 12 * scale
	local PAD_SMALL = 8 * scale
	local PAD_MED = 12 * scale
	local PAD_LARGE = 14 * scale

	local Window = { Tabs = {}, _current = nil }

	local startX = vpW * 0.5 - WIN_W * 0.5
	local startY = vpH * 0.12

	-- soft drop shadow (sibling, synced to window)
	local Shadow = create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = SHADOW_IMG,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(startX + WIN_W * 0.5, startY + WIN_H * 0.5 + 8 * scale),
		Size = UDim2.fromOffset(WIN_W + 110 * scale, WIN_H + 110 * scale),
		ZIndex = 0,
		Parent = ScreenGui,
	})

	local BG = create("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(startX, startY + 14 * scale),
		Size = UDim2.fromOffset(WIN_W, WIN_H),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		Active = true,
		GroupTransparency = 1,
		ZIndex = 1,
		Parent = ScreenGui,
	})
	corner(BG, WIN_R)
	stroke(BG, Theme.Stroke, 0.85)

	-- subtle background gradient for depth
	gradient(BG, Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 215), 90).Transparency =
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.985),
			NumberSequenceKeypoint.new(1, 1),
		})

	-- top sheen line
	local sheen = create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Position = UDim2.new(0, WIN_R, 0, 0),
		Size = UDim2.new(1, -WIN_R * 2, 0, 1),
		ZIndex = 3,
		Parent = BG,
	})
	gradient(sheen, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 0).Transparency =
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})

	local winScale = create("UIScale", { Scale = 0.965, Parent = BG })
	tween(BG, TI_S, { GroupTransparency = 0, Position = UDim2.fromOffset(startX, startY) })
	tween(winScale, TI_S, { Scale = 1 })
	tween(Shadow, TI_S, { ImageTransparency = 0.55 })

	-- keep shadow glued to the window
	track(RunService.Heartbeat:Connect(function()
		if Library._destroyed or not BG.Parent then return end
		local abs = BG.AbsoluteSize
		Shadow.Visible = BG.Visible
		Shadow.Position = UDim2.new(
			BG.Position.X.Scale, BG.Position.X.Offset + abs.X * 0.5,
			BG.Position.Y.Scale, BG.Position.Y.Offset + abs.Y * 0.5 + 8 * scale
		)
		Shadow.Size = UDim2.fromOffset(abs.X + 110 * scale, abs.Y + 110 * scale)
		Shadow.ImageTransparency = 0.55 + BG.GroupTransparency * 0.45
	end))

	----------------------------------------------------------------------
	-- Top bar
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

	local CTRL_SZ = 30 * scale
	local CTRL_GAP = CTRL_SZ + 6 * scale

	local ctrlReserve = CTRL_GAP * 3 + 12 * scale

	local titleWrap = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, PAD_LARGE + 2 * scale, 0.5, 0),
		Size = UDim2.new(1, -ctrlReserve, 0, 30 * scale),
		Parent = TopBar,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 9 * scale),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- logo mark
	local logo = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.fromOffset(26 * scale, 26 * scale),
		LayoutOrder = 1,
		BorderSizePixel = 0,
		Parent = titleWrap,
	})
	corner(logo, 8 * scale)
	accentGradient(logo, 55)
	local logoSheen = create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0.45, 0),
		Parent = logo,
	})
	corner(logoSheen, 8 * scale)
	gradient(logoSheen, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 90).Transparency =
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.75),
			NumberSequenceKeypoint.new(1, 1),
		})
	if cfg.Logo then
		local li = icon(cfg.Logo, 14 * scale, true, Color3.new(1, 1, 1))
		li.AnchorPoint = Vector2.new(0.5, 0.5)
		li.Position = UDim2.new(0.5, 0, 0.5, 0)
		li.ZIndex = 2
		li.Parent = logo
	end

	create("TextLabel", {
		Name = "Title", Text = cfg.Title or "Lib Name",
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = FONT_TITLE_SZ,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 2,
		Parent = titleWrap,
	})

	local tabLbl = create("TextLabel", {
		Name = "CurrentTab", Text = "",
		FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = FONT_MAIN_SZ,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 3,
		Parent = titleWrap,
	})

	local function ctrlBtn(iconName, slotIndex, hoverColor)
		local offsetX = -(slotIndex - 1) * CTRL_GAP - CTRL_SZ * 0.5 - 8 * scale
		local b = create("TextButton", {
			Text = "", AutoButtonColor = false, Selectable = true,
			BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offsetX, 0.5, 0),
			Size = UDim2.fromOffset(CTRL_SZ, CTRL_SZ),
			Parent = TopBar,
		})
		corner(b, CTRL_SZ * 0.5)
		local bScale = create("UIScale", { Scale = 1, Parent = b })
		b.MouseButton1Down:Connect(function() tween(bScale, TI, { Scale = 0.8 }) end)
		b.MouseButton1Up:Connect(function() tween(bScale, TI_S, { Scale = 1 }) end)
		local ic = icon(iconName, 13 * scale, false, Theme.SubText)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
		ic.Parent = b
		b.MouseEnter:Connect(function()
			tween(b, TI, { BackgroundTransparency = CHIP_T })
			tintIcon(ic, hoverColor or Theme.Text)
		end)
		b.MouseLeave:Connect(function()
			tween(b, TI, { BackgroundTransparency = 1 })
			tintIcon(ic, Theme.SubText)
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

	local YT_LINK = cfg.YouTube or "https://youtube.com/@Qanuir"
	local DC_LINK = cfg.Discord or "https://discord.gg/Qanuir"
	local DC_CODE = DC_LINK:match("([^/]+)$") or "Qanuir"

	YtBtn.Activated:Connect(function()
		local copied = copyToClipboard(YT_LINK)
		Library:Notify({
			Title = "YouTube", Type = "info",
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
		Library:Notify({ Title = "Discord", Type = "info", Content = msg, Duration = 3 })
	end)

	----------------------------------------------------------------------
	-- Icon rail
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
		Size = UDim2.new(1, 0, 1, -(64 * scale)),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		Selectable = true,
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
		BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0, 16 * scale),
		Size = UDim2.new(0, 1, 1, -(32 * scale)),
		ZIndex = 2, Parent = Rail,
	})

	local PWR_SZ = 40 * scale
	local PowerBtn = create("TextButton", {
		Text = "", AutoButtonColor = false, Selectable = true,
		BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12 * scale),
		Size = UDim2.fromOffset(PWR_SZ, PWR_SZ),
		Parent = Rail,
	})
	corner(PowerBtn, 12 * scale)
	Tooltip.Attach(PowerBtn, "Unload UI")
	local pwrScale = create("UIScale", { Scale = 1, Parent = PowerBtn })
	PowerBtn.MouseButton1Down:Connect(function() tween(pwrScale, TI, { Scale = 0.85 }) end)
	PowerBtn.MouseButton1Up:Connect(function() tween(pwrScale, TI_S, { Scale = 1 }) end)
	local powerIc = icon("x", 15 * scale, false, Theme.SubText)
	powerIc.AnchorPoint = Vector2.new(0.5, 0.5)
	powerIc.Position = UDim2.new(0.5, 0, 0.5, 0)
	powerIc.Parent = PowerBtn
	PowerBtn.MouseEnter:Connect(function()
		tween(PowerBtn, TI, { BackgroundTransparency = 0.85, BackgroundColor3 = Theme.Error })
		tintIcon(powerIc, Theme.Text)
	end)
	PowerBtn.MouseLeave:Connect(function()
		tween(PowerBtn, TI, { BackgroundTransparency = 1, BackgroundColor3 = Theme.Element })
		tintIcon(powerIc, Theme.SubText)
		tween(pwrScale, TI, { Scale = 1 })
	end)

	local Content = create("Frame", {
		Name = "Content", BackgroundTransparency = 1,
		Position = UDim2.new(0, SIDE_W, 0, TOP_H),
		Size = UDim2.new(1, -SIDE_W, 1, -TOP_H),
		Parent = BG,
	})

	makeDraggable(BG, TopBar)

	PowerBtn.Activated:Connect(function()
		tween(winScale, TI, { Scale = 0.965 })
		tween(BG, TI, { GroupTransparency = 1 })
		tween(Shadow, TI, { ImageTransparency = 1 })
		task.delay(0.18, function()
			Library:Destroy()
		end)
	end)

	----------------------------------------------------------------------
	-- Minimize / restore
	----------------------------------------------------------------------
	local minimized = false
	local fullSize = UDim2.fromOffset(WIN_W, WIN_H)
	MinBtn.Activated:Connect(function()
		minimized = not minimized
		if minimized then
			Rail.Visible = false
			Content.Visible = false
			tween(TopBar, TI_S, { Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, TOP_H) })
			tween(BG, TI_S, { Size = UDim2.fromOffset(fullSize.X.Offset, TOP_H) })
		else
			tween(BG, TI_S, { Size = fullSize })
			tween(TopBar, TI_S, { Position = UDim2.new(0, SIDE_W, 0, 0), Size = UDim2.new(1, -SIDE_W, 0, TOP_H) })
			task.delay(0.12, function()
				if Library._destroyed or minimized then return end
				Rail.Visible = true
				Content.Visible = true
			end)
		end
	end)

	----------------------------------------------------------------------
	-- Hide / show
	----------------------------------------------------------------------
	local hidden = false

	local function setHidden(h)
		if hidden == h then return end
		hidden = h
		if h then
			tween(winScale, TI, { Scale = 0.97 })
			tween(BG, TI, { GroupTransparency = 1 })
			task.delay(0.18, function()
				if hidden and not Library._destroyed then BG.Visible = false end
			end)
		else
			BG.Visible = true
			tween(winScale, TI_S, { Scale = 1 })
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
	-- Tabs
	----------------------------------------------------------------------
	function Window:CreateTab(tcfg)
		tcfg = tcfg or {}
		local Tab = { _order = 0 }

		local TAB_BTN_SZ = 40 * scale
		local btn = create("TextButton", {
			Text = "", AutoButtonColor = false, Selectable = true,
			BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
			Size = UDim2.fromOffset(TAB_BTN_SZ, TAB_BTN_SZ),
			Parent = TabList,
		})
		corner(btn, 12 * scale)
		if tcfg.Name then Tooltip.Attach(btn, tcfg.Name) end

		local btnScale = create("UIScale", { Scale = 1, Parent = btn })
		btn.MouseButton1Down:Connect(function() tween(btnScale, TI, { Scale = 0.88 }) end)
		btn.MouseButton1Up:Connect(function() tween(btnScale, TI_S, { Scale = 1 }) end)

		-- active indicator pill (left edge of rail)
		local indicator = create("Frame", {
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -(10 * scale), 0.5, 0),
			Size = UDim2.new(0, 3 * scale, 0, 0),
			Parent = btn,
		})
		corner(indicator, 2 * scale)
		accentGradient(indicator, 90)

		local ic = icon(tcfg.Icon or "circle", 18 * scale, false, Theme.SubText)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
		ic.Parent = btn

		local badge = create("Frame", {
			BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -3 * scale, 0, 3 * scale),
			Size = UDim2.fromOffset(7 * scale, 7 * scale),
			Visible = false, ZIndex = 3, Parent = btn,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badge })
		accentGradient(badge, 45)
		stroke(badge, Theme.Background, 0, 1.5 * scale)

		local pageWrap = create("CanvasGroup", {
			Name = "Page", BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), Visible = false, GroupTransparency = 0,
			Parent = Content,
		})
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2 * scale,
			ScrollBarImageColor3 = Theme.Stroke, ScrollBarImageTransparency = 0.7,
			Selectable = true,
			Parent = pageWrap,
		}, {
			create("UIListLayout", { Padding = UDim.new(0, 8 * scale), SortOrder = Enum.SortOrder.LayoutOrder }),
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
				tween(t._indicator, TI_S, { BackgroundTransparency = 1, Size = UDim2.new(0, 3 * scale, 0, 0) })
				tintIcon(t._icon, Theme.SubText)
			end
			Window._current = Tab
			badge.Visible = false
			tabLbl.Text = "/  " .. (tcfg.Name or "Tab")
			pageWrap.Visible = true
			pageWrap.GroupTransparency = 1
			pageWrap.Position = UDim2.new(0.025, 0, 0, 0)
			tween(pageWrap, TI_S, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
			tween(btn, TI, { BackgroundTransparency = 0.9 })
			tween(indicator, TI_S, { BackgroundTransparency = 0, Size = UDim2.new(0, 3 * scale, 0.45, 0) })
			tintIcon(ic, Theme.Text)
		end

		btn.MouseEnter:Connect(function()
			if Window._current ~= Tab then
				tween(btn, TI, { BackgroundTransparency = 0.94 })
				tintIcon(ic, Theme.Text)
			end
		end)
		btn.MouseLeave:Connect(function()
			if Window._current ~= Tab then
				tween(btn, TI, { BackgroundTransparency = 1 })
				tintIcon(ic, Theme.SubText)
			end
			tween(btnScale, TI, { Scale = 1 })
		end)
		btn.Activated:Connect(function()
			ripple(btn, Theme.Accent)
			select()
		end)

		Tab._btn, Tab._icon, Tab._page, Tab._wrap, Tab._select, Tab._indicator = btn, ic, page, pageWrap, select, indicator
		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then select() end

		function Tab:SetBadge(v)
			badge.Visible = (v == true) and Window._current ~= Tab
		end

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

		local function rowHover(row, rowStroke)
			return function()
				tween(row, TI, { BackgroundTransparency = GLASS_HT })
				if rowStroke then tween(rowStroke, TI, { Color = Theme.Accent, Transparency = 0.65 }) end
			end, function()
				tween(row, TI, { BackgroundTransparency = GLASS_T })
				if rowStroke then tween(rowStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T }) end
			end
		end

		----------------------------------------------------------------------
		-- 1. Label
		----------------------------------------------------------------------
		function Tab:CreateLabel(text)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = Tab._order,
				BorderSizePixel = 0, Parent = page,
			})
			local accentTick = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 4 * scale, 0, 0.5 * 0 + 9 * scale),
				Size = UDim2.new(0, 3 * scale, 0, 12 * scale),
				Parent = row,
			})
			corner(accentTick, 2 * scale)
			accentGradient(accentTick, 90)
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = text or "Label",
				FontFace = FONT_TITLE, TextColor3 = Theme.SubText, TextSize = FONT_SUB_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -(18 * scale), 0, 0),
				Position = UDim2.new(0, 14 * scale, 0, 0), Parent = row,
			})
			create("UIPadding", { PaddingTop = UDim.new(0, 4 * scale), PaddingBottom = UDim.new(0, 2 * scale), Parent = row })
			return { Set = function(_, t) lbl.Text = t end, Instance = row }
		end

		----------------------------------------------------------------------
		-- 2. Warning
		----------------------------------------------------------------------
		function Tab:CreateWarning(text)
			local row = newRow(0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			row.BackgroundColor3 = Theme.Warning
			row.BackgroundTransparency = 0.94
			for _, s in row:GetChildren() do
				if s:IsA("UIStroke") then
					s.Color = Theme.Warning
					s.Transparency = 0.6
				end
			end
			gradient(row, Theme.Warning, Theme.Warning, 0).Transparency =
				NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 0.6),
				})
			create("UIPadding", {
				PaddingTop = UDim.new(0, 10 * scale),
				PaddingBottom = UDim.new(0, 10 * scale),
				PaddingLeft = UDim.new(0, PAD_MED),
				PaddingRight = UDim.new(0, PAD_MED),
				Parent = row,
			})
			local ico = icon("triangle-exclamation", 16 * scale, false, Theme.Warning)
			ico.AnchorPoint = Vector2.new(0, 0.5)
			ico.Position = UDim2.new(0, 0, 0.5, 0)
			ico.Parent = row
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = text or "Warning",
				FontFace = FONT_MAIN, TextColor3 = Theme.Warning, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, -(28 * scale), 0, 0), Position = UDim2.new(0, 28 * scale, 0, 0), Parent = row,
			})
			return { Set = function(_, t) lbl.Text = t end, Instance = row }
		end

		----------------------------------------------------------------------
		-- 3. Button
		----------------------------------------------------------------------
		function Tab:CreateButton(bcfg)
			bcfg = bcfg or {}
			Tab._order += 1
			local btnEl = create("TextButton", {
				Text = "", AutoButtonColor = false, Selectable = true,
				BackgroundColor3 = Theme.Element, BackgroundTransparency = GLASS_T,
				Size = UDim2.new(1, 0, 0, ROW_H), LayoutOrder = Tab._order,
				BorderSizePixel = 0, Parent = page,
			})
			corner(btnEl, CARD_R)
			local btnStroke = stroke(btnEl, Theme.Stroke, STROKE_T)
			if bcfg.Tooltip then Tooltip.Attach(btnEl, bcfg.Tooltip) end
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
				Size = UDim2.fromOffset(26 * scale, 26 * scale),
				BorderSizePixel = 0, Parent = btnEl,
			})
			corner(chip, 13 * scale)
			local chipStroke = stroke(chip, Theme.Stroke, 0.92)
			local chipIc = icon("chevron-right", 12 * scale, false, Theme.SubText)
			chipIc.AnchorPoint = Vector2.new(0.5, 0.5)
			chipIc.Position = UDim2.new(0.5, 0, 0.5, 0)
			chipIc.Parent = chip

			btnEl.MouseEnter:Connect(function()
				tween(btnEl, TI, { BackgroundTransparency = GLASS_HT })
				tween(btnStroke, TI, { Color = Theme.Accent, Transparency = 0.55 })
				tween(chip, TI, { BackgroundTransparency = 0.82 })
				tween(chipStroke, TI, { Transparency = 0.7 })
				tween(chipIc, TI_S, { Position = UDim2.new(0.5, 2 * scale, 0.5, 0) })
				tintIcon(chipIc, Theme.Text)
			end)
			btnEl.MouseLeave:Connect(function()
				tween(btnEl, TI, { BackgroundTransparency = GLASS_T })
				tween(btnStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				tween(chip, TI, { BackgroundTransparency = CHIP_T })
				tween(chipStroke, TI, { Transparency = 0.92 })
				tween(chipIc, TI_S, { Position = UDim2.new(0.5, 0, 0.5, 0) })
				tintIcon(chipIc, Theme.SubText)
			end)
			btnEl.Activated:Connect(function()
				ripple(btnEl, Theme.Accent)
				tween(chip, TI, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.1 })
				tween(chipStroke, TI, { Transparency = 1 })
				tintIcon(chipIc, Color3.new(1, 1, 1))
				task.delay(0.16, function()
					if Library._destroyed or not chip.Parent then return end
					tween(chip, TI, { BackgroundColor3 = Theme.Element, BackgroundTransparency = CHIP_T })
					tween(chipStroke, TI, { Transparency = 0.92 })
					tintIcon(chipIc, Theme.SubText)
				end)
				if bcfg.Callback then task.spawn(bcfg.Callback) end
			end)
			return { Instance = btnEl }
		end

		----------------------------------------------------------------------
		-- 4. Toggle
		----------------------------------------------------------------------
		function Tab:CreateToggle(tocfg)
			tocfg = tocfg or {}
			local state = tocfg.Default or false
			local row = newRow(ROW_H)
			local rowStroke = row:FindFirstChildOfClass("UIStroke")
			local btnEl = create("TextButton", {
				Text = "", BackgroundTransparency = 1, Selectable = true,
				Size = UDim2.new(1, 0, 1, 0), Parent = row,
			})
			if tocfg.Tooltip then Tooltip.Attach(btnEl, tocfg.Tooltip) end
			create("TextLabel", {
				BackgroundTransparency = 1, Text = tocfg.Name or "Toggle",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), Size = UDim2.new(1, -(80 * scale), 1, 0), Parent = btnEl,
			})
			local track_ = create("Frame", {
				BackgroundColor3 = state and Theme.Accent or Theme.Off,
				BackgroundTransparency = state and 0 or 0.88,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -PAD_MED, 0.5, 0),
				Size = UDim2.fromOffset(42 * scale, 23 * scale), BorderSizePixel = 0, Parent = btnEl,
			})
			corner(track_, 12 * scale)
			local trackGrad = accentGradient(track_, 0)
			trackGrad.Enabled = state
			local trackStroke = stroke(track_, Theme.Stroke, state and 1 or 0.88)

			local knob = create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -(20 * scale), 0.5, 0) or UDim2.new(0, 3 * scale, 0.5, 0),
				Size = UDim2.fromOffset(17 * scale, 17 * scale), BorderSizePixel = 0, Parent = track_,
			})
			corner(knob, 9 * scale)
			stroke(knob, Color3.new(0, 0, 0), 0.85)
			local knobScale = create("UIScale", { Scale = 1, Parent = knob })

			local enter, leave = rowHover(row, rowStroke)
			btnEl.MouseEnter:Connect(enter)
			btnEl.MouseLeave:Connect(leave)
			btnEl.MouseButton1Down:Connect(function() tween(knobScale, TI, { Scale = 0.8 }) end)
			btnEl.MouseButton1Up:Connect(function() tween(knobScale, TI_S, { Scale = 1 }) end)

			local api = {}
			function api:Set(v)
				state = v
				trackGrad.Enabled = state
				tween(track_, TI, {
					BackgroundColor3 = state and Theme.Accent or Theme.Off,
					BackgroundTransparency = state and 0 or 0.88,
				})
				tween(trackStroke, TI, { Transparency = state and 1 or 0.88 })
				tween(knob, TI_S, { Position = state and UDim2.new(1, -(20 * scale), 0.5, 0) or UDim2.new(0, 3 * scale, 0.5, 0) })
				if tocfg.Callback then task.spawn(tocfg.Callback, state) end
			end
			function api:Get() return state end
			btnEl.Activated:Connect(function() api:Set(not state) end)
			if state and tocfg.Callback and tocfg.FireOnInit ~= false then task.spawn(tocfg.Callback, true) end
			api.Instance = row
			return api
		end

		----------------------------------------------------------------------
		-- 5. Stat
		----------------------------------------------------------------------
		function Tab:CreateStat(scfg)
			scfg = scfg or {}
			local row = newRow(40 * scale)
			if scfg.Tooltip then Tooltip.Attach(row, scfg.Tooltip) end
			create("TextLabel", {
				BackgroundTransparency = 1, Text = scfg.Name or "Stat",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), Size = UDim2.new(0.5, -PAD_MED, 1, 0), Parent = row,
			})
			local valChip = create("Frame", {
				BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.92,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -PAD_SMALL, 0.5, 0),
				Size = UDim2.new(0, 0, 0, 24 * scale),
				AutomaticSize = Enum.AutomaticSize.X,
				BorderSizePixel = 0, Parent = row,
			}, {
				create("UIPadding", { PaddingLeft = UDim.new(0, 10 * scale), PaddingRight = UDim.new(0, 10 * scale) }),
			})
			corner(valChip, 8 * scale)
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(scfg.Value or "-"),
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = FONT_SUB_SZ,
				TextXAlignment = Enum.TextXAlignment.Center,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0), Parent = valChip,
			})
			return { Set = function(_, v) valLbl.Text = tostring(v) end, Instance = row }
		end

		----------------------------------------------------------------------
		-- 6. Slider
		----------------------------------------------------------------------
		function Tab:CreateSlider(slcfg)
			slcfg = slcfg or {}
			local min, max = slcfg.Min or 0, slcfg.Max or 100
			local inc = slcfg.Increment or 1
			local value = math.clamp(slcfg.Default or min, min, max)
			local row = newRow(56 * scale)
			local rowStroke = row:FindFirstChildOfClass("UIStroke")
			if slcfg.Tooltip then Tooltip.Attach(row, slcfg.Tooltip) end

			create("TextLabel", {
				BackgroundTransparency = 1, Text = slcfg.Name or "Slider",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, PAD_MED, 0, 9 * scale),
				Size = UDim2.new(1, -(144 * scale), 0, 16 * scale), Parent = row,
			})

			local suffix = slcfg.Suffix or ""
			local function fmtVal(v) return tostring(v) .. suffix end
			local api = {}

			local valWrap = create("Frame", {
				BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -PAD_MED, 0, 7 * scale),
				Size = UDim2.fromOffset(118 * scale, 20 * scale), Parent = row,
			}, {
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 5 * scale), SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			})

			local function stepBtn(txt, delta, order)
				local b = create("TextButton", {
					Text = "", AutoButtonColor = false, Selectable = true,
					BackgroundColor3 = Theme.Element, BackgroundTransparency = CHIP_T,
					Size = UDim2.fromOffset(20 * scale, 20 * scale), LayoutOrder = order,
					BorderSizePixel = 0, Parent = valWrap,
				})
				corner(b, 7 * scale)
				local lbl = create("TextLabel", {
					BackgroundTransparency = 1, Text = txt, FontFace = FONT_TITLE,
					TextColor3 = Theme.SubText, TextSize = FONT_SUB_SZ,
					Size = UDim2.new(1, 0, 1, 0), Parent = b,
				})
				b.MouseEnter:Connect(function()
					tween(b, TI, { BackgroundTransparency = 0.8 })
					tween(lbl, TI, { TextColor3 = Theme.Text })
				end)
				b.MouseLeave:Connect(function()
					tween(b, TI, { BackgroundTransparency = CHIP_T })
					tween(lbl, TI, { TextColor3 = Theme.SubText })
				end)
				b.Activated:Connect(function()
					ripple(b, Theme.Accent)
					api:Set(value + delta)
				end)
			end

			local valBox = create("TextBox", {
				BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.93,
				Text = fmtVal(value), ClearTextOnFocus = false,
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = FONT_MAIN_SZ,
				LayoutOrder = 2, Size = UDim2.fromOffset(54 * scale, 20 * scale), Parent = valWrap,
			})
			corner(valBox, 7 * scale)
			local vbStroke = stroke(valBox, Theme.Stroke, STROKE_T)
			valBox.Focused:Connect(function() tween(vbStroke, TI, { Color = Theme.Accent, Transparency = 0.2 }) end)

			stepBtn("-", -inc, 1)
			stepBtn("+", inc, 3)

			local TRACK_H = 5 * scale
			local trackBar = create("Frame", {
				BackgroundColor3 = Theme.Off, BackgroundTransparency = 0.88,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, PAD_MED, 1, -13 * scale),
				Size = UDim2.new(1, -(2 * PAD_MED), 0, TRACK_H),
				BorderSizePixel = 0, Parent = row,
			})
			corner(trackBar, 3 * scale)
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
				BorderSizePixel = 0, Parent = trackBar,
			})
			corner(fill, 3 * scale)
			accentGradient(fill, 0)

			local KNOB_SZ = 14 * scale
			local knob = create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
				Size = UDim2.fromOffset(KNOB_SZ, KNOB_SZ), BorderSizePixel = 0, ZIndex = 2, Parent = trackBar,
			})
			corner(knob, KNOB_SZ * 0.5)
			stroke(knob, Theme.Accent, 0.4, 1.5 * scale)
			local knobScale = create("UIScale", { Scale = 1, Parent = knob })

			local function apply(alpha, fire)
				local raw = min + (max - min) * alpha
				value = math.clamp(math.floor(raw / inc + 0.5) * inc, min, max)
				local a = (max - min) == 0 and 0 or (value - min) / (max - min)
				fill.Size = UDim2.new(a, 0, 1, 0)
				knob.Position = UDim2.new(a, 0, 0.5, 0)
				valBox.Text = fmtVal(value)
				if fire and slcfg.Callback then task.spawn(slcfg.Callback, value) end
			end

			local dragging = false
			bindDrag(trackBar, function(ax, _, ended)
				if ended then
					dragging = false
					tween(knobScale, TI_S, { Scale = 1 })
					apply(ax, true)
				else
					if not dragging then
						dragging = true
						tween(knobScale, TI_S, { Scale = 1.35 })
					end
					if slcfg.Live then
						apply(ax, true)
					else
						apply(ax, false)
					end
				end
			end)

			valBox.FocusLost:Connect(function(enterPressed)
				tween(vbStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				if not enterPressed then valBox.Text = fmtVal(value); return end
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
		-- 7. Textbox
		----------------------------------------------------------------------
		function Tab:CreateTextbox(txcfg)
			txcfg = txcfg or {}
			local row = newRow(ROW_H)
			if txcfg.Tooltip then Tooltip.Attach(row, txcfg.Tooltip) end
			create("TextLabel", {
				BackgroundTransparency = 1, Text = txcfg.Name or "Textbox",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), Size = UDim2.new(0.42, -PAD_MED, 1, 0), Parent = row,
			})
			local boxWrap = create("Frame", {
				BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.93,
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
			tb.Focused:Connect(function()
				tween(tbStroke, TI, { Color = Theme.Accent, Transparency = 0.2 })
				tween(boxWrap, TI, { BackgroundTransparency = 0.88 })
			end)
			tb.FocusLost:Connect(function()
				tween(tbStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				tween(boxWrap, TI, { BackgroundTransparency = 0.93 })
				if txcfg.Callback then task.spawn(txcfg.Callback, tb.Text) end
			end)
			return {
				Set = function(_, t) tb.Text = t end,
				Get = function() return tb.Text end,
				Instance = row,
			}
		end

		----------------------------------------------------------------------
		-- 8. Color Picker
		----------------------------------------------------------------------
		function Tab:CreateColorPicker(ccfg)
			ccfg = ccfg or {}
			local color = ccfg.Default or Color3.fromRGB(255, 0, 0)
			local h, s, v = color:ToHSV()

			local row = newRow(ROW_H)
			row.ClipsDescendants = true
			local rowStroke = row:FindFirstChildOfClass("UIStroke")
			local header = create("TextButton", {
				Text = "", BackgroundTransparency = 1, Selectable = true,
				Size = UDim2.new(1, 0, 0, ROW_H), Parent = row,
			})
			if ccfg.Tooltip then Tooltip.Attach(header, ccfg.Tooltip) end
			create("TextLabel", {
				BackgroundTransparency = 1, Text = ccfg.Name or "Color",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), Size = UDim2.new(1, -(70 * scale), 1, 0), Parent = header,
			})
			local swatch = create("Frame", {
				BackgroundColor3 = color, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_MED, 0.5, 0), Size = UDim2.fromOffset(40 * scale, 20 * scale),
				BorderSizePixel = 0, Parent = header,
			})
			corner(swatch, 7 * scale)
			stroke(swatch, Theme.Stroke, 0.6)
			local swatchSheen = create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85,
				BorderSizePixel = 0, Size = UDim2.new(1, 0, 0.4, 0), Parent = swatch,
			})
			corner(swatchSheen, 7 * scale)
			gradient(swatchSheen, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 90).Transparency =
				NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.8),
					NumberSequenceKeypoint.new(1, 1),
				})

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
			stroke(sv, Theme.Stroke, 0.85)
			create("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, Parent = sv }, {
				create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }),
				create("UICorner", { CornerRadius = UDim.new(0, 10 * scale) }),
			})
			create("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, Parent = sv }, {
				create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0, 0, 0)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }),
				create("UICorner", { CornerRadius = UDim.new(0, 10 * scale) }),
			})
			local svCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0), Size = UDim2.fromOffset(12 * scale, 12 * scale),
				BorderSizePixel = 0, ZIndex = 5, Parent = sv,
			})
			corner(svCursor, 6 * scale)
			stroke(svCursor, Color3.new(1, 1, 1), 0, 2 * scale)

			local hue = create("Frame", {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 22 * scale, 1, 0), BorderSizePixel = 0, Parent = body,
			})
			corner(hue, 10 * scale)
			stroke(hue, Theme.Stroke, 0.85)
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
				BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, h, 0), Size = UDim2.new(1, 6 * scale, 0, 6 * scale),
				BorderSizePixel = 0, ZIndex = 5, Parent = hue,
			})
			corner(hueCursor, 3 * scale)
			stroke(hueCursor, Color3.new(1, 1, 1), 0, 2 * scale)

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

		----------------------------------------------------------------------
		-- 9. Dropdown
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
				Text = "", BackgroundTransparency = 1, Selectable = true,
				Size = UDim2.new(1, 0, 0, ROW_H), Parent = row,
			})
			if dcfg.Tooltip then Tooltip.Attach(header, dcfg.Tooltip) end
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
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(38 * scale), 0.5, 0),
				Size = UDim2.new(0.45, -(10 * scale), 1, 0), Parent = header,
			})
			local chev = icon("chevron-down", 14 * scale, false, Theme.SubText)
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
					local isOn = selected[opt] == true
					local ob = create("TextButton", {
						Text = "", AutoButtonColor = false, Selectable = true,
						BackgroundColor3 = isOn and Theme.Accent or Theme.Element,
						BackgroundTransparency = isOn and 0.92 or 0.96,
						Size = UDim2.new(1, 0, 0, 30 * scale), LayoutOrder = i, BorderSizePixel = 0, Parent = list,
					})
					corner(ob, 9 * scale)
					local selBar = create("Frame", {
						BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.new(0, 3 * scale, 0, isOn and 14 * scale or 0),
						BackgroundTransparency = isOn and 0 or 1,
						Parent = ob,
					})
					corner(selBar, 2 * scale)
					local txt = create("TextLabel", {
						BackgroundTransparency = 1, Text = opt, FontFace = FONT_MAIN,
						TextColor3 = isOn and Theme.Accent or Theme.SubText, TextSize = FONT_SUB_SZ,
						TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, PAD_MED, 0, 0),
						Size = UDim2.new(1, -(34 * scale), 1, 0), Parent = ob,
					})
					local check = icon("check", 12 * scale, false, Theme.Accent)
					check.AnchorPoint = Vector2.new(1, 0.5)
					check.Position = UDim2.new(1, -PAD_MED, 0.5, 0)
					check.Visible = isOn
					check.Parent = ob

					ob.MouseEnter:Connect(function()
						if selected[opt] then
							tween(ob, TI, { BackgroundTransparency = 0.86 })
						else
							tween(ob, TI, { BackgroundTransparency = 0.92 })
						end
					end)
					ob.MouseLeave:Connect(function()
						tween(ob, TI, { BackgroundTransparency = selected[opt] and 0.92 or 0.96 })
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
							tween(b.btn, TI, {
								BackgroundColor3 = on and Theme.Accent or Theme.Element,
								BackgroundTransparency = on and 0.92 or 0.96,
							})
							tween(b.bar, TI, {
								BackgroundTransparency = on and 0 or 1,
								Size = UDim2.new(0, 3 * scale, 0, on and 14 * scale or 0),
							})
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
					table.insert(optionBtns, { btn = ob, opt = opt, txt = txt, check = check, bar = selBar })
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
				tween(chev, TI_S, { Rotation = open and 180 or 0 })
				tintIcon(chev, open and Theme.Accent or Theme.SubText)
				if not open then
					task.delay(0.12, function()
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
