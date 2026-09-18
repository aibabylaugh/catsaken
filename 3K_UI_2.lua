return (function()
    if isfile("catsakenconfigs.json") then
        print("catsakenconfigs.json exists, loading " .. SaveFileName)
        SaveTable = HttpService:JSONDecode(readfile("catsakenconfigs.json"))[SaveFileName] or {}
    else
        warn("Creating a default config (" .. SaveFileName .. ")")
        writefile("catsakenconfigs.json", HttpService:JSONEncode({[SaveFileName] = {}}))
    end

    local Library = {}

    if RunService:IsStudio() then
        LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("debugUi"):Destroy()
    end

    local function addShadow(frame)
        local shadow = Instance.new("Frame")
        shadow.Size = UDim2.new(1, 0, 0, 80)
        shadow.Position = UDim2.new(0, 0, 1, -80)
        shadow.BackgroundColor3 = Color3.new(0, 0, 0)
        shadow.BackgroundTransparency = 0
        shadow.ZIndex = frame.ZIndex + 1
        shadow.Parent = frame.Parent
        
        local corner = Instance.new("UICorner", shadow)
        corner.CornerRadius = UDim.new(0, 5)
        
        local gradient = Instance.new("UIGradient")
        gradient.Rotation = 90
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0.6),
        })
        gradient.Parent = shadow

        local function update()
            local atBottom = (frame.CanvasPosition.Y + frame.AbsoluteWindowSize.Y + 10)
                >= frame.AbsoluteCanvasSize.Y - 1
            TweenService:Create(shadow, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                BackgroundTransparency = atBottom and 1 or 0
            }):Play()
        end

        frame:GetPropertyChangedSignal("CanvasPosition"):Connect(update)
        
        return shadow
    end

    local function createRipple(frame, x, y)
        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.6
        ripple.BorderSizePixel = 0
        ripple.Position = UDim2.fromOffset(x, y)
        ripple.Size = UDim2.fromOffset(0, 0)
        ripple.ZIndex = frame.ZIndex + 1
        ripple.ClipsDescendants = false

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple

        ripple.Parent = frame

        local absSize = frame.AbsoluteSize
        local maxDim = math.sqrt(absSize.X ^ 2 + absSize.Y ^ 2) * 0.2

        local TweenService = game:GetService("TweenService")
        local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        local expandTween = TweenService:Create(ripple, info, {
            Size = UDim2.fromOffset(maxDim, maxDim),
            BackgroundTransparency = 1,
        })

        expandTween:Play()
        expandTween.Completed:Connect(function()
            ripple:Destroy()
        end)
    end

    local function addCustomScrollbar(Frame)
        Frame.ScrollBarThickness = 0

        local Track = Instance.new("TextButton")
        Track.Name = "CustomScrollTrack"
        Track.Parent = Frame.Parent
        Track.AnchorPoint = Vector2.new(1, 0)
        Track.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Track.BackgroundTransparency = 0.450
        Track.BorderSizePixel = 0
        Track.ZIndex = Frame.ZIndex + 1
        Track.Text = ""

        local Bar = Instance.new("Frame")
        Bar.Name = "Bar"
        Bar.Parent = Track
        Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        Bar.BackgroundTransparency = 0.2
        Bar.BorderSizePixel = 0
        Bar.Size = UDim2.new(1, 0, 1, 0)
        Bar.Position = UDim2.new(0, 0, 0, 0)

        local THICKNESS = 16

        local function updateTrackPosition()
            Track.Position = UDim2.new(1, -2, 0, 0)
            Track.Size = UDim2.new(0, THICKNESS, 1, 0)
        end
        updateTrackPosition()

        local dragging = false
        local dragStartY = 0
        local dragStartCanvasY = 0

        local function updateBar()
            local canvasY = Frame.AbsoluteCanvasSize.Y
            local windowY = Frame.AbsoluteWindowSize.Y

            if canvasY <= windowY + 1 then
                Track.Visible = false
                return
            end
            Track.Visible = true

            local trackHeight = Track.AbsoluteSize.Y
            local barHeightScale = math.clamp(windowY / canvasY, 0.05, 1)
            local barHeightPx = math.max(trackHeight * barHeightScale, 20)

            local maxCanvasPos = canvasY - windowY
            local scrollAlpha = maxCanvasPos > 0 and (Frame.CanvasPosition.Y / maxCanvasPos) or 0
            local maxBarTravel = trackHeight - barHeightPx

            Bar.Size = UDim2.new(1, 0, 0, barHeightPx)
            Bar.Position = UDim2.new(0, 0, 0, maxBarTravel * scrollAlpha)
        end

        Frame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateBar)
        Frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateBar)
        Frame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateBar)
        Track:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBar)
        Frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateTrackPosition)
        Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateTrackPosition)

        local function setScrollFromBarCenter(inputY)
            local trackPos = Track.AbsolutePosition.Y
            local trackHeight = Track.AbsoluteSize.Y
            local barHeightPx = Bar.AbsoluteSize.Y

            local canvasY = Frame.AbsoluteCanvasSize.Y
            local windowY = Frame.AbsoluteWindowSize.Y
            local maxCanvasPos = math.max(canvasY - windowY, 0)
            local maxBarTravel = math.max(trackHeight - barHeightPx, 1)

            local relativeY = math.clamp(inputY - trackPos - (barHeightPx / 2), 0, maxBarTravel)
            local alpha = relativeY / maxBarTravel
            Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X, maxCanvasPos * alpha)
        end

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local canvasY = Frame.AbsoluteCanvasSize.Y
                local windowY = Frame.AbsoluteWindowSize.Y
                local maxCanvasPos = math.max(canvasY - windowY, 0)
                local trackHeight = Track.AbsoluteSize.Y
                local barHeightPx = Bar.AbsoluteSize.Y
                local maxBarTravel = math.max(trackHeight - barHeightPx, 1)

                local deltaY = input.Position.Y - dragStartY
                local deltaCanvas = (deltaY / maxBarTravel) * maxCanvasPos
                Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X, math.clamp(dragStartCanvasY + deltaCanvas, 0, maxCanvasPos))
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        Track.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            local barPos = Bar.AbsolutePosition.Y
            local barSize = Bar.AbsoluteSize.Y
            local clickedOnBar = input.Position.Y >= barPos and input.Position.Y <= barPos + barSize

            if clickedOnBar then
                dragging = true
                dragStartY = input.Position.Y
                dragStartCanvasY = Frame.CanvasPosition.Y
            else
                setScrollFromBarCenter(input.Position.Y)
            end
        end)

        updateBar()

        return Track
    end

    local SmoothScroll = (function()
        local RS, UIS, CAS = game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("ContextActionService")

        if not RS:IsClient() then
            error("SmoothScroll can only be used on the client")
        end

        local PlayerGui = RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui") or CoreGui
        local Mouse		= LocalPlayer:GetMouse()
        local ipairs,pairs	= ipairs,pairs

        wait()

        local DEFAULT_SENS,DEFAULT_FRICT = Mouse.ViewSizeY/27, 0.78


        local Objects = {}
        local ScrollBarHolder
        local DraggingBar = false
        if not UIS.TouchEnabled then

            ScrollBarHolder = Instance.new("ScreenGui")
            ScrollBarHolder.Name = "SmoothScroll"
            ScrollBarHolder.Parent = PlayerGui

            RS.Heartbeat:Connect(function()
                for Frame, Info in pairs(Objects) do
                    if Info.Velocity > 0.05 or Info.Velocity < -0.05 then
                        Info.Velocity = Info.Velocity*Info.Frict				
                        if Info.Axis == "X" then
                            Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X+Info.Velocity,Frame.CanvasPosition.Y)

                            if math.abs(Info.LastPos-Frame.CanvasPosition.X) == 0 then
                                Info.Velocity = 0
                            end
                            Info.LastPos = Frame.CanvasPosition.X
                        else
                            Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X,Frame.CanvasPosition.Y+Info.Velocity)

                            if math.abs(Info.LastPos-Frame.CanvasPosition.Y) == 0 then
                                Info.Velocity = 0
                            end
                            Info.LastPos = Frame.CanvasPosition.Y
                        end
                    end
                end
            end)

            UIS.PointerAction:Connect(function(Wheel,Pan,Pinch,GP)
                if not DraggingBar then
                    local HoveredObjects = PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)	
                    for i, Frame in ipairs(HoveredObjects) do
                        local Info = Objects[Frame]

                        if Info and Info.Visibility.Visible == true then
                            Info.Velocity = Info.Velocity - (Info.Sens * Pan.Y * (Info.Inverted and -1 or 1))
                            break
                        end
                    end
                end
            end)

            CAS:BindActionAtPriority("SmoothScroll", function(Name,State,Input)

                if DraggingBar then return Enum.ContextActionResult.Pass end

                local Processed = false

                local HoveredObjects = PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)	
                for i, Frame in ipairs(HoveredObjects) do
                    local Info = Objects[Frame]

                    if Info and Info.Visibility.Visible == true then
                        Info.Velocity = Info.Velocity - (Info.Sens * Input.Position.Z * (Info.Inverted and -1 or 1))
                        Processed = true
                        break
                    end
                end

                return Processed and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass

            end, false, 8000, Enum.UserInputType.MouseWheel)

        end

        local OnScreenTracker = {}
        OnScreenTracker.__index = OnScreenTracker

        function OnScreenTracker.new(obj)

            assert(typeof(obj) == "Instance" and obj:IsA("GuiObject"), "Argument #1 expected GuiObject")
            local visibleChanged = Instance.new("BindableEvent")

            local self = setmetatable({
                GuiObject = obj;
                Visible = nil;
                Changed = visibleChanged.Event;
                _path = {};
                _conn = {};
                _root = nil;
                _visibleChanged = visibleChanged;
            }, OnScreenTracker)

            local function CheckVisible()
                local vis = (self._root and self._root.Enabled or false)
                if (vis) then
                    local path = self._path
                    for i, p in ipairs(path) do
                        if (not p.Visible) then
                            vis = false
                            break
                        end
                    end
                end
                if (vis ~= self.Visible) then
                    self.Visible = vis
                    visibleChanged:Fire(vis)
                end
            end

            local function BuildAncestryPath()
                for _,c in ipairs(self._conn) do c:Disconnect() end
                local path = {}
                local conn = {}
                local root = nil
                local parent = obj
                while (parent and (parent:IsA("GuiObject") or parent:IsA("Folder"))) do
                    if parent:IsA("GuiObject") then
                        conn[#conn + 1] = parent:GetPropertyChangedSignal("Visible"):Connect(CheckVisible)
                        path[#path + 1] = parent
                    end
                    parent = parent.Parent
                end
                if (parent and parent:IsA("LayerCollector")) then
                    conn[#conn + 1] = parent:GetPropertyChangedSignal("Enabled"):Connect(CheckVisible)
                    root = parent
                end
                self._path = path
                self._conn = conn
                self._root = root
                CheckVisible()
            end

            self._ancestry = obj.AncestryChanged:Connect(function(child, parent)
                BuildAncestryPath()
            end)
            BuildAncestryPath()

            return self

        end

        function OnScreenTracker:Destroy()
            self._visibleChanged:Fire(false)
            self._visibleChanged:Destroy()
            self._ancestry:Disconnect()
            for _,c in ipairs(self._conn) do c:Disconnect() end
        end


        local function CreateBar(Frame,Axis)
            Axis = Axis or "Y"
            if not (Frame and typeof(Frame) == "Instance" and Frame.ClassName == "ScrollingFrame") then
                warn("Invalid frame to create custom bar")
                return
            end

            local Bar = Instance.new("TextButton")
            Bar.Name = Frame.Name.."_Scroller_"..Axis
            Bar.Text = ""
            Bar.BackgroundTransparency = 1
            Bar.Visible = Objects[Frame].Visibility.Visible

            local absSize,absPos,scrollThick = Frame.AbsoluteSize,Frame.AbsolutePosition,Frame.ScrollBarThickness

            local BarDrag
            Bar.MouseButton1Down:Connect(function()
                if not DraggingBar and not BarDrag then
                    DraggingBar = true

                    local LastPos = Vector2.new(Mouse.X,Mouse.Y)
                    BarDrag = UIS.InputChanged:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseMovement then

                            local Pos = Vector2.new(Input.Position.X,Input.Position.Y)
                            local Delta = Pos-LastPos
                            local DeltaPercent = (Axis == "Y" and Delta.Y or Delta.X)/(Axis == "Y" and Frame.AbsoluteWindowSize.Y or Frame.AbsoluteWindowSize.X)

                            local Parent = Frame:FindFirstAncestorWhichIsA("GuiBase2d")

                            local CanvasSize = Vector2.new(
                                (Frame.CanvasSize.X.Scale*Parent.AbsoluteSize.X)+Frame.CanvasSize.X.Offset,
                                (Frame.CanvasSize.Y.Scale*Parent.AbsoluteSize.Y)+Frame.CanvasSize.Y.Offset
                            )

                            Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X+(Axis == "X" and CanvasSize.X*DeltaPercent or 0),Frame.CanvasPosition.Y+(Axis == "Y" and CanvasSize.Y*DeltaPercent or 0))

                            LastPos = Pos
                        end
                    end)
                end
            end)
            local DragEnded = UIS.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 and BarDrag then
                    DraggingBar = false
                    BarDrag:Disconnect()
                    BarDrag = nil
                end
            end)

            Objects[Frame].Visibility.Changed:Connect(function(Visible)
                Bar.Visible = Visible

                if not Visible and BarDrag then
                    DraggingBar = false
                    BarDrag:Disconnect()
                    BarDrag = nil
                end
            end)

            if Axis == "X" then
                Bar.Size = UDim2.new(0,absSize.X,0,scrollThick)
                Bar.Position = UDim2.new(
                    0,absPos.X,
                    0,absPos.Y+absSize.Y-scrollThick
                )
            else
                Bar.Size = UDim2.new(0,scrollThick,0,absSize.Y)
                Bar.Position = UDim2.new(
                    0,Frame.VerticalScrollBarPosition == Enum.VerticalScrollBarPosition.Right and absPos.X+absSize.X-scrollThick or absPos.X,
                    0,absPos.Y
                )
            end

            local Updater
            Updater = Frame.Changed:Connect(function(Prop)
                if Objects[Frame] then
                    if Frame:FindFirstAncestorWhichIsA("GuiBase2d") then
                        if Prop == "AbsoluteSize" or Prop == "AbsolutePosition" or Prop == "AbsolutePosition" or Prop == "CanvasSize" or Prop == "ScrollBarThickness" then
                            absSize,absPos,scrollThick = Frame.AbsoluteSize,Frame.AbsolutePosition,Frame.ScrollBarThickness

                            if Axis == "X" then
                                Bar.Size = UDim2.new(0,absSize.X,0,scrollThick)
                                Bar.Position = UDim2.new(
                                    0,absPos.X,
                                    0,absPos.Y+absSize.Y-scrollThick
                                )
                            else
                                Bar.Size = UDim2.new(0,scrollThick,0,absSize.Y)
                                Bar.Position = UDim2.new(
                                    0,Frame.VerticalScrollBarPosition == Enum.VerticalScrollBarPosition.Right and absPos.X+absSize.X-scrollThick or absPos.X,
                                    0,absPos.Y
                                )
                            end
                        end

                    end
                else
                    Bar:Destroy()
                    Updater:Disconnect()
                    DragEnded:Disconnect()
                    if BarDrag then
                        BarDrag:Disconnect()
                        BarDrag = nil
                    end
                end
            end)

            Bar.Parent = ScrollBarHolder
        end

        local SmoothScroll = {}

        function SmoothScroll.Enable(Frame, Sensitivity, Friction, Inverted, Axis)
            if UIS.MouseEnabled and not UIS.TouchEnabled then

                if not (Frame and typeof(Frame) == "Instance" and Frame.ClassName == "ScrollingFrame") then
                    warn("Invalid frame to smooth")
                    return
                end

                if not Objects[Frame] then
                    Frame.ScrollingEnabled = false

                    local Actives,Connections = {},{}

                    for _,desc in ipairs(Frame:GetDescendants()) do
                        if desc:IsA("GuiObject") then
                            Actives[desc] = desc.Active
                            desc.Active = false
                            Connections[#Connections+1] = desc:GetPropertyChangedSignal("Active"):Connect(function()
                                desc.Active = false
                            end)
                        end
                    end

                    local parent = Frame
                    while (parent and (parent:IsA("GuiObject") or parent:IsA("Folder"))) do
                        if parent:IsA("GuiObject") then
                            Actives[parent] = parent.Active
                            parent.Active = false
                            Connections[#Connections+1] = parent:GetPropertyChangedSignal("Active"):Connect(function()
                                parent.Active = false
                            end)
                        end
                        parent = parent.Parent
                    end

                    Connections[#Connections+1] = Frame.DescendantAdded:Connect(function(desc)
                        if desc:IsA("GuiObject") then
                            Objects[Frame].Actives[desc] = desc.Active
                            desc.Active = false
                            Objects[Frame].Connections[#Objects[Frame].Connections+1] = desc:GetPropertyChangedSignal("Active"):Connect(function()
                                desc.Active = false
                            end)
                        end
                    end)


                    if Axis and (Axis == "X" or Axis == "Y") then
                    else
                        Axis = "Y" --Default to Y
                        if (Frame.CanvasSize.Y.Offset>0 or Frame.CanvasSize.Y.Scale>0) then
                            Axis = "Y"
                        elseif (Frame.CanvasSize.X.Offset>0 or Frame.CanvasSize.X.Scale>0) then
                            Axis = "X"
                        end
                    end

                    Objects[Frame] = {
                        Connections	= Connections;
                        Actives		= Actives;

                        Velocity	= 0;
                        LastPos		= 0;
                        Visibility	= OnScreenTracker.new(Frame);

                        Inverted	= Inverted;
                        Axis		= Axis;
                        Frict		= math.clamp(type(Friction)=="number" and Friction or DEFAULT_FRICT,0.2,0.99);
                        Sens		= math.clamp(type(Sensitivity)=="number" and Sensitivity or DEFAULT_SENS,0.01,99999999999999999);
                    }

                    CreateBar(Frame, "X")
                    CreateBar(Frame, "Y")
                else
                    Objects[Frame].Sens		= math.clamp(type(Sensitivity)=="number" and Sensitivity or DEFAULT_SENS,0.01,99999999999999999);
                    Objects[Frame].Frict	= math.clamp(type(Friction)=="number" and Friction or DEFAULT_FRICT,0.2,0.99);
                    Objects[Frame].Inverted	= Inverted
                end
            end
        end

        function SmoothScroll.Disable(Frame)

            if Objects[Frame] then
                Frame.ScrollingEnabled = true
                for i,c in ipairs(Objects[Frame].Connections) do
                    c:Disconnect()
                end
                Objects[Frame].Visibility:Destroy()
                for desc,a in pairs(Objects[Frame].Actives) do
                    desc.Active = a
                end

                Objects[Frame] = nil
            end

        end

        return SmoothScroll
    end)()

    local function AddDrag(Frame, DragBar)
        local dragToggle = nil
        local dragSpeed = 0.15
        local dragInput = nil
        local dragStart = nil
        local dragPos = nil
        local Delta
        local Position
        local startPos
        local function updateInput(input)
            Delta = input.Position - dragStart
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
            TweenService:Create(Frame, TweenInfo.new(0.05), {Position = Position}):Play()
        end
        DragBar.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and UserInputService:GetFocusedTextBox() == nil then
                dragToggle = true
                dragStart = input.Position
                startPos = Frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragToggle = false
                    end
                end)
            end
        end)
        DragBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragToggle then
                updateInput(input)
            end
        end)
    end

    Library.BlatantModeEnabled = Instance.new("BindableEvent")

    function Library:CreateWindow(Properties)
        local SpecialBackground = _G.LUNAR_BACKGROUND or getcustomasset("banner.png")
        local onimgupdate = function() end
        if not isfile("lunarbackgrounds") then
            makefolder("lunarbackgrounds")
        end
        function _G.UpdGuiBackground()
            SpecialBackground = _G.LUNAR_BACKGROUND
            if SpecialBackground then
                local filename = "lunarbackgrounds/" .. randomstring(10)
                if (SpecialBackground:find("https://") or SpecialBackground:find("http://")) and not SpecialBackground:match("http?.://roblox%.com") then
                    local content = safehttpget(SpecialBackground)
                    if content then
                        writefile(filename, content)
                        SpecialBackground = getcustomasset(filename) or getcustomasset("banner.png")
                    end
                end
            else
                SpecialBackground = getcustomasset("banner.png")
            end
            onimgupdate()
        end
        _G.UpdGuiBackground()
        local Name = Properties.Name
        local Icon = Properties.Icon
        if typeof(Icon) == "number" then
            Icon = "rbxassetid://" .. Icon
        end
        local uilibrary = Instance.new("ScreenGui")
        local MainFrame = Instance.new("Frame")
        local backgroundimagelabel = Instance.new("ImageLabel")
        local UICorner = Instance.new("UICorner")
        local Frame_2 = Instance.new("Frame")
        local UICorner_2 = Instance.new("UICorner")
        local ImageLabel = Instance.new("ImageLabel")
        local TextLabel = Instance.new("TextLabel")
        local search = Instance.new("Frame")
        local UICorner_3 = Instance.new("UICorner")
        local ImageLabel_2 = Instance.new("ImageLabel")
        local TextBox = Instance.new("TextBox")
        local UICorner_4 = Instance.new("UICorner")
        local Frame_3 = Instance.new("Frame")
        local NavigationBar = Instance.new("ScrollingFrame")
        local UIListLayout = Instance.new("UIListLayout")
        AddDrag(MainFrame, Frame_2)

        uilibrary.Name = game:GetService("HttpService"):GenerateGUID()
        uilibrary.Parent = not RunService:IsStudio() and gethui() or LocalPlayer.PlayerGui
        uilibrary.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        uilibrary.ResetOnSpawn = false
        uilibrary.Enabled = false
        uilibrary.OnTopOfCoreBlur = true
        uilibrary.DisplayOrder = (2^31)-1
        _G.globaluilibrary = uilibrary

        UserInputService.InputBegan:Connect(function(k,Gpe)
            if Unloaded then return end
            if Gpe then return end
            if k.KeyCode == Enum.KeyCode.F4 then
                if Env.MobileToggle and Env.MobileToggle.isSelected then
                    Env.MobileToggle:deselect()
                elseif Env.MobileToggle then
                    Env.MobileToggle:select()
                end
            end
        end)

        local Tooltip = Instance.new("Frame")
        local TooltipCorner = Instance.new("UICorner")
        local TooltipStroke = Instance.new("UIStroke")
        local TooltipPadding = Instance.new("UIPadding")
        local TooltipText = Instance.new("TextLabel")
        local TooltipScale = Instance.new("UIScale")

        Tooltip.Name = "Tooltip"
        Tooltip.Parent = uilibrary
        Tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        Tooltip.BackgroundTransparency = 0.05
        Tooltip.BorderSizePixel = 0
        Tooltip.Size = UDim2.fromOffset(220, 0)
        Tooltip.AutomaticSize = Enum.AutomaticSize.Y
        Tooltip.Visible = false
        Tooltip.ZIndex = 1000

        TooltipCorner.CornerRadius = UDim.new(0, 7)
        TooltipCorner.Parent = Tooltip

        TooltipStroke.Color = Color3.fromRGB(65, 65, 65)
        TooltipStroke.Thickness = 1
        TooltipStroke.Transparency = 0.15
        TooltipStroke.Parent = Tooltip

        TooltipPadding.PaddingLeft = UDim.new(0, 10)
        TooltipPadding.PaddingRight = UDim.new(0, 10)
        TooltipPadding.PaddingTop = UDim.new(0, 7)
        TooltipPadding.PaddingBottom = UDim.new(0, 7)
        TooltipPadding.Parent = Tooltip

        TooltipText.Parent = Tooltip
        TooltipText.BackgroundTransparency = 1
        TooltipText.BorderSizePixel = 0
        TooltipText.Size = UDim2.new(1, 0, 0, 0)
        TooltipText.AutomaticSize = Enum.AutomaticSize.Y
        TooltipText.Font = Enum.Font.Arial
        TooltipText.TextColor3 = Color3.fromRGB(220, 220, 220)
        TooltipText.TextSize = 12
        TooltipText.TextWrapped = true
        TooltipText.TextXAlignment = Enum.TextXAlignment.Left
        TooltipText.TextYAlignment = Enum.TextYAlignment.Top
        TooltipText.RichText = true
        TooltipText.ZIndex = 1001

        TooltipScale.Scale = 1
        TooltipScale.Parent = Tooltip

        local tooltipTarget = nil
        local tooltipText = nil
        local tooltipVisible = false
        local tooltipToken = 0
        local touchInput = nil

        local function getPointerPosition()
            if touchInput then
                return touchInput.Position
            end

            return UserInputService:GetMouseLocation()
        end

        local function positionTooltip()
            if not tooltipVisible then
                return
            end

            local camera = workspace.CurrentCamera
            if not camera then
                return
            end

            local viewport = camera.ViewportSize
            local mouse = getPointerPosition()

            local size = Tooltip.AbsoluteSize
            local padding = 14

            local x = mouse.X + padding
            local y = mouse.Y - size.Y - padding

            if x + size.X > viewport.X - 6 then
                x = mouse.X - size.X - padding
            end

            if y < 6 then
                y = mouse.Y + padding
            end

            x = math.clamp(x, 6, math.max(6, viewport.X - size.X - 6))
            y = math.clamp(y, 6, math.max(6, viewport.Y - size.Y - 6))

            Tooltip.Position = UDim2.fromOffset(x, y)
        end

        local function showTooltip(target, text)
            if not text or text == "" then
                return
            end

            tooltipToken += 1
            local token = tooltipToken

            tooltipTarget = target
            tooltipText = text
            tooltipVisible = true

            TooltipText.Text = text
            Tooltip.Visible = true

            TooltipScale.Scale = 0.96
            Tooltip.BackgroundTransparency = 0.05
            TooltipStroke.Transparency = 0.15

            task.defer(function()
                if token ~= tooltipToken or not tooltipVisible then
                    return
                end

                positionTooltip()

                TweenService:Create(
                    TooltipScale,
                    TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                    {Scale = 1}
                ):Play()
            end)
        end

        local function hideTooltip()
            tooltipToken += 1

            tooltipTarget = nil
            tooltipText = nil
            tooltipVisible = false
            touchInput = nil

            Tooltip.Visible = false
        end

        local function addToolTip(target, properties)
            if not target or not properties then
                return
            end

            local text = properties.ToolTip

            if not text or text == "" then
                return
            end

            target.Active = true

            target.MouseEnter:Connect(function()
                if IsMobile then
                    return
                end

                showTooltip(target, text)
            end)

            target.MouseLeave:Connect(function()
                if IsMobile then
                    return
                end

                if tooltipTarget == target then
                    hideTooltip()
                end
            end)

            target.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end

                touchInput = input

                tooltipToken += 1
                local token = tooltipToken

                task.delay(0.28, function()
                    if token ~= tooltipToken then
                        return
                    end

                    if touchInput ~= input then
                        return
                    end

                    showTooltip(target, text)
                end)
            end)

            target.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    touchInput = input

                    if tooltipTarget == target then
                        positionTooltip()
                    end
                end
            end)

            target.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    if touchInput == input then
                        hideTooltip()
                    end
                end
            end)
        end

        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if tooltipVisible then
                    positionTooltip()
                end
            elseif input.UserInputType == Enum.UserInputType.Touch then
                if tooltipVisible then
                    touchInput = input
                    positionTooltip()
                end
            end
        end)

        uilibrary.IgnoreGuiInset = true
        MainFrame.Parent = uilibrary
        MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        MainFrame.BorderSizePixel = 0
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        MainFrame.Size = (IsMobile or _G.SINGLE_COLUMNS) and UDim2.new(0, 570, 0, IsMobile and uilibrary.AbsoluteSize.Y / 1.4) or UDim2.new(0, 890, 0, 460)

        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = MainFrame

        Frame_2.Parent = MainFrame
        Frame_2.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        Frame_2.BackgroundTransparency = 0.650
        Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Frame_2.BorderSizePixel = 0
        Frame_2.Size = UDim2.new(1, 0, 0, 50)

        UICorner_2.CornerRadius = UDim.new(0, 5)
        UICorner_2.Parent = Frame_2

        ImageLabel.Parent = Frame_2
        ImageLabel.AnchorPoint = Vector2.new(0, 0.5)
        ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageLabel.BackgroundTransparency = 1.000
        ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageLabel.BorderSizePixel = 0
        ImageLabel.Position = UDim2.new(0, 3, 0.5, 0)
        ImageLabel.Size = UDim2.new(0, 36, 0, 36)
        ImageLabel.Image = Icon

        TextLabel.Parent = Frame_2
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.BackgroundTransparency = 1.000
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.BorderSizePixel = 0
        TextLabel.Position = UDim2.new(0, 50, 0.5, 0)
        TextLabel.Size = UDim2.new(0, 200, 0, 20)
        TextLabel.FontFace = Font.fromName("Arial", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        TextLabel.Text = Name
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextSize = 14.000
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left

        local Gradient = Instance.new("UIGradient")
        Gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 190, 80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 173, 80))
        })
        Gradient.Parent = TextLabel
        function _G.UpdGuiTitle()
            TextLabel.Text = type(_G.LUNAR_TITLE) == "string" and _G.LUNAR_TITLE or Name
        end

        search.Name = "search"
        search.Parent = Frame_2
        search.AnchorPoint = Vector2.new(1, 0.5)
        search.BackgroundColor3 = Color3.fromRGB(140, 85, 15)
        search.BackgroundTransparency = 0.650
        search.BorderColor3 = Color3.fromRGB(0, 0, 0)
        search.BorderSizePixel = 0
        search.Position = UDim2.new(1, -11, 0.5, 0)
        search.Size = UDim2.new(0, 139, 1, -24)

        UICorner_3.CornerRadius = UDim.new(0, 5)
        UICorner_3.Parent = search

        local searchasset = getIcon("search")
        ImageLabel_2.Parent = search
        ImageLabel_2.AnchorPoint = Vector2.new(1, 0.5)
        ImageLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ImageLabel_2.BackgroundTransparency = 1.000
        ImageLabel_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        ImageLabel_2.BorderSizePixel = 0
        ImageLabel_2.Position = UDim2.new(1, -6, 0.5, 0)
        ImageLabel_2.Size = UDim2.new(0, 16, 0, 16)
        ImageLabel_2.Image = searchasset.id
        ImageLabel_2.ImageRectOffset = searchasset.imageRectOffset
        ImageLabel_2.ImageRectSize = searchasset.imageRectSize

        TextBox.Parent = search
        TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextBox.BackgroundTransparency = 1.000
        TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextBox.BorderSizePixel = 0
        TextBox.ClipsDescendants = true
        TextBox.Position = UDim2.new(0, 4, 0, 0)
        TextBox.Size = UDim2.new(1, -34, 1, 0)
        TextBox.Font = Enum.Font.ArialBold
        TextBox.PlaceholderText = "Search"
        TextBox.Text = ""
        TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextBox.TextSize = 14.000
        TextBox.TextXAlignment = Enum.TextXAlignment.Left

        backgroundimagelabel.Name = "backgroundimagelabel"
        backgroundimagelabel.Parent = MainFrame
        backgroundimagelabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        backgroundimagelabel.BackgroundTransparency = 1.00
        backgroundimagelabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        backgroundimagelabel.BorderSizePixel = 0
        backgroundimagelabel.Size = UDim2.new(1, 0, 1, 0)
        backgroundimagelabel.ZIndex = 0
        backgroundimagelabel.Image = SpecialBackground
        backgroundimagelabel.ImageColor3 = Color3.fromRGB(116, 116, 116)
        backgroundimagelabel.ScaleType = Enum.ScaleType.Crop
        onimgupdate = function()
            backgroundimagelabel.Image = SpecialBackground or getcustomasset("banner.png")
        end

        UICorner_4.CornerRadius = UDim.new(0, 5)
        UICorner_4.Parent = backgroundimagelabel

        Frame_3.Parent = MainFrame
        Frame_3.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        Frame_3.BackgroundTransparency = 0.650
        Frame_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Frame_3.BorderSizePixel = 0
        Frame_3.Position = UDim2.new(0, 1, 0, 50)
        Frame_3.Size = UDim2.new(0, 160, 1, -50)

        NavigationBar.Parent = Frame_3
        NavigationBar.Active = true
        NavigationBar.AnchorPoint = Vector2.new(0, 0.5)
        NavigationBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        NavigationBar.BackgroundTransparency = 1.000
        NavigationBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
        NavigationBar.BorderSizePixel = 0
        NavigationBar.Position = UDim2.new(0, 0, 0.5, 0)
        NavigationBar.Size = UDim2.new(1, 0, 1, -6)
        NavigationBar.ScrollBarThickness = 2
        NavigationBar.ScrollBarImageColor3 = Color3.fromRGB(245, 159, 39)
        NavigationBar.ScrollBarImageTransparency = 0.4
        NavigationBar.CanvasSize = UDim2.new(0, 0, 0, 0)
        NavigationBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
        NavigationBar.ScrollingDirection = Enum.ScrollingDirection.Y
        NavigationBar.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
        NavigationBar.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
        NavigationBar.ClipsDescendants = true
        addShadow(NavigationBar)
        SmoothScroll.Enable(NavigationBar, 2, 0.9)

        UIListLayout.Parent = NavigationBar
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0, 4)
        
        local PageHolder = Instance.new("Frame")
        PageHolder.Name = "PageHolder"
        PageHolder.Parent = MainFrame
        PageHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        PageHolder.BackgroundTransparency = 1.000
        PageHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
        PageHolder.BorderSizePixel = 0
        PageHolder.Position = UDim2.new(0, 161, 0, 50)
        PageHolder.Size = UDim2.new(1, -159, 1, -60)
        PageHolder.ClipsDescendants = true
        
        local Window = {}
        local TabStore = {}

        local function scoreMatch(feature, query)
            local fl = feature:lower()
            local score = 0

            if fl == query then return 100 end

            -- Multi-word: all words must appear
            local queryWords = {}
            for w in query:gmatch("%S+") do table.insert(queryWords, w) end

            if #queryWords > 1 then
                for _, qw in ipairs(queryWords) do
                    if not fl:find(qw, 1, true) then return 0 end
                    score = score + 1
                end
                -- Bonus: feature contains exact full query as substring
                if fl:find(query, 1, true) then score = score + 3 end
                if fl == query then return 100 end
                score = score - (#fl / 20)
                return score
            end

            -- Single word path (your existing logic)
            local s = fl:find(query, 1, true)
            if not s then return 0 end
            score = score + 1
            if s == 1 then score = score + 4 end
            for word in fl:gmatch("%S+") do
                if word:sub(1, #query) == query then score = score + 3; break end
                if word == query then score = score + 5; break end
            end
            score = score - (#fl / 20)
            return score
        end

        local function search(query)
            query = query:lower()
            local bestScore = 0
            local bestTab = nil

            for i, v in pairs(TabStore) do
                local tabScore = 0
                for _, f in pairs(v.Features) do
                    tabScore = tabScore + scoreMatch(f, query)
                end
                v.Frame.Visible = tabScore > 0
                if tabScore > bestScore then
                    bestScore = tabScore
                    bestTab = i
                end
            end

            if bestTab then
                Window:SelectTab(bestTab)
            end
        end

        TextBox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = TextBox.Text
            if text ~= "" then
                search(text)
            else
                for _, v in pairs(TabStore) do
                    v.Frame.Visible = true
                end
            end
        end)
        
        function Window:CreateTab(Name, Icon)
            local TabButton = Instance.new("Frame")
            local Frame = Instance.new("Frame")
            local TextLabel = Instance.new("TextLabel")
            local ImageLabel = Instance.new("ImageLabel")
            local Asset = getIcon(Icon)
            local Page = Instance.new("Frame")
            local NFrame = Instance.new("Frame")
            local NTextLabel = Instance.new("TextLabel")
            local LeftScrolling = Instance.new("ScrollingFrame")
            local RightScrolling = Instance.new("ScrollingFrame")
            local LeftListLayout = Instance.new("UIListLayout")
            local RightListLayout = Instance.new("UIListLayout")
            local ScrollingFrame = LeftScrolling

            Page.Name = "Page"
            Page.Parent = PageHolder
            Page.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Page.BackgroundTransparency = 1.000
            Page.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Page.BorderSizePixel = 0
            Page.Position = UDim2.new(0, 0, 0, -30)
            Page.Size = UDim2.new(1, 0, 1, 0)
            Page.Visible = false

            NFrame.Parent = Page
            NFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            NFrame.BackgroundTransparency = 0.750
            NFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            NFrame.BorderSizePixel = 0
            NFrame.Size = UDim2.new(1, -1, 0, 28)
            NFrame.Position = UDim2.fromOffset(-1, 0)

            NTextLabel.Parent = NFrame
            NTextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            NTextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            NTextLabel.BackgroundTransparency = 1.000
            NTextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            NTextLabel.BorderSizePixel = 0
            NTextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            NTextLabel.Size = UDim2.new(1, 0, 1, 0)
            NTextLabel.Font = Enum.Font.ArialBold
            NTextLabel.Text = Name
            NTextLabel.TextColor3 = Color3.fromRGB(255, 190, 80)
            NTextLabel.TextSize = 13.000

            for _, sf in ipairs({LeftScrolling, RightScrolling}) do
                sf.Parent = Page
                sf.Active = true
                sf.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                sf.BackgroundTransparency = 1.000
                sf.BorderColor3 = Color3.fromRGB(0, 0, 0)
                sf.BorderSizePixel = 0
                sf.ScrollBarThickness = 0
                sf.CanvasSize = UDim2.new(0, 0, 0, 0)
                sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
                sf.ScrollingDirection = Enum.ScrollingDirection.Y
                sf.ClipsDescendants = true
                if IsMobile then
                    sf.ScrollingEnabled = false
                end
                SmoothScroll.Enable(sf, 4, 0.9)
            end

            LeftScrolling.Position = UDim2.new(0, 0, 0, 28)
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 6)
            padding.Parent = LeftScrolling
            if IsMobile or _G.SINGLE_COLUMNS then
                LeftScrolling.Size = UDim2.new(1, 0, 1, -28)
                RightScrolling.Visible = false
            else
                LeftScrolling.Size = UDim2.new(0.5, -4, 1, -28)
                RightScrolling.Position = UDim2.new(0.5, 4, 0, 28)
                RightScrolling.Size = UDim2.new(0.5, -4, 1, -28)
            end

            for _, pair in ipairs({{LeftListLayout, LeftScrolling}, {RightListLayout, RightScrolling}}) do
                local layout, sf = pair[1], pair[2]
                layout.Parent = sf
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                if IsMobile or _G.SINGLE_COLUMNS then
                    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                end
                layout.Padding = UDim.new(0, 3)
            end

            TabButton.Name = "TabButton"
            TabButton.Parent = NavigationBar
            TabButton.BackgroundColor3 = Color3.fromRGB(110, 65, 5)
            TabButton.BackgroundTransparency = 1.000
            TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TabButton.BorderSizePixel = 0
            TabButton.Size = UDim2.new(1, -4, 0, 35)

            Frame.Parent = TabButton
            Frame.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
            Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Frame.BorderSizePixel = 0
            Frame.AnchorPoint = Vector2.new(0, 0)
            Frame.Position = UDim2.new(0, 0, 0, 0)
            Frame.Size = UDim2.new(0, 1, 0, 0)

            TextLabel.Parent = TabButton
            TextLabel.AnchorPoint = Vector2.new(0, 0.5)
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.BackgroundTransparency = 1.000
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.Position = UDim2.new(0, 30, 0.5, 0)
            TextLabel.Size = UDim2.new(0, 200, 0, 20)
            TextLabel.Font = Enum.Font.ArialBold
            TextLabel.Text = Name
            TextLabel.TextColor3 = Color3.fromRGB(161, 161, 161)
            TextLabel.TextSize = 13.000
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left

            ImageLabel.Parent = TabButton
            ImageLabel.AnchorPoint = Vector2.new(0, 0.5)
            ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ImageLabel.BackgroundTransparency = 1.000
            ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ImageLabel.BorderSizePixel = 0
            ImageLabel.Position = UDim2.new(0, 7, 0.5, 0)
            ImageLabel.Size = UDim2.new(0, 16, 0, 16)
            ImageLabel.Image = Asset.id
            ImageLabel.ImageColor3 = Color3.fromRGB(161, 161, 161)
            ImageLabel.ImageRectOffset = Asset.imageRectOffset
            ImageLabel.ImageRectSize = Asset.imageRectSize
            ImageLabel.ScaleType = Enum.ScaleType.Fit

            local TInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
            local sepTween = nil

            local function SetSepAnchor(anchorY)
                Frame.AnchorPoint = Vector2.new(0, anchorY)
                Frame.Position = UDim2.new(0, Frame.Position.X.Offset, anchorY, Frame.Position.Y.Offset)
            end

            local function DeselectDirectional(goingDown, callback)
                Page.Position = UDim2.new(0, 0, 0, -10)
                Page.Visible = false
                TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 1}):Play()
                TweenService:Create(TextLabel, TInfo, {TextColor3 = Color3.fromRGB(161, 161, 161)}):Play()
                TweenService:Create(ImageLabel, TInfo, {ImageColor3 = Color3.fromRGB(161, 161, 161)}):Play()
                SetSepAnchor(goingDown and 1 or 0) -- shrink toward new tab
                if sepTween then sepTween:Cancel() end
                sepTween = TweenService:Create(Frame, TInfo, {Size = UDim2.new(0, 1, 0, 0)})
                if callback then
                    sepTween.Completed:Connect(callback)
                end
                sepTween:Play()
            end

            local function SelectDirectional(goingDown)
                Page.Visible = true
                TweenService:Create(Page, TweenInfo.new(0.2), {Position = UDim2.fromOffset(0, 0)}):Play()
                TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 0.65}):Play()
                TweenService:Create(TextLabel, TInfo, {TextColor3 = Color3.fromRGB(255, 190, 80)}):Play()
                TweenService:Create(ImageLabel, TInfo, {ImageColor3 = Color3.fromRGB(255, 190, 80)}):Play()
                SetSepAnchor(goingDown and 0 or 1) -- grow from direction it came from
                if sepTween then sepTween:Cancel() end
                Frame.Size = UDim2.new(0, 1, 0, 0)
                sepTween = TweenService:Create(Frame, TInfo, {Size = UDim2.new(0, 1, 1, 0)})
                sepTween:Play()
            end

            local this = {
                IsSelected = false,
                Frame = TabButton,
                Deselect = function() DeselectDirectional(true, nil) end,
                Select = function() SelectDirectional(true) end,
                DeselectDirectional = DeselectDirectional,
                SelectDirectional = SelectDirectional,
                Index = #TabStore + 1,
                Features = {},
                NumSections = 0,
                AutoIndex = 0
            }
            TabStore[#TabStore+1] = this

            local Click = Instance.new("TextButton")
            Click.Parent = TabButton
            Click.Text = ""
            Click.ZIndex = 2
            Click.BackgroundTransparency = 1
            Click.BorderSizePixel = 0
            Click.Size = UDim2.fromScale(1, 1)

            local function onClick()
                if this.IsSelected then return end

                local goingDown = true
                local prevTab = nil
                for _, v in pairs(TabStore) do
                    if v.IsSelected then
                        goingDown = this.Index > v.Index
                        prevTab = v
                        break
                    end
                end

                for _, v in pairs(TabStore) do
                    v.IsSelected = false
                end
                this.IsSelected = true

                if prevTab then
                    prevTab.DeselectDirectional(goingDown, function()
                        if this.IsSelected then
                            SelectDirectional(goingDown)
                        end
                    end)
                else
                    SelectDirectional(goingDown)
                end
            end

            Click.MouseEnter:Connect(function()
                this.IsHover = true
                if not this.IsSelected then
                    TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 0.8}):Play()
                end
            end)

            Click.MouseLeave:Connect(function()
                this.IsHover = false
                if not this.IsSelected then
                    TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 1}):Play()
                end
            end)
            
            Click.MouseButton1Down:Connect(function()
                if not this.IsSelected then
                    TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 0.7}):Play()
                end
            end)
            
            Click.MouseButton1Up:Connect(function()
                if not this.IsSelected then
                    if this.IsHover then
                        TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 0.8}):Play()
                    else
                        TweenService:Create(TabButton, TInfo, {BackgroundTransparency = 1}):Play()
                    end
                end
            end)
            
            Click.MouseButton1Click:Connect(onClick)
            
            local Tab = {}

            local HiddenHolder = Instance.new("Folder")
            HiddenHolder.Name = "HiddenElements"

            this.CurrentSection = nil
            this.CurrentSectionIndex = this.CurrentSectionIndex or 0
            this.SectionGroups = this.SectionGroups or {}
            this.Columns = this.Columns or {
                Left = {ScrollingFrame = LeftScrolling, Count = 0, LastSection = nil},
                Right = {ScrollingFrame = RightScrolling, Count = 0, LastSection = nil},
            }

            local function insertintosection(el)
                local sec = this.CurrentSection
                if sec then
                    local group = this.SectionGroups[sec]
                    el.LayoutOrder = this.CurrentSectionIndex * 1000 + #group + 1
                    table.insert(group, el)
                else
                    el.LayoutOrder = this.CurrentSectionIndex * 1000
                end
            end
            
            if IsMobile then
                addCustomScrollbar(LeftScrolling)
            end

            function Tab:CreateSection(Name, PreferredColumn)
                this.NumSections = this.NumSections + 1
                local Column
                if IsMobile or _G.SINGLE_COLUMNS then
                    Column = "Left"
                elseif PreferredColumn then
                    Column = PreferredColumn
                else
                    this.AutoIndex = this.AutoIndex + 1
                    Column = (this.AutoIndex % 2 == 1) and "Left" or "Right"
                end
                local colData = this.Columns[Column]

                if colData.Count > 0 and colData.LastSection then
                    local prevGroup = this.SectionGroups[colData.LastSection]
                    local filler = Instance.new("Frame")
                    filler.Parent = colData.ScrollingFrame
                    filler.BackgroundTransparency = 1
                    filler.Size = UDim2.new(0, 0, 0, 10)
                    filler.LayoutOrder = colData.LastSection.LayoutOrder + #prevGroup + 1
                    table.insert(prevGroup, filler)
                end

                ScrollingFrame = colData.ScrollingFrame

                local Section = Instance.new("Frame")
                local TextButton = Instance.new("TextButton")

                Section.Name = "Section"
                Section.Parent = ScrollingFrame
                Section.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Section.BackgroundTransparency = 1.000
                Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Section.BorderSizePixel = 0
                Section.Size = UDim2.new(1, 0, 0, 28)

                TextButton.Parent = Section
                TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextButton.BackgroundTransparency = 1.000
                TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextButton.BorderSizePixel = 0
                TextButton.Position = UDim2.new(0, 10, 0, 0)
                TextButton.Size = UDim2.new(1, -20, 1, 0)
                TextButton.Font = Enum.Font.ArialBold
                TextButton.Text = Name
                TextButton.TextColor3 = Color3.fromRGB(199, 199, 199)
                TextButton.TextSize = 13.000
                TextButton.TextXAlignment = Enum.TextXAlignment.Left
                TextButton.ZIndex = 2

                local tlc = TextButton:Clone()
                tlc.ZIndex = 1
                tlc.TextColor3 = Color3.fromRGB(0, 0, 0)
                tlc.Position = TextButton.Position + UDim2.fromOffset(1, 1)
                tlc.Parent = TextButton.Parent
                tlc.Active = false

                this.CurrentSectionIndex = this.CurrentSectionIndex + 1
                Section.LayoutOrder = this.CurrentSectionIndex * 1000
                this.CurrentSection = Section
                this.SectionGroups[Section] = {}
                colData.Count = colData.Count + 1
                colData.LastSection = Section

                local Collapsed = false
                local Animating = false
                local COLLAPSE_TIME = 0.2
                local STAGGER = 0.06
                local COLLAPSE_TINFO = TweenInfo.new(COLLAPSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

                local ListLayout = colData.ScrollingFrame:FindFirstChildOfClass("UIListLayout")

                TextButton.MouseButton1Click:Connect(function()
                    if Animating then return end
                    Animating = true
                    Collapsed = not Collapsed
                    local group = this.SectionGroups[Section]
                    local n = #group
                    local totalTime = COLLAPSE_TIME + (n > 0 and (n - 1) * STAGGER or 0)

                    if Collapsed then
                        local originals = {}
                        local origClips = {}
                        local origPos = {}
                        local origAutoSize = {}
                        for i = 1, n do
                            local el = group[i]
                            originals[el] = el.Size
                            origAutoSize[el] = el.AutomaticSize
                            if el.AutomaticSize ~= Enum.AutomaticSize.None then
                                el.AutomaticSize = Enum.AutomaticSize.None
                            end
                            origClips[el] = el.ClipsDescendants
                            origPos[el] = el.Position
                            el.ClipsDescendants = true
                        end
                        for i = n, 1, -1 do
                            local el = group[i]
                            local delay = (n - i) * STAGGER
                            local shrinkHeight = originals[el].Y.Offset
                            task.delay(delay, function()
                                TweenService:Create(el, COLLAPSE_TINFO, {
                                    Size = UDim2.new(el.Size.X.Scale, el.Size.X.Offset, 0, 0)
                                }):Play()
                                for j = i + 1, n do
                                    local below = group[j]
                                    local curPos = below.Position
                                    TweenService:Create(below, COLLAPSE_TINFO, {
                                        Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset - shrinkHeight)
                                    }):Play()
                                end
                            end)
                        end
                        task.delay(totalTime, function()
                            for i = 1, n do
                                local el = group[i]
                                el.Parent = HiddenHolder
                                el.Position = origPos[el]
                                el:SetAttribute("__restoreX", originals[el].X.Scale)
                                el:SetAttribute("__restoreXO", originals[el].X.Offset)
                                el:SetAttribute("__restoreY", originals[el].Y.Scale)
                                el:SetAttribute("__restoreYO", originals[el].Y.Offset)
                                el:SetAttribute("__clips", origClips[el])
                                el:SetAttribute("__autosize", origAutoSize[el].Name)
                            end
                            Animating = false
                        end)
                    else
                        for i = 1, n do
                            local el = group[i]
                            local rx = el:GetAttribute("__restoreX") or 0
                            local rxo = el:GetAttribute("__restoreXO") or 0
                            el.Size = UDim2.new(rx, rxo, 0, 0)
                            el.Parent = colData.ScrollingFrame
                        end
                        task.wait()
                        local restPositions = {}
                        for i = 1, n do
                            restPositions[group[i]] = group[i].Position
                        end
                        for i = 1, n do
                            local el = group[i]
                            el.Position = restPositions[el]
                        end
                        for i = 1, n do
                            local el = group[i]
                            local rx = el:GetAttribute("__restoreX") or 0
                            local rxo = el:GetAttribute("__restoreXO") or 0
                            local ry = el:GetAttribute("__restoreY") or 0
                            local ryo = el:GetAttribute("__restoreYO") or 0
                            local growHeight = ryo
                            local delay = (i - 1) * STAGGER
                            task.delay(delay, function()
                                TweenService:Create(el, COLLAPSE_TINFO, {
                                    Size = UDim2.new(rx, rxo, ry, ryo)
                                }):Play()
                                for j = i + 1, n do
                                    local below = group[j]
                                    local curPos = below.Position
                                    TweenService:Create(below, COLLAPSE_TINFO, {
                                        Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset + growHeight)
                                    }):Play()
                                end
                            end)
                        end
                        task.delay(totalTime, function()
                            for i = 1, n do
                                local el = group[i]
                                local clips = el:GetAttribute("__clips")
                                el.ClipsDescendants = (clips == nil) and false or clips
                                local autosizeName = el:GetAttribute("__autosize")
                                if autosizeName then
                                    el.AutomaticSize = Enum.AutomaticSize[autosizeName]
                                end
                            end
                            Animating = false
                        end)
                    end
                end)

                return {
                    Set = function(self, New)
                        TextButton.Text = New
                        tlc.Text = New
                    end
                }
            end

            function Tab:CreateLabel(Text)
                local Toggle = Instance.new("Frame")
                local TextLabel = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local UIPadding = Instance.new("UIPadding")

                Toggle.Name = "Toggle"
                Toggle.Parent = ScrollingFrame
                insertintosection(Toggle)
                Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Toggle.BackgroundTransparency = 0.450
                Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Toggle.BorderSizePixel = 0
                Toggle.AutomaticSize = Enum.AutomaticSize.Y
                Toggle.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 28)

                UIPadding.Parent = Toggle
                UIPadding.PaddingTop = UDim.new(0, 6)
                UIPadding.PaddingBottom = UDim.new(0, 6)

                TextLabel.Parent = Toggle
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.BackgroundTransparency = 1.000
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BorderSizePixel = 0
                TextLabel.Position = UDim2.new(0, 10, 0, 0)
                TextLabel.Size = UDim2.new(1, -20, 0, 0)
                TextLabel.AutomaticSize = Enum.AutomaticSize.Y
                TextLabel.TextWrapped = true
                TextLabel.Font = Enum.Font.ArialBold
                TextLabel.Text = Text
                TextLabel.TextColor3 = Color3.fromRGB(145, 145, 145)
                TextLabel.TextSize = 13.000
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.RichText = true

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Toggle

                return {
                    Set = function(self, New)
                        TextLabel.Text = New
                    end
                }
            end
            
            function Tab:CreateToggle(Properties)
                local Flag = Properties.Flag
                local CurrentValue = Properties.CurrentValue
                local Name = Properties.Name
                local Callback = Properties.Callback or function() end
                local TextMode = Properties.TextMode
                Window.Flags[Flag] = {CurrentValue = CurrentValue, __ISTOGGLE = true}
                table.insert(this.Features, Name)
                
                local Toggle = Instance.new("Frame")
                local TextLabel = Instance.new("TextButton")
                local UICorner = Instance.new("UICorner")
                local Switch, UICorner_2, ball, UICorner_3, StateLabel

                Toggle.Name = "Toggle"
                Toggle.Parent = ScrollingFrame
                insertintosection(Toggle)
                Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Toggle.BackgroundTransparency = 0.450
                Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Toggle.BorderSizePixel = 0
                Toggle.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 28)

                TextLabel.Parent = Toggle
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.BackgroundTransparency = 1.000
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BorderSizePixel = 0
                TextLabel.Position = UDim2.new(0, 10, 0, 0)
                TextLabel.Size = UDim2.new(0.5, 0, 0, 28)
                TextLabel.Font = Enum.Font.ArialBold
                TextLabel.Text = Name
                TextLabel.TextColor3 = Color3.fromRGB(199, 199, 199)
                TextLabel.TextSize = 13.000
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.RichText = true
                addToolTip(TextLabel, Properties)

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Toggle

                local Click = Instance.new("TextButton")
                Click.Text = ""
                Click.ZIndex = 2
                Click.BackgroundTransparency = 1
                Click.BorderSizePixel = 0

                local animation

                if TextMode then
                    StateLabel = Instance.new("TextLabel")
                    StateLabel.Name = "StateLabel"
                    StateLabel.Parent = Toggle
                    StateLabel.AnchorPoint = Vector2.new(1, 0.5)
                    StateLabel.BackgroundTransparency = 1
                    StateLabel.Position = UDim2.new(1, -10, 0.5, 0)
                    StateLabel.Size = UDim2.new(0, 40, 0, 20)
                    StateLabel.Font = Enum.Font.ArialBold
                    StateLabel.TextSize = 13
                    StateLabel.TextXAlignment = Enum.TextXAlignment.Right

                    Click.Parent = StateLabel
                    Click.Size = UDim2.fromScale(1, 1)

                    animation = function()
                        if CurrentValue then
                            StateLabel.Text = "ON"
                            StateLabel.TextColor3 = Color3.fromRGB(85, 170, 85)
                        else
                            StateLabel.Text = "OFF"
                            StateLabel.TextColor3 = Color3.fromRGB(170, 60, 60)
                        end

                        StateLabel.TextSize = 18
                        TweenService:Create(StateLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 13}):Play()
                    end
                else
                    Switch = Instance.new("Frame")
                    UICorner_2 = Instance.new("UICorner")
                    ball = Instance.new("Frame")
                    UICorner_3 = Instance.new("UICorner")

                    Switch.Name = "Switch"
                    Switch.Parent = Toggle
                    Switch.AnchorPoint = Vector2.new(1, 0)
                    Switch.BackgroundColor3 = Color3.fromRGB(67, 67, 67)
                    Switch.BackgroundTransparency = 0.700
                    Switch.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Switch.BorderSizePixel = 0
                    Switch.Position = UDim2.new(1, -4, 0, 4)
                    Switch.Size = UDim2.new(0, 48, 0, 20)

                    UICorner_2.CornerRadius = UDim.new(1, 0)
                    UICorner_2.Parent = Switch

                    ball.Name = "ball"
                    ball.Parent = Switch
                    ball.AnchorPoint = Vector2.new(0, 0.5)
                    ball.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
                    ball.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ball.BorderSizePixel = 0
                    ball.Position = UDim2.new(0, 2, 0.5, 0)
                    ball.Size = UDim2.new(0, 16, 0, 16)

                    UICorner_3.CornerRadius = UDim.new(1, 0)
                    UICorner_3.Parent = ball

                    Click.Parent = Switch
                    Click.Size = UDim2.fromScale(1, 1)

                    local TInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine)

                    animation = function()
                        if CurrentValue then
                            TweenService:Create(Switch, TInfo, {BackgroundColor3 = Color3.fromRGB(140, 85, 15)}):Play()
                            TweenService:Create(ball, TInfo, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                            TweenService:Create(ball, TInfo, {Position = UDim2.new(0, 30, 0.5, 0)}):Play()
                        else
                            TweenService:Create(Switch, TInfo, {BackgroundColor3 = Color3.fromRGB(67, 67, 67)}):Play()
                            TweenService:Create(ball, TInfo, {BackgroundColor3 = Color3.fromRGB(62, 62, 62)}):Play()
                            TweenService:Create(ball, TInfo, {Position = UDim2.new(0, 2, 0.5, 0)}):Play()
                        end
                    end

                    Click.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch
                        then
                            TweenService:Create(ball, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 16, 0, 10)}):Play()
                        end
                    end)

                    Click.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch
                        then
                            TweenService:Create(ball, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 16, 0, 16)}):Play()
                        end
                    end)
                end

                local F = Window.Flags[Flag]
                function F:Set(New, IsSave)
                    CurrentValue = New
                    Window.Flags[Flag].CurrentValue = CurrentValue
                    animation()
                    task.spawn(function()
                        Callback(New, IsSave)
                    end)
                end

                local toset

                if CurrentValue then
                    toset = CurrentValue
                end
                if SaveTable[Flag] and SaveTable[Flag].CurrentValue ~= nil and not Properties.NoSave then
                    toset = SaveTable[Flag].CurrentValue
                end
                if toset ~= nil then
                    F:Set(toset, true)
                end
                
                Click.MouseButton1Click:Connect(function()
                    if Properties.Blatant and not Properties.__UNLOCKED then return end
                    F:Set(not CurrentValue)
                end)

                if not CurrentValue and TextMode then
                    animation()
                end

                TextLabel.MouseButton1Click:Connect(function()
                    if Properties.Blatant and not Properties.__UNLOCKED then
                        Window:SelectTab(Library.BlatantTabIndex)
                    end
                end)

                if Properties.Blatant and Library.BlatantTabIndex then
                    TextLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
                    Library.BlatantModeEnabled.Event:Connect(function(bool)
                        Properties.__UNLOCKED = bool
                        TextLabel.TextColor3 = bool and Color3.fromRGB(199, 199, 199) or Color3.fromRGB(100, 100, 100)
                        TextLabel.Text = bool and Name or (Name .. '\n<font size="9"><font color="rgb(170, 60, 60)">Blatant mode is required --></font></font>')
                    end)
                end

                return F
            end
            
            function Tab:CreateButton(Properties)
                local Name = Properties.Name
                local Callback = Properties.Callback or function() end
                table.insert(this.Features, Name)
                
                local Button = Instance.new("Frame")
                local TextLabel = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local ImageLabel = Instance.new("ImageLabel")
                local HelpIcon = Instance.new("ImageLabel")

                Button.Name = "Button"
                Button.Parent = ScrollingFrame
                insertintosection(Button)
                Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Button.BackgroundTransparency = 0.450
                Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Button.BorderSizePixel = 0
                Button.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)
                Button.ClipsDescendants = true

                TextLabel.Parent = Button
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.BackgroundTransparency = 1.000
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BorderSizePixel = 0
                TextLabel.Position = UDim2.new(0, 10, 0, 0)
                TextLabel.Size = UDim2.new(0.5, 0, 0, 32)
                TextLabel.Font = Enum.Font.ArialBold
                TextLabel.Text = Name
                TextLabel.TextColor3 = Color3.fromRGB(199, 199, 199)
                TextLabel.TextSize = 13.000
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                addToolTip(HelpIcon, Properties)

                if Properties.ToolTip then
                    local infoasset = getIcon("info")
                    ImageLabel.Parent = Button
                    ImageLabel.AnchorPoint = Vector2.new(1, 0)
                    ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ImageLabel.BackgroundTransparency = 1.000
                    ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    ImageLabel.BorderSizePixel = 0
                    ImageLabel.Position = UDim2.new(1, -30, 0, 6)
                    ImageLabel.Size = UDim2.new(0, 20, 0, 20)
                    ImageLabel.Image = infoasset.id
                    ImageLabel.ImageRectOffset = infoasset.imageRectOffset
                    ImageLabel.ImageRectSize = infoasset.imageRectSize
                end

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Button

                local mouseasset = getIcon("mouse-pointer-2")
                ImageLabel.Parent = Button
                ImageLabel.AnchorPoint = Vector2.new(1, 0)
                ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ImageLabel.BackgroundTransparency = 1.000
                ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ImageLabel.BorderSizePixel = 0
                ImageLabel.Position = UDim2.new(1, -4, 0, 6)
                ImageLabel.Size = UDim2.new(0, 20, 0, 20)
                ImageLabel.Image = mouseasset.id
                ImageLabel.ImageRectOffset = mouseasset.imageRectOffset
                ImageLabel.ImageRectSize = mouseasset.imageRectSize

                local bigclicker = Instance.new("TextButton", Button)
                bigclicker.Text = ""
                bigclicker.BackgroundTransparency = 1
                bigclicker.Size = UDim2.fromScale(1, 1)

                local isdown = false
                bigclicker.MouseButton1Click:Connect(function()
                    task.spawn(function()
                        Callback()
                    end)
                end)
                bigclicker.MouseButton1Down:Connect(function()
                    isdown = true
                end)
                bigclicker.MouseButton1Up:Connect(function()
                    isdown = false
                end)

                bigclicker.InputBegan:Connect(function(type)
                    if type.UserInputType == Enum.UserInputType.Touch or type.UserInputType == Enum.UserInputType.MouseButton1 then
                        local absPos = Button.AbsolutePosition
                        local localX = type.Position.X - absPos.X
                        local localY = type.Position.Y - absPos.Y
                        createRipple(Button, localX, localY)
                    end
                end)
            end
            
            function Tab:CreateSlider(Properties)
                local Name = Properties.Name
                local Range = Properties.Range
                local Min = Range[1]
                local Max = Range[2]
                local CurrentValue = Properties.CurrentValue
                local Flag = Properties.Flag
                Window.Flags[Flag] = {CurrentValue = CurrentValue}
                local Callback = Properties.Callback or function() end
                local Suffix = Properties.Suffix or ""
                local Increment = Properties.Increment
                local FormatType = Properties.FormatType
                table.insert(this.Features, Name)

                local Slider = Instance.new("Frame")
                local SliderName = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local Bar = Instance.new("Frame")
                local UICorner_2 = Instance.new("UICorner")
                local Ball = Instance.new("Frame")
                local UICorner_3 = Instance.new("UICorner")
                local Fill = Instance.new("Frame")
                local UICorner_4 = Instance.new("UICorner")
                Slider.Name = "Slider"
                Slider.Parent = ScrollingFrame
                insertintosection(Slider)
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BackgroundTransparency = 0.450
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderSizePixel = 0
                Slider.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)
                SliderName.Name = "SliderName"
                SliderName.Parent = Slider
                SliderName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SliderName.BackgroundTransparency = 1.000
                SliderName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                SliderName.BorderSizePixel = 0
                SliderName.Position = UDim2.new(0, 10, 0, 0)
                SliderName.Size = UDim2.new(0.5, 0, 0, 32)
                SliderName.Font = Enum.Font.ArialBold
                SliderName.Text = Name
                SliderName.TextColor3 = Color3.fromRGB(199, 199, 199)
                SliderName.TextSize = 13.000
                SliderName.TextXAlignment = Enum.TextXAlignment.Left
                SliderName.RichText = true
                addToolTip(SliderName, Properties)
                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Slider
                Bar.Name = "Bar"
                Bar.Parent = Slider
                Bar.AnchorPoint = Vector2.new(1, 0)
                Bar.BackgroundColor3 = Color3.fromRGB(109, 109, 129)
                Bar.BackgroundTransparency = 0.500
                Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Bar.BorderSizePixel = 0
                Bar.Position = UDim2.new(1, -16, 0, 13)
                Bar.Size = UDim2.new(0, 120, 0, 6)
                UICorner_2.CornerRadius = UDim.new(1, 0)
                UICorner_2.Parent = Bar
                Ball.Name = "Ball"
                Ball.Parent = Bar
                Ball.AnchorPoint = Vector2.new(0.5, 0.5)
                Ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Ball.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Ball.BorderSizePixel = 0
                Ball.Position = UDim2.new(0.5, 0, 0.5, 0)
                Ball.Size = UDim2.new(0, 16, 0, 16)
                Ball.ZIndex = 2
                UICorner_3.CornerRadius = UDim.new(1, 0)
                UICorner_3.Parent = Ball
                Fill.Name = "Fill"
                Fill.Parent = Bar
                Fill.BackgroundColor3 = Color3.fromRGB(245, 159, 39)
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.BorderSizePixel = 0
                Fill.Size = UDim2.new(0.5, 0, 1, 0)
                UICorner_4.CornerRadius = UDim.new(1, 0)
                UICorner_4.Parent = Fill
                
                -- Add after UICorner_4.Parent = Fill

                local BAR_DEFAULT_SIZE = UDim2.new(0, 120, 0, 6)
                local BAR_HOVER_SIZE = UDim2.new(0, 120, 0, 9)
                local BALL_DEFAULT_SIZE = UDim2.new(0, 16, 0, 16)
                local BALL_HOVER_SIZE = UDim2.new(0, 20, 0, 20)
                local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

                local function valueToAlpha(val)
                    return (val - Min) / (Max - Min)
                end

                local function alphaToValue(alpha)
                    local raw = alpha * (Max - Min) + Min
                    local stepped = math.round(raw / Increment) * Increment
                    local decimals = math.max(0, math.ceil(-math.log10(Increment)))
                    return tonumber(string.format("%." .. decimals .. "f", math.clamp(stepped, Min, Max)))
                end

                local function updateVisuals(alpha, tween)
                    local val = alphaToValue(alpha)
                    SliderName.Text = Name .. " <font color=\"rgb(245, 159, 39)\">" .. (FormatType == "time" and truncatetime(val) or val) .. "<font color=\"rgb(141, 141, 141)\">" .. Suffix .. "</font></font>"
                    local targetFill = UDim2.new(alpha, 0, 1, 0)
                    local targetBall = UDim2.new(alpha, 0, 0.5, 0)
                    if tween then
                        TweenService:Create(Fill, TWEEN_INFO, {Size = targetFill}):Play()
                        TweenService:Create(Ball, TWEEN_INFO, {Position = targetBall}):Play()
                    else
                        Fill.Size = targetFill
                        Ball.Position = targetBall
                    end
                end

                if SaveTable[Flag] then
                    CurrentValue = SaveTable[Flag].CurrentValue
                    Window.Flags[Flag] = {CurrentValue = CurrentValue}
                    task.spawn(function()
                        Callback(CurrentValue)
                    end)
                end

                -- Set initial visuals without callback
                updateVisuals(valueToAlpha(CurrentValue), false)

                local dragging = false

                local function onDrag(inputX)
                    local barPos = Bar.AbsolutePosition.X
                    local barSize = Bar.AbsoluteSize.X
                    local alpha = math.clamp((inputX - barPos) / barSize, 0, 1)
                    local newValue = alphaToValue(alpha)
                    if newValue ~= Window.Flags[Flag].CurrentValue then
                        Window.Flags[Flag].CurrentValue = newValue
                        updateVisuals(valueToAlpha(newValue), true)
                        SliderName.Text = Name .. " <font color=\"rgb(245, 159, 39)\">" .. (FormatType == "time" and truncatetime(newValue) or newValue) .. "<font color=\"rgb(141, 141, 141)\">" .. Suffix .. "</font></font>"
                        Callback(newValue)
                    end
                end

                -- Hover
                local Hover = false
                local Hover2 = false
                Bar.MouseEnter:Connect(function()
                    Hover = true
                    TweenService:Create(Bar, TWEEN_INFO, {Size = BAR_HOVER_SIZE}):Play()
                    TweenService:Create(Ball, TWEEN_INFO, {Size = BALL_HOVER_SIZE}):Play()
                end)
                Bar.MouseLeave:Connect(function()
                    Hover = false
                    if not Hover2 and not dragging then
                        TweenService:Create(Bar, TWEEN_INFO, {Size = BAR_DEFAULT_SIZE}):Play()
                        TweenService:Create(Ball, TWEEN_INFO, {Size = BALL_DEFAULT_SIZE}):Play()
                    end
                end)
                Ball.MouseEnter:Connect(function()
                    Hover2 = true
                    TweenService:Create(Bar, TWEEN_INFO, {Size = BAR_HOVER_SIZE}):Play()
                    TweenService:Create(Ball, TWEEN_INFO, {Size = BALL_HOVER_SIZE}):Play()
                end)
                Ball.MouseLeave:Connect(function()
                    Hover2 = false
                    if not Hover and not dragging then
                        TweenService:Create(Bar, TWEEN_INFO, {Size = BAR_DEFAULT_SIZE}):Play()
                        TweenService:Create(Ball, TWEEN_INFO, {Size = BALL_DEFAULT_SIZE}):Play()
                    end
                end)
                
                Ball.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        onDrag(input.Position.X)
                    end
                end)

                -- Mouse
                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        onDrag(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        onDrag(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                        dragging = false
                        if input.UserInputType == Enum.UserInputType.Touch or (not Hover and not Hover2) then
                            TweenService:Create(Bar, TWEEN_INFO, {Size = BAR_DEFAULT_SIZE}):Play()
                            TweenService:Create(Ball, TWEEN_INFO, {Size = BALL_DEFAULT_SIZE}):Play()
                        end
                    end
                end)

                -- Init label
                SliderName.Text = Name .. " <font color=\"rgb(245, 159, 39)\">" .. (FormatType == "time" and truncatetime(CurrentValue) or CurrentValue) .. "<font color=\"rgb(141, 141, 141)\">" .. Suffix .. "</font></font>"
            end
            
            function Tab:CreateDropdown(Properties)
                local Name = Properties.Name
                local Flag = Properties.Flag
                local CurrentOption = deepcopy(Properties.CurrentOption)
                local Options = deepcopy(Properties.Options)
                local MultipleOptions = Properties.MultipleOptions
                local Callback = Properties.Callback or function() end
                table.insert(this.Features, Name)
                
                local Dropdown = Instance.new("Frame")
                local DropdownName = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local ImageLabel = Instance.new("ImageLabel")
                local ScrollingFrame2 = Instance.new("ScrollingFrame")
                local UIListLayout = Instance.new("UIListLayout")

                Dropdown.Name = "Dropdown"
                Dropdown.Parent = ScrollingFrame
                insertintosection(Dropdown)
                Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BackgroundTransparency = 0.450
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BorderSizePixel = 0
                Dropdown.ClipsDescendants = true
                Dropdown.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)
                Dropdown.ClipsDescendants = true

                DropdownName.Name = "SliderName"
                DropdownName.Parent = Dropdown
                DropdownName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                DropdownName.BackgroundTransparency = 1.000
                DropdownName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                DropdownName.BorderSizePixel = 0
                DropdownName.Position = UDim2.new(0, 10, 0, 0)
                DropdownName.Size = UDim2.new(0.5, 0, 0, 32)
                DropdownName.Font = Enum.Font.ArialBold
                DropdownName.TextColor3 = Color3.fromRGB(199, 199, 199)
                DropdownName.TextSize = 13.000
                DropdownName.TextXAlignment = Enum.TextXAlignment.Left
                DropdownName.RichText = true
                addToolTip(DropdownName, Properties)

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Dropdown

                ImageLabel.Parent = Dropdown
                ImageLabel.AnchorPoint = Vector2.new(1, 0)
                ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ImageLabel.BackgroundTransparency = 1.000
                ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ImageLabel.BorderSizePixel = 0
                ImageLabel.Position = UDim2.new(1, -4, 0, 6)
                ImageLabel.Size = UDim2.new(0, 20, 0, 20)
                ImageLabel.Image = "rbxassetid://130996747355335"

                ScrollingFrame2.Parent = Dropdown
                ScrollingFrame2.Active = true
                ScrollingFrame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ScrollingFrame2.BackgroundTransparency = 1.000
                ScrollingFrame2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ScrollingFrame2.BorderSizePixel = 0
                ScrollingFrame2.Position = UDim2.new(0, 10, 0, 32)
                ScrollingFrame2.Size = UDim2.new(1, -20, 1, -42)
                ScrollingFrame2.ScrollBarThickness = 8
                ScrollingFrame2.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                ScrollingFrame2.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                ScrollingFrame2.AutomaticCanvasSize = Enum.AutomaticSize.Y
                ScrollingFrame2.CanvasSize = UDim2.new(0, 0, 0, 0)
                ScrollingFrame2.Visible = false

                UIListLayout.Parent = ScrollingFrame2
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Padding = UDim.new(0, 4)
                UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

                local function ValuesToTable(vals)
                    local a = {}
                    for i, _ in pairs(vals) do
                        if _ == true then
                            table.insert(a, i)
                        end
                    end
                    return a
                end

                local function TableToValues(vals)
                    local a = {}
                    for _, v in pairs(vals) do
                        a[v] = true
                    end
                    return a
                end

                local function DeepEqual(a, b)
                    if type(a) ~= type(b) then return false end
                    if type(a) ~= "table" then return a == b end
                    for k, v in pairs(a) do
                        if not DeepEqual(v, b[k]) then return false end
                    end
                    for k in pairs(b) do
                        if a[k] == nil then return false end
                    end
                    return true
                end

                if (SaveTable[Flag] or {}).CurrentOption and not DeepEqual(SaveTable[Flag].CurrentOption, Options) then
                    CurrentOption = SaveTable[Flag].CurrentOption
                    task.spawn(function()
                        Callback(CurrentOption,true)
                    end)
                end
                local Values = {}
                for i, v in pairs(Options) do
                    Values[v] = false
                end
                for i, v in pairs(CurrentOption) do
                    Values[v] = true
                end
                Window.Flags[Flag] = {CurrentOption = ValuesToTable(Values)}
                
                local Click = Instance.new("TextButton")
                Click.Parent = Dropdown
                Click.Text = ""
                Click.ZIndex = 2
                Click.BackgroundTransparency = 1
                Click.BorderSizePixel = 0
                Click.Size = UDim2.new(1, 0, 0, 32)
                
                local shadow
                if #Options > 3 then
                    shadow = addShadow(ScrollingFrame2)
                    shadow.Visible = false
                end
                
                local Opened = false
                Click.MouseButton1Click:Connect(function(input)
                    Opened = not Opened
                    if shadow then
                        shadow.Visible = Opened
                    end
                    ScrollingFrame2.Visible = Opened
                    if Opened then
                        local NewY = math.clamp(38 + (#Options * (28 + UIListLayout.Padding.Offset)), 0, 38 + (3 * (28 + UIListLayout.Padding.Offset)))
                        TweenService:Create(Dropdown, TweenInfo.new(0.3), {Size = UDim2.new(Dropdown.Size.X.Scale, Dropdown.Size.X.Offset, Dropdown.Size.Y.Scale, NewY)}):Play()
                    else
                        ScrollingFrame2.CanvasPosition = Vector2.new(0, 0)
                        TweenService:Create(Dropdown, TweenInfo.new(0.3), {Size = UDim2.new(Dropdown.Size.X.Scale, Dropdown.Size.X.Offset, Dropdown.Size.Y.Scale, 32)}):Play()
                    end
                end)
                
                local DropdownData = {
                    __DropdownOptions = {}
                }
                local function GetGoodstring(tbl)
                    local John = {}
                    
                    for i, v in pairs(tbl) do
                        if v == true then
                            table.insert(John, tostring(i))
                        end
                    end
                    
                    return #John == 1 and John[1] or ((#John == 0 and "no" or #John) .. " options")
                end
                
                function DropdownData:SetTitle(NewTitle)
                    Name = NewTitle
                    DropdownName.Text = Name .. " <font color=\"rgb(100, 100, 100)\">" .. GetGoodstring(Values) .. "</font>"
                end
                
                DropdownData:SetTitle(Name)
                            
                local function RefreshDropdown(List)
                    Options = List
                    for i, v in pairs(ScrollingFrame2:GetChildren()) do
                        if v.Name == "Option" then
                            v:Destroy()
                        end
                    end
                    for i, v in pairs(List) do
                        local Option = Instance.new("Frame")
                        local UICorner_2 = Instance.new("UICorner")
                        local OName = Instance.new("TextLabel")
                        local ONameShadow = Instance.new("TextLabel")
                        
                        Option.Name = "Option"
                        Option.Parent = ScrollingFrame2
                        Option.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                        Option.BackgroundTransparency = 0.800
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.BorderSizePixel = 0
                        Option.Size = UDim2.new(1, 0, 0, 28)
                        Option.ClipsDescendants = true

                        UICorner_2.CornerRadius = UDim.new(0, 5)
                        UICorner_2.Parent = Option

                        OName.Name = "OName"
                        OName.Parent = Option
                        OName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        OName.BackgroundTransparency = 1.000
                        OName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        OName.BorderSizePixel = 0
                        OName.Position = UDim2.new(0, 10, 0, 0)
                        OName.Size = UDim2.new(1, -20, 1, 0)
                        OName.ZIndex = 2
                        OName.Font = Enum.Font.ArialBold
                        OName.Text = tostring(v)
                        OName.TextColor3 = Color3.fromRGB(199, 199, 199)
                        OName.TextSize = 13.000
                        OName.TextXAlignment = Enum.TextXAlignment.Left

                        ONameShadow.Name = "ONameShadow"
                        ONameShadow.Parent = Option
                        ONameShadow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        ONameShadow.BackgroundTransparency = 1.000
                        ONameShadow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        ONameShadow.BorderSizePixel = 0
                        ONameShadow.Position = UDim2.new(0, 11, 0, 1)
                        ONameShadow.Size = UDim2.new(1, -20, 1, 0)
                        ONameShadow.Font = Enum.Font.ArialBold
                        ONameShadow.Text = tostring(v)
                        ONameShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
                        ONameShadow.TextSize = 13.000
                        ONameShadow.TextXAlignment = Enum.TextXAlignment.Left
                        
                        local Click = Instance.new("TextButton")
                        Click.Parent = Option
                        Click.Text = ""
                        Click.ZIndex = 2
                        Click.BackgroundTransparency = 1
                        Click.BorderSizePixel = 0
                        Click.Size = UDim2.fromScale(1, 1)
                        
                        table.insert(DropdownData.__DropdownOptions, {
                            Title = setmetatable({}, {
                                __newindex = function(a, b, c)
                                    if b == "Text" then
                                        OName.Text = c
                                        ONameShadow.Text = c
                                    end
                                end,
                            })
                        })
                        
                        local TInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
                        
                        Click.MouseButton1Click:Connect(function()
                            if Values[v] == true and not MultipleOptions then -- stop being able to unselect the selected option if multiple options if off, always have 1 selected
                                return
                            end
                            Values[v] = not Values[v]
                            if not MultipleOptions then
                                for e, b in pairs(Values) do
                                    if e ~= v then
                                        Values[e] = false
                                    end
                                end
                                for i, v in pairs(ScrollingFrame2:GetChildren()) do
                                    if v.Name == "Option" then
                                        TweenService:Create(v, TInfo, {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
                                        TweenService:Create(v.OName, TInfo, {TextColor3 = Color3.fromRGB(199, 199, 199)}):Play()
                                    end
                                end
                            end
                            if Values[v] then
                                TweenService:Create(Option, TInfo, {BackgroundColor3 = Color3.fromRGB(245, 159, 39)}):Play()
                                TweenService:Create(OName, TInfo, {TextColor3 = Color3.fromRGB(245, 159, 39)}):Play()
                            else
                                TweenService:Create(Option, TInfo, {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
                                TweenService:Create(OName, TInfo, {TextColor3 = Color3.fromRGB(199, 199, 199)}):Play()
                            end
                            
                            DropdownData:SetTitle(Name)
                            
                            Window.Flags[Flag] = {CurrentOption = ValuesToTable(Values)}
                            task.spawn(function()
                                Callback(ValuesToTable(Values))
                            end)
                        end)
                        
                        Click.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1
                                or input.UserInputType == Enum.UserInputType.Touch
                            then
                                local absPos = Option.AbsolutePosition
                                local localX = input.Position.X - absPos.X
                                local localY = input.Position.Y - absPos.Y
                                createRipple(Option, localX, localY)
                            end
                        end)
                        
                        if Values[v] then
                            Option.BackgroundColor3 = Color3.fromRGB(245, 159, 39)
                            OName.TextColor3 = Color3.fromRGB(245, 159, 39)
                        end
                    end
                end
                RefreshDropdown(Options)
                function DropdownData:Refresh(new)
                    RefreshDropdown(new)
                end
                
                return DropdownData
            end

            function Tab:CreateKeybind(Properties)
                local CurrentKeybind = Properties.CurrentKeybind
                local Name = Properties.Name
                local Callback = Properties.Callback or function() end
                table.insert(this.Features, Name)

                if Properties.Flag and SaveTable[Flag] then
                    CurrentKeybind = SaveTable[Flag]
                end

                local Keybind = Instance.new("Frame")
                local KeybindName = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local Frame = Instance.new("Frame")
                local UICorner_2 = Instance.new("UICorner")
                local TextLabel = Instance.new("TextButton")
                local ImageLabel = Instance.new("ImageLabel")
                Keybind.Name = "Keybind"
                Keybind.Parent = ScrollingFrame
                insertintosection(Keybind)
                Keybind.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Keybind.BackgroundTransparency = 0.450
                Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Keybind.BorderSizePixel = 0
                Keybind.ClipsDescendants = true
                Keybind.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)
                KeybindName.Name = "KeybindName"
                KeybindName.Parent = Keybind
                KeybindName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindName.BackgroundTransparency = 1.000
                KeybindName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                KeybindName.BorderSizePixel = 0
                KeybindName.Position = UDim2.new(0, 10, 0, 0)
                KeybindName.Size = UDim2.new(0.5, 0, 0, 32)
                KeybindName.Font = Enum.Font.ArialBold
                KeybindName.Text = Name
                KeybindName.TextColor3 = Color3.fromRGB(199, 199, 199)
                KeybindName.TextSize = 13.000
                KeybindName.TextXAlignment = Enum.TextXAlignment.Left
                addToolTip(KeybindName, Properties)
                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Keybind
                Frame.Parent = Keybind
                Frame.AnchorPoint = Vector2.new(1, 0)
                Frame.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
                Frame.BackgroundTransparency = 0.700
                Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Frame.BorderSizePixel = 0
                Frame.Position = UDim2.new(1, -4, 0, 4)
                Frame.Size = UDim2.new(0, 30, 0, 20)
                Frame.ClipsDescendants = true
                UICorner_2.CornerRadius = UDim.new(0, 5)
                UICorner_2.Parent = Frame
                TextLabel.Parent = Frame
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.BackgroundTransparency = 1.000
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BorderSizePixel = 0
                TextLabel.Size = UDim2.new(1, 0, 1, 0)
                TextLabel.Font = Enum.Font.ArialBold
                TextLabel.Text = CurrentKeybind or ""
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextSize = 14.000
                TextLabel.ClipsDescendants = true

                ImageLabel.Parent = Frame
                ImageLabel.AnchorPoint = Vector2.new(0.5, 0)
                ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ImageLabel.BackgroundTransparency = 1.000
                ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ImageLabel.BorderSizePixel = 0
                ImageLabel.Position = UDim2.new(0.5, 0, 0, 2)
                ImageLabel.Size = UDim2.new(0, 16, 0, 16)
                ImageLabel.Image = "rbxassetid://121142147574111"
                ImageLabel.Visible = false

                if CurrentKeybind == nil then
                    ImageLabel.Visible = true
                end

                local KeyInfo = {KeyCode = CurrentKeybind, Callback = Callback, Pressable = true}
                table.insert(Window.Keybinds, KeyInfo)

                local Debounce = false
                local Awaiting = false
                local PulseThread = nil

                local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tweenInfoBounce = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

                local function SetAwaiting()
                    -- Pulse color orange to indicate waiting
                    if PulseThread then task.cancel(PulseThread) end
                    TweenService:Create(Frame, tweenInfo, {BackgroundColor3 = Color3.fromRGB(160, 100, 15), BackgroundTransparency = 0.3}):Play()
                    TweenService:Create(TextLabel, tweenInfo, {TextColor3 = Color3.fromRGB(245, 159, 39)}):Play()
                    -- Pulsing loop
                    PulseThread = task.spawn(function()
                        while Awaiting do
                            TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.1}):Play()
                            task.wait(0.5)
                            TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.4}):Play()
                            task.wait(0.5)
                        end
                    end)
                end

                local function SetKeybind(keyName)
                    if PulseThread then task.cancel(PulseThread) PulseThread = nil end
                    TweenService:Create(Frame, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60, 180, 80), BackgroundTransparency = 0.2}):Play()
                    TweenService:Create(TextLabel, tweenInfo, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()

                    -- Set text first, then size to fit, then bounce
                    --TextLabel.Text = Replace[keyName] and tostring(Replace[keyName]) or keyName
                    task.wait() -- wait a frame for TextBounds to update
                    local targetWidth = math.max(30, TextLabel.TextBounds.X + 16)
                    local bigSize = UDim2.new(0, targetWidth + 8, 0, 24)
                    local normalSize = UDim2.new(0, targetWidth, 0, 20)

                    TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = bigSize}):Play()
                    task.delay(0.1, function()
                        TweenService:Create(Frame, tweenInfoBounce, {Size = normalSize}):Play()
                    end)
                    task.delay(0.4, function()
                        TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                            BackgroundColor3 = Color3.fromRGB(53, 53, 53), BackgroundTransparency = 0.700
                        }):Play()
                    end)
                end

                local function SetEmpty()
                    if PulseThread then task.cancel(PulseThread) PulseThread = nil end
                    TweenService:Create(Frame, tweenInfo, {BackgroundColor3 = Color3.fromRGB(53, 53, 53), BackgroundTransparency = 0.700}):Play()
                    TweenService:Create(TextLabel, tweenInfo, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                end

                TextLabel.MouseButton1Click:Connect(function()
                    if Debounce then return end
                    Debounce = true
                    KeyInfo.Pressable = false
                    ImageLabel.Visible = false
                    TextLabel.Text = "..."
                    Awaiting = true
                    SetAwaiting()
                    task.wait(0.1)
                    Debounce = false
                end)

                UserInputService.InputBegan:Connect(function(Input, Gpe)
                    if Unloaded then return end
                    if Gpe then return end
                    if Awaiting and Input.KeyCode.Name ~= "Unknown" then
                        local Previous = KeyInfo.KeyCode
                        KeyInfo.KeyCode = Input.KeyCode.Name
                        Awaiting = false
                        if Previous == KeyInfo.KeyCode then
                            KeyInfo.KeyCode = nil
                            ImageLabel.Visible = true
                            TextLabel.Text = ""
                            SetEmpty()
                            return
                        end
                        TextLabel.Text =  KeyInfo.KeyCode
                        SetKeybind(KeyInfo.KeyCode)
                    end
                    task.wait(0.1)
                    KeyInfo.Pressable = true
                end)
                
                local function UpdateFrameSize()
                    local textWidth = math.max(30, TextLabel.TextBounds.X + 16)
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, textWidth, 0, 20)
                    }):Play()
                end
                
                RunService.RenderStepped:Connect(UpdateFrameSize)
            end
            
            function Tab:CreateInput(Properties)
                local Name = Properties.Name
                local Flag = Properties.Flag
                local RemoveTextAfterFocusLost = Properties.RemoveTextAfterFocusLost
                local CurrentValue = Properties.CurrentValue
                local PlaceholderText = Properties.PlaceholderText
                local Callback = Properties.Callback or function() end
                table.insert(this.Features, Name)
                Window.Flags[Flag] = {CurrentValue = CurrentValue}
                
                local Input = Instance.new("Frame")
                local KeybindName = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local Frame = Instance.new("Frame")
                local UICorner_2 = Instance.new("UICorner")
                local TextLabel = Instance.new("TextLabel")
                local ImageLabel = Instance.new("ImageLabel")
                local TextBox = Instance.new("TextBox")

                Input.Name = "Input"
                Input.Parent = ScrollingFrame
                insertintosection(Input)
                Input.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Input.BackgroundTransparency = 0.450
                Input.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Input.BorderSizePixel = 0
                Input.ClipsDescendants = true
                Input.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)

                KeybindName.Name = "KeybindName"
                KeybindName.Parent = Input
                KeybindName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindName.BackgroundTransparency = 1.000
                KeybindName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                KeybindName.BorderSizePixel = 0
                KeybindName.Position = UDim2.new(0, 10, 0, 0)
                KeybindName.Size = UDim2.new(0.5, 0, 0, 32)
                KeybindName.Font = Enum.Font.ArialBold
                KeybindName.Text = Name
                KeybindName.TextColor3 = Color3.fromRGB(199, 199, 199)
                KeybindName.TextSize = 13.000
                KeybindName.TextXAlignment = Enum.TextXAlignment.Left
                addToolTip(KeybindName, Properties)

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Input

                Frame.Parent = Input
                Frame.AnchorPoint = Vector2.new(1, 0)
                Frame.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
                Frame.BackgroundTransparency = 0.700
                Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Frame.BorderSizePixel = 0
                Frame.ClipsDescendants = true
                Frame.Position = UDim2.new(1, -4, 0, 4)
                Frame.Size = UDim2.new(0, 0, 0, 20)

                UICorner_2.CornerRadius = UDim.new(0, 5)
                UICorner_2.Parent = Frame

                TextLabel.Parent = Frame
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.BackgroundTransparency = 1.000
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BorderSizePixel = 0
                TextLabel.Size = UDim2.new(1, 0, 1, 0)
                TextLabel.Font = Enum.Font.ArialBold
                TextLabel.Text = ""
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextSize = 14.000

                ImageLabel.Parent = Frame
                ImageLabel.AnchorPoint = Vector2.new(1, 0)
                ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ImageLabel.BackgroundTransparency = 1.000
                ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ImageLabel.BorderSizePixel = 0
                ImageLabel.Position = UDim2.new(1, -8, 0, 2)
                ImageLabel.Size = UDim2.new(0, 16, 0, 16)
                ImageLabel.Image = "rbxassetid://76137750753739"
                ImageLabel.ImageColor3 = Color3.fromRGB(255, 200, 110)

                TextBox.Parent = Frame
                TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextBox.BackgroundTransparency = 1.000
                TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextBox.BorderSizePixel = 0
                TextBox.ClipsDescendants = true
                TextBox.Position = UDim2.new(0, 7, 0, 0)
                TextBox.Size = UDim2.new(1, -40, 1, 0)
                TextBox.Font = Enum.Font.ArialBold
                TextBox.PlaceholderColor3 = Color3.fromRGB(127, 127, 127)
                TextBox.PlaceholderText = PlaceholderText or "Input Text"
                TextBox.Text = CurrentValue or ""
                TextBox.TextColor3 = Color3.fromRGB(255, 200, 110)
                TextBox.TextSize = 12.000
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                TextBox.ClearTextOnFocus = Properties.ClearTextOnFocus
                
                TextBox.FocusLost:Connect(function()
                    local Text = TextBox.Text
                    Window.Flags[Flag] = {CurrentValue = Text}
                    if Properties.RemoveTextAfterFocusLost then
                        TextBox.Text = ""
                    end
                    task.spawn(function()
                        Callback(Text)
                    end)
                end)

                if SaveTable[Flag] and not Properties.DontSave then
                    Window.Flags[Flag] = SaveTable[Flag]
                    TextBox.Text = tostring(SaveTable[Flag].CurrentValue)
                    task.spawn(function()
                        Callback(TextBox.Text, true)
                    end)
                end
                
                RunService.RenderStepped:Connect(function()
                    local textWidth = math.max(30, TextBox.TextBounds.X + 50)
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, math.clamp(textWidth, 0, 160), 0, 20)
                    }):Play()
                end)
            end
            
            function Tab:CreateColorPicker(Properties)
                local Name = Properties.Name
                local Color = Properties.Color -- default color
                local Flag = Properties.Flag
                local Callback = Properties.Callback or function() end
                Window.Flags[Flag] = {Color = Color}
                table.insert(this.Features, Name)
                
                local Colorpicker = Instance.new("Frame")
                local ColorpickerName = Instance.new("TextLabel")
                local UICorner = Instance.new("UICorner")
                local ColorIndicatorBackground = Instance.new("Frame")
                local UICorner_2 = Instance.new("UICorner")
                local ColorIndicator = Instance.new("Frame")
                local UICorner_3 = Instance.new("UICorner")
                local ColorSlider = Instance.new("Frame")
                local UIGradient = Instance.new("UIGradient")
                local UICorner_5 = Instance.new("UICorner")
                local Base = Instance.new("Frame")
                local UICorner_6 = Instance.new("UICorner")
                local UIGradient_2 = Instance.new("UIGradient")
                local Overlay = Instance.new("Frame")
                local UICorner_7 = Instance.new("UICorner")
                local UIGradient_3 = Instance.new("UIGradient")
                local HexValue = Instance.new("Frame")
                local UICorner_8 = Instance.new("UICorner")
                local HexValueText = Instance.new("TextBox")
                local FormatIndication = Instance.new("TextLabel")
                local RgbValue = Instance.new("Frame")
                local UICorner_9 = Instance.new("UICorner")
                local RgbValueText = Instance.new("TextBox")
                local FormatIndication_2 = Instance.new("TextLabel")
                local HsvValue = Instance.new("Frame")
                local UICorner_10 = Instance.new("UICorner")
                local HsvValueText = Instance.new("TextBox")
                local FormatIndication_3 = Instance.new("TextLabel")

                Colorpicker.Name = "Colorpicker"
                Colorpicker.Parent = ScrollingFrame
                insertintosection(Colorpicker)
                Colorpicker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Colorpicker.BackgroundTransparency = 0.450
                Colorpicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Colorpicker.BorderSizePixel = 0
                Colorpicker.ClipsDescendants = true
                Colorpicker.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)

                ColorpickerName.Name = "SliderName"
                ColorpickerName.Parent = Colorpicker
                ColorpickerName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ColorpickerName.BackgroundTransparency = 1.000
                ColorpickerName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ColorpickerName.BorderSizePixel = 0
                ColorpickerName.Position = UDim2.new(0, 10, 0, 0)
                ColorpickerName.Size = UDim2.new(0.5, 0, 0, 32)
                ColorpickerName.Font = Enum.Font.ArialBold
                ColorpickerName.Text = Name
                ColorpickerName.TextColor3 = Color3.fromRGB(199, 199, 199)
                ColorpickerName.TextSize = 13.000
                ColorpickerName.TextXAlignment = Enum.TextXAlignment.Left
                addToolTip(ColorpickerName, Properties)

                UICorner.CornerRadius = UDim.new(0, 5)
                UICorner.Parent = Colorpicker

                ColorIndicatorBackground.Name = "ColorIndicatorBackground"
                ColorIndicatorBackground.Parent = Colorpicker
                ColorIndicatorBackground.AnchorPoint = Vector2.new(1, 0.5)
                ColorIndicatorBackground.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                ColorIndicatorBackground.BackgroundTransparency = 0.300
                ColorIndicatorBackground.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ColorIndicatorBackground.BorderSizePixel = 0
                ColorIndicatorBackground.Position = UDim2.new(1, -4, 0, 16)
                ColorIndicatorBackground.Size = UDim2.new(0, 50, 0, 20)

                UICorner_2.CornerRadius = UDim.new(0, 5)
                UICorner_2.Parent = ColorIndicatorBackground

                ColorIndicator.Name = "ColorIndicator"
                ColorIndicator.Parent = Colorpicker
                ColorIndicator.AnchorPoint = Vector2.new(1, 0.5)
                ColorIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                ColorIndicator.BorderColor3 = Color3.fromRGB(0, 0, 0)
                ColorIndicator.BorderSizePixel = 0
                ColorIndicator.Position = UDim2.new(1, -6, 0, 16)
                ColorIndicator.Size = UDim2.new(0, 46, 0, 16)

                UICorner_3.CornerRadius = UDim.new(0, 4)
                UICorner_3.Parent = ColorIndicator

                ColorSlider.Name = "ColorSlider"
                ColorSlider.Parent = Colorpicker
                ColorSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ColorSlider.BorderColor3 = Color3.fromRGB(27, 42, 53)
                ColorSlider.ClipsDescendants = true
                ColorSlider.Position = UDim2.new(0, 10, 0, 120)
                ColorSlider.Size = UDim2.new(0, 173, 0, 12)

                UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.06, Color3.fromRGB(255, 85, 0)), ColorSequenceKeypoint.new(0.11, Color3.fromRGB(255, 170, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(254, 255, 0)), ColorSequenceKeypoint.new(0.22, Color3.fromRGB(169, 255, 0)), ColorSequenceKeypoint.new(0.28, Color3.fromRGB(83, 255, 0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 1)), ColorSequenceKeypoint.new(0.39, Color3.fromRGB(0, 255, 86)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(0, 255, 171)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 252, 255)), ColorSequenceKeypoint.new(0.56, Color3.fromRGB(0, 167, 255)), ColorSequenceKeypoint.new(0.61, Color3.fromRGB(0, 82, 255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(2, 0, 255)), ColorSequenceKeypoint.new(0.72, Color3.fromRGB(88, 0, 255)), ColorSequenceKeypoint.new(0.78, Color3.fromRGB(173, 0, 255)), ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 0, 251)), ColorSequenceKeypoint.new(0.89, Color3.fromRGB(255, 0, 166)), ColorSequenceKeypoint.new(0.95, Color3.fromRGB(255, 0, 80)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))}
                UIGradient.Parent = ColorSlider

                UICorner_5.CornerRadius = UDim.new(0, 6)
                UICorner_5.Parent = ColorSlider

                Base.Name = "Base"
                Base.Parent = Colorpicker
                Base.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Base.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Base.BorderSizePixel = 0
                Base.Position = UDim2.new(0, 10, 0, 33)
                Base.Size = UDim2.new(0, 173, 0, 80)

                UICorner_6.CornerRadius = UDim.new(0, 6)
                UICorner_6.Parent = Base
                
                local HueThumb                = Instance.new("Frame")
                local HueThumbCorner          = Instance.new("UICorner")
                
                HueThumb.Name               = "HueThumb"
                HueThumb.Parent             = ColorSlider
                HueThumb.AnchorPoint        = Vector2.new(0.5, 0.5)
                HueThumb.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
                HueThumb.BorderSizePixel    = 0
                HueThumb.Size               = UDim2.new(0, 6, 0, 6)
                HueThumb.ZIndex             = 10
                HueThumb.ClipsDescendants   = false

                HueThumbCorner.CornerRadius = UDim.new(1, 0)
                HueThumbCorner.Parent       = HueThumb
                
                local Stroke = Instance.new("UIStroke", HueThumb)
                Stroke.Color = Color3.fromRGB(0, 0, 0)
                Stroke.Thickness = 1
                
                local ColorThumb                = Instance.new("Frame")
                local ColorThumbCorner          = Instance.new("UICorner")

                ColorThumb.Name               = "ColorThumb"
                ColorThumb.Parent             = Overlay
                ColorThumb.AnchorPoint        = Vector2.new(0.5, 0.5)
                ColorThumb.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
                ColorThumb.BorderColor3       = Color3.fromRGB(0, 0, 0)
                ColorThumb.BorderSizePixel    = 0
                ColorThumb.Size               = UDim2.fromOffset(6, 6)
                ColorThumb.ZIndex             = 10
                ColorThumb.ClipsDescendants   = false

                ColorThumbCorner.CornerRadius = UDim.new(1, 0)
                ColorThumbCorner.Parent       = ColorThumb
                
                local Stroke = Instance.new("UIStroke", ColorThumb)
                Stroke.Color = Color3.fromRGB(0, 0, 0)
                Stroke.Thickness = 1
                
                local function OnHTDrag(inputX)
                    local barPos = ColorSlider.AbsolutePosition.X
                    local barSize = ColorSlider.AbsoluteSize.X
                    local alpha = math.clamp((inputX - barPos) / barSize, 0, 1)
                    return alpha
                end

                local function OnCTDrag(inputX, inputY)
                    local barPos = Overlay.AbsolutePosition.X
                    local barSize = Overlay.AbsoluteSize.X
                    local x = math.clamp((inputX - barPos) / barSize, 0, 1)
                    local barPos = Overlay.AbsolutePosition.Y
                    local barSize = Overlay.AbsoluteSize.Y
                    local y = math.clamp((inputY - barPos) / barSize, 0, 1)
                    return x, y
                end


                local HueThumbPos

                local H, S, V = Color:ToHSV()
                ColorThumb.Position = UDim2.fromScale(1-V, 1-S)
                S = 1
                V = 1
                UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(H, S, V))}
                UIGradient_2.Rotation = 270
                UIGradient_2.Parent = Base
                
                HueThumbPos = H
                HueThumb.Position = UDim2.fromScale(H, 0.5)
                
                local OldHex
                local OldRgb
                local OldHsv
                
                local function UpdateEverything(InputX, InputY, X, Y, CallbackYes)
                    if not (X and Y) then 
                        X, Y = OnCTDrag(InputX, InputY)
                    end
                    TweenService:Create(ColorThumb, TweenInfo.new(0.1), {Position = UDim2.fromScale(X, Y)}):Play()
                    local RealColor = Color3.fromHSV(HueThumbPos, 1-Y, 1-X)
                    ColorIndicatorBackground.BackgroundColor3 = RealColor
                    ColorIndicator.BackgroundColor3 = RealColor
                    local ColorStr = tostring(RealColor)
                    HsvValueText.Text = string.format("%s, %s, %s", 
                        math.floor(tonumber(ColorStr:split(", ")[1]) * 360),
                        math.floor(tonumber(ColorStr:split(", ")[2]) * 255),
                        math.floor(tonumber(ColorStr:split(", ")[3]) * 255)
                    )
                    local R, G, B = math.floor((RealColor.R*255)+0.5),math.floor((RealColor.G*255)+0.5),math.floor((RealColor.B*255)+0.5)
                    RgbValueText.Text = string.format("%s, %s, %s", R, G, B)
                    HexValueText.Text = string.format("#%02x%02x%02x", R, G, B)
                    OldHex = HexValueText.Text
                    OldRgb = RgbValueText.Text
                    OldHsv = HsvValueText.Text
                    Window.Flags[Flag] = {Color = RealColor}
                    
                    if not CallbackYes then
                        task.spawn(function()
                            Callback(RealColor)
                        end)
                    end
                end
                
                local DraggingHueThumb = false
                local DraggingColorThumb = false
                local HueThumbDragInput
                local ColorThumbbDragInput
                ColorSlider.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DraggingHueThumb = true
                        HueThumbDragInput = Input
                        while DraggingHueThumb and task.wait() do
                            local P = OnHTDrag(HueThumbDragInput.Position.X)
                            HueThumbPos = P
                            TweenService:Create(HueThumb, TweenInfo.new(0.1), {Position = UDim2.fromScale(P, 0.5)}):Play()
                            local CLR = Color3.fromHSV(P, 1, 1)
                            UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, CLR)}
                            UpdateEverything(nil, nil, ColorThumb.Position.X.Scale, ColorThumb.Position.Y.Scale)
                        end
                    end
                end)
                ColorSlider.InputChanged:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                        HueThumbDragInput = Input
                    end
                end)
                
                ColorSlider.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DraggingHueThumb = false
                    end
                end)
                
                UpdateEverything(nil, nil, ColorThumb.Position.X.Scale, ColorThumb.Position.Y.Scale, true)
                
                Overlay.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DraggingColorThumb = true
                        ColorThumbbDragInput = Input
                        while DraggingColorThumb and task.wait() do
                            UpdateEverything(ColorThumbbDragInput.Position.X, ColorThumbbDragInput.Position.Y)
                        end
                    end
                end)
                Overlay.InputChanged:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                        ColorThumbbDragInput = Input
                    end
                end)

                Overlay.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        DraggingColorThumb = false
                    end
                end)

                Overlay.Name = "Overlay"
                Overlay.Parent = Colorpicker
                Overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Overlay.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Overlay.BorderSizePixel = 0
                Overlay.Position = UDim2.new(0, 10, 0, 33)
                Overlay.Size = UDim2.new(0, 173, 0, 80)

                UICorner_7.CornerRadius = UDim.new(0, 6)
                UICorner_7.Parent = Overlay

                UIGradient_3.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))}
                UIGradient_3.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)}
                UIGradient_3.Parent = Overlay

                HexValue.Name = "HexValue"
                HexValue.Parent = Colorpicker
                HexValue.AnchorPoint = Vector2.new(1, 1)
                HexValue.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                HexValue.BackgroundTransparency = 0.500
                HexValue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                HexValue.BorderSizePixel = 0
                HexValue.Position = UDim2.new(1, -10, 1, -10)
                HexValue.Size = UDim2.new(0, 100, 0, 26)

                UICorner_8.Parent = HexValue

                HexValueText.Name = "HexValueText"
                HexValueText.Parent = HexValue
                HexValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HexValueText.BackgroundTransparency = 1.000
                HexValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                HexValueText.BorderSizePixel = 0
                HexValueText.Size = UDim2.new(1, 0, 1, 0)
                HexValueText.Font = Enum.Font.ArialBold
                HexValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
                HexValueText.TextSize = 14.000
                HexValueText.ClearTextOnFocus = false
                HexValueText.FocusLost:Connect(function()
                    local text = HexValueText.Text
                    if text:sub(1, 1) == "#" then
                        text = text:sub(2)
                    end
                    if not text:match("%x+%x+%x+") then
                        HexValueText.Text = OldHex
                        return
                    end
                    local seg1 = text:sub(1, 2)
                    local seg2 = text:sub(3, 4)
                    local seg3 = text:sub(5, 6)
                    local r, g, b = tonumber(seg1, 16), tonumber(seg2, 16), tonumber(seg3, 16)
                    local h, s, v = Color3.fromRGB(r, g, b):ToHSV()
                    HueThumbPos = h
                    TweenService:Create(HueThumb, TweenInfo.new(0.1), {Position = UDim2.fromScale(h, 0.5)}):Play()
                    UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(h, 1, 1))}
                    UpdateEverything(nil, nil, 1-v, 1-s)
                end)

                FormatIndication.Name = "FormatIndication"
                FormatIndication.Parent = HexValue
                FormatIndication.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                FormatIndication.BackgroundTransparency = 1.000
                FormatIndication.BorderColor3 = Color3.fromRGB(0, 0, 0)
                FormatIndication.BorderSizePixel = 0
                FormatIndication.Position = UDim2.new(-1, -7, 0, 0)
                FormatIndication.Size = UDim2.new(1, 0, 1, 0)
                FormatIndication.Font = Enum.Font.ArialBold
                FormatIndication.Text = "HEX"
                FormatIndication.TextColor3 = Color3.fromRGB(141, 141, 141)
                FormatIndication.TextSize = 14.000
                FormatIndication.TextWrapped = true
                FormatIndication.TextXAlignment = Enum.TextXAlignment.Right

                RgbValue.Name = "RgbValue"
                RgbValue.Parent = Colorpicker
                RgbValue.AnchorPoint = Vector2.new(1, 1)
                RgbValue.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                RgbValue.BackgroundTransparency = 0.500
                RgbValue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                RgbValue.BorderSizePixel = 0
                RgbValue.Position = UDim2.new(1, -10, 1, -40)
                RgbValue.Size = UDim2.new(0, 100, 0, 26)

                UICorner_9.Parent = RgbValue

                RgbValueText.Name = "RgbValueText"
                RgbValueText.Parent = RgbValue
                RgbValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                RgbValueText.BackgroundTransparency = 1.000
                RgbValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                RgbValueText.BorderSizePixel = 0
                RgbValueText.Size = UDim2.new(1, 0, 1, 0)
                RgbValueText.Font = Enum.Font.ArialBold
                RgbValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
                RgbValueText.TextSize = 14.000
                RgbValueText.ClearTextOnFocus = false
                RgbValueText.FocusLost:Connect(function()
                    local text = RgbValueText.Text
                    text = text:gsub(" ", "")
                    if not text:match("%d+,%d+,%d+") then
                        RgbValueText.Text = OldRgb
                        return
                    end
                    local seg1 = text:split(",")[1]
                    local seg2 = text:split(",")[2]
                    local seg3 = text:split(",")[3]
                    local r, g, b = tonumber(seg1), tonumber(seg2), tonumber(seg3)
                    if not (r and g and b) then
                        RgbValueText.Text = OldRgb
                        return
                    end
                    if (r < 0 or r > 255) or (g < 0 or g > 255) or (b < 0 or b > 255) then
                        RgbValueText.Text = OldRgb
                        return
                    end
                    local h, s, v = Color3.fromRGB(r, g, b):ToHSV()
                    HueThumbPos = h
                    TweenService:Create(HueThumb, TweenInfo.new(0.1), {Position = UDim2.fromScale(h, 0.5)}):Play()
                    UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(h, 1, 1))}
                    UpdateEverything(nil, nil, 1-v, 1-s)
                end)

                FormatIndication_2.Name = "FormatIndication"
                FormatIndication_2.Parent = RgbValue
                FormatIndication_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                FormatIndication_2.BackgroundTransparency = 1.000
                FormatIndication_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                FormatIndication_2.BorderSizePixel = 0
                FormatIndication_2.Position = UDim2.new(-1, -7, 0, 0)
                FormatIndication_2.Size = UDim2.new(1, 0, 1, 0)
                FormatIndication_2.Font = Enum.Font.ArialBold
                FormatIndication_2.Text = "RGB"
                FormatIndication_2.TextColor3 = Color3.fromRGB(141, 141, 141)
                FormatIndication_2.TextSize = 14.000
                FormatIndication_2.TextWrapped = true
                FormatIndication_2.TextXAlignment = Enum.TextXAlignment.Right

                HsvValue.Name = "HsvValue"
                HsvValue.Parent = Colorpicker
                HsvValue.AnchorPoint = Vector2.new(1, 1)
                HsvValue.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                HsvValue.BackgroundTransparency = 0.500
                HsvValue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                HsvValue.BorderSizePixel = 0
                HsvValue.Position = UDim2.new(1, -10, 1, -70)
                HsvValue.Size = UDim2.new(0, 100, 0, 26)

                UICorner_10.Parent = HsvValue

                HsvValueText.Name = "HsvValueText"
                HsvValueText.Parent = HsvValue
                HsvValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HsvValueText.BackgroundTransparency = 1.000
                HsvValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                HsvValueText.BorderSizePixel = 0
                HsvValueText.Size = UDim2.new(1, 0, 1, 0)
                HsvValueText.Font = Enum.Font.ArialBold
                HsvValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
                HsvValueText.TextSize = 14.000
                HsvValueText.FocusLost:Connect(function()
                    local text = HsvValueText.Text
                    text = text:gsub(" ", "")
                    if not text:match("%d+,%d+,%d+") then
                        HsvValueText.Text = OldRgb
                        return
                    end
                    local seg1 = text:split(",")[1]
                    local seg2 = text:split(",")[2]
                    local seg3 = text:split(",")[3]
                    local h, s, v = tonumber(seg1), tonumber(seg2), tonumber(seg3)
                    if not (h and s and v) then
                        HsvValueText.Text = OldRgb
                        return
                    end
                    if (h < 0 or h > 360) or (s < 0 or s > 255) or (v < 0 or v > 255) then
                        HsvValueText.Text = OldRgb
                        return
                    end
                    h, s, v = h / 360, s / 255, v / 255
                    h, s, v = Color3.fromHSV(h, s, v):ToHSV()
                    print(h, s, v)
                    HueThumbPos = h
                    TweenService:Create(HueThumb, TweenInfo.new(0.1), {Position = UDim2.fromScale(h, 0.5)}):Play()
                    UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(h, 1, 1))}
                    UpdateEverything(nil, nil, 1-v, 1-s)
                end)


                FormatIndication_3.Name = "FormatIndication"
                FormatIndication_3.Parent = HsvValue
                FormatIndication_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                FormatIndication_3.BackgroundTransparency = 1.000
                FormatIndication_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
                FormatIndication_3.BorderSizePixel = 0
                FormatIndication_3.Position = UDim2.new(-1, -7, 0, 0)
                FormatIndication_3.Size = UDim2.new(1, 0, 1, 0)
                FormatIndication_3.Font = Enum.Font.ArialBold
                FormatIndication_3.Text = "HSV"
                FormatIndication_3.TextColor3 = Color3.fromRGB(141, 141, 141)
                FormatIndication_3.TextSize = 14.000
                FormatIndication_3.TextWrapped = true
                FormatIndication_3.TextXAlignment = Enum.TextXAlignment.Right
                
                local Click = Instance.new("TextButton")
                Click.Parent = Colorpicker
                Click.Text = ""
                Click.ZIndex = 2
                Click.BackgroundTransparency = 1
                Click.BorderSizePixel = 0
                Click.Size = UDim2.new(1, 0, 0, 32)
                
                local IsOpen = false
                local function Collapse()
                    Colorpicker.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 32)
                    HexValue.Visible = false
                    RgbValue.Visible = false
                    HsvValue.Visible = false
                    ColorSlider.Visible = false
                    Overlay.Visible = false
                    Base.Visible = false
                end
                local function Open()
                    Colorpicker.Size = UDim2.new(1, -((IsMobile or _G.SINGLE_COLUMNS) and 29 or 10), 0, 140)
                    HexValue.Visible = true
                    RgbValue.Visible = true
                    HsvValue.Visible = true
                    ColorSlider.Visible = true
                    Overlay.Visible = true
                    Base.Visible = true
                end
                
                Click.MouseButton1Click:Connect(function()
                    IsOpen = not IsOpen
                    if not IsOpen then
                        Collapse()
                    else
                        Open()
                    end
                end)
                
                Collapse()
                
            end

            function Tab:CreateDivider()
                local space = Instance.new("Frame")
                space.Parent = ScrollingFrame
                insertintosection(space)
                space.BackgroundTransparency = 1
                space.Size = UDim2.new(1, 0, 0, 18)
                space.ClipsDescendants = true
                local bar = Instance.new("Frame")
                bar.Parent = space
                bar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                bar.Size = UDim2.new(1, -4, 0, 1)
                bar.Position = UDim2.new(0.5, -2, 0.5, 0)
                bar.AnchorPoint = Vector2.new(0.5, 0.5)
                bar.BorderSizePixel = 0
                bar.BackgroundTransparency = 0.5
            end
            
            return Tab
        end
        
        Window.Keybinds = {}
        UserInputService.InputBegan:Connect(function(Input, Gpe)
            if (Unloaded) then return end
            if Gpe then return end
            for i, v in pairs(Window.Keybinds) do
                if v.Pressable and v.KeyCode and Input.KeyCode == Enum.KeyCode[v.KeyCode] then
                    v.Callback()
                end
            end
        end)
        
        function Window:SelectTab(Num)
            for i,v in pairs(TabStore) do
                if v ~= TabStore[Num] then
                    v.IsSelected = false
                    v.Deselect()
                end
            end
            TabStore[Num].IsSelected = true
            TabStore[Num].Select()
        end
        
        Window.Flags = setmetatable({}, {
            __index = function(t, k)
                if not rawget(t, k) then
                    --warn("flag", k, "not yet created, but you accessed it")
                    return {
                        CurrentValue = false,
                        Color = Color3.fromRGB(0, 0, 0),
                        CurrentOption = {}
                    }
                end
                return rawget(t, k)
            end
        })
        Library.__Window__ = MainFrame

        return Window
    end

    function Library:Destroy()
        pcall(function()
            Library.__Window__.Parent:Destroy()
        end)
    end

    return Library
end)()
