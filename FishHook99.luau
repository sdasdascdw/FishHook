--======================================================================================
-- FILE: Linoria_Premium_Survival_Suite.lua
-- CONFIGURATION & INITIALIZATION
--======================================================================================

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- Window Layout Config
local Window = Library:CreateWindow({
    Title = '99 Nights In The Forest Script | Made by Tg9ze',
    Center = true,
    AutoShow = true
})

-- UI Tabs
local Tabs = {
    Main = Window:AddTab('Main'),
    Character = Window:AddTab('Character'),
    World = Window:AddTab('World'),
    Settings = Window:AddTab('Settings')
}

-- UI Layout Groupboxes
local LightingBox = Tabs.World:AddRightGroupbox('Lighting')
local MainBox = Tabs.Main:AddLeftGroupbox('Campfire')
local FarmBox = Tabs.Main:AddRightGroupbox('Auto Farm Operations')
local CharBox = Tabs.Character:AddLeftGroupbox('Character Mods')
local MiscBox = Tabs.Character:AddRightGroupbox('Misc')
local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu')

--======================================================================================
-- GLOBAL RUNTIME STATES & CONFIGURATIONS
--======================================================================================
local WalkSpeedEnabled = false
local JumpPowerEnabled = false
local WalkSpeedValue = 16
local JumpPowerValue = 50
local InfiniteJumpConnection
local AnimConnection
local CollisionConnection

local AutoBunnyEnabled = false
local AutoTreeEnabled = false
local AutoBringItems = false

local SelectedBringItems = {} -- Stores selections from the Dropdown

-- Backup original global game conditions
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

--======================================================================================
-- CORE DATA HELPER FUNCTIONS
--======================================================================================
local function getChar()
    local char = LocalPlayer.Character
    if not char then return end
    return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
end

-- Radar Search: Closest Living Bunny
local function getClosestBunny()
    local char, _, hrp = getChar()
    if not hrp then return nil end

    local closestBunny = nil
    local shortestDistance = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Bunny" then
            local bunnyHum = obj:FindFirstChildOfClass("Humanoid")
            local bunnyPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("PrimaryPart") or obj:FindFirstChildOfClass("BasePart")
            
            if bunnyPart and (not bunnyHum or bunnyHum.Health > 0) then
                local distance = (hrp.Position - bunnyPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestBunny = obj
                end
            end
        end
    end
    return closestBunny
end

-- Radar Search: Closest Valid Small Tree
local function getClosestTree()
    local char, _, hrp = getChar()
    if not hrp then return nil end

    local closestTree = nil
    local shortestDistance = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Small Tree" then
            local treePart = obj:FindFirstChild("PrimaryPart") or obj:FindFirstChild("Trunk") or obj:FindFirstChildOfClass("BasePart")
            
            if treePart and treePart.Transparency < 1 and obj.Parent then
                local distance = (hrp.Position - treePart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestTree = obj
                end
            end
        end
    end
    return closestTree
end

--======================================================================================
-- WORLD & LIGHTING SUITE (WORLD TAB)
--======================================================================================
LightingBox:AddToggle("FullbrightToggle", {
    Text = "Fullbright",
    Default = false,

    Callback = function(Value)
        if Value then
            Lighting.Brightness = 10
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        else
            Lighting.Brightness = OriginalLighting.Brightness
            Lighting.ClockTime = OriginalLighting.ClockTime
            Lighting.FogEnd = OriginalLighting.FogEnd
            Lighting.GlobalShadows = OriginalLighting.GlobalShadows
            Lighting.Ambient = OriginalLighting.Ambient
            Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        end
    end
})

--======================================================================================
-- CAMPFIRE MANAGEMENT (MAIN TAB)
--======================================================================================
MainBox:AddToggle('AutoCampfireToggle', {
    Text = 'Auto Teleport To Campfire when night',
    Default = false,

    Callback = function(Value)
        getgenv().AutoCampfire = Value
        getgenv().HasTeleportedTonight = false

        if Value then
            task.spawn(function()
                while getgenv().AutoCampfire do
                    task.wait(1)

                    local LightingService = game:GetService("Lighting")
                    local isNight = (LightingService.ClockTime >= 18 or LightingService.ClockTime <= 6)

                    if isNight and not getgenv().HasTeleportedTonight then
                        local char, _, hrp = getChar()

                        if hrp then
                            hrp.CFrame = CFrame.new(0, 6, 0)
                            getgenv().HasTeleportedTonight = true

                            pcall(function()
                                game:GetService("StarterGui"):SetCore("SendNotification", {
                                    Title = "Auto Campfire",
                                    Text = "Teleported to the campfire!",
                                    Duration = 5
                                })
                            end)
                        end
                    end

                    if not isNight then
                        getgenv().HasTeleportedTonight = false
                    end
                end
            end)
        end
    end
})

MainBox:AddButton({
    Text = 'Teleport To Campfire',
    Func = function()
        local _, _, hrp = getChar()
        if hrp then
            hrp.CFrame = CFrame.new(0, 6, 0)
        end
    end
})

--======================================================================================
-- AUTO FARM ENGINES & DROP UTILITIES (MAIN TAB)
--======================================================================================

-- Engine A: Anti-Shake Small Tree Farm Loop
FarmBox:AddToggle('AutoTreeToggle', {
    Text = 'Auto Farm Small Tree',
    Default = false,
    Callback = function(Value)
        AutoTreeEnabled = Value

        if CollisionConnection then 
            CollisionConnection:Disconnect() 
            CollisionConnection = nil 
        end

        if Value then
            CollisionConnection = RunService.Stepped:Connect(function()
                if AutoTreeEnabled or AutoBunnyEnabled then
                    local char = LocalPlayer.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)

            task.spawn(function()
                while AutoTreeEnabled do
                    task.wait(0.05)
                    
                    local char, hum, hrp = getChar()
                    if char and hum and hum.Health > 0 and hrp then
                        local targetTree = getClosestTree()

                        if targetTree then
                            local treePart = targetTree:FindFirstChild("PrimaryPart") or targetTree:FindFirstChild("Trunk") or targetTree:FindFirstChildOfClass("BasePart")

                            while AutoTreeEnabled and targetTree and targetTree.Parent and treePart and treePart.Transparency < 1 and hum.Health > 0 do
                                task.wait(0.04)
                                
                                char, hum, hrp = getChar()
                                if not hrp or hum.Health <= 0 then break end

                                local weapon = char:FindFirstChild("Axe") or LocalPlayer.Backpack:FindFirstChild("Axe")
                                if weapon and weapon.Parent ~= char then
                                    weapon.Parent = char
                                    task.wait(0.05)
                                end

                                hrp.CFrame = treePart.CFrame * CFrame.new(0, 0, 2.6)
                                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                                if weapon and weapon.Parent == char then
                                    weapon:Activate()
                                    
                                    pcall(function()
                                        if treePart.Anchored then treePart.Anchored = false end
                                    end)

                                    local viewport = workspace.CurrentCamera.ViewportSize
                                    VirtualInputManager:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, true, game, 0)
                                    task.wait(0.02)
                                    VirtualInputManager:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, false, game, 0)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})

-- Engine B: Bunny Combat Farm Loop
FarmBox:AddToggle('AutoBunnyToggle', {
    Text = 'Auto Farm Bunny',
    Default = false,
    Callback = function(Value)
        AutoBunnyEnabled = Value

        if Value and not CollisionConnection then
            CollisionConnection = RunService.Stepped:Connect(function()
                if AutoTreeEnabled or AutoBunnyEnabled then
                    local char = LocalPlayer.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end

        if Value then
            task.spawn(function()
                while AutoBunnyEnabled do
                    task.wait(0.05)
                    
                    local char, hum, hrp = getChar()
                    if char and hum and hum.Health > 0 and hrp then
                        local targetBunny = getClosestBunny()

                        if targetBunny then
                            local bunnyPart = targetBunny:FindFirstChild("HumanoidRootPart") or targetBunny:FindFirstChild("PrimaryPart") or targetBunny:FindFirstChildOfClass("BasePart")
                            local bunnyHum = targetBunny:FindFirstChildOfClass("Humanoid")

                            while AutoBunnyEnabled and targetBunny and targetBunny.Parent and bunnyPart and (not bunnyHum or bunnyHum.Health > 0) and hum.Health > 0 do
                                task.wait(0.1)
                                
                                char, hum, hrp = getChar()
                                if not hrp or hum.Health <= 0 then break end

                                local weapon = char:FindFirstChild("Axe") or LocalPlayer.Backpack:FindFirstChild("Axe")
                                if weapon and weapon.Parent ~= char then
                                    weapon.Parent = char
                                    task.wait(0.05)
                                end

                                hrp.CFrame = bunnyPart.CFrame * CFrame.new(0, 0, 2)

                                if weapon and weapon.Parent == char then
                                    weapon:Activate()
                                    local viewport = workspace.CurrentCamera.ViewportSize
                                    VirtualInputManager:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, true, game, 0)
                                    task.wait(0.03)
                                    VirtualInputManager:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, false, game, 0)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})

-- Engine C: Fixed Item Bring System (Exact Word Match Filter)
local function bringSelectedItemsToCoordinates()
    local dropTarget = Vector3.new(0, 27, 1)
    local activeTargets = {}
    
    for item, enabled in pairs(SelectedBringItems) do
        if enabled then activeTargets[item:lower()] = true end
    end

    local hasSelection = false
    for _ in pairs(activeTargets) do hasSelection = true break end
    if not hasSelection then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        local nameLower = obj.Name:lower()
        local parentNameLower = (obj.Parent and obj.Parent.Name:lower()) or ""
        
        -- Exact target validation protects single item selections from cross-triggering
        local isTargetItem = activeTargets[nameLower] or activeTargets[parentNameLower]

        if isTargetItem then
            local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            
            if targetPart then
                local distanceToDropZone = (targetPart.Position - dropTarget).Magnitude
                
                if distanceToDropZone < 6 and targetPart.Position.Y > 22 then
                    targetPart.Anchored = false
                    pcall(function()
                        targetPart.AssemblyLinearVelocity = Vector3.new(0, -35, 0)
                        if targetPart:CanDeclareNetworkOwnership() then
                            targetPart:SetNetworkOwner(LocalPlayer)
                        end
                    end)
                
                elseif distanceToDropZone > 10 then
                    targetPart.Anchored = false
                    targetPart.CFrame = CFrame.new(dropTarget)
                    
                    pcall(function()
                        targetPart.AssemblyLinearVelocity = Vector3.new(0, -35, 0)
                        if targetPart:CanDeclareNetworkOwnership() then
                            targetPart:SetNetworkOwner(LocalPlayer)
                        end
                    end)
                end
            end
        end
    end
end

FarmBox:AddDropdown('ItemBringSelect', {
    Values = { 'Morsel', 'Cooked Morsel', 'Steak', 'Cooked Steak', 'Coal', 'Log' },
    Multi = true,
    Default = {},
    Text = 'Select Items to Bring',
    Callback = function(Value)
        SelectedBringItems = Value
    end
})

FarmBox:AddToggle('AutoBringItemsToggle', {
    Text = 'Auto Bring Items (1s Loop)',
    Default = false,
    Callback = function(Value)
        AutoBringItems = Value

        if Value then
            task.spawn(function()
                while AutoBringItems do
                    bringSelectedItemsToCoordinates()
                    task.wait(1.0)
                end
            end)
        end
    end
})

--======================================================================================
-- CHARACTER MODIFICATIONS SUITE (CHARACTER TAB)
--======================================================================================
CharBox:AddToggle('InfiniteJump', {
    Text = 'Infinite Jump',
    Default = false,
    Callback = function(v)
        if v then
            InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                local _, hum = getChar()
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if InfiniteJumpConnection then
                InfiniteJumpConnection:Disconnect()
                InfiniteJumpConnection = nil
            end
        end
    end
})

local originalWalkSpeed = 16
local originalJumpPower = 50

CharBox:AddToggle('WalkSpeedToggle', {
    Text = 'WalkSpeed',
    Default = false,
    Callback = function(v)
        local _, hum = getChar()
        if not hum then return end

        if v then
            originalWalkSpeed = hum.WalkSpeed
        else
            hum.WalkSpeed = originalWalkSpeed
        end

        WalkSpeedEnabled = v
    end
})

CharBox:AddSlider('WalkSpeedSlider', {
    Text = 'Speed',
    Default = 16,
    Min = 16,
    Max = 500,
    Rounding = 0,
    Callback = function(v)
        WalkSpeedValue = v
    end
})

CharBox:AddToggle('JumpPowerToggle', {
    Text = 'Jump Power',
    Default = false,
    Callback = function(v)
        local _, hum = getChar()
        if not hum then return end

        if v then
            originalJumpPower = hum.JumpPower
        else
            hum.UseJumpPower = true
            hum.JumpPower = originalJumpPower
        end

        JumpPowerEnabled = v
    end
})

CharBox:AddSlider('JumpPowerSlider', {
    Text = 'Jump',
    Default = 50,
    Min = 50,
    Max = 350,
    Rounding = 0,
    Callback = function(v)
        JumpPowerValue = v
    end
})

local animOptions = {}

CharBox:AddToggle('NoAnim', {
    Text = 'Disable Animations',
    Default = false,
    Callback = function(v)
        if AnimConnection then
            AnimConnection:Disconnect()
            AnimConnection = nil
        end

        if v then
            AnimConnection = RunService.Heartbeat:Connect(function()
                local _, hum = getChar()
                if not hum then return end

                local animator = hum:FindFirstChildOfClass("Animator")
                if not animator then return end

                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local name = track.Name:lower()
                    for anim, enabled in pairs(animOptions) do
                        if enabled and name:find(anim) then
                            track:Stop(0)
                        end
                    end
                end
            end)
        end
    end
})

CharBox:AddDropdown('AnimSelect', {
    Values = { 'idle', 'walk', 'run', 'jump', 'fall', 'climb', 'swim', 'sit' },
    Multi = true,
    Default = {},
    Text = 'Block Animations',
    Callback = function(v)
        animOptions = v
    end
})

MiscBox:AddButton({
    Text = 'Reset Character',
    Func = function()
        local _, hum = getChar()
        if hum then hum.Health = 0 end
    end
})

-- Heartbeat Enforcement: Overrides anti-cheats resetting walkspeed/jump properties
task.spawn(function()
    while task.wait() do
        local _, hum = getChar()

        if hum then
            if WalkSpeedEnabled then
                hum.WalkSpeed = WalkSpeedValue
            end

            if JumpPowerEnabled then
                hum.UseJumpPower = true
                hum.JumpPower = JumpPowerValue
            end
        end
    end
end)

--======================================================================================
-- SYSTEM MENU & SAVE SETTINGS PANEL (SETTINGS TAB)
--======================================================================================
MenuGroup:AddButton('Unload', function()
    Library:Unload()
end)

MenuGroup:AddLabel('Menu Keybind'):AddKeyPicker('MenuKey', {
    Default = 'RightShift',
    NoUI = true,
    Text = 'Toggle Menu'
})

Library.ToggleKeybind = Options.MenuKey

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

ThemeManager:SetFolder('FishHook')
SaveManager:SetFolder('FishHook/99NightsConfigs')

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKey' })

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

SaveManager:LoadAutoloadConfig()

-- De-initialization Garbage Collection
Library:OnUnload(function()
    if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
    if AnimConnection then AnimConnection:Disconnect() end
    if CollisionConnection then CollisionConnection:Disconnect() end
    AutoBunnyEnabled = false
    AutoTreeEnabled = false
    AutoBringItems = false
end)
