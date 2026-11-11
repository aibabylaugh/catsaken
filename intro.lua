if (not isfile('catsakenwoman.png')) then
    writefile("catsakenwoman.png", game:HttpGet("https://github.com/aibabylaugh/catsaken/raw/main/woman.png"))
end

local TweenService = game:GetService("TweenService")

local blur = Instance.new("BlurEffect", game:GetService("Lighting"))
blur.Size = 0

local loadgui = Instance.new("ScreenGui", gethui())
loadgui.ResetOnSpawn = false

local container = Instance.new("Frame", loadgui)
container.Size = UDim2.new(0, 600, 0, 100)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1

local img = Instance.new("ImageLabel", container)
img.Size = UDim2.new(0, 100, 0, 100)
img.Position = UDim2.new(0, 250, 0, 0)
img.AnchorPoint = Vector2.new(0, 0)
img.BackgroundTransparency = 1
img.Image = getcustomasset("catsakenwoman.png")
img.ImageTransparency = 1

local text = Instance.new("TextLabel", container)
text.Text = "CATSAKEN REMASTERED"
text.Font = Enum.Font.LuckiestGuy
text.Size = UDim2.new(0, 0, 0, 100)
text.Position = UDim2.new(0, 350, 0, 0)
text.TextSize = 40
text.TextColor3 = Color3.fromRGB(0, 0, 0)
text.TextXAlignment = Enum.TextXAlignment.Left
text.BackgroundTransparency = 1
text.ClipsDescendants = true

local gold = Color3.fromHex("F59F27")
local white = Color3.fromRGB(0, 0, 0)
local pulsing = false

local function startPulse()
    pulsing = true
    task.spawn(function()
        while pulsing do
            TweenService:Create(text, TweenInfo.new(0.5), {TextColor3 = gold}):Play()
            task.wait(0.5)
            if not pulsing then break end
            TweenService:Create(text, TweenInfo.new(0.5), {TextColor3 = white}):Play()
            task.wait(0.5)
        end
    end)
end

local function stopPulse()
    pulsing = false
    TweenService:Create(text, TweenInfo.new(0.5), {TextColor3 = gold}):Play()
    task.wait(0.5)
end

-- intro
TweenService:Create(img, TweenInfo.new(1), {ImageTransparency = 0}):Play()
TweenService:Create(blur, TweenInfo.new(1), {Size = 12}):Play()
task.wait(1)

local infoIn = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(img, infoIn, {Position = UDim2.new(0, 0, 0, 0)}):Play()
TweenService:Create(text, infoIn, {
    Position = UDim2.new(0, 100, 0, 0),
    Size = UDim2.new(0, 500, 0, 100)
}):Play()
startPulse()
task.wait(1.5 + 1)

-- outro
stopPulse()
task.wait(0.3)

local infoOut = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
TweenService:Create(img, infoOut, {Position = UDim2.new(0, 250, 0, 0)}):Play()
TweenService:Create(text, infoOut, {
    Position = UDim2.new(0, 350, 0, 0),
    Size = UDim2.new(0, 0, 0, 100)
}):Play()
task.wait(1.5)

TweenService:Create(img, TweenInfo.new(1), {ImageTransparency = 1}):Play()
TweenService:Create(blur, TweenInfo.new(1), {Size = 0}):Play()
task.wait(1)

blur:Destroy()
loadgui:Destroy()
