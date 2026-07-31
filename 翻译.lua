--[[
	GoogleTranslate - Roblox 注入器翻译模块 (Google 公开接口)
	
	适配所有主流注入器（Synapse X / Krnl / ScriptWare / Delta / Fluxus 等）
	使用 Google 翻译公开 API，无需 API Key，支持 100+ 种语言互译。
	
	API 端点:
	  https://translate.googleapis.com/translate_a/single?client=gtx&sl={源语言}&tl={目标语言}&dt=t&q={文本}
	
	作者: TRAE
	版本: 2.0.0 (注入器适配版)
]]

-- ==================== 环境检测 & 适配层 ====================

local function detectEnvironment()
	local env = {
		httpGet = nil,      -- HTTP GET 请求函数
		jsonDecode = nil,   -- JSON 解析函数
		jsonEncode = nil,   -- JSON 编码函数
		urlEncode = nil,    -- URL 编码函数
		executorName = "Unknown",
		isReady = false,
	}

	-- 1. 检测 HTTP 请求函数（按优先级）
	-- syn.request (Synapse X) - 返回 {Body, StatusCode, Headers}
	if syn and syn.request then
		env.httpGet = function(url)
			local response = syn.request({
				Url = url,
				Method = "GET",
				Headers = {
					["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
				}
			})
			if response and response.Body then
				return response.Body
			end
			return nil
		end
		env.executorName = "Synapse X"

	-- request (ScriptWare / Fluxus / Delta) - 返回 {Body, StatusCode}
	elseif request and type(request) == "function" then
		env.httpGet = function(url)
			local response = request({Url = url, Method = "GET"})
			if response then
				if type(response) == "string" then
					return response
				elseif response.Body then
					return response.Body
				end
			end
			return nil
		end
		env.executorName = "ScriptWare/Fluxus/Delta"

	-- http_request (Krnl / Electron) - 返回 {Body, StatusCode}
	elseif http_request and type(http_request) == "function" then
		env.httpGet = function(url)
			local response = http_request({Url = url, Method = "GET"})
			if response then
				if type(response) == "string" then
					return response
				elseif response.Body then
					return response.Body
				end
			end
			return nil
		end
		env.executorName = "Krnl/Electron"

	-- http.request (通用方式)
	elseif http and http.request then
		env.httpGet = function(url)
			local response = http.request({Url = url, Method = "GET"})
			if response then
				if type(response) == "string" then
					return response
				elseif response.Body then
					return response.Body
				end
			end
			return nil
		end
		env.executorName = "Generic HTTP"

	-- game:HttpGet (部分免费注入器)
	elseif game and pcall(function() return game.HttpGet end) then
		env.httpGet = function(url)
			local success, result = pcall(function()
				return game:HttpGet(url, true)
			end)
			if success then
				return result
			end
			return nil
		end
		env.executorName = "Simple Executor"

	-- HttpService (Roblox Studio 官方环境)
	elseif game and game:GetService("HttpService") then
		local HttpService = game:GetService("HttpService")
		env.httpGet = function(url)
			local success, result = pcall(function()
				return HttpService:GetAsync(url, true)
			end)
			if success then
				return result
			end
			return nil
		end
		env.executorName = "Roblox Studio"
	end

	-- 2. 检测 JSON 解析函数
	if env.httpGet and game and game:GetService("HttpService") then
		local HttpService = game:GetService("HttpService")
		env.jsonDecode = function(str)
			return HttpService:JSONDecode(str)
		end
		env.jsonEncode = function(tbl)
			return HttpService:JSONEncode(tbl)
		end
		env.urlEncode = function(str)
			return HttpService:UrlEncode(str)
		end
	else
		-- 没有 HttpService 时使用自定义实现
		env.jsonDecode = function(str)
			-- 简单 JSON 解析（仅用于翻译 API 返回的格式）
			-- 提取 [[["译文","原文",...]],...] 中的翻译文本
			local results = {}
			for part in string.gmatch(str, '\"([^\"]*)\"') do
				table.insert(results, part)
			end
			-- 返回模拟格式
			if #results >= 2 then
				return {
					{ { results[1], results[2] } },
					nil,
					results[3] or "auto"
				}
			end
			return nil
		end
		env.jsonEncode = function(tbl)
			return "{}"
		end
		env.urlEncode = nil  -- 将使用自定义 URL 编码
	end

	env.isReady = (env.httpGet ~= nil)
	return env
end

local ENV = detectEnvironment()

-- ==================== 自定义 URL 编码 ====================

-- 如果注入器没有提供 UrlEncode，使用自定义实现
local function customUrlEncode(str)
	if ENV.urlEncode then
		return ENV.urlEncode(str)
	end

	-- 手动 URL 编码（覆盖常见字符）
	local result = str
		:gsub("\n", "%%0A")
		:gsub("\r", "%%0D")
		:gsub(" ", "%%20")
		:gsub("!", "%%21")
		:gsub("\"", "%%22")
		:gsub("#", "%%23")
		:gsub("$", "%%24")
		:gsub("&", "%%26")
		:gsub("'", "%%27")
		:gsub("%(", "%%28")
		:gsub("%)", "%%29")
		:gsub("%*", "%%2A")
		:gsub("%+", "%%2B")
		:gsub(",", "%%2C")
		:gsub("/", "%%2F")
		:gsub(":", "%%3A")
		:gsub(";", "%%3B")
		:gsub("<", "%%3C")
		:gsub("=", "%%3D")
		:gsub(">", "%%3E")
		:gsub("%?", "%%3F")
		:gsub("@", "%%40")
		:gsub("%[", "%%5B")
		:gsub("\\", "%%5C")
		:gsub("%]", "%%5D")
		:gsub("%^", "%%5E")
		:gsub("`", "%%60")
		:gsub("{", "%%7B")
		:gsub("|", "%%7C")
		:gsub("}", "%%7D")
		:gsub("~", "%%7E")

	-- 处理中文等多字节字符
	result = result:gsub("([^%w%-%.%_%~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)

	return result
end

-- ==================== 模块定义 ====================

local GoogleTranslate = {}

-- Google 翻译公开 API 端点
local API_URL = "https://translate.googleapis.com/translate_a/single"

-- 翻译缓存
local translationCache = {}
local CACHE_MAX_SIZE = 500

-- 请求间隔控制
local lastRequestTime = 0
local MIN_REQUEST_INTERVAL = 0.5

-- 使用 wait() 替代 task.wait()（兼容更多注入器）
local function safeWait(seconds)
	local success = pcall(function()
		task.wait(seconds)
	end)
	if not success then
		-- task 库不可用，使用基础 wait
		wait(seconds)
	end
end

-- 获取当前时间（兼容注入器）
local function getTime()
	local success, result = pcall(function()
		return os.clock()
	end)
	if success then
		return result
	end
	return tick()
end

-- ==================== 语言代码表 ====================

GoogleTranslate.Languages = {
	Auto = "auto",
	ChineseSimplified = "zh-CN",
	ChineseTraditional = "zh-TW",
	English = "en",
	Japanese = "ja",
	Korean = "ko",
	French = "fr",
	German = "de",
	Spanish = "es",
	Portuguese = "pt",
	Russian = "ru",
	Italian = "it",
	Arabic = "ar",
	Thai = "th",
	Vietnamese = "vi",
	Indonesian = "id",
	Hindi = "hi",
	Turkish = "tr",
	Dutch = "nl",
	Polish = "pl",
	Swedish = "sv",
	Danish = "da",
	Finnish = "fi",
	Norwegian = "no",
	Czech = "cs",
	Hungarian = "hu",
	Romanian = "ro",
	Greek = "el",
	Hebrew = "iw",
	Ukrainian = "uk",
	Malay = "ms",
	Filipino = "tl",
}

-- ==================== 内部辅助函数 ====================

local function makeCacheKey(text, sourceLang, targetLang)
	return (sourceLang or "auto") .. "|" .. targetLang .. "|" .. text
end

local function trimCache()
	local count = 0
	for _ in pairs(translationCache) do
		count = count + 1
	end
	if count > CACHE_MAX_SIZE then
		translationCache = {}
	end
end

local function waitForRateLimit()
	local elapsed = getTime() - lastRequestTime
	if elapsed < MIN_REQUEST_INTERVAL then
		safeWait(MIN_REQUEST_INTERVAL - elapsed)
	end
	lastRequestTime = getTime()
end

-- 解析翻译 API 返回的 JSON 响应
local function parseTranslationResponse(responseBody)
	if not responseBody then
		return nil
	end

	-- 尝试用 JSON 解析
	if ENV.jsonDecode then
		local success, data = pcall(function()
			return ENV.jsonDecode(responseBody)
		end)
		if success and data and data[1] then
			local translatedParts = {}
			for _, segment in ipairs(data[1]) do
				if segment[1] then
					table.insert(translatedParts, segment[1])
				end
			end
			return table.concat(translatedParts, "")
		end
	end

	-- JSON 解析失败时的回退方案：用正则提取
	-- Google 翻译返回格式: [[["译文","原文",...]],...]
	local parts = {}
	for translated, original in string.gmatch(responseBody, '"([^"]*)"%s*,%s*"([^"]*)"') do
		table.insert(parts, translated)
	end
	if #parts > 0 then
		-- 第一个是翻译结果，第二个是原文（跳过）
		local result = parts[1]
		-- 如果后面还有翻译片段（非原文），拼接
		for i = 3, #parts, 2 do
			result = result .. parts[i]
		end
		return result
	end

	return nil
end

-- 解析语言检测结果
local function parseDetectionResponse(responseBody)
	if not responseBody then
		return "unknown"
	end

	if ENV.jsonDecode then
		local success, data = pcall(function()
			return ENV.jsonDecode(responseBody)
		end)
		if success and data and data[2] then
			return data[2]
		end
	end

	-- 回退：从响应中提取语言代码
	local lang = string.match(responseBody, '(%a%a%-?%a*)",%s*null%s*%]%]')
	if lang then
		return lang
	end

	return "unknown"
end

-- ==================== 核心 API ====================

--[[
	翻译文本
	@param text        string  - 要翻译的文本
	@param targetLang  string  - 目标语言代码（如 "zh-CN", "en", "ja"）
	@param sourceLang  string? - 源语言代码，默认 "auto"（自动检测）
	@return string     - 翻译后的文本；失败时返回原始文本
]]
function GoogleTranslate:Translate(text, targetLang, sourceLang)
	if not ENV.isReady then
		warn("[GoogleTranslate] 未检测到可用的 HTTP 请求函数，请确认注入器支持网络请求")
		return text
	end

	if not text or text == "" then
		return text
	end

	targetLang = targetLang or "zh-CN"
	sourceLang = sourceLang or "auto"

	-- 检查缓存
	local cacheKey = makeCacheKey(text, sourceLang, targetLang)
	if translationCache[cacheKey] then
		return translationCache[cacheKey]
	end

	-- 频率限制
	waitForRateLimit()

	-- 构建 URL
	local encodedText = customUrlEncode(text)
	local url = API_URL
		.. "?client=gtx"
		.. "&sl=" .. sourceLang
		.. "&tl=" .. targetLang
		.. "&dt=t"
		.. "&q=" .. encodedText

	-- 发送请求
	local responseBody = ENV.httpGet(url)

	if not responseBody then
		warn("[GoogleTranslate] 翻译请求失败: " .. tostring(text))
		return text
	end

	-- 解析结果
	local translatedText = parseTranslationResponse(responseBody)

	if not translatedText then
		warn("[GoogleTranslate] 翻译结果解析失败: " .. tostring(text))
		return text
	end

	-- 缓存
	trimCache()
	translationCache[cacheKey] = translatedText

	return translatedText
end

--[[
	批量翻译
	@param texts       table   - 要翻译的文本数组
	@param targetLang  string  - 目标语言代码
	@param sourceLang  string? - 源语言代码，默认 "auto"
	@return table      - 翻译后的文本数组
]]
function GoogleTranslate:TranslateBatch(texts, targetLang, sourceLang)
	local results = {}
	for i, text in ipairs(texts) do
		results[i] = self:Translate(text, targetLang, sourceLang)
		safeWait(0.3)
	end
	return results
end

--[[
	检测文本语言
	@param text string - 要检测的文本
	@return string - 检测到的语言代码，失败返回 "unknown"
]]
function GoogleTranslate:DetectLanguage(text)
	if not ENV.isReady or not text or text == "" then
		return "unknown"
	end

	waitForRateLimit()

	local encodedText = customUrlEncode(text)
	local url = API_URL
		.. "?client=gtx"
		.. "&sl=auto"
		.. "&tl=en"
		.. "&dt=t"
		.. "&q=" .. encodedText

	local responseBody = ENV.httpGet(url)
	return parseDetectionResponse(responseBody)
end

--[[
	翻译聊天消息（跳过 / 开头的命令）
	@param message    string - 原始消息
	@param targetLang string - 目标语言
	@return string    - 翻译后的消息
]]
function GoogleTranslate:TranslateChatMessage(message, targetLang)
	if not message or message == "" then
		return message
	end
	if string.sub(message, 1, 1) == "/" then
		return message
	end
	return self:Translate(message, targetLang, "auto")
end

--[[
	翻译 GUI 对象的 Text 属性
	@param guiObject  Instance - 任意含 Text 属性的 GUI 对象
	@param targetLang string   - 目标语言
]]
function GoogleTranslate:TranslateGuiObject(guiObject, targetLang)
	local success = pcall(function()
		if guiObject and guiObject.Text then
			local original = guiObject.Text
			if original and original ~= "" then
				local translated = self:Translate(original, targetLang)
				guiObject.Text = translated
			end
		end
	end)
	if not success then
		warn("[GoogleTranslate] GUI 翻译失败")
	end
end

--[[
	递归翻译所有子 GUI 的文本
	@param parent     Instance - 父级 GUI 对象
	@param targetLang string   - 目标语言
]]
function GoogleTranslate:TranslateAllGuiObjects(parent, targetLang)
	if not parent then return end

	local function processChildren(obj)
		pcall(function()
			for _, child in ipairs(obj:GetChildren()) do
				local className = child.ClassName or ""
				if className == "TextLabel" or className == "TextButton" or className == "TextBox" then
					self:TranslateGuiObject(child, targetLang)
				end
				-- 递归处理子对象
				if #child:GetChildren() > 0 then
					processChildren(child)
				end
			end
		end)
	end

	processChildren(parent)
end

--[[
	获取环境信息
	@return table - {executorName, isReady, httpGet, jsonDecode, urlEncode}
]]
function GoogleTranslate:GetEnvironment()
	return {
		executorName = ENV.executorName,
		isReady = ENV.isReady,
	}
end

--[[
	清除翻译缓存
]]
function GoogleTranslate:ClearCache()
	translationCache = {}
end

--[[
	获取缓存大小
	@return number - 缓存条目数
]]
function GoogleTranslate:GetCacheSize()
	local count = 0
	for _ in pairs(translationCache) do
		count = count + 1
	end
	return count
end

--[[
	设置请求间隔
	@param interval number - 最小请求间隔秒数，默认 0.5
]]
function GoogleTranslate:SetRequestInterval(interval)
	MIN_REQUEST_INTERVAL = math.max(0.1, interval or 0.5)
end

-- ==================== 初始化日志 ====================

if ENV.isReady then
	print("[GoogleTranslate] 环境检测成功 → " .. ENV.executorName)
	print("[GoogleTranslate] 模块已就绪，支持 100+ 语言互译")
else
	warn("[GoogleTranslate] 未检测到可用 HTTP 函数！")
	warn("[GoogleTranslate] 支持的注入器: Synapse X / Krnl / ScriptWare / Delta / Fluxus / 通用注入器")
end

-- ==================== 使用示例（注释掉，按需取消） ====================
--[[
-- 基础翻译
local zh = GoogleTranslate:Translate("Hello World", "zh-CN")       -- 英→中
local ja = GoogleTranslate:Translate("你好", "ja")                  -- 中→日
local en = GoogleTranslate:Translate("안녕하세요", "en")              -- 韩→英

-- 批量翻译
local texts = {"Welcome", "Play", "Settings"}
local trans = GoogleTranslate:TranslateBatch(texts, "zh-CN")

-- 检测语言
print(GoogleTranslate:DetectLanguage("こんにちは"))  -- "ja"

-- 翻译聊天消息（自动跳过 / 命令）
local msg = GoogleTranslate:TranslateChatMessage("Hello", "zh-CN")

-- 翻译游戏界面
local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
GoogleTranslate:TranslateAllGuiObjects(gui, "zh-CN")

-- 查看环境 / 清缓存 / 调频率
print(GoogleTranslate:GetEnvironment().executorName)
GoogleTranslate:ClearCache()
GoogleTranslate:SetRequestInterval(1.0)
]]

return GoogleTranslate