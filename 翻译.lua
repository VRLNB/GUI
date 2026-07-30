local httpRequest = (syn and syn.request) or request or (fluxus and fluxus.request) or http_request
if not httpRequest then
	error("当前注入器不支持标准的 HTTP 请求函数！")
end

local HttpService = game:GetService("HttpService")
local GoogleTranslator = {
	Cache = {} -- 本地翻译缓存表，避免重复请求
}

-- 核心翻译函数（带缓存）
function GoogleTranslator.Translate(text)
	if not text or text == "" then return text end
	
	-- 1. 去除首尾空格，检查缓存
	text = text:match("^%s*(.-)%s*$")
	if GoogleTranslator.Cache[text] then
		return GoogleTranslator.Cache[text]
	end
	
	-- 2. 对文本进行 URL 编码
	local encodedText = text:gsub("([^%w%.%-])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	
	local url = string.format("https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=zh-CN&dt=t&q=%s", encodedText)
	
	-- 3. 发送网络请求（使用 pcall 确保不崩脚本）
	local success, response = pcall(function()
		return httpRequest({
			Url = url,
			Method = "GET"
		})
	end)
	
	if success and response and response.StatusCode == 200 then
		local decodeSuccess, data = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)
		
		if decodeSuccess and data and data[1] then
			local result = ""
			for _, v in ipairs(data[1]) do
				if v[1] then
					result = result .. v[1]
				end
			end
			
			if result ~= "" then
				-- 写入缓存
				GoogleTranslator.Cache[text] = result
				return result
			end
		end
	end
	
	-- 失败或超时返回原文，并加入缓存防止反复死请求
	GoogleTranslator.Cache[text] = text
	return text
end

--[[
	异步流式汉化 UI（防卡顿核心）
	@param parentObject 包含文本的 UI 容器（如 ScreenGui）
]]
function GoogleTranslator.TranslateUIAsync(parentObject)
	task.spawn(function()
		local descendants = parentObject:GetDescendants()
		local batchCount = 0
		
		for _, child in ipairs(descendants) do
			if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
				if child.Text and child.Text ~= "" and not GoogleTranslator.Cache[child.Text] then
					local originalText = child.Text
					
					-- 异步单个处理，绝不卡主线程
					task.spawn(function()
						local translated = GoogleTranslator.Translate(originalText)
						if child and child.Parent then
							child.Text = translated
						end
					end)
					
					batchCount = batchCount + 1
					-- 每发起 5 个请求稍微暂停 0.05 秒，防止触发注入器网络流控或客户端瞬间掉帧
					if batchCount % 5 == 0 then
						task.wait(0.05)
					end
				end
			end
		end
	end)
end

return GoogleTranslator