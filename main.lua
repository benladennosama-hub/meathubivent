local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- КОНФИГУРАЦИЯ КЛЮЧА
local CorrectKey = "meatt2026bySko1zk1"

local AuthWindow = Fluent:CreateWindow({
    Title = "🔑 MEAT HUB AUTH",
    SubTitle = "Verification Required",
    TabWidth = 160,
    Size = UDim2.fromOffset(400, 280),
    Theme = "Darker"
})

local AuthTab = AuthWindow:AddTab({ Title = "Key", Icon = "lock" })

AuthTab:AddInput("KeyInput", {
    Title = "Enter Access Key",
    Default = "",
    Placeholder = "Paste key here...",
    Callback = function(Value)
        if Value == CorrectKey then
            Fluent:Notify({Title = "Success", Content = "Key Accepted! Loading...", Duration = 3})
            AuthWindow:Destroy()
            LoadMeatHub() -- Запуск основного хаба
        else
            Fluent:Notify({Title = "Error", Content = "Invalid Key!", Duration = 2})
        end
    end
})

-- ОСНОВНАЯ ФУНКЦИЯ
function LoadMeatHub()
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
    local SpeedLoop = nil -- Для цикла скорости

    local Plr = game.Players.LocalPlayer
    local VU = game:GetService("VirtualUser")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")

    -- СИСТЕМА СОХРАНЕНИЯ КАСТОМНЫХ ТП
    local TPFileName = "MeatHub_SavedTPs.json"
    local CustomTPs = {}

    if isfile and isfile(TPFileName) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(TPFileName)) end)
        if success and type(data) == "table" then CustomTPs = data end
    end

    local function SaveTPsToFile()
        if writefile then writefile(TPFileName, HttpService:JSONEncode(CustomTPs)) end
    end

    -- ФУНКЦИЯ БЕЗОПАСНОГО ТП
    local function SafeTeleport(targetCFrame, offsetCFrame)
        if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = Plr.Character.HumanoidRootPart
            local finalCFrame = offsetCFrame and (targetCFrame * offsetCFrame) or targetCFrame
            hrp.CFrame = finalCFrame + Vector3.new(0, 2, 0)
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
    end

    -- ANTI-VOID
    task.spawn(function()
        while task.wait(2) do
            if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") and Plr.Character.HumanoidRootPart.Position.Y < -50 then
                if getgenv().Depo then
                    SafeTeleport(getgenv().Depo, CFrame.new(0, 0, -35))
                    Fluent:Notify({Title = "Anti-Void", Content = "Выпал! ТП на точку сдачи", Duration = 2})
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
                    SafeTeleport(getgenv().Depo, CFrame.new(0, 0, -35))
                    task.wait(2.5)
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

    Tabs.Main:AddSlider("Delay", { Title = "Collect Speed", Default = 0.5, Min = 0.1, Max = 2, Rounding = 1, Callback = function(v) getgenv().Speed = v end })

    -- [ WORLD SECTION ]
    Tabs.World:AddSection("Default Navigation")
    Tabs.World:AddButton({ Title = "TP to Lake (Forward Method)", Callback = function() if getgenv().Depo then SafeTeleport(getgenv().Depo, CFrame.new(0, 0, -35)) end end })
    Tabs.World:AddButton({ Title = "TP to Town (Gifts)", Callback = function() game:GetService("ReplicatedStorage").API:FindFirstChild("LocationAPI/SetLocation"):FireServer("Gifts", "MainMap") end })

    Tabs.World:AddSection("Custom Teleports")
    local function GetTPNames()
        local list = {}
        for name, _ in pairs(CustomTPs) do table.insert(list, name) end
        if #list == 0 then table.insert(list, "No Saves Yet") end
        return list
    end

    local TPDropdown = Tabs.World:AddDropdown("SavedTPs", {
        Title = "Your Saved Locations",
        Values = GetTPNames(),
        Multi = false,
        Default = GetTPNames()[1]
    })

    Tabs.World:AddButton({
        Title = "⚡ Teleport to Selected",
        Callback = function()
            local selected = TPDropdown.Value
            if CustomTPs[selected] then
                local pos = CustomTPs[selected]
                SafeTeleport(CFrame.new(pos.X, pos.Y, pos.Z))
            end
        end
    })

    local newTpName = ""
    Tabs.World:AddInput("NewTPName", { Title = "Name for New TP", Default = "", Callback = function(Value) newTpName = Value end })

    Tabs.World:AddButton({
        Title = "💾 Save Current Position",
        Callback = function()
            if newTpName == "" then return end
            if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
                local pos = Plr.Character.HumanoidRootPart.Position
                CustomTPs[newTpName] = {X = pos.X, Y = pos.Y, Z = pos.Z}
                SaveTPsToFile()
                TPDropdown:SetValues(GetTPNames())
                Fluent:Notify({Title = "Saved", Content = "Location saved!", Duration = 2})
            end
        end
    })

    -- [ PLAYER SECTION - ОБНОВЛЕННЫЙ С ЦИКЛОМ ]
    Tabs.Player:AddSection("Movement")
    Tabs.Player:AddSlider("WS", {
        Title = "WalkSpeed",
        Description = "Зацикленная скорость (Loop)",
        Default = 16,
        Min = 16,
        Max = 300,
        Rounding = 0,
        Callback = function(v)
            if SpeedLoop then SpeedLoop:Disconnect() SpeedLoop = nil end
            if v > 16 then
                SpeedLoop = RunService.Heartbeat:Connect(function()
                    if Plr.Character and Plr.Character:FindFirstChild("Humanoid") then
                        Plr.Character.Humanoid.WalkSpeed = v
                    end
                end)
            else
                if Plr.Character and Plr.Character:FindFirstChild("Humanoid") then
                    Plr.Character.Humanoid.WalkSpeed = 16
                end
            end
        end
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

    Tabs.Player:AddSlider("FlySpeed", { Title = "Fly Speed", Default = 50, Min = 10, Max = 300, Rounding = 0, Callback = function(v) flySpeed = v end })

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
end
