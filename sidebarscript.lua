
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local TableUtils = require(ReplicatedStorage.Modules.Utilities.TableUtils);

local RealScreens = {}
for i, v in ipairs(LocalPlayer.PlayerGui.MainUI:GetChildren()) do
    if not table.find({'SettingsScreen', 'AchievementsScreen', 'ShopScreen', 'InventoryScreen', 'StatsScreen', 'Spectate'}, v.Name) then continue end
    RealScreens[#RealScreens+1]={v,v.Parent}
    v.Parent = ReplicatedStorage
end
ReplicatedStorage.Systems.Player.UI.Menus.Parent = ReplicatedStorage
LocalPlayer.PlayerGui.MainUI.Sidebar.Parent = ReplicatedStorage
LocalPlayer.PlayerGui.MainUI.AFKLabel:Destroy()
local print = function()end
local warn = function()end
local obj = game:GetObjects("rbxassetid://71002825519760")[1]
obj.Parent = game.Players.LocalPlayer.PlayerGui.MainUI
obj.Name = 'Sidebar'
local data = game:HttpGet("https://github.com/aibabylaugh/catsaken/raw/main/menus4.rbxm")
writefile("Catsaken/menus.rbxm", data)
local menus_folder = game:GetObjects(getcustomasset("Catsaken/menus.rbxm"))[1]
menus_folder.Name = 'Menus'
menus_folder.Parent = ReplicatedStorage.Systems.Player.UI

local SidebarHandler = {
    SidebarMenus = {},
    SidebarButtons = {},
    PendingSidebarMenus = {},
    onTransitionState = Signal.new(),
    onMenuSwitched = Signal.new(),
    Sidebar = LocalPlayer.PlayerGui.MainUI.Sidebar,
}
SidebarHandler.Bottombar = SidebarHandler.Sidebar.Bottombar
SidebarHandler.Bottombar.Buttons.Credits:Destroy()
SidebarHandler.__index = SidebarHandler

local function disabled_oldmenu()
    for i, v in ipairs(LocalPlayer.PlayerGui.MainUI:GetChildren()) do
        if not table.find({'SettingsScreen', 'AchievementsScreen', 'ShopScreen', 'InventoryScreen', 'Spectate'}, v.Name) then continue end
        RealScreens[#RealScreens+1]={v,v.Parent}
        v.Parent = ReplicatedStorage
    end
    for i = 1, #RealScreens do
        local v = RealScreens[i]
        v[1].Parent = v[2]
    end
    game:GetService("ReplicatedStorage").Menus.Parent = game:GetService("ReplicatedStorage").Systems.Player.UI
    game:GetService("ReplicatedStorage").Sidebar.Parent = game.Players.LocalPlayer.PlayerGui.MainUI
    SidebarHandler.Sidebar.Parent = game:GetService("ReplicatedStorage")
    menus_folder.Parent = game:GetService("ReplicatedStorage")
end

function SidebarHandler.Stop(self)
    warn('Deleting old menu script')
    disabled_oldmenu()
    warn('ok')
end

local DataHandler = require(ReplicatedStorage.Modules.Data.DataHandler)
local Sounds = require(ReplicatedStorage.Modules.Rendering.Sounds)
local Signal = require(ReplicatedStorage.Modules.Utilities.Signal)
local Util = require(ReplicatedStorage.Modules.Utilities.Util)
local Achievements = LocalPlayer:WaitForChild("PlayerData"):WaitForChild("Achievements");
local Achievements2 = require(ReplicatedStorage.Modules.Schematics.Achievements);

local MenuTweenInfo = TweenInfo.new(0.25)

local function getMenuModule(name)
    return nil
end

local Menu = {}
Menu.__index = Menu

function Menu.new(menuName, template)
    print(`Menu.new({menuName}, {template})`)
    local self = setmetatable({}, Menu)
    self.Menu = template:Clone()
    self.Toggled = Signal.new()
    self.Button = nil
    self.MenuName = menuName
    self.Menu.Visible = false
    self.Menu.Size = UDim2.fromScale()
    self.Menu.Parent = LocalPlayer.PlayerGui.MainUI

    for _, descendant in self.Menu:GetDescendants() do
        if descendant:IsA("ScrollingFrame") then
            descendant:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                descendant.ScrollBarThickness = descendant.AbsoluteSize.X / 44
            end)
        end
    end

    return self
end

function Menu.ToggleMenu(self, forceClose)
    print(`Menu.ToggleMenu({self}, {forceClose})`)
    local sidebar = self._sidebar

    if sidebar.TogglingMenus then
        return
    end

    if sidebar.MenusHidden and self.SidebarButton then
        return
    end

    if forceClose and self.Menu.Visible then
        return
    end

    sidebar.TogglingMenus = true
    local wasVisible = self.Menu.Visible
    Sounds:Play("select")
    local otherOpen = nil

    for _, v in sidebar.SidebarMenus do
        if v.Menu ~= self.Menu or wasVisible then
            if v.Menu ~= self.Menu and v.Menu.Visible then
                otherOpen = v
            end

            if v.Menu.Visible then
                v.Toggled:Fire(false)
                TweenService:Create(v.Menu, MenuTweenInfo, {
                    Size = UDim2.new(1, -20, 0, 0)
                }):Play()
                task.delay(0.25, function()
                    v.Menu.Visible = false
                end)

                if v.Button then
                    v.Button:SetAppearanceState(false)
                end
            end
        end
    end

    task.delay(0.3 + (otherOpen and 0.125 or 0), function()
        sidebar.TogglingMenus = nil
    end)

    if otherOpen then
        task.wait(0.125)

        if sidebar.MenusHidden then
            sidebar.TogglingMenus = nil
            return
        end
    end

    print(`wasVisible = {wasVisible}`)
    if not wasVisible then
        self.Toggled:Fire(true)
        local success, result = pcall(require, getMenuModule(self.MenuName))
        print(`local success, result = {success}, {result}\nresult.OnTransitionState = {result.OnTransitionState}`)

        if success and result and result.OnTransitionState then
            result.OnTransitionState(true)
        else
            self.Menu.Visible = true
            TweenService:Create(self.Menu, MenuTweenInfo, {
                Size = UDim2.new(1, -20, 1, -20)
            }):Play()
        end

        if self.Button then
            self.Button:SetAppearanceState(true)
        end
    end
end

local ButtonObj = {}
ButtonObj.__index = ButtonObj

function ButtonObj.new(ButtonFrame)
    print(`ButtonObj.new({ButtonFrame})`)
    local self = setmetatable({}, ButtonObj)
    self.Frame = ButtonFrame
    self.onClick = Signal.new()

    local isbottom = ButtonFrame.Parent.Parent.Name == 'Bottombar'
    local PulloutHolder = (not isbottom) and ButtonFrame.PulloutHolder or SidebarHandler.Bottombar.Pullouts.BottomPulloutHolder
    local OldPullout = PulloutHolder
    PulloutHolder = PulloutHolder:Clone()
    PulloutHolder.Parent = isbottom and PulloutHolder.Parent or ButtonFrame
    OldPullout:Destroy()

    local PulloutFrame = PulloutHolder.PulloutFrame
    PulloutFrame.Title.Text = ButtonFrame.Name
    PulloutFrame.Title.TextScaled = false
    PulloutFrame.Title.TextWrap = false
    PulloutFrame.Title.TextWrapped = false

    if isbottom then
        PulloutHolder:Destroy()
    end

    ButtonFrame.Button.MouseButton1Click:Connect(function()
        self.onClick:Fire()
    end)

    ButtonFrame.MouseEnter:Connect(function()
        if ButtonFrame.Button.ImageTransparency <= 0.1 then
            TweenService:Create(ButtonFrame, MenuTweenInfo, {
                Size = UDim2.fromScale(1.05, isbottom and 1.15 or 0.25)
            }):Play()
            if not isbottom then
                TweenService:Create(PulloutFrame, MenuTweenInfo, {
                    Position = UDim2.new(0.225, PulloutFrame.Title.TextBounds.X, 0.5, 0)
                }):Play()

                Sounds:Play("hover")
            end
        end
    end)

    ButtonFrame.MouseLeave:Connect(function()
        game.TweenService:Create(ButtonFrame, MenuTweenInfo, {
            Size = UDim2.fromScale(1, isbottom and 1 or 0.2)
        }):Play();

        if not isbottom then
            game.TweenService:Create(PulloutFrame, MenuTweenInfo, {
                Position = UDim2.fromScale(0, 0.5)
            }):Play();
        end;
    end)

    return self
end

function ButtonObj.SetAppearanceState(self, active)
    local f = self.Frame
    local t = active and 0 or 1
    print(`ButtonObj.SetAppearanceState({self}, {active}) | {f}`)
    local PulloutHolder = f:FindFirstChild('PulloutHolder')
    if not PulloutHolder then return end
    TweenService:Create(f.Inverted, MenuTweenInfo, {ImageTransparency = t}):Play()
    TweenService:Create(f.InvertedIcon, MenuTweenInfo, {ImageTransparency = t}):Play()
    TweenService:Create(PulloutHolder.PulloutFrame.Inverted, MenuTweenInfo, {ImageTransparency = t}):Play()
    TweenService:Create(PulloutHolder.PulloutFrame.Title, MenuTweenInfo, {
        TextColor3 = active and Color3.new() or Color3.new(1, 1, 1)
    }):Play()
end

function ButtonObj.RegisterMenu(self, menu) end

local function registerSidebarMenuButton(name, menu)
    local button = SidebarHandler.SidebarButtons[name]

    if not button then
        SidebarHandler.PendingSidebarMenus[name] = menu
        print(`SidebarHandler.PendingSidebarMenus[{name}] = {menu}`)
        return false
    end

    button.onClick:Connect(function()
        print(`button.onClick() | {name}`)
        SidebarHandler.onMenuSwitched:Fire(name)
    end)

    local success, result = pcall(function()
        button:RegisterMenu(menu)
    end)

    if not success then
        warn(`[SidebarHandler]: Failed to register sidebar menu '{name}' to its button: {result}`)
        return false
    end

    menu.Button = button
    SidebarHandler.PendingSidebarMenus[name] = nil

    return true
end

function SidebarHandler.CreateSidebarMenu(self, menuName, template, isbutton)
    print(`SidebarHandler.CreateSidebarMenu({self}, {menuName}, {template})`)
    local menu = Menu.new(menuName, template)
    menu._sidebar = self
    menu.SidebarButton = SidebarHandler[isbutton and "Bottombar" or "Sidebar"].Buttons:FindFirstChild(menuName);
    SidebarHandler.SidebarMenus[menuName] = menu
    registerSidebarMenuButton(menuName, menu)
    print("CreateSidebarMenu", menuName)
    return menu
end

function SidebarHandler.ToggleButtons(self, state)
    print(`SidebarHandler.ToggleButtons({self}, {state})`)
    SidebarHandler.onTransitionState:Fire(state)

    for _, v in SidebarHandler.SidebarMenus do
        local success, result = pcall(require, getMenuModule(v.MenuName))

        if success and result and result.OnTransitionState then
            result.OnTransitionState(false)
        else
            TweenService:Create(v.Menu, MenuTweenInfo, {
                Size = UDim2.new(1, -20, 0, 0)
            }):Play()
            task.delay(0.25, function()
                v.Menu.Visible = false
            end)
        end

        if v.Button then
            v.Button:SetAppearanceState(false)
        end

        task.delay(0.25, function()
            v.Menu.Visible = false
        end)
    end
end

function SidebarHandler.ToggleSidebarButtons(self, show)
    print(`SidebarHandler.ToggleSidebarButtons({self}, {show})`)
    SidebarHandler.MenusHidden = not show
    SidebarHandler.Sidebar.Visible = show

    if show then
        return
    end

    SidebarHandler:ToggleButtons(show)
end

function SidebarHandler.Start(self)
    print(`SidebarHandler.Start({self})`)
    local MainUI = LocalPlayer.PlayerGui:WaitForChild("MainUI")
    SidebarHandler.Sidebar.Parent = MainUI
    Util:CreateMoneyDisplay(SidebarHandler.Sidebar.Money)

    for _, ButtonFrame in pairs(TableUtils.Extend(SidebarHandler.Sidebar.Buttons:GetChildren(), SidebarHandler.Bottombar.Buttons:GetChildren())) do
        if ButtonFrame:IsA("Frame") then
            local btn = ButtonObj.new(ButtonFrame)
            SidebarHandler.SidebarButtons[ButtonFrame.Name] = btn
            btn.onClick:Connect(function()
                print(`btn.onClick() | {ButtonFrame.Name}`)
                SidebarHandler.onMenuSwitched:Fire(ButtonFrame.Name)
                local m = SidebarHandler.SidebarMenus[ButtonFrame.Name]
                if m then m:ToggleMenu() end
            end)

            local pending = SidebarHandler.PendingSidebarMenus[ButtonFrame.Name]
            if pending then
                registerSidebarMenuButton(ButtonFrame.Name, pending)
            end
        end
    end

    for name in SidebarHandler.PendingSidebarMenus do
        if not SidebarHandler.SidebarButtons[name] then
            warn(`[SidebarHandler]: Sidebar menu '{name}' has no matching button.`)
        end
    end
end

local realsidebarhandler = require(ReplicatedStorage.Systems.Player.UI.SidebarHandler)
realsidebarhandler.ToggleSidebarButtons = SidebarHandler.ToggleSidebarButtons
SidebarHandler:Start()
SidebarHandler:ToggleSidebarButtons(not realsidebarhandler.MenusHidden)

local menus = {
    Achievements = (function()setthreadidentity(2)
        local script = menus_folder.Achievements
        local u1 = {};
        function u1.Start(p2) -- Line: 4
            -- upvalues: u1 (copy)
            task.spawn(function() -- Line: 6
                setthreadidentity(2)
                -- upvalues: u1 (ref)
                local LocalPlayer = game.Players.LocalPlayer;
                u1.AchievementsMenu = SidebarHandler:CreateSidebarMenu("Achievements", script.AchievementsScreen);
                local AchievementsContainer = u1.AchievementsMenu.Menu.AchievementsContainer;
                local Contents = AchievementsContainer.Contents;
                local script_Templates = script.Templates;
                local u3 = 0;
                local u4 = 0;
                local u5 = 0;

                local function _() -- Line: 19
                    -- upvalues: AchievementsContainer (copy), u3 (ref), u5 (ref), u4 (ref)
                    AchievementsContainer.MainTitle.Title.Text = `Achievements -- {u3}/{u5}{u4 > 0 and ` (+{u3})` or ""} Unlocked`;
                end;

                local u6 = nil;

                local function v10(u7, p8) -- Line: 24
                    -- upvalues: AchievementsContainer (copy), u6 (ref), Contents (copy)
                    local u9 = script.Templates.TabButton:Clone();
                    u9.Name = u7;
                    u9.LayoutOrder = p8;
                    u9.Inverted.ImageTransparency = u7 == "All" and 0 or 1;
                    u9.Title.TextColor3 = u7 == "All" and Color3.new() or Color3.new(1, 1, 1);
                    u9.Title.Text = u7;
                    u9.Parent = AchievementsContainer.Tabs;
                    u9.MouseButton1Click:Connect(function() -- Line: 33
                        -- upvalues: u6 (ref), u9 (copy), Contents (ref), u7 (copy)
                        if u6 then
                            game.TweenService:Create(u6.Inverted, TweenInfo.new(0.3), {
                                ImageTransparency = 1
                            }):Play();
                            game.TweenService:Create(u6.Title, TweenInfo.new(0.3), {
                                TextColor3 = Color3.new(1, 1, 1)
                            }):Play();
                        end;

                        u6 = u9;
                        game.TweenService:Create(u9.Inverted, TweenInfo.new(0.3), {
                            ImageTransparency = 0
                        }):Play();
                        game.TweenService:Create(u9.Title, TweenInfo.new(0.3), {
                            TextColor3 = Color3.new()
                        }):Play();

                        for _, child in pairs(Contents:GetChildren()) do
                            if child:IsA("GuiObject") then
                                child.Visible = u7 == "All" and true or child:GetAttribute("BranchName") == u7;
                            end;
                        end;
                    end);

                    return u9;
                end;

                u6 = v10("All", 0);
                for i, v in pairs(Achievements2) do
                    local v11 = Achievements:WaitForChild(i, 5);

                    if v11 then
                        local v12 = (tonumber(v.LayoutOrder) or 1) * 1000;
                        local v13 = script_Templates.Seperator:Clone();
                        v13.Name = i;
                        v13.LayoutOrder = v12;
                        v13.Title.Text = v.Title or i;
                        v13.Parent = Contents;
                        v13:SetAttribute("BranchName", i);
                        v10(i, v12).Title.Text = v13.Title.Text;
                        local v14 = i;

                        for i2, v2 in pairs(v.Achievements or {}) do
                            local u15 = v11:WaitForChild(i2, 5);

                            if u15 then
                                local u16 = script_Templates.Achievement:Clone();
                                u16.Name = i2;
                                u16.LayoutOrder = v12 + (tonumber(v2.LayoutOrder) or 1);
                                u16.Title.Text = v2.Title or i2;
                                u16.Description.Text = tostring(v2.Description);
                                u16.Icon.Image = tostring(v2.Icon);
                                u16.Visible = v2.Hidden;
                                u16.Parent = Contents;
                                u16:SetAttribute("BranchName", v14);
                                u5 = u5 + 1;
                                local u17;

                                if v2.RewardType then
                                    if v2.RewardType == "Currency" then
                                        u16.RewardOverlay.RewardTitle.Text = `+ {v2.Amount and (tostring(Util:ToCommas(v2.Amount)) or "???") or "???"}$`;
                                        u17 = v2;
                                    elseif v2.RewardType == "Emote" or v2.RewardType == "Skin" then
                                        u17 = v2;
                                        local v18 = {};

                                        for _, v3 in pairs(v2.Emotes or {}) do
                                            local v19 = `{v3:gsub("(%l)(%u)", "%1 %2")} (Emote)`;
                                            table.insert(v18, v19);
                                        end;

                                        for _, v3 in pairs(u17.Skins or {}) do
                                            local v20 = `{v3:gsub("(%l)(%u)", "%1 %2")} (Skin)`;
                                            table.insert(v18, v20);
                                        end;

                                        if u17.Skin then
                                            local v21 = `{u17.Skin:gsub("(%l)(%u)", "%1 %2")} (Skin)`;
                                            table.insert(v18, v21);
                                        end;

                                        if u17.Emote then
                                            local v22 = `{u17.Emote:gsub("(%l)(%u)", "%1 %2")} (Emote)`;
                                            table.insert(v18, v22);
                                        end;

                                        u16.RewardOverlay.RewardTitle.Text = table.concat(v18, " + ");
                                    else
                                        u17 = v2;
                                    end;

                                    u16.MouseEnter:Connect(function() -- Line: 114
                                        -- upvalues: Sounds (copy), u16 (copy)
                                        Sounds:Play("hover");
                                        u16.RewardOverlay.Visible = true;
                                    end);
                                    u16.MouseLeave:Connect(function() -- Line: 119
                                        -- upvalues: Sounds (copy), u16 (copy)
                                        Sounds:Play("hoverEnd");
                                        u16.RewardOverlay.Visible = false;
                                    end);
                                else
                                    u16.RewardOverlay:Destroy();
                                    u17 = v2;
                                end;

                                local function _() -- Line: 127
                                    -- upvalues: u16 (copy), u17 (copy), u4 (ref), u3 (ref), AchievementsContainer (copy), u5 (ref)
                                    local IncompleteOverlay = u16:FindFirstChild("IncompleteOverlay");

                                    if IncompleteOverlay then
                                        IncompleteOverlay:Destroy();

                                        if u17.Hidden then
                                            u16.Visible = true;
                                            u4 = u4 + 1;
                                        else
                                            u3 = u3 + 1;
                                        end;

                                        AchievementsContainer.MainTitle.Title.Text = `Achievements -- {u3}/{u5}{u4 > 0 and ` (+{u3})` or ""} Unlocked`;
                                    end;
                                end;

                                local function v26() -- Line: 141
                                    -- upvalues: u15 (copy), u16 (copy), u17 (copy), u4 (ref), u3 (ref), AchievementsContainer (copy), u5 (ref), LocalPlayer (copy)
                                    if u15:IsA("BoolValue") then
                                        u16.Progress.Visible = false;
                                        u16.ProgressBar.Visible = false;
                                        local v23 = u15.Value and u16:FindFirstChild("IncompleteOverlay");

                                        if v23 then
                                            v23:Destroy();

                                            if u17.Hidden then
                                                u16.Visible = true;
                                                u4 = u4 + 1;
                                            else
                                                u3 = u3 + 1;
                                            end;

                                            AchievementsContainer.MainTitle.Title.Text = `Achievements -- {u3}/{u5}{u4 > 0 and ` (+{u3})` or ""} Unlocked`;
                                        end;
                                    elseif u15:IsA("IntValue") and u17.Requirement then
                                        local v24 = typeof(u17.Requirement) == "function" and u17.Requirement(LocalPlayer) or u17.Requirement;
                                        local math_clamp_ret = math.clamp(u15.Value / v24, 0, 1);
                                        u16.ProgressBar.Clipping.Size = UDim2.fromScale(math_clamp_ret, 1);
                                        u16.ProgressBar.Clipping.Top.Size = UDim2.fromScale(math_clamp_ret == 0 and 0 or 1 / math_clamp_ret, 1);
                                        local Progress = u16.Progress;
                                        local math_clamp_ret2 = math.clamp(u15.Value, 0, v24);
                                        Progress.Text = `{math.round(math_clamp_ret2)}/{math.round(v24)}`;
                                        local v25 = v24 <= u15.Value and u16:FindFirstChild("IncompleteOverlay");

                                        if v25 then
                                            v25:Destroy();

                                            if u17.Hidden then
                                                u16.Visible = true;
                                                u4 = u4 + 1;
                                            else
                                                u3 = u3 + 1;
                                            end;

                                            AchievementsContainer.MainTitle.Title.Text = `Achievements -- {u3}/{u5}{u4 > 0 and ` (+{u3})` or ""} Unlocked`;
                                        end;
                                    end;
                                end;

                                u15:GetPropertyChangedSignal("Value"):Connect(v26);
                                v26();
                                task.wait();
                            end;
                        end;
                    end;
                end;

                AchievementsContainer.MainTitle.Title.Text = `Achievements -- {u3}/{u5}{u4 > 0 and ` (+{u3})` or ""} Unlocked`;
            end);
        end;
        return u1;
    end)(),
    Inventory = (function()setthreadidentity(2)
        local script = menus_folder.Inventory
        local u1 = {};
        local Tabs = {
            Emotes = function()
                local script = menus_folder.Inventory.Tabs.Emotes
                setthreadidentity(2)
                local u1 = {};

                function u1.CreateTab(p2, p3) -- Line: 4
                    -- upvalues: u1 (copy)
                    setthreadidentity(2)
                    local Templates = script.Parent.Parent.Templates;
                    local v4 = {};
                    local LocalPlayer = game.Players.LocalPlayer;
                    local PlayerData = LocalPlayer.PlayerData;
                    local Emotes = PlayerData.Purchased.Emotes;
                    local Emotes2 = PlayerData.Equipped.Emotes;
                    local ExtraEmotes = PlayerData.Equipped.ExtraEmotes;
                    local Attribute = LocalPlayer:GetAttribute("ExtraEmotes");
                    local u5 = false;
                    local u6 = nil;
                    local u7 = Templates.EmoteMenuHolder:Clone();
                    u1.EmoteWheel = u7;
                    local u8 = false;

                    local function u15(u9, u10) -- Line: 21
                        -- upvalues: u8 (ref), u1 (ref), Templates (copy), Emotes (copy)
                        if u8 then
                            return;
                        end;

                        u8 = true;
                        task.delay(0.5, function() -- Line: 26
                            -- upvalues: u8 (ref)
                            u8 = false;
                        end);

                        if u1.EquipMenu then
                            game.TweenService:Create(u1.EquipMenu, TweenInfo.new(0.2), {
                                Size = UDim2.fromScale(0, 0)
                            }):Play();
                            game.Debris:AddItem(u1.EquipMenu, 0.2);
                        end;

                        local u11 = Templates.EmoteEquipMenu:Clone();
                        u11.Size = UDim2.fromScale();
                        u11.Parent = u9.Parent;
                        u11.Position = u9.Position;
                        u11.ZIndex = 4;
                        u1.EquipMenu = u11;
                        game.TweenService:Create(u11, TweenInfo.new(0.2), {
                            Size = UDim2.fromScale(0.56, 0.41)
                        }):Play();

                        for _, v in pairs({ u11.Cancel, u11.Unequip }) do
                            v.MouseButton1Click:Connect(function() -- Line: 49
                                -- upvalues: u11 (copy), u1 (ref), v (copy), u10 (copy), u9 (copy)
                                if u11 == u1.EquipMenu then
                                    u1.EquipMenu = nil;
                                    game.TweenService:Create(u11, TweenInfo.new(0.2), {
                                        Size = UDim2.fromScale(0, 0)
                                    }):Play();
                                    game.Debris:AddItem(u11, 0.2);

                                    if v.Name == "Unequip" then
                                        require(game.ReplicatedStorage.Modules.Network.Network):FireServerConnection("EquipState", "REMOTE_EVENT", "Emotes", (u10.Name == "ExtraEmotes" and 8 or 0) + tonumber(u9.Name));
                                    end;
                                end;
                            end);
                        end;

                        u11.Searchbar.TextBox:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 64
                            -- upvalues: u11 (copy)
                            for _, child in pairs(u11.EmoteList:GetChildren()) do
                                if child:IsA("GuiObject") then
                                    child.Visible = u11.Searchbar.TextBox.Text == "" and true or child.Name:lower():find(u11.Searchbar.TextBox.Text:lower());
                                end;
                            end;
                        end);

                        for _, child in pairs(Emotes:GetChildren()) do
                            local u12 = game.ReplicatedStorage.Assets.Emotes:FindFirstChild(child.Name);
                            local v13;

                            if u12 then
                                v13 = require(u12);
                            else
                                v13 = u12;
                            end;

                            if v13 then
                                local v14 = Templates.EmoteHolder:Clone();
                                v14.Name = v13.DisplayName or u12.Name;
                                v14.Title.Text = v14.Name;
                                v14.Button.Icon.Image = v13.RenderImage or "";
                                v14.Parent = u11.EmoteList;
                                v14.Button.MouseButton1Click:Connect(function() -- Line: 86
                                    setthreadidentity(2)
                                    -- upvalues: u11 (copy), u1 (ref), u12 (copy), u10 (copy), u9 (copy)
                                    if u11 == u1.EquipMenu then
                                        u1.EquipMenu = nil;
                                        game.TweenService:Create(u11, TweenInfo.new(0.2), {
                                            Size = UDim2.fromScale(0, 0)
                                        }):Play();
                                        game.Debris:AddItem(u11, 0.2);
                                        require(game.ReplicatedStorage.Modules.Network.Network):FireServerConnection("EquipState", "REMOTE_EVENT", u12, (u10.Name == "ExtraEmotes" and 8 or 0) + tonumber(u9.Name));
                                    end;
                                end);
                                v14.ZIndex = 4;
                                v14.Title.ZIndex = 7;
                                v14.Button.ZIndex = 5;
                                v14.Button.Icon.ZIndex = 6;
                            end;
                        end;
                    end;

                    local function v17() -- Line: 107
                        -- upvalues: Attribute (ref), LocalPlayer (copy), u7 (copy), u6 (ref), Sounds (copy), u5 (ref)
                        Attribute = LocalPlayer:GetAttribute("ExtraEmotes") == true;
                        u7.ExtraSwitch.Visible = Attribute;
                        u7.ExtraSwitch.Interactable = Attribute;
                        local EmoteType = u7.EmoteType;
                        local v16;

                        if Attribute then
                            v16 = UDim2.fromScale(0.5, 0.413);
                        else
                            v16 = UDim2.fromScale(0.5, 0.5);
                        end;

                        EmoteType.Position = v16;

                        if Attribute then
                            u6 = u7.ExtraSwitch.MouseButton1Click:Connect(function() -- Line: 114
                                setthreadidentity(2)
                                -- upvalues: Sounds (ref), u5 (ref), u7 (ref)
                                Sounds:Play("switch");
                                u5 = not u5;
                                u7.Emotes.Visible = not u5;
                                u7.ExtraEmotes.Visible = u5;
                            end);

                            return;
                        end;

                        if u6 then
                            u6:Disconnect();
                            u6 = nil;
                        end;
                    end;

                    for _, v in ipairs({ u7.Emotes, u7.ExtraEmotes }) do
                        local u18 = v;

                        for _, child in ipairs(v:GetChildren()) do
                            child.MouseButton1Click:Connect(function() -- Line: 132
                                -- upvalues: u15 (copy), child (copy), u18 (copy)
                                u15(child, u18);
                            end);
                        end;
                    end;

                    local function u23() -- Line: 138
                        -- upvalues: ExtraEmotes (copy), Emotes2 (copy), u7 (copy)
                        for _, v in ipairs({ "Emotes", "ExtraEmotes" }) do
                            local v19;

                            if v == "ExtraEmotes" then
                                v19 = ExtraEmotes;
                            else
                                v19 = Emotes2;
                            end;

                            local string_split_ret = string.split(v19.Value, "|");
                            local v20 = v;

                            for i, v2 in pairs(string_split_ret) do
                                local v21 = u7[v20]:FindFirstChild(i);

                                if v21 then
                                    local v22 = game.ReplicatedStorage.Assets.Emotes:FindFirstChild(v2);

                                    if v22 then
                                        setthreadidentity(2)
                                        v22 = require(v22);
                                    end;

                                    v21.Asset.Image = v22 and (v22.RenderImage or "") or "";
                                    v21.Title.Text = v22 and v22.DisplayName or "";
                                end;
                            end;
                        end;
                    end;

                    local function v24() -- Line: 154
                        -- upvalues: u23 (copy)
                        setthreadidentity(2)
                        require(game.ReplicatedStorage.Systems.Character.Game.Emotes):BuildMenu();
                        u23();
                    end;

                    u23();
                    Emotes2:GetPropertyChangedSignal("Value"):Connect(v24);
                    ExtraEmotes:GetPropertyChangedSignal("Value"):Connect(v24);
                    v17();
                    LocalPlayer:GetAttributeChangedSignal("ExtraEmotes"):Connect(v17);

                    return v4;
                end;

                function u1.Selected(p25, p26) -- Line: 168
                    setthreadidentity(2)
                    -- upvalues: u1 (copy)
                    local InventoryContainer = p26.InventoryRoot.InventoryContainer;

                    if not u1.EmoteWheel.Parent then
                        u1.EmoteWheel.Parent = InventoryContainer;
                    end;
                end;

                function u1.Deselected(p27, p28) -- Line: 175
                    setthreadidentity(2)
                    -- upvalues: u1 (copy)
                    u1.EmoteWheel.Parent = nil;

                    if u1.EquipMenu then
                        u1.EquipMenu:Destroy();
                        u1.EquipMenu = nil;
                    end;
                end;

                return u1;
            end,
            Killers = function()
                local script = menus_folder.Inventory.Tabs.Killers
                return {
                    CreateTab = function(u1, p2) -- Line: 4, Name: CreateTab
                        setthreadidentity(2)
                        local CardTemplate = script.Parent.Parent.Templates.CardTemplate;
                        local SideContainer = p2.InventoryRoot.SideContainer;
                        local u3 = {};
                        local PlayerData = game.Players.LocalPlayer.PlayerData;
                        local Killers = PlayerData.Purchased.Killers;
                        local Killer = PlayerData.Equipped.Killer;
                        local DisplayExtraLevel = PlayerData.Settings.Customization.DisplayExtraLevel;
                        local Killers2 = game.ReplicatedStorage.Assets.Killers;

                        local function u13(u4, u5) -- Line: 12
                            -- upvalues: CardTemplate (copy), DisplayExtraLevel (copy), SideContainer (copy), Killer (copy), u1 (copy), u3 (copy)
                            if not u5 then
                                return;
                            end;

                            if not u4 then
                                return;
                            end;

                            local Config = require(u4.Config);
                            local v6 = CardTemplate:Clone();
                            local Container = v6.Container;
                            v6.Name = u4.Name;
                            v6.LayoutOrder = Config.Price or 1000;
                            Container.CharacterRender.Image = Config.RenderImage or "rbxassetid://13373279056";
                            Container.Title.Text = tostring(Config.DisplayName);
                            Container.Title.TextColor3 = Color3.fromRGB(255, 200, 200);
                            Container.MouseEnter:Connect(function() -- Line: 27
                                -- upvalues: Container (copy)
                                game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                    Size = UDim2.fromScale(1.05, 1.05)
                                }):Play();
                            end);
                            Container.MouseLeave:Connect(function() -- Line: 33
                                -- upvalues: Container (copy)
                                game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                    Size = UDim2.fromScale(1, 1)
                                }):Play();
                            end);

                            local function u12() -- Line: 39
                                setthreadidentity(2)
                                -- upvalues: u5 (copy), DisplayExtraLevel (ref), SideContainer (ref), Killer (ref), u4 (copy), Config (copy)
                                local v7, v8, v9 = require(game:GetService("ReplicatedStorage").Modules.Utilities.Util):CalculateLevelFromEXP(u5.Value);
                                local v10 = v7 > 100 and `MAX LEVEL{DisplayExtraLevel.Value and (` (+{math.floor(v7 - 100)})` or "") or ""}` or (v7 == 100 and "MAX LEVEL" or `{v8}/{v9} EXP`);
                                local v11 = v8 / v9;
                                SideContainer.PreviewContainer.EXPBar.Visible = v7 < 100;
                                SideContainer.PreviewContainer.EXPBar.Clipping.Size = UDim2.fromScale(v11, 1);
                                SideContainer.PreviewContainer.EXPBar.Clipping.Top.Size = UDim2.fromScale(v11 == 0 and 0 or 1 / v11, 1);
                                SideContainer.EquipContainer.Equip.Title.Text = Killer.Value == u4.Name and "Equipped" or "Equip";
                                SideContainer.PreviewContainer.Title.Text = tostring(Config.DisplayName);
                                SideContainer.PreviewContainer.Level.Text = `Level {math.min(v7, 100)}`;
                                SideContainer.PreviewContainer.EXP.Text = v10;
                                SideContainer.PreviewContainer.Render.Image = Config.SquareRenderImage or (Config.RenderImage or "rbxassetid://13373279056");
                            end;

                            DisplayExtraLevel.Changed:Connect(u12);
                            Container.Interact.MouseButton1Click:Connect(function() -- Line: 56
                                -- upvalues: u1 (ref), u4 (copy), u12 (copy), SideContainer (ref)
                                u1.Inventory.CurrentlySelected = u4;
                                u12();
                                SideContainer.Visible = true;
                                game.TweenService:Create(SideContainer, TweenInfo.new(0.4), {
                                    Size = UDim2.fromScale(0.3, 1)
                                }):Play();
                            end);
                            table.insert(u3, v6);
                        end;

                        for _, child in pairs(Killers2:GetChildren()) do
                            setthreadidentity(2)
                            u13(child, Killers:FindFirstChild(child.Name));
                        end;

                        Killers.ChildAdded:Connect(function(p14) -- Line: 73
                            -- upvalues: u13 (copy), Killers2 (copy)
                            setthreadidentity(2)
                            u13(Killers2:FindFirstChild(p14.Name), p14);
                        end);

                        return u3;
                    end
                };
            end,
            Survivors = function()
                local script = menus_folder.Inventory.Tabs.Emotes
                return {
                    CreateTab = function(u1, p2) -- Line: 4, Name: CreateTab
                        setthreadidentity(2)
                        local CardTemplate = script.Parent.Parent.Templates.CardTemplate;
                        local SideContainer = p2.InventoryRoot.SideContainer;
                        local u3 = {};
                        local PlayerData = game.Players.LocalPlayer.PlayerData;
                        local Survivors = PlayerData.Purchased.Survivors;
                        local Survivor = PlayerData.Equipped.Survivor;
                        local DisplayExtraLevel = PlayerData.Settings.Customization.DisplayExtraLevel;
                        local Survivors2 = game.ReplicatedStorage.Assets.Survivors;

                        local function u13(u4, u5) -- Line: 12
                            -- upvalues: CardTemplate (copy), DisplayExtraLevel (copy), SideContainer (copy), Survivor (copy), u1 (copy), u3 (copy)
                            if not u5 then
                                return;
                            end;

                            if not u4 then
                                return;
                            end;

                            local Config = require(u4.Config);
                            local v6 = CardTemplate:Clone();
                            local Container = v6.Container;
                            v6.Name = u4.Name;
                            v6.LayoutOrder = Config.Price or 1000;
                            Container.CharacterRender.Image = Config.RenderImage or "rbxassetid://13373279056";
                            Container.Title.Text = tostring(Config.DisplayName);
                            Container.Title.TextColor3 = Color3.fromRGB(200, 200, 255);
                            Container.MouseEnter:Connect(function() -- Line: 27
                                -- upvalues: Container (copy)
                                game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                    Size = UDim2.fromScale(1.05, 1.05)
                                }):Play();
                            end);
                            Container.MouseLeave:Connect(function() -- Line: 33
                                -- upvalues: Container (copy)
                                game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                    Size = UDim2.fromScale(1, 1)
                                }):Play();
                            end);

                            local function u12() -- Line: 39
                                setthreadidentity(2)
                                -- upvalues: u5 (copy), DisplayExtraLevel (ref), SideContainer (ref), Survivor (ref), Config (copy)
                                local v7, v8, v9 = require(game:GetService("ReplicatedStorage").Modules.Utilities.Util):CalculateLevelFromEXP(u5.Value);
                                local v10 = v7 > 100 and `MAX LEVEL{DisplayExtraLevel.Value and (` (+{math.floor(v7 - 100)})` or "") or ""}` or (v7 == 100 and "MAX LEVEL" or `{v8}/{v9} EXP`);
                                local v11 = v8 / v9;
                                SideContainer.PreviewContainer.EXPBar.Visible = v7 < 100;
                                SideContainer.PreviewContainer.EXPBar.Clipping.Size = UDim2.fromScale(v11, 1);
                                SideContainer.PreviewContainer.EXPBar.Clipping.Top.Size = UDim2.fromScale(v11 == 0 and 0 or 1 / v11, 1);
                                SideContainer.EquipContainer.Equip.Title.Text = Survivor.Value == Config.Name and "Equipped" or "Equip";
                                SideContainer.PreviewContainer.Title.Text = tostring(Config.DisplayName);
                                SideContainer.PreviewContainer.Level.Text = `Level {math.min(v7, 100)}`;
                                SideContainer.PreviewContainer.EXP.Text = v10;
                                SideContainer.PreviewContainer.Render.Image = Config.SquareRenderImage or (Config.RenderImage or "rbxassetid://13373279056");
                            end;

                            DisplayExtraLevel.Changed:Connect(u12);
                            Container.Interact.MouseButton1Click:Connect(function() -- Line: 56
                                -- upvalues: u1 (ref), u4 (copy), u12 (copy), SideContainer (ref)
                                u1.Inventory.CurrentlySelected = u4;
                                u12();
                                SideContainer.Visible = true;
                                game.TweenService:Create(SideContainer, TweenInfo.new(0.4), {
                                    Size = UDim2.fromScale(0.3, 1)
                                }):Play();
                            end);
                            table.insert(u3, v6);
                        end;

                        for _, child in pairs(Survivors2:GetChildren()) do
                            setthreadidentity(2)
                            u13(child, Survivors:FindFirstChild(child.Name));
                        end;

                        Survivors.ChildAdded:Connect(function(p14) -- Line: 73
                            -- upvalues: u13 (copy), Survivors2 (copy)
                            setthreadidentity(2)
                            u13(Survivors2:FindFirstChild(p14.Name), p14);
                        end);

                        return u3;
                    end
                };
            end
        }
        for name, fn in pairs(Tabs) do
            local cached
            Tabs[name] = function()
                cached = cached or fn()
                return cached
            end
        end
        function u1.SwitchTab(p2, p3, p4) -- Line: 9
            -- upvalues: u1 (copy)
            if u1.LastTab == p3 and not p4 then
                return;
            end;

            local Menu = u1.InventoryMenu.Menu;
            local InfoContainer = Menu.InventoryRoot.InfoContainer;
            local SideContainer = Menu.InventoryRoot.SideContainer;
            local InventoryContainer = Menu.InventoryRoot.InventoryContainer;
            local Topbar = InventoryContainer.Topbar;
            local Searchbar = Topbar.Searchbar;

            if u1.InventoryMenu.Menu.Visible and not p4 then
                Sounds:Play("select");
            end;

            game.TweenService:Create(SideContainer, TweenInfo.new(0.4), {
                Size = UDim2.fromScale(0, 1)
            }):Play();
            game.TweenService:Create(InfoContainer, TweenInfo.new(0.4), {
                Size = UDim2.fromScale(0, 1)
            }):Play();
            game.TweenService:Create(InventoryContainer, TweenInfo.new(0.4), {
                Size = UDim2.fromScale(0.7, 1)
            }):Play();
            InventoryContainer.Contents.UIPadding.PaddingTop = UDim.new(0, workspace.CurrentCamera.ViewportSize.Y / 40);

            for _, child in pairs(Topbar:GetChildren()) do
                if child:IsA("ImageButton") then
                    game.TweenService:Create(child, TweenInfo.new(0.25), {
                        ImageColor3 = p3 == child.Name and Color3.new(1, 1, 1) or Color3.new()
                    }):Play();
                    game.TweenService:Create(child.Title, TweenInfo.new(0.25), {
                        TextColor3 = p3 == child.Name and Color3.new() or Color3.new(1, 1, 1)
                    }):Play();
                end;
            end;

            for _, child in pairs(InventoryContainer.Contents:GetChildren()) do
                if child:IsA("GuiObject") or child:IsA("Folder") then
                    child.Parent = nil;
                end;
            end;

            local v5 = Tabs[tostring(u1.LastTab)]

            if v5 then
                v5 = v5();
            else
                print(v5, ' v5 tab doesnt exist!!!!? NANI UWU!')
            end;

            if v5 and v5.Selected then
                v5:Deselected(Menu);
            end;

            local v6 = u1.__tabsData[p3];

            if v6 then
                for _, v in pairs(v6) do
                    local Container = v:FindFirstChild("Container");

                    if Container then
                        Container = Container:FindFirstChild("Title");
                    end;

                    if v:IsA("GuiObject") then
                        v.Visible = not Container or (Searchbar.TextBox.Text == "" and true or string.find(Container.Text:lower(), Searchbar.TextBox.Text:lower()));
                    end;

                    v.Parent = InventoryContainer.Contents;
                end;
            end;

            local v7 = Tabs[p3];

            if v7 then
                v7 = v7();
            else
                print(v7, ' v7 tab doesnt exist!!!!? NANI UWU!')
            end;

            if v7 and v7.Selected then
                v7:Selected(Menu);
            end;

            u1.LastTab = p3;
        end;
        function u1.Start(p8) -- Line: 73
            -- upvalues: u1 (copy)
            local LocalPlayer = game.Players.LocalPlayer;
            local Equipped = LocalPlayer.PlayerData.Equipped;
            local Initializer = require(game.ReplicatedStorage.Initializer);
            local Network = require(game.ReplicatedStorage.Modules.Network.Network);
            local TextService = game:GetService("TextService");
            local UserInputService = game:GetService("UserInputService");
            u1.InventoryMenu = SidebarHandler:CreateSidebarMenu("Inventory", script.InventoryScreen);
            local Menu = u1.InventoryMenu.Menu;
            local SideContainer = Menu.InventoryRoot.SideContainer;
            local InfoContainer = Menu.InventoryRoot.InfoContainer;
            local SkinsContainer = Menu.InventoryRoot.SkinsContainer;
            local InventoryContainer = Menu.InventoryRoot.InventoryContainer;
            local EquipContainer = SideContainer.EquipContainer;
            local Topbar = InventoryContainer.Topbar;
            local Searchbar = Topbar.Searchbar;

            local function _(p9) -- Line: 91
                p9.CanvasSize = UDim2.fromScale(1, 0);

                if p9.AbsoluteCanvasSize.Y > p9.AbsoluteWindowSize.Y then
                    p9.CanvasSize = UDim2.new(1, 0, 0, p9.AbsoluteCanvasSize.Y * 1.05);
                end;
            end;

            InventoryContainer.Contents.ChildAdded:Connect(function() -- Line: 97
                -- upvalues: InventoryContainer (copy)
                local Contents = InventoryContainer.Contents;
                Contents.CanvasSize = UDim2.fromScale(1, 0);

                if Contents.AbsoluteCanvasSize.Y > Contents.AbsoluteWindowSize.Y then
                    Contents.CanvasSize = UDim2.new(1, 0, 0, Contents.AbsoluteCanvasSize.Y * 1.05);
                end;
            end);
            InventoryContainer.Contents.ChildRemoved:Connect(function() -- Line: 105
                -- upvalues: InventoryContainer (copy)
                local Contents = InventoryContainer.Contents;
                Contents.CanvasSize = UDim2.fromScale(1, 0);

                if Contents.AbsoluteCanvasSize.Y > Contents.AbsoluteWindowSize.Y then
                    Contents.CanvasSize = UDim2.new(1, 0, 0, Contents.AbsoluteCanvasSize.Y * 1.05);
                end;
            end);
            InventoryContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() -- Line: 113
                -- upvalues: InventoryContainer (copy)
                local Contents = InventoryContainer.Contents;
                Contents.CanvasSize = UDim2.fromScale(1, 0);

                if Contents.AbsoluteCanvasSize.Y > Contents.AbsoluteWindowSize.Y then
                    Contents.CanvasSize = UDim2.new(1, 0, 0, Contents.AbsoluteCanvasSize.Y * 1.05);
                end;
            end);
            SkinsContainer.Contents.ChildAdded:Connect(function() -- Line: 121
                -- upvalues: SkinsContainer (copy)
                local Contents = SkinsContainer.Contents;
                Contents.CanvasSize = UDim2.fromScale(1, 0);

                if Contents.AbsoluteCanvasSize.Y > Contents.AbsoluteWindowSize.Y then
                    Contents.CanvasSize = UDim2.new(1, 0, 0, Contents.AbsoluteCanvasSize.Y * 1.05);
                end;
            end);
            SkinsContainer.Contents.ChildRemoved:Connect(function() -- Line: 129
                -- upvalues: SkinsContainer (copy)
                local Contents = SkinsContainer.Contents;
                Contents.CanvasSize = UDim2.fromScale(1, 0);

                if Contents.AbsoluteCanvasSize.Y > Contents.AbsoluteWindowSize.Y then
                    Contents.CanvasSize = UDim2.new(1, 0, 0, Contents.AbsoluteCanvasSize.Y * 1.05);
                end;
            end);
            SideContainer.Size = UDim2.fromScale(0, 1);
            SideContainer.Visible = false;
            u1.InventoryMenu.Toggled:Connect(function(p10) -- Line: 139
                -- upvalues: u1 (ref), EquipContainer (copy), SideContainer (copy), InfoContainer (copy), SkinsContainer (copy), InventoryContainer (copy)
                u1:SwitchTab(u1.LastTab or "Killers", true);
                game.TweenService:Create(EquipContainer.Buttons.ViewSkins.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 1
                }):Play();
                game.TweenService:Create(EquipContainer.Buttons.ViewInfo.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 1
                }):Play();
                game.TweenService:Create(SideContainer, TweenInfo.new(0.4), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                game.TweenService:Create(InfoContainer, TweenInfo.new(0.4), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                game.TweenService:Create(SkinsContainer, TweenInfo.new(0.4), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                game.TweenService:Create(InventoryContainer, TweenInfo.new(0.4), {
                    Size = UDim2.fromScale(0.7, 1)
                }):Play();
                task.delay(0.25, function() -- Line: 160
                    -- upvalues: InventoryContainer (ref)
                    InventoryContainer.Visible = true;
                end);
            end);

            local function v12(p11) -- Line: 191
                -- upvalues: Sounds (copy)
                if (p11:IsA("TextButton") or p11:IsA("ImageButton")) and not p11:GetAttribute("SFXImplemented") then
                    p11:SetAttribute("SFXImplemented", true);
                    p11.MouseEnter:Connect(function() -- Line: 195
                        -- upvalues: Sounds (ref)
                        Sounds:Play("hover");
                    end);
                    p11.MouseLeave:Connect(function() -- Line: 199
                        -- upvalues: Sounds (ref)
                        Sounds:Play("hoverEnd");
                    end);

                    if p11.Parent.Name ~= "Topbar" then
                        p11.MouseButton1Click:Connect(function() -- Line: 204
                            -- upvalues: Sounds (ref)
                            Sounds:Play("select");
                        end);
                    end;
                end;
            end;

            local function v15() -- Line: 165
                -- upvalues: LocalPlayer (copy)
                if workspace:GetAttribute("ServerType") == "VIP" and LocalPlayer:GetAttribute("VIP") then
                    local PlayerData = LocalPlayer:FindFirstChild("PlayerData");

                    if not PlayerData then
                        return;
                    end;

                    for _, v in ipairs(require(game.ReplicatedStorage.Modules.Schematics.VIPKillersSchematic)) do
                        if v.Type and v.Name then
                            local v13 = PlayerData.Purchased:FindFirstChild(v.Type);
                            local v14 = game.ReplicatedStorage.Assets:FindFirstChild(v.Type);

                            if v14 and v13 then
                                if v14:FindFirstChild(v.Name, true) then
                                    if not v13:FindFirstChild(v.Name) then
                                        local NumberValue = Instance.new("NumberValue");
                                        NumberValue:SetAttribute("Temp", true);
                                        NumberValue.Name = v.Name;
                                        NumberValue.Parent = v13;
                                    end;
                                else
                                    warn((`[{script}]: Could not find folder for item {v.Name}`));
                                end;
                            else
                                warn((`[{script}]: Could not find folder for item type {v.Type} in {not v14 and "Assets" or `{LocalPlayer.Name}'s PlayerData`}`));
                            end;
                        end;
                    end;
                end;
            end;

            for _, descendant in pairs(Menu:GetDescendants()) do
                v12(descendant);
            end;

            Menu.DescendantAdded:Connect(v12);
            local Util = require(game:GetService("ReplicatedStorage").Modules.Utilities.Util);
            Util:CreateMoneyDisplay(InventoryContainer.Money);
            EquipContainer.Equip.MouseButton1Click:Connect(function() -- Line: 217
                -- upvalues: Network (copy), u1 (ref)
                Network:FireServerConnection("EquipState", "REMOTE_EVENT", u1.CurrentlySelected, true);
            end);

            local function u19(p16) -- Line: 221
                -- upvalues: InventoryContainer (copy), SkinsContainer (copy), Equipped (copy), u1 (ref)
                for _, v in pairs({ InventoryContainer.Contents, SkinsContainer.Contents }) do
                    for _, child in pairs(v:GetChildren()) do
                        if child:IsA("GuiObject") and not child:GetAttribute("IgnoreEquipUpdate") then
                            local v17 = child;
                            local v18 = false;

                            for _, descendant in pairs(Equipped:GetDescendants()) do
                                if descendant:IsA("ValueBase") and (descendant.Value == v17.Name and (descendant.Parent.Name ~= "Skins" or descendant.Name == u1.CurrentlySelected.Name)) then
                                    v18 = true;
                                    break;
                                end;
                            end;

                            if v18 and v17.Container.Equipped.ImageTransparency ~= 0 then
                                if p16 then
                                    v17.Container.Equipped.ImageTransparency = 0;
                                else
                                    game.TweenService:Create(v17.Container.Equipped, TweenInfo.new(0.125), {
                                        ImageTransparency = 0
                                    }):Play();
                                end;
                            elseif not v18 and v17.Container.Equipped.ImageTransparency ~= 1 then
                                game.TweenService:Create(v17.Container.Equipped, TweenInfo.new(0.125), {
                                    ImageTransparency = 1
                                }):Play();
                            end;
                        end;
                    end;
                end;
            end;

            local u20 = nil;

            local function u47(u21) -- Line: 254
                -- upvalues: u20 (ref), InfoContainer (copy), Menu (copy), LocalPlayer (copy), UserInputService (copy), TextService (copy), Util (copy)
                if u20 ~= u21 then
                    u20 = u21;
                    local script_Templates = script.Templates;
                    local u22 = {};

                    for _, child in pairs(InfoContainer.Contents:GetChildren()) do
                        if child:IsA("GuiObject") then
                            child:Destroy();
                        end;
                    end;

                    for i, v in pairs(u21 or {}) do
                        local Frame = Instance.new("Frame");
                        Frame.Name = "Content";
                        Frame.BackgroundTransparency = 1;
                        Frame.Size = UDim2.fromScale(1, 0);
                        Frame.AutomaticSize = Enum.AutomaticSize.Y;
                        Frame.LayoutOrder = i;
                        Frame.Parent = InfoContainer.Contents;
                        local UIListLayout = Instance.new("UIListLayout");
                        UIListLayout.Padding = UDim.new(0, 10);
                        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
                        UIListLayout.Parent = Frame;
                        local _ = workspace.CurrentCamera.ViewportSize.Y;
                        local v23 = v;

                        for i2, v2 in pairs(v) do
                            if i2 == "Separator" then
                                local v24 = script_Templates.Seperator:Clone();
                                v24.Title.Text = tostring(v2);
                                v24.Parent = Frame;
                            elseif i2 == "Header" then
                                local v25 = script_Templates.Header:Clone();
                                v25.Text = tostring(v2);
                                v25.Parent = Frame;
                            elseif i2 == "Quote" then
                                local v26 = script_Templates.Quote:Clone();
                                v26.Text = tostring(v2);
                                v26.Parent = Frame;
                            elseif i2 == "Text" then
                                local v27 = script_Templates.TextContainer:Clone();
                                v27.Title.MaxVisibleGraphemes = 0;
                                v27.Title.Text = tostring(v2);
                                v27.Image.Image = tostring(v23.Image);
                                v27.Image.Visible = v23.Image;
                                v27.Parent = Frame;
                                table.insert(u22, v27.Title);
                                game.TweenService:Create(v27.Title, TweenInfo.new(5, Enum.EasingStyle.Quint), {
                                    MaxVisibleGraphemes = #v27.Title.Text + 10
                                }):Play();
                            end;
                        end;
                    end;

                    task.spawn(function() -- Line: 307
                        setthreadidentity(2)
                        -- upvalues: u21 (copy), u20 (ref), Menu (ref), InfoContainer (ref), LocalPlayer (ref), UserInputService (ref), u22 (copy), TextService (ref), Util (ref)
                        local u28 = {};

                        local function u31(p29) -- Line: 311
                            -- upvalues: u31 (copy), u28 (copy)
                            if p29:IsA("Folder") then
                                for _, child in pairs(p29:GetChildren()) do
                                    u31(child);
                                end;

                                return;
                            end;

                            if p29:IsA("ModuleScript") then
                                local v30 = require(p29);
                                u28[p29.Name] = v30.Data.Description or "???";
                            end;
                        end;

                        u31(game.ReplicatedStorage.Modules.StatusEffects);
                        local v32 = nil;
                        local v33 = false;

                        while true do
                            while true do
                                if not (task.wait() and (u21 and u20 == u21)) then
                                    return;
                                end;

                                if not (Menu.Visible and (InfoContainer.Size.X.Scale >= 0.5 and (LocalPlayer.Character and tostring(LocalPlayer.Character.Parent) == "Spectating"))) then
                                    break;
                                end;

                                local v34 = UserInputService:GetMouseLocation() - game.GuiService:GetGuiInset();
                                local v35 = false;

                                for _, v in pairs(u22) do
                                    if v35 then
                                        break;
                                    end;

                                    local AbsolutePosition = v.AbsolutePosition;
                                    local AbsoluteSize = v.AbsoluteSize;

                                    if v34.X >= AbsolutePosition.X and (v34.X <= AbsolutePosition.X + AbsoluteSize.X and (v34.Y >= AbsolutePosition.Y and v34.Y <= AbsolutePosition.Y + AbsoluteSize.Y)) then
                                        local v36 = v.Text:gsub("<.->", "");
                                        local Font = v.Font;
                                        local TextSize = v.TextSize;
                                        local X = AbsoluteSize.X;
                                        local v37 = v36:split("\n");
                                        local v38 = {};

                                        for _, v2 in ipairs(v37) do
                                            local v39 = v2:split(" ");
                                            local v40 = {};
                                            local v41 = 0;

                                            for _, v3 in ipairs(v39) do
                                                local TextSize2 = TextService:GetTextSize(v3, TextSize, Font, Vector2.new(X, (1 / 0)));
                                                local X2 = TextService:GetTextSize(" ", TextSize, Font, Vector2.new(X, (1 / 0))).X;

                                                if X < v41 + TextSize2.X then
                                                    table.insert(v38, v40);
                                                    v40 = {};
                                                    v41 = 0;
                                                end;

                                                table.insert(v40, v3);
                                                v41 = v41 + TextSize2.X + X2;
                                            end;

                                            if #v40 > 0 then
                                                table.insert(v38, v40);
                                            end;
                                        end;

                                        local Y = TextService:GetTextSize("Test", TextSize, Font, Vector2.new(X, (1 / 0))).Y;
                                        local v42 = 0;

                                        for _, v2 in ipairs(v38) do
                                            if v35 then
                                                break;
                                            end;

                                            local v43 = AbsolutePosition.Y + v42;

                                            if v43 <= v34.Y and v43 + Y >= v34.Y then
                                                local v44 = 0;

                                                for _, v3 in ipairs(v2) do
                                                    local TextSize2 = TextService:GetTextSize(v3, TextSize, Font, Vector2.new(X, (1 / 0)));
                                                    local v45 = AbsolutePosition.X + v44;

                                                    if v45 <= v34.X and v45 + TextSize2.X >= v34.X then
                                                        local _ = game.ReplicatedStorage.Modules.StatusEffects;
                                                        local v46 = u28[v3];

                                                        if v46 then
                                                            v32 = Util:CreateTooltip(v46);
                                                            v33 = true;
                                                            v35 = true;
                                                        else
                                                            v33 = true;
                                                        end;
                                                    else
                                                        local X2 = TextService:GetTextSize(" ", TextSize, Font, Vector2.new(X, (1 / 0))).X;
                                                        v44 = v44 + TextSize2.X + X2;
                                                    end;

                                                    if v33 or v33 then
                                                        break;
                                                    end;
                                                end;

                                                if not (v33 or v33) then
                                                    break;
                                                end;
                                            else
                                                v42 = v42 + Y;
                                            end;

                                            if v33 or v33 then
                                                break;
                                            end;
                                        end;
                                    end;

                                    v33 = false;
                                end;

                                if not v35 then
                                    v32 = Util:CreateTooltip();
                                end;
                            end;

                            if v32 then
                                v32 = Util:CreateTooltip();
                            end;
                        end;
                    end);
                end;
            end;

            local function u53(p48) -- Line: 429
                -- upvalues: SkinsContainer (copy), u1 (ref), LocalPlayer (copy), Util (copy), Network (copy), u19 (copy)
                if p48 then
                    for _, child in pairs(SkinsContainer.Contents:GetChildren()) do
                        if child:IsA("GuiObject") then
                            child:Destroy();
                        end;
                    end;

                    local v49 = u1.CurrentlySelected and u1.CurrentlySelected:FindFirstChild("Config");

                    if v49 then
                        v49 = require(v49);
                    end;

                    SkinsContainer.TitleDisplay.Title.Text = `{v49.DisplayName or tostring(p48.Name)} Skins`;

                    for _, child in pairs(p48:GetChildren()) do
                        if LocalPlayer.PlayerData.Purchased.Skins:FindFirstChild(child.Name, true) then
                            local Config = require(child.Config);
                            local v50 = script.Templates.CardTemplate:Clone();
                            local Container = v50.Container;
                            v50.Name = child.Name;
                            v50.LayoutOrder = Config.Price or 1000;
                            v50.Parent = SkinsContainer.Contents;
                            Container.CharacterRender.Image = Config.RenderImage or "rbxassetid://13373279056";
                            Container.Title.Text = tostring(Config.DisplayName);

                            if Config.ExclusiveText or Config.Exclusive then
                                script.Templates.ExclusiveGradient:Clone().Parent = Container.Outline;
                                Container.Outline.ImageColor3 = Color3.new(1, 1, 1);
                            end;

                            if Config.SpecialText or Config.Special then
                                script.Templates.SpecialGradient:Clone().Parent = Container.Outline;
                                Container.Outline.ImageColor3 = Color3.new(1, 1, 1);
                            end;

                            if Config.Dev and Config.Exclusive then
                                Container.Outline.ImageColor3 = Color3.new(1, 1, 1);
                                Container.Outline.Image = "rbxassetid://96503567839232";
                            end;

                            if Config.Uncommon then
                                script.Templates.UncommonGradient:Clone().Parent = Container.Outline;
                                Container.Outline.ImageColor3 = Color3.new(1, 1, 1);
                            end;

                            if Config.Epic then
                                script.Templates.EpicGradient:Clone().Parent = Container.Outline;
                                Container.Outline.ImageColor3 = Color3.new(1, 1, 1);
                            end;

                            if Config.Legendary then
                                script.Templates.LegendaryGradient:Clone().Parent = Container.Outline;
                                Container.Outline.ImageColor3 = Color3.new(1, 1, 1);
                            end;

                            local u51 = require(game.ReplicatedStorage.Modules.Schematics.IngameCollabs)[Config.CollabInfo] or Config.CollabInfo;

                            if typeof(u51) == "table" then
                                local v52 = game.ReplicatedStorage.Assets.UI.ShopCardIcon:Clone();
                                v52.Image = u51.Icon or "rbxassetid://9011713759";
                                v52.Parent = Container.CardIcons;
                                v52.MouseEnter:Connect(function() -- Line: 479
                                    -- upvalues: Util (ref), u51 (copy)
                                    Util:CreateTooltip(u51.Description);
                                end);
                                v52.MouseLeave:Connect(function() -- Line: 483
                                    -- upvalues: Util (ref)
                                    Util:CreateTooltip();
                                end);
                            end;

                            local Name = p48.Parent.Name;

                            if Name == "Survivors" then
                                Container.Title.TextColor3 = Color3.fromRGB(200, 200, 255);
                            elseif Name == "Killers" then
                                Container.Title.TextColor3 = Color3.fromRGB(255, 200, 200);
                            end;

                            Container.MouseEnter:Connect(function() -- Line: 494
                                -- upvalues: Container (copy)
                                game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                    Size = UDim2.fromScale(1.05, 1.05)
                                }):Play();
                            end);
                            Container.MouseLeave:Connect(function() -- Line: 500
                                -- upvalues: Container (copy)
                                game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                    Size = UDim2.fromScale(1, 1)
                                }):Play();
                            end);
                            Container.Interact.MouseButton1Click:Connect(function() -- Line: 506
                                -- upvalues: Network (ref), child (copy), Container (copy)
                                Network:FireServerConnection("EquipState", "REMOTE_EVENT", child, Container.Equipped.ImageTransparency > 0.5);
                            end);
                            u19(true);
                        end;
                    end;
                end;
            end;

            local u54 = nil;
            local u55 = false;
            EquipContainer.Buttons.ViewInfo.MouseButton1Click:Connect(function() -- Line: 517
                -- upvalues: u55 (ref), u1 (ref), u47 (copy), u54 (ref), InfoContainer (copy), EquipContainer (copy), SkinsContainer (copy), InventoryContainer (copy)
                if u55 then
                    return;
                end;

                u55 = true;
                local v56 = u1.CurrentlySelected and u1.CurrentlySelected:FindFirstChild("Config");

                if v56 then
                    v56 = require(v56);
                end;

                if not (v56 and v56.Information) then
                    u55 = false;

                    return;
                end;

                u47(v56.Information);

                if u54 then
                    task.cancel(u54);
                end;

                if InfoContainer.Size.X.Scale >= 0.35 then
                    game.TweenService:Create(EquipContainer.Buttons.ViewSkins.Inverted, TweenInfo.new(0.25), {
                        ImageTransparency = 1
                    }):Play();
                    game.TweenService:Create(EquipContainer.Buttons.ViewInfo.Inverted, TweenInfo.new(0.25), {
                        ImageTransparency = 1
                    }):Play();
                    game.TweenService:Create(SkinsContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0, 1)
                    }):Play();
                    game.TweenService:Create(InfoContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0, 1)
                    }):Play();
                    game.TweenService:Create(InventoryContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0.7, 1)
                    }):Play();
                    u54 = task.delay(0.25, function() -- Line: 549
                        -- upvalues: SkinsContainer (ref), InfoContainer (ref)
                        SkinsContainer.Visible = false;
                        InfoContainer.Visible = false;
                    end);
                    task.delay(0.175, function() -- Line: 554
                        -- upvalues: u55 (ref)
                        u55 = false;
                    end);
                    InventoryContainer.Visible = true;

                    return;
                end;

                game.TweenService:Create(EquipContainer.Buttons.ViewSkins.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 1
                }):Play();
                game.TweenService:Create(EquipContainer.Buttons.ViewInfo.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 0
                }):Play();
                game.TweenService:Create(SkinsContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                game.TweenService:Create(InfoContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0.7, 1)
                }):Play();
                game.TweenService:Create(InventoryContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                u54 = task.delay(0.25, function() -- Line: 576
                    -- upvalues: SkinsContainer (ref), InventoryContainer (ref)
                    SkinsContainer.Visible = false;
                    InventoryContainer.Visible = false;
                end);
                task.delay(0.175, function() -- Line: 581
                    -- upvalues: u55 (ref)
                    u55 = false;
                end);
                InfoContainer.Visible = true;
            end);
            EquipContainer.Buttons.ViewSkins.MouseButton1Click:Connect(function() -- Line: 591
                -- upvalues: u55 (ref), u1 (ref), u53 (copy), u54 (ref), SkinsContainer (copy), EquipContainer (copy), InfoContainer (copy), InventoryContainer (copy)
                if u55 then
                    return;
                end;

                u55 = true;

                if not u1.CurrentlySelected then
                    return;
                end;

                local v57 = game.ReplicatedStorage.Assets.Skins:FindFirstChild((tostring(u1.CurrentlySelected.Parent)));

                if v57 then
                    v57 = v57:FindFirstChild((tostring(u1.CurrentlySelected)));
                end;

                if not v57 then
                    u55 = false;

                    return;
                end;

                u53(v57);

                if u54 then
                    task.cancel(u54);
                end;

                if SkinsContainer.Size.X.Scale >= 0.35 then
                    game.TweenService:Create(EquipContainer.Buttons.ViewSkins.Inverted, TweenInfo.new(0.25), {
                        ImageTransparency = 1
                    }):Play();
                    game.TweenService:Create(EquipContainer.Buttons.ViewInfo.Inverted, TweenInfo.new(0.25), {
                        ImageTransparency = 1
                    }):Play();
                    game.TweenService:Create(SkinsContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0, 1)
                    }):Play();
                    game.TweenService:Create(InfoContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0, 1)
                    }):Play();
                    game.TweenService:Create(InventoryContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0.7, 1)
                    }):Play();
                    u54 = task.delay(0.25, function() -- Line: 626
                        -- upvalues: InfoContainer (ref), SkinsContainer (ref)
                        InfoContainer.Visible = false;
                        SkinsContainer.Visible = false;
                    end);
                    task.delay(0.175, function() -- Line: 631
                        -- upvalues: u55 (ref)
                        u55 = false;
                    end);
                    InventoryContainer.Visible = true;

                    return;
                end;

                game.TweenService:Create(EquipContainer.Buttons.ViewSkins.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 0
                }):Play();
                game.TweenService:Create(EquipContainer.Buttons.ViewInfo.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 1
                }):Play();
                game.TweenService:Create(SkinsContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0.7, 1)
                }):Play();
                game.TweenService:Create(InfoContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                game.TweenService:Create(InventoryContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                u54 = task.delay(0.25, function() -- Line: 653
                    -- upvalues: InfoContainer (ref), InventoryContainer (ref)
                    InfoContainer.Visible = false;
                    InventoryContainer.Visible = false;
                end);
                task.delay(0.175, function() -- Line: 658
                    -- upvalues: u55 (ref)
                    u55 = false;
                end);
                SkinsContainer.Visible = true;
            end);

            for _, child in pairs(EquipContainer.Buttons:GetChildren()) do
                local Attribute = child:GetAttribute("Description");

                if Attribute then
                    child.Title.TextTransparency = 0;
                    child.Title.Text = Attribute;
                end;
            end;

            u1.__tabsData = {};

            for name, tabFn in pairs(Tabs) do
                local v58 = tabFn();
                v58.Inventory = u1;
                local v59 = v58:CreateTab(Menu);
                u1.__tabsData[name] = v59;
            end;

            u1:SwitchTab("Killers");
            u19();

            for _, descendant in pairs(Equipped:GetDescendants()) do
                if descendant:IsA("ValueBase") then
                    descendant:GetPropertyChangedSignal("Value"):Connect(function() -- Line: 687
                        -- upvalues: SideContainer (copy), u19 (copy)
                        SideContainer.EquipContainer.Equip.Title.Text = "Equipped";
                        u19();
                    end);
                end;
            end;

            for _, child in pairs(Topbar:GetChildren()) do
                if child:IsA("ImageButton") then
                    child.MouseButton1Click:Connect(function() -- Line: 696
                        -- upvalues: u1 (ref), child (copy), u19 (copy)
                        u1:SwitchTab(child.Name);
                        u19(true);
                    end);
                end;
            end;

            Searchbar.TextBox:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 703
                -- upvalues: InventoryContainer (copy), Searchbar (copy)
                for _, child in pairs(InventoryContainer.Contents:GetChildren()) do
                    if child:IsA("Frame") then
                        child.Visible = Searchbar.TextBox.Text == "" and true or string.find(child.Container.Title.Text:lower(), Searchbar.TextBox.Text:lower());
                    end;
                end;
            end);
            workspace:GetAttributeChangedSignal("ServerType"):Connect(v15);
            LocalPlayer:GetAttributeChangedSignal("VIP"):Connect(v15);
            v15();
        end;
        return u1;
    end)(),
    Settings = (function()setthreadidentity(2)
        local script = menus_folder.Settings
        local u1 = {};
        local templates = {
            Bool = function()
                local script = script.Templates.Bool
                local u1 = {};
                u1.__index = u1;

                function u1.CreateSettingUI(p2, u3, p4) -- Line: 5
                    -- upvalues: u1 (copy)
                    if not u3 then
                        u3 = Instance.new("BoolValue");
                        u3.Name = "SettingValue";
                    end;

                    local u5 = setmetatable({
                        SettingValue = u3
                    }, u1);
                    u5.isDebounce = false;
                    u5.Instance = p4 or script.Checkbox:Clone();
                    u5.Instance.CheckboxButton.MouseButton1Click:Connect(function() -- Line: 16
                        -- upvalues: u5 (copy), u3 (ref)
                        if u5.isDebounce then
                            return;
                        end;

                        u5.isDebounce = true;
                        task.delay(0.25, function() -- Line: 22
                            -- upvalues: u5 (ref)
                            u5.isDebounce = false;
                        end);
                        Sounds:Play("switch");
                        require(game.ReplicatedStorage.Modules.Network.Network):FireServerConnection("UpdateSettings", "REMOTE_EVENT", u3, not u3.Value);
                    end);

                    return u5;
                end;

                function u1.OnUpdate(p6) -- Line: 33
                    p6.Value = p6.SettingValue.Value;
                    p6.Instance.CheckboxButton.Checked.Visible = p6.Value;
                end;

                return u1;
            end,
            Keybind = function()
                local script = script.Templates.Keybind
                local u1 = {};
                u1.__index = u1;

                function u1.CreateSettingUI(p2, u3, p4) -- Line: 5
                    -- upvalues: u1 (copy)
                    local Device = require(game.ReplicatedStorage.Modules.Utilities.Device);

                    if not u3 then
                        u3 = Instance.new("StringValue");
                        u3.Name = "SettingValue";
                    end;

                    local u5 = setmetatable({
                        SettingValue = u3
                    }, u1);
                    u5.Instance = p4 or script.KeybindFrame:Clone();
                    u5.IsKeybind = true;

                    local function _() -- Line: 18
                        -- upvalues: u1 (ref)
                        if u1.__currentConnection then
                            u1.__currentConnection:Disconnect();
                            u1.__currentConnection = nil;
                        end;
                    end;

                    local u6 = { "None", "Unknown", "MouseMovement", "Focus", "Accelerometer", "TextInput" };
                    u5.Instance.KeybindButton.MouseButton1Click:Connect(function() -- Line: 33
                        -- upvalues: Sounds (copy), u1 (ref), u5 (copy), u6 (copy), u3 (ref)
                        Sounds:Play("click");

                        if u1.__currentConnection then
                            return;
                        end;

                        if u5.__debounce then
                            return;
                        end;

                        u5.__debounce = true;
                        task.delay(0.25, function() -- Line: 42
                            -- upvalues: u5 (ref)
                            u5.__debounce = nil;
                        end);
                        task.wait(0.05);
                        u5.Instance.KeybindButton.CurrentBind.Title.Text = "...";
                        u1.__currentConnection = game.UserInputService.InputEnded:Connect(function(p7) -- Line: 48
                            -- upvalues: u1 (ref), u6 (ref), u3 (ref), Sounds (ref), u5 (ref)
                            if u1.__currentConnection then
                                local v8 = p7.KeyCode == Enum.KeyCode.Unknown and p7.UserInputType.Name or p7.KeyCode.Name;

                                if table.find(u6, v8) or p7.KeyCode == Enum.KeyCode.Unknown and u3:GetAttribute("KeycodeOnly") then
                                    Sounds:Play("error");

                                    return;
                                end;

                                local Initializer = require(game.ReplicatedStorage.Initializer);

                                for i, v in pairs(Initializer.PlayerSettings) do
                                    if v.IsKeybind and (v.Value == v8 and i ~= u3.Name) then
                                        Sounds:Play("error");

                                        return;
                                    end;
                                end;

                                require(game.ReplicatedStorage.Modules.Network.Network):FireServerConnection("UpdateSettings", "REMOTE_EVENT", u3, v8);
                                Sounds:Play("switch");

                                if u1.__currentConnection then
                                    u1.__currentConnection:Disconnect();
                                    u1.__currentConnection = nil;
                                end;

                                u5.Instance.KeybindButton.CurrentBind.Title.Text = v8;
                            end;
                        end);
                    end);

                    local function v9() -- Line: 76
                        -- upvalues: Device (copy), u3 (ref), u5 (copy)
                        local PlayerDevice = Device:GetPlayerDevice();

                        if PlayerDevice == "Console" and u3.Name:find("~Console") then
                            u5.Instance.Visible = true;

                            return;
                        end;

                        if PlayerDevice == "PC" and not u3.Name:find("~Console") then
                            u5.Instance.Visible = true;

                            return;
                        end;

                        u5.Instance.Visible = false;
                    end;

                    v9();
                    Device.Changed:Connect(v9);

                    return u5;
                end;

                function u1.OnUpdate(p10) -- Line: 94
                    p10.Instance.KeybindButton.CurrentBind.Title.Text = p10.Value;
                end;

                return u1;
            end,
            Number = function()
                local script = script.Templates.Number
                local u1 = {};
                u1.__index = u1;

                local function _(p2, p3, p4) -- Line: 5
                    return math.clamp(p3 + (p4 - p3) * p2, p3, p4);
                end;

                local function _(p5, p6, p7) -- Line: 8
                    return math.clamp((p5 - p6) / (p7 - p6), 0, 1);
                end;

                local function _(p8, p9) -- Line: 11
                    return p9 == 0 and p8 and p8 or math.floor((p8 + p9 / 2) / p9) * p9;
                end;

                function u1.CreateSettingUI(p10, u11, p12, u13) -- Line: 14
                    -- upvalues: u1 (copy)

                    if not u11 then
                        u11 = Instance.new("NumberValue");
                        u11.Name = "SettingValue";
                    end;

                    local u14 = setmetatable({
                        SettingValue = u11
                    }, u1);
                    u14.Instance = p12 or script.Slider:Clone();
                    u14.Value = u11.Value;
                    local DragBar = u14.Instance.DragBar;
                    local Dragger = DragBar.Dragger;
                    local Mouse = game.Players.LocalPlayer:GetMouse();
                    local Attribute = u11:GetAttribute("MinValue");
                    local Attribute2 = u11:GetAttribute("MaxValue");
                    local Attribute3 = u11:GetAttribute("Step");
                    u14.__displayValue = Instance.new("NumberValue");
                    u14.__displayValue.Name = "__displayValue";
                    u14.__displayValue.Value = u11.Value;
                    u14.__displayValue.Parent = u14.Instance;
                    u14.__displayValue:GetPropertyChangedSignal("Value"):Connect(function() -- Line: 36
                        -- upvalues: Dragger (copy), u14 (copy)
                        local Title = Dragger.Title;
                        local math_round_ret = math.round(u14.__displayValue.Value);
                        Title.Text = tostring(math_round_ret);
                    end);
                    local Title = Dragger.Title;
                    local math_round_ret = math.round(u14.__displayValue.Value);
                    Title.Text = tostring(math_round_ret);

                    local function v16(p15) -- Line: 66
                        -- upvalues: u14 (copy), Sounds (copy), u11 (ref), u13 (copy)
                        if not u14.Dragging then
                            return;
                        end;

                        if p15.UserInputType == Enum.UserInputType.MouseButton1 or (p15.UserInputType == Enum.UserInputType.Touch or p15.UserInputType == Enum.UserInputType.Gamepad1 and p15.KeyCode == Enum.KeyCode.ButtonR2) then
                            u14.Dragging = false;
                            Sounds:Play("switch");

                            if u11.Name ~= "SettingValue" and u11.Name ~= "Value" then
                                require(game.ReplicatedStorage.Modules.Network.Network):FireServerConnection("UpdateSettings", "REMOTE_EVENT", u11, u14.Value);

                                return;
                            end;

                            u14:OnUpdate();

                            if u13 then
                                u13(u14.Value);
                            end;
                        end;
                    end;

                    Dragger.MouseButton1Down:Connect(function() -- Line: 41, Name: v30
                        -- upvalues: u14 (copy), Sounds (copy), Mouse (copy), DragBar (copy), Attribute (copy), Attribute2 (copy), Attribute3 (copy)
                        u14.Dragging = true;
                        Sounds:Play("switch");

                        while task.wait() and u14.Dragging do
                            local v17 = Attribute;
                            local v18 = Attribute2;
                            local math_clamp_ret = math.clamp(v17 + (v18 - v17) * ((Mouse.X - DragBar.AbsolutePosition.X) / DragBar.AbsoluteSize.X), v17, v18);
                            local v19 = Attribute3;
                            local v20 = v19 == 0 and math_clamp_ret and math_clamp_ret or math.floor((math_clamp_ret + v19 / 2) / v19) * v19;

                            if u14.Value ~= v20 then
                                Sounds:Play("tick", {
                                    Volume = 0.025
                                });
                                u14.Value = v20;
                                u14:OnUpdate();

                                if u14.__updatedEvent then
                                    u14.__updatedEvent:Fire();
                                end;
                            end;
                        end;
                    end);
                    game.UserInputService.InputEnded:Connect(v16);

                    return u14;
                end;

                function u1.OnUpdate(p21) -- Line: 91
                    local Attribute = p21.SettingValue:GetAttribute("MinValue");
                    local Attribute2 = p21.SettingValue:GetAttribute("MaxValue");
                    local math_clamp_ret = math.clamp((p21.Value - Attribute) / (Attribute2 - Attribute), 0, 1);
                    local Dragger = p21.Instance.DragBar.Dragger;
                    local math_clamp_ret2 = math.clamp(math_clamp_ret, 0, 1);
                    game.TweenService:Create(Dragger, TweenInfo.new(0.1), {
                        Position = UDim2.fromScale(math_clamp_ret2, 0.5)
                    }):Play();
                    game.TweenService:Create(p21.__displayValue, TweenInfo.new(0.1), {
                        Value = p21.Value
                    }):Play();
                end;

                return u1;
            end,
            String = function()
                local script = script.Templates.String
                local u1 = {};
                u1.__index = u1;
                local u2 = 10;

                function u1.CreateSettingUI(p3, u4, p5, u6) -- Line: 6
                    -- upvalues: u1 (copy), u2 (ref)

                    if not u4 then
                        u4 = Instance.new("StringValue");
                        u4.Name = "SettingValue";
                    end;

                    local u7 = setmetatable({
                        SettingValue = u4
                    }, u1);
                    u7.Value = u4.Value;
                    u7.Instance = p5 or script.Dropdown:Clone();
                    u7.DropdownVisible = false;
                    u7.Instance.DropdownFrame.MouseButton1Click:Connect(function() -- Line: 19
                        -- upvalues: Sounds (copy), u7 (copy), u2 (ref), u4 (ref), u6 (copy)
                        Sounds:Play("click");
                        u7.DropdownVisible = not u7.DropdownVisible;
                        u7.Instance.DropdownFrame.DropdownArrow.Rotation = u7.DropdownVisible and 180 or 0;
                        u7.Instance.DropdownFrame.Options.Visible = u7.DropdownVisible;
                        u2 = u2 + 1;
                        u7.Instance.ZIndex = u2;

                        for _, child in pairs(u7.Instance.DropdownFrame.Options:GetChildren()) do
                            if child:IsA("GuiObject") then
                                child:Destroy();
                            end;
                        end;

                        local v8 = u4:GetAttribute("Options") and string.split(u4:GetAttribute("Options"), "|");

                        for i, v in pairs(v8 or {}) do
                            local v9 = script.DropdownOption:Clone();
                            v9.Name = v;
                            v9.LayoutOrder = i;
                            v9.Title.Text = v9.Name;
                            v9.Parent = u7.Instance.DropdownFrame.Options;
                            v9.MouseButton1Click:Connect(function() -- Line: 41
                                -- upvalues: u4 (ref), v (copy), u7 (ref), u6 (ref), Sounds (ref)
                                if u4.Name == "SettingValue" or u4.Name == "Value" then
                                    u7.Value = v;
                                    u7:OnUpdate();

                                    if u6 then
                                        u6(u7.Value);
                                    end;
                                else
                                    require(game.ReplicatedStorage.Modules.Network.Network):FireServerConnection("UpdateSettings", "REMOTE_EVENT", u4, v);
                                end;

                                Sounds:Play("switch");
                            end);
                        end;
                    end);

                    return u7;
                end;

                function u1.OnUpdate(p10) -- Line: 58
                    p10.Instance.DropdownFrame.ChosenValue.Title.Text = p10.Value;
                    p10.Instance.DropdownFrame.Options.Visible = false;
                    p10.Instance.DropdownFrame.DropdownArrow.Rotation = 0;
                    p10.DropdownVisible = false;
                end;

                return u1;
            end,
            Textbox = function()
                local script = script.Templates.Textbox
                local u1 = {};
                u1.__index = u1;

                function u1.CreateSettingUI(p2, u3, p4, u5) -- Line: 5
                    -- upvalues: u1 (copy)

                    if not u3 then
                        u3 = Instance.new("StringValue");
                        u3.Name = "SettingValue";
                    end;

                    local u6 = setmetatable({
                        SettingValue = u3
                    }, u1);
                    u6.Value = u3.Value;
                    u6.Instance = p4 or script.Textbox:Clone();
                    u6.Instance.TextboxBackground.Textbox.Focused:Connect(function() -- Line: 17
                        -- upvalues: Sounds (copy)
                        Sounds:Play("click");
                    end);
                    u6.Instance.TextboxBackground.Textbox.FocusLost:Connect(function() -- Line: 21
                        -- upvalues: u3 (ref), u6 (copy), u5 (copy), Sounds (copy)
                        if u3.Name == "SettingValue" or u3.Name == "Value" then
                            u6.Value = u6.Instance.TextboxBackground.Textbox.Text;
                            u6:OnUpdate();

                            if u5 then
                                u5(u6.Value);
                            end;
                        else
                            require(game.ReplicatedStorage.Modules.Network.Network):FireServerConnection("UpdateSettings", "REMOTE_EVENT", u3, u6.Instance.TextboxBackground.Textbox.Text);
                        end;

                        Sounds:Play("click");
                    end);

                    return u6;
                end;

                function u1.OnUpdate(p7) -- Line: 36
                    p7.Instance.TextboxBackground.Textbox.Text = p7.Value or "";
                end;

                return u1;
            end
        }
        for i, v in pairs(templates) do
            templates[i] = v()
        end
        function u1.Start(p2) -- Line: 4
            -- upvalues: u1 (copy)
            local LocalPlayer = game.Players.LocalPlayer;
            local Settings = LocalPlayer:WaitForChild("PlayerData"):WaitForChild("Settings");
            local Initializer = require(game.ReplicatedStorage.Initializer);
            Initializer.PlayerSettings = {};
            u1.SettingsMenu = SidebarHandler:CreateSidebarMenu("Settings", script.SettingsScreen);
            local Contents = u1.SettingsMenu.Menu.SettingsContainer.Contents;
            local script_Templates = script.Templates;

            local function u17(u3, p4) -- Line: 13
                -- upvalues: script_Templates (copy), Contents (copy), u17 (copy), Settings (copy), LocalPlayer (copy), Initializer (copy)
                local v5 = p4 or 0;
                local Attribute = u3:GetAttribute("LayoutOrder");
                local Attribute2 = u3:GetAttribute("DisplayTitle");
                local Attribute3 = u3:GetAttribute("DisplayDescription");
                u3:GetAttribute("PostDisplayTitle");

                if not (Attribute and Attribute2) then
                    return;
                end;

                if not u3:IsA("Folder") then
                    if u3:IsA("ValueBase") then
                        local v6 = templates[u3:GetAttribute("TemplateType") or string.gsub(u3.ClassName, "Value", "")];

                        for name, child in pairs(templates) do
                            if u3.Parent.Name:find(name) then
                                v6 = child;
                            end;
                        end;

                        if v6 and v6.CreateSettingUI then
                            local u7 = v6:CreateSettingUI(u3);
                            u7.Instance.Name = u3.Name;
                            u7.Instance.LayoutOrder = Attribute + v5;
                            u7.Instance.Parent = Contents;
                            local Attribute4 = u3:GetAttribute("Requirement");

                            if Attribute4 then
                                local u8 = Settings:FindFirstChild(Attribute4, true);

                                if u8 then
                                    u7.Instance.Visible = u8.Value;
                                    u8:GetPropertyChangedSignal("Value"):Connect(function() -- Line: 53, Name: v25
                                        -- upvalues: u7 (copy), u8 (copy)
                                        u7.Instance.Visible = u8.Value;
                                    end);
                                elseif Attribute4 == "VIP" then
                                    local function v9() -- Line: 60
                                        -- upvalues: u7 (copy), LocalPlayer (ref)
                                        u7.Instance.Visible = LocalPlayer:GetAttribute("VIP");
                                    end;

                                    u7.Instance.Visible = LocalPlayer:GetAttribute("VIP");
                                    LocalPlayer:GetAttributeChangedSignal("VIP"):Connect(v9);
                                elseif Attribute4:find("Device=") then
                                    local Device = require(game:GetService("ReplicatedStorage").Modules.Utilities.Device);
                                    u7.Instance.Visible = `Device={Device:GetPlayerDevice()}` == Attribute4;
                                    Device.Changed:Connect(function() -- Line: 69, Name: v29
                                        -- upvalues: u7 (copy), Device (copy), Attribute4 (copy)
                                        u7.Instance.Visible = `Device={Device:GetPlayerDevice()}` == Attribute4;
                                    end);
                                elseif Attribute4:find("Rank=") then
                                    local u10 = 0;
                                    pcall(function() -- Line: 79
                                        -- upvalues: u10 (ref), LocalPlayer (ref)
                                        u10 = LocalPlayer:GetAttribute("Rank") or 0;
                                    end);
                                    local v11 = string.split(Attribute4, "=")[2];
                                    local v12 = tonumber(v11) or 255;
                                    u7.Instance.Visible = v12 <= u10;
                                end;
                            end;

                            local v13 = script_Templates.Reset:Clone();
                            v13.Parent = u7.Instance;
                            v13.MouseButton1Click:Connect(function() -- Line: 91
                                -- upvalues: u3 (copy), Sounds (copy)
                                require(game.ReplicatedStorage.Modules.Network.Network):FireServerConnection("UpdateSettings", "REMOTE_EVENT", u3);
                                Sounds:Play("switch");
                            end);
                            v13.MouseEnter:Connect(function() -- Line: 96
                                -- upvalues: Sounds (copy)
                                Sounds:Play("hover");
                            end);
                            v13.MouseLeave:Connect(function() -- Line: 100
                                -- upvalues: Sounds (copy)
                                Sounds:Play("hoverEnd");
                            end);
                            local SettingName = u7.Instance:FindFirstChild("SettingName", true);
                            local SettingDesc = u7.Instance:FindFirstChild("SettingDesc", true);
                            SettingName.Text = Attribute2;
                            SettingDesc.Text = Attribute3;
                            u7.__updatedEvent = Instance.new("BindableEvent");
                            u7.__updatedEvent.Parent = u7.Instance;
                            u7.Updated = u7.__updatedEvent.Event;
                            local u14 = script.SettingConnections:FindFirstChild(u3.Name);

                            if u14 then
                                setthreadidentity(8)
                                local path = `game.{menus_folder:GetFullName()}.Settings.SettingConnections["{u3.Name}"]`
                                print(`setting path: {path}`)
                                u14 = loadstring(`--Catsaken OLD SIDEBAR project!\nlocal script={path}\n{u14.Source}`)();
                            end;

                            if u14 then
                                u7.Updated:Connect(function() -- Line: 114
                                    -- upvalues: u14 (copy), u7 (copy)
                                    setthreadidentity(2)
                                    print(`({u14}):Updated(u7.Value) | {u3.Name}`)
                                    u14:Updated(u7.Value);
                                end);
                            end;

                            local function v15() -- Line: 119
                                -- upvalues: u7 (copy), u3 (copy)
                                u7.Value = u3.Value;

                                if u7.OnUpdate then
                                    u7:OnUpdate();
                                end;

                                u7.__updatedEvent:Fire();
                            end;

                            u7.Value = u3.Value;

                            if u7.OnUpdate then
                                u7:OnUpdate();
                            end;

                            u7.__updatedEvent:Fire();
                            u3:GetPropertyChangedSignal("Value"):Connect(v15);
                            Initializer.PlayerSettings[u3.Name] = u7;
                            task.wait();
                        end;
                    end;

                    return;
                end;

                local v16 = script_Templates.Seperator:Clone();
                v16.Name = u3.Name;
                v16.LayoutOrder = Attribute * 100 + v5;
                v16.Title.Text = Attribute2;
                v16.Parent = Contents;

                for _, child in pairs(u3:GetChildren()) do
                    u17(child, Attribute * 100);
                end;
            end;

            task.spawn(function() -- Line: 140
                setthreadidentity(2)
                -- upvalues: Settings (copy), u17 (copy)
                for _, child in pairs(Settings:GetChildren()) do
                    u17(child);
                end;
            end);
        end;
        return u1;
    end)(),
    Shop = (function()setthreadidentity(2)
        local script = menus_folder.Shop
        local u1 = {};
        local math_floor = math.floor;
        local string_format = string.format;
        local Tabs = {
            Emotes = function()
                print("lol", debug.traceback()) 
                local script = menus_folder.Shop.Tabs.Emotes
                return {
                    test_lol = 69420,
                    CreateTab = function(u1, p2) -- Line: 3, Name: CreateTab
                        print("eeeeeety", debug.traceback())
                        print(u1, u1.test_lol)
                        u1.test_lol = 42099
                        setthreadidentity(2)
                        local Parent = script.Parent.Parent;
                        local CardTemplate = Parent.Templates.CardTemplate;
                        local SideContainer = p2.ShopRoot.SideContainer;
                        local Emotes = game.ReplicatedStorage.Assets.Emotes;
                        u1.Shop.ShopMenu.Toggled:Connect(function() -- Line: 10
                            -- upvalues: u1 (copy)
                            if u1.SFX then
                                game.TweenService:Create(u1.SFX, TweenInfo.new(0.1), {
                                    Volume = 0
                                }):Play();
                                game.Debris:AddItem(u1.SFX, 0.1);
                                u1.SFX = nil;
                            end;
                        end);
                        game.Players.LocalPlayer.CharacterAdded:Connect(function() -- Line: 20
                            setthreadidentity(2)
                            -- upvalues: u1 (copy)
                            if u1.SFX then
                                game.TweenService:Create(u1.SFX, TweenInfo.new(0.1), {
                                    Volume = 0
                                }):Play();
                                game.Debris:AddItem(u1.SFX, 0.1);
                                u1.SFX = nil;
                            end;
                        end);
                        local v3 = script.EmoteViewport:Clone();
                        local u4 = v3:FindFirstChildOfClass("WorldModel") or Instance.new("WorldModel", v3);
                        local v5 = {};

                        for _, child in pairs(u4:GetChildren()) do
                            if child.Name == "Rig" then
                                child:Destroy();
                            end;
                        end;

                        local LocalPlayer = game.Players.LocalPlayer;
                        local v6;

                        if LocalPlayer.Character then
                            LocalPlayer.Character.Archivable = true;
                            v6 = LocalPlayer.Character:Clone();
                            LocalPlayer.Character.Archivable = false;
                        else
                            v6 = nil;
                        end;

                        local v7;

                        if v6 then
                            v7 = v6;
                        else
                            local v8;
                            v8, v7 = pcall(function() -- Line: 49
                                setthreadidentity(2)
                                -- upvalues: LocalPlayer (copy)
                                return game.Players:CreateHumanoidModelFromUserId(LocalPlayer.UserId);
                            end);

                            if not v8 then
                                v7 = v6;
                            end;
                        end;

                        if v7 then
                            v7.Name = "Rig";

                            for _, descendant in pairs(v7:GetDescendants()) do
                                if descendant:IsA("LuaSourceContainer") then
                                    descendant:Destroy();
                                end;
                            end;

                            v7.Parent = u4;
                            v7:SetPrimaryPartCFrame(CFrame.new(0, 0, 0));
                        end;

                        local Camera = Instance.new("Camera");
                        Camera.FieldOfView = 25;
                        task.defer(function() -- Line: 71
                            -- upvalues: u4 (copy), Camera (copy)
                            local v9 = u4:FindFirstChild("Rig") and u4.Rig:FindFirstChild("Head");

                            if v9 then
                                Camera.CFrame = v9.CFrame * CFrame.Angles(0, 3.4906, 0) * CFrame.new(0, 0, 15) * CFrame.Angles(-0.1221, 0, 0);
                            end;
                        end);
                        Camera.Parent = v3;
                        v3.CurrentCamera = Camera;
                        u1.ViewportFrame = v3;

                        for _, child in pairs(Emotes:GetChildren()) do
                            local u10 = require(child);

                            if not u10.Exclusive then
                                local v11 = CardTemplate:Clone();
                                local Container = v11.Container;
                                v11.Name = child.Name;
                                v11.LayoutOrder = u10.Price or 1000;
                                Container.CharacterRender.Image = u10.RenderImage or "rbxassetid://13373279056";
                                Container.Title.Text = tostring(u10.DisplayName);
                                Container.Price.Text = (not u10.Price or u10.Price <= 0) and "FREE" or `{tostring(u10.Price)}$`;
                                Container.MouseEnter:Connect(function() -- Line: 93
                                    -- upvalues: Container (copy)
                                    game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                        Size = UDim2.fromScale(1.05, 1.05)
                                    }):Play();
                                end);
                                Container.MouseLeave:Connect(function() -- Line: 99
                                    -- upvalues: Container (copy)
                                    game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                        Size = UDim2.fromScale(1, 1)
                                    }):Play();
                                end);
                                Container.Interact.MouseButton1Click:Connect(function() -- Line: 105
                                    -- upvalues: u1 (copy), child (copy), SideContainer (copy), u10 (copy), Container (copy), u4 (copy)
                                    u1.Shop.CurrentlySelected = child;

                                    if u1.CurrentlyLoadedAnim then
                                        u1.CurrentlyLoadedAnim:Stop(0);
                                        u1.CurrentlyLoadedAnim = nil;
                                    end;

                                    SideContainer.PreviewContainer.Render.Image = "";
                                    SideContainer.PreviewContainer.Title.Text = tostring(u10.DisplayName);
                                    SideContainer.PreviewContainer.Quote.Text = tostring(u10.Description);
                                    SideContainer.PreviewContainer.Credits.Text = tostring(u10.Credits);
                                    SideContainer.PurchaseContainer.Price.Text = Container.Price.Text;
                                    SideContainer.PurchaseContainer.Buttons.Visible = false;
                                    SideContainer.Visible = true;
                                    game.TweenService:Create(SideContainer, TweenInfo.new(0.4), {
                                        Size = UDim2.fromScale(0.3, 1)
                                    }):Play();

                                    if u1.SFX then
                                        game.TweenService:Create(u1.SFX, TweenInfo.new(0.1), {
                                            Volume = 0
                                        }):Play();
                                        game.Debris:AddItem(u1.SFX, 0.1);
                                        u1.SFX = nil;
                                    end;

                                    if u1.CurrentAnimInfo and u1.CurrentAnimInfo.DestroyedServer then
                                        u1.CurrentAnimInfo.DestroyedServer(u1.CurrentEmoteData);
                                    end;

                                    if u1.CurrentAnimInfo and u1.CurrentAnimInfo.DestroyedClient then
                                        u1.CurrentAnimInfo.DestroyedClient(u1.CurrentEmoteData);
                                    end;

                                    u1.CurrentAnimInfo = u10;
                                    local AssetID = u10.AssetID;

                                    if typeof(AssetID) == "table" then
                                        if u10.isDuoAnim then
                                            AssetID = AssetID[1];
                                        else
                                            local v12 = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character.Name;

                                            if v12 then
                                                v12 = game.ReplicatedStorage.Assets.Survivors:FindFirstChild(v12);
                                            end;

                                            local v13 = v12 and v12:FindFirstChild("Config") and require(v12.Config).Class;

                                            if v13 and u10.AssetID[v13] then
                                                AssetID = u10.AssetID[v13];
                                            elseif u10.AssetID.Survivalist then
                                                AssetID = u10.AssetID.Survivalist;
                                            else
                                                AssetID = AssetID[math.random(#AssetID)];
                                            end;
                                        end;
                                    end;

                                    local v14 = require(game.ReplicatedStorage.Modules.Utilities.Util):LoadAnimationFromID(u4.Rig, AssetID);

                                    if v14 then
                                        local u15 = u10.SFXProperties or {};
                                        u15.SoundGroup = game.SoundService.Soundtrack;
                                        u1.SFX = Sounds:Play(u10.SFX, u15);
                                        task.spawn(function() -- Line: 159
                                            -- upvalues: u1 (ref)
                                            repeat
                                                task.wait();
                                            until not (u1.SFX and (u1.SFX.Parent and u1.SFX.TimeLength <= 0));

                                            if u1.SFX and u1.SFX.Parent then
                                                u1.SFX.PlaybackRegionsEnabled = true;
                                                u1.SFX.LoopRegion = NumberRange.new(0, (math.clamp(u1.SFX.TimeLength - 0.05, 0.1, 60000)));
                                            end;
                                        end);

                                        if v14.Looped and (u1.SFX and not u1.SFX.Looped) then
                                            v14.DidLoop:Connect(function() -- Line: 169
                                                -- upvalues: u1 (ref), Sounds (copy), u10 (ref), u15 (copy)
                                                if u1.SFX then
                                                    game.TweenService:Create(u1.SFX, TweenInfo.new(0.1), {
                                                        Volume = 0
                                                    }):Play();
                                                    game.Debris:AddItem(u1.SFX, 0.1);
                                                    u1.SFX = Sounds:Play(u10.SFX, u15);
                                                end;
                                            end);
                                        end;

                                        v14:Play(0);
                                        v14.Priority = Enum.AnimationPriority.Action;
                                        u1.CurrentlyLoadedAnim = v14;
                                    end;

                                    u1.CurrentEmoteData = {
                                        Player = game.Players.LocalPlayer,
                                        Character = u4.Rig,
                                        Emote = v14
                                    };

                                    if u1.CurrentAnimInfo and u1.CurrentAnimInfo.CreatedServer then
                                        u1.CurrentAnimInfo.CreatedServer(u1.CurrentEmoteData);
                                    end;

                                    if u1.CurrentAnimInfo and u1.CurrentAnimInfo.CreatedClient then
                                        u1.CurrentAnimInfo.CreatedClient(u1.CurrentEmoteData);
                                    end;
                                end);
                                table.insert(v5, v11);
                            end;
                        end;

                        return v5;
                    end,

                    Selected = function(u16, p17) -- Line: 204, Name: Selected
                        print(u16, u16.test_lol)
                        setthreadidentity(2)
                        u16.ViewportFrame.Parent = p17.ShopRoot.SideContainer.PreviewContainer;
                        task.spawn(function() -- Line: 207
                            -- upvalues: u16 (copy)
                            local v18 = u16.ViewportFrame:FindFirstChild("WorldModel") and u16.ViewportFrame.WorldModel:FindFirstChild("Rig");
                            local v19 = v18 and require(game.ReplicatedStorage.Modules.Utilities.Util):LoadAnimationFromID(v18, "rbxassetid://180435571");

                            if v19 then
                                v19.Looped = true;
                                v19:Play(0);
                                u16.IdleAnim = v19;
                            end;
                        end);
                    end,

                    Deselected = function(p20, p21) -- Line: 220, Name: Deselected
                        setthreadidentity(2)
                        if p20.CurrentlyLoadedAnim then
                            p20.CurrentlyLoadedAnim:Stop(0);
                            p20.CurrentlyLoadedAnim = nil;
                        end;

                        if p20.IdleAnim then
                            p20.IdleAnim:Stop(0);
                            p20.IdleAnim = nil;
                        end;

                        if p20.CurrentAnimInfo and p20.CurrentAnimInfo.Destroyed then
                            p20.CurrentAnimInfo.Destroyed(p20.CurrentEmoteData);
                        end;

                        if p20.SFX then
                            game.TweenService:Create(p20.SFX, TweenInfo.new(0.1), {
                                Volume = 0
                            }):Play();
                            game.Debris:AddItem(p20.SFX, 0.1);
                            p20.SFX = nil;
                        end;

                        p20.ViewportFrame.Parent = nil;
                    end
                };
            end,
            Killers = function()
                local script = menus_folder.Shop.Tabs.Killers
                return {
                    CreateTab = function(u1, p2) -- Line: 4, Name: CreateTab
                        setthreadidentity(2)
                        local CardTemplate = script.Parent.Parent.Templates.CardTemplate;
                        local SideContainer = p2.ShopRoot.SideContainer;
                        local v3 = {};

                        for _, child in pairs(game.ReplicatedStorage.Assets.Killers:GetChildren()) do
                            local Config = require(child.Config);

                            if not Config.Exclusive then
                                local v4 = CardTemplate:Clone();
                                local Container = v4.Container;
                                v4.Name = child.Name;
                                v4.LayoutOrder = Config.Price or 1000;
                                Container.CharacterRender.Image = Config.RenderImage or "rbxassetid://13373279056";
                                Container.Title.Text = tostring(Config.DisplayName);
                                Container.Price.Text = Config.Price <= 0 and "FREE" or `{tostring(Config.Price)}$`;
                                Container.Title.TextColor3 = Color3.fromRGB(255, 200, 200);
                                Container.MouseEnter:Connect(function() -- Line: 20
                                    -- upvalues: Container (copy)
                                    game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                        Size = UDim2.fromScale(1.05, 1.05)
                                    }):Play();
                                end);
                                Container.MouseLeave:Connect(function() -- Line: 26
                                    -- upvalues: Container (copy)
                                    game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                        Size = UDim2.fromScale(1, 1)
                                    }):Play();
                                end);
                                Container.Interact.MouseButton1Click:Connect(function() -- Line: 32
                                    setthreadidentity(2)
                                    -- upvalues: u1 (copy), child (copy), SideContainer (copy), Config (copy), Container (copy)
                                    u1.Shop.CurrentlySelected = child;
                                    SideContainer.PreviewContainer.Title.Text = tostring(Config.DisplayName);
                                    SideContainer.PreviewContainer.Quote.Text = tostring(Config.Quote);
                                    SideContainer.PreviewContainer.Credits.Text = tostring(Config.Credits);
                                    SideContainer.PreviewContainer.Render.Image = Config.SquareRenderImage or (Config.RenderImage or "rbxassetid://13373279056");
                                    SideContainer.PurchaseContainer.Price.Text = Container.Price.Text;
                                    SideContainer.PurchaseContainer.Buttons.Visible = true;
                                    SideContainer.Visible = true;
                                    game.TweenService:Create(SideContainer, TweenInfo.new(0.4), {
                                        Size = UDim2.fromScale(0.3, 1)
                                    }):Play();
                                end);
                                table.insert(v3, v4);
                            end;
                        end;

                        return v3;
                    end
                };
            end,
            Survivors = function()
                local script = menus_folder.Shop.Tabs.Survivors
                return {
                    CreateTab = function(u1, p2) -- Line: 4, Name: CreateTab
                        setthreadidentity(2)
                        local CardTemplate = script.Parent.Parent.Templates.CardTemplate;
                        local SideContainer = p2.ShopRoot.SideContainer;
                        local v3 = {};

                        for _, child in pairs(game.ReplicatedStorage.Assets.Survivors:GetChildren()) do
                            local Config = require(child.Config);

                            if not Config.Exclusive then
                                local v4 = CardTemplate:Clone();
                                local Container = v4.Container;
                                v4.Name = child.Name;
                                v4.LayoutOrder = Config.Price or 1000;
                                Container.CharacterRender.Image = Config.RenderImage or "rbxassetid://13373279056";
                                Container.Title.Text = tostring(Config.DisplayName);
                                Container.Price.Text = Config.Price <= 0 and "FREE" or `{tostring(Config.Price)}$`;
                                Container.Title.TextColor3 = Color3.fromRGB(200, 200, 255);
                                Container.MouseEnter:Connect(function() -- Line: 20
                                    -- upvalues: Container (copy)
                                    game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                        Size = UDim2.fromScale(1.05, 1.05)
                                    }):Play();
                                end);
                                Container.MouseLeave:Connect(function() -- Line: 26
                                    -- upvalues: Container (copy)
                                    game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                        Size = UDim2.fromScale(1, 1)
                                    }):Play();
                                end);
                                Container.Interact.MouseButton1Click:Connect(function() -- Line: 32
                                    setthreadidentity(2)
                                    -- upvalues: u1 (copy), child (copy), SideContainer (copy), Config (copy), Container (copy)
                                    u1.Shop.CurrentlySelected = child;
                                    SideContainer.PreviewContainer.Title.Text = tostring(Config.DisplayName);
                                    SideContainer.PreviewContainer.Quote.Text = tostring(Config.Quote);
                                    SideContainer.PreviewContainer.Credits.Text = tostring(Config.Credits);
                                    SideContainer.PreviewContainer.Render.Image = Config.SquareRenderImage or (Config.RenderImage or "rbxassetid://13373279056");
                                    SideContainer.PurchaseContainer.Price.Text = Container.Price.Text;
                                    SideContainer.PurchaseContainer.Buttons.Visible = true;
                                    SideContainer.Visible = true;
                                    game.TweenService:Create(SideContainer, TweenInfo.new(0.4), {
                                        Size = UDim2.fromScale(0.3, 1)
                                    }):Play();
                                end);
                                table.insert(v3, v4);
                            end;
                        end;

                        return v3;
                    end
                };
            end
        }
        local Temp = {
            Emotes = Tabs.Emotes()
        }
        Tabs.Emotes = function()
            return Temp.Emotes
        end
        function u1.SwitchTab(p2, p3) -- Line: 11
            -- upvalues: u1 (copy)
            if u1.LastTab == p3 then
                return;
            end;

            local Menu = u1.ShopMenu.Menu;
            local InfoContainer = Menu.ShopRoot.InfoContainer;
            local SideContainer = Menu.ShopRoot.SideContainer;
            local ProductDescription = Menu.ShopRoot.ProductDescription;
            local ShopContainer = Menu.ShopRoot.ShopContainer;
            local Topbar = ShopContainer.Topbar;
            local Searchbar = Topbar.Searchbar;

            if u1.ShopMenu.Menu.Visible and (p3 ~= "Robux" or u1.ShopMenu.Menu.Size.Y.Scale >= 0.2) then
                require(game:GetService("ReplicatedStorage").Modules.Rendering.Sounds):Play("select");
            end;

            game.TweenService:Create(SideContainer, TweenInfo.new(0.4), {
                Size = UDim2.fromScale(0, 1)
            }):Play();
            game.TweenService:Create(ProductDescription, TweenInfo.new(0.4), {
                Size = UDim2.fromScale(0, 0.5)
            });
            game.TweenService:Create(InfoContainer, TweenInfo.new(0.4), {
                Size = UDim2.fromScale(0, 1)
            }):Play();
            game.TweenService:Create(ShopContainer, TweenInfo.new(0.4), {
                Size = UDim2.fromScale(0.7, 1)
            }):Play();
            ShopContainer.Contents.UIPadding.PaddingTop = UDim.new(0, workspace.CurrentCamera.ViewportSize.Y / 40);

            for _, child in pairs(Topbar:GetChildren()) do
                if child:IsA("ImageButton") then
                    game.TweenService:Create(child, TweenInfo.new(0.25), {
                        ImageColor3 = p3 == child.Name and Color3.new(1, 1, 1) or Color3.new()
                    }):Play();
                    game.TweenService:Create(child.Title, TweenInfo.new(0.25), {
                        TextColor3 = p3 == child.Name and Color3.new() or Color3.new(1, 1, 1)
                    }):Play();
                end;
            end;

            for _, child in pairs(ShopContainer.Contents:GetChildren()) do
                if child:IsA("GuiObject") or child:IsA("Folder") then
                    child.Parent = nil;
                end;
            end;

            local v4 = Tabs[tostring(u1.LastTab)];

            if v4 then
                v4 = v4();
            else
                warn('WOW', u1)
            end;

            if v4 and v4.Selected then
                v4:Deselected(Menu);
            end;

            local v5 = u1.__tabsData[p3];

            if v5 then
                for _, v in pairs(v5) do
                    local Container = v:FindFirstChild("Container");

                    if Container then
                        Container = Container:FindFirstChild("Title");
                    end;

                    if v:IsA("GuiObject") then
                        v.Visible = not Container or (Searchbar.TextBox.Text == "" and true or string.find(Container.Text:lower(), Searchbar.TextBox.Text:lower()));
                    end;

                    v.Parent = ShopContainer.Contents;
                end;
            end;

            local v6 = Tabs[p3];

            if v6 then
                v6 = v6();
            else
                warn('WOWW', v6)
            end;

            if v6 and v6.Selected then
                v6:Selected(Menu);
            end;

            u1.LastTab = p3;
        end;
        function u1.Start(p7) -- Line: 79
            -- upvalues: u1 (copy), math_floor (copy), string_format (copy)
            local LocalPlayer = game.Players.LocalPlayer;
            local Purchased = LocalPlayer:WaitForChild("PlayerData"):WaitForChild("Purchased");
            local Initializer = require(game.ReplicatedStorage.Initializer);
            local Network = require(game.ReplicatedStorage.Modules.Network.Network);
            local Signal = require(game:GetService("ReplicatedStorage").Modules.Utilities.Signal);
            local u8 = Signal.new();
            local TextService = game:GetService("TextService");
            local UserInputService = game:GetService("UserInputService");
            local RunService = game:GetService("RunService");
            u1.ShopMenu = SidebarHandler:CreateSidebarMenu("Shop", script.ShopScreen);
            local Menu = u1.ShopMenu.Menu;
            local SideContainer = Menu.ShopRoot.SideContainer;
            local InfoContainer = Menu.ShopRoot.InfoContainer;
            local ShopContainer = Menu.ShopRoot.ShopContainer;
            local SkinsContainer = Menu.ShopRoot.SkinsContainer;
            local PurchaseContainer = SideContainer.PurchaseContainer;
            local Topbar = ShopContainer.Topbar;
            local Searchbar = Topbar.Searchbar;

            local function _(p9) -- Line: 100
                p9.CanvasSize = UDim2.fromScale(1, 0);

                if p9.AbsoluteCanvasSize.Y > p9.AbsoluteWindowSize.Y then
                    p9.CanvasSize = UDim2.new(1, 0, 0, p9.AbsoluteCanvasSize.Y * 1.05);
                end;
            end;

            ShopContainer.Contents.ChildAdded:Connect(function() -- Line: 106
                -- upvalues: ShopContainer (copy)
                local Contents = ShopContainer.Contents;
                Contents.CanvasSize = UDim2.fromScale(1, 0);

                if Contents.AbsoluteCanvasSize.Y > Contents.AbsoluteWindowSize.Y then
                    Contents.CanvasSize = UDim2.new(1, 0, 0, Contents.AbsoluteCanvasSize.Y * 1.05);
                end;
            end);
            ShopContainer.Contents.ChildRemoved:Connect(function() -- Line: 114
                -- upvalues: ShopContainer (copy)
                local Contents = ShopContainer.Contents;
                Contents.CanvasSize = UDim2.fromScale(1, 0);

                if Contents.AbsoluteCanvasSize.Y > Contents.AbsoluteWindowSize.Y then
                    Contents.CanvasSize = UDim2.new(1, 0, 0, Contents.AbsoluteCanvasSize.Y * 1.05);
                end;
            end);
            ShopContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() -- Line: 122
                -- upvalues: ShopContainer (copy)
                local Contents = ShopContainer.Contents;
                Contents.CanvasSize = UDim2.fromScale(1, 0);

                if Contents.AbsoluteCanvasSize.Y > Contents.AbsoluteWindowSize.Y then
                    Contents.CanvasSize = UDim2.new(1, 0, 0, Contents.AbsoluteCanvasSize.Y * 1.05);
                end;
            end);
            SkinsContainer.Contents.ChildAdded:Connect(function() -- Line: 130
                -- upvalues: SkinsContainer (copy)
                local Contents = SkinsContainer.Contents;
                Contents.CanvasSize = UDim2.fromScale(1, 0);

                if Contents.AbsoluteCanvasSize.Y > Contents.AbsoluteWindowSize.Y then
                    Contents.CanvasSize = UDim2.new(1, 0, 0, Contents.AbsoluteCanvasSize.Y * 1.05);
                end;
            end);
            SkinsContainer.Contents.ChildRemoved:Connect(function() -- Line: 138
                -- upvalues: SkinsContainer (copy)
                local Contents = SkinsContainer.Contents;
                Contents.CanvasSize = UDim2.fromScale(1, 0);

                if Contents.AbsoluteCanvasSize.Y > Contents.AbsoluteWindowSize.Y then
                    Contents.CanvasSize = UDim2.new(1, 0, 0, Contents.AbsoluteCanvasSize.Y * 1.05);
                end;
            end);
            SideContainer.Size = UDim2.fromScale(0, 1);
            SideContainer.Visible = false;
            u1.ShopMenu.Toggled:Connect(function(p10) -- Line: 148
                -- upvalues: PurchaseContainer (copy), SideContainer (copy), InfoContainer (copy), SkinsContainer (copy), ShopContainer (copy)
                game.TweenService:Create(PurchaseContainer.Buttons.ViewSkins.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 1
                }):Play();
                game.TweenService:Create(PurchaseContainer.Buttons.ViewInfo.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 1
                }):Play();
                game.TweenService:Create(SideContainer, TweenInfo.new(0.4), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                game.TweenService:Create(InfoContainer, TweenInfo.new(0.4), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                game.TweenService:Create(SkinsContainer, TweenInfo.new(0.4), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                game.TweenService:Create(ShopContainer, TweenInfo.new(0.4), {
                    Size = UDim2.fromScale(0.7, 1)
                }):Play();
                task.delay(0.25, function() -- Line: 168
                    -- upvalues: ShopContainer (ref)
                    ShopContainer.Visible = true;
                end);
            end);

            local function v12(p11) -- Line: 173
                -- upvalues: Sounds (copy)
                if not (p11.Name == "Money" or not (p11:IsA("TextButton") or p11:IsA("ImageButton")) or p11:GetAttribute("SFXImplemented")) then
                    p11:SetAttribute("SFXImplemented", true);
                    p11.MouseEnter:Connect(function() -- Line: 177
                        -- upvalues: Sounds (ref)
                        Sounds:Play("hover");
                    end);
                    p11.MouseLeave:Connect(function() -- Line: 181
                        -- upvalues: Sounds (ref)
                        Sounds:Play("hoverEnd");
                    end);

                    if p11.Parent.Name ~= "Topbar" then
                        p11.MouseButton1Click:Connect(function() -- Line: 186
                            -- upvalues: Sounds (ref)
                            Sounds:Play("select");
                        end);
                    end;
                end;
            end;

            for _, descendant in pairs(Menu:GetDescendants()) do
                v12(descendant);
            end;

            Menu.DescendantAdded:Connect(v12);
            local Util = require(game:GetService("ReplicatedStorage").Modules.Utilities.Util);
            Util:CreateMoneyDisplay(ShopContainer.Money);

            local function u14(p13) -- Line: 199
                -- upvalues: Purchased (copy)
                if p13:IsA("Frame") and (not p13.Container:FindFirstChild("Purchased") and Purchased:FindFirstChild(p13.Name, true)) then
                    local Frame = Instance.new("Frame");
                    Frame.Name = "Purchased";
                    Frame.ZIndex = 10;
                    Frame.BorderSizePixel = 0;
                    Frame.BackgroundTransparency = 0.25;
                    Frame.BackgroundColor3 = Color3.new();
                    Frame.Position = UDim2.fromScale(0.5, 0.5);
                    Frame.AnchorPoint = Vector2.new(0.5, 0.5);
                    Frame.Size = UDim2.fromScale(1.05, 1.05);
                    Frame.Parent = p13.Container;
                    local TextLabel = Instance.new("TextLabel");
                    TextLabel.Name = "Title";
                    TextLabel.Text = "Owned";
                    TextLabel.BackgroundTransparency = 1;
                    TextLabel.TextScaled = true;
                    TextLabel.Size = UDim2.fromScale(0.85, 0.125);
                    TextLabel.Position = UDim2.fromScale(0.5, 0.5);
                    TextLabel.AnchorPoint = Vector2.new(0.5, 0.5);
                    TextLabel.TextColor3 = Color3.new(1, 1, 1);
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/AccanthisADFStd.json");
                    TextLabel.Parent = Frame;
                    p13.LayoutOrder = p13.LayoutOrder + 100000000;
                end;
            end;

            local function u22(p15) -- Line: 226
                -- upvalues: u1 (ref), Menu (copy), Purchased (copy), Network (copy)
                local v16 = p15 and p15:FindFirstChild("Config") or u1.CurrentlySelected and (u1.CurrentlySelected:FindFirstChild("Config") or u1.CurrentlySelected:IsA("ModuleScript") and u1.CurrentlySelected);

                if v16 then
                    v16 = require(v16);
                end;

                if v16 and not Menu:FindFirstChild("ConfirmPurchase") then
                    local u17 = script.Templates.ConfirmPurchase:Clone();
                    u17.Size = UDim2.fromScale(0.3, 0);
                    u17.Title.Text = `Are you sure you would like to purchase <b><font color="rgb(255,255,255)">{tostring(v16.DisplayName)}</font></b> for <b><font color="rgb(255,255,255)">{v16.Price <= 0 and "FREE" or `{tostring(v16.Price)}$`}</font></b>?`;
                    u17.Parent = Menu;
                    game.TweenService:Create(u17, TweenInfo.new(0.3), {
                        Size = UDim2.fromScale(0.3, 0.3)
                    }):Play();

                    if p15 and not (Purchased.Killers:FindFirstChild((tostring(u1.CurrentlySelected))) or Purchased.Survivors:FindFirstChild((tostring(u1.CurrentlySelected)))) then
                        u17.Disclaimer.Text = "DISCLAIMER:\nYou don\'t own this character yet.\nWhatever you\'re trying to do right now is dumb.";
                    elseif v16.DisclaimerText then
                        u17.Disclaimer.Text = `DISCLAIMER:\n{tostring(v16.DisclaimerText)}`;
                    end;

                    local Title = u17.Buttons.Yes.Title;
                    local u18 = p15 or u1.CurrentlySelected;
                    local u19 = false;
                    local u20 = false;
                    u17.Buttons.Yes.MouseButton1Click:Connect(function() -- Line: 249
                        -- upvalues: u19 (ref), Title (copy), Network (ref), u18 (copy), u20 (ref), u17 (copy)
                        if not u19 then
                            u19 = true;
                            Title.Text = "...";
                            local v21 = Network:FireServerConnection("PurchaseContent", "REMOTE_FUNCTION", u18);

                            if v21.Status == "success" then
                                Title.Text = "Bought!";
                                task.wait(0.5);

                                if not u20 then
                                    u20 = true;
                                    game.TweenService:Create(u17, TweenInfo.new(0.3), {
                                        Size = UDim2.fromScale(0.3, 0)
                                    }):Play();
                                    game.Debris:AddItem(u17, 0.3);
                                end;

                                return;
                            end;

                            if v21.Status == "poor" then
                                Title.Text = "Insufficient funds!";
                            elseif v21.Status == "alreadyBought" then
                                Title.Text = "Already owned! (You were not charged)";
                            elseif v21.Status == "rateLimited" then
                                Title.Text = "Ratelimited! (You were not charged)";
                            elseif v21.Status == "failed" then
                                Title.Text = "Something went wrong... (You were not charged)";
                            end;

                            task.delay(0.5, function() -- Line: 276
                                -- upvalues: u19 (ref), Title (ref)
                                u19 = false;
                                Title.Text = "Yes";
                            end);
                        end;
                    end);
                    u17.Buttons.No.MouseButton1Click:Connect(function() -- Line: 284
                        -- upvalues: u20 (ref), u17 (copy)
                        if not u20 then
                            u20 = true;
                            game.TweenService:Create(u17, TweenInfo.new(0.3), {
                                Size = UDim2.fromScale(0.3, 0)
                            }):Play();
                            game.Debris:AddItem(u17, 0.3);
                        end;
                    end);
                end;
            end;

            PurchaseContainer.Purchase.MouseButton1Click:Connect(u22);
            SkinsContainer.Contents.ChildAdded:Connect(u14);
            ShopContainer.Contents.ChildAdded:Connect(u14);
            Purchased.DescendantAdded:Connect(function(p23) -- Line: 300
                -- upvalues: ShopContainer (copy), SkinsContainer (copy), u14 (copy)
                local v24 = ShopContainer.Contents:FindFirstChild(p23.Name) or SkinsContainer.Contents:FindFirstChild(p23.Name);

                if v24 then
                    u14(v24);
                end;
            end);
            local u25 = nil;

            local function u52(u26) -- Line: 308
                -- upvalues: u25 (ref), InfoContainer (copy), Menu (copy), LocalPlayer (copy), UserInputService (copy), TextService (copy), Util (copy)
                if u25 ~= u26 then
                    u25 = u26;
                    local script_Templates = script.Templates;
                    local u27 = {};

                    for _, child in pairs(InfoContainer.Contents:GetChildren()) do
                        if child:IsA("GuiObject") then
                            child:Destroy();
                        end;
                    end;

                    for i, v in pairs(u26 or {}) do
                        local Frame = Instance.new("Frame");
                        Frame.Name = "Content";
                        Frame.BackgroundTransparency = 1;
                        Frame.Size = UDim2.fromScale(1, 0);
                        Frame.AutomaticSize = Enum.AutomaticSize.Y;
                        Frame.LayoutOrder = i;
                        Frame.Parent = InfoContainer.Contents;
                        local UIListLayout = Instance.new("UIListLayout");
                        UIListLayout.Padding = UDim.new(0, 10);
                        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
                        UIListLayout.Parent = Frame;
                        local _ = workspace.CurrentCamera.ViewportSize.Y;
                        local v28 = v;

                        for i2, v2 in pairs(v) do
                            if i2 == "Separator" then
                                local v29 = script_Templates.Seperator:Clone();
                                v29.Title.Text = tostring(v2);
                                v29.Parent = Frame;
                            elseif i2 == "Header" then
                                local v30 = script_Templates.Header:Clone();
                                v30.Text = tostring(v2);
                                v30.Parent = Frame;
                            elseif i2 == "Quote" then
                                local v31 = script_Templates.Quote:Clone();
                                v31.Text = tostring(v2);
                                v31.Parent = Frame;
                            elseif i2 == "Text" then
                                local v32 = script_Templates.TextContainer:Clone();
                                v32.Title.MaxVisibleGraphemes = 0;
                                v32.Title.Text = tostring(v2);
                                v32.Image.Image = tostring(v28.Image);
                                v32.Image.Visible = v28.Image;
                                v32.Parent = Frame;
                                table.insert(u27, v32.Title);
                                game.TweenService:Create(v32.Title, TweenInfo.new(5, Enum.EasingStyle.Quint), {
                                    MaxVisibleGraphemes = #v32.Title.Text + 10
                                }):Play();
                            end;
                        end;
                    end;

                    task.spawn(function() -- Line: 361
                        setthreadidentity(2)
                        -- upvalues: u26 (copy), u25 (ref), Menu (ref), InfoContainer (ref), LocalPlayer (ref), UserInputService (ref), u27 (copy), TextService (ref), Util (ref)
                        local u33 = {};

                        local function u36(p34) -- Line: 365
                            -- upvalues: u36 (copy), u33 (copy)
                            if p34:IsA("Folder") then
                                for _, child in pairs(p34:GetChildren()) do
                                    u36(child);
                                end;

                                return;
                            end;

                            if p34:IsA("ModuleScript") then
                                local v35 = require(p34);
                                u33[p34.Name] = v35.Data.Description or "???";
                            end;
                        end;

                        u36(game.ReplicatedStorage.Modules.StatusEffects);
                        local v37 = nil;
                        local v38 = false;

                        while true do
                            while true do
                                if not (task.wait() and (u26 and u25 == u26)) then
                                    return;
                                end;

                                if not (Menu.Visible and (InfoContainer.Size.X.Scale >= 0.5 and (LocalPlayer.Character and tostring(LocalPlayer.Character.Parent) == "Spectating"))) then
                                    break;
                                end;

                                local v39 = UserInputService:GetMouseLocation() - game.GuiService:GetGuiInset();
                                local v40 = false;

                                for _, v in pairs(u27) do
                                    if v40 then
                                        break;
                                    end;

                                    local AbsolutePosition = v.AbsolutePosition;
                                    local AbsoluteSize = v.AbsoluteSize;

                                    if v39.X >= AbsolutePosition.X and (v39.X <= AbsolutePosition.X + AbsoluteSize.X and (v39.Y >= AbsolutePosition.Y and v39.Y <= AbsolutePosition.Y + AbsoluteSize.Y)) then
                                        local v41 = v.Text:gsub("<.->", "");
                                        local Font2 = v.Font;
                                        local TextSize = v.TextSize;
                                        local X = AbsoluteSize.X;
                                        local v42 = v41:split("\n");
                                        local v43 = {};

                                        for _, v2 in ipairs(v42) do
                                            local v44 = v2:split(" ");
                                            local v45 = {};
                                            local v46 = 0;

                                            for _, v3 in ipairs(v44) do
                                                local TextSize2 = TextService:GetTextSize(v3, TextSize, Font2, Vector2.new(X, (1 / 0)));
                                                local X2 = TextService:GetTextSize(" ", TextSize, Font2, Vector2.new(X, (1 / 0))).X;

                                                if X < v46 + TextSize2.X then
                                                    table.insert(v43, v45);
                                                    v45 = {};
                                                    v46 = 0;
                                                end;

                                                table.insert(v45, v3);
                                                v46 = v46 + TextSize2.X + X2;
                                            end;

                                            if #v45 > 0 then
                                                table.insert(v43, v45);
                                            end;
                                        end;

                                        local Y = TextService:GetTextSize("Test", TextSize, Font2, Vector2.new(X, (1 / 0))).Y;
                                        local v47 = 0;

                                        for _, v2 in ipairs(v43) do
                                            if v40 then
                                                break;
                                            end;

                                            local v48 = AbsolutePosition.Y + v47;

                                            if v48 <= v39.Y and v48 + Y >= v39.Y then
                                                local v49 = 0;

                                                for _, v3 in ipairs(v2) do
                                                    local TextSize2 = TextService:GetTextSize(v3, TextSize, Font2, Vector2.new(X, (1 / 0)));
                                                    local v50 = AbsolutePosition.X + v49;

                                                    if v50 <= v39.X and v50 + TextSize2.X >= v39.X then
                                                        local _ = game.ReplicatedStorage.Modules.StatusEffects;
                                                        local v51 = u33[v3];

                                                        if v51 then
                                                            v37 = Util:CreateTooltip(v51);
                                                            v38 = true;
                                                            v40 = true;
                                                        else
                                                            v38 = true;
                                                        end;
                                                    else
                                                        local X2 = TextService:GetTextSize(" ", TextSize, Font2, Vector2.new(X, (1 / 0))).X;
                                                        v49 = v49 + TextSize2.X + X2;
                                                    end;

                                                    if v38 or v38 then
                                                        break;
                                                    end;
                                                end;

                                                if not (v38 or v38) then
                                                    break;
                                                end;
                                            else
                                                v47 = v47 + Y;
                                            end;

                                            if v38 or v38 then
                                                break;
                                            end;
                                        end;
                                    end;

                                    v38 = false;
                                end;

                                if not v40 then
                                    v37 = Util:CreateTooltip();
                                end;
                            end;

                            if v37 then
                                v37 = Util:CreateTooltip();
                            end;
                        end;
                    end);
                end;
            end;

            local u53 = nil;

            local function u68(u54) -- Line: 484
                -- upvalues: u53 (ref), SkinsContainer (copy), u1 (ref), u8 (copy), math_floor (ref), string_format (ref), Util (copy), u22 (copy)
                if u54 and u53 ~= u54 then
                    u53 = u54;

                    for _, child in pairs(SkinsContainer.Contents:GetChildren()) do
                        if child:IsA("GuiObject") then
                            child:Destroy();
                        end;
                    end;

                    local v55 = u1.CurrentlySelected and u1.CurrentlySelected:FindFirstChild("Config");

                    if v55 then
                        v55 = require(v55);
                    end;

                    SkinsContainer.TitleDisplay.Title.Text = `{v55.DisplayName or tostring(u54.Name)} Skins`;
                    task.spawn(function() -- Line: 496
                        setthreadidentity(2)
                        -- upvalues: u54 (copy), SkinsContainer (ref), u8 (ref), math_floor (ref), string_format (ref), Util (ref), u22 (ref)
                        for _, child in pairs(u54:GetChildren()) do
                            local success, result = pcall(require, child.Config);

                            if success then
                                if not result.Exclusive then
                                    local u56 = script.Templates.CardTemplate:Clone();
                                    local Container = u56.Container;
                                    u56.Name = child.Name;
                                    u56.LayoutOrder = result.Price or 1000;
                                    u56.Parent = SkinsContainer.Contents;
                                    Container.CharacterRender.Image = result.RenderImage or "rbxassetid://13373279056";
                                    Container.Title.Text = tostring(result.DisplayName);
                                    Container.Price.Text = result.Price <= 0 and "FREE" or `{tostring(result.Price)}$`;
                                    local LimitedTimeData = result.LimitedTimeData;

                                    if result.LimitedTimeData then
                                        local u57 = 0;
                                        local u62 = u8:Connect(function(p58) -- Line: 516
                                            -- upvalues: u57 (ref), Container (copy), LimitedTimeData (copy), u56 (copy), math_floor (ref), string_format (ref)
                                            local UnixTimestamp = DateTime.now().UnixTimestamp;

                                            if UnixTimestamp == u57 then
                                                return;
                                            end;

                                            if not (Container and Container.LimitedTime) then
                                                return;
                                            end;

                                            u57 = UnixTimestamp;
                                            local EndUnix = LimitedTimeData.EndUnix;
                                            local v59 = EndUnix - UnixTimestamp;
                                            local v60;

                                            if LimitedTimeData.StartUnix < UnixTimestamp then
                                                v60 = UnixTimestamp < EndUnix;
                                            else
                                                v60 = false;
                                            end;

                                            u56.Visible = v60;
                                            Container.LimitedTime.Visible = v60;

                                            if not v60 or v59 <= 0 then
                                                return;
                                            end;

                                            local v61 = string_format("%02dd %02dh %02ds", math_floor(v59 / 86400), math_floor(v59 % 86400 / 3600), v59 % 60);

                                            if Container.LimitedTime.Text ~= v61 then
                                                Container.LimitedTime.Text = v61;
                                            end;
                                        end);
                                        u56.AncestryChanged:Connect(function(p63, p64) -- Line: 548
                                            -- upvalues: u62 (copy)
                                            if p64 == nil then
                                                u62:Disconnect();
                                            end;
                                        end);
                                    end;

                                    local u65;

                                    if result.ExclusiveText then
                                        script.Templates.ExclusiveGradient:Clone().Parent = Container.Outline;
                                        Container.Outline.ImageColor3 = Color3.new(1, 1, 1);
                                        u65 = script.Templates.ExclusiveTitle:Clone();
                                        u65.Text = tostring(result.ExclusiveText);
                                        u65.Parent = Container;
                                    else
                                        u65 = nil;
                                    end;

                                    if result.Uncommon then
                                        script.Templates.UncommonGradient:Clone().Parent = Container.Outline;
                                        Container.Outline.ImageColor3 = Color3.new(1, 1, 1);
                                    end;

                                    if result.Epic then
                                        script.Templates.EpicGradient:Clone().Parent = Container.Outline;
                                        Container.Outline.ImageColor3 = Color3.new(1, 1, 1);
                                    end;

                                    if result.Legendary then
                                        script.Templates.LegendaryGradient:Clone().Parent = Container.Outline;
                                        Container.Outline.ImageColor3 = Color3.new(1, 1, 1);
                                    end;

                                    local u66 = require(game.ReplicatedStorage.Modules.Schematics.IngameCollabs)[result.CollabInfo] or result.CollabInfo;

                                    if typeof(u66) == "table" then
                                        local v67 = game.ReplicatedStorage.Assets.UI.ShopCardIcon:Clone();
                                        v67.Image = u66.Icon or "rbxassetid://9011713759";
                                        v67.Parent = Container.CardIcons;
                                        v67.MouseEnter:Connect(function() -- Line: 581
                                            -- upvalues: Util (ref), u66 (copy)
                                            Util:CreateTooltip(u66.Description);
                                        end);
                                        v67.MouseLeave:Connect(function() -- Line: 585
                                            -- upvalues: Util (ref)
                                            Util:CreateTooltip();
                                        end);
                                    end;

                                    local Name = u54.Parent.Name;

                                    if Name == "Survivors" then
                                        Container.Title.TextColor3 = Color3.fromRGB(200, 200, 255);
                                    elseif Name == "Killers" then
                                        Container.Title.TextColor3 = Color3.fromRGB(255, 200, 200);
                                    end;

                                    Container.MouseEnter:Connect(function() -- Line: 598
                                        -- upvalues: Container (copy), u65 (copy)
                                        game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                            Size = UDim2.fromScale(1.05, 1.05)
                                        }):Play();

                                        if u65 then
                                            game.TweenService:Create(u65, TweenInfo.new(0.175), {
                                                TextTransparency = 0,
                                                TextStrokeTransparency = 0
                                            }):Play();
                                        end;
                                    end);
                                    Container.MouseLeave:Connect(function() -- Line: 610
                                        -- upvalues: Container (copy), u65 (copy)
                                        game.TweenService:Create(Container, TweenInfo.new(0.25), {
                                            Size = UDim2.fromScale(1, 1)
                                        }):Play();

                                        if u65 then
                                            game.TweenService:Create(u65, TweenInfo.new(0.175), {
                                                TextTransparency = 1,
                                                TextStrokeTransparency = 1
                                            }):Play();
                                        end;
                                    end);
                                    Container.Interact.MouseButton1Click:Connect(function() -- Line: 622
                                        -- upvalues: Container (copy), u22 (ref), child (copy)
                                        if not Container:FindFirstChild("Purchased") then
                                            u22(child);
                                        end;
                                    end);
                                end;
                            else
                                print((`[Shop]: Failed to get information for skin: {child.Name}`));
                            end;
                        end;
                    end);
                end;
            end;

            local u69 = nil;
            local u70 = false;
            PurchaseContainer.Buttons.ViewInfo.MouseButton1Click:Connect(function() -- Line: 636
                -- upvalues: u70 (ref), u1 (ref), u52 (copy), u69 (ref), InfoContainer (copy), PurchaseContainer (copy), SkinsContainer (copy), ShopContainer (copy)
                if u70 then
                    return;
                end;

                u70 = true;
                local v71 = u1.CurrentlySelected and u1.CurrentlySelected:FindFirstChild("Config");

                if v71 then
                    v71 = require(v71);
                end;

                if not (v71 and v71.Information) then
                    u70 = false;

                    return;
                end;

                u52(v71.Information);

                if u69 then
                    task.cancel(u69);
                end;

                if InfoContainer.Size.X.Scale >= 0.35 then
                    game.TweenService:Create(PurchaseContainer.Buttons.ViewSkins.Inverted, TweenInfo.new(0.25), {
                        ImageTransparency = 1
                    }):Play();
                    game.TweenService:Create(PurchaseContainer.Buttons.ViewInfo.Inverted, TweenInfo.new(0.25), {
                        ImageTransparency = 1
                    }):Play();
                    game.TweenService:Create(SkinsContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0, 1)
                    }):Play();
                    game.TweenService:Create(InfoContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0, 1)
                    }):Play();
                    game.TweenService:Create(ShopContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0.7, 1)
                    }):Play();
                    u69 = task.delay(0.25, function() -- Line: 668
                        -- upvalues: SkinsContainer (ref), InfoContainer (ref)
                        SkinsContainer.Visible = false;
                        InfoContainer.Visible = false;
                    end);
                    task.delay(0.175, function() -- Line: 673
                        -- upvalues: u70 (ref)
                        u70 = false;
                    end);
                    ShopContainer.Visible = true;

                    return;
                end;

                game.TweenService:Create(PurchaseContainer.Buttons.ViewSkins.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 1
                }):Play();
                game.TweenService:Create(PurchaseContainer.Buttons.ViewInfo.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 0
                }):Play();
                game.TweenService:Create(SkinsContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                game.TweenService:Create(InfoContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0.7, 1)
                }):Play();
                game.TweenService:Create(ShopContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                u69 = task.delay(0.25, function() -- Line: 695
                    -- upvalues: SkinsContainer (ref), ShopContainer (ref)
                    SkinsContainer.Visible = false;
                    ShopContainer.Visible = false;
                end);
                task.delay(0.175, function() -- Line: 700
                    -- upvalues: u70 (ref)
                    u70 = false;
                end);
                InfoContainer.Visible = true;
            end);
            PurchaseContainer.Buttons.ViewSkins.MouseButton1Click:Connect(function() -- Line: 710
                -- upvalues: u70 (ref), u1 (ref), u68 (copy), u69 (ref), SkinsContainer (copy), PurchaseContainer (copy), InfoContainer (copy), ShopContainer (copy)
                if u70 then
                    return;
                end;

                u70 = true;

                if not u1.CurrentlySelected then
                    return;
                end;

                local v72 = game.ReplicatedStorage.Assets.Skins:FindFirstChild((tostring(u1.CurrentlySelected.Parent)));

                if v72 then
                    v72 = v72:FindFirstChild((tostring(u1.CurrentlySelected)));
                end;

                if not v72 then
                    u70 = false;

                    return;
                end;

                u68(v72);

                if u69 then
                    task.cancel(u69);
                end;

                if SkinsContainer.Size.X.Scale >= 0.35 then
                    game.TweenService:Create(PurchaseContainer.Buttons.ViewSkins.Inverted, TweenInfo.new(0.25), {
                        ImageTransparency = 1
                    }):Play();
                    game.TweenService:Create(PurchaseContainer.Buttons.ViewInfo.Inverted, TweenInfo.new(0.25), {
                        ImageTransparency = 1
                    }):Play();
                    game.TweenService:Create(SkinsContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0, 1)
                    }):Play();
                    game.TweenService:Create(InfoContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0, 1)
                    }):Play();
                    game.TweenService:Create(ShopContainer, TweenInfo.new(0.25), {
                        Size = UDim2.fromScale(0.7, 1)
                    }):Play();
                    u69 = task.delay(0.25, function() -- Line: 745
                        -- upvalues: InfoContainer (ref), SkinsContainer (ref)
                        InfoContainer.Visible = false;
                        SkinsContainer.Visible = false;
                    end);
                    task.delay(0.175, function() -- Line: 750
                        -- upvalues: u70 (ref)
                        u70 = false;
                    end);
                    ShopContainer.Visible = true;

                    return;
                end;

                game.TweenService:Create(PurchaseContainer.Buttons.ViewSkins.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 0
                }):Play();
                game.TweenService:Create(PurchaseContainer.Buttons.ViewInfo.Inverted, TweenInfo.new(0.25), {
                    ImageTransparency = 1
                }):Play();
                game.TweenService:Create(SkinsContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0.7, 1)
                }):Play();
                game.TweenService:Create(InfoContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                game.TweenService:Create(ShopContainer, TweenInfo.new(0.25), {
                    Size = UDim2.fromScale(0, 1)
                }):Play();
                u69 = task.delay(0.25, function() -- Line: 772
                    -- upvalues: InfoContainer (ref), ShopContainer (ref)
                    InfoContainer.Visible = false;
                    ShopContainer.Visible = false;
                end);
                task.delay(0.175, function() -- Line: 777
                    -- upvalues: u70 (ref)
                    u70 = false;
                end);
                SkinsContainer.Visible = true;
            end);

            for _, child in pairs(PurchaseContainer.Buttons:GetChildren()) do
                local Attribute = child:GetAttribute("Description");

                if Attribute then
                    child.Title.TextTransparency = 0;
                    child.Title.Text = Attribute;
                end;
            end;

            u1.__tabsData = {};

            for name, tabFn in pairs(Tabs) do
                local v73 = tabFn();
                v73.Shop = u1;
                local v74 = v73:CreateTab(Menu);
                u1.__tabsData[name] = v74;
            end;

            u1:SwitchTab("Killers");

            for _, child in pairs(Topbar:GetChildren()) do
                if child:IsA("ImageButton") then
                    child.MouseButton1Click:Connect(function() -- Line: 805
                        -- upvalues: u1 (ref), child (copy)
                        u1:SwitchTab(child.Name);
                    end);
                end;
            end;

            Searchbar.TextBox:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 811
                -- upvalues: ShopContainer (copy), Searchbar (copy)
                for _, child in pairs(ShopContainer.Contents:GetChildren()) do
                    if child:IsA("Frame") then
                        local Title = child.Container.Title;
                        pcall(function() -- Line: 816
                            -- upvalues: child (copy), Searchbar (ref), Title (copy)
                            child.Visible = Searchbar.TextBox.Text == "" and true or string.find(Title.Text:lower(), Searchbar.TextBox.Text:lower());
                        end);
                    end;
                end;
            end);
            RunService.Heartbeat:Connect(function(p75) -- Line: 828
                -- upvalues: u8 (copy)
                u8:FireDeferred(p75);
            end);
        end;
        return u1;
    end)(),
    Stats = (function()setthreadidentity(2)
        local script = menus_folder.Stats
        local u1 = {};
        function u1.Start(p2) -- Line: 4
            -- upvalues: u1 (copy)
            local Stats = game.Players.LocalPlayer:WaitForChild("PlayerData"):WaitForChild("Stats");
            u1.StatsMenu = SidebarHandler:CreateSidebarMenu("Stats", script.StatsScreen);
            local Contents = u1.StatsMenu.Menu.StatsContainer.Contents;
            local script_Templates = script.Templates;

            local function u9(u3, p4) -- Line: 10
                -- upvalues: script_Templates (copy), Contents (copy), u9 (copy)
                local v5 = p4 or 0;
                local Attribute = u3:GetAttribute("LayoutOrder");

                if not Attribute then
                    return;
                end;

                local Attribute2 = u3:GetAttribute("DisplayTitle");

                if not Attribute2 then
                    return;
                end;

                local Attribute3 = u3:GetAttribute("PostDisplayTitle");

                if not u3:IsA("Folder") then
                    if u3:IsA("NumberValue") then
                        local u6 = script_Templates.Title:Clone();
                        u6.Name = u3.Name;
                        u6.LayoutOrder = Attribute + v5;
                        u6.Parent = Contents;

                        local function v7() -- Line: 40
                            -- upvalues: Attribute3 (copy), u6 (copy), Attribute2 (copy), u3 (copy)
                            if Attribute3 == "Time" then
                                u6.Text = `{Attribute2}: {require(game:GetService("ReplicatedStorage").Modules.Utilities.Util):FormatTime(u3.Value, "String")}`;
                            else
                                u6.Text = `{Attribute2}: {u3.Value}{Attribute3 or ""}`;
                            end;

                            if u3:GetAttribute("HideIfZero") then
                                u6.Visible = u3.Value ~= 0;
                            end;
                        end;

                        u3:GetPropertyChangedSignal("Value"):Connect(v7);
                        v7();
                    end;

                    return;
                end;

                local v8 = script_Templates.Seperator:Clone();
                v8.Name = u3.Name;
                v8.LayoutOrder = Attribute * 100 + v5;
                v8.Title.Text = Attribute2;
                v8.Parent = Contents;

                for _, child in pairs(u3:GetChildren()) do
                    u9(child, Attribute * 100);
                end;
            end;

            for _, child in pairs(Stats:GetChildren()) do
                u9(child);
            end;
        end;
        return u1;
    end)(),
    Rules = (function()
        local script = ReplicatedStorage.Menus.Rules
        local UpdatelogPresets = ReplicatedStorage.Assets.UI.UpdatelogPresets;
        local TweenInfo_new_ret = TweenInfo.new(0.2);
        local u1 = {};

        function u1.Start(p2) -- Line: 20
            -- upvalues: u1 (copy), Initializer (copy), ReplicatedStorage (copy), UpdatelogPresets (copy), TweenService (copy), TweenInfo_new_ret (copy), Sounds (copy)
            u1.RulesMenu = SidebarHandler:CreateSidebarMenu("Rules", script.RulesScreen, true);
            local success, result = pcall(function() -- Line: 24
                -- upvalues: ReplicatedStorage (ref)
                return require(ReplicatedStorage.Assets.Rules);
            end);


            local v3 = 1;

            for i = 1, #result do
                local v4 = result[i];
                local v5 = UpdatelogPresets.Components.Header:Clone();
                v5.Text = v4.Header;
                v5.LayoutOrder = v3;
                v5.Parent = u1.RulesMenu.Menu.RulesContainer.Contents;
                local v6 = UpdatelogPresets.Components.Seperator:Clone();
                v6.LayoutOrder = v3 + 1;
                v6.Parent = u1.RulesMenu.Menu.RulesContainer.Contents;
                local v7 = UpdatelogPresets.Components.TextPreset:Clone();
                v7.Main.Text = v4.Body;
                v7.AutomaticSize = Enum.AutomaticSize.None;
                v7.Size = v4.NoteSize or UDim2.fromScale(0.9, 0.5);
                v7.LayoutOrder = v3 + 2;
                v7.Parent = u1.RulesMenu.Menu.RulesContainer.Contents;
                v3 = v3 + 3;
                local _ = i;
            end;

            local Exit = u1.RulesMenu.Menu.RulesContainer.Exit;
            Exit.MouseEnter:Connect(function() -- Line: 60
                -- upvalues: TweenService (ref), Exit (copy), TweenInfo_new_ret (ref), Sounds (ref)
                TweenService:Create(Exit, TweenInfo_new_ret, {
                    Size = UDim2.fromScale(0.175, 0.175)
                }):Play();
                Sounds:Play("hover");
            end);
            Exit.MouseLeave:Connect(function() -- Line: 65
                -- upvalues: TweenService (ref), Exit (copy), TweenInfo_new_ret (ref), Sounds (ref)
                TweenService:Create(Exit, TweenInfo_new_ret, {
                    Size = UDim2.fromScale(0.15, 0.15)
                }):Play();
                Sounds:Play("hoverEnd");
            end);
            Exit.MouseButton1Click:Connect(function() -- Line: 70
                -- upvalues: u1 (ref)
                u1.RulesMenu:ToggleMenu(false);
            end);
        end;

        return u1;
    end)()
}

for i, v in pairs(menus) do
    print('Requiring', i)
    --local suc, res = pcall(function()
        v.Start()
    --end)
    --if not suc then
    --    warn('Error loading menu', i, 'error:', tostring(res))
    --end
end

function SidebarHandler:Run()
    local script = ReplicatedStorage.Modules.Round.Spectating
    local TweenService = game:GetService("TweenService");
    local RunService = game:GetService("RunService");
    local ReplicatedStorage = game:GetService("ReplicatedStorage");
    local UserInputService = game:GetService("UserInputService");
    require(ReplicatedStorage.Initializer);
    local Network = require(ReplicatedStorage.Modules.Network.Network);
    local Device = require(ReplicatedStorage.Modules.Utilities.Device);
    local DataHandler = require(ReplicatedStorage.Modules.Data.DataHandler);
    local Heartbeat = require(ReplicatedStorage.Systems.Player.Game.Heartbeat);
    local PlayersHandler = require(ReplicatedStorage.Systems.Player.Game.PlayersHandler);
    local TweenInfo_new_ret = TweenInfo.new(0.25);
    local _ = ReplicatedStorage.Assets.Sounds.SFX.Menu;
    local u1 = {
        CurrentIndx = 1,
        CurrentHumanoid = nil,
        Spectating = false,
        Connections = {
            HealthConnection = nil,
            DeathConnection = nil
        }
    };

    local function changeProp(p2: userdata, p3: any, p4: any) -- Line: 41
        if p2[p3] ~= p4 then
            p2[p3] = p4;
        end;
    end;

    function u1.Toggle(p5, p6) -- Line: 47
        -- upvalues: SidebarHandler (copy), Heartbeat (copy), u1 (copy), RunService (copy), Sounds (copy), PlayersHandler (copy)
        workspace:FindFirstChild("Ragdolls");
        local LocalPlayer = game.Players.LocalPlayer;
        local Character = LocalPlayer.Character;

        if Character then
            Character = Character:FindFirstChild("Humanoid");
        end;

        local _ = SidebarHandler.Sidebar.Buttons.Spectate;

        if not Character then
            return;
        end;

        if LocalPlayer.Character.Parent ~= workspace.Players.Spectating then
            p6 = false;
        end;

        if p6 then
            Heartbeat:EnableHearbeat();
        else
            Heartbeat:DisableHeartbeat();

            for i, v in u1.Connections do
                pcall(function() -- Line: 65
                    -- upvalues: v (copy), RunService (ref), i (copy)
                    v:Disconnect();

                    if RunService:IsStudio() then
                        warn((`[{script:GetFullName()}]: Removed event: {i} from Spectating.`));
                    end;
                end);
                u1.Connections[i] = nil;
            end;
        end;

        if p6 then
            local Map = workspace.Map.Ingame:FindFirstChild("Map");
            local v7;

            if Map then
                v7 = Map:FindFirstChild("Config");
            else
                v7 = Map;
            end;

            if v7 then
                v7 = require(v7);
            end;

            if v7 and (v7.Config and v7.Config.Ambience) then
                local v8 = v7.Config.AmbienceProperties or {};

                if not v8.Priority then
                    v8.Priority = 0.5;
                end;

                local Ambience = v7.Config.Ambience;
                local v9 = Map:GetAttribute("MapName") or "";

                if typeof(Ambience) == "table" and Ambience[v9] then
                    Ambience = Ambience[v9];
                end;

                v8.Name = "SpectatingMapAmbience";
                Sounds:PlayTheme(Ambience, v8);
            end;
        else
            Sounds:StopTheme("SpectatingMapAmbience");
        end;

        u1.UI.Visible = p6;
        workspace.CurrentCamera.CameraSubject = Character;
        local Spectate = SidebarHandler.SidebarButtons.Spectate;

        if Spectate then
            Spectate:SetAppearanceState(p6);
        end;

        u1.Spectating = p6;

        if not p6 then
            PlayersHandler:SetSpectating(nil);
        end;
    end;

    function u1.Start(p10) -- Line: 117
        -- upvalues: RunService (copy), u1 (copy), Network (copy), PlayersHandler (copy), Heartbeat (copy), Device (copy), DataHandler (copy), Sounds (copy), TweenService (copy), TweenInfo_new_ret (copy), UserInputService (copy), SidebarHandler (copy)
        if RunService:IsClient() then
            local LocalPlayer = game.Players.LocalPlayer;
            u1.UI = script.Spectate:Clone();
            u1.UI.Visible = false;
            u1.UI.Parent = LocalPlayer.PlayerGui:WaitForChild("MainUI");

            local function fuckOff() -- Line: 126
                -- upvalues: Network (ref)
                Network:FireServerConnection("UpdateHeartbeatAsync", "REMOTE_EVENT", 53643);
            end;

            local function playerAdded(p11: userdata) -- Line: 130
                -- upvalues: Network (ref)
                local u12 = { "Name", "DisplayName", "UserId" };
                p11.Changed:Connect(function(p13) -- Line: 133
                    -- upvalues: u12 (copy), Network (ref)
                    if table.find(u12, p13) then
                        Network:FireServerConnection("UpdateHeartbeatAsync", "REMOTE_EVENT", 53643);
                    end;
                end);
            end;

            local function adjustSpectatorIndex(p14: number) -- Line: 141
                -- upvalues: LocalPlayer (copy), u1 (ref), adjustSpectatorIndex (copy), PlayersHandler (ref), Heartbeat (ref)
                if LocalPlayer.Character.Parent ~= workspace.Players.Spectating then
                    return;
                end;

                local v15 = u1;
                v15.CurrentIndx = v15.CurrentIndx + p14;
                local u16 = {};

                local function addToSpectatorTable(p17: userdata?) -- Line: 150
                    -- upvalues: u16 (copy)
                    local Humanoid = p17:FindFirstChild("Humanoid");

                    if Humanoid and (Humanoid.Parent and Humanoid.Health > 0) then
                        table.insert(u16, p17);
                    end;
                end;

                local function updateHealth(p18: userdata?) -- Line: 157
                    -- upvalues: u1 (ref)
                    if not p18 then
                        return;
                    end;

                    local v19 = p18.Health / p18.MaxHealth;
                    u1.UI.Health.Text = `{math.round(v19 * 100)}%`;
                    u1.UI.Health.TextColor3 = Color3.fromHSV(v19 / 3, 1, 1);
                end;

                local function setHealthConnection(u20: userdata) -- Line: 165
                    -- upvalues: u1 (ref), adjustSpectatorIndex (ref)
                    pcall(function() -- Line: 167
                        -- upvalues: u1 (ref)
                        u1.Connections.HealthConnection:Disconnect();
                    end);
                    pcall(function() -- Line: 168
                        -- upvalues: u1 (ref)
                        u1.Connections.DeathConnection:Disconnect();
                    end);
                    pcall(function() -- Line: 169
                        -- upvalues: u1 (ref)
                        u1.Connections.GoneConnection:Disconnect();
                    end);
                    local _ = u20.Parent;

                    if u20.Health > 0 then
                        u1.Connections.DeathConnection = u20.Died:Once(function() -- Line: 174
                            -- upvalues: u1 (ref), u20 (copy), adjustSpectatorIndex (ref)
                            task.delay(3, function() -- Line: 175
                                -- upvalues: u1 (ref), u20 (ref), adjustSpectatorIndex (ref)
                                if u1.CurrentHumanoid == u20 and u1.UI.Visible then
                                    adjustSpectatorIndex(1);
                                end;
                            end);
                        end);
                        u1.Connections.GoneConnection = u20.AncestryChanged:Once(function(p21, p22) -- Line: 181
                            -- upvalues: adjustSpectatorIndex (ref)
                            adjustSpectatorIndex(1);
                        end);
                    end;

                    u1.Connections.HealthConnection = u20:GetPropertyChangedSignal("Health"):Connect(function() -- Line: 186
                        -- upvalues: u20 (copy), u1 (ref)
                        local v23 = u20;

                        if not v23 then
                            return;
                        end;

                        local v24 = v23.Health / v23.MaxHealth;
                        u1.UI.Health.Text = `{math.round(v24 * 100)}%`;
                        u1.UI.Health.TextColor3 = Color3.fromHSV(v24 / 3, 1, 1);
                    end);
                end;

                for _, child in pairs(workspace.Players.Killers:GetChildren()) do
                    local Humanoid = child:FindFirstChild("Humanoid");

                    if Humanoid and (Humanoid.Parent and Humanoid.Health > 0) then
                        table.insert(u16, child);
                    end;
                end;

                for _, child in pairs(workspace.Players.Survivors:GetChildren()) do
                    local Humanoid = child:FindFirstChild("Humanoid");

                    if Humanoid and (Humanoid.Parent and Humanoid.Health > 0) then
                        table.insert(u16, child);
                    end;
                end;

                local v25 = u16[u1.CurrentIndx % #u16 + 1];
                local v26;

                if v25 then
                    v26 = v25:FindFirstChild("Humanoid");
                else
                    v26 = v25;
                end;

                if v26 then
                    u1.CurrentHumanoid = v26;

                    if u1.Spectating then
                        PlayersHandler:SetSpectating(game.Players:GetPlayerFromCharacter(v25));
                    end;

                    if v26:IsDescendantOf(workspace.Players.Survivors) == true then
                        Heartbeat:SetSubject(v26.Parent);
                    end;

                    local v27 = v25:GetAttribute("Username") or v25.Name;
                    local v28 = v25:GetAttribute("ActorDisplayName") or v25.Name;
                    local Attribute = v25:GetAttribute("SkinNameDisplay");
                    local v29 = `{v28} {(Attribute == nil or Attribute == "") and "" or (`({Attribute})` or "")}`;
                    u1.UI.Username.Text = v27;
                    u1.UI.ActorName.Text = v29;

                    if u1.UI.Visible then
                        workspace.CurrentCamera.CameraSubject = v26;
                    end;

                    if v26 then
                        local v30 = v26.Health / v26.MaxHealth;
                        u1.UI.Health.Text = `{math.round(v30 * 100)}%`;
                        u1.UI.Health.TextColor3 = Color3.fromHSV(v30 / 3, 1, 1);
                    end;

                    setHealthConnection(v26);
                end;
            end;

            local PlayerDevice = Device:GetPlayerDevice();
            local u31 = {};
            local u32 = DataHandler:ReadPath("Settings/Keybinds");

            local function __checkBind(p33: userdata) -- Line: 259
                -- upvalues: u31 (copy), PlayerDevice (ref)
                local v34 = u31[p33.Name];

                if v34 then
                    v34.Visible = false;
                    u31[p33.Name] = nil;
                end;

                local v35 = p33:FindFirstChild((`{PlayerDevice}Keybind`));

                if v35 then
                    u31[p33.Name] = v35;
                    v35.Visible = true;
                end;
            end;

            local function getSpectateDirection(p36: string) -- Line: 243
                -- upvalues: u32 (copy)
                local v37 = {};
                local v38 = {};

                for _, v in ipairs({ "SpectateNext", "SpectateNextConsole" }) do
                    local v39 = u32:FindFirstChild(v);

                    if v39 then
                        v37[tostring(v39.Value)] = true;
                    end;
                end;

                for _, v in ipairs({ "SpectatePrevious", "SpectatePreviousConsole" }) do
                    local v40 = u32:FindFirstChild(v);

                    if v40 then
                        v38[tostring(v40.Value)] = true;
                    end;
                end;

                if v37[p36] then
                    return 1;
                end;

                if v38[p36] then
                    return -1;
                end;
            end;

            for i, v in { u1.UI.Next, u1.UI.Back } do
                local v41 = u31[v.Name];

                if v41 then
                    v41.Visible = false;
                    u31[v.Name] = nil;
                end;

                local v42 = v:FindFirstChild((`{PlayerDevice}Keybind`));

                if v42 then
                    u31[v.Name] = v42;
                    v42.Visible = true;
                end;

                Device.Changed:Connect(function(p43: string) -- Line: 275
                    -- upvalues: PlayerDevice (ref), v (copy), u31 (copy)
                    PlayerDevice = p43;
                    local v44 = v;
                    local v45 = u31[v44.Name];

                    if v45 then
                        v45.Visible = false;
                        u31[v44.Name] = nil;
                    end;

                    local v46 = v44:FindFirstChild((`{PlayerDevice}Keybind`));

                    if v46 then
                        u31[v44.Name] = v46;
                        v46.Visible = true;
                    end;
                end);
                v.MouseButton1Click:Connect(function() -- Line: 280
                    -- upvalues: Sounds (ref), adjustSpectatorIndex (copy), i (copy)
                    Sounds:Play("rbxassetid://112519459573278");
                    adjustSpectatorIndex(i == 1 and 1 or -1);
                end);
                v.MouseEnter:Connect(function() -- Line: 285
                    -- upvalues: Sounds (ref), TweenService (ref), v (copy), TweenInfo_new_ret (ref)
                    Sounds:Play("tick");
                    TweenService:Create(v, TweenInfo_new_ret, {
                        Size = UDim2.fromScale(0.25, 1.05)
                    }):Play();
                end);
                v.MouseLeave:Connect(function() -- Line: 290
                    -- upvalues: Sounds (ref), TweenService (ref), v (copy), TweenInfo_new_ret (ref)
                    Sounds:Play("tick");
                    TweenService:Create(v, TweenInfo_new_ret, {
                        Size = UDim2.fromScale(0.2, 1)
                    }):Play();
                end);
            end;

            UserInputService.InputBegan:Connect(function(p47: userdata, p48: boolean) -- Line: 296
                -- upvalues: u1 (ref), getSpectateDirection (copy), Sounds (ref), adjustSpectatorIndex (copy)
                if p48 then
                    return;
                end;

                if not u1.Spectating then
                    return;
                end;

                local v49 = getSpectateDirection(p47.KeyCode.Name);

                if v49 then
                    Sounds:Play("rbxassetid://112519459573278");
                    adjustSpectatorIndex(v49);
                end;
            end);
            SidebarHandler.Sidebar.Buttons.Spectate.Button.MouseButton1Click:Connect(function() -- Line: 317
                -- upvalues: SidebarHandler (ref), Sounds (ref), u1 (ref), adjustSpectatorIndex (copy)
                if SidebarHandler.MenusHidden then
                    return;
                end;

                Sounds:Play("select");
                u1:Toggle(not u1.Spectating);

                if not u1.Spectating == false then
                    adjustSpectatorIndex(0);
                end;
            end);
            u1.UI.Username.Changed:Connect(function(p50) -- Line: 330
                -- upvalues: u1 (ref), Network (ref)
                if p50 ~= "Text" then
                    return;
                end;

                local Text = u1.UI.Username.Text;
                local v51 = u1.CurrentHumanoid and u1.CurrentHumanoid.Parent;
                local v52;

                if v51 then
                    v52 = v51:GetAttribute("Username");
                else
                    v52 = v51;
                end;

                local v53;

                if v51 then
                    v53 = game.Players:GetPlayerFromCharacter(v51);
                else
                    v53 = v51;
                end;

                if not v51 then
                    return;
                end;

                if v53 and v52 then
                    if v52 ~= Text then
                        Network:FireServerConnection("UpdateHeartbeatAsync", "REMOTE_EVENT", 53643);
                    end;
                elseif v53 and not v52 then
                    Network:FireServerConnection("UpdateHeartbeatAsync", "REMOTE_EVENT", 53643);
                end;
            end);
            game.Players.PlayerAdded:Connect(playerAdded);
        end;
    end;
    print('starting spectate module')
    u1:Start()
end

return SidebarHandler
