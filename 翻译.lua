--[=[
    Roblox Google 免费 API 全动态汉化脚本
    功能：
    1. 对接 Google 翻译免费公开 API 接口，实现全自动动态汉化。
    2. 内置 Cache 缓存系统，防止相同文本重复请求 API，极大地提升运行速度。
    3. 支持动态 UI 捕获（DescendantAdded）与文本修改监听（GetPropertyChangedSignal）。
]=]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== 1. 配置区域 = ====================
local CONFIG = {
    TargetLang = "zh-CN", -- 目标语言：简体中文
    SourceLang = "en",    -- 源语言：英文
    DebugMode = true,     -- 是否打印翻译日志
}

-- 翻译缓存表（避免相同文本重复消耗 API 请求）
local TranslationCache = {}
-- 正在请求中的队列（防止短时间内对同一文本发起多次网络请求）
local PendingRequests = {}

-- ==================== 2. Google 免费 API 请求核心 = ====================
local function GoogleTranslate(text)
    if not text or text == "" then return nil end
    
    -- 清理前后空格
    text = text:gsub("^%s*(.-)%s*$", "%1")
    
    -- 命中缓存直接返回
    if TranslationCache[text] then
        return TranslationCache[text]
    end
    
    if PendingRequests[text] then
        return nil
    end
    
    PendingRequests[text] = true

    -- 构造 Google 翻译公开 API 请求链接
    local encodedText = HttpService:UrlEncode(text)
    local url = string.format(
        "https://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s",
        CONFIG.SourceLang,
        CONFIG.TargetLang,
        encodedText
    )

    local success, response = pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if not req then return nil end
        
        local res = req({
            Url = url,
            Method = "GET"
        })
        
        if res and res.StatusCode == 200 then
            -- 解析 Google 返回的嵌套 JSON 数组格式
            local data = HttpService:JSONDecode(res.Body)
            if data and data[1] then
                local translatedString = ""
                for _, chunk in ipairs(data[1]) do
                    if chunk[1] then
                        translatedString = translatedString .. chunk[1]
                    end
                end
                if translatedString ~= "" then
                    return translatedString
                end
            end
        end
    end)

    PendingRequests[text] = nil

    if success and response then
        TranslationCache[text] = response
        return response
    end

    return nil
end

-- ==================== 3. 异步处理 UI 元素 = ====================
local function ProcessElement(element)
    if not element:IsA("TextLabel") and not element:IsA("TextButton") and not element:IsA("TextBox") then
        return
    end
    
    -- 处理主文本 (Text)
    local originalText = element.Text
    if originalText and originalText ~= "" and not originalText:match("^%s*$") then
        task.spawn(function()
            local translated = GoogleTranslate(originalText)
            if translated and element.Parent then
                if CONFIG.DebugMode then
                    print(string.("[Google Translate] '%s' -> '%s'"):format(originalText, translated))
                end
                element.Text = translated
            end
        end)
    end
    
    -- 处理输入框占位符 (PlaceholderText)
    if element:IsA("TextBox") then
        local originalPlaceholder = element.PlaceholderText
        if originalPlaceholder and originalPlaceholder ~= "" then
            task.spawn(function()
                local translated = GoogleTranslate(originalPlaceholder)
                if translated and element.Parent then
                    element.PlaceholderText = translated
                end
            end)
        end
    end
    
    -- 实时监听第三方脚本后续对文本的修改
    element:GetPropertyChangedSignal("Text"):Connect(function()
        local currentText = element.Text
        if currentText and currentText ~= "" and not TranslationCache[currentText] then
            task.spawn(function()
                local translated = GoogleTranslate(currentText)
                if translated and element.Parent and element.Text == currentText then
                    element.Text = translated
                end
            end)
        end
    end)
end

-- ==================== 4. 遍历与动态监听容器 = ====================
local function ScanContainer(container)
    for _, descendant in ipairs(container:GetDescendants()) do
        ProcessElement(descendant)
    end
    
    -- 动态捕获后面才生成的 UI 菜单
    container.DescendantAdded:Connect(function(descendant)
        ProcessElement(descendant)
    end)
end

-- ==================== 5. 启动脚本 = ====================
task.spawn(function()
    ScanContainer(PlayerGui)
    pcall(function()
        ScanContainer(CoreGui)
    end)
    print("[Google Translate] 动态汉化引擎已成功启动！")
end)