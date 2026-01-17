-- Auto Walk System untuk Map Gunung Roblox dengan Maclib UI
-- Load Maclib UI Library
local Maclib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Brady-xyz/Maclib/main/src/init.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Auto Walk Data Storage
local AutoWalkData = {
    recordings = {},
    currentRecording = {},
    isRecording = false,
    isPlaying = false,
    recordingName = "",
    selectedPath = nil,
    playConnection = nil
}

-- Create Main Window
local Window = Maclib:CreateWindow({
    Title = "Auto Walk System - Gunung",
    Subtitle = "Record & Play Path",
    Size = UDim2.new(0, 500, 0, 400),
    Theme = "Dark"
})

-- Create Tabs
local RecordTab = Window:CreateTab({
    Name = "Record",
    Icon = "rbxassetid://7733960981"
})

local ManageTab = Window:CreateTab({
    Name = "Manage Paths",
    Icon = "rbxassetid://7733920644"
})

local PlayTab = Window:CreateTab({
    Name = "Play Path",
    Icon = "rbxassetid://7733954760"
})

-- RECORD TAB
local RecordSection = RecordTab:CreateSection("Recording Controls")

local PathNameInput = RecordSection:CreateInput({
    Name = "Path Name",
    Placeholder = "Masukkan nama path...",
    Callback = function(value)
        AutoWalkData.recordingName = value
    end
})

local RecordButton = RecordSection:CreateButton({
    Name = "Start Recording",
    Callback = function()
        if AutoWalkData.recordingName == "" then
            Maclib:Notify({
                Title = "Error",
                Content = "Masukkan nama path terlebih dahulu!",
                Duration = 3
            })
            return
        end
        
        if not AutoWalkData.isRecording then
            -- Start Recording
            AutoWalkData.isRecording = true
            AutoWalkData.currentRecording = {}
            RecordButton:SetName("Stop Recording")
            
            Maclib:Notify({
                Title = "Recording Started",
                Content = "Path '" .. AutoWalkData.recordingName .. "' sedang direkam",
                Duration = 3
            })
            
            -- Record position every 0.5 seconds
            AutoWalkData.recordConnection = RunService.Heartbeat:Connect(function()
                if AutoWalkData.isRecording then
                    local pos = HumanoidRootPart.Position
                    table.insert(AutoWalkData.currentRecording, {
                        X = pos.X,
                        Y = pos.Y,
                        Z = pos.Z
                    })
                end
            end)
        else
            -- Stop Recording and Save
            AutoWalkData.isRecording = false
            if AutoWalkData.recordConnection then
                AutoWalkData.recordConnection:Disconnect()
            end
            
            RecordButton:SetName("Start Recording")
            
            if #AutoWalkData.currentRecording > 0 then
                AutoWalkData.recordings[AutoWalkData.recordingName] = AutoWalkData.currentRecording
                
                Maclib:Notify({
                    Title = "Recording Saved",
                    Content = "Path '" .. AutoWalkData.recordingName .. "' tersimpan dengan " .. #AutoWalkData.currentRecording .. " waypoints",
                    Duration = 3
                })
                
                UpdatePathList()
            end
        end
    end
})

local RecordInfoLabel = RecordSection:CreateLabel({
    Text = "Waypoints: 0"
})

-- Update waypoint counter while recording
RunService.Heartbeat:Connect(function()
    if AutoWalkData.isRecording then
        RecordInfoLabel:SetText("Waypoints: " .. #AutoWalkData.currentRecording)
    end
end)

-- MANAGE TAB
local ManageSection = ManageTab:CreateSection("Saved Paths")

local PathListDropdown = ManageSection:CreateDropdown({
    Name = "Select Path",
    Options = {},
    Callback = function(selected)
        AutoWalkData.selectedPath = selected
    end
})

function UpdatePathList()
    local pathNames = {}
    for name, _ in pairs(AutoWalkData.recordings) do
        table.insert(pathNames, name)
    end
    PathListDropdown:UpdateOptions(pathNames)
end

local DeleteButton = ManageSection:CreateButton({
    Name = "Delete Selected Path",
    Callback = function()
        if AutoWalkData.selectedPath and AutoWalkData.recordings[AutoWalkData.selectedPath] then
            AutoWalkData.recordings[AutoWalkData.selectedPath] = nil
            
            Maclib:Notify({
                Title = "Path Deleted",
                Content = "Path '" .. AutoWalkData.selectedPath .. "' telah dihapus",
                Duration = 3
            })
            
            AutoWalkData.selectedPath = nil
            UpdatePathList()
        else
            Maclib:Notify({
                Title = "Error",
                Content = "Pilih path terlebih dahulu!",
                Duration = 3
            })
        end
    end
})

local MergeSection = ManageTab:CreateSection("Merge Paths")

local MergePath1 = MergeSection:CreateDropdown({
    Name = "Path 1",
    Options = {},
    Callback = function(selected)
        AutoWalkData.mergePath1 = selected
    end
})

local MergePath2 = MergeSection:CreateDropdown({
    Name = "Path 2",
    Options = {},
    Callback = function(selected)
        AutoWalkData.mergePath2 = selected
    end
})

local MergeNameInput = MergeSection:CreateInput({
    Name = "Merged Path Name",
    Placeholder = "Nama path gabungan...",
    Callback = function(value)
        AutoWalkData.mergedName = value
    end
})

local MergeButton = MergeSection:CreateButton({
    Name = "Merge Paths",
    Callback = function()
        if not AutoWalkData.mergePath1 or not AutoWalkData.mergePath2 or not AutoWalkData.mergedName then
            Maclib:Notify({
                Title = "Error",
                Content = "Lengkapi semua field untuk merge!",
                Duration = 3
            })
            return
        end
        
        local path1 = AutoWalkData.recordings[AutoWalkData.mergePath1]
        local path2 = AutoWalkData.recordings[AutoWalkData.mergePath2]
        
        if path1 and path2 then
            local mergedPath = {}
            
            -- Gabungkan path 1
            for _, waypoint in ipairs(path1) do
                table.insert(mergedPath, waypoint)
            end
            
            -- Gabungkan path 2
            for _, waypoint in ipairs(path2) do
                table.insert(mergedPath, waypoint)
            end
            
            AutoWalkData.recordings[AutoWalkData.mergedName] = mergedPath
            
            Maclib:Notify({
                Title = "Paths Merged",
                Content = "Path baru '" .. AutoWalkData.mergedName .. "' dengan " .. #mergedPath .. " waypoints",
                Duration = 3
            })
            
            UpdatePathList()
            UpdateMergeDropdowns()
        end
    end
})

function UpdateMergeDropdowns()
    local pathNames = {}
    for name, _ in pairs(AutoWalkData.recordings) do
        table.insert(pathNames, name)
    end
    MergePath1:UpdateOptions(pathNames)
    MergePath2:UpdateOptions(pathNames)
end

-- PLAY TAB
local PlaySection = PlayTab:CreateSection("Playback Controls")

local PlayPathDropdown = PlaySection:CreateDropdown({
    Name = "Select Path to Play",
    Options = {},
    Callback = function(selected)
        AutoWalkData.playSelectedPath = selected
    end
})

local SpeedSlider = PlaySection:CreateSlider({
    Name = "Walk Speed",
    Min = 10,
    Max = 50,
    Default = 16,
    Callback = function(value)
        AutoWalkData.walkSpeed = value
    end
})

AutoWalkData.walkSpeed = 16

local PlayButton = PlaySection:CreateButton({
    Name = "Start Auto Walk",
    Callback = function()
        if not AutoWalkData.playSelectedPath or not AutoWalkData.recordings[AutoWalkData.playSelectedPath] then
            Maclib:Notify({
                Title = "Error",
                Content = "Pilih path untuk dijalankan!",
                Duration = 3
            })
            return
        end
        
        if not AutoWalkData.isPlaying then
            AutoWalkData.isPlaying = true
            PlayButton:SetName("Stop Auto Walk")
            
            local path = AutoWalkData.recordings[AutoWalkData.playSelectedPath]
            local currentWaypoint = 1
            
            Maclib:Notify({
                Title = "Auto Walk Started",
                Content = "Berjalan di path '" .. AutoWalkData.playSelectedPath .. "'",
                Duration = 3
            })
            
            AutoWalkData.playConnection = RunService.Heartbeat:Connect(function()
                if not AutoWalkData.isPlaying or currentWaypoint > #path then
                    if AutoWalkData.playConnection then
                        AutoWalkData.playConnection:Disconnect()
                    end
                    AutoWalkData.isPlaying = false
                    PlayButton:SetName("Start Auto Walk")
                    
                    if currentWaypoint > #path then
                        Maclib:Notify({
                            Title = "Path Completed",
                            Content = "Auto walk selesai!",
                            Duration = 3
                        })
                    end
                    return
                end
                
                local waypoint = path[currentWaypoint]
                local targetPos = Vector3.new(waypoint.X, waypoint.Y, waypoint.Z)
                local distance = (HumanoidRootPart.Position - targetPos).Magnitude
                
                if distance < 3 then
                    currentWaypoint = currentWaypoint + 1
                else
                    local direction = (targetPos - HumanoidRootPart.Position).Unit
                    Character.Humanoid:MoveTo(targetPos)
                    Character.Humanoid.WalkSpeed = AutoWalkData.walkSpeed
                end
            end)
        else
            AutoWalkData.isPlaying = false
            if AutoWalkData.playConnection then
                AutoWalkData.playConnection:Disconnect()
            end
            PlayButton:SetName("Start Auto Walk")
        end
    end
})

local LoopToggle = PlaySection:CreateToggle({
    Name = "Loop Path",
    Default = false,
    Callback = function(enabled)
        AutoWalkData.loopPath = enabled
    end
})

-- Update play dropdown when paths change
local function UpdateAllDropdowns()
    UpdatePathList()
    UpdateMergeDropdowns()
    
    local pathNames = {}
    for name, _ in pairs(AutoWalkData.recordings) do
        table.insert(pathNames, name)
    end
    PlayPathDropdown:UpdateOptions(pathNames)
end

-- Initial update
UpdateAllDropdowns()

-- Cleanup on character death
Player.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    if AutoWalkData.isRecording then
        AutoWalkData.isRecording = false
        if AutoWalkData.recordConnection then
            AutoWalkData.recordConnection:Disconnect()
        end
    end
    
    if AutoWalkData.isPlaying then
        AutoWalkData.isPlaying = false
        if AutoWalkData.playConnection then
            AutoWalkData.playConnection:Disconnect()
        end
    end
end)

Maclib:Notify({
    Title = "Auto Walk System",
    Content = "System loaded! Siap untuk merekam path gunung.",
    Duration = 5
})