-- Arceus X 兼容性网络请求适配
local httpRequest = (syn and syn.request) or request or (fluxus and fluxus.request) or http_request
if not httpRequest then
	warn("当前注入器不支持 request")
	return
end

local HttpService = game:GetService("HttpService")

-- 翻译单条文本函数
local function Translate(text)
	if not text or text == "" or #text < 2 then return text end
	-- 过滤纯数字或符号
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
			if result ~= "" then return result end
		end
	end
	return text
end

print("正在开始汉化当前界面...")

-- 遍历 PlayerGui 和 CoreGui 中的所有文字
local function ScanGui(container)
	local count = 0
	for _, obj in ipairs(container:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			if obj.Text and obj.Text ~= "" and not obj:GetAttribute("Localized") then
				obj:SetAttribute("Localized", true)
				local oldText = obj.Text
				local newText = Translate(oldText)
				if newText ~= oldText then
					obj.Text = newText
					count = count + 1
				end
			end
		end
	end
	print("成功汉化文本数量: " .. count)
end

-- 执行扫描
if game.Players.LocalPlayer then
	local pg = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
	if pg then ScanGui(pg) end
end

local coreGui = game:FindFirstChild("CoreGui")
if coreGui then ScanGui(coreGui) end

print("汉化执行完毕！")