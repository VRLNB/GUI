-- ====================== 配置区 ======================
local SOURCE_LANG = "en"                  -- 源语言：英文
local TARGET_LANG = "zh-CN"               -- 目标语言：简体中文
local AUTO_TRANSLATE_NEW = true           -- 自动汉化后续加载的新UI
-- =========================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer.PlayerGui
local translateCache = {} -- 翻译缓存，避免重复请求浪费性能

-- ====================== 核心翻译函数（Google） ======================
local function requestTranslate(text)
    if not text or text == "" then return text end
    if translateCache[text] then return translateCache[text] end
    if not string.find(text, "%a") then return text end -- 无英文字母直接跳过

    local ok, res = pcall(function()
        -- 使用 Google 翻译的公开接口
        local url = string.format(
            "https://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s",
            SOURCE_LANG, TARGET_LANG, HttpService:UrlEncode(text)
        )
        
        local response = HttpService:GetAsync(url)
        local data = HttpService:JSONDecode(response)
        
        -- 解析 Google 返回的 JSON 数组结构
        if data and data[1] and data[1][1] and data[1][1][1] then
            local translatedText = ""
            for _, v in ipairs(data[1]) do
                if v[1] then
                    translatedText = translatedText .. v[1]
                end
            end
            return translatedText ~= "" and translatedText or text
        end
        return text
    end)

    if ok then
        translateCache[text] = res
        task.wait(0.15) -- 增加微小停顿，防并发过高
        return res
    else
        warn("Google 翻译请求失败:", res)
        return text
    end
end

-- ====================== UI 遍历汉化 ======================
local function translateElement(el)
    if not (el:IsA("TextLabel") or el:IsA("TextButton") or el:IsA("TextBox")) then return end
    if el:GetAttribute("Translated") then return end

    local original = el.Text
    if original == "" then return end
    
    task.spawn(function()
        el.Text = requestTranslate(original)
        el:SetAttribute("Translated", true)
        el:SetAttribute("OriginalText", original) -- 保留原文可还原
    end)
end

-- 汉化当前所有已加载UI
local function translateAll()
    for _, desc in ipairs(PlayerGui:GetDescendants()) do
        translateElement(desc)
    end
end

-- 监听新增UI自动汉化
if AUTO_TRANSLATE_NEW then
    PlayerGui.DescendantAdded:Connect(function(desc)
        task.wait(0.2) -- 等待控件文本初始化
        translateElement(desc)
    end)
end

-- 启动汉化
task.spawn(translateAll)