--!strict
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 兼容不同的 Executor 的 HTTP 请求函数（优先使用外部脚本常用的扩展请求，其次尝试标准）
local requestFunc = (syn and syn.request) or (http and http.request) or http_request

local TARGET_LANGUAGE = "zh-CN"
local SOURCE_LANGUAGE = "auto"

local translationCache: {[string]: string} = {}
local translatingSet: {[string]: boolean} = {}

-- 免费谷歌翻译请求函数
local function translateText(text: string): string
	if not text or text:match("^%s*$") or tonumber(text) then
		return text
	end

	if translationCache[text] then
		return translationCache[text]
	end

	if translatingSet[text] then
		return text
	end
	translatingSet[text] = true

	-- 编码文本
	-- 如果有内置的HttpService，用HttpService编码，否则用简单替换
	local HttpService = game:GetService("HttpService")
	local successEncode, encodedText = pcall(function()
		return HttpService:UrlEncode(text)
	end)
	if not successEncode then
		encodedText = text:gsub(" ", "%%20")
	end

	local url = string.format(
		"https://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s",
		SOURCE_LANGUAGE,
		TARGET_LANGUAGE,
		encodedText
	)

	local responseText = nil
	
	-- 优先使用 Executor 的全局 request 接口（客户端可跨域调用）
	if requestFunc then
		local success, res = pcall(function()
			return requestFunc({
				Url = url,
				Method = "GET"
			})
		end)
		if success and res and res.Body then
			responseText = res.Body
		end
	else
		-- 如果没有扩展请求，尝试标准方法（部分客户端环境可能会受限，但标准 Executor 基本都支持上面的 requestFunc）
		local success, res = pcall(function()
			return game:HttpGet(url)
		end)
		if success then
			responseText = res
		end
	end

	translatingSet[text] = nil

	if responseText then
		local successDecode, decoded = pcall(function()
			return HttpService:JSONDecode(responseText)
		end)

		if successDecode and decoded and decoded[1] and decoded[1][1] and decoded[1][1][1] then
			local translatedText = decoded[1][1][1]
			translationCache[text] = translatedText
			return translatedText
		end
	end

	return text
end

-- 处理单个 UI 文本对象
local function processTextInstance(instance: Instance)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		-- 立即翻译初始文本
		local currentText = (instance :: any).Text
		if currentText and currentText ~= "" then
			task.spawn(function()
				local translated = translateText(currentText)
				if translated and translated ~= currentText then
					(instance :: any).Text = translated
				end
			end)
		end

		-- 监听后续文本改动（防止别人脚本动态刷新文字导致变回英文）
		instance:GetPropertyChangedSignal("Text"):Connect(function()
			local newText = (instance :: any).Text
			if newText and newText ~= "" and not translationCache[newText] then
				task.spawn(function()
					local translated = translateText(newText)
					if translated and translated ~= newText then
						(instance :: any).Text = translated
					end
				end)
			end
		end)
	end
end

-- 递归扫描并监控容器
local function scanContainer(parent: Instance)
	for _, child in ipairs(parent:GetDescendants()) do
		processTextInstance(child)
	end
	
	-- 监听未来动态新增的子孙 UI
	parent.DescendantAdded:Connect(function(child)
		processTextInstance(child)
	end)
end

-- 监控玩家自身的 GUI 以及 CoreGui（专门对付各种外部菜单/脚本生成的悬浮窗）
if LocalPlayer then
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		scanContainer(playerGui)
	end
	LocalPlayer.PlayerGuiAdded:Connect(function(pg)
		scanContainer(pg)
	end)
end

pcall(function()
	scanContainer(CoreGui)
end)

print("外部 UI 强力汉化拦截器已在客户端成功挂载！")