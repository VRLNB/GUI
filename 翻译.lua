--[[
	Roblox 翻译面板 - 注入器通用版
	一个带开关按钮的浮动 UI，开启后自动翻译当前游戏界面中的所有英文文本
	使用 Google 翻译公开接口，无需 API Key
]]

-- ==================== 安全全局变量访问 ====================
local function safeGet(name)
	local ok, val = pcall(function() return _G[name] end)
	if ok and val ~= nil then return val end
	return nil
end

-- ==================== 环境检测 ====================
local httpGet = nil
local envName = "Unknown"

local syn = safeGet("syn")
local request = safeGet("request")
local http_request = safeGet("http_request")
local http = safeGet("http")

if syn and type(syn) == "table" and syn.request then
	httpGet = function(url)
		local r = syn.request({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
		return r and r.Body
	end
	envName = "Synapse X"
elseif request and type(request) == "function" then
	httpGet = function(url)
		local r = request({Url = url, Method = "GET"})
		if type(r) == "string" then return r end
		return r and r.Body
	end
	envName = "ScriptWare/Delta/Fluxus"
elseif http_request and type(http_request) == "function" then
	httpGet = function(url)
		local r = http_request({Url = url, Method = "GET"})
		if type(r) == "string" then return r end
		return r and r.Body
	end
	envName = "Krnl/Electron"
elseif http and type(http) == "table" and http.request then
	httpGet = function(url)
		local r = http.request({Url = url, Method = "GET"})
		if type(r) == "string" then return r end
		return r and r.Body
	end
	envName = "Generic HTTP"
elseif game and pcall(function() return game.HttpGet end) then
	httpGet = function(url)
		local ok, r = pcall(function() return game:HttpGet(url, true) end)
		return ok and r or nil
	end
	envName = "Simple Executor"
elseif game and game.GetService and pcall(function() game:GetService("HttpService") end) then
	local hs = game:GetService("HttpService")
	httpGet = function(url)
		local ok, r = pcall(function() return hs:GetAsync(url, true) end)
		return ok and r or nil
	end
	envName = "Roblox Studio"
end

if not httpGet then
	print("[翻译面板] 你的注入器不支持网络请求，脚本无法运行")
	return
end

-- ==================== JSON 解析 ====================
local jsonDecode = nil
if game and game.GetService and pcall(function() game:GetService("HttpService") end) then
	local hs = game:GetService("HttpService")
	jsonDecode = function(s) return hs:JSONDecode(s) end
end

-- ==================== URL 编码 ====================
local function encodeURL(str)
	str = tostring(str)
	str = str:gsub("%W", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	return str
end

-- ==================== 翻译函数 ====================
local cache = {}
local lastTime = 0
local interval = 0.3

local function translate(text, toLang)
	toLang = toLang or "zh-CN"
	if not text or text == "" then return text end

	local key = "auto|" .. toLang .. "|" .. text
	if cache[key] then return cache[key] end

	-- 频率限制
	local now = tick()
	if now - lastTime < interval then
		wait(interval - (now - lastTime))
	end
	lastTime = tick()

	local url = "https://translate.googleapis.com/translate_a/single"
		.. "?client=gtx&sl=auto&tl=" .. toLang
		.. "&dt=t&q=" .. encodeURL(text)

	local body = httpGet(url)
	if not body then return text end

	-- 解析
	local data
	if jsonDecode then
		pcall(function() data = jsonDecode(body) end)
	end
	if not data then
		local parts = {}
		for t in body:gmatch('"([^"]*)"') do
			parts[#parts + 1] = t
		end
		if #parts >= 2 then
			data = {{parts}, nil}
		end
	end

	if data and data[1] and data[1][1] then
		local parts = {}
		for _, seg in ipairs(data[1]) do
			if seg[1] then parts[#parts + 1] = seg[1] end
		end
		local result = table.concat(parts, "")
		if #cache > 500 then cache = {} end
		cache[key] = result
		return result
	end
	return text
end

-- ==================== 创建 UI ====================
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 主容器
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TranslatePanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 检查是否已存在，避免重复创建
local existing = playerGui:FindFirstChild("TranslatePanel")
if existing then
	existing:Destroy()
	wait(0.5)
end
ScreenGui.Parent = playerGui

-- ====== 面板主体 ======
local Panel = Instance.new("Frame")
Panel.Name = "MainPanel"
Panel.Size = UDim2.new(0, 220, 0, 140)
Panel.Position = UDim2.new(0.5, -110, 0.3, 0)
Panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Panel.BorderSizePixel = 0
Panel.BackgroundTransparency = 0.05
Panel.ClipsDescendants = true
Panel.Parent = ScreenGui

-- 圆角
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Panel

-- 阴影
local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(60, 180, 255)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.4
Stroke.Parent = Panel

-- ====== 标题栏（可拖拽） ======
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Panel

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

-- 标题文字
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "翻译面板"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- 状态指示点
local StatusDot = Instance.new("Frame")
StatusDot.Name = "StatusDot"
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(1, -30, 0.5, -4)
StatusDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
StatusDot.BorderSizePixel = 0
StatusDot.Parent = TitleBar

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = StatusDot

-- ====== 内容区域 ======
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -36)
Content.Position = UDim2.new(0, 0, 0, 36)
Content.BackgroundTransparency = 1
Content.Parent = Panel

-- 状态文字
local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(1, -30, 0, 24)
StatusText.Position = UDim2.new(0, 15, 0, 12)
StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.Gotham
StatusText.Text = "翻译: 关闭"
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.TextSize = 14
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = Content

-- 开关按钮背景
local ToggleBg = Instance.new("Frame")
ToggleBg.Name = "ToggleBg"
ToggleBg.Size = UDim2.new(0, 56, 0, 28)
ToggleBg.Position = UDim2.new(1, -70, 0, 10)
ToggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
ToggleBg.BorderSizePixel = 0
ToggleBg.Parent = Content

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBg

-- 开关滑块
local ToggleKnob = Instance.new("Frame")
ToggleKnob.Name = "ToggleKnob"
ToggleKnob.Size = UDim2.new(0, 22, 0, 22)
ToggleKnob.Position = UDim2.new(0, 3, 0, 3)
ToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleKnob.BorderSizePixel = 0
ToggleKnob.Parent = ToggleBg

local KnobCorner = Instance.new("UICorner")
KnobCorner.CornerRadius = UDim.new(1, 0)
KnobCorner.Parent = ToggleKnob

-- 分隔线
local Divider = Instance.new("Frame")
Divider.Name = "Divider"
Divider.Size = UDim2.new(1, -30, 0, 1)
Divider.Position = UDim2.new(0, 15, 0, 50)
Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
Divider.BorderSizePixel = 0
Divider.Parent = Content

-- 翻译计数
local CountText = Instance.new("TextLabel")
CountText.Name = "CountText"
CountText.Size = UDim2.new(1, -30, 0, 20)
CountText.Position = UDim2.new(0, 15, 0, 60)
CountText.BackgroundTransparency = 1
CountText.Font = Enum.Font.Gotham
CountText.Text = "已翻译: 0 条"
CountText.TextColor3 = Color3.fromRGB(150, 150, 155)
CountText.TextSize = 12
CountText.TextXAlignment = Enum.TextXAlignment.Left
CountText.Parent = Content

-- 底部提示
local HintText = Instance.new("TextLabel")
HintText.Name = "HintText"
HintText.Size = UDim2.new(1, -30, 0, 20)
HintText.Position = UDim2.new(0, 15, 0, 84)
HintText.BackgroundTransparency = 1
HintText.Font = Enum.Font.Gotham
HintText.Text = "点击开关开启翻译"
HintText.TextColor3 = Color3.fromRGB(120, 120, 125)
HintText.TextSize = 11
HintText.TextXAlignment = Enum.TextXAlignment.Left
HintText.Parent = Content

-- ====== 拖拽逻辑 ======
local dragging = false
local dragStart = nil
local panelStart = nil

TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		panelStart = Panel.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

TitleBar.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		Panel.Position = UDim2.new(
			panelStart.X.Scale,
			panelStart.X.Offset + delta.X,
			panelStart.Y.Scale,
			panelStart.Y.Offset + delta.Y
		)
	end
end)

-- ====== 开关逻辑 ======
local enabled = false
local translatedCount = 0
local translatedSet = {}

local function scanAndTranslate()
	if not enabled then return end

	pcall(function()
		-- 遍历所有 ScreenGui
		local guis = playerGui:GetChildren()
		for _, gui in ipairs(guis) do
			if gui:IsA("ScreenGui") and gui.Name ~= "TranslatePanel" then
				-- 遍历所有后代
				local descendants = gui:GetDescendants()
				for _, obj in ipairs(descendants) do
					pcall(function()
						local cn = obj.ClassName or ""
						if cn == "TextLabel" or cn == "TextButton" or cn == "TextBox" then
							local text = obj.Text
							if text and text ~= "" and #text > 0 then
								-- 检查是否已翻译过
								if not translatedSet[obj] then
									-- 判断是否包含英文
									local hasEnglish = false
									for ch in text:gmatch("[%a]") do
										hasEnglish = true
										break
									end
									if hasEnglish then
										local translated = translate(text, "zh-CN")
										if translated ~= text then
											obj.Text = translated
											translatedCount = translatedCount + 1
											CountText.Text = "已翻译: " .. translatedCount .. " 条"
										end
									end
									translatedSet[obj] = true
								end
							end
						end
					end)
				end
			end
		end
	end)
end

local function toggle(on)
	enabled = on
	if on then
		-- 开启
		ToggleBg.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
		ToggleKnob:TweenPosition(UDim2.new(1, -25, 0, 3), "Out", "Quad", 0.2, true)
		StatusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
		StatusText.Text = "翻译: 开启中"
		StatusText.TextColor3 = Color3.fromRGB(0, 255, 150)
		HintText.Text = "正在自动翻译界面文本..."
		print("[翻译面板] 已开启翻译")
	else
		-- 关闭
		ToggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
		ToggleKnob:TweenPosition(UDim2.new(0, 3, 0, 3), "Out", "Quad", 0.2, true)
		StatusDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
		StatusText.Text = "翻译: 关闭"
		StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
		HintText.Text = "点击开关开启翻译"
		print("[翻译面板] 已关闭翻译")
	end
end

-- 开关点击
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(0, 56, 0, 28)
toggleBtn.Position = UDim2.new(1, -70, 0, 10)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""
toggleBtn.ZIndex = 10
toggleBtn.Parent = Content

toggleBtn.MouseButton1Click:Connect(function()
	toggle(not enabled)
end)

-- ====== 扫描循环 ======
local scanLoop
scanLoop = coroutine.wrap(function()
	while true do
		scanAndTranslate()
		wait(1) -- 每秒扫描一次
	end
end)
scanLoop()

-- ====== 退出时清理 ======
player.CharacterRemoving:Connect(function()
	ScreenGui:Destroy()
end)

-- ====== 启动日志 ======
print("========================================")
print(" 翻译面板 已加载")
print(" 环境: " .. envName)
print(" 拖拽标题栏移动面板")
print(" 点击开关按钮开启翻译")
print(" 开启后每 1 秒自动扫描并翻译")
print("========================================")