--[[
	Roblox 实时翻译面板 - 注入器通用版
	带开关UI，开启后实时扫描并翻译游戏中的所有英文文本
	使用 Google 翻译公开接口，无需 API Key
]]
print("========================================")
print(" 实时翻译面板 加载中...")
print("========================================")

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
local gethui = safeGet("gethui")  -- 注入器隐藏UI容器函数

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
local interval = 0.25

local function translate(text, toLang)
	toLang = toLang or "zh-CN"
	if not text or text == "" then return text end

	local key = toLang .. "|" .. text
	if cache[key] then return cache[key] end

	-- 频率限制
	local now = tick()
	local diff = now - lastTime
	if diff < interval then
		wait(interval - diff)
	end
	lastTime = tick()

	local url = "https://translate.googleapis.com/translate_a/single"
		.. "?client=gtx&sl=auto&tl=" .. toLang
		.. "&dt=t&q=" .. encodeURL(text)

	local body = httpGet(url)
	if not body then return text end

	-- 解析 JSON
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

-- 销毁旧面板
local existing = playerGui:FindFirstChild("TranslatePanel")
if existing then existing:Destroy() wait(0.3) end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TranslatePanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = playerGui

-- ====== 面板 ======
local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 230, 0, 150)
Panel.Position = UDim2.new(0.5, -115, 0.3, 0)
Panel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Panel.BorderSizePixel = 0
Panel.BackgroundTransparency = 0.03
Panel.ClipsDescendants = true
Panel.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Panel

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 200, 255)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.5
Stroke.Parent = Panel

-- ====== 标题栏 ======
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Panel

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
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
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(1, -30, 0.5, -4)
StatusDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
StatusDot.BorderSizePixel = 0
StatusDot.Parent = TitleBar

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = StatusDot

-- ====== 内容区 ======
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -36)
Content.Position = UDim2.new(0, 0, 0, 36)
Content.BackgroundTransparency = 1
Content.Parent = Panel

-- 状态文字
local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -30, 0, 24)
StatusText.Position = UDim2.new(0, 15, 0, 12)
StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.Gotham
StatusText.Text = "翻译: 关闭"
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.TextSize = 14
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = Content

-- 开关背景
local ToggleBg = Instance.new("Frame")
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
Divider.Size = UDim2.new(1, -30, 0, 1)
Divider.Position = UDim2.new(0, 15, 0, 50)
Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
Divider.BorderSizePixel = 0
Divider.Parent = Content

-- 翻译计数
local CountText = Instance.new("TextLabel")
CountText.Size = UDim2.new(1, -30, 0, 20)
CountText.Position = UDim2.new(0, 15, 0, 60)
CountText.BackgroundTransparency = 1
CountText.Font = Enum.Font.Gotham
CountText.Text = "已翻译: 0 条"
CountText.TextColor3 = Color3.fromRGB(150, 150, 155)
CountText.TextSize = 12
CountText.TextXAlignment = Enum.TextXAlignment.Left
CountText.Parent = Content

-- 扫描范围
local ScanText = Instance.new("TextLabel")
ScanText.Size = UDim2.new(1, -30, 0, 20)
ScanText.Position = UDim2.new(0, 15, 0, 84)
ScanText.BackgroundTransparency = 1
ScanText.Font = Enum.Font.Gotham
ScanText.Text = "扫描: 全局"
ScanText.TextColor3 = Color3.fromRGB(120, 120, 125)
ScanText.TextSize = 11
ScanText.TextXAlignment = Enum.TextXAlignment.Left
ScanText.Parent = Content

-- 底部提示
local HintText = Instance.new("TextLabel")
HintText.Size = UDim2.new(1, -30, 0, 20)
HintText.Position = UDim2.new(0, 15, 0, 108)
HintText.BackgroundTransparency = 1
HintText.Font = Enum.Font.Gotham
HintText.Text = "点击开关开启实时翻译"
HintText.TextColor3 = Color3.fromRGB(100, 100, 105)
HintText.TextSize = 11
HintText.TextXAlignment = Enum.TextXAlignment.Left
HintText.Parent = Content

-- ====== 拖拽 ======
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
			panelStart.X.Scale, panelStart.X.Offset + delta.X,
			panelStart.Y.Scale, panelStart.Y.Offset + delta.Y
		)
	end
end)

-- ====== 开关 ======
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 56, 0, 28)
toggleBtn.Position = UDim2.new(1, -70, 0, 10)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""
toggleBtn.ZIndex = 10
toggleBtn.Parent = Content

-- ====== 核心：实时翻译逻辑 ======
local enabled = false
local translatedCount = 0
local textCache = {}  -- 缓存 {原始文本 → 翻译后文本}

-- 判断文本是否包含英文
local function isEnglish(text)
	if not text or text == "" then return false end
	local hasAlpha = false
	for ch in text:gmatch("[%a]") do
		hasAlpha = true
		break
	end
	return hasAlpha
end

-- 收集文本对象的辅助函数
local function collectTextObjects(parent, objects)
	pcall(function()
		for _, obj in ipairs(parent:GetDescendants()) do
			local cn = obj.ClassName or ""
			if cn == "TextLabel" or cn == "TextButton" or cn == "TextBox" then
				objects[#objects + 1] = obj
			end
		end
	end)
end

-- 全局扫描所有可能的文本对象（包括注入器隐藏UI）
local function findTextObjects()
	local objects = {}

	-- 1. PlayerGui（Roblox 自带 UI）
	pcall(function()
		for _, gui in ipairs(playerGui:GetChildren()) do
			if gui.Name ~= "TranslatePanel" then
				collectTextObjects(gui, objects)
			end
		end
	end)

	-- 2. CoreGui（Roblox 核心 UI + 部分脚本 UI）
	pcall(function()
		local coreGui = game:FindService("CoreGui")
		if coreGui then
			collectTextObjects(coreGui, objects)
		end
	end)

	-- 3. ★关键★ gethui()（注入器隐藏容器，第三方脚本UI都在这里）
	pcall(function()
		if gethui and type(gethui) == "function" then
			local hui = gethui()
			if hui then
				collectTextObjects(hui, objects)
			end
		end
	end)

	-- 3.5 备用：部分注入器用 get_hui 或 GetHui
	pcall(function()
		local alt1 = safeGet("get_hui")
		local alt2 = safeGet("GetHui")
		local fn = alt1 or alt2
		if fn and type(fn) == "function" then
			local hui = fn()
			if hui then
				collectTextObjects(hui, objects)
			end
		end
	end)

	-- 4. 兜底：扫描所有已知的 GUI 容器类型
	-- 有些注入器把 UI 直接挂在 game 下或其他地方
	pcall(function()
		for _, obj in ipairs(game:GetDescendants()) do
			local cn = obj.ClassName or ""
			if cn == "ScreenGui" or cn == "SurfaceGui" or cn == "BillboardGui" then
				-- 跳过我们自己的面板
				if obj.Name ~= "TranslatePanel" then
					collectTextObjects(obj, objects)
				end
			end
		end
	end)

	return objects
end

-- 实时翻译循环
local function translateLoop()
	while true do
		if enabled then
			pcall(function()
				local objects = findTextObjects()
				local newTranslated = 0

				for _, obj in ipairs(objects) do
					pcall(function()
						local text = obj.Text
						if text and text ~= "" and #text > 0 and isEnglish(text) then
							-- 关键：不基于对象判断，基于文本内容判断
							-- 如果文本已经被翻译过（在缓存中），直接用缓存
							local cached = textCache[text]
							if cached then
								-- 文本变了？更新
								if obj.Text ~= cached and obj.Text == text then
									obj.Text = cached
									newTranslated = newTranslated + 1
								end
							else
								-- 新文本，需要翻译
								local translated = translate(text, "zh-CN")
								if translated ~= text then
									textCache[text] = translated
									obj.Text = translated
									newTranslated = newTranslated + 1
								end
							end
						end
					end)
				end

				if newTranslated > 0 then
					translatedCount = translatedCount + newTranslated
					CountText.Text = "已翻译: " .. translatedCount .. " 条"
					ScanText.Text = "扫描: " .. #objects .. " 个对象"
				end
			end)
		end
		wait(0.5)  -- 每 0.5 秒扫描一次，更实时
	end
end

local function toggle(on)
	enabled = on
	if on then
		ToggleBg.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
		ToggleKnob:TweenPosition(UDim2.new(1, -25, 0, 3), "Out", "Quad", 0.2, true)
		StatusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
		StatusText.Text = "翻译: 实时运行中"
		StatusText.TextColor3 = Color3.fromRGB(0, 255, 150)
		HintText.Text = "持续翻译所有英文文本..."
		print("[翻译面板] 已开启实时翻译")
	else
		ToggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
		ToggleKnob:TweenPosition(UDim2.new(0, 3, 0, 3), "Out", "Quad", 0.2, true)
		StatusDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
		StatusText.Text = "翻译: 已关闭"
		StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
		HintText.Text = "点击开关开启实时翻译"
		print("[翻译面板] 已关闭翻译")
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	toggle(not enabled)
end)

-- ====== 启动翻译循环 ======
coroutine.wrap(translateLoop)()

-- ====== 清理 ======
player.CharacterRemoving:Connect(function()
	ScreenGui:Destroy()
end)

-- ====== 日志 ======
print("----------------------------------------")
print(" 翻译面板 已就绪")
print(" 环境: " .. envName)
if gethui then
	print(" 隐藏容器: gethui() 已检测 ✓")
else
	print(" 隐藏容器: gethui() 未检测到")
end
print(" 面板可拖拽 | 点击开关开启")
print(" 开启后实时翻译所有英文 → 中文")
print(" 扫描范围: PlayerGui + CoreGui + gethui + 全局兜底")
print("========================================")

return true