--[[
	LuminaUI v2.0 - 高颜值独立版
	玻璃拟态 · 渐变光效 · 流畅动画
	复制全部代码到注入器执行即可
]]

-- ==================== 环境检测 ====================
print("[Lumina] 启动中...")

local env = {}
local function safe(fn, errMsg)
	local ok, result = pcall(fn)
	if not ok then print("[Lumina] " .. (errMsg or "错误") .. ": " .. tostring(result)) end
	return ok, result
end

safe(function() env.game = game end, "game对象不存在")
if not env.game then return end

safe(function() env.Players = env.game:GetService("Players") end)
safe(function() env.Tween = env.game:GetService("TweenService") end)
safe(function() env.UIS = env.game:GetService("UserInputService") end)
safe(function() env.Run = env.game:GetService("RunService") end)

-- 等 Player
for i = 1, 100 do
	safe(function()
		env.plr = env.Players.LocalPlayer or env.Players:FindFirstChildOfClass("Player")
	end)
	if env.plr then break end
	wait(0.1)
end
if not env.plr then print("[Lumina] 无法获取LocalPlayer"); return end

-- 等 PlayerGui
safe(function()
	env.pgui = env.plr:FindFirstChild("PlayerGui")
	if not env.pgui then env.pgui = env.plr:WaitForChild("PlayerGui", 5) end
end)
if not env.pgui then print("[Lumina] 无法获取PlayerGui"); return end

safe(function() env.mouse = env.plr:GetMouse() end)

print("[Lumina] 环境就绪 | 玩家: " .. env.plr.Name)

-- ==================== 颜色主题 ====================
local C = {
	Bg     = Color3.fromRGB(10, 10, 16),
	Bg2    = Color3.fromRGB(16, 16, 26),
	Card   = Color3.fromRGB(20, 20, 32),
	Card2  = Color3.fromRGB(26, 26, 42),
	Accent = Color3.fromRGB(120, 80, 255),   -- 紫色主色
	Accent2= Color3.fromRGB(255, 80, 160),   -- 粉色辅色
	Green  = Color3.fromRGB(40, 220, 120),
	Red    = Color3.fromRGB(255, 65, 85),
	Orange = Color3.fromRGB(255, 160, 50),
	White  = Color3.fromRGB(255, 255, 255),
	Gray   = Color3.fromRGB(150, 150, 165),
	Gray2  = Color3.fromRGB(100, 100, 115),
	Line   = Color3.fromRGB(40, 40, 55),
}

-- ==================== 工具函数 ====================
local function New(cls, props, parent)
	local obj = Instance.new(cls)
	for k, v in pairs(props) do pcall(function() obj[k] = v end) end
	if parent then obj.Parent = parent end
	return obj
end

local function Corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = p
	return c
end

local function Stroke(p, color, t)
	local s = Instance.new("UIStroke")
	s.Color = color or C.Line
	s.Thickness = t or 1
	s.Parent = p
	return s
end

local function Gradient(p, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, c1 or C.Accent),
		ColorSequenceKeypoint.new(1, c2 or C.Accent2),
	}
	g.Rotation = rot or 135
	g.Parent = p
	return g
end

local function Tween(obj, props, dur, style, dir, cb)
	if not env.Tween then return end
	dur = dur or 0.3
	local ti = TweenInfo.new(dur, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out, 0, false, 0)
	local tw = env.Tween:Create(obj, ti, props)
	tw:Play()
	if cb then tw.Completed:Connect(cb) end
	return tw
end

-- ==================== 清理旧UI ====================
safe(function()
	local old = env.pgui:FindFirstChild("LuminaUI")
	if old then old:Destroy(); wait(0.2) end
end)

-- ==================== ScreenGui ====================
local sg = New("ScreenGui", {
	Name = "LuminaUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 99999,
}, env.pgui)

-- ==================== 主窗口背景 ====================
local main = New("Frame", {
	Name = "Main",
	Size = UDim2.new(0, 520, 0, 440),
	Position = UDim2.new(0.5, -260, 0.5, -220),
	BackgroundColor3 = C.Bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	BackgroundTransparency = 0.04,
}, sg)
Corner(main, 14)

-- 主窗口渐变边框
Stroke(main, C.Accent, 1.5)

-- 顶部光晕装饰
local glow = New("Frame", {
	Size = UDim2.new(1, 0, 0, 2),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = C.Accent,
	BorderSizePixel = 0,
	ZIndex = 10,
}, main)
Gradient(glow, C.Accent, C.Accent2, 90)

-- ==================== 标题栏 ====================
local titleBar = New("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundColor3 = C.Bg2,
	BorderSizePixel = 0,
}, main)
Corner(titleBar, 14)
-- 底部填充
New("Frame", {
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.new(0, 0, 1, -14),
	BackgroundColor3 = C.Bg2,
	BorderSizePixel = 0,
}, titleBar)

-- Logo 图标
local logo = New("Frame", {
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(0, 14, 0.5, -14),
	BackgroundColor3 = C.Accent,
	BorderSizePixel = 0,
}, titleBar)
Corner(logo, 8)
Gradient(logo, C.Accent, C.Accent2, 45)

local logoText = New("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "L",
	TextColor3 = C.White,
	TextSize = 16,
}, logo)

-- 标题
New("TextLabel", {
	Size = UDim2.new(1, -130, 1, 0),
	Position = UDim2.new(0, 50, 0, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "LuminaUI",
	TextColor3 = C.White,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

-- 最小化按钮
local minBtn = New("TextButton", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -74, 0.5, -15),
	BackgroundColor3 = Color3.fromRGB(255, 180, 50),
	Text = "—",
	TextColor3 = C.White,
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
	AutoButtonColor = false,
}, titleBar)
Corner(minBtn, 8)

-- 关闭按钮
local closeBtn = New("TextButton", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -38, 0.5, -15),
	BackgroundColor3 = Color3.fromRGB(255, 70, 80),
	Text = "✕",
	TextColor3 = C.White,
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
	AutoButtonColor = false,
}, titleBar)
Corner(closeBtn, 8)

-- 关闭事件
local minimized = false
local origSize = UDim2.new(0, 520, 0, 440)

closeBtn.MouseButton1Click:Connect(function()
	Tween(main, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
		sg:Destroy()
	end)
end)

minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		Tween(main, {Size = UDim2.new(0, 520, 0, 44)}, 0.3)
	else
		Tween(main, {Size = origSize}, 0.4, Enum.EasingStyle.Elastic)
	end
end)

-- 按钮悬停
for _, b in ipairs({closeBtn, minBtn}) do
	b.MouseEnter:Connect(function()
		local c = b.BackgroundColor3
		Tween(b, {BackgroundColor3 = Color3.new(c.R * 0.8, c.G * 0.8, c.B * 0.8)}, 0.15)
	end)
	b.MouseLeave:Connect(function()
		local c = b.BackgroundColor3
		-- restore
		if b == closeBtn then Tween(b, {BackgroundColor3 = Color3.fromRGB(255, 70, 80)}, 0.15)
		else Tween(b, {BackgroundColor3 = Color3.fromRGB(255, 180, 50)}, 0.15) end
	end)
end

-- ==================== 拖拽 ====================
local dragging, dragStart, winStart = false, nil, nil
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		winStart = main.Position
	end
end)
titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
if env.UIS then
	env.UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset + delta.X, winStart.Y.Scale, winStart.Y.Offset + delta.Y)
		end
	end)
end

-- ==================== 内容区 ====================
local content = New("Frame", {
	Name = "Content",
	Size = UDim2.new(1, 0, 1, -44),
	Position = UDim2.new(0, 0, 0, 44),
	BackgroundColor3 = C.Bg2,
	BorderSizePixel = 0,
}, main)

-- ==================== 左侧导航 ====================
local nav = New("Frame", {
	Name = "Nav",
	Size = UDim2.new(0, 150, 1, 0),
	BackgroundColor3 = C.Bg,
	BorderSizePixel = 0,
}, content)

-- 右侧页面区
local pages = New("Frame", {
	Name = "Pages",
	Size = UDim2.new(1, -160, 1, 0),
	Position = UDim2.new(0, 160, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
}, content)

-- 页面滚动
local scroll = New("ScrollingFrame", {
	Name = "Scroll",
	Size = UDim2.new(1, -6, 1, 0),
	Position = UDim2.new(0, 6, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = C.Line,
	CanvasSize = UDim2.new(0, 0, 0, 0),
}, pages)

local scrollLayout = New("UIListLayout", {
	Padding = UDim.new(0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scroll)

New("UIPadding", {
	PaddingTop = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 6),
	PaddingBottom = UDim.new(0, 20),
}, scroll)

-- ==================== 导航按钮 ====================
local navBtns = {}
local pageFrames = {}
local curPage = nil

local function makeNavBtn(name, icon, index)
	local btn = New("TextButton", {
		Name = name,
		Size = UDim2.new(1, -20, 0, 38),
		Position = UDim2.new(0, 10, 0, 10 + (index - 1) * 44),
		BackgroundColor3 = (index == 1) and C.Card2 or C.Bg,
		Text = "  " .. (icon or "") .. "  " .. name,
		TextColor3 = (index == 1) and C.White or C.Gray,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, nav)
	Corner(btn, 10)

	-- 选中指示条
	if index == 1 then
		local bar = New("Frame", {
			Name = "Indicator",
			Size = UDim2.new(0, 3, 0, 22),
			Position = UDim2.new(0, 0, 0.5, -11),
			BackgroundColor3 = C.Accent,
			BorderSizePixel = 0,
		}, btn)
		Corner(bar, 2)
		Gradient(bar, C.Accent, C.Accent2, 0)
	end

	table.insert(navBtns, btn)
	return btn
end

local function switchPage(name)
	curPage = name
	for _, p in ipairs(pageFrames) do
		p.Visible = (p.Name == name)
		if p.Visible then Tween(p, {BackgroundTransparency = 0}, 0.2) end
	end
	for _, b in ipairs(navBtns) do
		local isActive = (b.Name == name)
		Tween(b, {
			BackgroundColor3 = isActive and C.Card2 or C.Bg,
			TextColor3 = isActive and C.White or C.Gray,
		}, 0.2)
		local ind = b:FindFirstChild("Indicator")
		if isActive and not ind then
			ind = New("Frame", {
				Name = "Indicator",
				Size = UDim2.new(0, 3, 0, 22),
				Position = UDim2.new(0, 0, 0.5, -11),
				BackgroundColor3 = C.Accent,
				BorderSizePixel = 0,
			}, b)
			Corner(ind, 2)
			Gradient(ind, C.Accent, C.Accent2, 0)
		elseif not isActive and ind then
			ind:Destroy()
		end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 10)
end

-- ==================== 创建页面 ====================
local function makePage(name)
	local p = New("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = (#pageFrames == 0),
	}, scroll)
	table.insert(pageFrames, p)
	return p
end

-- ==================== 组件：Section ====================
local function Section(parent, title)
	local sec = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		BackgroundTransparency = 0.05,
	}, parent)
	Corner(sec, 12)
	Stroke(sec, C.Line, 1)

	-- 标题区
	local hdr = New("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
	}, sec)
	Corner(hdr, 12)
	New("Frame", {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
	}, hdr)

	-- 左侧色条
	local bar = New("Frame", {
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.new(0, 0, 0.5, -9),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
	}, hdr)
	Corner(bar, 2)
	Gradient(bar, C.Accent, C.Accent2, 0)

	New("TextLabel", {
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = C.White,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, hdr)

	-- 内容区
	local body = New("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 38),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, sec)

	local layout = New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)

	New("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 10),
	}, body)

	return sec, body
end

-- ==================== 组件：Button ====================
local function Button(parent, text, cb, opts)
	opts = opts or {}
	local btn = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = opts.Color or C.Accent,
		Text = text,
		TextColor3 = C.White,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, parent)
	Corner(btn, 8)
	if not opts.NoGradient then Gradient(btn, opts.Color or C.Accent, opts.Color2 or C.Accent2, 90) end

	local origColor = btn.BackgroundColor3
	btn.MouseEnter:Connect(function()
		Tween(btn, {Size = UDim2.new(1, 0, 0, 38)}, 0.12)
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, {Size = UDim2.new(1, 0, 0, 36)}, 0.12)
	end)
	btn.MouseButton1Down:Connect(function()
		Tween(btn, {Size = UDim2.new(1, -4, 0, 34)}, 0.06)
	end)
	btn.MouseButton1Up:Connect(function()
		Tween(btn, {Size = UDim2.new(1, 0, 0, 36)}, 0.1)
	end)
	btn.MouseButton1Click:Connect(function()
		-- 涟漪
		pcall(function()
			local ripple = New("Frame", {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = C.White,
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, btn)
			Corner(ripple, 50)
			Tween(ripple, {
				Size = UDim2.new(0, 200, 0, 200),
				BackgroundTransparency = 1,
			}, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function() ripple:Destroy() end)
		end)
		if cb then cb() end
	end)
	return btn
end

-- ==================== 组件：Toggle ====================
local function Toggle(parent, text, cb, default)
	default = default or false
	local enabled = default

	local container = New("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, parent)

	New("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = C.Gray,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, container)

	local bg = New("Frame", {
		Size = UDim2.new(0, 50, 0, 28),
		Position = UDim2.new(1, -54, 0.5, -14),
		BackgroundColor3 = C.Line,
		BorderSizePixel = 0,
	}, container)
	Corner(bg, 14)

	local knob = New("Frame", {
		Size = UDim2.new(0, 22, 0, 22),
		Position = UDim2.new(0, 3, 0, 3),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, bg)
	Corner(knob, 11)

	local hit = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 10,
	}, container)

	local function update()
		if enabled then
			Tween(bg, {BackgroundColor3 = C.Green}, 0.25)
			Tween(knob, {Position = UDim2.new(1, -25, 0, 3)}, 0.25)
		else
			Tween(bg, {BackgroundColor3 = C.Line}, 0.25)
			Tween(knob, {Position = UDim2.new(0, 3, 0, 3)}, 0.25)
		end
	end
	update()

	hit.MouseButton1Click:Connect(function()
		enabled = not enabled
		update()
		if cb then cb(enabled) end
	end)

	return {Get = function() return enabled end, Set = function(v) enabled = v; update() end}
end

-- ==================== 组件：Slider ====================
local function Slider(parent, text, cb, opts)
	opts = opts or {}
	local min = opts.Min or 0
	local max = opts.Max or 100
	local val = opts.Default or 50

	local container = New("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, parent)

	-- 标签 + 数值
	local labelRow = New("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, container)

	New("TextLabel", {
		Size = UDim2.new(0.7, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = C.Gray,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, labelRow)

	local valLabel = New("TextLabel", {
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(0.7, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(val),
		TextColor3 = C.Accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, labelRow)

	-- 轨道
	local track = New("Frame", {
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 0, 26),
		BackgroundColor3 = C.Line,
		BorderSizePixel = 0,
	}, container)
	Corner(track, 4)

	local fill = New("Frame", {
		Size = UDim2.new((val - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
	}, track)
	Corner(fill, 4)
	Gradient(fill, C.Accent, C.Accent2, 90)

	local knob = New("Frame", {
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new((val - min) / (max - min), -10, 0.5, -10),
		BackgroundColor3 = C.White,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, track)
	Corner(knob, 10)
	Stroke(knob, C.Accent, 2)

	local function setVal(x)
		local ratio = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		val = math.floor(min + ratio * (max - min) + 0.5)
		val = math.clamp(val, min, max)
		ratio = (val - min) / (max - min)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, -10, 0.5, -10)
		valLabel.Text = tostring(val)
		if cb then cb(val) end
	end

	local dragging = false
	knob.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	knob.InputEnded:Connect(function() dragging = false end)
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setVal(i.Position.X)
		end
	end)
	track.InputEnded:Connect(function() dragging = false end)
	if env.UIS then
		env.UIS.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				if env.mouse then setVal(env.mouse.X) end
			end
		end)
	end

	return {Get = function() return val end, Set = function(v) val = math.clamp(v, min, max); local r = (val - min) / (max - min); fill.Size = UDim2.new(r, 0, 1, 0); knob.Position = UDim2.new(r, -10, 0.5, -10); valLabel.Text = tostring(val) end}
end

-- ==================== 组件：Dropdown ====================
local function Dropdown(parent, text, options, cb, opts)
	opts = opts or {}
	local selected = opts.Default or options[1]
	local expanded = false

	local container = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, parent)

	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = C.Gray,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, container)

	local header = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = C.Card2,
		Text = selected,
		TextColor3 = C.White,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, container)
	Corner(header, 8)
	New("UIPadding", {PaddingLeft = UDim.new(0, 12)}, header)

	-- 箭头
	local arrow = New("TextLabel", {
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -24, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "▾",
		TextColor3 = C.Gray,
		TextSize = 10,
	}, header)

	-- 选项列表
	local list = New("Frame", {
		Name = "List",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 60),
		BackgroundColor3 = C.Card2,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
	}, container)
	Corner(list, 8)
	Stroke(list, C.Line, 1)

	New("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, list)

	for _, opt in ipairs(options) do
		local ob = New("TextButton", {
			Name = opt,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = (opt == selected) and C.Card or C.Card2,
			Text = opt,
			TextColor3 = C.White,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			AutoButtonColor = false,
		}, list)
		New("UIPadding", {PaddingLeft = UDim.new(0, 12)}, ob)

		ob.MouseEnter:Connect(function()
			Tween(ob, {BackgroundColor3 = C.Card}, 0.1)
		end)
		ob.MouseLeave:Connect(function()
			if opt ~= selected then Tween(ob, {BackgroundColor3 = C.Card2}, 0.1) end
		end)
		ob.MouseButton1Click:Connect(function()
			selected = opt
			header.Text = opt
			-- 更新高亮
			for _, c in ipairs(list:GetChildren()) do
				if c:IsA("TextButton") then
					Tween(c, {BackgroundColor3 = (c.Name == opt) and C.Card or C.Card2}, 0.2)
				end
			end
			expanded = false
			Tween(list, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, nil, nil, function() list.Visible = false end)
			Tween(arrow, {Rotation = 0}, 0.2)
			if cb then cb(opt) end
		end)
	end

	header.MouseButton1Click:Connect(function()
		expanded = not expanded
		if expanded then
			list.Visible = true
			list.Size = UDim2.new(1, 0, 0, 0)
			Tween(list, {Size = UDim2.new(1, 0, 0, 30 * #options)}, 0.25)
			Tween(arrow, {Rotation = 180}, 0.25)
		else
			Tween(list, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, nil, nil, function() list.Visible = false end)
			Tween(arrow, {Rotation = 0}, 0.2)
		end
	end)

	return {Get = function() return selected end, Set = function(v) selected = v; header.Text = v end}
end

-- ==================== 通知 Toast ====================
local function Toast(title, msg, duration, color)
	duration = duration or 3
	color = color or C.Accent

	local toast = New("Frame", {
		Name = "Toast",
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(1, 0, 0, 16),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 999,
		BackgroundTransparency = 0.05,
	}, sg)
	Corner(toast, 10)
	Stroke(toast, color, 1.5)

	-- 左侧色条
	local bar = New("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, toast)
	Gradient(bar, color, C.Accent2, 0)

	New("TextLabel", {
		Size = UDim2.new(1, -36, 0, 18),
		Position = UDim2.new(0, 14, 0, 8),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = C.White,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, toast)

	New("TextLabel", {
		Size = UDim2.new(1, -36, 0, 16),
		Position = UDim2.new(0, 14, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = msg,
		TextColor3 = C.Gray,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, toast)

	-- 进度条
	local prog = New("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, toast)

	-- 入场
	toast.Size = UDim2.new(0, 280, 0, 52)
	Tween(prog, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

	-- 自动关闭
	delay(duration, function()
		pcall(function()
			Tween(toast, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
				toast:Destroy()
			end)
		end)
	end)

	return toast
end

-- ==================== 构建页面 ====================

-- ---- 主页 ----
local homePage = makePage("主页")

local s1, b1 = Section(homePage, "欢迎回来")
s1.Size = UDim2.new(1, 0, 0, 56)

New("TextLabel", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "LuminaUI v2.0 已就绪\n所有组件均可交互，尽情体验",
	TextColor3 = C.Gray,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
}, b1)

local s2, b2 = Section(homePage, "快速操作")
s2.Size = UDim2.new(1, 0, 0, 100)

Button(b2, "发送成功通知", function()
	Toast("操作成功", "任务已完成！", 3, C.Green)
end, {Color = C.Green, Color2 = Color3.fromRGB(40, 200, 100)})

Button(b2, "发送警告通知", function()
	Toast("请注意", "这是一个警告信息", 3, C.Orange)
end, {Color = C.Orange, Color2 = Color3.fromRGB(255, 140, 30)})

-- ---- 设置页 ----
local setPage = makePage("设置")

local s3, b3 = Section(setPage, "功能开关")
s3.Size = UDim2.new(1, 0, 0, 100)

Toggle(b3, "自动瞄准", function(v)
	Toast("设置", "自动瞄准: " .. (v and "开启" or "关闭"), 2, v and C.Green or C.Gray)
end)

Toggle(b3, "ESP 透视", function(v)
	Toast("设置", "ESP透视: " .. (v and "开启" or "关闭"), 2, v and C.Green or C.Gray)
end)

local s4, b4 = Section(setPage, "参数调节")
s4.Size = UDim2.new(1, 0, 0, 75)

Slider(b4, "移动速度", function(v) end, {Min = 1, Max = 100, Default = 50})

local s5, b5 = Section(setPage, "高级选项")
s5.Size = UDim2.new(1, 0, 0, 75)

Dropdown(b5, "选择武器", {"手枪", "步枪", "狙击枪", "霰弹枪", "冲锋枪"}, function(v)
	Toast("武器", "已选择: " .. v, 2)
end)

-- ---- 关于页 ----
local aboutPage = makePage("关于")

local s6, b6 = Section(aboutPage, "关于 LuminaUI")
s6.Size = UDim2.new(1, 0, 0, 100)

New("TextLabel", {
	Size = UDim2.new(1, 0, 0, 80),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "LuminaUI v2.0\n\n玻璃拟态 · 渐变光效 · 流畅动画\n为 Roblox 注入器打造的现代化 UI 库\n\n组件: 按钮 · 开关 · 滑块 · 下拉菜单",
	TextColor3 = C.Gray,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
}, b6)

-- ==================== 导航按钮 ====================
local nav1 = makeNavBtn("主页", "🏠", 1)
local nav2 = makeNavBtn("设置", "⚙", 2)
local nav3 = makeNavBtn("关于", "ℹ", 3)

nav1.MouseButton1Click:Connect(function() switchPage("主页") end)
nav2.MouseButton1Click:Connect(function() switchPage("设置") end)
nav3.MouseButton1Click:Connect(function() switchPage("关于") end)

for _, b in ipairs({nav1, nav2, nav3}) do
	b.MouseEnter:Connect(function()
		if curPage ~= b.Name then Tween(b, {BackgroundColor3 = C.Card}, 0.15) end
	end)
	b.MouseLeave:Connect(function()
		if curPage ~= b.Name then Tween(b, {BackgroundColor3 = C.Bg}, 0.15) end
	end)
end

curPage = "主页"

-- ==================== 入场动画 ====================
main.Size = UDim2.new(0, 0, 0, 0)
main.BackgroundTransparency = 0.6
Tween(main, {
	Size = UDim2.new(0, 520, 0, 440),
	BackgroundTransparency = 0.04,
}, 0.5, Enum.EasingStyle.Back)

-- 欢迎通知
delay(0.6, function()
	pcall(function()
		Toast("欢迎", "LuminaUI v2.0 已启动", 4, C.Accent)
	end)
end)

print("========================================")
print(" LuminaUI v2.0 加载完成！")
print(" 玻璃拟态 · 渐变光效 · 流畅动画")
print(" DisplayOrder: 99999")
print("========================================")