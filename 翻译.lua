-- 1. 基础环境检测与提示
local httpRequest = (syn and syn.request) or request or (fluxus and fluxus.request) or http_request
if not httpRequest then
	game.StarterGui:SetCore("SendNotification", {
		Title = "翻译脚本报错",
		Text = "当前注入器不支持 request 函数！",
		Duration = 5
	})
	return
end

game.StarterGui:SetCore("SendNotification", {
	Title = "翻译工具",
	Text = "脚本已成功注入，开始全局暴力汉化...",
	Duration = 3
})

local HttpService = game:GetService("HttpService")

-- 2. 核心翻译函数（直连 Google 接口）
local function TranslateText(text)
	if not text or text == "" or #text < 2 then return text end
	-- 过滤纯数字或特殊符号
	if text:match("^[%d%p%s]+$") then return text end
	
	local encoded = text:gsub("([^%w%.%-])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	
	local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=zh-CN&dt=t&q=" .. encoded
	
	local success, res = pcall(function()
		return httpRequest({ Url = url, Method = "GET" })
	end)
	
	if success and res and res.StatusCode == 200 then
		local decSuccess, data = pcall(function()
			return HttpService:JSONDecode(res.Body)
		end)
		if decSuccess and data and data[1] then
			local result = ""
			for _, v in ipairs(data[1]) do
				if v[1] then result = result .. v[1] end
			end
			if result ~= "" then
				print("成功翻译: " .. text .. " -> " .. result)
				return result
			end
		end
	end
	return text
end

-- 3. 全局扫描整个游戏里的所有界面（同时遍历 CoreGui 和 PlayerGui）
local function ScanAndTranslate(root)
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			-- 如果有文字且没被汉化过
			if obj.Text and obj.Text ~= "" and not obj:GetAttribute("Translated") then
				obj:SetAttribute("Translated", true) -- 标记为已处理，防止重复请求
				local original = obj.Text
				
				task.spawn(function()
					local translated = TranslateText(original)
					if obj and obj.Parent then
						obj.Text = translated
					end
				end)
			end
		end
	end
end

-- 立即执行一次扫描
ScanAndTranslate(game:GetService("CoreGui"))
if game.Players.LocalPlayer then
	ScanAndTranslate(game.Players.LocalPlayer:WaitForChild("PlayerGui", 2))
end

-- 4. 监听后续动态生成的 UI（防止有些脚本是执行后几秒才弹出的）
game:GetService("CoreGui").DescendantAdded:Connect(function(obj)
	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		task.wait(0.2) -- 等待文本初始化
		if obj.Text and obj.Text ~= "" and not obj:GetAttribute("Translated") then
			obj:SetAttribute("Translated", true)
			local original = obj.Text
			task.spawn(function()
				obj.Text = TranslateText(original)
			end)
		end
	end
end)

print("【汉化接口】已全方位挂载成功！")