local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- [[ CONFIG & FILES ]]
local CorrectKey = "meatt2026bySko1zk1"
local ConfigFile = "MeatHub_v3_Config.json"
local TPFileName = "MeatHub_v3_TPs.json"
local Plr = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VU = game:GetService("VirtualUser")

-- [[ GLOBALS ]]
getgenv().AutoFarm = false
getgenv().Speed = 0.5
getgenv().WalkSpeedValue = 16
getgenv().DepoPos = nil 
getgenv().AntiAFK = true
local flySpeed = 50
local flying = false
local CustomTPs = {}

-- [[ LOAD CONFIG ]]
pcall(function()
    if isfile(ConfigFile) then
        local data = HttpService:JSONDecode(readfile(ConfigFile))
        if data.Depo then getgenv().DepoPos = CFrame.new(data.Depo.x, data.Depo.y, data.Depo.z) end
        getgenv().Speed = data.FarmSpeed or 0.5
        flySpeed = data.FlySpeed or 50
    end
    if isfile(TPFileName) then CustomTPs = HttpService:JSONDecode(readfile(TPFileName)) end
end)

local function SaveFullConfig()
    pcall(function()
        local data = {
            Depo = getgenv().DepoPos and {x = getgenv().DepoPos.Position.X, y = getgenv().DepoPos.Position.Y, z = getgenv().DepoPos.Position.Z},
            FarmSpeed = getgenv().Speed,
            FlySpeed = flySpeed
        }
        writefile(ConfigFile, HttpService:JSONEncode(data))
    end)
end

-- [[ UTILS ]]
local function SafeTeleport(targetCFrame)
    if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = Plr.Character.HumanoidRootPart
        hrp.CFrame = targetCFrame + Vector3.new(0, 2, 0)
        hrp.Velocity = Vector3.new(0, 0, 0)
    end
end

-- [[ UI ]]
local Window = Fluent:CreateWindow({
    Title = "🥩 MEAT HUB v3",
    SubTitle = "Sugarfest 2026 | Ultimate Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Darker"
})

local AuthTab = Window:AddTab({ Title = "🔑 Auth", Icon = "lock" })

AuthTab:AddInput("KeyInput", {
    Title = "Access Key",
    Callback = function(Value)
        if Value == CorrectKey then
            Fluent:Notify({Title = "✅ Success", Content = "Welcome, Sir!", Duration = 3})
            
            -- Удаляем элементы из AuthTab вместо самой вкладки, чтобы не было ошибок
            AuthTab:AddParagraph({Title = "Status", Content = "Logged In"})
            
            local TabFarm = Window:AddTab({ Title = "🚜 Farm", Icon = "egg" })
            local TabWorld = Window:AddTab({ Title = "🌍 World", Icon = "map" })
            local TabPlayer = Window:AddTab({ Title = "⚡ Movement", Icon = "user" })
            local TabSettings = Window:AddTab({ Title = "⚙️ Settings", Icon = "settings" })

            -- [[ FARM ]]
            TabFarm:AddSection("Auto-Collection")
            TabFarm:AddButton({
                Title = "📍 Set permanent Deposit Point",
                Callback = function()
                    getgenv().DepoPos = Plr.Character.HumanoidRootPart.CFrame
                    SaveFullConfig()
                    Fluent:Notify({Title = "Saved", Content = "Deposit point set!", Duration = 2})
                end
            })

            TabFarm:AddToggle("FarmToggle", {Title = "🚀 Start Auto-Farm", Default = false}):OnChanged(function(v)
                getgenv().AutoFarm = v
                if v then
                    if not getgenv().DepoPos then 
                        Fluent:Notify({Title = "Error", Content = "Set deposit point first!", Duration = 3}) 
                        return 
                    end
                    task.spawn(function()
                        while getgenv().AutoFarm do
                            local folder = workspace:FindFirstChild("Interiors") and workspace.Interiors:FindFirstChild("MainMap!Sugarfest2026")
                            local eggs = {}
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
                                    if egg and egg.Parent then
                                        SafeTeleport(egg.CFrame)
                                        task.wait(getgenv().Speed)
                                    end
                                end
                                if getgenv().DepoPos and getgenv().AutoFarm then
                                    SafeTeleport(getgenv().DepoPos * CFrame.new(0,0,-35))
                                    task.wait(2)
                                end
                            else
                                task.wait(1)
                            end
                            task.wait(0.1)
                        end
                    end)
                end
            end)

            TabFarm:AddSlider("Delay", { Title = "🕒 Collection Delay", Default = getgenv().Speed, Min = 0.1, Max = 2, Rounding = 1, Callback = function(v) getgenv().Speed = v end })

            -- [[ WORLD ]]
            TabWorld:AddSection("Locations")
            TabWorld:AddButton({ Title = "🏠 Go to Deposit", Callback = function() if getgenv().DepoPos then SafeTeleport(getgenv().DepoPos) end end })
            
            local function GetTPNames()
                local list = {}
                for name, _ in pairs(CustomTPs) do table.insert(list, name) end
                return #list > 0 and list or {"No Saves"}
            end

            local TPDropdown = TabWorld:AddDropdown("SavedTPs", { Title = "📍 Custom TPs", Values = GetTPNames(), Multi = false, Default = GetTPNames()[1] })

            TabWorld:AddButton({
                Title = "⚡ Teleport to Selected",
                Callback = function()
                    local sel = TPDropdown.Value
                    if CustomTPs[sel] then SafeTeleport(CFrame.new(CustomTPs[sel].X, CustomTPs[sel].Y, CustomTPs[sel].Z)) end
                end
            })

            local newTp = ""
            TabWorld:AddInput("NewTPName", { Title = "Name Spot", Callback = function(v) newTp = v end })
            TabWorld:AddButton({
                Title = "💾 Save Current Pos",
                Callback = function()
                    if newTp ~= "" and Plr.Character then
                        local p = Plr.Character.HumanoidRootPart.Position
                        CustomTPs[newTp] = {X = p.X, Y = p.Y, Z = p.Z}
                        writefile(TPFileName, HttpService:JSONEncode(CustomTPs))
                        TPDropdown:SetValues(GetTPNames())
                        Fluent:Notify({Title = "✅ Saved", Content = "Location stored!", Duration = 2})
                    end
                end
            })

            -- [[ MOVEMENT ]]
            TabPlayer:AddSection("Character Settings")
            TabPlayer:AddSlider("WS", {
                Title = "🏃 WalkSpeed",
                Default = 16, Min = 16, Max = 300, Rounding = 0,
                Callback = function(v) getgenv().WalkSpeedValue = v end
            })

            -- ОБЫЧНЫЙ FLY (WASD + КАМЕРА)
            TabPlayer:AddToggle("FlyToggle", {Title = "🕊️ Classic Fly", Default = false}):OnChanged(function(v)
                flying = v
                if v and Plr.Character then
                    task.spawn(function()
                        local hrp = Plr.Character.HumanoidRootPart
                        local bg = Instance.new("BodyGyro", hrp)
                        local bv = Instance.new("BodyVelocity", hrp)
                        bg.maxTorque, bv.maxForce = Vector3.new(9e9, 9e9, 9e9), Vector3.new(9e9, 9e9, 9e9)
                        
                        while flying do
                            local direction = Vector3.new(0, 0, 0)
                            local cam = workspace.CurrentCamera.CFrame
                            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + cam.LookVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - cam.LookVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - cam.RightVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + cam.RightVector end
                            
                            bg.cframe = cam
                            bv.velocity = direction * flySpeed
                            task.wait()
                        end
                        bg:Destroy() bv:Destroy()
                    end)
                end
            end)

            TabPlayer:AddSlider("FlySpeed", { Title = "🛸 Fly Speed", Default = flySpeed, Min = 10, Max = 300, Rounding = 0, Callback = function(v) flySpeed = v end })
            TabPlayer:AddToggle("AFK", {Title = "💤 Anti-AFK", Default = true}):OnChanged(function(v) getgenv().AntiAFK = v end)

            TabSettings:AddSection("Config")
            TabSettings:AddButton({ Title = "💾 Save Config", Callback = function() SaveFullConfig() Fluent:Notify({Title="Ok", Content="Saved", Duration=2}) end })

            Window:SelectTab(2) -- Сразу прыгаем в фарм
        else
            Fluent:Notify({Title = "❌ Error", Content = "Invalid Key!", Duration = 2})
        end
    end
})

-- [[ LOOPS ]]
RunService.Heartbeat:Connect(function()
    if Plr.Character and Plr.Character:FindFirstChild("Humanoid") then
        Plr.Character.Humanoid.WalkSpeed = getgenv().WalkSpeedValue
    end
end)

task.spawn(function()
    while task.wait(5) do if getgenv().AntiAFK then VU:CaptureController() VU:ClickButton2(Vector2.new()) end end
end)

task.spawn(function()
    while task.wait(2) do
        if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") and Plr.Character.HumanoidRootPart.Position.Y < -50 then
            if getgenv().DepoPos then SafeTeleport(getgenv().DepoPos) end
        end
    end
end)

Window:SelectTab(1)
