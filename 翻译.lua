-- ========================================================
-- Roblox 实时智能排队汉化版 (不卡顿 · 实时 API 翻译)
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
-- 🎯 [用户身份配置表]
-----------------------------------------------------------
local AllowedDevelopers = {
    ["tgjsz78"] = true,
}

local AllowedTesterUsers = {
    ["YC1232870"] = true,
    ["no"] = true,
}

-----------------------------------------------------------
-- 🌐 [智能排队与缓存网络翻译引擎 (解决卡顿与并发)]
-----------------------------------------------------------
local TranslationCache = {}
local TranslationQueue = {}
local IsProcessingQueue = false

local function httpRequest(url)
    if request then return request({Url = url, Method = "GET"}).Body
    elseif http_request then return http_request({Url = url, Method = "GET"}).Body
    elseif syn and syn.request then return syn.request({Url = url, Method = "GET"}).Body
    else return game:HttpGet(url) end
end

local function fetchGoogleTranslate(text)
    local encodedText = HttpService:UrlEncode(text)
    local url = string.format("https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=zh-CN&dt=t&q=%s", encodedText)
    
    local success, response = pcall(function() return httpRequest(url) end)
    if success and response and #response > 0 then
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

-- 队列消费者：每隔 0.15 秒发送一个请求，绝对不卡主线程，也不会被接口限制
local function processQueue()
    if IsProcessingQueue then return end
    IsProcessingQueue = true
    
    task.spawn(function()
        while #TranslationQueue > 0 do
            local item = table.remove(TranslationQueue, 1)
            local text = item.text
            local callback = item.callback
            
            if TranslationCache[text] then
                callback(TranslationCache[text])
            else
                local result = fetchGoogleTranslate(text)
                if result and result ~= "" then
                    TranslationCache[text] = result
                    callback(result)
                else
                    callback(text)
                end
                -- 控制请求节奏，防卡顿防封禁
                task.wait(0.12)
            end
        end
        IsProcessingQueue = false
    end)
end

local function queueTranslate(text, callback)
    if not text or type(text) ~= "string" or text:match("^%s*$") then return end
    local trimmed = text:match("^%s*(.-)%s*$")
    
    -- 纯数字或链接不送去翻译
    if tonumber(trimmed) or trimmed:match("^https?://") or trimmed:match("discord%.gg") then return end
    
    if TranslationCache[trimmed] then
        callback(TranslationCache[trimmed])
        return
    end
    
    table.insert(TranslationQueue, {text = trimmed, callback = callback})
    processQueue()
end

-----------------------------------------------------------
-- 🔍 [UI 动态绑定与安全过滤]
-----------------------------------------------------------
local function processSingleUI(element)
    if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
        if element.Text and #element.Text > 0 then
            queueTranslate(element.Text, function(trans)
                if element and element.Parent and trans ~= element.Text then
                    element.Text = trans
                end
            end)
        end

        element:GetPropertyChangedSignal("Text"):Connect(function()
            if element.Text and #element.Text > 0 then
                queueTranslate(element.Text, function(trans)
                    if element and element.Parent and trans ~= element.Text then
                        element.Text = trans
                    end
                end)
            end
        end)
    end
end

local function startScan()
    task.spawn(function()
        local containers = {PlayerGui}
        if CoreGui then table.insert(containers, CoreGui) end
        if gethui then pcall(function() table.insert(containers, gethui()) end) end
        if get_hidden_gui then pcall(function() table.insert(containers, get_hidden_gui()) end) end

        for _, container in ipairs(containers) do
            pcall(function()
                for _, obj in ipairs(container:GetDescendants()) do
                    processSingleUI(obj)
                end
                container.DescendantAdded:Connect(processSingleUI)
            end)
        end
    end)
end

-----------------------------------------------------------
-- 🎨 [通用脚本作者信息弹窗]
-----------------------------------------------------------
local function showAuthorNotification(playSound)
    local notifyGui = Instance.new("ScreenGui")
    notifyGui.Name = "TaibaoNotifyGui"
    notifyGui.ResetOnSpawn = false
    notifyGui.DisplayOrder = 9999
    
    if gethui then notifyGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(notifyGui); notifyGui.Parent = CoreGui
    else notifyGui.Parent = CoreGui end

    if playSound ~= false then
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://602698205"
        sound.Volume = 1
        sound.Parent = notifyGui
        sound:Play()
    end

    local cardFrame = Instance.new("Frame")
    cardFrame.Size = UDim2.new(0, 260, 0, 66)
    cardFrame.Position = UDim2.new(1, 20, 1, -86)
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
    topLabel.Size = UDim2.new(1, -22, 0, 18)
    topLabel.Position = UDim2.new(0, 16, 0, 5)
    topLabel.BackgroundTransparency = 1
    topLabel.Font = Enum.Font.SourceSansBold
    topLabel.Text = "✨ 智能队列实时汉化已就绪"
    topLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    topLabel.TextSize = 14
    topLabel.TextXAlignment = Enum.TextXAlignment.Left
    topLabel.Parent = cardFrame

    local midLabel = Instance.new("TextLabel")
    midLabel.Size = UDim2.new(1, -22, 0, 16)
    midLabel.Position = UDim2.new(0, 16, 0, 24)
    midLabel.BackgroundTransparency = 1
    midLabel.Font = Enum.Font.SourceSans
    midLabel.Text = "⚡ 模式: 智能流控 / 实时翻译"
    midLabel.TextColor3 = Color3.fromRGB(0, 230, 180)
    midLabel.TextSize = 12
    midLabel.TextXAlignment = Enum.TextXAlignment.Left
    midLabel.Parent = cardFrame

    local bottomLabel = Instance.new("TextLabel")
    bottomLabel.Size = UDim2.new(1, -22, 0, 16)
    bottomLabel.Position = UDim2.new(0, 16, 0, 42)
    bottomLabel.BackgroundTransparency = 1
    bottomLabel.Font = Enum.Font.SourceSans
    bottomLabel.Text = "作者: Taibao001  |  🐧群聊: 1038531272"
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

    local tweenIn = TweenService:Create(cardFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -275, 1, -86)})
    tweenIn:Play()

    task.delay(2.8, function()
        local tweenInfoOut = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        TweenService:Create(cardFrame, tweenInfoOut, {Position = UDim2.new(1, 20, 1, -86), BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, tweenInfoOut, {Transparency = 1}):Play()
        TweenService:Create(accentBar, tweenInfoOut, {BackgroundTransparency = 1}):Play()
        TweenService:Create(topLabel, tweenInfoOut, {TextTransparency = 1}):Play()
        TweenService:Create(midLabel, tweenInfoOut, {TextTransparency = 1}):Play()
        local tweenOut = TweenService:Create(bottomLabel, tweenInfoOut, {TextTransparency = 1})
        tweenOut:Play()

        tweenOut.Completed:Connect(function()
            if rainbowConnection then rainbowConnection:Disconnect() end
            notifyGui:Destroy()
        end)
    end)
end

-----------------------------------------------------------
-- 🚀 [启动逻辑]
-----------------------------------------------------------
print("[Taibao Script] 智能队列流控汉化脚本启动成功")
startScan()

task.spawn(function()
    task.wait(0.2)
    local isSpecialUser = AllowedDevelopers[LocalPlayer.Name] or AllowedTesterUsers[LocalPlayer.Name]
    showAuthorNotification(not isSpecialUser)
end)