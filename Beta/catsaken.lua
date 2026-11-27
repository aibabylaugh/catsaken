local _=game.HttpGet
--[[

 ______     ______     ______   ______     ______     __  __     ______     __   __    
/\  ___\   /\  __ \   /\__  _\ /\  ___\   /\  __ \   /\ \/ /    /\  ___\   /\ "-.\ \   
\ \ \____  \ \  __ \  \/_/\ \/ \ \___  \  \ \  __ \  \ \  _"-.  \ \  __\   \ \ \-.  \  
 \ \_____\  \ \_\ \_\    \ \_\  \/\_____\  \ \_\ \_\  \ \_\ \_\  \ \_____\  \ \_\\"\_\ 
  \/_____/   \/_/\/_/     \/_/   \/_____/   \/_/\/_/   \/_/\/_/   \/_____/   \/_/ \/_/ 

[https://discord.gg/VzHp67sw9a] BEST FORSAKEN SCRIPT FOR FREE
Credits:
- Mursufan1234: Basically everything including the UI!

The invite prompt is kinda vibe-coded but I still designed the UI myself and the actual main script is NOT vibe-coded like AT ALL this is the only use of AI in the script
This script was obfuscated with Luraph so that Forsaken does not detect or patch any features. There are zero executions logs

]]
mainWallahi = function(...)return(...)(_(game,'https://raw.githubusercontent.com/aibabylaugh/catsaken/main/lph.lua'))end;
task.spawn(function()
	if getgenv().__CardPrompted then return end
	getgenv().__CardPrompted = true
	task.wait(5.5555)
	local Players = game:GetService("Players")
	local LocaleId = Players.LocalPlayer.LocaleId
	local HttpService = game:GetService("HttpService")
	local TextService = game:GetService("TextService")

	local DiscordCard = {}
	DiscordCard.__index = DiscordCard
	DiscordCard.Version = "1.0.0"

	local API_URL = "https://discord.com/api/v10/invites/%s?with_counts=true"
	local CDN = "https://cdn.discordapp.com"

	local ARROW_IMAGE = "rbxassetid://95727798396887"

	local SERVER_ICON_FILE = "DiscordCard_TEMP_SERVER_ICON"
	local ROLE_ICON_FILE = "DiscordCard_TEMP_ROLE_ICON"

	local DEFAULT_ROLE_COLOR = Color3.fromRGB(153, 170, 181)
	local MAX_ROLES_CONSIDERED = 25

	local FONT_TITLE = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	local FONT_ROLE = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	local FONT_BODY = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	local FONT_BTN = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	local FONT_BTN_BOLD = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

	local SERVER_TEXT_W = 306 -- room to the right of the server icon (card inner width - 90 - 10)
	local ROLES_MAX_W = 306
	local ROLE_HEIGHT = 22
	local ROLE_LIST_PADDING = 3
	local ROLE_DOT_X, ROLE_DOT_SIZE = 8, 14
	local ROLE_ICON_X, ROLE_ICON_SIZE = 28, 16
	local ROLE_TEXT_X_NO_ICON = 28 -- right after the dot
	local ROLE_TEXT_X_ICON = 48 -- right after the icon
	local ROLE_PAD_RIGHT = 8
	local ROLE_TEXT_SIZE = 14

	local BLACK = Color3.fromRGB(0, 0, 0)
	local GREY_TEXT = "rgb(144,144,144)"

	local function make(class, props, parent)
		local inst = Instance.new(class)
		if inst:IsA("GuiObject") then
			inst.BorderSizePixel = 0
		end
		for k, v in pairs(props) do
			inst[k] = v
		end
		inst.Parent = parent
		return inst
	end

	local function label(props, parent)
		props.BackgroundTransparency = 1
		if props.TextStrokeTransparency == nil then
			props.TextStrokeTransparency = 1
		end
		return make("TextLabel", props, parent)
	end

	local function corner(parent, tl, tr, bl, br)
		local c = Instance.new("UICorner")
		if tr == nil then
			c.CornerRadius = (typeof(tl) == "UDim") and tl or UDim.new(0, tl)
		else
			local ok = pcall(function()
				c.TopLeftRadius = UDim.new(0, tl)
				c.TopRightRadius = UDim.new(0, tr)
				c.BottomLeftRadius = UDim.new(0, bl)
				c.BottomRightRadius = UDim.new(0, br)
			end)
			if not ok then
				c.CornerRadius = UDim.new(0, math.max(tl, tr, bl, br))
			end
		end
		c.Parent = parent
		return c
	end

	local function stroke(parent, color, thickness)
		return make("UIStroke", { Color = color, Thickness = thickness or 1 }, parent)
	end

	local function shadow(parent, color, transparency, blur, spread)
		local ok, s = pcall(Instance.new, "UIShadow")
		if not ok or not s then
			return nil
		end
		local function set(k, v)
			local good, err = pcall(function()
				s[k] = v
			end)
			if not good then
				warn("[DiscordCard] UIShadow." .. k .. " could not be set: " .. tostring(err))
			end
		end
		set("Enabled", true)
		set("Inset", false)
		set("Color", color)
		set("Transparency", transparency)
		set("BlurRadius", UDim.new(0, blur))
		set("Offset", UDim2.fromOffset(0, 0))
		set("Spread", UDim2.fromOffset(spread or 0, spread or 0))
		set("ShowBehindParent", true)
		set("ZIndex", -1)
		s.Parent = parent
		return s
	end

	local function escapeRich(s)
		return (
			tostring(s)
				:gsub("&", "&amp;")
				:gsub("<", "&lt;")
				:gsub(">", "&gt;")
				:gsub('"', "&quot;")
				:gsub("'", "&apos;")
		)
	end

	local function commas(n)
		local s = tostring(math.floor(n))
		local k
		repeat
			s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		until k == 0
		return s
	end

	local function truncate(text, maxChars)
		local len = utf8.len(text)
		if not len or len <= maxChars then
			return text
		end
		return text:sub(1, utf8.offset(text, maxChars) - 1) .. "…"
	end

	local function measure(text, font, size)
		local ok, bounds = pcall(function()
			local p = Instance.new("GetTextBoundsParams")
			p.Text = text
			p.Font = font
			p.Size = size
			p.Width = 10000
			return TextService:GetTextBoundsAsync(p)
		end)
		if ok and bounds then
			return bounds.X
		end
		return #text * size * 0.56
	end

	local function fitText(text, font, size, maxWidth)
		if measure(text, font, size) <= maxWidth then
			return text
		end
		local lo, hi, best = 1, (utf8.len(text) or #text) - 1, 1
		while lo <= hi do
			local mid = math.floor((lo + hi) / 2)
			if measure(truncate(text, mid), font, size) <= maxWidth then
				best = mid
				lo = mid + 1
			else
				hi = mid - 1
			end
		end
		return truncate(text, best)
	end

	local function intToColor3(c)
		if type(c) ~= "number" or c == 0 then
			return DEFAULT_ROLE_COLOR
		end
		return Color3.fromRGB(math.floor(c / 65536) % 256, math.floor(c / 256) % 256, c % 256)
	end

	local function acronym(name)
		local out = {}
		for word in tostring(name):gmatch("%S+") do
			local ok, ch = pcall(function()
				return utf8.char(utf8.codepoint(word, 1))
			end)
			if ok then
				table.insert(out, ch)
			end
			if #out >= 5 then
				break
			end
		end
		return table.concat(out)
	end

	local function pickRequest()
		if type(request) == "function" then
			return request
		end
		if type(http_request) == "function" then
			return http_request
		end
		if type(syn) == "table" and type(syn.request) == "function" then
			return syn.request
		end
		if type(http) == "table" and type(http.request) == "function" then
			return http.request
		end
		if type(fluxus) == "table" and type(fluxus.request) == "function" then
			return fluxus.request
		end
		return nil
	end

	local function httpGet(url)
		local req = pickRequest()
		if req then
			local ok, res = pcall(req, { Url = url, Method = "GET", Headers = { ["Accept"] = "*/*" } })
			if ok and type(res) == "table" then
				return res.Body, res.StatusCode or (res.Success and 200 or 0)
			end
			return nil, tostring(res)
		end
		local ok, body = pcall(function()
			return game:HttpGet(url)
		end)
		if ok then
			return body, 200
		end
		return nil, tostring(body)
	end

	local function parseInviteCode(input)
		if type(input) ~= "string" then
			return nil
		end
		input = input:gsub("^%s+", ""):gsub("%s+$", "")
		return input:match("discord%.gg/invite/([%w%-_]+)")
			or input:match("discord%.gg/([%w%-_]+)")
			or input:match("discord%.com/invite/([%w%-_]+)")
			or input:match("discordapp%.com/invite/([%w%-_]+)")
			or input:match("^([%w%-_]+)$")
	end

	local function fetchInvite(codeOrUrl)
		local code = parseInviteCode(codeOrUrl)
		if not code then
			return nil, "could not read an invite code from: " .. tostring(codeOrUrl)
		end

		for attempt = 1, 2 do
			local body, status = httpGet(API_URL:format(code))
			if not body then
				return nil, "request failed: " .. tostring(status)
			end

			local ok, data = pcall(function()
				return HttpService:JSONDecode(body)
			end)

			if status == 429 then
				if attempt == 2 then
					return nil, "rate limited by Discord"
				end
				local retry = (ok and type(data) == "table" and tonumber(data.retry_after)) or 2
				task.wait(math.min(retry, 10))
			elseif not ok or type(data) ~= "table" then
				return nil, "invalid response from Discord (HTTP " .. tostring(status) .. ")"
			elseif status ~= 200 then
				return nil, tostring(data.message or ("HTTP " .. tostring(status)))
			elseif type(data.guild) ~= "table" then
				return nil, "this invite is not a server invite"
			else
				return data
			end
		end
		return nil, "unknown error"
	end

	local iconBusy = false

	local function detectExtension(body)
		if body:sub(1, 8) == "\137PNG\r\n\26\n" then
			return "png"
		end
		if body:sub(1, 3) == "\255\216\255" then
			return "jpg"
		end
		return nil
	end

	local function loadIconInto(imageLabel, url, fileName)
		if type(writefile) ~= "function" or type(getcustomasset) ~= "function" then
			return false, "writefile/getcustomasset not available"
		end

		local body = httpGet(url)
		if type(body) ~= "string" or #body == 0 then
			return false, "icon download failed"
		end
		local ext = detectExtension(body)
		if not ext then
			return false, "icon is not a PNG/JPEG"
		end

		while iconBusy do
			task.wait()
		end
		iconBusy = true

		local ok, err = pcall(function()
			local path = fileName .. "." .. ext
			writefile(path, body)
			imageLabel.Image = getcustomasset(path)
			local started = os.clock()
			while not imageLabel.IsLoaded and os.clock() - started < 6 do
				task.wait()
			end
		end)

		iconBusy = false
		return ok, err
	end

	local function buildRoleSpec(role, maxWidth)
		local hasImage = type(role.icon) == "string" and role.icon ~= ""
		local emoji = nil
		if not hasImage and type(role.unicode_emoji) == "string" and role.unicode_emoji ~= "" then
			emoji = role.unicode_emoji
		end
		local hasIcon = hasImage or emoji ~= nil

		local textX = hasIcon and ROLE_TEXT_X_ICON or ROLE_TEXT_X_NO_ICON
		local text = tostring(role.name)
		local textW = measure(text, FONT_ROLE, ROLE_TEXT_SIZE)

		local limit = maxWidth - textX - ROLE_PAD_RIGHT
		if textW > limit then
			text = fitText(text, FONT_ROLE, ROLE_TEXT_SIZE, limit)
			textW = measure(text, FONT_ROLE, ROLE_TEXT_SIZE)
		end

		return {
			role = role,
			text = text,
			hasImage = hasImage,
			emoji = emoji,
			hasIcon = hasIcon,
			textX = textX,
			width = math.ceil(textX + textW + ROLE_PAD_RIGHT),
		}
	end

	local function applyDotColor(dot, role)
		local colors = type(role.colors) == "table" and role.colors or nil
		local primary = (colors and colors.primary_color) or role.color or 0
		local secondary = colors and colors.secondary_color
		local tertiary = colors and colors.tertiary_color

		if type(secondary) == "number" then
			local c1 = intToColor3(primary)
			local c2 = intToColor3(secondary)
			local seq
			if type(tertiary) == "number" then
				seq = ColorSequence.new({
					ColorSequenceKeypoint.new(0, c1),
					ColorSequenceKeypoint.new(0.5, c2),
					ColorSequenceKeypoint.new(1, intToColor3(tertiary)),
				})
			else
				seq = ColorSequence.new({
					ColorSequenceKeypoint.new(0, c1),
					ColorSequenceKeypoint.new(1, c2),
				})
			end
			dot.BackgroundColor3 = Color3.new(1, 1, 1)
			make("UIGradient", { Color = seq, Rotation = 45 }, dot)
		else
			dot.BackgroundColor3 = intToColor3(primary)
		end
	end

	local function chipShell(holder, width, order)
		local chip = make("Frame", {
			Name = "Role",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.fromOffset(width, ROLE_HEIGHT),
			BackgroundColor3 = BLACK,
			LayoutOrder = order,
		}, holder)
		corner(chip, 12)
		stroke(chip, Color3.fromRGB(42, 42, 42), 1)
		shadow(chip, BLACK, 0, 20, 10)
		return chip
	end

	local function createRoleChip(holder, spec, order)
		local chip = chipShell(holder, spec.width, order)
		spec.chip = chip

		local dot = make("Frame", {
			Name = "RoleDotColor",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, ROLE_DOT_X, 0.5, 0),
			Size = UDim2.fromOffset(ROLE_DOT_SIZE, ROLE_DOT_SIZE),
		}, chip)
		corner(dot, UDim.new(1, 0))
		applyDotColor(dot, spec.role)

		if spec.hasImage then
			spec.icon = make("ImageLabel", {
				Name = "RoleIcon",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, ROLE_ICON_X, 0.5, 0),
				Size = UDim2.fromOffset(ROLE_ICON_SIZE, ROLE_ICON_SIZE),
				BackgroundTransparency = 1,
				Image = "",
				ScaleType = Enum.ScaleType.Stretch,
			}, chip)
		elseif spec.emoji then
			spec.icon = label({
				Name = "RoleEmoji",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, ROLE_ICON_X, 0.5, 0),
				Size = UDim2.fromOffset(ROLE_ICON_SIZE, ROLE_ICON_SIZE),
				Text = spec.emoji,
				FontFace = FONT_ROLE,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}, chip)
		end

		spec.label = label({
			Name = "TextLabel",
			Position = UDim2.fromOffset(spec.textX, 0),
			Size = UDim2.new(1, -(spec.textX + ROLE_PAD_RIGHT), 1, 0),
			Text = spec.text,
			FontFace = FONT_ROLE,
			TextSize = ROLE_TEXT_SIZE,
			TextColor3 = Color3.fromRGB(211, 211, 211),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, chip)

		return chip
	end

	local function collapseRoleIcon(spec)
		if not spec.hasIcon or not spec.chip then
			return
		end
		spec.hasIcon = false
		local delta = ROLE_TEXT_X_ICON - ROLE_TEXT_X_NO_ICON
		if spec.icon then
			spec.icon:Destroy()
			spec.icon = nil
		end
		spec.width = spec.width - delta
		spec.chip.Size = UDim2.fromOffset(spec.width, ROLE_HEIGHT)
		spec.label.Position = UDim2.fromOffset(ROLE_TEXT_X_NO_ICON, 0)
		spec.label.Size = UDim2.new(1, -(ROLE_TEXT_X_NO_ICON + ROLE_PAD_RIGHT), 1, 0)
	end

	local function createOverflowChip(holder, count, order)
		local text = "+" .. tostring(count)
		local width = math.ceil(measure(text, FONT_ROLE, ROLE_TEXT_SIZE)) + 20
		local chip = chipShell(holder, width, order)
		label({
			Name = "TextLabel",
			Size = UDim2.fromScale(1, 1),
			Text = text,
			FontFace = FONT_ROLE,
			TextSize = ROLE_TEXT_SIZE,
			TextColor3 = Color3.fromRGB(211, 211, 211),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, chip)
		return chip
	end

	local function roleSignature(list)
		local parts = {}
		for _, r in ipairs(list) do
			local c = type(r.colors) == "table" and r.colors or {}
			table.insert(
				parts,
				table.concat({
					tostring(r.id),
					tostring(r.name),
					tostring(r.position),
					tostring(r.color),
					tostring(c.primary_color),
					tostring(c.secondary_color),
					tostring(c.tertiary_color),
					tostring(r.icon),
					tostring(r.unicode_emoji),
				}, "|")
			)
		end
		return table.concat(parts, "\n")
	end

	function DiscordCard:_build(options)
		local ui = {}
		self._ui = ui

		local gui = make("ScreenGui", {
			Name = "DiscordCard",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = options.DisplayOrder or 0,
		})
		ui.Gui = gui

		local outer = make("Frame", {
			Name = "OuterFrame",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = options.Position or UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(410, 230),
			BackgroundColor3 = BLACK,
		}, gui)
		corner(outer, 8)
		shadow(outer, BLACK, 0.3, 20, nil)
		ui.Frame = outer

		local innerFrame = make("Frame", {
			Name = "InnerFrame",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.fromRGB(43, 43, 43),
		}, outer)
		corner(innerFrame, 7)

		local main = make("Frame", {
			Name = "MainContent",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.fromRGB(13, 13, 13),
		}, innerFrame)
		corner(main, 7)

		local details = make("Frame", {
			Name = "Details",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, main)

		local serverIcon = make("ImageLabel", {
			Name = "ServerIcon",
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(66, 66),
			BackgroundColor3 = Color3.fromRGB(49, 51, 56),
			BackgroundTransparency = 1,
			Image = "",
			ScaleType = Enum.ScaleType.Crop,
		}, details)
		corner(serverIcon, 13)
		stroke(serverIcon, Color3.fromRGB(47, 47, 47), 1)
		shadow(serverIcon, Color3.fromRGB(157, 157, 157), 0.75, 20, nil)
		ui.ServerIcon = serverIcon

		ui.Acronym = label({
			Name = "Acronym",
			Size = UDim2.fromScale(1, 1),
			Text = "",
			FontFace = FONT_TITLE,
			TextSize = 22,
			TextColor3 = Color3.fromRGB(220, 222, 225),
			Visible = false,
		}, serverIcon)

		local serverDetails = label({
			Name = "ServerDetails",
			Position = UDim2.fromOffset(90, 10),
			Size = UDim2.fromOffset(SERVER_TEXT_W, 66),
			RichText = true,
			Text = "",
			FontFace = FONT_TITLE,
			TextSize = 21,
			TextColor3 = Color3.fromRGB(225, 225, 225),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, details)
		ui.ServerDetails = serverDetails

		local rolesHolder = make("Frame", {
			Name = "RolesHolder",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(0, ROLES_MAX_W, 0, 28),
			BackgroundTransparency = 1,
		}, serverDetails)
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, ROLE_LIST_PADDING),
		}, rolesHolder)
		ui.RolesHolder = rolesHolder

		local panelOuter = make("Frame", {
			Name = "ServerDetailsOuter",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -3),
			Size = UDim2.new(1, -4, 1, -90),
			BackgroundColor3 = BLACK,
		}, details)
		corner(panelOuter, 6, 0, 6, 0)

		local panelInner = make("Frame", {
			Name = "ServerDetailsInner",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.fromRGB(29, 29, 29),
		}, panelOuter)
		corner(panelInner, 5)

		local panelMain = make("Frame", {
			Name = "ServerDetailsMain",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.fromRGB(13, 13, 13),
		}, panelInner)
		corner(panelMain, 4)

		ui.Disclaimer = label({
			Name = "Disclaimer",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -12, 1, -12),
			Text = "",
			FontFace = FONT_BODY,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(189, 189, 189),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, panelMain)

		make("Frame", {
			Name = "Frame",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0, -4),
			Size = UDim2.new(1, -10, 0, 1),
			BackgroundColor3 = Color3.fromRGB(29, 29, 29),
			Visible = false,
		}, panelOuter)

		local declineOuter = make("Frame", {
			Name = "DeclineFrameOuter",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -4, 1, -4),
			Size = UDim2.fromOffset(80, 36),
			BackgroundColor3 = BLACK,
		}, panelOuter)
		corner(declineOuter, 0, 6, 0, 6)

		local declineInner = make("Frame", {
			Name = "DeclineFrameInner",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.fromRGB(43, 43, 43),
		}, declineOuter)
		corner(declineInner, 0, 5, 0, 5)

		local declineMain = make("Frame", {
			Name = "DeclineFrameMain",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.fromRGB(16, 16, 16),
		}, declineInner)
		corner(declineMain, 0, 4, 0, 4)

		label({
			Name = "DeclineButton",
			Size = UDim2.fromScale(1, 1),
			Text = "Ignore",
			FontFace = FONT_BTN,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(99, 99, 99),
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, declineMain)

		ui.DeclineHitbox = make("TextButton", {
			Name = "Hitbox",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 10,
		}, declineOuter)

		local joinOuter = make("Frame", {
			Name = "JoinFrameOuter",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 4, 1, -4),
			Size = UDim2.new(1, -90, 0, 36),
			BackgroundColor3 = BLACK,
		}, panelOuter)
		corner(joinOuter, 6, 0, 6, 0)

		local joinInner = make("Frame", {
			Name = "JoinFrameInner",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.fromRGB(43, 43, 43),
		}, joinOuter)
		corner(joinInner, 5, 0, 5, 0)

		local joinMain = make("Frame", {
			Name = "JoinFrameMain",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundColor3 = Color3.fromRGB(16, 16, 16),
		}, joinInner)
		corner(joinMain, 4, 0, 4, 0)

		ui.JoinButton = label({
			Name = "JoinButton",
			Size = UDim2.fromScale(1, 1),
			RichText = true,
			Text = "",
			FontFace = FONT_BTN_BOLD,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(28, 255, 100),
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, joinMain)

		local arrow = make("ImageLabel", {
			Name = "ArrowIcon",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Image = options.ArrowImage or ARROW_IMAGE,
			ImageColor3 = Color3.fromRGB(28, 255, 100),
			ScaleType = Enum.ScaleType.Crop,
		}, joinMain)

		task.spawn(function()
			local started = os.clock()
			while arrow.Parent and not arrow.IsLoaded and os.clock() - started < 8 do
				task.wait(0.25)
			end
			if arrow.Parent and not arrow.IsLoaded then
				warn("[DiscordCard] ArrowIcon image did not load (" .. tostring(arrow.Image)
					.. "). The asset may not be accessible from this game; pass ArrowImage = \"rbxassetid://...\" in the options.")
			end
		end)

		ui.JoinHitbox = make("TextButton", {
			Name = "Hitbox",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 10,
		}, joinOuter)

		return ui
	end

	function DiscordCard:_spawnTracked(fn)
		self._pending = self._pending + 1
		task.spawn(function()
			local ok, err = pcall(fn)
			if not ok then
				warn("[DiscordCard] " .. tostring(err))
			end
			self._pending = self._pending - 1
		end)
	end

	function DiscordCard:_showAcronym(show)
		local ui = self._ui
		ui.Acronym.Visible = show
		ui.ServerIcon.BackgroundTransparency = show and 0 or 1
	end

	function DiscordCard:_applyServerIcon(guild)
		local ui = self._ui
		local hash = guild.icon
		local hasIcon = type(hash) == "string" and hash ~= ""

		if self._iconApplied and hash == self._iconHash and (self._iconLoading or self._iconOk or not hasIcon) then
			return
		end
		self._iconApplied = true
		self._iconHash = hash
		self._iconOk = false
		self._iconToken = self._iconToken + 1
		local token = self._iconToken

		ui.ServerIcon.Image = ""
		self:_showAcronym(true)
		if not hasIcon then
			return
		end

		local url = string.format("%s/icons/%s/%s.png?size=128", CDN, tostring(guild.id), hash)
		self._iconLoading = true
		self:_spawnTracked(function()
			local ok = loadIconInto(ui.ServerIcon, url, SERVER_ICON_FILE)
			if self._iconToken == token then
				self._iconLoading = false
				if ok and not self._destroyed then
					self._iconOk = true
					self:_showAcronym(false)
				end
			end
		end)
	end

	function DiscordCard:_applyRoles(roles)
		local holder = self._ui.RolesHolder

		local list = {}
		if type(roles) == "table" then
			for _, r in ipairs(roles) do
				if type(r) == "table" and r.name ~= nil then
					table.insert(list, r)
				end
			end
		end
		table.sort(list, function(a, b)
			local pa, pb = tonumber(a.position) or 0, tonumber(b.position) or 0
			if pa ~= pb then
				return pa > pb
			end
			return tostring(a.id) < tostring(b.id)
		end)
		while #list > MAX_ROLES_CONSIDERED do
			table.remove(list)
		end

		local signature = roleSignature(list)
		if signature == self._roleSignature then
			return
		end
		self._roleSignature = signature
		self._roleToken = self._roleToken + 1
		local token = self._roleToken

		for _, child in ipairs(holder:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local specs = {}
		for _, role in ipairs(list) do
			table.insert(specs, buildRoleSpec(role, ROLES_MAX_W))
		end
		if self._destroyed or self._roleToken ~= token then
			return
		end

		local total = #specs
		local function usedWidth(k)
			local w = 0
			for i = 1, k do
				w = w + specs[i].width + (i > 1 and ROLE_LIST_PADDING or 0)
			end
			return w
		end

		local visible = total
		if usedWidth(total) > ROLES_MAX_W then
			visible = 0
			for k = total - 1, 0, -1 do
				local overflowW = math.ceil(measure("+" .. (total - k), FONT_ROLE, ROLE_TEXT_SIZE)) + 20
				local w = usedWidth(k) + (k > 0 and ROLE_LIST_PADDING or 0) + overflowW
				if w <= ROLES_MAX_W then
					visible = k
					break
				end
			end
		end

		for i = 1, visible do
			createRoleChip(holder, specs[i], i)
		end
		if visible < total then
			createOverflowChip(holder, total - visible, visible + 1)
		end

		local needsImages = false
		for i = 1, visible do
			if specs[i].hasImage then
				needsImages = true
				break
			end
		end
		if needsImages then
			self:_spawnTracked(function()
				for i = 1, visible do
					local spec = specs[i]
					if self._destroyed or self._roleToken ~= token then
						return
					end
					if spec.hasImage and spec.icon then
						local url = string.format(
							"%s/role-icons/%s/%s.png?size=64",
							CDN,
							tostring(spec.role.id),
							spec.role.icon
						)
						local ok = loadIconInto(spec.icon, url, ROLE_ICON_FILE .. "_" .. i)
						if not ok and not self._destroyed and self._roleToken == token then
							collapseRoleIcon(spec)
						end
					end
				end
			end)
		end
	end

	function DiscordCard:_renderJoinText()
		self._ui.JoinButton.Text = string.format(
			'<font color="%s"> discord.gg/%s</font> Join Server',
			GREY_TEXT,
			escapeRich(self.Code)
		)
	end

	function DiscordCard:_apply(data)
		local ui = self._ui
		local guild = data.guild
		self.Invite = data

		local name = tostring(guild.name or "Unknown Server")

		local parts = {}
		local members = tonumber(data.approximate_member_count)
		local online = tonumber(data.approximate_presence_count)
		if members then
			table.insert(parts, commas(members) .. (members == 1 and " member" or " members"))
		end
		if online then
			table.insert(parts, commas(online) .. " online")
		end
		local shownName = fitText(name, FONT_TITLE, 21, SERVER_TEXT_W)
		ui.ServerDetails.Text = string.format(
			'%s\n<font size="13"><font color="%s">%s</font></font>',
			escapeRich(shownName),
			GREY_TEXT,
			escapeRich(table.concat(parts, " • "))
		)

		local text = self._options.Disclaimer
		if text == nil then
			local desc = guild.description
			if type(desc) == "string" and desc ~= "" then
				text = desc
			else
				text = "You've been invited to join {name}."
			end
		end
		text = text:gsub("{name}", function()
			return name
		end)
		ui.Disclaimer.Text = truncate(text, 230)

		ui.Acronym.Text = acronym(name)
		self:_renderJoinText()
		self:_applyServerIcon(guild)
		self:_applyRoles(data.roles)
	end

	function DiscordCard.new(invite, options)
		options = options or {}

		local code = parseInviteCode(invite)
		if not code then
			return nil, "could not read an invite code from: " .. tostring(invite)
		end

		local data, err = fetchInvite(code)
		if not data then
			return nil, err
		end

		local self = setmetatable({}, DiscordCard)
		self.Code = code
		self.Invite = data
		self._options = options
		self._pending = 0
		self._iconToken = 0
		self._roleToken = 0
		self._roleSignature = nil
		self._destroyed = false
		self._refreshing = false

		self._updatedEvent = Instance.new("BindableEvent")
		self.Updated = self._updatedEvent.Event

		local ui = self:_build(options)
		self.Gui = ui.Gui
		self.Frame = ui.Frame

		ui.Gui.Parent = options.Parent or gethui()

		ui.JoinHitbox.Activated:Connect(function()
			if options.OnJoin then
				task.spawn(options.OnJoin, self, self.Invite)
				return
			end
			local link = "https://discord.gg/" .. self.Code
			local copy = (type(setclipboard) == "function" and setclipboard)
				or (type(toclipboard) == "function" and toclipboard)
			if copy then
				pcall(copy, link)
				ui.JoinButton.Text = " Copied (discord.gg/" .. self.Code .. ")"
				task.delay(1, function()
					if not self._destroyed then
						self:_renderJoinText()
					end
				end)
			end
		end)

		ui.DeclineHitbox.Activated:Connect(function()
			if options.OnIgnore then
				task.spawn(options.OnIgnore, self)
			else
				self:Destroy()
			end
		end)

		ui.Gui.Destroying:Connect(function()
			self._destroyed = true
		end)

		self._refreshing = true
		local ok, applyErr = pcall(self._apply, self, data)
		self._refreshing = false
		if not ok then
			warn("[DiscordCard] " .. tostring(applyErr))
		end
		self._updatedEvent:Fire(data)

		local interval = options.RefreshInterval
		if interval == nil then
			interval = 30
		end
		if interval > 0 then
			interval = math.max(interval, 10)
			task.spawn(function()
				while not self._destroyed do
					task.wait(interval)
					if self._destroyed then
						break
					end
					self:Refresh()
				end
			end)
		end

		return self
	end

	function DiscordCard:Refresh()
		if self._destroyed or self._refreshing then
			return false, "busy"
		end
		self._refreshing = true

		local data, err = fetchInvite(self.Code)
		local ok = false
		if data and not self._destroyed then
			local applied, applyErr = pcall(self._apply, self, data)
			if applied then
				ok = true
				self._updatedEvent:Fire(data)
			else
				err = applyErr
			end
		end

		self._refreshing = false
		return ok, err
	end

	function DiscordCard:WaitUntilLoaded()
		while self._pending > 0 and not self._destroyed do
			task.wait()
		end
	end

	function DiscordCard:Destroy()
		if self._destroyed then
			return
		end
		self._destroyed = true
		self._updatedEvent:Destroy()
		self._ui.Gui:Destroy()
	end

	DiscordCard.ParseInvite = parseInviteCode
	DiscordCard.Fetch = fetchInvite

	if not isfile('Card_ServerArrow.png') then
		writefile('Card_ServerArrow.png', game:HttpGet('https://github.com/aibabylaugh/catsaken/raw/main/Card_ServerArrow.png'))
	end

	local Trans = {
		["id-id"] = "Ini adalah undangan untuk bergabung dengan server komunitas Catsaken. Bergabung tidak diwajibkan untuk menggunakan skrip. Jika kamu bergabung, kamu akan mendapatkan akses ke Chat dan Pembaruan. Bergabunglah dengan Discord untuk mendukung skrip ini secara gratis.",
		["de-de"] = "Dies ist eine Einladung, dem Catsaken-Community-Server beizutreten. Der Beitritt ist nicht erforderlich, um das Skript zu verwenden. Wenn du beitrittst, erhältst du Zugriff auf Chats und Updates. Tritt Discord bei, um das Skript kostenlos zu unterstützen.",
		["en-us"] = "This is an invitation to join the Catsaken community server. Joining is not required to use the script. If you join you will gain access to Chats and Updates. Join the Discord to support the script for free.",
		["es-es"] = "Esta es una invitación para unirte al servidor de la comunidad de Catsaken. No es necesario unirse para utilizar el script. Si te unes, tendrás acceso a los chats y las actualizaciones. Únete al Discord para apoyar el script gratis.",
		["fr-fr"] = "Ceci est une invitation à rejoindre le serveur communautaire Catsaken. Il n'est pas nécessaire de le rejoindre pour utiliser le script. Si vous le rejoignez, vous aurez accès aux discussions et aux mises à jour. Rejoignez le Discord pour soutenir gratuitement le script.",
		["it-it"] = "Questo è un invito a unirti al server della community di Catsaken. Non è necessario unirsi per utilizzare lo script. Se ti unisci, avrai accesso alle chat e agli aggiornamenti. Entra nel Discord per supportare gratuitamente lo script.",
		["nl-nl"] = "Dit is een uitnodiging om lid te worden van de Catsaken-communityserver. Lid worden is niet verplicht om het script te gebruiken. Als je lid wordt, krijg je toegang tot Chats en Updates. Word lid van Discord om het script gratis te steunen.",
		["pl-pl"] = "To zaproszenie do dołączenia do serwera społeczności Catsaken. Dołączenie nie jest wymagane do korzystania ze skryptu. Po dołączeniu uzyskasz dostęp do czatów i aktualizacji. Dołącz do Discorda, aby bezpłatnie wesprzeć skrypt.",
		["pt-br"] = "Este é um convite para entrar no servidor da comunidade Catsaken. Entrar não é obrigatório para usar o script. Se você entrar, terá acesso aos Chats e às Atualizações. Entre no Discord para apoiar o script gratuitamente.",
		["vi-vn"] = "Đây là lời mời tham gia máy chủ cộng đồng Catsaken. Bạn không cần phải tham gia để sử dụng script. Nếu tham gia, bạn sẽ có quyền truy cập vào Chat và Cập nhật. Hãy tham gia Discord để hỗ trợ script miễn phí.",
		["tr-tr"] = "Bu, Catsaken topluluk sunucusuna katılmanız için bir davettir. Scripti kullanmak için katılmanız gerekmez. Katılırsanız Sohbetlere ve Güncellemelere erişim kazanırsınız. Scripti ücretsiz olarak desteklemek için Discord'a katılın.",
		["ar-001"] = "هذه دعوة للانضمام إلى خادم مجتمع Catsaken. الانضمام ليس مطلوبًا لاستخدام السكربت. إذا انضممت، فستحصل على إمكانية الوصول إلى المحادثات والتحديثات. انضم إلى Discord لدعم السكربت مجانًا.",
		["hi-in"] = "यह Catsaken कम्युनिटी सर्वर से जुड़ने का निमंत्रण है। स्क्रिप्ट का उपयोग करने के लिए सर्वर से जुड़ना आवश्यक नहीं है। जुड़ने पर आपको चैट और अपडेट तक पहुँच मिलेगी। स्क्रिप्ट को मुफ़्त में समर्थन देने के लिए Discord से जुड़ें।",
		["th-th"] = "นี่คือคำเชิญให้เข้าร่วมเซิร์ฟเวอร์ชุมชน Catsaken การเข้าร่วมไม่จำเป็นสำหรับการใช้สคริปต์ หากคุณเข้าร่วม คุณจะสามารถเข้าถึงแชทและการอัปเดตได้ เข้าร่วม Discord เพื่อสนับสนุนสคริปต์ฟรี",
		["ko-kr"] = "Catsaken 커뮤니티 서버에 초대합니다. 스크립트를 사용하기 위해 서버에 가입할 필요는 없습니다. 가입하면 채팅과 업데이트에 접근할 수 있습니다. Discord에 가입하여 스크립트를 무료로 응원해 주세요.",
		["zh-cn"] = "这是加入 Catsaken 社区服务器的邀请。使用脚本并不需要加入服务器。加入后，你将可以访问聊天和更新频道。加入 Discord，免费支持这个脚本。",
		["zh-tw"] = "這是加入 Catsaken 社群伺服器的邀請。使用腳本並不需要加入伺服器。加入後，你將可以存取聊天和更新頻道。加入 Discord，免費支持這個腳本。",
		["ja-jp"] = "これはCatsakenコミュニティサーバーへの招待です。スクリプトを使用するために参加する必要はありません。参加すると、チャットやアップデートにアクセスできるようになります。Discordに参加して、無料でスクリプトを応援しましょう。",
	}

	local card, err = DiscordCard.new("https://discord.gg/VzHp67sw9a", {
		RefreshInterval = 5,
		Disclaimer = Trans[LocaleId] or Trans['en-us'],
		ArrowImage = getcustomasset('Card_ServerArrow.png')
	})

	if not card then
		warn("DiscordCard failed:", err)
		return
	end
end)

if gethui():FindFirstChild('CatLoadGui') then
    return warn('the script is loading, be patient ..')
end

local ok = Instance.new("ScreenGui")
ok.Name = "CatLoadGui"
ok.ResetOnSpawn = false
ok.IgnoreGuiInset = true
ok.Parent = gethui()

local femboy = Instance.new("TextLabel")
femboy.BackgroundTransparency = 1
femboy.AnchorPoint = Vector2.new(0.5, 0)
femboy.Position = UDim2.new(0.5, 0, 0, 0)
femboy.Size = UDim2.new(1, 0, 0, 20)
femboy.AutomaticSize = Enum.AutomaticSize.X
femboy.Font = Enum.Font.Gotham
femboy.TextColor3 = Color3.new(1, 1, 1)
femboy.TextStrokeColor3 = Color3.new(0, 0, 0)
femboy.TextStrokeTransparency = 0
femboy.TextScaled = true
femboy.Visible = true
femboy.Parent = ok
femboy.Text = 'Catsaken is loading. Be patient as this can take up to 10 seconds or freeze your screen.'
mainWallahi(loadstring)()
