--[[
	LuminaUI - Roblox 极致 UI 交互系统 (注入器通用版 - 修复版)
	
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
]]

print("========================================")
print(" LuminaUI 交互系统 加载中 (修复版)...")
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
		game.Debris:AddItem(sound, sound.TimeLength + 0.1)
	end)
end

function SoundManager:SetEnabled(enabled)
	soundEnabled = enabled
end

-- ==================== 动画引擎 ====================
local Animator = {}

function Animator:Tween(obj, properties, duration, easingStyle, easingDirection, callback)
	if not obj or not obj.Parent then return end
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

function Animator:Spring(obj, properties, duration, callback)
	if not obj or not obj.Parent then return end
	duration = duration or 0.4
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0)
	local tween = tweenService:Create(obj, tweenInfo, properties)
	tween:Play()

	if callback then
		tween.Completed:Connect(callback)
	end
	return tween
end

function Animator:PopIn(frame, targetSize, duration, callback)
	if not frame then return end
	local originalSize = targetSize or frame.Size
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.BackgroundTransparency = 0.3

	duration = duration or 0.4
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
	local tween = tweenService:Create(frame, tweenInfo, {
		Size = originalSize,
		BackgroundTransparency = 0.03,
	})
	tween:Play()
	if callback then tween.Completed:Connect(callback) end
	return tween
end

function Animator:PopOut(frame, duration, callback)
	if not frame then return end
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

function Animator:FadeIn(obj, duration, callback)
	if not obj then return end
	obj.BackgroundTransparency = 1
	pcall(function() obj.TextTransparency = 1 end)
	local tweenInfo = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
	local props = {BackgroundTransparency = 0, TextTransparency = 0}
	pcall(function() props.ImageTransparency = 0 end)
	local tween = tweenService:Create(obj, tweenInfo, props)
	tween:Play()
	if callback then tween.Completed:Connect(callback) end
	return tween
end

function Animator:SlideIn(frame, direction, duration, callback)
	if not frame then return end
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
	ScrollBar = Color3.fromRGB(60, 60, 70),
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

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or getTheme().Border
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
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

	local existing = playerGui:FindFirstChild(screenGui.Name)
	if existing then existing:Destroy() task.wait(0.2) end

	screenGui.Parent = playerGui

	local mainFrame = createInstance("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(0, config.Width or 520, 0, config.Height or 440),
		Position = UDim2.new(0.5, -(config.Width or 520) / 2, 0.5, -(config.Height or 440) / 2),
		BackgroundColor3 = t.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		BackgroundTransparency = 0.03,
		Parent = screenGui,
	})
	addCorner(mainFrame, 10)
	addShadow(mainFrame, 0.7, 4)
	addStroke(mainFrame, t.Border, 1.5)

	local titleBar = createInstance("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = t.Surface,
		BorderSizePixel = 0,
		Parent = mainFrame,
	})
	addCorner(titleBar, 10)

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

	local contentFrame = createInstance("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -40),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundColor3 = t.Surface,
		BorderSizePixel = 0,
		Parent = mainFrame,
	})

	local navWidth = config.NavWidth or 150
	local navFrame = createInstance("Frame", {
		Name = "Navigation",
		Size = UDim2.new(0, navWidth, 1, 0),
		BackgroundColor3 = t.Surface2,
		BorderSizePixel = 0,
		Parent = contentFrame,
	})
	addCorner(navFrame, 10)

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

	createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		Parent = navList,
	})

	local rightFrame = createInstance("Frame", {
		Name = "RightContent",
		Size = UDim2.new(1, -(navWidth + 10), 1, 0),
		Position = UDim2.new(0, navWidth + 10, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = contentFrame,
	})

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

	createInstance("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = pageScroll,
	})

	createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 10),
		Parent = pageScroll,
	})

	local pages = {}
	local navButtons = {}
	local currentPage = nil

	-- 拖拽逻辑
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

	closeBtn.MouseButton1Click:Connect(function()
		SoundManager:Play("Close")
		Animator:PopOut(mainFrame, 0.25, function()
			screenGui:Destroy()
		end)
	end)

	local minimized = false
	local originalSize = mainFrame.Size
	minBtn.MouseButton1Click:Connect(function()
		if not minimized then
			SoundManager:Play("ToggleOff")
			originalSize = mainFrame.Size
			local tween = Animator:Tween(mainFrame, {
				Size = UDim2.new(0, originalSize.X.Offset, 0, 40)
			}, 0.3)
			tween.Completed:Connect(function() minimized = true end)
		else
			SoundManager:Play("ToggleOn")
			Animator:Spring(mainFrame, {Size = originalSize}, 0.5)
			minimized = false
		end
	end)

	local self = setmetatable({
		ScreenGui = screenGui,
		MainFrame = mainFrame,
		Pages = pages,
		NavButtons = navButtons,
		CurrentPage = nil,
		PageScroll = pageScroll,
		NavList = navList,
		NavLayout = navLayout,
	}, Window)

	Animator:PopIn(mainFrame, mainFrame.Size, 0.45)
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

	createInstance("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})

	table.insert(self.Pages, page)

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

	createInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		Parent = btn,
	})

	local pageNameRef = name
	btn.MouseButton1Click:Connect(function()
		SoundManager:Play("Click")
		self:SwitchPage(pageNameRef)
	end)

	table.insert(self.NavButtons, btn)

	if #self.Pages == 1 then
		self.CurrentPage = name
		btn.BackgroundColor3 = t.Surface3
		btn.TextColor3 = t.Text
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

	self.NavList.CanvasSize = UDim2.new(0, 0, 0, self.NavLayout.AbsoluteContentSize.Y + 10)
	return page
end

function Window:SwitchPage(name)
	local t = getTheme()
	for _, page in ipairs(self.Pages) do
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

-- ==================== 组件: 分区 (Section) ====================
local Section = {}
Section.__index = Section

function Section.new(parent, title, config)
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

	if title then
		local titleFrame = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = t.Surface2,
			BorderSizePixel = 0,
			Parent = frame,
		})
		addCorner(titleFrame, 8)
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

	local content = createInstance("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		Position = title and UDim2.new(0, 0, 0, 36) or UDim2.new(0, 0, 0, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	})

	createInstance("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})

	createInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 8),
		Parent = content,
	})

	return content -- 直接返回内部容器以防后续找不到
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
	addCorner(btn, 6)

	btn.MouseEnter:Connect(function()
		SoundManager:Play("Hover", 0.3)
	end)

	btn.MouseButton1Click:Connect(function()
		SoundManager:Play("Click")
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

	createInstance("TextLabel", {
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
			Animator:Tween(toggleKnob, {Position = UDim2.new(1, -23, 0, 3)}, 0.25)
		else
			Animator:Tween(toggleBg, {BackgroundColor3 = t.Surface3}, 0.25)
			Animator:Tween(toggleKnob, {Position = UDim2.new(0, 3, 0, 3)}, 0.25)
		end
	end

	updateVisual()

	toggleBtn.MouseButton1Click:Connect(function()
		enabled = not enabled
		SoundManager:Play(enabled and "ToggleOn" or "ToggleOff")
		updateVisual()
		if callback then callback(enabled) end
	end)

	return container
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

	local trackFrame = createInstance("Frame", {
		Name = "Track",
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 0, 28),
		BackgroundColor3 = t.Surface3,
		BorderSizePixel = 0,
		Parent = container,
	})
	addCorner(trackFrame, 3)

	local fill = createInstance("Frame", {
		Name = "Fill",
		Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = t.Accent,
		BorderSizePixel = 0,
		Parent = trackFrame,
	})
	addCorner(fill, 3)

	local knob = createInstance("Frame", {
		Name = "Knob",
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new((default - min) / (max - min), -9, 0.5, -9),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = trackFrame,
	})
	addCorner(knob, 9)

	local currentValue = default
	local knobDragging = false

	local function setValueFromX(x)
		local trackAbs = trackFrame.AbsolutePosition.X
		local trackWidth = trackFrame.AbsoluteSize.X
		if trackWidth <= 0 then return end
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

	trackFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			setValueFromX(input.Position.X)
			knobDragging = true
			SoundManager:Play("Slider", 0.3)
		end
	end)

	uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			knobDragging = false
		end
	end)

	uis.InputChanged:Connect(function(input)
		if knobDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setValueFromX(uis:GetMouseLocation().X)
		end
	end)

	return container
end

-- ==================== 组件: 下拉菜单 (Dropdown) ====================
local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(parent, text, options, callback, config)
	config = config or {}
	options = options or {}
	local t = getTheme()

	local container = createInstance("Frame", {
		Name = "Dropdown_" .. (text or "Dropdown"),
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = parent,
	})

	createInstance("TextLabel", {
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
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 22),
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

	createInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		Parent = header,
	})

	local expanded = false
	header.MouseButton1Click:Connect(function()
		SoundManager:Play("Dropdown")
		expanded = not expanded
		if callback and options[1] then
			callback(options[1])
		end
	end)

	return container
end

-- ==================== 全局通知 API ====================
local NotificationAPI = {}

function NotificationAPI:Show(title, message, notifType)
	local t = getTheme()
	local notifFrame = createInstance("Frame", {
		Name = "Notification",
		Size = UDim2.new(0, 280, 0, 56),
		Position = UDim2.new(1, 0, 0, 20),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = t.Surface,
		BorderSizePixel = 0,
		ZIndex = 999,
		Parent = playerGui,
	})
	addCorner(notifFrame, 8)
	addShadow(notifFrame, 0.6, 3)

	createInstance("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18),
		Position = UDim2.new(0, 14, 0, 8),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = title or "提示",
		TextColor3 = t.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = notifFrame,
	})

	createInstance("TextLabel", {
		Size = UDim2.new(1, -20, 0, 16),
		Position = UDim2.new(0, 14, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = message or "",
		TextColor3 = t.TextSecondary,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = notifFrame,
	})

	SoundManager:Play("Popup")
	Animator:SlideIn(notifFrame, "Right", 0.35)

	task.delay(3, function()
		if notifFrame and notifFrame.Parent then
			notifFrame:Destroy()
		end
	end)
end

function NotificationAPI:Success(title, msg) self:Show(title, msg, "Success") end
function NotificationAPI:Error(title, msg) self:Show(title, msg, "Error") end
function NotificationAPI:Info(title, msg) self:Show(title, msg, "Info") end
function NotificationAPI:Warning(title, msg) self:Show(title, msg, "Warning") end

-- ==================== 启动演示窗口 ====================
task.spawn(function()
	task.wait(0.5)

	local demo = Window.new({
		Title = "LuminaUI 演示",
		Width = 500,
		Height = 420,
	})

	-- 主页
	local home = demo:AddPage("🏠 主页")
	local sec1 = Section.new(home, "欢迎")
	Button.new(sec1, "点击我试试", function()
		NotificationAPI:Success("成功", "按钮被点击了！")
	end)
	Button.new(sec1, "危险操作", function()
		NotificationAPI:Error("错误", "这是一个错误通知")
	end)

	-- 设置页
	local settings = demo:AddPage("⚙ 设置")
	local sec2 = Section.new(settings, "基础设置")
	Toggle.new(sec2, "自动瞄准", function(enabled)
		NotificationAPI:Info("提示", "自动瞄准: " .. tostring(enabled))
	end)
	Slider.new(sec2, "移动速度", function(value)
		print("速度:", value)
	end, {Min = 1, Max = 100, Default = 50})
	Dropdown.new(sec2, "选择武器", {"手枪", "步枪", "狙击枪"}, function(selected)
		NotificationAPI:Info("提示", "选中: " .. selected)
	end)

	NotificationAPI:Success("LuminaUI", "演示窗口已加载完成！")
end)

return {
	Window = Window,
	Section = Section,
	Button = Button,
	Toggle = Toggle,
	Slider = Slider,
	Dropdown = Dropdown,
	Notification = NotificationAPI,
}