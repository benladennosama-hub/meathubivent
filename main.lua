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
            
            -- ЗАПУСК ОСНОВНОГО ХАБА
            local MainHubWindow = Fluent:CreateWindow({
                Title = "🥩 MEAT HUB",
                SubTitle = "Sugarfest 2026 | Forward Elite",
                TabWidth = 160,
                Size = UDim2.fromOffset(580, 460),
                Theme = "Darker" 
            })
            LoadMeatHubLogic(MainHubWindow) 
        else
            Fluent:Notify({Title = "Error", Content = "Invalid Key!", Duration = 2})
        end
    end
})

-- ВСЯ ЛОГИКА ТУТ
function LoadMeatHubLogic(Window)
    -- GLOBALS
    getgenv().AutoFarm = false
    getgenv().Speed = 0.5
    getgenv().Depo = nil
    getgenv().AntiAFK = true
    local flySpeed = 50
    local SpeedLoop = nil 

    local Plr = game.Players.LocalPlayer
    local VU = game:GetService("VirtualUser")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")

    -- СИСТЕМА СОХРАНЕНИЯ ТП
    local TPFileName = "MeatHub_SavedTPs.json"
    local CustomTPs = {}

    if isfile and isfile(TPFileName) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(TPFileName)) end)
        if success and type(data) == "table" then CustomTPs = data end
    end

    local function SaveTPsToFile()
        if writefile then writefile(TPFileName, HttpService:JSONEncode(CustomTPs)) end
    end

    local function SafeTeleport(targetCFrame, offsetCFrame)
        if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = Plr.Character.HumanoidRootPart
            local finalCFrame = offsetCFrame and (targetCFrame * offsetCFrame) or targetCFrame
            hrp.CFrame = finalCFrame + Vector3.new(0, 2, 0)
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
    end

    -- ANTI-VOID & ANTI-AFK
    task.spawn(function()
        while task.wait(2) do
            if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") and Plr.Character.HumanoidRootPart.Position.Y < -50 then
                if getgenv().Depo then SafeTeleport(getgenv().Depo, CFrame.new(0, 0, -35)) end
            end
        end
    end)

    task.spawn(function()
        while task.wait(5) do
            if getgenv().AntiAFK then VU:CaptureController() VU:ClickButton2(Vector2.new()) end
        end
    end)

    -- ВКЛАДКИ
    local Tabs = {
        Main = Window:AddTab({ Title = "Farm", Icon = "egg" }),
        World = Window:AddTab({ Title = "World", Icon = "map" }),
        Player = Window:AddTab({ Title = "Movement", Icon = "user" })
    }

    -- [ FARM ]
    Tabs.Main:AddToggle("FarmToggle", {Title = "Auto Collect", Default = false}):OnChanged(function(v)
        getgenv().AutoFarm = v
        task.spawn(function()
            while getgenv().AutoFarm do
                local eggs = {}
                local folder = workspace:FindFirstChild("Interiors") and workspace.Interiors:FindFirstChild("MainMap!Sugarfest2026")
                if folder then
                    for _, egg in pairs(folder:GetDescendants()) do
                        if egg.Name == "Collider" and egg.Parent and egg.Parent.Name:find("CandyEgg") then
                            table.insert(eggs, egg)
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
        Callback = function()
            if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
                getgenv().Depo = Plr.Character.HumanoidRootPart.CFrame
