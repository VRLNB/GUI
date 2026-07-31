--[[
	LuminaUI v3.0 - 夜态玻璃 Glassmorphism
	深色毛玻璃 · 独立大开关 · 全组件动画
	复制全部代码到注入器执行
]]

-- ==================== 环境检测 ====================
print("[Glass] 启动中...")

local env = {}
local function safe(fn)
	local ok, result = pcall(fn)
	if not ok then print("[Glass] 失败: " .. tostring(result)) end
	return ok, result
end

safe(function() env.game = game end)
if not env.game then return end
safe(function() env.Players = env.game:GetService("Players") end)
safe(function() env.Tween = env.game:GetService("TweenService") end)
safe(function() env.UIS = env.game:GetService("UserInputService") end)

for i = 1, 100 do
	safe(function() env.plr = env.Players.LocalPlayer or env.Players:FindFirstChildOfClass("Player") end)
	if env.plr then break end
	wait(0.1)
end
if not env.plr then return end

safe(function()
	env.pgui = env.plr:FindFirstChild("PlayerGui")
	if not env.pgui then env.pgui = env.plr:WaitForChild("PlayerGui", 5) end
end)
if not env.pgui then return end

safe(function() env.mouse = env.plr:GetMouse() end)
print("[Glass] 就绪 | " .. env.plr.Name)

-- ==================== 色彩 ====================
-- 夜态玻璃配色：深色底 + 半透明层 + 紫蓝渐变点缀
local C = {
	Base  = Color3.fromRGB(8, 8, 14),      -- 最深底色
	Glass = Color3.fromRGB(18, 18, 30),    -- 玻璃面板
	Glass2= Color3.fromRGB(24, 24, 38),    -- 玻璃层2
	Glass3= Color3.fromRGB(30, 30, 46),    -- 玻璃层3
	Phosphor= Color3.fromRGB(130, 100, 255), -- 磷光紫
	Cyan  = Color3.fromRGB(80, 200, 230),  -- 青
	Pink  = Color3.fromRGB(255, 100, 180), -- 粉
	Green = Color3.fromRGB(50, 230, 130),  -- 绿
	Red   = Color3.fromRGB(255, 70, 90),   -- 红
	Orange= Color3.fromRGB(255, 170, 50),  -- 橙
	White = Color3.fromRGB(240, 240, 250),
	Gray  = Color3.fromRGB(150, 150, 165),
	Gray2 = Color3.fromRGB(90, 90, 105),
	Line  = Color3.fromRGB(45, 45, 58),
	Glow  = Color3.fromRGB(130, 100, 255),
}

-- ==================== 工具 ====================
local function _(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props) do pcall(function() o[k] = v end) end
	if parent then o.Parent = parent end
	return o
end

local function R(p, r)
	_("UICorner", {CornerRadius = UDim.new(0, r or 10)}, p)
end
local function S(p, c, t)
	_("UIStroke", {Color = c or C.Line, Thickness = t or 1}, p)
end
local function G(p, c1, c2, rot)
	_("UIGradient", {
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, c1 or C.Phosphor),
			ColorSequenceKeypoint.new(1, c2 or C.Cyan),
		},
		Rotation = rot or 135,
	}, p)
end
local function TW(obj, props, dur, style, dir, cb)
	if not env.Tween then return end
	local ti = TweenInfo.new(dur or 0.3, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out, 0, false, 0)
	local tw = env.Tween:Create(obj, ti, props)
	tw:Play()
	if cb then tw.Completed:Connect(cb) end
	return tw
end

-- ==================== 清理 ====================
safe(function()
	local old = env.pgui:FindFirstChild("GlassUI")
	if old then old:Destroy(); wait(0.2) end
end)

-- ==================== ScreenGui ====================
local sg = _("ScreenGui", {
	Name = "GlassUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 99999,
}, env.pgui)

-- ==================== 主窗口 ====================
local W, H = 560, 490
local main = _("Frame", {
	Name = "Main",
	Size = UDim2.new(0, W, 0, H),
	Position = UDim2.new(0.5, -W/2, 0.5, -H/2),
	BackgroundColor3 = C.Base,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	BackgroundTransparency = 0.06,
}, sg)
R(main, 16)

-- 玻璃边框：半透明发光
S(main, Color3.fromRGB(90, 80, 140), 1.5)

-- 顶部渐变光条
local topGlow = _("Frame", {
	Size = UDim2.new(1, 0, 0, 2),
	BackgroundColor3 = C.Phosphor,
	BorderSizePixel = 0,
	ZIndex = 10,
}, main)
G(topGlow, C.Phosphor, C.Cyan, 90)

-- 背景微弱光晕
local bgGlow = _("Frame", {
	Size = UDim2.new(0, 300, 0, 300),
	Position = UDim2.new(0.5, -150, 0, -100),
	BackgroundColor3 = C.Phosphor,
	BackgroundTransparency = 0.95,
	BorderSizePixel = 0,
	ZIndex = 0,
}, main)
R(bgGlow, 150)

-- ==================== 标题栏 ====================
local titleBar = _("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = C.Glass,
	BorderSizePixel = 0,
	BackgroundTransparency = 0.08,
}, main)
R(titleBar, 16)
_("Frame", {
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 0, 1, -16),
	BackgroundColor3 = C.Glass,
	BorderSizePixel = 0,
	BackgroundTransparency = 0.08,
}, titleBar)

-- 标题图标
local icon = _("Frame", {
	Size = UDim2.new(0, 32, 0, 32),
	Position = UDim2.new(0, 16, 0.5, -16),
	BackgroundColor3 = C.Phosphor,
	BorderSizePixel = 0,
	BackgroundTransparency = 0.1,
}, titleBar)
R(icon, 10)
G(icon, C.Phosphor, C.Cyan, 45)
_("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "G",
	TextColor3 = C.White,
	TextSize = 16,
}, icon)

_("TextLabel", {
	Size = UDim2.new(1, -140, 1, 0),
	Position = UDim2.new(0, 56, 0, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Glass UI",
	TextColor3 = C.White,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

-- 关闭按钮
local closeBtn = _("TextButton", {
	Size = UDim2.new(0, 32, 0, 32),
	Position = UDim2.new(1, -42, 0.5, -16),
	BackgroundColor3 = Color3.fromRGB(255, 70, 90),
	BackgroundTransparency = 0.15,
	Text = "✕",
	TextColor3 = C.White,
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
	AutoButtonColor = false,
}, titleBar)
R(closeBtn, 10)

closeBtn.MouseEnter:Connect(function()
	TW(closeBtn, {BackgroundTransparency = 0}, 0.15)
end)
closeBtn.MouseLeave:Connect(function()
	TW(closeBtn, {BackgroundTransparency = 0.15}, 0.15)
end)
closeBtn.MouseButton1Click:Connect(function()
	TW(main, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
		sg:Destroy()
	end)
end)

-- ==================== 拖拽 ====================
local dragging, dragStart, winStart = false, nil, nil
titleBar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true; dragStart = i.Position; winStart = main.Position
	end
end)
titleBar.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
if env.UIS then
	env.UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			main.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset + d.X, winStart.Y.Scale, winStart.Y.Offset + d.Y)
		end
	end)
end

-- ==================== 内容区 ====================
local content = _("Frame", {
	Size = UDim2.new(1, 0, 1, -48),
	Position = UDim2.new(0, 0, 0, 48),
	BackgroundColor3 = C.Glass,
	BorderSizePixel = 0,
	BackgroundTransparency = 0.08,
}, main)

-- 左侧导航
local nav = _("Frame", {
	Size = UDim2.new(0, 160, 1, 0),
	BackgroundColor3 = C.Glass2,
	BorderSizePixel = 0,
	BackgroundTransparency = 0.06,
}, content)

-- 右侧页面
local pages = _("Frame", {
	Size = UDim2.new(1, -170, 1, 0),
	Position = UDim2.new(0, 170, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
}, content)

local scroll = _("ScrollingFrame", {
	Size = UDim2.new(1, -8, 1, 0),
	Position = UDim2.new(0, 8, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = C.Line,
	CanvasSize = UDim2.new(0, 0, 0, 0),
}, pages)

local scrollLayout = _("UIListLayout", {
	Padding = UDim.new(0, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scroll)

_("UIPadding", {
	PaddingTop = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 20),
}, scroll)

-- ==================== 导航 ====================
local navBtns = {}
local pageFrames = {}
local curPage = nil

local function makeNavBtn(name, _icon, index)
	local btn = _("TextButton", {
		Name = name,
		Size = UDim2.new(1, -24, 0, 40),
		Position = UDim2.new(0, 12, 0, 12 + (index - 1) * 46),
		BackgroundColor3 = (index == 1) and C.Glass3 or C.Glass2,
		BackgroundTransparency = (index == 1) and 0.05 or 0.06,
		Text = "  " .. (_icon or "") .. "  " .. name,
		TextColor3 = (index == 1) and C.White or C.Gray,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, nav)
	R(btn, 12)

	if index == 1 then
		local bar = _("Frame", {
			Name = "Indicator",
			Size = UDim2.new(0, 3, 0, 24),
			Position = UDim2.new(0, 0, 0.5, -12),
			BackgroundColor3 = C.Phosphor,
			BorderSizePixel = 0,
		}, btn)
		R(bar, 2)
		G(bar, C.Phosphor, C.Cyan, 0)
	end

	table.insert(navBtns, btn)
	return btn
end

local function switchPage(name)
	curPage = name
	for _, p in ipairs(pageFrames) do
		p.Visible = (p.Name == name)
	end
	for _, b in ipairs(navBtns) do
		local active = (b.Name == name)
		TW(b, {
			BackgroundColor3 = active and C.Glass3 or C.Glass2,
			TextColor3 = active and C.White or C.Gray,
		}, 0.25)
		local ind = b:FindFirstChild("Indicator")
		if active and not ind then
			ind = _("Frame", {
				Name = "Indicator",
				Size = UDim2.new(0, 3, 0, 24),
				Position = UDim2.new(0, 0, 0.5, -12),
				BackgroundColor3 = C.Phosphor,
				BorderSizePixel = 0,
			}, b)
			R(ind, 2); G(ind, C.Phosphor, C.Cyan, 0)
		elseif not active and ind then
			ind:Destroy()
		end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 10)
end

local function makePage(name)
	local p = _("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = (#pageFrames == 0),
	}, scroll)
	table.insert(pageFrames, p)
	return p
end

-- ==================== 组件: Section 玻璃卡片 ====================
local function Section(parent, title)
	local sec = _("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = C.Glass2,
		BorderSizePixel = 0,
		BackgroundTransparency = 0.06,
	}, parent)
	R(sec, 14)
	S(sec, C.Line, 1)

	if title then
		local hdr = _("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = C.Glass3,
			BorderSizePixel = 0,
			BackgroundTransparency = 0.05,
		}, sec)
		R(hdr, 14)
		_("Frame", {
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 1, -14),
			BackgroundColor3 = C.Glass3,
			BorderSizePixel = 0,
			BackgroundTransparency = 0.05,
		}, hdr)

		local bar = _("Frame", {
			Size = UDim2.new(0, 3, 0, 20),
			Position = UDim2.new(0, 0, 0.5, -10),
			BackgroundColor3 = C.Phosphor,
			BorderSizePixel = 0,
		}, hdr)
		R(bar, 2); G(bar, C.Phosphor, C.Cyan, 0)

		_("TextLabel", {
			Size = UDim2.new(1, -30, 1, 0),
			Position = UDim2.new(0, 14, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = title,
			TextColor3 = C.White,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, hdr)
	end

	local body = _("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 0, 0),
		Position = title and UDim2.new(0, 0, 0, 40) or UDim2.new(0, 0, 0, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, sec)

	local layout = _("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)

	_("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 12),
	}, body)

	return sec, body
end

-- ==================== 组件: 独立大开关 (带玻璃底座) ====================
local function BigToggle(parent, title, desc, cb, default)
	default = default or false
	local enabled = default

	-- 玻璃卡片容器
	local card = _("Frame", {
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = C.Glass,
		BorderSizePixel = 0,
		BackgroundTransparency = 0.1,
	}, parent)
	R(card, 12)
	S(card, C.Line, 1)

	-- 标题
	_("TextLabel", {
		Size = UDim2.new(1, -80, 0, 20),
		Position = UDim2.new(0, 16, 0, 10),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = C.White,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	-- 描述
	_("TextLabel", {
		Size = UDim2.new(1, -80, 0, 16),
		Position = UDim2.new(0, 16, 0, 32),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = desc or "",
		TextColor3 = C.Gray2,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	-- 开关底座
	local base = _("Frame", {
		Size = UDim2.new(0, 56, 0, 32),
		Position = UDim2.new(1, -72, 0.5, -16),
		BackgroundColor3 = C.Glass3,
		BorderSizePixel = 0,
		BackgroundTransparency = 0.05,
		ZIndex = 2,
	}, card)
	R(base, 16)

	-- 开关光环
	local ring = _("Frame", {
		Size = UDim2.new(0, 52, 0, 28),
		Position = UDim2.new(0.5, -26, 0.5, -14),
		BackgroundColor3 = C.Phosphor,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, base)
	R(ring, 14)

	-- 滑块
	local knob = _("Frame", {
		Size = UDim2.new(0, 26, 0, 26),
		Position = UDim2.new(0, 3, 0, 3),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, base)
	R(knob, 13)

	-- 滑块内发光点
	local dot = _("Frame", {
		Size = UDim2.new(0, 8, 0, 8),
		Position = UDim2.new(0.5, -4, 0.5, -4),
		BackgroundColor3 = C.Phosphor,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, knob)
	R(dot, 4)

	-- 点击区域
	local hit = _("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 10,
	}, card)

	-- 动画函数
	local function animate()
		if enabled then
			-- 底座变绿
			TW(base, {BackgroundColor3 = C.Green, BackgroundTransparency = 0.1}, 0.3)
			-- 光环变绿并扩大
			TW(ring, {
				BackgroundColor3 = C.Green,
				BackgroundTransparency = 0.7,
				Size = UDim2.new(0, 60, 0, 36),
				Position = UDim2.new(0.5, -30, 0.5, -18),
			}, 0.35)
			-- 滑块右移
			TW(knob, {Position = UDim2.new(1, -29, 0, 3)}, 0.3, Enum.EasingStyle.Quart)
			-- 内部点变绿
			TW(dot, {BackgroundColor3 = C.Green, BackgroundTransparency = 0}, 0.3)
			-- 卡片边框发光
			card:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(50, 200, 120)
		else
			TW(base, {BackgroundColor3 = C.Glass3, BackgroundTransparency = 0.05}, 0.3)
			TW(ring, {
				BackgroundColor3 = C.Phosphor,
				BackgroundTransparency = 0.85,
				Size = UDim2.new(0, 52, 0, 28),
				Position = UDim2.new(0.5, -26, 0.5, -14),
			}, 0.35)
			TW(knob, {Position = UDim2.new(0, 3, 0, 3)}, 0.3, Enum.EasingStyle.Quart)
			TW(dot, {BackgroundColor3 = C.Phosphor, BackgroundTransparency = 0.3}, 0.3)
			card:FindFirstChildOfClass("UIStroke").Color = C.Line
		end
	end

	-- 初始状态
	if enabled then
		base.BackgroundColor3 = C.Green
		base.BackgroundTransparency = 0.1
		knob.Position = UDim2.new(1, -29, 0, 3)
		dot.BackgroundColor3 = C.Green
		dot.BackgroundTransparency = 0
		ring.BackgroundColor3 = C.Green
		ring.BackgroundTransparency = 0.7
		ring.Size = UDim2.new(0, 60, 0, 36)
		ring.Position = UDim2.new(0.5, -30, 0.5, -18)
		card:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(50, 200, 120)
	end

	hit.MouseButton1Click:Connect(function()
		enabled = not enabled
		animate()
		if cb then cb(enabled) end
	end)

	-- 悬停
	hit.MouseEnter:Connect(function()
		TW(card, {BackgroundTransparency = 0.04}, 0.2)
	end)
	hit.MouseLeave:Connect(function()
		TW(card, {BackgroundTransparency = 0.1}, 0.2)
	end)

	return {
		Card = card,
		Get = function() return enabled end,
		Set = function(v) enabled = v; animate() end,
	}
end

-- ==================== 组件: 按钮 ====================
local function Button(parent, text, cb, opts)
	opts = opts or {}
	local btn = _("TextButton", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = opts.Color or C.Phosphor,
		BackgroundTransparency = 0.1,
		Text = text,
		TextColor3 = C.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, parent)
	R(btn, 12)
	if not opts.NoGradient then
		G(btn, opts.Color or C.Phosphor, opts.Color2 or C.Cyan, 90)
	end

	btn.MouseEnter:Connect(function()
		TW(btn, {BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, 42)}, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		TW(btn, {BackgroundTransparency = 0.1, Size = UDim2.new(1, 0, 0, 40)}, 0.15)
	end)
	btn.MouseButton1Down:Connect(function()
		TW(btn, {Size = UDim2.new(1, -4, 0, 38)}, 0.05)
	end)
	btn.MouseButton1Up:Connect(function()
		TW(btn, {Size = UDim2.new(1, 0, 0, 40)}, 0.1)
	end)
	btn.MouseButton1Click:Connect(function()
		-- 涟漪效果
		pcall(function()
			local ripple = _("Frame", {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = C.White,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, btn)
			R(ripple, 50)
			TW(ripple, {
				Size = UDim2.new(0, 300, 0, 300),
				BackgroundTransparency = 1,
			}, 0.5, nil, nil, function() ripple:Destroy() end)
		end)
		if cb then cb() end
	end)
	return btn
end

-- ==================== 组件: 滑块 ====================
local function Slider(parent, title, cb, opts)
	opts = opts or {}
	local mn, mx, val = opts.Min or 0, opts.Max or 100, opts.Default or 50

	local card = _("Frame", {
		Size = UDim2.new(1, 0, 0, 68),
		BackgroundColor3 = C.Glass,
		BorderSizePixel = 0,
		BackgroundTransparency = 0.1,
	}, parent)
	R(card, 12); S(card, C.Line, 1)

	-- 标题 + 数值
	local row = _("Frame", {
		Size = UDim2.new(1, -32, 0, 22),
		Position = UDim2.new(0, 16, 0, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, card)

	_("TextLabel", {
		Size = UDim2.new(0.7, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = C.White,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local valLabel = _("TextLabel", {
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(0.7, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(val),
		TextColor3 = C.Cyan,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)

	-- 轨道
	local track = _("Frame", {
		Size = UDim2.new(1, -32, 0, 8),
		Position = UDim2.new(0, 16, 0, 38),
		BackgroundColor3 = C.Glass3,
		BorderSizePixel = 0,
		BackgroundTransparency = 0.05,
	}, card)
	R(track, 4)

	-- 填充
	local fill = _("Frame", {
		Size = UDim2.new((val - mn) / (mx - mn), 0, 1, 0),
		BackgroundColor3 = C.Phosphor,
		BorderSizePixel = 0,
	}, track)
	R(fill, 4); G(fill, C.Phosphor, C.Cyan, 90)

	-- 拖拽球
	local knob = _("Frame", {
		Size = UDim2.new(0, 22, 0, 22),
		Position = UDim2.new((val - mn) / (mx - mn), -11, 0.5, -11),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ZIndex = 5,
		BackgroundTransparency = 0.05,
	}, track)
	R(knob, 11)
	S(knob, C.Phosphor, 2)

	-- 拖拽球光晕
	local knobGlow = _("Frame", {
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(0.5, -15, 0.5, -15),
		BackgroundColor3 = C.Phosphor,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, knob)
	R(knobGlow, 15)

	local function setValFromPos(x)
		local ratio = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		val = math.floor(mn + ratio * (mx - mn) + 0.5)
		val = math.clamp(val, mn, mx)
		ratio = (val - mn) / (mx - mn)
		TW(fill, {Size = UDim2.new(ratio, 0, 1, 0)}, 0.05)
		TW(knob, {Position = UDim2.new(ratio, -11, 0.5, -11)}, 0.05)
		valLabel.Text = tostring(val)
		if cb then cb(val) end
	end

	local dragging = false
	knob.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			TW(knobGlow, {BackgroundTransparency = 0.5, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0.5, -20, 0.5, -20)}, 0.15)
		end
	end)
	knob.InputEnded:Connect(function()
		dragging = false
		TW(knobGlow, {BackgroundTransparency = 0.8, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0.5, -15, 0.5, -15)}, 0.2)
	end)
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setValFromPos(i.Position.X)
			TW(knobGlow, {BackgroundTransparency = 0.5, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0.5, -20, 0.5, -20)}, 0.15)
		end
	end)
	track.InputEnded:Connect(function()
		dragging = false
		TW(knobGlow, {BackgroundTransparency = 0.8, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0.5, -15, 0.5, -15)}, 0.2)
	end)
	if env.UIS then
		env.UIS.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				if env.mouse then setValFromPos(env.mouse.X) end
			end
		end)
	end

	return {
		Card = card,
		Get = function() return val end,
		Set = function(v) val = math.clamp(v, mn, mx); local r = (val - mn) / (mx - mn); fill.Size = UDim2.new(r, 0, 1, 0); knob.Position = UDim2.new(r, -11, 0.5, -11); valLabel.Text = tostring(val) end,
	}
end

-- ==================== 组件: 下拉菜单 ====================
local function Dropdown(parent, title, options, cb, opts)
	opts = opts or {}
	local selected = opts.Default or options[1]
	local expanded = false

	local card = _("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = C.Glass,
		BorderSizePixel = 0,
		BackgroundTransparency = 0.1,
	}, parent)
	R(card, 12); S(card, C.Line, 1)

	_("TextLabel", {
		Size = UDim2.new(1, -32, 0, 20),
		Position = UDim2.new(0, 16, 0, 8),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = C.White,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	-- 下拉头
	local header = _("TextButton", {
		Size = UDim2.new(1, -32, 0, 36),
		Position = UDim2.new(0, 16, 0, 32),
		BackgroundColor3 = C.Glass3,
		BackgroundTransparency = 0.05,
		Text = selected,
		TextColor3 = C.White,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, card)
	R(header, 10)
	_("UIPadding", {PaddingLeft = UDim.new(0, 12)}, header)

	local arrow = _("TextLabel", {
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -24, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "▾",
		TextColor3 = C.Gray,
		TextSize = 10,
	}, header)

	-- 选项列表
	local list = _("Frame", {
		Name = "List",
		Size = UDim2.new(1, -32, 0, 0),
		Position = UDim2.new(0, 16, 0, 72),
		BackgroundColor3 = C.Glass3,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
	}, card)
	R(list, 10); S(list, C.Line, 1)
	_("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, list)

	for _, opt in ipairs(options) do
		local ob = _("TextButton", {
			Name = opt,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = (opt == selected) and C.Glass or C.Glass3,
			BackgroundTransparency = (opt == selected) and 0.1 or 0.05,
			Text = opt,
			TextColor3 = C.White,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			AutoButtonColor = false,
		}, list)
		_("UIPadding", {PaddingLeft = UDim.new(0, 12)}, ob)

		ob.MouseEnter:Connect(function()
			TW(ob, {BackgroundColor3 = C.Glass, BackgroundTransparency = 0.1}, 0.1)
		end)
		ob.MouseLeave:Connect(function()
			if opt ~= selected then TW(ob, {BackgroundColor3 = C.Glass3, BackgroundTransparency = 0.05}, 0.1) end
		end)
		ob.MouseButton1Click:Connect(function()
			selected = opt
			header.Text = opt
			for _, c in ipairs(list:GetChildren()) do
				if c:IsA("TextButton") then
					TW(c, {BackgroundColor3 = (c.Name == opt) and C.Glass or C.Glass3, BackgroundTransparency = (c.Name == opt) and 0.1 or 0.05}, 0.2)
				end
			end
			expanded = false
			TW(list, {Size = UDim2.new(1, -32, 0, 0)}, 0.2, nil, nil, function() list.Visible = false end)
			TW(arrow, {Rotation = 0}, 0.2)
			if cb then cb(opt) end
		end)
	end

	header.MouseButton1Click:Connect(function()
		expanded = not expanded
		if expanded then
			list.Visible = true
			list.Size = UDim2.new(1, -32, 0, 0)
			TW(list, {Size = UDim2.new(1, -32, 0, 32 * #options)}, 0.25)
			TW(arrow, {Rotation = 180}, 0.25)
		else
			TW(list, {Size = UDim2.new(1, -32, 0, 0)}, 0.2, nil, nil, function() list.Visible = false end)
			TW(arrow, {Rotation = 0}, 0.2)
		end
	end)

	return {
		Card = card,
		Get = function() return selected end,
		Set = function(v) selected = v; header.Text = v end,
	}
end

-- ==================== 通知 Toast ====================
local function Toast(title, msg, dur, color)
	dur = dur or 3
	color = color or C.Phosphor

	local toast = _("Frame", {
		Name = "Toast",
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(1, 0, 0, 20),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = C.Glass,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 999,
		BackgroundTransparency = 0.06,
	}, sg)
	R(toast, 12); S(toast, color, 1.5)

	local bar = _("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, toast)
	G(bar, color, C.Cyan, 0)

	_("TextLabel", {
		Size = UDim2.new(1, -36, 0, 18),
		Position = UDim2.new(0, 14, 0, 8),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = C.White,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, toast)

	_("TextLabel", {
		Size = UDim2.new(1, -36, 0, 16),
		Position = UDim2.new(0, 14, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = msg,
		TextColor3 = C.Gray,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, toast)

	local prog = _("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, toast)

	toast.Size = UDim2.new(0, 280, 0, 52)
	TW(prog, {Size = UDim2.new(0, 0, 0, 2)}, dur, Enum.EasingStyle.Linear)

	delay(dur, function()
		pcall(function()
			TW(toast, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
				toast:Destroy()
			end)
		end)
	end)

	return toast
end

-- ==================== 构建页面 ====================

-- ===== 主页 =====
local home = makePage("主页")

local hs1, hb1 = Section(home, "欢迎")
hs1.Size = UDim2.new(1, 0, 0, 70)

_("TextLabel", {
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "Glass UI v3.0\n夜态玻璃 · 磷光渐变 · 全组件动画",
	TextColor3 = C.Gray,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
}, hb1)

local hs2, hb2 = Section(home, "通知测试")
hs2.Size = UDim2.new(1, 0, 0, 110)

Button(hb2, "发送成功通知", function()
	Toast("完成", "操作已成功执行", 3, C.Green)
end, {Color = C.Green, Color2 = Color3.fromRGB(40, 200, 100)})

Button(hb2, "发送警告通知", function()
	Toast("注意", "请检查你的设置", 3, C.Orange)
end, {Color = C.Orange, Color2 = Color3.fromRGB(255, 140, 30)})

-- ===== 功能页 =====
local func = makePage("功能开关")

-- 独立大开关
local fs1, fb1 = Section(func, nil)
fs1.Size = UDim2.new(1, 0, 0, 160)

BigToggle(fb1, "自动瞄准", "自动锁定附近的敌对目标", function(v)
	Toast("自动瞄准", v and "已开启" or "已关闭", 2, v and C.Green or C.Gray2)
end, false)

BigToggle(fb1, "ESP 透视", "显示敌人位置、血量与距离信息", function(v)
	Toast("ESP透视", v and "已开启" or "已关闭", 2, v and C.Green or C.Gray2)
end, false)

-- 更多开关
local fs2, fb2 = Section(func, nil)
fs2.Size = UDim2.new(1, 0, 0, 160)

BigToggle(fb2, "无限跳跃", "取消跳跃冷却时间", function(v)
	Toast("无限跳跃", v and "已开启" or "已关闭", 2, v and C.Green or C.Gray2)
end, false)

BigToggle(fb2, "飞行模式", "允许角色在空中自由移动", function(v)
	Toast("飞行模式", v and "已开启" or "已关闭", 2, v and C.Green or C.Gray2)
end, false)

-- ===== 设置页 =====
local set = makePage("参数设置")

local ss1, sb1 = Section(set, "移动参数")
ss1.Size = UDim2.new(1, 0, 0, 100)

Slider(sb1, "移动速度", function(v) end, {Min = 1, Max = 100, Default = 50})
Slider(sb1, "跳跃高度", function(v) end, {Min = 10, Max = 200, Default = 70})

local ss2, sb2 = Section(set, "武器选项")
ss2.Size = UDim2.new(1, 0, 0, 100)

Dropdown(sb2, "主武器", {"手枪", "步枪", "狙击枪", "霰弹枪", "冲锋枪"}, function(v)
	Toast("主武器", "已选择: " .. v, 2)
end)
Dropdown(sb2, "模式", {"经典模式", "竞技模式", "自定义"}, function(v)
	Toast("模式", "已选择: " .. v, 2)
end)

-- ===== 关于页 =====
local about = makePage("关于")

local as1, ab1 = Section(about, "Glass UI")
as1.Size = UDim2.new(1, 0, 0, 110)

_("TextLabel", {
	Size = UDim2.new(1, 0, 0, 84),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "Glass UI v3.0\n\n深色玻璃拟态设计\n磷光紫 + 青色渐变点缀\n所有组件独立化，全动画驱动\n\n为 Roblox 注入器环境打造",
	TextColor3 = C.Gray,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
}, ab1)

-- ==================== 导航按钮 ====================
local bn1 = makeNavBtn("主页", "◆", 1)
local bn2 = makeNavBtn("功能开关", "◈", 2)
local bn3 = makeNavBtn("参数设置", "◇", 3)
local bn4 = makeNavBtn("关于", "○", 4)

bn1.MouseButton1Click:Connect(function() switchPage("主页") end)
bn2.MouseButton1Click:Connect(function() switchPage("功能开关") end)
bn3.MouseButton1Click:Connect(function() switchPage("参数设置") end)
bn4.MouseButton1Click:Connect(function() switchPage("关于") end)

for _, b in ipairs({bn1, bn2, bn3, bn4}) do
	b.MouseEnter:Connect(function()
		if curPage ~= b.Name then TW(b, {BackgroundColor3 = C.Glass3, BackgroundTransparency = 0.05}, 0.15) end
	end)
	b.MouseLeave:Connect(function()
		if curPage ~= b.Name then TW(b, {BackgroundColor3 = C.Glass2, BackgroundTransparency = 0.06}, 0.15) end
	end)
end

curPage = "主页"

-- ==================== 入场动画 ====================
main.Size = UDim2.new(0, 0, 0, 0)
main.BackgroundTransparency = 0.8
TW(main, {
	Size = UDim2.new(0, W, 0, H),
	BackgroundTransparency = 0.06,
}, 0.5, Enum.EasingStyle.Back)

delay(0.6, function()
	pcall(function() Toast("Glass UI", "v3.0 夜态玻璃已就绪", 4, C.Phosphor) end)
end)

print("========================================")
print(" Glass UI v3.0 - 夜态玻璃")
print(" 独立开关 · 全动画 · 磷光渐变")
print("========================================")