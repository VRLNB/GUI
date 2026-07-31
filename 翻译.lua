--[[
	LuminaUI - 独立版（直接运行即可弹出界面）
	复制全部代码到你的注入器执行即可
]]

-- ==================== 第一步：环境检测（全部用pcall保护） ====================
print("[LuminaUI] 正在检测环境...")

-- 检查 game 对象
local gameExists = pcall(function() return game end)
if not gameExists then
	print("[LuminaUI] 错误: game 对象不存在，请在Roblox环境中运行")
	return
end

-- 逐个安全获取服务
local Players, player, playerGui, mouse, TweenService, UserInputService, RunService

local ok, result = pcall(function() return game:GetService("Players") end)
if ok then Players = result else print("[LuminaUI] 无法获取 Players 服务") end

local ok2, result2 = pcall(function() return game:GetService("TweenService") end)
if ok2 then TweenService = result2 else print("[LuminaUI] 无法获取 TweenService") end

local ok3, result3 = pcall(function() return game:GetService("UserInputService") end)
if ok3 then UserInputService = result3 else print("[LuminaUI] 无法获取 UserInputService") end

local ok4, result4 = pcall(function() return game:GetService("RunService") end)
if ok4 then RunService = result4 else print("[LuminaUI] 无法获取 RunService") end

-- 获取 Player
if Players then
	pcall(function()
		player = Players.LocalPlayer
		if not player then
			player = Players:FindFirstChildOfClass("Player")
		end
	end)
end

if not player then
	print("[LuminaUI] 正在等待 LocalPlayer...")
	-- 等待最多10秒
	for i = 1, 100 do
		pcall(function()
			player = Players.LocalPlayer or Players:FindFirstChildOfClass("Player")
		end)
		if player then break end
		wait(0.1)
	end
end

if not player then
	print("[LuminaUI] 错误: 无法获取 LocalPlayer")
	return
end

-- 获取 PlayerGui
pcall(function()
	playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		-- 等待 PlayerGui 出现
		playerGui = player:WaitForChild("PlayerGui", 5)
	end
end)

if not playerGui then
	print("[LuminaUI] 错误: 无法获取 PlayerGui")
	return
end

-- 获取 Mouse
pcall(function()
	mouse = player:GetMouse()
end)

print("[LuminaUI] 环境检测通过！")
print("[LuminaUI] Player: " .. player.Name)
print("[LuminaUI] PlayerGui: " .. tostring(playerGui ~= nil))

-- ==================== 第二步：销毁旧UI ====================
print("[LuminaUI] 清理旧UI...")
pcall(function()
	local old = playerGui:FindFirstChild("LuminaUI")
	if old then
		old:Destroy()
		wait(0.3)
	end
end)

-- ==================== 第三步：创建ScreenGui ====================
print("[LuminaUI] 创建 ScreenGui...")

local screenGui
pcall(function()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LuminaUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 99999  -- 最高层级，确保不被遮挡
	screenGui.Parent = playerGui
end)

if not screenGui then
	print("[LuminaUI] 错误: 无法创建 ScreenGui")
	return
end

print("[LuminaUI] ScreenGui 创建成功，DisplayOrder = 99999")

-- ==================== 第四步：创建主窗口 ====================
print("[LuminaUI] 创建主窗口...")

local mainFrame
pcall(function()
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.BackgroundTransparency = 0.05
	mainFrame.Parent = screenGui
end)

-- 圆角
pcall(function()
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame
end)

-- 描边
pcall(function()
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 140, 255)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.4
	stroke.Parent = mainFrame
end)

print("[LuminaUI] 主窗口创建成功")

-- ==================== 第五步：标题栏 ====================
print("[LuminaUI] 创建标题栏...")

local titleBar
pcall(function()
	titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame
end)

-- 标题栏圆角
pcall(function()
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = titleBar
	-- 填充底部直角
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 0, 10)
	fill.Position = UDim2.new(0, 0, 1, -10)
	fill.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
	fill.BorderSizePixel = 0
	fill.Parent = titleBar
end)

-- 标题文字
pcall(function()
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -120, 1, 0)
	title.Position = UDim2.new(0, 16, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "LuminaUI 交互系统"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar
end)

-- 关闭按钮
pcall(function()
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 28, 0, 28)
	closeBtn.Position = UDim2.new(1, -36, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 14
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 0
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = titleBar

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = closeBtn

	-- 关闭事件
	closeBtn.MouseButton1Click:Connect(function()
		pcall(function()
			-- 关闭动画
			if TweenService then
				local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0)
				local tween = TweenService:Create(mainFrame, tweenInfo, {
					Size = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,
				})
				tween:Play()
				tween.Completed:Connect(function()
					screenGui:Destroy()
				end)
			else
				screenGui:Destroy()
			end
		end)
	end)

	-- 悬停效果
	closeBtn.MouseEnter:Connect(function()
		pcall(function()
			closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		end)
	end)
	closeBtn.MouseLeave:Connect(function()
		pcall(function()
			closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
		end)
	end)
end)

-- 最小化按钮
pcall(function()
	local minBtn = Instance.new("TextButton")
	minBtn.Name = "MinBtn"
	minBtn.Size = UDim2.new(0, 28, 0, 28)
	minBtn.Position = UDim2.new(1, -68, 0, 6)
	minBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 60)
	minBtn.Text = "_"
	minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	minBtn.TextSize = 14
	minBtn.Font = Enum.Font.GothamBold
	minBtn.BorderSizePixel = 0
	minBtn.AutoButtonColor = false
	minBtn.Parent = titleBar

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = minBtn

	local minimized = false
	local originalSize = UDim2.new(0, 500, 0, 400)

	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			-- 最小化
			if TweenService then
				local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, 0)
				local tween = TweenService:Create(mainFrame, tweenInfo, {
					Size = UDim2.new(0, 500, 0, 40)
				})
				tween:Play()
			else
				mainFrame.Size = UDim2.new(0, 500, 0, 40)
			end
		else
			-- 恢复
			if TweenService then
				local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0)
				local tween = TweenService:Create(mainFrame, tweenInfo, {
					Size = originalSize
				})
				tween:Play()
			else
				mainFrame.Size = originalSize
			end
		end
	end)
end)

print("[LuminaUI] 标题栏创建成功")

-- ==================== 第六步：拖拽功能 ====================
print("[LuminaUI] 添加拖拽功能...")

pcall(function()
	local dragging = false
	local dragStart = nil
	local winStart = nil

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			winStart = mainFrame.Position
		end
	end)

	titleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	if UserInputService then
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
			   input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				mainFrame.Position = UDim2.new(
					winStart.X.Scale, winStart.X.Offset + delta.X,
					winStart.Y.Scale, winStart.Y.Offset + delta.Y
				)
			end
		end)
	end
end)

-- ==================== 第七步：左侧导航栏 ====================
print("[LuminaUI] 创建导航栏...")

local navFrame, rightFrame, pageContainer

pcall(function()
	-- 内容区
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, 0, 1, -40)
	contentFrame.Position = UDim2.new(0, 0, 0, 40)
	contentFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
	contentFrame.BorderSizePixel = 0
	contentFrame.Parent = mainFrame

	-- 导航栏
	navFrame = Instance.new("Frame")
	navFrame.Name = "Nav"
	navFrame.Size = UDim2.new(0, 140, 1, 0)
	navFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
	navFrame.BorderSizePixel = 0
	navFrame.Parent = contentFrame

	local navCorner = Instance.new("UICorner")
	navCorner.CornerRadius = UDim.new(0, 10)
	navCorner.Parent = navFrame

	-- 右侧内容区
	rightFrame = Instance.new("Frame")
	rightFrame.Name = "Right"
	rightFrame.Size = UDim2.new(1, -150, 1, 0)
	rightFrame.Position = UDim2.new(0, 150, 0, 0)
	rightFrame.BackgroundTransparency = 1
	rightFrame.BorderSizePixel = 0
	rightFrame.Parent = contentFrame

	-- 页面容器
	pageContainer = Instance.new("Frame")
	pageContainer.Name = "Pages"
	pageContainer.Size = UDim2.new(1, 0, 1, 0)
	pageContainer.BackgroundTransparency = 1
	pageContainer.BorderSizePixel = 0
	pageContainer.Parent = rightFrame
end)

print("[LuminaUI] 导航栏创建成功")

-- ==================== 第八步：创建导航按钮 ====================
local pages = {}
local navButtons = {}

local function createNavButton(name, index)
	local btn
	pcall(function()
		btn = Instance.new("TextButton")
		btn.Name = "Nav_" .. name
		btn.Size = UDim2.new(1, -16, 0, 34)
		btn.Position = UDim2.new(0, 8, 0, 8 + (index - 1) * 38)
		btn.BackgroundColor3 = (index == 1) and Color3.fromRGB(42, 42, 54) or Color3.fromRGB(34, 34, 44)
		btn.Text = "  " .. name
		btn.TextColor3 = (index == 1) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 170)
		btn.TextSize = 13
		btn.Font = Enum.Font.Gotham
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Parent = navFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn

		-- 左侧指示条
		if index == 1 then
			local indicator = Instance.new("Frame")
			indicator.Name = "Indicator"
			indicator.Size = UDim2.new(0, 3, 0, 20)
			indicator.Position = UDim2.new(0, 0, 0.5, -10)
			indicator.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
			indicator.BorderSizePixel = 0
			indicator.Parent = btn

			local indCorner = Instance.new("UICorner")
			indCorner.CornerRadius = UDim.new(0, 2)
			indCorner.Parent = indicator
		end
	end)
	return btn
end

-- ==================== 第九步：创建页面内容 ====================
-- 主页
local homePage
pcall(function()
	homePage = Instance.new("Frame")
	homePage.Name = "主页"
	homePage.Size = UDim2.new(1, 0, 1, 0)
	homePage.BackgroundTransparency = 1
	homePage.BorderSizePixel = 0
	homePage.Visible = true
	homePage.Parent = pageContainer
end)

-- 设置页
local settingsPage
pcall(function()
	settingsPage = Instance.new("Frame")
	settingsPage.Name = "设置"
	settingsPage.Size = UDim2.new(1, 0, 1, 0)
	settingsPage.BackgroundTransparency = 1
	settingsPage.BorderSizePixel = 0
	settingsPage.Visible = false
	settingsPage.Parent = pageContainer
end)

-- 关于页
local aboutPage
pcall(function()
	aboutPage = Instance.new("Frame")
	aboutPage.Name = "关于"
	aboutPage.Size = UDim2.new(1, 0, 1, 0)
	aboutPage.BackgroundTransparency = 1
	aboutPage.BorderSizePixel = 0
	aboutPage.Visible = false
	aboutPage.Parent = pageContainer
end)

-- 页面切换函数
local function switchPage(pageName)
	pcall(function()
		-- 隐藏所有页面
		for _, child in ipairs(pageContainer:GetChildren()) do
			if child:IsA("Frame") then
				child.Visible = false
			end
		end

		-- 显示目标页面
		local target = pageContainer:FindFirstChild(pageName)
		if target then target.Visible = true end

		-- 更新导航按钮样式
		for _, btn in ipairs(navFrame:GetChildren()) do
			if btn:IsA("TextButton") then
				local btnPageName = btn.Name:gsub("Nav_", "")
				if btnPageName == pageName then
					btn.BackgroundColor3 = Color3.fromRGB(42, 42, 54)
					btn.TextColor3 = Color3.fromRGB(255, 255, 255)
					-- 添加指示条
					if not btn:FindFirstChild("Indicator") then
						local indicator = Instance.new("Frame")
						indicator.Name = "Indicator"
						indicator.Size = UDim2.new(0, 3, 0, 20)
						indicator.Position = UDim2.new(0, 0, 0.5, -10)
						indicator.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
						indicator.BorderSizePixel = 0
						indicator.Parent = btn

						local indCorner = Instance.new("UICorner")
						indCorner.CornerRadius = UDim.new(0, 2)
						indCorner.Parent = indicator
					end
				else
					btn.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
					btn.TextColor3 = Color3.fromRGB(160, 160, 170)
					local indicator = btn:FindFirstChild("Indicator")
					if indicator then indicator:Destroy() end
				end
			end
		end
	end)
end

-- 创建导航按钮
local navHome = createNavButton("主页", 1)
local navSettings = createNavButton("设置", 2)
local navAbout = createNavButton("关于", 3)

navHome.MouseButton1Click:Connect(function() switchPage("主页") end)
navSettings.MouseButton1Click:Connect(function() switchPage("设置") end)
navAbout.MouseButton1Click:Connect(function() switchPage("关于") end)

-- 导航按钮悬停效果
for _, btn in ipairs({navHome, navSettings, navAbout}) do
	btn.MouseEnter:Connect(function()
		local pageName = btn.Name:gsub("Nav_", "")
		local currentVisible = nil
		for _, child in ipairs(pageContainer:GetChildren()) do
			if child:IsA("Frame") and child.Visible then
				currentVisible = child.Name
				break
			end
		end
		if pageName ~= currentVisible then
			btn.BackgroundColor3 = Color3.fromRGB(42, 42, 54)
		end
	end)
	btn.MouseLeave:Connect(function()
		local pageName = btn.Name:gsub("Nav_", "")
		local currentVisible = nil
		for _, child in ipairs(pageContainer:GetChildren()) do
			if child:IsA("Frame") and child.Visible then
				currentVisible = child.Name
				break
			end
		end
		if pageName ~= currentVisible then
			btn.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
		end
	end)
end

-- ==================== 第十步：填充主页内容 ====================
print("[LuminaUI] 创建UI组件...")

-- 辅助函数：创建分区
local function createSection(parent, title, yPos)
	local section = Instance.new("Frame")
	section.Name = "Section_" .. title
	section.Size = UDim2.new(1, -20, 0, 0)
	section.Position = UDim2.new(0, 10, 0, yPos)
	section.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
	section.BorderSizePixel = 0
	section.Parent = parent

	local secCorner = Instance.new("UICorner")
	secCorner.CornerRadius = UDim.new(0, 8)
	secCorner.Parent = section

	-- 标题
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = section

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleBar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 0, 8)
	fill.Position = UDim2.new(0, 0, 1, -8)
	fill.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
	fill.BorderSizePixel = 0
	fill.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 1, 0)
	titleLabel.Position = UDim2.new(0, 12, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- 内容区
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 0, 0)
	content.Position = UDim2.new(0, 0, 0, 34)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Parent = section

	return section, content
end

-- 主页：欢迎区
local welcomeSection, welcomeContent = createSection(homePage, "欢迎使用 LuminaUI", 10)
welcomeSection.Size = UDim2.new(1, -20, 0, 80)

-- 欢迎文字
local welcomeText = Instance.new("TextLabel")
welcomeText.Size = UDim2.new(1, -20, 0, 40)
welcomeText.Position = UDim2.new(0, 10, 0, 0)
welcomeText.BackgroundTransparency = 1
welcomeText.Font = Enum.Font.Gotham
welcomeText.Text = "这是一个功能完整的UI交互系统演示\n包含按钮、开关、滑块、下拉菜单等组件"
welcomeText.TextColor3 = Color3.fromRGB(160, 160, 170)
welcomeText.TextSize = 12
welcomeText.TextXAlignment = Enum.TextXAlignment.Left
welcomeText.TextWrapped = true
welcomeText.Parent = welcomeContent

-- 主页：按钮演示
local btnSection, btnContent = createSection(homePage, "按钮演示", 100)
btnSection.Size = UDim2.new(1, -20, 0, 120)

-- 普通按钮
local btn1 = Instance.new("TextButton")
btn1.Size = UDim2.new(1, -20, 0, 34)
btn1.Position = UDim2.new(0, 10, 0, 5)
btn1.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
btn1.Text = "点击发送通知"
btn1.TextColor3 = Color3.fromRGB(255, 255, 255)
btn1.TextSize = 13
btn1.Font = Enum.Font.GothamBold
btn1.BorderSizePixel = 0
btn1.AutoButtonColor = false
btn1.Parent = btnContent

local btn1Corner = Instance.new("UICorner")
btn1Corner.CornerRadius = UDim.new(0, 6)
btn1Corner.Parent = btn1

btn1.MouseEnter:Connect(function()
	btn1.BackgroundColor3 = Color3.fromRGB(100, 160, 255)
end)
btn1.MouseLeave:Connect(function()
	btn1.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
end)
btn1.MouseButton1Click:Connect(function()
	print("[LuminaUI] 按钮被点击了！")
end)

-- 危险按钮
local btn2 = Instance.new("TextButton")
btn2.Size = UDim2.new(1, -20, 0, 34)
btn2.Position = UDim2.new(0, 10, 0, 45)
btn2.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
btn2.Text = "危险操作按钮"
btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
btn2.TextSize = 13
btn2.Font = Enum.Font.GothamBold
btn2.BorderSizePixel = 0
btn2.AutoButtonColor = false
btn2.Parent = btnContent

local btn2Corner = Instance.new("UICorner")
btn2Corner.CornerRadius = UDim.new(0, 6)
btn2Corner.Parent = btn2

btn2.MouseEnter:Connect(function()
	btn2.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
end)
btn2.MouseLeave:Connect(function()
	btn2.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
end)
btn2.MouseButton1Click:Connect(function()
	print("[LuminaUI] 危险按钮被点击！")
end)

-- ==================== 第十一步：填充设置页内容 ====================
-- 设置页：开关
local toggleSection, toggleContent = createSection(settingsPage, "开关设置", 10)
toggleSection.Size = UDim2.new(1, -20, 0, 130)

-- 开关1：自动瞄准
local toggle1Container = Instance.new("Frame")
toggle1Container.Size = UDim2.new(1, -20, 0, 36)
toggle1Container.Position = UDim2.new(0, 10, 0, 5)
toggle1Container.BackgroundTransparency = 1
toggle1Container.BorderSizePixel = 0
toggle1Container.Parent = toggleContent

local toggle1Label = Instance.new("TextLabel")
toggle1Label.Size = UDim2.new(1, -60, 1, 0)
toggle1Label.BackgroundTransparency = 1
toggle1Label.Font = Enum.Font.Gotham
toggle1Label.Text = "自动瞄准"
toggle1Label.TextColor3 = Color3.fromRGB(160, 160, 170)
toggle1Label.TextSize = 13
toggle1Label.TextXAlignment = Enum.TextXAlignment.Left
toggle1Label.Parent = toggle1Container

local toggle1Bg = Instance.new("Frame")
toggle1Bg.Size = UDim2.new(0, 48, 0, 26)
toggle1Bg.Position = UDim2.new(1, -52, 0.5, -13)
toggle1Bg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
toggle1Bg.BorderSizePixel = 0
toggle1Bg.Parent = toggle1Container

local toggle1BgCorner = Instance.new("UICorner")
toggle1BgCorner.CornerRadius = UDim.new(0, 13)
toggle1BgCorner.Parent = toggle1Bg

local toggle1Knob = Instance.new("Frame")
toggle1Knob.Size = UDim2.new(0, 20, 0, 20)
toggle1Knob.Position = UDim2.new(0, 3, 0, 3)
toggle1Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
toggle1Knob.BorderSizePixel = 0
toggle1Knob.Parent = toggle1Bg

local toggle1KnobCorner = Instance.new("UICorner")
toggle1KnobCorner.CornerRadius = UDim.new(0, 10)
toggle1KnobCorner.Parent = toggle1Knob

local toggle1Enabled = false
local toggle1Btn = Instance.new("TextButton")
toggle1Btn.Size = UDim2.new(1, 0, 1, 0)
toggle1Btn.BackgroundTransparency = 1
toggle1Btn.Text = ""
toggle1Btn.ZIndex = 10
toggle1Btn.Parent = toggle1Container

toggle1Btn.MouseButton1Click:Connect(function()
	toggle1Enabled = not toggle1Enabled
	if toggle1Enabled then
		toggle1Bg.BackgroundColor3 = Color3.fromRGB(50, 220, 120)
		toggle1Knob.Position = UDim2.new(1, -23, 0, 3)
	else
		toggle1Bg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		toggle1Knob.Position = UDim2.new(0, 3, 0, 3)
	end
	print("[LuminaUI] 自动瞄准: " .. tostring(toggle1Enabled))
end)

-- 开关2：ESP透视
local toggle2Container = Instance.new("Frame")
toggle2Container.Size = UDim2.new(1, -20, 0, 36)
toggle2Container.Position = UDim2.new(0, 10, 0, 45)
toggle2Container.BackgroundTransparency = 1
toggle2Container.BorderSizePixel = 0
toggle2Container.Parent = toggleContent

local toggle2Label = Instance.new("TextLabel")
toggle2Label.Size = UDim2.new(1, -60, 1, 0)
toggle2Label.BackgroundTransparency = 1
toggle2Label.Font = Enum.Font.Gotham
toggle2Label.Text = "ESP 透视"
toggle2Label.TextColor3 = Color3.fromRGB(160, 160, 170)
toggle2Label.TextSize = 13
toggle2Label.TextXAlignment = Enum.TextXAlignment.Left
toggle2Label.Parent = toggle2Container

local toggle2Bg = Instance.new("Frame")
toggle2Bg.Size = UDim2.new(0, 48, 0, 26)
toggle2Bg.Position = UDim2.new(1, -52, 0.5, -13)
toggle2Bg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
toggle2Bg.BorderSizePixel = 0
toggle2Bg.Parent = toggle2Container

local toggle2BgCorner = Instance.new("UICorner")
toggle2BgCorner.CornerRadius = UDim.new(0, 13)
toggle2BgCorner.Parent = toggle2Bg

local toggle2Knob = Instance.new("Frame")
toggle2Knob.Size = UDim2.new(0, 20, 0, 20)
toggle2Knob.Position = UDim2.new(0, 3, 0, 3)
toggle2Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
toggle2Knob.BorderSizePixel = 0
toggle2Knob.Parent = toggle2Bg

local toggle2KnobCorner = Instance.new("UICorner")
toggle2KnobCorner.CornerRadius = UDim.new(0, 10)
toggle2KnobCorner.Parent = toggle2Knob

local toggle2Enabled = false
local toggle2Btn = Instance.new("TextButton")
toggle2Btn.Size = UDim2.new(1, 0, 1, 0)
toggle2Btn.BackgroundTransparency = 1
toggle2Btn.Text = ""
toggle2Btn.ZIndex = 10
toggle2Btn.Parent = toggle2Container

toggle2Btn.MouseButton1Click:Connect(function()
	toggle2Enabled = not toggle2Enabled
	if toggle2Enabled then
		toggle2Bg.BackgroundColor3 = Color3.fromRGB(50, 220, 120)
		toggle2Knob.Position = UDim2.new(1, -23, 0, 3)
	else
		toggle2Bg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		toggle2Knob.Position = UDim2.new(0, 3, 0, 3)
	end
	print("[LuminaUI] ESP透视: " .. tostring(toggle2Enabled))
end)

-- 设置页：滑块
local sliderSection, sliderContent = createSection(settingsPage, "滑块设置", 150)
sliderSection.Size = UDim2.new(1, -20, 0, 85)

-- 滑块1：移动速度
local slider1Container = Instance.new("Frame")
slider1Container.Size = UDim2.new(1, -20, 0, 50)
slider1Container.Position = UDim2.new(0, 10, 0, 5)
slider1Container.BackgroundTransparency = 1
slider1Container.BorderSizePixel = 0
slider1Container.Parent = sliderContent

local slider1Label = Instance.new("TextLabel")
slider1Label.Size = UDim2.new(0.7, 0, 0, 20)
slider1Label.BackgroundTransparency = 1
slider1Label.Font = Enum.Font.Gotham
slider1Label.Text = "移动速度"
slider1Label.TextColor3 = Color3.fromRGB(160, 160, 170)
slider1Label.TextSize = 13
slider1Label.TextXAlignment = Enum.TextXAlignment.Left
slider1Label.Parent = slider1Container

local slider1Value = Instance.new("TextLabel")
slider1Value.Size = UDim2.new(0.3, 0, 0, 20)
slider1Value.Position = UDim2.new(0.7, 0, 0, 0)
slider1Value.BackgroundTransparency = 1
slider1Value.Font = Enum.Font.GothamBold
slider1Value.Text = "50"
slider1Value.TextColor3 = Color3.fromRGB(80, 140, 255)
slider1Value.TextSize = 13
slider1Value.TextXAlignment = Enum.TextXAlignment.Right
slider1Value.Parent = slider1Container

local slider1Track = Instance.new("Frame")
slider1Track.Size = UDim2.new(1, 0, 0, 6)
slider1Track.Position = UDim2.new(0, 0, 0, 28)
slider1Track.BackgroundColor3 = Color3.fromRGB(42, 42, 54)
slider1Track.BorderSizePixel = 0
slider1Track.Parent = slider1Container

local slider1TrackCorner = Instance.new("UICorner")
slider1TrackCorner.CornerRadius = UDim.new(0, 3)
slider1TrackCorner.Parent = slider1Track

local slider1Fill = Instance.new("Frame")
slider1Fill.Size = UDim2.new(0.5, 0, 1, 0)
slider1Fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
slider1Fill.BorderSizePixel = 0
slider1Fill.Parent = slider1Track

local slider1FillCorner = Instance.new("UICorner")
slider1FillCorner.CornerRadius = UDim.new(0, 3)
slider1FillCorner.Parent = slider1Fill

local slider1Knob = Instance.new("Frame")
slider1Knob.Size = UDim2.new(0, 18, 0, 18)
slider1Knob.Position = UDim2.new(0.5, -9, 0.5, -9)
slider1Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
slider1Knob.BorderSizePixel = 0
slider1Knob.ZIndex = 5
slider1Knob.Parent = slider1Track

local slider1KnobCorner = Instance.new("UICorner")
slider1KnobCorner.CornerRadius = UDim.new(0, 9)
slider1KnobCorner.Parent = slider1Knob

-- 滑块拖拽
local slider1Dragging = false
slider1Knob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		slider1Dragging = true
	end
end)
slider1Knob.InputEnded:Connect(function(input)
	slider1Dragging = false
end)
slider1Track.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		slider1Dragging = true
		local trackAbs = slider1Track.AbsolutePosition.X
		local trackWidth = slider1Track.AbsoluteSize.X
		local ratio = math.clamp((input.Position.X - trackAbs) / trackWidth, 0, 1)
		slider1Fill.Size = UDim2.new(ratio, 0, 1, 0)
		slider1Knob.Position = UDim2.new(ratio, -9, 0.5, -9)
		local val = math.floor(ratio * 100)
		slider1Value.Text = tostring(val)
	end
end)
slider1Track.InputEnded:Connect(function()
	slider1Dragging = false
end)

if UserInputService then
	UserInputService.InputChanged:Connect(function(input)
		if slider1Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
		   input.UserInputType == Enum.UserInputType.Touch) then
			if mouse then
				local trackAbs = slider1Track.AbsolutePosition.X
				local trackWidth = slider1Track.AbsoluteSize.X
				local ratio = math.clamp((mouse.X - trackAbs) / trackWidth, 0, 1)
				slider1Fill.Size = UDim2.new(ratio, 0, 1, 0)
				slider1Knob.Position = UDim2.new(ratio, -9, 0.5, -9)
				local val = math.floor(ratio * 100)
				slider1Value.Text = tostring(val)
			end
		end
	end)
end

-- ==================== 第十二步：填充关于页内容 ====================
local aboutSection, aboutContent = createSection(aboutPage, "关于 LuminaUI", 10)
aboutSection.Size = UDim2.new(1, -20, 0, 120)

local aboutInfo = Instance.new("TextLabel")
aboutInfo.Size = UDim2.new(1, -20, 0, 80)
aboutInfo.Position = UDim2.new(0, 10, 0, 5)
aboutInfo.BackgroundTransparency = 1
aboutInfo.Font = Enum.Font.Gotham
aboutInfo.Text = "LuminaUI v1.0\n\n一个为 Roblox 注入器设计的\n纯代码 UI 交互系统\n\n支持: 按钮 · 开关 · 滑块\n      拖拽 · 动画 · 页面切换"
aboutInfo.TextColor3 = Color3.fromRGB(160, 160, 170)
aboutInfo.TextSize = 12
aboutInfo.TextXAlignment = Enum.TextXAlignment.Left
aboutInfo.TextWrapped = true
aboutInfo.Parent = aboutContent

-- ==================== 第十三步：入场动画 + 完成 ====================
print("[LuminaUI] 播放入场动画...")

-- 弹入动画
pcall(function()
	if TweenService then
		-- 先缩小到0
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		mainFrame.BackgroundTransparency = 0.5

		local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
		local tween = TweenService:Create(mainFrame, tweenInfo, {
			Size = UDim2.new(0, 500, 0, 400),
			BackgroundTransparency = 0.05,
		})
		tween:Play()
		print("[LuminaUI] 入场动画播放中...")
	else
		print("[LuminaUI] TweenService 不可用，跳过动画")
	end
end)

print("========================================")
print(" LuminaUI 独立版 - 加载完成！")
print(" 界面应该已经显示在屏幕中央")
print(" 如果看不到，请检查:")
print(" 1. 是否有其他UI遮挡 (DisplayOrder = 99999)")
print(" 2. 注入器是否支持 ScreenGui")
print(" 3. PlayerGui 是否正常加载")
print("========================================")