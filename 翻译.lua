-- ========================================================
-- Roblox 极速 UI 汉化脚本 (全界面精准匹配版 - 右下角纯彩虹跑马灯)
-- 作者: 𝕿𝖆𝖎𝖇𝖆𝖔𝟎𝟎𝟏  |  🐧群聊: 1038531272
-- ========================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-----------------------------------------------------------
-- 📚 [第一层] 拓展版游戏术语字典 (0 毫秒延迟，优先匹配)
-----------------------------------------------------------
local SuperDictionary = {
    -- 核心控制与挂机
    ["Auto Farm"] = "自动挂机",
    ["Auto Attack"] = "自动攻击",
    ["Auto Collect"] = "自动拾取",
    ["Auto Quest"] = "自动任务",
    ["Auto Stats"] = "自动加点",
    ["Auto Rebirth"] = "自动转生",
    ["Auto Buy"] = "自动购买",
    ["Auto Sell"] = "自动出售",
    ["Auto Equip"] = "自动装备",
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

    -- 截图特定常用词库
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
    ["Random Voicelines"] = "随机台词",
    ["Jerk Off R15"] = "动作 R15",
    ["ON"] = "开",
    ["OFF"] = "关",

    -- 菜单选项卡与状态
    ["Main"] = "主页",
    ["Combat"] = "战斗",
    ["Player"] = "玩家",
    ["Visuals"] = "视觉/透视",
    ["Misc"] = "杂项",
    ["Settings"] = "设置",
    ["Configs"] = "配置保存",
    ["Shop"] = "商店",
    ["Select Weapon"] = "选择武器",
    ["Select Method"] = "选择模式",
    ["Select Target"] = "选择目标",
    ["Select Player"] = "选择玩家",
    ["Toggle"] = "开关",
    ["Enabled"] = "已开启",
    ["Disabled"] = "已关闭",
    ["Enable"] = "开启",
    ["Disable"] = "关闭",
    ["Status"] = "当前状态",
    ["Refresh"] = "刷新列表",
    ["Close"] = "关闭",
    ["Minimize"] = "最小化"
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

-- 判断是否属于 Roblox 官方系统 UI 组件
local function isRobloxSystemUI(element)
    local current = element
    while current and current ~= game do
        local name = current.Name
        -- 精确跳过 Roblox 官方语音、菜单、顶栏、提示窗等
        if name == "RobloxGui" or name == "RobloxPromptGui" or name == "CoreGui" and current.Parent == game then
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
-- 🌐 [第三层] 自动公共翻译引擎
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
-- 🔍 [第四层] 深度 UI 监听与遍历 (全面捕获脚本 Gui)
-----------------------------------------------------------
local function processUI(element)
    -- 🛑 严格过滤 Roblox 官方自带 UI
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

    -- 深度搜索所有支持的脚本隐藏容器 (gethui / get_hidden_gui 等)
    if gethui then pcall(function() table.insert(containers, gethui()) end) end
    if get_hidden_gui then pcall(function() table.insert(containers, get_hidden_gui()) end) end

    for _, container in ipairs(containers) do
        for _, obj in ipairs(container:GetDescendants()) do processUI(obj) end
        container.DescendantAdded:Connect(processUI)
    end
end

-----------------------------------------------------------
-- 🎨 [纯彩虹跑马灯弹窗] (2.5秒自动淡出)
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
    cardFrame.Size = UDim2.new(0, 260, 0, 36)
    cardFrame.Position = UDim2.new(1, 20, 1, -56)
    cardFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    cardFrame.BackgroundTransparency = 0
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = notifyGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = cardFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 0
    stroke.Parent = cardFrame

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, -12)
    accentBar.Position = UDim2.new(0, 6, 0, 6)
    accentBar.BorderSizePixel = 0
    accentBar.Parent = cardFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = accentBar

    local marqueeContainer = Instance.new("Frame")
    marqueeContainer.Name = "MarqueeContainer"
    marqueeContainer.Size = UDim2.new(1, -22, 1, 0)
    marqueeContainer.Position = UDim2.new(0, 16, 0, 0)
    marqueeContainer.BackgroundTransparency = 1
    marqueeContainer.ClipsDescendants = true
    marqueeContainer.Parent = cardFrame

    local singleText = "✨ 全界面汉化已就绪  |  作者: 𝕿𝖆𝖎𝖇𝖆𝖔𝟎𝟎𝟏  |  🐧群聊: 1038531272     "
    
    local marqueeLabel = Instance.new("TextLabel")
    marqueeLabel.Name = "MarqueeText"
    marqueeLabel.Size = UDim2.new(0, 2000, 1, 0)
    marqueeLabel.Position = UDim2.new(0, 0, 0, 0)
    marqueeLabel.BackgroundTransparency = 1
    marqueeLabel.Font = Enum.Font.SourceSansBold
    marqueeLabel.Text = singleText .. singleText
    marqueeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    marqueeLabel.TextSize = 14
    marqueeLabel.TextXAlignment = Enum.TextXAlignment.Left
    marqueeLabel.Parent = marqueeContainer

    local singleTextWidth = TextService:GetTextSize(
        singleText, 
        marqueeLabel.TextSize, 
        marqueeLabel.Font, 
        Vector2.new(10000, 36)
    ).X

    local scrollSpeed = 65
    local xOffset = 0

    local scrollConnection
    scrollConnection = RunService.RenderStepped:Connect(function(deltaTime)
        xOffset = xOffset - (scrollSpeed * deltaTime)
        if math.abs(xOffset) >= singleTextWidth then
            xOffset = xOffset + singleTextWidth
        end
        marqueeLabel.Position = UDim2.new(0, xOffset, 0, 0)

        local hue = (tick() % 2) / 2
        local rainbowColor = Color3.fromHSV(hue, 0.8, 1)
        stroke.Color = rainbowColor
        accentBar.BackgroundColor3 = rainbowColor
    end)

    local tweenIn = TweenService:Create(cardFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -275, 1, -56)})
    tweenIn:Play()

    task.delay(2.5, function()
        local tweenInfoOut = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        
        TweenService:Create(cardFrame, tweenInfoOut, {Position = UDim2.new(1, 20, 1, -56), BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, tweenInfoOut, {Transparency = 1}):Play()
        TweenService:Create(accentBar, tweenInfoOut, {BackgroundTransparency = 1}):Play()
        
        local tweenOut = TweenService:Create(marqueeLabel, tweenInfoOut, {TextTransparency = 1})
        tweenOut:Play()

        tweenOut.Completed:Connect(function()
            if scrollConnection then 
                scrollConnection:Disconnect()
                scrollConnection = nil
            end
            notifyGui:Destroy()
        end)
    end)
end

-----------------------------------------------------------
-- 🚀 [启动]
-----------------------------------------------------------
print("[Taibao Translator] 汉化脚本运行成功")
startScan()

task.spawn(function()
    task.wait(0.2)
    showAuthorNotification()
end)