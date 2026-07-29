--[=[
    Roblox 全动态 API 智能汉化脚本
    功能：
    1. 移除本地词典，通过外部翻译 API 实现全自动智能汉化。
    2. 内置翻译缓存（Cache），避免对相同文本重复发起网络请求，极大地提升性能并防止 API 封禁。
    3. 实时监听动态生成的 UI (`DescendantAdded`) 与文本变动 (`GetPropertyChangedSignal`)。
]=]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== 1. 配置区域 = ====================
local CONFIG = {
    TargetLanguage = "zh", -- 目标语言：简体中文
    DebugMode = true,      -- 是否开启控制台日志
    -- 使用支持 Roblox 跨域或公共免费的翻译接口（例如 MyMemory API 或自建代理 API）
    -- 提示：部分 Executor 的 http_request 可能需要根据实际情况调整请求头
}

-- 翻译缓存表：防止相同文本重复请求 API，大幅节省性能
local TranslationCache = {}
-- 正在请求中的文本队列，防止并发重复请求
local PendingRequests = {}

-- ==================== 2. API 请求函数 = ====================
local function RequestApiTranslation(text)
    if not text or text == "" then return nil end
    
    -- 检查缓存
    if TranslationCache[text] then
        return TranslationCache[text]
    end
    
    if PendingRequests[text] then
        return nil -- 正在请求中，跳过本次
    end
    
    PendingRequests[text] = true

    -- 这里以 MyMemory 免费公开翻译 API 为例（无需 Key，适合基础汉化）
    -- 如果您有自己的高级翻译 API（如 DeepL / Google Cloud API），可以在这里替换 URL 和解析方式
    local encodedText = HttpService:UrlEncode(text)
    local url = string.format("https://api.mymemory.translated.net/get?q=%s&langpair=en|zh", encodedText)

    local success, response = pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if not req then return nil end
        
        local res = req({
            Url = url,
            Method = "GET"
        })
        
        if res and res.StatusCode == 200 then
            local data = HttpService:JSONDecode(res.Body)
            if data and data.responseData and data.responseData.translatedText then
                return data.responseData.translatedText
            end
        end
    end)

    PendingRequests[text] = nil

    if success and response then
        -- 过滤掉 API 报错或未翻译的情况
        if response:sub(1, 7) == "MYMEMORY" or response == text then
            return nil
        end
        TranslationCache[text] = response
        return response
    end

    return nil
end

-- ==================== 3. 异步处理 UI 翻译 = ====================
local function ProcessElement(element)
    if not element:IsA("TextLabel") and not element:IsA("TextButton") and not element:IsA("TextBox") then
        return
    end
    
    -- 处理主文本 (Text)
    local originalText = element.Text
    if originalText and originalText ~= "" and not originalText:match("^%s*$") then
        task.spawn(function()
            local translated = RequestApiTranslation(originalText)
            if translated and element.Parent then
                if CONFIG.DebugMode then
                    print(string.("[API Localization] '%s' -> '%s'"):format(originalText, translated))
                end
                element.Text = translated
            end
        end)
    end
    
    -- 处理输入框占位符文本 (PlaceholderText)
    if element:IsA("TextBox") then
        local originalPlaceholder = element.PlaceholderText
        if originalPlaceholder and originalPlaceholder ~= "" then
            task.spawn(function()
                local translated = RequestApiTranslation(originalPlaceholder)
                if translated and element.Parent then
                    element.PlaceholderText = translated
                end
            end)
        end
    end
    
    -- 监听文本后续修改
    element:GetPropertyChangedSignal("Text"):Connect(function()
        local currentText = element.Text
        if currentText and currentText ~= "" and not TranslationCache[currentText] then
            task.spawn(function()
                local translated = RequestApiTranslation(currentText)
                if translated and element.Parent and element.Text == currentText then
                    element.Text = translated
                end
            end)
        end
    end)
end

-- ==================== 4. 容器扫描与监听 = ====================
local function ScanContainer(container)
    for _, descendant in ipairs(container:GetDescendants()) do
        ProcessElement(descendant)
    end
    
    container.DescendantAdded:Connect(function(descendant)
        ProcessElement(descendant)
    end)
end

-- ==================== 5. 启动程序 = ====================
task.spawn(function()
    ScanContainer(PlayerGui)
    pcall(function()
        ScanContainer(CoreGui)
    end)
    print("[API Localization] 全动态 API 汉化脚本已成功启动！")
end)