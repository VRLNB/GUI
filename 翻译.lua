--[[
	LuminaUI - Roblox 极致 UI 交互系统 (注入器通用版)
	
	特性:
	- 窗口系统（拖拽、弹出/关闭动画、进出场特效）
	- 按钮（悬停/按下动画、音效反馈）
	- 开关/Toggle（滑动动画、颜色过渡）
	- 滑块（拖动、填充动画、数值显示）
	- 下拉菜单（折叠/展开动画）
	- 按键绑定（键盘输入捕获）
	- 分类折叠面板
	- 移动端触摸拖动支持
	- 通知弹窗（入场/出场动画）
	- 音效系统（Roblox 内置音频）
	- 统一动画引擎
	- 生命周期管理（绑定/解绑/清理）
	
	所有 UI 使用纯代码生成，无需任何预制资源
]]

print("========================================")
print(" LuminaUI 交互系统 加载中...")
print("========================================")

-- ==================== 安全全局变量访问 ====================
local function safeGet(name)
	local ok, val = pcall(function() return _G[name] end)
	if ok and val ~= nil then return val end
	return nil
end

-- ==================== 环境检测 ====================
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local httpService = nil
pcall(function() httpService = game:GetService("HttpService") end)

-- 检测注入器
local syn = safeGet("syn")
local request = safeGet("request")
local http_request = safeGet("http_request")
local gethui = safeGet("gethui")
local envName = "Unknown"

if syn and type(syn) == "table" and syn.request then envName = "Synapse X"
elseif request and type(request) == "function" then envName = "ScriptWare/Delta/Fluxus"
elseif http_request and type(http_request) == "function" then envName = "Krnl/Electron"
elseif safeGet("http") and type(safeGet("http")) == "table" and safeGet("http").request then envName = "Generic HTTP"
end

-- ==================== 音效系统 ====================
local SoundManager = {}
local soundCache = {}

-- Roblox 内置音效 ID 列表
SoundManager.Sounds = {
	Click = "rbxassetid://9116332393",          -- 点击
	Hover = "rbxassetid://9116332520",          -- 悬停
	ToggleOn = "rbxassetid://9116332656",       -- 开关开启
	ToggleOff = "rbxassetid://9116332780",      -- 开关关闭
	Open = "rbxassetid://9116332884",           -- 面板打开
	Close = "rbxassetid://9116332987",          -- 面板关闭
	Popup = "rbxassetid://9116333089",          -- 弹出通知
	Slider = "rbxassetid://9116333180",         -- 滑块拖动
	Dropdown = "rbxassetid://9116333285",       -- 下拉展开
	Success = "rbxassetid://9116333390",        -- 成功
	Error = "rbxassetid://9116333500",          -- 错误
	Keybind = "rbxassetid://9116333605",        -- 按键绑定
}

local soundEnabled = true

function SoundManager:Play(soundName, volume, parent)
	if not soundEnabled then return end
	local soundId = self.Sounds[soundName]
	if not soundId then return end

	volume = volume or 0.5
	parent = parent or game.SoundService

	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = volume
		sound.Parent = parent
		sound:Play()

		-- 自动清理
		game.Debris:AddItem(sound, sound.TimeLength + 0.1)
	end)
end

function SoundManager:SetEnabled(enabled)
	soundEnabled = enabled
end

-- ==================== 动画引擎 ====================
local Animator = {}

-- Tween 动画
function Animator:Tween(obj, properties, duration, easingStyle, easingDirection, callback)
	duration = duration or 0.3
	easingStyle = easingStyle or Enum.EasingStyle.Quart
	easingDirection = easingDirection or Enum.EasingDirection.Out

	local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection, 0, false, 0)
	local tween = tweenService:Create(obj, tweenInfo, properties)
	tween:Play()

	if callback then
		tween.Completed:Connect(function()
			callback()
		end)
	end

	return tween
end

-- 弹簧动画（模拟）
function Animator:Spring(obj, properties, duration, callback)
	duration = duration or 0.4
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0)
	local tween = tweenService:Create(obj, tweenInfo, properties)
	tween:Play()

	if callback then
		tween.Completed:Connect(callback)
	end
	return tween
end

-- 弹出入场动画
function Animator:PopIn(frame, duration, callback)
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1

	local targetSize = UDim2.new(0, 400, 0, 300) -- 由调用者覆盖

	-- 先做尺寸弹簧
	local tweenInfo = TweenInfo.new(duration or 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
	frame.Size = UDim2.new(0, 0, 0, 0)
	local tween = tweenService:Create(frame, tweenInfo, {
		Size = targetSize,
		BackgroundTransparency = frame.BackgroundTransparency
	})
	tween:Play()
	if callback then tween.Completed:Connect(callback) end
	return tween
end

-- 关闭收缩动画
function Animator:PopOut(frame, duration, callback)
	duration = duration or 0.2
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0)
	local tween = tweenService:Create(frame, tweenInfo, {
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		if frame then frame.Visible = false end
		if callback then callback() end
	end)
	return tween
end

-- 淡入
function Animator:FadeIn(obj, duration, callback)
	obj.BackgroundTransparency = 1
	obj.TextTransparency = 1
	local tweenInfo = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
	local props = {BackgroundTransparency = 0, TextTransparency = 0}
	pcall(function() props.ImageTransparency = 0 end)
	local tween = tweenService:Create(obj, tweenInfo, props)
	tween:Play()
	if callback then tween.Completed:Connect(callback) end
	return tween
end

-- 淡出
function Animator:FadeOut(obj, duration, callback)
	local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0)
	local props = {BackgroundTransparency = 1, TextTransparency = 1}
	pcall(function() props.ImageTransparency = 1 end)
	local tween = tweenService:Create(obj, tweenInfo, props)
	tween:Play()
	tween.Completed:Connect(function()
		obj.Visible = false
		if callback then callback() end
	end)
	return tween
end

-- 滑动入场（从右侧滑入）
function Animator:SlideIn(frame, direction, duration, callback)
	direction = direction or "Right"
	duration = duration or 0.35
	local startPos
	if direction == "Right" then startPos = UDim2.new(1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
	elseif direction == "Left" then startPos = UDim2.new(-1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
	elseif direction == "Top" then startPos = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, -1, 0)
	elseif direction == "Bottom" then startPos = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, 1, 0)
	end
	local targetPos = frame.Position
	frame.Position = startPos
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, 0)
	local tween = tweenService:Create(frame, tweenInfo, {Position = targetPos})
	tween:Play()
	if callback then tween.Completed:Connect(callback) end
	return tween
end

-- ==================== 主题系统 ====================
local Theme = {}

Theme.Default = {
	Background = Color3.fromRGB(18, 18, 24),
	Surface = Color3.fromRGB(26, 26, 34),
	Surface2 = Color3.fromRGB(34, 34, 44),
	Surface3 = Color3.fromRGB(42, 42, 54),
	Accent = Color3.fromRGB(80, 140, 255),
	Accent2 = Color3.fromRGB(255, 100, 130),
	Success = Color3.fromRGB(50, 220, 120),
	Warning = Color3.fromRGB(255, 180, 60),
	Danger = Color3.fromRGB(255, 70, 70),
	Text = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(160, 160, 170),
	TextMuted = Color3.fromRGB(100, 100, 110),
	Border = Color3.fromRGB(50, 50, 60),
	BorderAccent = Color3.fromRGB(80, 140, 255),
	ScrollBar = Color3.fromRGB(60, 60, 70),
	ScrollBarBg = Color3.fromRGB(30, 30, 38),
	Shadow = Color3.fromRGB(0, 0, 0),
}

Theme.Dark = {
	Background = Color3.fromRGB(12, 12, 16),
	Surface = Color3.fromRGB(18, 18, 26),
	Surface2 = Color3.fromRGB(26, 26, 36),
	Surface3 = Color3.fromRGB(34, 34, 46),
	Accent = Color3.fromRGB(100, 100, 255),
	Accent2 = Color3.fromRGB(255, 80, 120),
	Success = Color3.fromRGB(40, 200, 100),
	Warning = Color3.fromRGB(240, 160, 40),
	Danger = Color3.fromRGB(240, 60, 60),
	Text = Color3.fromRGB(240, 240, 250),
	TextSecondary = Color3.fromRGB(150, 150, 160),
	TextMuted = Color3.fromRGB(90, 90, 100),
	Border = Color3.fromRGB(40, 40, 50),
	BorderAccent = Color3.fromRGB(100, 100, 255),
	ScrollBar = Color3.fromRGB(50, 50, 60),
	ScrollBarBg = Color3.fromRGB(22, 22, 30),
	Shadow = Color3.fromRGB(0, 0, 0),
}

Theme.Light = {
	Background = Color3.fromRGB(240, 240, 245),
	Surface = Color3.fromRGB(255, 255, 255),
	Surface2 = Color3.fromRGB(245, 245, 250),
	Surface3 = Color3.fromRGB(235, 235, 240),
	Accent = Color3.fromRGB(60, 120, 240),
	Accent2 = Color3.fromRGB(240, 80, 100),
	Success = Color3.fromRGB(40, 180, 100),
	Warning = Color3.fromRGB(240, 160, 40),
	Danger = Color3.fromRGB(230, 60, 60),
	Text = Color3.fromRGB(20, 20, 30),
	TextSecondary = Color3.fromRGB(100, 100, 110),
	TextMuted = Color3.fromRGB(150, 150, 160),
	Border = Color3.fromRGB(210, 210, 220),
	BorderAccent = Color3.fromRGB(60, 120, 240),
	ScrollBar = Color3.fromRGB(180, 180, 190),
	ScrollBarBg = Color3.fromRGB(225, 225, 230),
	Shadow = Color3.fromRGB(0, 0, 0),
}

local currentTheme = Theme.Default
local function getTheme() return currentTheme end

-- ==================== 工具函数 ====================
local function createInstance(className, properties)
	local obj = Instance.new(className)
	for k, v in pairs(properties or {}) do
		pcall(function() obj[k] = v end)
	end
	return obj
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or getTheme().Border
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function addGradient(parent, color1, color2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1 or getTheme().Accent),
		ColorSequenceKeypoint.new(1, color2 or getTheme().Accent2),
	})
	g.Rotation = rotation or 135
	g.Parent = parent
	return g
end

local function addShadow(parent, transparency, offset)
	local s = createInstance("ImageLabel", {
		Name = "Shadow",
		Image = "rbxassetid://1316045217",
		ImageColor3 = getTheme().Shadow,
		ImageTransparency = transparency or 0.7,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, offset or 3, 0.5, offset or 3),
		Size = UDim2.new(1, 20, 1, 20),
		BackgroundTransparency = 1,
		ZIndex = -1,
		Parent = parent,
	})
	return s
end

-- ==================== 组件: 窗口 (Window) ====================
local Window = {}
Window.__index = Window

function Window.new(config)
	config = config or {}
	local t = getTheme()

	local screenGui = createInstance("ScreenGui", {
		Name = config.Name or "LuminaUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = config.DisplayOrder or 100,
	})

	-- 检查是否已存在
	local existing = playerGui:FindFirstChild(screenGui.Name)
	if existing then existing:Destroy() wait(0.2) end

	screenGui.Parent = playerGui

	-- 主窗口容器
	local mainFrame = createInstance("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(0, config.Width or 520, 0, config.Height or 440),
		Position = UDim2.new(0.5, -(config.Width or 520) / 2, 0.5, -(config.Height or 440) / 2),
		BackgroundColor3 = t.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		Parent = screenGui,
	})
	addCorner(mainFrame, 10)
	addShadow(mainFrame, 0.7, 4)
	addStroke(mainFrame, t.Border, 1.5)

	-- 标题栏
	local titleBar = createInstance("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = t.Surface,
		BorderSizePixel = 0,
		Parent = mainFrame,
	})
	addCorner(titleBar, 10)

	-- 标题栏底部填充
	createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = t.Surface,
		BorderSizePixel = 0,
		Parent = titleBar,
	})

	local titleLabel = createInstance("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = config.Title or "LuminaUI",
		TextColor3 = t.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleBar,
	})

	-- 关闭按钮
	local closeBtn = createInstance("TextButton", {
		Name = "CloseBtn",
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -36, 0, 6),
		BackgroundColor3 = Color3.fromRGB(255, 70, 70),
		Text = "✕",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		Parent = titleBar,
	})
	addCorner(closeBtn, 6)

	-- 最小化按钮
	local minBtn = createInstance("TextButton", {
		Name = "MinBtn",
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -68, 0, 6),
		BackgroundColor3 = Color3.fromRGB(255, 180, 60),
		Text = "─",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		Parent = titleBar,
	})
	addCorner(minBtn, 6)

	-- 内容区（带滚动）
	local contentFrame = createInstance("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -40),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundColor3 = t.Surface,
		BorderSizePixel = 0,
		Parent = mainFrame,
	})

	-- 左侧导航
	local navWidth = config.NavWidth or 150
	local navFrame = createInstance("Frame", {
		Name = "Navigation",
		Size = UDim2.new(0, navWidth, 1, 0),
		BackgroundColor3 = t.Surface2,
		BorderSizePixel = 0,
		Parent = contentFrame,
	})
	addCorner(navFrame, 10)

	-- 导航按钮容器
	local navList = createInstance("ScrollingFrame", {
		Name = "NavList",
		Size = UDim2.new(1, 0, 1, -60),
		Position = UDim2.new(0, 0, 0, 10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = navFrame,
	})

	local navLayout = createInstance("UIListLayout", {
		Padding = UDim.new(0, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = navList,
	})

	local navPadding = createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		Parent = navList,
	})

	-- 右侧内容区
	local rightFrame = createInstance("Frame", {
		Name = "RightContent",
		Size = UDim2.new(1, -(navWidth + 10), 1, 0),
		Position = UDim2.new(0, navWidth + 10, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = contentFrame,
	})

	-- 右侧滚动区
	local pageScroll = createInstance("ScrollingFrame", {
		Name = "PageScroll",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = t.ScrollBar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = rightFrame,
	})

	local pageLayout = createInstance("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = pageScroll,
	})

	local pagePadding = createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 10),
		Parent = pageScroll,
	})

	-- 页面容器
	local pages = {}
	local navButtons = {}
	local currentPage = nil

	-- 窗口拖拽
	local dragging = false
	local dragStart = nil
	local winStart = nil

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			winStart = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	titleBar.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
		   input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				winStart.X.Scale, winStart.X.Offset + delta.X,
				winStart.Y.Scale, winStart.Y.Offset + delta.Y
			)
		end
	end)

	-- 移动端触摸拖动
	mainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			-- 通过标题栏区域判断
		end
	end)

	-- 关闭按钮
	local minimized = false
	local originalSize = mainFrame.Size

	closeBtn.MouseButton1Click:Connect(function()
		SoundManager:Play("Close")
		Animator:PopOut(mainFrame, 0.25, function()
			screenGui:Destroy()
		end)
	end)

	minBtn.MouseButton1Click:Connect(function()
		if not minimized then
			SoundManager:Play("ToggleOff")
			originalSize = mainFrame.Size
			local tween = Animator:Tween(mainFrame, {
				Size = UDim2.new(0, originalSize.X.Offset, 0, 40)
			}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			tween.Completed:Connect(function()
				minimized = true
			end)
		else
			SoundManager:Play("ToggleOn")
			Animator:Spring(mainFrame, {
				Size = originalSize
			}, 0.5)
			minimized = false
		end
	end)

	-- 构建 self
	local self = setmetatable({
		ScreenGui = screenGui,
		MainFrame = mainFrame,
		TitleBar = titleBar,
		TitleLabel = titleLabel,
		ContentFrame = contentFrame,
		NavFrame = navFrame,
		NavList = navList,
		NavLayout = navLayout,
		RightFrame = rightFrame,
		PageScroll = pageScroll,
		PageLayout = pageLayout,
		Pages = pages,
		NavButtons = navButtons,
		CurrentPage = nil,
		Minimized = false,
		_isOpen = true,
		_components = {},
		_bindings = {},
	}, Window)

	-- 入场动画
	Animator:PopIn(mainFrame, 0.45)
	SoundManager:Play("Open")

	return self
end

function Window:AddPage(name, icon)
	local t = getTheme()
	local page = createInstance("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = (#self.Pages == 0),
		Parent = self.PageScroll,
	})

	local pageLayout = createInstance("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})

	table.insert(self.Pages, page)

	-- 导航按钮
	local btn = createInstance("TextButton", {
		Name = "Nav_" .. name,
		Size = UDim2.new(1, -12, 0, 34),
		BackgroundColor3 = (#self.NavButtons == 0) and t.Surface3 or t.Surface2,
		Text = (icon or "") .. "  " .. name,
		TextColor3 = (#self.NavButtons == 0) and t.Text or t.TextSecondary,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		LayoutOrder = #self.NavButtons + 1,
		Parent = self.NavList,
	})
	addCorner(btn, 6)

	local btnPadding = createInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		Parent = btn,
	})

	btn.MouseButton1Click:Connect(function()
		SoundManager:Play("Click")
		self:SwitchPage(name)
	end)

	btn.MouseEnter:Connect(function()
		SoundManager:Play("Hover", 0.3)
		if self.CurrentPage and self.Pages[self.CurrentPage] and self.Pages[self.CurrentPage].Name ~= name then
			Animator:Tween(btn, {BackgroundColor3 = t.Surface3}, 0.15)
		end
	end)

	btn.MouseLeave:Connect(function()
		if self.CurrentPage and self.Pages[self.CurrentPage] and self.Pages[self.CurrentPage].Name ~= name then
			Animator:Tween(btn, {BackgroundColor3 = t.Surface2}, 0.15)
		end
	end)

	table.insert(self.NavButtons, btn)

	-- 首次自动选中
	if #self.Pages == 1 then
		self.CurrentPage = name
		btn.BackgroundColor3 = t.Surface3
		btn.TextColor3 = t.Text
		-- 添加左侧指示条
		local indicator = createInstance("Frame", {
			Name = "ActiveIndicator",
			Size = UDim2.new(0, 3, 0, 20),
			Position = UDim2.new(0, 0, 0.5, -10),
			BackgroundColor3 = t.Accent,
			BorderSizePixel = 0,
			Parent = btn,
		})
		addCorner(indicator, 2)
	end

	-- 更新滚动大小
	self.NavList.CanvasSize = UDim2.new(0, 0, 0, self.NavLayout.AbsoluteContentSize.Y + 10)

	return page
end

function Window:SwitchPage(name)
	local t = getTheme()
	SoundManager:Play("Click")

	for i, page in ipairs(self.Pages) do
		if page.Name == name then
			page.Visible = true
			self.CurrentPage = name
			Animator:FadeIn(page, 0.2)
		else
			page.Visible = false
		end
	end

	for _, btn in ipairs(self.NavButtons) do
		local pageName = btn.Name:gsub("Nav_", "")
		if pageName == name then
			Animator:Tween(btn, {BackgroundColor3 = t.Surface3, TextColor3 = t.Text}, 0.2)
			-- 添加/更新指示条
			local indicator = btn:FindFirstChild("ActiveIndicator")
			if not indicator then
				indicator = createInstance("Frame", {
					Name = "ActiveIndicator",
					Size = UDim2.new(0, 3, 0, 20),
					Position = UDim2.new(0, 0, 0.5, -10),
					BackgroundColor3 = t.Accent,
					BorderSizePixel = 0,
					Parent = btn,
				})
				addCorner(indicator, 2)
			end
		else
			Animator:Tween(btn, {BackgroundColor3 = t.Surface2, TextColor3 = t.TextSecondary}, 0.2)
			local indicator = btn:FindFirstChild("ActiveIndicator")
			if indicator then indicator:Destroy() end
		end
	end
end

function Window:Destroy()
	SoundManager:Play("Close")
	Animator:PopOut(self.MainFrame, 0.25, function()
		-- 清理所有绑定
		for _, binding in ipairs(self._bindings) do
			pcall(function() binding:Disconnect() end)
		end
		self.ScreenGui:Destroy()
	end)
end

-- ==================== 组件: 分区 (Section) ====================
local Section = {}
Section.__index = Section

function Section.new(parent, title, config)
	config = config or {}
	local t = getTheme()

	local frame = createInstance("Frame", {
		Name = "Section_" .. (title or "Untitled"),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = t.Surface,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	addCorner(frame, 8)
	addStroke(frame, t.Border, 1)

	-- 标题
	if title then
		local titleFrame = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = t.Surface2,
			BorderSizePixel = 0,
			Parent = frame,
		})
		addCorner(titleFrame, 8)
		-- 底部填充
		createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 8),
			Position = UDim2.new(0, 0, 1, -8),
			BackgroundColor3 = t.Surface2,
			BorderSizePixel = 0,
			Parent = titleFrame,
		})

		createInstance("TextLabel", {
			Size = UDim2.new(1, -20, 1, 0),
			Position = UDim2.new(0, 14, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = title,
			TextColor3 = t.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = titleFrame,
		})
	end

	-- 内容区
	local content = createInstance("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		Position = title and UDim2.new(0, 0, 0, 36) or UDim2.new(0, 0, 0, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	})

	local layout = createInstance("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})

	local padding = createInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 8),
		Parent = content,
	})

	return setmetatable({
		Frame = frame,
		Content = content,
		Layout = layout,
	}, Section)
end

-- ==================== 组件: 按钮 (Button) ====================
local Button = {}
Button.__index = Button

function Button.new(parent, text, callback, config)
	config = config or {}
	local t = getTheme()

	local btn = createInstance("TextButton", {
		Name = "Btn_" .. (text or "Button"),
		Size = UDim2.new(1, 0, 0, config.Height or 34),
		BackgroundColor3 = config.Color or t.Accent,
		Text = text or "Button",
		TextColor3 = config.TextColor or Color3.fromRGB(255, 255, 255),
		TextSize = config.TextSize or 13,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = parent,
	})
	addCorner(btn, config.CornerRadius or 6)

	if config.Gradient then
		addGradient(btn, t.Accent, t.Accent2, 90)
	end

	local originalColor = btn.BackgroundColor3
	local hoverColor = config.HoverColor or Color3.new(
		originalColor.R + 0.1, originalColor.G + 0.1, originalColor.B + 0.1
	)
	local pressColor = config.PressColor or Color3.new(
		originalColor.R - 0.05, originalColor.G - 0.05, originalColor.B - 0.05
	)

	btn.MouseEnter:Connect(function()
		SoundManager:Play("Hover", 0.3)
		Animator:Tween(btn, {BackgroundColor3 = hoverColor}, 0.15)
		Animator:Tween(btn, {Size = UDim2.new(1, 0, 0, (config.Height or 34) + 2)}, 0.1)
	end)

	btn.MouseLeave:Connect(function()
		Animator:Tween(btn, {BackgroundColor3 = originalColor}, 0.15)
		Animator:Tween(btn, {Size = UDim2.new(1, 0, 0, config.Height or 34)}, 0.1)
	end)

	btn.MouseButton1Down:Connect(function()
		Animator:Tween(btn, {BackgroundColor3 = pressColor, Size = UDim2.new(1, -4, 0, (config.Height or 34) - 2)}, 0.08)
	end)

	btn.MouseButton1Up:Connect(function()
		Animator:Tween(btn, {BackgroundColor3 = hoverColor, Size = UDim2.new(1, 0, 0, config.Height or 34)}, 0.1)
	end)

	btn.MouseButton1Click:Connect(function()
		SoundManager:Play("Click")
		-- 点击涟漪效果
		pcall(function()
			local ripple = createInstance("Frame", {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.6,
				BorderSizePixel = 0,
				ZIndex = 5,
				Parent = btn,
			})
			addCorner(ripple, 50)
			Animator:Tween(ripple, {
				Size = UDim2.new(0, btn.AbsoluteSize.X * 2, 0, btn.AbsoluteSize.X * 2),
				BackgroundTransparency = 1,
			}, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
				ripple:Destroy()
			end)
		end)

		if callback then callback() end
	end)

	return btn
end

-- ==================== 组件: 开关 (Toggle) ====================
local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, text, callback, config)
	config = config or {}
	local t = getTheme()

	local container = createInstance("Frame", {
		Name = "Toggle_" .. (text or "Toggle"),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = parent,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = text or "Toggle",
		TextColor3 = t.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	local toggleBg = createInstance("Frame", {
		Name = "ToggleBg",
		Size = UDim2.new(0, 48, 0, 26),
		Position = UDim2.new(1, -52, 0.5, -13),
		BackgroundColor3 = t.Surface3,
		BorderSizePixel = 0,
		Parent = container,
	})
	addCorner(toggleBg, 13)

	local toggleKnob = createInstance("Frame", {
		Name = "Knob",
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0, 3, 0, 3),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = toggleBg,
	})
	addCorner(toggleKnob, 10)

	local toggleBtn = createInstance("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 10,
		Parent = container,
	})

	local enabled = config.Default or false

	local function updateVisual()
		if enabled then
			Animator:Tween(toggleBg, {BackgroundColor3 = t.Success}, 0.25)
			Animator:Tween(toggleKnob, {Position = UDim2.new(1, -23, 0, 3)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		else
			Animator:Tween(toggleBg, {BackgroundColor3 = t.Surface3}, 0.25)
			Animator:Tween(toggleKnob, {Position = UDim2.new(0, 3, 0, 3)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		end
	end

	updateVisual()

	toggleBtn.MouseButton1Click:Connect(function()
		enabled = not enabled
		SoundManager:Play(enabled and "ToggleOn" or "ToggleOff")
		updateVisual()
		if callback then callback(enabled) end
	end)

	return setmetatable({
		Container = container,
		ToggleBg = toggleBg,
		ToggleKnob = toggleKnob,
		Label = label,
		GetValue = function() return enabled end,
		SetValue = function(val)
			enabled = val
			updateVisual()
		end,
	}, Toggle)
end

-- ==================== 组件: 滑块 (Slider) ====================
local Slider = {}
Slider.__index = Slider

function Slider.new(parent, text, callback, config)
	config = config or {}
	local t = getTheme()
	local min = config.Min or 0
	local max = config.Max or 100
	local default = config.Default or 50
	local step = config.Step or 1

	local container = createInstance("Frame", {
		Name = "Slider_" .. (text or "Slider"),
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = parent,
	})

	-- 标签行
	local labelFrame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = container,
	})

	createInstance("TextLabel", {
		Size = UDim2.new(0.7, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = text or "Slider",
		TextColor3 = t.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = labelFrame,
	})

	local valueLabel = createInstance("TextLabel", {
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(0.7, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(default),
		TextColor3 = t.Accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = labelFrame,
	})

	-- 滑块轨道
	local trackFrame = createInstance("Frame", {
		Name = "Track",
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 0, 28),
		BackgroundColor3 = t.Surface3,
		BorderSizePixel = 0,
		Parent = container,
	})
	addCorner(trackFrame, 3)

	-- 填充
	local fill = createInstance("Frame", {
		Name = "Fill",
		Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = t.Accent,
		BorderSizePixel = 0,
		Parent = trackFrame,
	})
	addCorner(fill, 3)

	-- 拖拽手柄
	local knob = createInstance("Frame", {
		Name = "Knob",
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new((default - min) / (max - min), -9, 0.5, -9),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = trackFrame,
	})
	addCorner(knob, 9)
	addStroke(knob, t.Accent, 2)

	local currentValue = default

	-- 拖拽逻辑
	local knobDragging = false

	local function setValueFromX(x)
		local trackAbs = trackFrame.AbsolutePosition.X
		local trackWidth = trackFrame.AbsoluteSize.X
		local ratio = math.clamp((x - trackAbs) / trackWidth, 0, 1)
		local rawValue = min + ratio * (max - min)
		local steppedValue = math.floor(rawValue / step + 0.5) * step
		steppedValue = math.clamp(steppedValue, min, max)
		currentValue = steppedValue
		ratio = (steppedValue - min) / (max - min)

		fill.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, -9, 0.5, -9)
		valueLabel.Text = tostring(steppedValue)

		if callback then callback(steppedValue) end
	end

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			knobDragging = true
			SoundManager:Play("Slider", 0.3)
		end
	end)

	knob.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			knobDragging = false
		end
	end)

	trackFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			setValueFromX(input.Position.X)
			knobDragging = true
			SoundManager:Play("Slider", 0.3)
		end
	end)

	trackFrame.InputEnded:Connect(function(input)
		knobDragging = false
	end)

	uis.InputChanged:Connect(function(input)
		if knobDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
		   input.UserInputType == Enum.UserInputType.Touch) then
			setValueFromX(mouse.X)
		end
	end)

	-- 移动端触摸
	container.TouchMoved:Connect(function(input)
		-- pass, handled by uis
	end)

	return setmetatable({
		Container = container,
		Track = trackFrame,
		Fill = fill,
		Knob = knob,
		ValueLabel = valueLabel,
		GetValue = function() return currentValue end,
		SetValue = function(val)
			currentValue = math.clamp(val, min, max)
			local ratio = (currentValue - min) / (max - min)
			fill.Size = UDim2.new(ratio, 0, 1, 0)
			knob.Position = UDim2.new(ratio, -9, 0.5, -9)
			valueLabel.Text = tostring(currentValue)
		end,
	}, Slider)
end

-- ==================== 组件: 下拉菜单 (Dropdown) ====================
local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(parent, text, options, callback, config)
	config = config or {}
	local t = getTheme()

	local container = createInstance("Frame", {
		Name = "Dropdown_" .. (text or "Dropdown"),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = text or "Dropdown",
		TextColor3 = t.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	local header = createInstance("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 24),
		BackgroundColor3 = t.Surface3,
		Text = config.Default or options[1] or "Select...",
		TextColor3 = t.Text,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = container,
	})
	addCorner(header, 6)

	-- 箭头
	local arrow = createInstance("TextLabel", {
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -24, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "▼",
		TextColor3 = t.TextSecondary,
		TextSize = 10,
		Parent = header,
	})

	local headerPadding = createInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		Parent = header,
	})

	-- 选项列表
	local optionList = createInstance("Frame", {
		Name = "OptionList",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 60),
		BackgroundColor3 = t.Surface2,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Parent = container,
	})
	addCorner(optionList, 6)
	addStroke(optionList, t.Border, 1)

	local optionLayout = createInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = optionList,
	})

	local expanded = false
	local selectedOption = config.Default or options[1]
	local optionButtons = {}

	for i, opt in ipairs(options) do
		local optBtn = createInstance("TextButton", {
			Name = opt,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = (opt == selectedOption) and t.Surface3 or t.Surface2,
			Text = opt,
			TextColor3 = t.Text,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Parent = optionList,
		})
		local optPadding = createInstance("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			Parent = optBtn,
		})

		optBtn.MouseEnter:Connect(function()
			Animator:Tween(optBtn, {BackgroundColor3 = t.Surface3}, 0.1)
		end)
		optBtn.MouseLeave:Connect(function()
			if opt ~= selectedOption then
				Animator:Tween(optBtn, {BackgroundColor3 = t.Surface2}, 0.1)
			end
		end)
		optBtn.MouseButton1Click:Connect(function()
			selectedOption = opt
			header.Text = opt
			SoundManager:Play("Click")
			if callback then callback(opt) end
			-- 关闭下拉
			expanded = false
			Animator:Tween(optionList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function()
				optionList.Visible = false
			end)
			Animator:Tween(arrow, {Rotation = 0}, 0.2)
			-- 更新高亮
			for _, b in ipairs(optionButtons) do
				Animator:Tween(b, {BackgroundColor3 = (b.Name == opt) and t.Surface3 or t.Surface2}, 0.2)
			end
		end)
		table.insert(optionButtons, optBtn)
	end

	optionList.Size = UDim2.new(1, 0, 0, 28 * #options)

	header.MouseButton1Click:Connect(function()
		SoundManager:Play("Dropdown")
		expanded = not expanded
		if expanded then
			optionList.Visible = true
			optionList.Size = UDim2.new(1, 0, 0, 0)
			Animator:Tween(optionList, {Size = UDim2.new(1, 0, 0, 28 * #options)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			Animator:Tween(arrow, {Rotation = 180}, 0.25)
		else
			Animator:Tween(optionList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function()
				optionList.Visible = false
			end)
			Animator:Tween(arrow, {Rotation = 0}, 0.2)
		end
	end)

	return setmetatable({
		Container = container,
		Header = header,
		OptionList = optionList,
		GetValue = function() return selectedOption end,
		SetValue = function(val) selectedOption = val; header.Text = val end,
	}, Dropdown)
end

-- ==================== 组件: 按键绑定 (Keybind) ====================
local Keybind = {}
Keybind.__index = Keybind

function Keybind.new(parent, text, callback, config)
	config = config or {}
	local t = getTheme()

	local container = createInstance("Frame", {
		Name = "Keybind_" .. (text or "Keybind"),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = parent,
	})

	createInstance("TextLabel", {
		Size = UDim2.new(0.6, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = text or "Keybind",
		TextColor3 = t.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	local keyBtn = createInstance("TextButton", {
		Name = "KeyBtn",
		Size = UDim2.new(0, 80, 0, 26),
		Position = UDim2.new(1, -84, 0.5, -13),
		BackgroundColor3 = t.Surface3,
		Text = config.Default or "None",
		TextColor3 = t.TextSecondary,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = container,
	})
	addCorner(keyBtn, 6)

	local currentKey = config.Default or "None"
	local listening = false

	keyBtn.MouseButton1Click:Connect(function()
		listening = true
		keyBtn.Text = "..."
		keyBtn.TextColor3 = t.Accent
		SoundManager:Play("Keybind", 0.4)
	end)

	uis.InputBegan:Connect(function(input, processed)
		if listening and not processed then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				currentKey = input.KeyCode.Name
				keyBtn.Text = currentKey
				keyBtn.TextColor3 = t.Text
				listening = false
				if callback then callback(currentKey) end
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				local mbName = input.UserInputType.Name
				currentKey = mbName
				keyBtn.Text = mbName
				keyBtn.TextColor3 = t.Text
				listening = false
				if callback then callback(currentKey) end
			end
		end
	end)

	return setmetatable({
		Container = container,
		KeyBtn = keyBtn,
		GetValue = function() return currentKey end,
		SetValue = function(val)
			currentKey = val
			keyBtn.Text = val
			keyBtn.TextColor3 = t.Text
		end,
	}, Keybind)
end

-- ==================== 组件: 通知 (Notification) ====================
local Notification = {}
Notification.__index = Notification

function Notification.new(config)
	config = config or {}
	local t = getTheme()
	local title = config.Title or "Notification"
	local message = config.Message or ""
	local duration = config.Duration or 3
	local notifType = config.Type or "Info" -- Info, Success, Error, Warning

	local typeColors = {
		Info = t.Accent,
		Success = t.Success,
		Error = t.Danger,
		Warning = t.Warning,
	}

	local notifFrame = createInstance("Frame", {
		Name = "Notification",
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(1, 0, 0, 20),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = t.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 999,
		Parent = playerGui,
	})
	addCorner(notifFrame, 8)
	addShadow(notifFrame, 0.6, 3)

	-- 左侧色条
	createInstance("Frame", {
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = typeColors[notifType] or t.Accent,
		BorderSizePixel = 0,
		Parent = notifFrame,
	})

	-- 标题
	createInstance("TextLabel", {
		Size = UDim2.new(1, -50, 0, 18),
		Position = UDim2.new(0, 14, 0, 8),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = t.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = notifFrame,
	})

	-- 内容
	createInstance("TextLabel", {
		Size = UDim2.new(1, -50, 0, 16),
		Position = UDim2.new(0, 14, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = message,
		TextColor3 = t.TextSecondary,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = notifFrame,
	})

	-- 关闭按钮
	local closeBtn = createInstance("TextButton", {
		Size = UDim2.new(0, 22, 0, 22),
		Position = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9,
		Text = "✕",
		TextColor3 = t.TextSecondary,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		Parent = notifFrame,
	})

	-- 进度条
	local progressBar = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = typeColors[notifType] or t.Accent,
		BorderSizePixel = 0,
		Parent = notifFrame,
	})

	SoundManager:Play("Popup")

	-- 入场动画
	notifFrame.Size = UDim2.new(0, 280, 0, 56)
	local slideIn = Animator:SlideIn(notifFrame, "Right", 0.35)

	-- 进度条动画
	Animator:Tween(progressBar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	-- 自动关闭
	local closeTween = nil
	local function close()
		closeTween = Animator:SlideIn(notifFrame, "Right", 0.25)
		closeTween.Completed:Connect(function()
			notifFrame:Destroy()
		end)
	end

	closeBtn.MouseButton1Click:Connect(close)
	task.delay(duration, close)

	return notifFrame
end

-- ==================== 组件: 颜色选择器 (ColorPicker) ====================
local ColorPicker = {}
ColorPicker.__index = ColorPicker

function ColorPicker.new(parent, text, callback, config)
	config = config or {}
	local t = getTheme()
	local defaultColor = config.Default or Color3.fromRGB(255, 255, 255)

	local container = createInstance("Frame", {
		Name = "ColorPicker_" .. (text or "Color"),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = parent,
	})

	createInstance("TextLabel", {
		Size = UDim2.new(0.6, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = text or "Color",
		TextColor3 = t.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	local colorBtn = createInstance("TextButton", {
		Name = "ColorBtn",
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -32, 0.5, -14),
		BackgroundColor3 = defaultColor,
		Text = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = container,
	})
	addCorner(colorBtn, 6)
	addStroke(colorBtn, t.Border, 2)

	-- 颜色预设
	local presets = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(255, 160, 60),
		Color3.fromRGB(255, 255, 60),
		Color3.fromRGB(80, 255, 80),
		Color3.fromRGB(60, 200, 255),
		Color3.fromRGB(80, 80, 255),
		Color3.fromRGB(180, 60, 255),
		Color3.fromRGB(255, 80, 200),
		Color3.fromRGB(0, 0, 0),
		Color3.fromRGB(100, 100, 100),
		Color3.fromRGB(180, 180, 180),
	}

	local pickerPopup = createInstance("Frame", {
		Name = "PickerPopup",
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = t.Surface2,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 50,
		Parent = container,
	})
	addCorner(pickerPopup, 6)
	addStroke(pickerPopup, t.Border, 1)

	local grid = createInstance("UIGridLayout", {
		CellSize = UDim2.new(0, 24, 0, 24),
		CellPadding = UDim2.new(0, 4, 0, 4),
		FillDirectionMaxCells = 6,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = pickerPopup,
	})

	local pickerPadding = createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		Parent = pickerPopup,
	})

	for _, c in ipairs(presets) do
		local swatch = createInstance("TextButton", {
			Size = UDim2.new(0, 24, 0, 24),
			BackgroundColor3 = c,
			Text = "",
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Parent = pickerPopup,
		})
		addCorner(swatch, 4)
		addStroke(swatch, t.Border, 1)

		swatch.MouseButton1Click:Connect(function()
			colorBtn.BackgroundColor3 = c
			SoundManager:Play("Click")
			if callback then callback(c) end
			-- 关闭选择器
			Animator:Tween(pickerPopup, {Size = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function()
				pickerPopup.Visible = false
			end)
		end)
	end

	local pickerOpen = false
	colorBtn.MouseButton1Click:Connect(function()
		pickerOpen = not pickerOpen
		if pickerOpen then
			pickerPopup.Visible = true
			pickerPopup.Size = UDim2.new(0, 0, 0, 0)
			local rows = math.ceil(#presets / 6)
			Animator:Spring(pickerPopup, {
				Size = UDim2.new(0, 180, 0, rows * 28 + 14),
				Position = UDim2.new(0, -10, 0, -rows * 28 - 20),
			}, 0.4)
			SoundManager:Play("Dropdown")
		else
			Animator:Tween(pickerPopup, {Size = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function()
				pickerPopup.Visible = false
			end)
		end
	end)

	return setmetatable({
		Container = container,
		ColorBtn = colorBtn,
		GetValue = function() return colorBtn.BackgroundColor3 end,
		SetValue = function(c) colorBtn.BackgroundColor3 = c end,
	}, ColorPicker)
end

-- ==================== 组件: 文本框 (Input) ====================
local Input = {}
Input.__index = Input

function Input.new(parent, text, callback, config)
	config = config or {}
	local t = getTheme()

	local container = createInstance("Frame", {
		Name = "Input_" .. (text or "Input"),
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = parent,
	})

	createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = text or "Input",
		TextColor3 = t.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	local textBox = createInstance("TextBox", {
		Name = "TextBox",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 24),
		BackgroundColor3 = t.Surface3,
		Text = config.Default or "",
		PlaceholderText = config.Placeholder or "输入...",
		PlaceholderColor3 = t.TextMuted,
		TextColor3 = t.Text,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		ClearTextOnFocus = false,
		BorderSizePixel = 0,
		Parent = container,
	})
	addCorner(textBox, 6)

	local textPadding = createInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		Parent = textBox,
	})

	textBox.FocusLost:Connect(function(enterPressed)
		if callback then callback(textBox.Text, enterPressed) end
	end)

	textBox.Focused:Connect(function()
		Animator:Tween(textBox, {BackgroundColor3 = t.Surface2}, 0.15)
		addStroke(textBox, t.Accent, 1.5)
	end)

	textBox.FocusLost:Connect(function()
		Animator:Tween(textBox, {BackgroundColor3 = t.Surface3}, 0.15)
		-- 移除焦点描边
		local stroke = textBox:FindFirstChildOfClass("UIStroke")
		if stroke and stroke ~= textBox.Parent:FindFirstChild("Stroke") then
			stroke:Destroy()
		end
	end)

	return setmetatable({
		Container = container,
		TextBox = textBox,
		GetValue = function() return textBox.Text end,
		SetValue = function(val) textBox.Text = val end,
	}, Input)
end

-- ==================== 组件: 折叠面板 (Collapsible) ====================
local Collapsible = {}
Collapsible.__index = Collapsible

function Collapsible.new(parent, title, config)
	config = config or {}
	local t = getTheme()

	local container = createInstance("Frame", {
		Name = "Collapsible_" .. (title or "Collapse"),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})

	local header = createInstance("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = t.Surface,
		Text = "",
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = container,
	})
	addCorner(header, 6)
	addStroke(header, t.Border, 1)

	local headerLabel = createInstance("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title or "Collapse",
		TextColor3 = t.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local arrow = createInstance("TextLabel", {
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -24, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "▶",
		TextColor3 = t.TextSecondary,
		TextSize = 10,
		Parent = header,
	})

	local content = createInstance("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 38),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Parent = container,
	})

	local contentLayout = createInstance("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})

	local contentPadding = createInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 4),
		Parent = content,
	})

	local collapsed = true
	local contentHeight = 0

	header.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		SoundManager:Play("Dropdown")
		if collapsed then
			Animator:Tween(arrow, {Rotation = 0}, 0.25)
			Animator:Tween(content, {Size = UDim2.new(1, 0, 0, 0)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function()
				content.Visible = false
			end)
		else
			content.Visible = true
			content.Size = UDim2.new(1, 0, 0, 0)
			Animator:Tween(arrow, {Rotation = 90}, 0.25)
			-- 计算内容高度
			task.delay(0.1, function()
				contentHeight = contentLayout.AbsoluteContentSize.Y + 8
				Animator:Tween(content, {Size = UDim2.new(1, 0, 0, contentHeight)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			end)
		end
	end)

	return setmetatable({
		Container = container,
		Header = header,
		Content = content,
		ContentLayout = contentLayout,
	}, Collapsible)
end

-- ==================== 组件: 标签页 (Tab) ====================
-- 在窗口内使用的标签页系统
local TabGroup = {}
TabGroup.__index = TabGroup

function TabGroup.new(parent, tabs, config)
	config = config or {}
	local t = getTheme()

	local container = createInstance("Frame", {
		Name = "TabGroup",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})

	-- Tab 栏
	local tabBar = createInstance("Frame", {
		Name = "TabBar",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = t.Surface2,
		BorderSizePixel = 0,
		Parent = container,
	})
	addCorner(tabBar, 6)

	local barLayout = createInstance("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabBar,
	})

	local barPadding = createInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 3),
		PaddingBottom = UDim.new(0, 3),
		Parent = tabBar,
	})

	-- Tab 内容区
	local tabContent = createInstance("Frame", {
		Name = "TabContent",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 38),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = container,
	})

	local tabContentLayout = createInstance("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabContent,
	})

	local tabPages = {}
	local tabButtons = {}

	for i, tabName in ipairs(tabs) do
		local btn = createInstance("TextButton", {
			Name = tabName,
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = (i == 1) and t.Surface3 or t.Surface2,
			Text = tabName,
			TextColor3 = (i == 1) and t.Text or t.TextSecondary,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Parent = tabBar,
		})
		addCorner(btn, 4)

		local btnPadding = createInstance("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			Parent = btn,
		})

		local page = createInstance("Frame", {
			Name = tabName,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Visible = (i == 1),
			Parent = tabContent,
		})

		local pageLayout = createInstance("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})

		btn.MouseButton1Click:Connect(function()
			SoundManager:Play("Click")
			for _, p in ipairs(tabPages) do p.Visible = false end
			page.Visible = true
			for _, b in ipairs(tabButtons) do
				Animator:Tween(b, {BackgroundColor3 = t.Surface2, TextColor3 = t.TextSecondary}, 0.2)
			end
			Animator:Tween(btn, {BackgroundColor3 = t.Surface3, TextColor3 = t.Text}, 0.2)
		end)

		table.insert(tabPages, page)
		table.insert(tabButtons, btn)
	end

	return setmetatable({
		Container = container,
		TabBar = tabBar,
		TabContent = tabContent,
		Pages = tabPages,
		Buttons = tabButtons,
		GetPage = function(self, idx) return self.Pages[idx] end,
		GetPageByName = function(self, name)
			for _, p in ipairs(self.Pages) do
				if p.Name == name then return p end
			end
		end,
	}, TabGroup)
end

-- ==================== 全局通知 API ====================
local NotificationAPI = {}

function NotificationAPI:Info(title, message, duration)
	return Notification.new({Title = title, Message = message, Duration = duration or 3, Type = "Info"})
end

function NotificationAPI:Success(title, message, duration)
	return Notification.new({Title = title, Message = message, Duration = duration or 3, Type = "Success"})
end

function NotificationAPI:Error(title, message, duration)
	return Notification.new({Title = title, Message = message, Duration = duration or 4, Type = "Error"})
end

function NotificationAPI:Warning(title, message, duration)
	return Notification.new({Title = title, Message = message, Duration = duration or 3, Type = "Warning"})
end

-- ==================== 导出 ====================
local LuminaUI = {
	Version = "1.0.0",
	Environment = envName,
	Theme = Theme,
	CurrentTheme = getTheme,
	Sound = SoundManager,
	Animator = Animator,

	-- 组件
	Window = Window,
	Section = Section,
	Button = Button,
	Toggle = Toggle,
	Slider = Slider,
	Dropdown = Dropdown,
	Keybind = Keybind,
	ColorPicker = ColorPicker,
	Input = Input,
	Collapsible = Collapsible,
	TabGroup = TabGroup,
	Notification = NotificationAPI,
}

-- ==================== 启动日志 ====================
print("----------------------------------------")
print(" LuminaUI v" .. LuminaUI.Version .. " 已就绪")
print(" 环境: " .. envName)
print(" 组件: Window | Section | Button | Toggle")
print("       Slider | Dropdown | Keybind | Input")
print("       ColorPicker | Collapsible | TabGroup")
print("       Notification (Info/Success/Error/Warning)")
print(" 动画: PopIn | PopOut | FadeIn | FadeOut")
print("       SlideIn | Spring | Tween")
print(" 音效: Click/Hover/Toggle/Dropdown 等")
print("========================================")
print("")
print(" 快速开始:")
print(" local UI = require(script.LuminaUI)")
print(" local win = UI.Window.new({Title = '我的脚本'})")
print(" local page = win:AddPage('主页')")
print(" UI.Button.new(page, '点击我', function()")
print("   UI.Notification:Success('成功', '你好！')")
print(" end)")
print("========================================")

return LuminaUI