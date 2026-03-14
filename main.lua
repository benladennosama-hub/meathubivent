local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "🥩 MEAT HUB",
    SubTitle = "Sugarfest 2026 | Forward Elite",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Darker" 
})

-- GLOBALS
getgenv().AutoFarm = false
getgenv().Speed = 0.5
getgenv().Depo = nil
getgenv().AntiAFK = true
local flySpeed = 50

local Plr = game.Players.LocalPlayer
local VU = game:GetService("VirtualUser")

-- ФУНКЦИЯ БЕЗОПАСНОГО ТП (С поддержкой CFrame смещения)
local function SafeTeleport(targetCFrame, offsetCFrame)
    if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = Plr.Character.HumanoidRootPart
        -- Если передан CFrame офсет (например вперед), умножаем. Если нет — просто ТП.
        local finalCFrame = offsetCFrame and (targetCFrame * offsetCFrame) or targetCFrame
        
        -- Добавляем +2 вверх для подстраховки от застревания в полу
        hrp.CFrame = finalCFrame + Vector3.new(0, 2, 0)
        hrp.Velocity = Vector3.new(0, 0, 0)
    end
end

-- ANTI-VOID (Если всё же упал)
task.spawn(function()
    while task.wait(2) do
        if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") and Plr.Character.HumanoidRootPart.Position.Y < -50 then
            if getgenv().Depo then
                SafeTeleport(getgenv().Depo, CFrame.new(0, 0, -35)) -- Спасаем в точку сдачи вперед
                Fluent:Notify({Title = "Anti-Void", Content = "Выпал! ТП на точку сдачи (вперед)", Duration = 2})
            end
        end
    end
end)

-- ANTI-AFK
task.spawn(function()
    while task.wait(5) do
        if getgenv().AntiAFK then
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end
    end
end)

local Tabs = {
    Main = Window:AddTab({ Title = "Farm", Icon = "egg" }),
    World = Window:AddTab({ Title = "World", Icon = "map" }),
    Player = Window:AddTab({ Title = "Movement", Icon = "user" })
}

-- [ FARM SECTION ]
Tabs.Main:AddToggle("FarmToggle", {Title = "Auto Collect", Default = false}):OnChanged(function(v)
    getgenv().AutoFarm = v
    task.spawn(function()
        while getgenv().AutoFarm do
            local eggs = {}
            local folder = workspace:FindFirstChild("Interiors") and workspace.Interiors:FindFirstChild("MainMap!Sugarfest2026")
            
            if folder then
                for _, v in pairs(folder:GetDescendants()) do
                    if v.Name == "Collider" and v.Parent and v.Parent.Name:find("CandyEgg") then
                        table.insert(eggs, v)
                    end
                end
            end

            if #eggs > 0 then
                for _, egg in ipairs(eggs) do
                    if not getgenv().AutoFarm then break end
                    SafeTeleport(egg.CFrame)
                    task.wait(getgenv().Speed)
                end
            elseif getgenv().Depo then
                -- ТЕЛЕПОРТ В ОЗЕРО НА 35 БЛОКОВ ВПЕРЕД
                SafeTeleport(getgenv().Depo, CFrame.new(0, 0, -35))
                task.wait(2.5) -- Ожидание сдачи
            end
            task.wait(0.5)
        end
    end)
end)

Tabs.Main:AddButton({
    Title = "Set Deposit Point",
    Description = "Смотри в сторону реки и нажми это",
    Callback = function()
        if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
            getgenv().Depo = Plr.Character.HumanoidRootPart.CFrame
            Fluent:Notify({Title = "Meat Hub", Content = "Точка сохранена! ТП будет на 35м вперед.", Duration = 3})
        end
    end
})

Tabs.Main:AddSlider("Delay", {
    Title = "Collect Speed (Delay)",
    Default = 0.5, Min = 0.1, Max = 2, Rounding = 1,
    Callback = function(v) getgenv().Speed = v end
})

-- [ WORLD SECTION ]
Tabs.World:AddSection("Navigation")

Tabs.World:AddButton({
    Title = "TP to Lake (Forward Method)",
    Callback = function()
        if getgenv().Depo then
            SafeTeleport(getgenv().Depo, CFrame.new(0, 0, -35))
        end
    end
})

Tabs.World:AddButton({
    Title = "TP to Town (Gifts)",
    Callback = function()
        game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("Gifts", "MainMap")
    end
})

-- [ PLAYER SECTION ]
Tabs.Player:AddSection("Movement")

Tabs.Player:AddSlider("WS", {
    Title = "WalkSpeed",
    Default = 16, Min = 16, Max = 300, Rounding = 0,
    Callback = function(v) if Plr.Character then Plr.Character.Humanoid.WalkSpeed = v end end
})

local flying = false
Tabs.Player:AddToggle("FlyToggle", {Title = "Enable Fly", Default = false}):OnChanged(function(v)
    flying = v
    local root = Plr.Character:FindFirstChild("HumanoidRootPart")
    if v and root then
        local bg = Instance.new("BodyGyro", root)
        local bv = Instance.new("BodyVelocity", root)
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        task.spawn(function()
            while flying do
                bv.velocity = (Plr.Character.Humanoid.MoveDirection * flySpeed)
                bg.cframe = workspace.CurrentCamera.CFrame
                task.wait()
            end
            bg:Destroy() bv:Destroy()
        end)
    end
end)

Tabs.Player:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Default = 50, Min = 10, Max = 300, Rounding = 0,
    Callback = function(v) flySpeed = v end
})

Tabs.Player:AddButton({
    Title = "💀 FALL RESET",
    Callback = function()
        local hrp = Plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            getgenv().AutoFarm = false
            hrp.CFrame = CFrame.new(hrp.Position.X, -150, hrp.Position.Z)
            hrp.Velocity = Vector3.new(0, -1000, 0)
        end
    end
})

Tabs.Player:AddToggle("AFK", {Title = "Anti-AFK", Default = true}):OnChanged(function(v) getgenv().AntiAFK = v end)

Window:SelectTab(1)
