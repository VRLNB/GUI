--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui") -- 有些脚本的UI会生成在这里

local TARGET_LANGUAGE = "zh-CN"
local SOURCE_LANGUAGE = "auto"

local translationCache: {[string]: string} = {}
local translatingSet: {[string]: boolean} = {}

-- 翻译核心函数（使用免费 gtx 接口）
local function translateText(text: string): string
	if not text or text:match("^%s*$") or tonumber(text) then
		return text
	end

	if translationCache[text] then
		return translationCache[text]
	end

	if translatingSet[text] then
		return text -- 正在翻译中，暂不重复请求
	end
	translatingSet[text] = true

	local encodedText = HttpService:UrlEncode(text)
	local url = string.format(
		"https://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s",
		SOURCE_LANGUAGE,
		TARGET_LANGUAGE,
		encodedText
	)

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	translatingSet[text] = nil

	if success then
		local successDecode, decoded = pcall(function()
			return HttpService:JSONDecode(response)
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
local function hookTextInstance(instance: Instance)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		-- 初始翻译
		local currentText = (instance :: any).Text
		if currentText and currentText ~= "" then
			task.spawn(function()
				local translated = translateText(currentText)
				if translated ~= currentText then
					(instance :: any).Text = translated
				end
			end)
		end

		-- 监听后续文字修改（防止别人脚本动态改字又变成外语）
		instance:GetPropertyChangedSignal("Text"):Connect(function()
			local newText = (instance :: any).Text
			-- 避免死循环：如果已经是缓存里的中文，就不再翻
			if newText and newText ~= "" and not translationCache[newText] then
				task.spawn(function()
					local translated = translateText(newText)
					if translated ~= newText then
						(instance :: any).Text = translated
					end
				end)
			end
		end)
	end
end

-- 递归绑定容器
local function scanAndHook(parent: Instance)
	for _, child in ipairs(parent:GetDescendants()) do
		hookTextInstance(child)
	end
	
	-- 动态新增的 UI 也自动绑定
	parent.DescendantAdded:Connect(function(child)
		hookTextInstance(child)
	end)
end

-- 监控所有玩家的 PlayerGui 以及 CoreGui (防备外部脚本生成在特殊地方)
local function monitorPlayer(player: Player)
	if player:FindFirstChild("PlayerGui") then
		scanAndHook(player.PlayerGui)
	end
	player.PlayerGuiAdded:Connect(function(playerGui)
		scanAndHook(playerGui)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	monitorPlayer(player)
end
Players.PlayerAdded:Connect(monitorPlayer)

-- 尝试监控 CoreGui（部分外部菜单会把 UI 挂载在这里）
pcall(function()
	scanAndHook(CoreGui)
end)

print("全自动 UI 强制汉化拦截器已启动！")