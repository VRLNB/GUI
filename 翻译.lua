-- ========================================================
-- Roblox 极速 UI 汉化 + 测试用户启动检测脚本
-- 作者: 𝕿𝖆𝖎𝖇𝖆𝖔𝟎𝟎𝟏  |  🐧群聊: 1038531272
-- ========================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-----------------------------------------------------------
-- 🎯 [特定测试用户名 (Name) 启动配置表]
-----------------------------------------------------------
local AllowedTesterUsers = {
    ["YC1232870"] = true,     -- 匹配的测试用户
     ["no"] = true,   -- 匹配的测试用户
    -- ["其他测试用户名"] = true,
}

-----------------------------------------------------------
-- 📚 [第一层] 游戏术语字典
-----------------------------------------------------------
local SuperDictionary = {
    ["Auto Farm"] = "自动挂机",
    ["Auto Attack"] = "自动攻击",
    ["Auto Collect"] = "自动拾取",
    ["Auto Quest"] = "自动任务",
    ["Auto Stats"] = "自动加点",
    ["Auto Rebirth"] = "自动转生",
    ["Bring Mobs"] = "自动吸怪",
    ["Kill Aura"] = "杀戮光环",
    ["God Mode"] = "无敌模式",
    ["Infinite Jump"] = "无限跳跃",
    ["Noclip"] = "穿墙模式",
    ["Fly"] = "飞行",
    ["WalkSpeed"] = "移动速度",
    ["JumpPower"] = "跳跃高度",
    ["Teleport"] = "传送",
    ["ESP"] = "透视",

    ["X-Ray: OFF"] = "透视: 关",
    ["X-Ray: ON"] = "透视: 开",
    ["X-Ray"] = "X光透视",
    ["Fling: OFF"] = "甩人: 关",
    ["Fling: ON"] = "甩人: 开",
    ["Fling"] = "甩人/击飞",
    ["Ground Land: ON"] = "着地: 开",
    ["Ground Land: OFF"] = "着地: 关",
    ["Homelander: ON"] = "祖国人: 开",
    ["Homelander: OFF"] = "祖国人: 关",
    ["ON"] = "开",
    ["OFF"] = "关",

    ["Main"] = "主页",
    ["Combat"] = "战斗",
    ["Player"] = "玩家",
    ["Visuals"] = "视觉/透视",
    ["Misc"] = "杂项",
    ["Settings"] = "设置",
    ["Close"] = "关闭"
}

local TranslationCache = {}
for eng, chn in pairs(SuperDictionary) do
    TranslationCache[eng] = chn
end

-----------------------------------------------------------
-- 🛡️ [第二层] 精准过滤规则
-----------------------------------------------------------
local function isPlayerName(text)
    for _, player in ipairs(Players:GetPlayers()) do
        if text == player.Name or text == player.DisplayName then return true end
    end
    return false
end

local function shouldSkipText(text)
    if not text or type(text) ~= "string" or text:match("^%s*$") then return true end
    local trimmed = text:match("^%s*(.-)%s*$")
    if #trimmed <= 1 or tonumber(trimmed) then return true end
    if trimmed:match("^%$?%d+[kKmMbB%d%,%.%s]*$") or trimmed:match("^https?://") or trimmed:match("discord%.gg") then return true end
    if isPlayerName(trimmed) then return true end
    return false
end

local function isRobloxSystemUI(element)
    local current = element
    while current and current ~= game do
        local name = current.Name
        if name == "RobloxGui" or name == "RobloxPromptGui" or (name == "CoreGui" and current.Parent == game) then
            if element:IsDescendantOf(CoreGui:FindFirstChild("RobloxGui")) or element:IsDescendantOf(CoreGui:FindFirstChild("RobloxPromptGui")) then
                return true
            end
        end
        if name:find("VoiceChat") or name:find("InGameMenu") or name:find("TopBar") or name:find("PurchasePrompt") then
            return true
        end
        current = current.Parent
    end
    return false
end

-----------------------------------------------------------
-- 🌐 [第三层] 翻译引擎
-----------------------------------------------------------
local function httpRequest(url)
    if request then return request({Url = url, Method = "GET"}).Body
    elseif http_request then return http_request({Url = url, Method = "GET"}).Body
    elseif syn and syn.request then return syn.request({Url = url, Method = "GET"}).Body
    else return game:HttpGet(url) end
end

local function translateFree(text)
    local encodedText = HttpService:UrlEncode(text)
    local url = string.format("https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=zh-CN&dt=t&q=%s", encodedText)
    local success, response = pcall(function() return httpRequest(url) end)

    if success and response then
        local decodedSuccess, decoded = pcall(function() return HttpService:JSONDecode(response) end)
        if decodedSuccess and decoded and decoded[1] then
            local translated = ""
            for _, item in ipairs(decoded[1]) do
                if item[1] then translated = translated .. item[1] end
            end
            if translated ~= "" then return translated end
        end
    end
    return text
end

local function translateSmart(text)
    local trimmed = text:match("^%s*(.-)%s*$")
    if shouldSkipText(trimmed) then return text end
    if TranslationCache[trimmed] then return TranslationCache[trimmed] end

    local translatedResult = translateFree(trimmed)
    if translatedResult and translatedResult ~= "" and translatedResult ~= trimmed then
        TranslationCache[trimmed] = translatedResult
        return translatedResult
    end
    return text
end

-----------------------------------------------------------
-- 🔍 [第四层] 动态 UI 监听与绑定
-----------------------------------------------------------
local function processUI(element)
    if isRobloxSystemUI(element) then return end

    if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
        if element.Text and #element.Text > 0 then
            task.spawn(function()
                local trans = translateSmart(element.Text)
                if element and element.Parent and trans ~= element.Text then element.Text = trans end
            end)
        end

        element:GetPropertyChangedSignal("Text"):Connect(function()
            if not TranslationCache[element.Text] and not shouldSkipText(element.Text) then
                task.spawn(function()
                    local trans = translateSmart(element.Text)
                    if element and element.Parent then element.Text = trans end
                end)
            end
        end)
    end
end

local function startScan()
    local containers = {PlayerGui, CoreGui}
    if gethui then pcall(function() table.insert(containers, gethui()) end) end
    if get_hidden_gui then pcall(function() table.insert(containers, get_hidden_gui()) end) end

    for _, container in ipairs(containers) do
        for _, obj in ipairs(container:GetDescendants()) do processUI(obj) end
        container.DescendantAdded:Connect(processUI)
    end
end

-----------------------------------------------------------
-- 🎨 [通用脚本作者信息弹窗]
-----------------------------------------------------------
local function showAuthorNotification()
    local notifyGui = Instance.new("ScreenGui")
    notifyGui.Name = "TaibaoNotifyGui"
    notifyGui.ResetOnSpawn = false
    notifyGui.DisplayOrder = 9999
    
    if gethui then notifyGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(notifyGui); notifyGui.Parent = CoreGui
    else notifyGui.Parent = CoreGui end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://602698205"
    sound.Volume = 1
    sound.Parent = notifyGui
    sound:Play()

    local cardFrame = Instance.new("Frame")
    cardFrame.Name = "NotifyCard"
    cardFrame.Size = UDim2.new(0, 260, 0, 48)
    cardFrame.Position = UDim2.new(1, 20, 1, -68)
    cardFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = notifyGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = cardFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = cardFrame

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, -12)
    accentBar.Position = UDim2.new(0, 6, 0, 6)
    accentBar.BorderSizePixel = 0
    accentBar.Parent = cardFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = accentBar

    local topLabel = Instance.new("TextLabel")
    topLabel.Size = UDim2.new(1, -22, 0, 20)
    topLabel.Position = UDim2.new(0, 16, 0, 5)
    topLabel.BackgroundTransparency = 1
    topLabel.Font = Enum.Font.SourceSansBold
    topLabel.Text = "✨ 界面自动汉化已就绪"
    topLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    topLabel.TextSize = 14
    topLabel.TextXAlignment = Enum.TextXAlignment.Left
    topLabel.Parent = cardFrame

    local bottomLabel = Instance.new("TextLabel")
    bottomLabel.Size = UDim2.new(1, -22, 0, 18)
    bottomLabel.Position = UDim2.new(0, 16, 0, 24)
    bottomLabel.BackgroundTransparency = 1
    bottomLabel.Font = Enum.Font.SourceSans
    bottomLabel.Text = "作者: 𝕿𝖆𝖎𝖇𝖆𝖔𝟎𝟎𝟏  |  🐧群聊: 1038531272"
    bottomLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
    bottomLabel.TextSize = 12
    bottomLabel.TextXAlignment = Enum.TextXAlignment.Left
    bottomLabel.Parent = cardFrame

    local rainbowConnection
    rainbowConnection = RunService.RenderStepped:Connect(function()
        local hue = (tick() % 2) / 2
        local rainbowColor = Color3.fromHSV(hue, 0.8, 1)
        stroke.Color = rainbowColor
        accentBar.BackgroundColor3 = rainbowColor
    end)

    local tweenIn = TweenService:Create(cardFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -275, 1, -68)})
    tweenIn:Play()

    task.delay(2.5, function()
        local tweenInfoOut = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        TweenService:Create(cardFrame, tweenInfoOut, {Position = UDim2.new(1, 20, 1, -68), BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, tweenInfoOut, {Transparency = 1}):Play()
        TweenService:Create(accentBar, tweenInfoOut, {BackgroundTransparency = 1}):Play()
        TweenService:Create(topLabel, tweenInfoOut, {TextTransparency = 1}):Play()
        local tweenOut = TweenService:Create(bottomLabel, tweenInfoOut, {TextTransparency = 1})
        tweenOut:Play()

        tweenOut.Completed:Connect(function()
            if rainbowConnection then rainbowConnection:Disconnect() end
            notifyGui:Destroy()
        end)
    end)
end

-----------------------------------------------------------
-- 👑 [测试用户执行脚本时的专属欢迎弹窗]
-----------------------------------------------------------
local function showTesterWelcomeNotification(username)
    local notifyGui = Instance.new("ScreenGui")
    notifyGui.Name = "TaibaoTesterWelcomeGui"
    notifyGui.ResetOnSpawn = false
    notifyGui.DisplayOrder = 9999
    
    if gethui then notifyGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(notifyGui); notifyGui.Parent = CoreGui
    else notifyGui.Parent = CoreGui end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://4590662766"
    sound.Volume = 1.2
    sound.Parent = notifyGui
    sound:Play()

    local cardFrame = Instance.new("Frame")
    cardFrame.Name = "TesterCard"
    cardFrame.Size = UDim2.new(0, 260, 0, 48)
    cardFrame.Position = UDim2.new(1, 20, 1, -124)
    cardFrame.BackgroundColor3 = Color3.fromRGB(24, 20, 36)
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = notifyGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = cardFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = cardFrame

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, -12)
    accentBar.Position = UDim2.new(0, 6, 0, 6)
    accentBar.BorderSizePixel = 0
    accentBar.Parent = cardFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = accentBar

    local topLabel = Instance.new("TextLabel")
    topLabel.Size = UDim2.new(1, -22, 0, 20)
    topLabel.Position = UDim2.new(0, 16, 0, 5)
    topLabel.BackgroundTransparency = 1
    topLabel.Font = Enum.Font.SourceSansBold
    topLabel.Text = "👑 测试用户"
    topLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    topLabel.TextSize = 14
    topLabel.TextXAlignment = Enum.TextXAlignment.Left
    topLabel.Parent = cardFrame

    local bottomLabel = Instance.new("TextLabel")
    bottomLabel.Size = UDim2.new(1, -22, 0, 18)
    bottomLabel.Position = UDim2.new(0, 16, 0, 24)
    bottomLabel.BackgroundTransparency = 1
    bottomLabel.Font = Enum.Font.SourceSans
    bottomLabel.Text = "欢迎测试用户: @" .. username
    bottomLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    bottomLabel.TextSize = 13
    bottomLabel.TextXAlignment = Enum.TextXAlignment.Left
    bottomLabel.Parent = cardFrame

    local rainbowConnection
    rainbowConnection = RunService.RenderStepped:Connect(function()
        local hue = (tick() % 2) / 2
        local rainbowColor = Color3.fromHSV(hue, 0.8, 1)
        stroke.Color = rainbowColor
        accentBar.BackgroundColor3 = rainbowColor
    end)

    local tweenIn = TweenService:Create(cardFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -275, 1, -124)})
    tweenIn:Play()

    task.delay(4, function()
        local tweenInfoOut = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        TweenService:Create(cardFrame, tweenInfoOut, {Position = UDim2.new(1, 20, 1, -124), BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, tweenInfoOut, {Transparency = 1}):Play()
        TweenService:Create(accentBar, tweenInfoOut, {BackgroundTransparency = 1}):Play()
        TweenService:Create(topLabel, tweenInfoOut, {TextTransparency = 1}):Play()
        local tweenOut = TweenService:Create(bottomLabel, tweenInfoOut, {TextTransparency = 1})
        tweenOut:Play()

        tweenOut.Completed:Connect(function()
            if rainbowConnection then rainbowConnection:Disconnect() end
            notifyGui:Destroy()
        end)
    end)
end

-----------------------------------------------------------
-- 🚀 [启动逻辑：检测“当前运行脚本的人”]
-----------------------------------------------------------
print("[Taibao Script] 脚本启动成功")
startScan()

task.spawn(function()
    task.wait(0.2)
    
    -- 1. 弹出通用的汉化信息
    showAuthorNotification()

    -- 2. 检查启动脚本的当前本地用户 (LocalPlayer.Name) 是否在测试名单中
    if AllowedTesterUsers[LocalPlayer.Name] then
        showTesterWelcomeNotification(LocalPlayer.Name)
    end
end)