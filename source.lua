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
-- Premium Theme System
----------------------------------------------------------------------
local Theme = {
	-- Base palette with depth
	Surface0     = Color3.fromRGB(12, 12, 16),
	Surface1     = Color3.fromRGB(18, 18, 24),
	Surface2     = Color3.fromRGB(26, 26, 34),
	Surface3     = Color3.fromRGB(34, 34, 44),
	
	-- Element colors
	Element      = Color3.fromRGB(255, 255, 255),
	ElementHover = Color3.fromRGB(255, 255, 255),
	Off          = Color3.fromRGB(120, 120, 140),
	Stroke       = Color3.fromRGB(255, 255, 255),
	
	-- Text hierarchy
	Text         = Color3.fromRGB(245, 245, 250),
	TextMuted    = Color3.fromRGB(160, 160, 180),
	TextDim      = Color3.fromRGB(110, 110, 130),
	
	-- Functional colors
	Warning      = Color3.fromRGB(255, 200, 90),
	Error        = Color3.fromRGB(255, 100, 100),
	Success      = Color3.fromRGB(90, 220, 140),
	
	-- Premium accent with variants
	Accent       = Color3.fromRGB(99, 130, 255),
	AccentSoft   = Color3.fromRGB(99, 130, 255),
	AccentGlow   = Color3.fromRGB(99, 130, 255),
}

-- Premium transparency values
local GLASS_T  = 0.96
local GLASS_HT = 0.90
local CHIP_T   = 0.92
local STROKE_T = 0.94
local SURFACE_T = 0.85

local BUILDER_ICONS = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"
local FONT_TITLE = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_MAIN  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FONT_NUM   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)

local TI    = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_S  = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_R  = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_GLOW = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

----------------------------------------------------------------------
-- Connection tracking
----------------------------------------------------------------------
local Connections = {}

local function track(conn)
	table.insert(Connections, conn)
	return conn
end

----------------------------------------------------------------------
-- Premium Helpers
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
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
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
	local d = math.max(host.AbsoluteSize.X, host.AbsoluteSize.Y) * 2.4
	local r = create("Frame", {
		BackgroundColor3 = color or Theme.Text,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 0),
		ZIndex = host.ZIndex + 5,
		Parent = host,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = r })
	tween(r, TI_R, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 })
	task.delay(0.55, function() if r.Parent then r:Destroy() end end)
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

-- Premium glow effect for interactive elements
local function addGlow(parent, color, size)
	local glow = create("Frame", {
		Name = "Glow",
		BackgroundColor3 = color or Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, size or 20, 1, size or 20),
		ZIndex = 0,
		Parent = parent,
	})
	corner(glow, 100)
	local blur = create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = color or Theme.Accent,
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 0,
		Parent = glow,
	})
	return glow, blur
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

local NotifHolder = create("Frame", {
	Name = "Notifications",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -20),
	Size = UDim2.new(0, 280, 1, -40),
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
-- Premium Tooltip manager
----------------------------------------------------------------------
local Tooltip = {}
do
	local tip = create("Frame", {
		Name = "Tooltip",
		BackgroundColor3 = Theme.Surface2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = false,
		ZIndex = 50,
		Parent = ScreenGui,
	})
	corner(tip, 10)
	local tipStroke = stroke(tip, Theme.Stroke, 1, 1.2)
	tipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	create("UIPadding", {
		PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7),
		PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11),
		Parent = tip,
	})
	local tipLbl = create("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 12,
		TextTransparency = 1,
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
		task.delay(0.17, function()
			if not hoverObj and not Library._destroyed then tip.Visible = false end
		end)
	end
	track(UserInputService.InputChanged:Connect(function(inp)
		if hoverObj and tip.Visible and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local mp = UserInputService:GetMouseLocation()
			local maxX = tip.Parent.AbsoluteSize.X
			local x = mp.X + 16
			if tip.AbsoluteSize.X > 0 and x + tip.AbsoluteSize.X > maxX - 10 then
				x = maxX - tip.AbsoluteSize.X - 10
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
			task.delay(0.35, function()
				if Library._destroyed or hoverObj ~= obj or token ~= my then return end
				tipLbl.Text = text
				local mp = UserInputService:GetMouseLocation()
				tip.Position = UDim2.fromOffset(mp.X + 16, mp.Y + 14)
				tip.Visible = true
				tween(tip, TI, { BackgroundTransparency = 0.04 })
				tween(tipStroke, TI, { Transparency = 0.88 })
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

	local card = create("Frame", {
		BackgroundColor3 = Theme.Surface1,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 280 * nscale, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = NotifHolder,
	})
	corner(card, 16 * nscale)
	local st = stroke(card, Theme.Stroke, 1, 1.2)

	-- Premium accent line
	local accentLine = create("Frame", {
		BackgroundColor3 = cfg.Color or Theme.Accent, 
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 3, 1, 0), 
		BorderSizePixel = 0, 
		Parent = card,
	})

	local content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 0), 
		Size = UDim2.new(1, -30, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, 
		Parent = card,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }),
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
			FontFace = FONT_MAIN, 
			TextColor3 = Theme.TextMuted, 
			TextSize = 13 * nscale,
			TextXAlignment = Enum.TextXAlignment.Left, 
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0), 
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2, 
			Parent = content,
		})
	end

	local pop = create("UIScale", { Scale = 0.94, Parent = card })
	tween(pop, TI_S, { Scale = 1 })
	tween(card, TI_S, { BackgroundTransparency = 0.04 })
	tween(st, TI_S, { Transparency = 0.9 })
	tween(accentLine, TI_S, { BackgroundTransparency = 0 })
	tween(titleLbl, TI_S, { TextTransparency = 0 })
	if bodyLbl then tween(bodyLbl, TI_S, { TextTransparency = 0 }) end

	task.delay(dur, function()
		if Library._destroyed or not card.Parent then return end
		tween(pop, TI, { Scale = 0.94 })
		tween(card, TI, { BackgroundTransparency = 1 })
		tween(st, TI, { Transparency = 1 })
		tween(accentLine, TI, { BackgroundTransparency = 1 })
		tween(titleLbl, TI, { TextTransparency = 1 })
		if bodyLbl then tween(bodyLbl, TI, { TextTransparency = 1 }) end
		task.wait(0.22)
		if card.Parent then card:Destroy() end
	end)
end

----------------------------------------------------------------------
-- Premium Window
----------------------------------------------------------------------
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	if cfg.Accent then 
		Theme.Accent = cfg.Accent 
		Theme.AccentSoft = cfg.Accent
		Theme.AccentGlow = cfg.Accent
	end

	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local vpW, vpH = vp.X, vp.Y

	local BASE_W, BASE_H = 600, 420
	local scale = cfg.Scale or 0.85
	Library._scale = scale

	local WIN_W = BASE_W * scale
	local WIN_H = BASE_H * scale
	local TOP_H = 58 * scale
	local SIDE_W = 72 * scale
	local ROW_H = 46 * scale
	local WIN_R = 24 * scale
	local CARD_R = 16 * scale
	local FONT_TITLE_SZ = 16 * scale
	local FONT_MAIN_SZ = 13 * scale
	local FONT_SUB_SZ = 12 * scale
	local PAD_SMALL = 10 * scale
	local PAD_MED = 14 * scale
	local PAD_LARGE = 16 * scale

	local Window = { Tabs = {}, _current = nil }

	local startX = vpW * 0.5 - WIN_W * 0.5
	local startY = vpH * 0.1

	-- Premium layered background with depth
	local BG = create("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(startX, startY),
		Size = UDim2.fromOffset(WIN_W, WIN_H),
		BackgroundColor3 = Theme.Surface0,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		Active = true,
		GroupTransparency = 1,
		Parent = ScreenGui,
	})
	corner(BG, WIN_R)
	
	-- Premium multi-layer stroke
	local outerStroke = stroke(BG, Theme.Stroke, 0.92, 1.5)
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	
	-- Subtle inner glow for depth
	local innerGlow = create("Frame", {
		Name = "InnerGlow",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 0,
		Parent = BG,
	})
	local glowGrad = create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.Accent),
			ColorSequenceKeypoint.new(0.5, Theme.Surface0),
			ColorSequenceKeypoint.new(1, Theme.Surface0),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.97),
			NumberSequenceKeypoint.new(0.15, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 135,
		Parent = innerGlow,
	})

	local winScale = create("UIScale", { Scale = 0.95, Parent = BG })
	tween(BG, TI_S, { GroupTransparency = 0 })
	tween(winScale, TI_S, { Scale = 1 })

	----------------------------------------------------------------------
	-- Premium Top bar
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

	local CTRL_SZ = 34 * scale
	local CTRL_GAP = CTRL_SZ + 8

	local ctrlReserve = CTRL_GAP * 3 + 12 * scale

	local titleWrap = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, PAD_LARGE + 2 * scale, 0.5, 0),
		Size = UDim2.new(1, -ctrlReserve, 0, 26 * scale),
		Parent = TopBar,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10 * scale),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- Premium title with subtle accent
	local titleContainer = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 1,
		Parent = titleWrap,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8 * scale),
		}),
	})

	-- Accent dot for premium feel
	local accentDot = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(6 * scale, 6 * scale),
		Parent = titleContainer,
	})
	corner(accentDot, 3 * scale)

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
		Parent = titleContainer,
	})

	local tabLbl = create("TextLabel", {
		Name = "CurrentTab", 
		Text = "",
		FontFace = FONT_MAIN, 
		TextColor3 = Theme.TextDim, 
		TextSize = FONT_MAIN_SZ,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 2,
		Parent = titleWrap,
	})

	local function ctrlBtn(iconName, slotIndex, hoverColor)
		local offsetX = -(slotIndex - 1) * CTRL_GAP - CTRL_SZ * 0.5 - 8 * scale
		local b = create("TextButton", {
			Text = "", 
			AutoButtonColor = false, 
			Selectable = true,
			BackgroundColor3 = Theme.Surface2, 
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
		local ic = icon(iconName, 15 * scale, false, Theme.TextDim)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
		ic.Parent = b
		b.MouseEnter:Connect(function()
			tween(b, TI, { BackgroundTransparency = 0.88 })
			tintIcon(ic, hoverColor or Theme.Text)
		end)
		b.MouseLeave:Connect(function()
			tween(b, TI, { BackgroundTransparency = 1 })
			tintIcon(ic, Theme.TextDim)
			tween(bScale, TI, { Scale = 1 })
		end)
		return b
	end

	local MinBtn = ctrlBtn("minus", 1, Theme.Text)
	local YtBtn  = ctrlBtn("youtube", 2, Color3.fromRGB(255, 90, 90))
	local DcBtn  = ctrlBtn("discord", 3, Color3.fromRGB(120, 150, 255))
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
	-- Premium Icon rail with depth
	----------------------------------------------------------------------
	local Rail = create("Frame", {
		Name = "Rail",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, SIDE_W, 1, 0),
		Parent = BG,
	})

	-- Premium rail background with subtle separation
	local railBg = create("Frame", {
		BackgroundColor3 = Theme.Surface1,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = Rail,
	})
	corner(railBg, WIN_R)
	-- Only round right corners
	local railCornerFix = create("Frame", {
		BackgroundColor3 = Theme.Surface1,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Parent = Rail,
	})

	local TabList = create("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 10 * scale),
		Size = UDim2.new(1, 0, 1, -(68 * scale)),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		Selectable = true,
		Parent = Rail,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 10 * scale),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- Premium divider with gradient
	local RailDivider = create("Frame", {
		Name = "RailDivider",
		BackgroundColor3 = Theme.Stroke, 
		BackgroundTransparency = 0.95,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0, 16 * scale),
		Size = UDim2.new(0, 1, 1, -(32 * scale)),
		ZIndex = 2, 
		Parent = Rail,
	})

	local PWR_SZ = 44 * scale
	local PowerBtn = create("TextButton", {
		Text = "", 
		AutoButtonColor = false, 
		Selectable = true,
		BackgroundColor3 = Theme.Surface2, 
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12 * scale),
		Size = UDim2.fromOffset(PWR_SZ, PWR_SZ),
		Parent = Rail,
	})
	corner(PowerBtn, 14 * scale)
	Tooltip.Attach(PowerBtn, "Unload UI")
	local powerIc = icon("x", 18 * scale, false, Theme.TextDim)
	powerIc.AnchorPoint = Vector2.new(0.5, 0.5)
	powerIc.Position = UDim2.new(0.5, 0, 0.5, 0)
	powerIc.Parent = PowerBtn
	PowerBtn.MouseEnter:Connect(function()
		tween(PowerBtn, TI, { BackgroundTransparency = 0.82, BackgroundColor3 = Color3.fromRGB(255, 85, 85) })
		tintIcon(powerIc, Theme.Text)
	end)
	PowerBtn.MouseLeave:Connect(function()
		tween(PowerBtn, TI, { BackgroundTransparency = 1, BackgroundColor3 = Theme.Surface2 })
		tintIcon(powerIc, Theme.TextDim)
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
		tween(winScale, TI, { Scale = 0.95 })
		tween(BG, TI, { GroupTransparency = 1 })
		task.delay(0.2, function()
			Library:Destroy()
		end)
	end)

	----------------------------------------------------------------------
	-- Minimize / restore with premium animation
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
			tween(innerGlow, TI_S, { ImageTransparency = 1 })
		else
			tween(BG, TI_S, { Size = fullSize })
			tween(TopBar, TI_S, { Position = UDim2.new(0, SIDE_W, 0, 0), Size = UDim2.new(1, -SIDE_W, 0, TOP_H) })
			task.delay(0.14, function()
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
			tween(winScale, TI, { Scale = 0.96 })
			tween(BG, TI, { GroupTransparency = 1 })
			task.delay(0.2, function()
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
	-- Premium Tabs
	----------------------------------------------------------------------
	function Window:CreateTab(tcfg)
		tcfg = tcfg or {}
		local Tab = { _order = 0 }

		local TAB_BTN_SZ = 46 * scale
		local btn = create("TextButton", {
			Text = "", 
			AutoButtonColor = false, 
			Selectable = true,
			BackgroundColor3 = Theme.Surface2, 
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(TAB_BTN_SZ, TAB_BTN_SZ),
			Parent = TabList,
		})
		corner(btn, 14 * scale)
		if tcfg.Name then Tooltip.Attach(btn, tcfg.Name) end

		-- Premium icon with glow potential
		local ic = icon(tcfg.Icon or "circle", 20 * scale, false, Theme.TextDim)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
		ic.Parent = btn

		-- Premium badge with pulse
		local badge = create("Frame", {
			BackgroundColor3 = Theme.Accent, 
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -4 * scale, 0, 4 * scale),
			Size = UDim2.fromOffset(8 * scale, 8 * scale),
			Visible = false, 
			ZIndex = 3, 
			Parent = btn,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badge })

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
			ScrollBarThickness = 4 * scale,
			ScrollBarImageColor3 = Theme.Stroke, 
			ScrollBarImageTransparency = 0.7,
			Selectable = true,
			Parent = pageWrap,
		}, {
			create("UIListLayout", { 
				Padding = UDim.new(0, 12 * scale), 
				SortOrder = Enum.SortOrder.LayoutOrder 
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
				tintIcon(t._icon, Theme.TextDim)
			end
			Window._current = Tab
			badge.Visible = false
			tabLbl.Text = "/  " .. (tcfg.Name or "Tab")
			pageWrap.Visible = true
			pageWrap.GroupTransparency = 1
			pageWrap.Position = UDim2.new(0.02, 0, 0, 0)
			tween(pageWrap, TI_S, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
			tween(btn, TI, { BackgroundTransparency = 0.82 })
			tintIcon(ic, Theme.Text)
		end

		btn.MouseEnter:Connect(function()
			if Window._current ~= Tab then tween(btn, TI, { BackgroundTransparency = 0.92 }) end
		end)
		btn.MouseLeave:Connect(function()
			if Window._current ~= Tab then tween(btn, TI, { BackgroundTransparency = 1 }) end
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

		local function newRow(height)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundColor3 = Theme.Surface2,
				BackgroundTransparency = GLASS_T,
				Size = UDim2.new(1, 0, 0, height or ROW_H),
				LayoutOrder = Tab._order,
				BorderSizePixel = 0, 
				Parent = page,
			})
			corner(row, CARD_R)
			local rowStroke = stroke(row, Theme.Stroke, STROKE_T, 1.2)
			rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			return row, rowStroke
		end

		local function rowHover(row, rowStroke)
			return function()
				tween(row, TI, { BackgroundTransparency = GLASS_HT })
				if rowStroke then tween(rowStroke, TI, { Color = Theme.Accent, Transparency = 0.75 }) end
			end, function()
				tween(row, TI, { BackgroundTransparency = GLASS_T })
				if rowStroke then tween(rowStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T }) end
			end
		end

		----------------------------------------------------------------------
		-- 1. Label (Premium)
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
				FontFace = FONT_MAIN, 
				TextColor3 = Theme.TextMuted, 
				TextSize = FONT_SUB_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, 
				TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y, 
				Size = UDim2.new(1, -PAD_SMALL, 0, 0),
				Position = UDim2.new(0, 4 * scale, 0, 0), 
				Parent = row,
			})
			create("UIPadding", { 
				PaddingTop = UDim.new(0, 3 * scale), 
				PaddingBottom = UDim.new(0, 3 * scale), 
				Parent = row 
			})
			return { Set = function(_, t) lbl.Text = t end, Instance = row }
		end

		----------------------------------------------------------------------
		-- 2. Warning (Premium)
		----------------------------------------------------------------------
		function Tab:CreateWarning(text)
			local row, rowStroke = newRow(0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			row.BackgroundColor3 = Theme.Warning
			row.BackgroundTransparency = 0.94
			if rowStroke then
				rowStroke.Color = Theme.Warning
				rowStroke.Transparency = 0.6
			end
			create("UIPadding", {
				PaddingTop = UDim.new(0, 12 * scale),
				PaddingBottom = UDim.new(0, 12 * scale),
				PaddingLeft = UDim.new(0, PAD_MED),
				PaddingRight = UDim.new(0, PAD_MED),
				Parent = row,
			})
			local ico = icon("triangle-exclamation", 18 * scale, false, Theme.Warning)
			ico.AnchorPoint = Vector2.new(0, 0.5)
			ico.Position = UDim2.new(0, 0, 0.5, 0)
			ico.Parent = row
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, 
				Text = text or "Warning",
				FontFace = FONT_MAIN, 
				TextColor3 = Theme.Warning, 
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, 
				TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true, 
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, -30 * scale, 0, 0), 
				Position = UDim2.new(0, 30 * scale, 0, 0), 
				Parent = row,
			})
			return { Set = function(_, t) lbl.Text = t end, Instance = row }
		end

		----------------------------------------------------------------------
		-- 3. Button (Premium with glow)
		----------------------------------------------------------------------
		function Tab:CreateButton(bcfg)
			bcfg = bcfg or {}
			Tab._order += 1
			local btnEl = create("TextButton", {
				Text = "", 
				AutoButtonColor = false, 
				Selectable = true,
				BackgroundColor3 = Theme.Surface2, 
				BackgroundTransparency = GLASS_T,
				Size = UDim2.new(1, 0, 0, ROW_H), 
				LayoutOrder = Tab._order,
				BorderSizePixel = 0, 
				Parent = page,
			})
			corner(btnEl, CARD_R)
			local btnStroke = stroke(btnEl, Theme.Stroke, STROKE_T, 1.2)
			btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			if bcfg.Tooltip then Tooltip.Attach(btnEl, bcfg.Tooltip) end
			
			create("TextLabel", {
				BackgroundTransparency = 1, 
				Text = bcfg.Name or "Button",
				FontFace = FONT_MAIN, 
				TextColor3 = Theme.Text, 
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, 
				TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0),
				Size = UDim2.new(1, -(68 * scale), 1, 0), 
				Parent = btnEl,
			})
			
			-- Premium chip with depth
			local chip = create("Frame", {
				BackgroundColor3 = Theme.Surface3, 
				BackgroundTransparency = CHIP_T,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_SMALL, 0.5, 0),
				Size = UDim2.fromOffset(30 * scale, 30 * scale),
				BorderSizePixel = 0, 
				Parent = btnEl,
			})
			corner(chip, 15 * scale)
			local chipIc = icon("chevron-right", 14 * scale, false, Theme.TextDim)
			chipIc.AnchorPoint = Vector2.new(0.5, 0.5)
			chipIc.Position = UDim2.new(0.5, 0, 0.5, 0)
			chipIc.Parent = chip

			-- Premium glow on hover
			local glow, glowBlur = addGlow(btnEl, Theme.Accent, 30)

			btnEl.MouseEnter:Connect(function()
				tween(btnEl, TI, { BackgroundTransparency = GLASS_HT })
				tween(btnStroke, TI, { Color = Theme.Accent, Transparency = 0.65 })
				tween(chip, TI, { BackgroundTransparency = 0.82 })
				tintIcon(chipIc, Theme.Text)
			end)
			btnEl.MouseLeave:Connect(function()
				tween(btnEl, TI, { BackgroundTransparency = GLASS_T })
				tween(btnStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				tween(chip, TI, { BackgroundTransparency = CHIP_T })
				tintIcon(chipIc, Theme.TextDim)
			end)
			btnEl.Activated:Connect(function()
				ripple(btnEl, Theme.Accent)
				tween(chip, TI, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.12 })
				tintIcon(chipIc, Theme.Text)
				task.delay(0.16, function()
					if Library._destroyed or not chip.Parent then return end
					tween(chip, TI, { BackgroundColor3 = Theme.Surface3, BackgroundTransparency = CHIP_T })
					tintIcon(chipIc, Theme.TextDim)
				end)
				if bcfg.Callback then task.spawn(bcfg.Callback) end
			end)
			return { Instance = btnEl }
		end

		----------------------------------------------------------------------
		-- 4. Toggle (Premium with smooth track)
		----------------------------------------------------------------------
		function Tab:CreateToggle(tocfg)
			tocfg = tocfg or {}
			local state = tocfg.Default or false
			local row, rowStroke = newRow(ROW_H)
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
				FontFace = FONT_MAIN, 
				TextColor3 = Theme.Text, 
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, 
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), 
				Size = UDim2.new(1, -(84 * scale), 1, 0), 
				Parent = btnEl,
			})
			
			-- Premium track with better proportions
			local track_ = create("Frame", {
				BackgroundColor3 = state and Theme.Accent or Theme.Off,
				BackgroundTransparency = state and 0 or 0.88,
				AnchorPoint = Vector2.new(1, 0.5), 
				Position = UDim2.new(1, -PAD_MED, 0.5, 0),
				Size = UDim2.fromOffset(48 * scale, 26 * scale), 
				BorderSizePixel = 0, 
				Parent = btnEl,
			})
			corner(track_, 13 * scale)
			
			-- Premium knob with shadow
			local knob = create("Frame", {
				BackgroundColor3 = Theme.Text, 
				AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -(24 * scale), 0.5, 0) or UDim2.new(0, 2 * scale, 0.5, 0),
				Size = UDim2.fromOffset(22 * scale, 22 * scale), 
				BorderSizePixel = 0, 
				Parent = track_,
			})
			corner(knob, 11 * scale)
			stroke(knob, Color3.new(0, 0, 0), 0.85, 2)

			local enter, leave = rowHover(row, rowStroke)
			btnEl.MouseEnter:Connect(enter)
			btnEl.MouseLeave:Connect(leave)

			local api = {}
			function api:Set(v)
				state = v
				tween(track_, TI, {
					BackgroundColor3 = state and Theme.Accent or Theme.Off,
					BackgroundTransparency = state and 0 or 0.88,
				})
				tween(knob, TI, { 
					Position = state and UDim2.new(1, -(24 * scale), 0.5, 0) or UDim2.new(0, 2 * scale, 0.5, 0) 
				})
				if tocfg.Callback then task.spawn(tocfg.Callback, state) end
			end
			function api:Get() return state end
			btnEl.Activated:Connect(function() api:Set(not state) end)
			if state and tocfg.Callback and tocfg.FireOnInit ~= false then task.spawn(tocfg.Callback, true) end
			api.Instance = row
			return api
		end

		----------------------------------------------------------------------
		-- 5. Stat (Premium with accent)
		----------------------------------------------------------------------
		function Tab:CreateStat(scfg)
			scfg = scfg or {}
			local row, rowStroke = newRow(42 * scale)
			if scfg.Tooltip then Tooltip.Attach(row, scfg.Tooltip) end
			create("TextLabel", {
				BackgroundTransparency = 1, 
				Text = scfg.Name or "Stat",
				FontFace = FONT_MAIN, 
				TextColor3 = Theme.TextMuted, 
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
				FontFace = FONT_NUM, 
				TextColor3 = Theme.Accent, 
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Right, 
				TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), 
				Position = UDim2.new(1, -PAD_MED, 0.5, 0),
				Size = UDim2.new(0.5, -PAD_MED, 1, 0), 
				Parent = row,
			})
			return { Set = function(_, v) valLbl.Text = tostring(v) end, Instance = row }
		end

		----------------------------------------------------------------------
		-- 6. Slider (Premium with refined track)
		----------------------------------------------------------------------
		function Tab:CreateSlider(slcfg)
			slcfg = slcfg or {}
			local min, max = slcfg.Min or 0, slcfg.Max or 100
			local inc = slcfg.Increment or 1
			local value = math.clamp(slcfg.Default or min, min, max)
			local row, rowStroke = newRow(58 * scale)
			if slcfg.Tooltip then Tooltip.Attach(row, slcfg.Tooltip) end

			create("TextLabel", {
				BackgroundTransparency = 1, 
				Text = slcfg.Name or "Slider",
				FontFace = FONT_MAIN, 
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

			local valWrap = create("Frame", {
				BackgroundTransparency = 1, 
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -PAD_MED, 0, 8 * scale),
				Size = UDim2.fromOffset(124 * scale, 22 * scale), 
				Parent = row,
			}, {
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 6 * scale), 
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			})

			local function stepBtn(txt, delta, order)
				local b = create("TextButton", {
					Text = "", 
					AutoButtonColor = false, 
					Selectable = true,
					BackgroundColor3 = Theme.Surface3, 
					BackgroundTransparency = CHIP_T,
					Size = UDim2.fromOffset(22 * scale, 22 * scale), 
					LayoutOrder = order,
					BorderSizePixel = 0, 
					Parent = valWrap,
				})
				corner(b, 8 * scale)
				local lbl = create("TextLabel", {
					BackgroundTransparency = 1, 
					Text = txt, 
					FontFace = FONT_NUM,
					TextColor3 = Theme.TextDim, 
					TextSize = FONT_SUB_SZ,
					Size = UDim2.new(1, 0, 1, 0), 
					Parent = b,
				})
				b.MouseEnter:Connect(function() tween(lbl, TI, { TextColor3 = Theme.Text }) end)
				b.MouseLeave:Connect(function() tween(lbl, TI, { TextColor3 = Theme.TextDim }) end)
				b.Activated:Connect(function()
					ripple(b, Theme.Accent)
					api:Set(value + delta)
				end)
			end

			local valBox = create("TextBox", {
				BackgroundColor3 = Theme.Surface3, 
				BackgroundTransparency = 0.94,
				Text = fmtVal(value), 
				ClearTextOnFocus = false,
				FontFace = FONT_NUM, 
				TextColor3 = Theme.Accent, 
				TextSize = FONT_MAIN_SZ,
				LayoutOrder = 2, 
				Size = UDim2.fromOffset(56 * scale, 22 * scale), 
				Parent = valWrap,
			})
			corner(valBox, 8 * scale)
			local vbStroke = stroke(valBox, Theme.Stroke, STROKE_T, 1.2)
			vbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			valBox.Focused:Connect(function() tween(vbStroke, TI, { Color = Theme.Accent, Transparency = 0.2 }) end)

			stepBtn("-", -inc, 1)
			stepBtn("+", inc, 3)

			local TRACK_H = 5 * scale
			local trackBar = create("Frame", {
				BackgroundColor3 = Theme.Off, 
				BackgroundTransparency = 0.88,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, PAD_MED, 1, -(14 * scale)),
				Size = UDim2.new(1, -(2 * PAD_MED), 0, TRACK_H),
				BorderSizePixel = 0, 
				Parent = row,
			})
			corner(trackBar, 3 * scale)
			
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
				BorderSizePixel = 0, 
				Parent = trackBar,
			})
			corner(fill, 3 * scale)
			
			local KNOB_SZ = 14 * scale
			local knob = create("Frame", {
				BackgroundColor3 = Theme.Text, 
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
				Size = UDim2.fromOffset(KNOB_SZ, KNOB_SZ), 
				BorderSizePixel = 0, 
				ZIndex = 2, 
				Parent = trackBar,
			})
			corner(knob, KNOB_SZ * 0.5)
			stroke(knob, Color3.new(0, 0, 0), 0.85, 2)

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
		-- 7. Textbox (Premium)
		----------------------------------------------------------------------
		function Tab:CreateTextbox(txcfg)
			txcfg = txcfg or {}
			local row, rowStroke = newRow(ROW_H)
			if txcfg.Tooltip then Tooltip.Attach(row, txcfg.Tooltip) end
			create("TextLabel", {
				BackgroundTransparency = 1, 
				Text = txcfg.Name or "Textbox",
				FontFace = FONT_MAIN, 
				TextColor3 = Theme.Text, 
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, 
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), 
				Size = UDim2.new(0.42, -PAD_MED, 1, 0), 
				Parent = row,
			})
			local boxWrap = create("Frame", {
				BackgroundColor3 = Theme.Surface3, 
				BackgroundTransparency = 0.94,
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
					PaddingRight = UDim.new(0, 12 * scale) 
				}),
			})
			corner(boxWrap, 10 * scale)
			local tbStroke = stroke(boxWrap, Theme.Stroke, STROKE_T, 1.2)
			tbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			local tb = create("TextBox", {
				BackgroundTransparency = 1, 
				Text = txcfg.Default or "",
				PlaceholderText = txcfg.Placeholder or "...", 
				PlaceholderColor3 = Theme.TextDim,
				FontFace = FONT_MAIN, 
				TextColor3 = Theme.Text, 
				TextSize = 13 * scale,
				ClearTextOnFocus = false, 
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.X, 
				Size = UDim2.new(0, 0, 1, 0), 
				Parent = boxWrap,
			}, {
				create("UISizeConstraint", {
					MinSize = Vector2.new((txcfg.MinWidth or 64) * scale, 0),
					MaxSize = Vector2.new((txcfg.MaxWidth or 200) * scale, math.huge),
				}),
			})
			tb.Focused:Connect(function() tween(tbStroke, TI, { Color = Theme.Accent, Transparency = 0.2 }) end)
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
		-- 8. Color Picker (Premium with refined layout)
		----------------------------------------------------------------------
		function Tab:CreateColorPicker(ccfg)
			ccfg = ccfg or {}
			local color = ccfg.Default or Color3.fromRGB(255, 0, 0)
			local h, s, v = color:ToHSV()

			local row, rowStroke = newRow(ROW_H)
			row.ClipsDescendants = true
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
				FontFace = FONT_MAIN, 
				TextColor3 = Theme.Text, 
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, 
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), 
				Size = UDim2.new(1, -(72 * scale), 1, 0), 
				Parent = header,
			})
			local swatch = create("Frame", {
				BackgroundColor3 = color, 
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -PAD_MED, 0.5, 0), 
				Size = UDim2.fromOffset(40 * scale, 22 * scale),
				BorderSizePixel = 0, 
				Parent = header,
			})
			corner(swatch, 8 * scale)
			stroke(swatch, Theme.Stroke, 0.5, 1.2)

			local body = create("Frame", {
				BackgroundTransparency = 1, 
				Position = UDim2.new(0, 0, 0, ROW_H),
				Size = UDim2.new(1, 0, 0, 148 * scale), 
				Visible = false, 
				Parent = row,
			})
			create("UIPadding", {
				PaddingLeft = UDim.new(0, PAD_MED),
				PaddingRight = UDim.new(0, PAD_MED),
				PaddingBottom = UDim.new(0, PAD_MED),
				Parent = body,
			})

			local sv = create("Frame", {
				BackgroundColor3 = Color3.fromHSV(h, 1, 1), 
				Size = UDim2.new(1, -(38 * scale), 1, 0),
				BorderSizePixel = 0, 
				Parent = body,
			})
			corner(sv, 12 * scale)
			create("Frame", { 
				BackgroundColor3 = Color3.new(1, 1, 1), 
				Size = UDim2.new(1, 0, 1, 0), 
				BorderSizePixel = 0, 
				Parent = sv 
			}, {
				create("UIGradient", { 
					Color = ColorSequence.new(Color3.new(1, 1, 1)), 
					Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) 
				}),
				create("UICorner", { CornerRadius = UDim.new(0, 12 * scale) }),
			})
			create("Frame", { 
				BackgroundColor3 = Color3.new(0, 0, 0), 
				Size = UDim2.new(1, 0, 1, 0), 
				BorderSizePixel = 0, 
				Parent = sv 
			}, {
				create("UIGradient", { 
					Rotation = 90, 
					Color = ColorSequence.new(Color3.new(0, 0, 0)), 
					Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) 
				}),
				create("UICorner", { CornerRadius = UDim.new(0, 12 * scale) }),
			})
			local svCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1), 
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0), 
				Size = UDim2.fromOffset(12 * scale, 12 * scale),
				BorderSizePixel = 0, 
				ZIndex = 5, 
				Parent = sv,
			})
			corner(svCursor, 6 * scale)
			stroke(svCursor, Color3.new(0, 0, 0), 0.3, 2)

			local hue = create("Frame", {
				AnchorPoint = Vector2.new(1, 0), 
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 26 * scale, 1, 0), 
				BorderSizePixel = 0, 
				Parent = body,
			})
			corner(hue, 12 * scale)
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
			stroke(hueCursor, Color3.new(0, 0, 0), 0.3, 2)

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
				tween(row, TI_S, { Size = UDim2.new(1, 0, 0, open and (ROW_H + 148 * scale) or ROW_H) })
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
		-- 9. Dropdown (Premium with refined list)
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

			local row, rowStroke = newRow(ROW_H)
			row.ClipsDescendants = true
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
				FontFace = FONT_MAIN, 
				TextColor3 = Theme.Text, 
				TextSize = FONT_MAIN_SZ,
				TextXAlignment = Enum.TextXAlignment.Left, 
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, PAD_MED, 0.5, 0), 
				Size = UDim2.new(0.45, 0, 1, 0), 
				Parent = header,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, 
				Text = "",
				FontFace = FONT_MAIN, 
				TextColor3 = Theme.TextDim, 
				TextSize = FONT_SUB_SZ,
				TextXAlignment = Enum.TextXAlignment.Right, 
				TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), 
				Position = UDim2.new(1, -(38 * scale), 0.5, 0),
				Size = UDim2.new(0.45, -(10 * scale), 1, 0), 
				Parent = header,
			})
			local chev = icon("chevron-down", 16 * scale, false, Theme.TextDim)
			chev.AnchorPoint = Vector2.new(1, 0.5)
			chev.Position = UDim2.new(1, -PAD_MED, 0.5, 0)
			chev.Parent = header

			local list = create("Frame", {
				BackgroundTransparency = 1, 
				Position = UDim2.new(0, 0, 0, ROW_H),
				Size = UDim2.new(1, 0, 0, 0), 
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false, 
				Parent = row,
			}, {
				create("UIListLayout", { 
					Padding = UDim.new(0, 4 * scale), 
					SortOrder = Enum.SortOrder.LayoutOrder 
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
						BackgroundColor3 = Theme.Surface3, 
						BackgroundTransparency = 0.96,
						Size = UDim2.new(1, 0, 0, 32 * scale), 
						LayoutOrder = i, 
						BorderSizePixel = 0, 
						Parent = list,
					})
					corner(ob, 10 * scale)
					local txt = create("TextLabel", {
						BackgroundTransparency = 1, 
						Text = opt, 
						FontFace = FONT_MAIN,
						TextColor3 = selected[opt] and Theme.Accent or Theme.TextMuted, 
						TextSize = FONT_SUB_SZ,
						TextXAlignment = Enum.TextXAlignment.Left, 
						Position = UDim2.new(0, PAD_MED, 0, 0),
						Size = UDim2.new(1, -(36 * scale), 1, 0), 
						Parent = ob,
					})
					local check = icon("check", 14 * scale, false, Theme.Accent)
					check.AnchorPoint = Vector2.new(1, 0.5)
					check.Position = UDim2.new(1, -PAD_MED, 0.5, 0)
					check.Visible = selected[opt] == true
					check.Parent = ob

					ob.MouseEnter:Connect(function() tween(ob, TI, { BackgroundTransparency = 0.9 }) end)
					ob.MouseLeave:Connect(function() tween(ob, TI, { BackgroundTransparency = 0.96 }) end)
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
							tween(b.txt, TI, { TextColor3 = on and Theme.Accent or Theme.TextMuted })
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
					table.insert(optionBtns, { btn = ob, opt = opt, txt = txt, check = check })
				end
				updateValLabel()
			end

			local function openHeight()
				local n = #options
				if n == 0 then return ROW_H + 18 * scale end
				return ROW_H + (14 * scale) + (n * 32 * scale) + ((n - 1) * 4 * scale)
			end

			local open = false
			function api._toggle(force)
				if Library._destroyed then return end
				if force ~= nil then open = force else open = not open end
				if open then list.Visible = true end
				tween(row, TI_S, { Size = UDim2.new(1, 0, 0, open and openHeight() or ROW_H) })
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
