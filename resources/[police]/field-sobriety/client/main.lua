local QBox = exports['qbx-core']:GetCoreObject()
local testingTarget = nil

local function isLeo()
    local job = QBox.Functions.GetPlayerData().job
    if not job then return false end
    for _, j in ipairs(Config.FieldSobriety.allowedJobs) do
        if job.name == j and job.onduty then return true end
    end
    return false
end

RegisterCommand('sobriety', function()
    if not isLeo() then Wrappers.Notify('Not authorized', 'error') return end
    local ped = PlayerPedId()
    local closest = nil
    local closestDist = 10.0
    for _, pid in ipairs(GetActivePlayers()) do
        local target = GetPlayerPed(pid)
        local dist = #(GetEntityCoords(ped) - GetEntityCoords(target))
        if dist < closestDist then
            closestDist = dist
            closest = pid
        end
    end
    if not closest then Wrappers.Notify('No player nearby', 'error') return end
    testingTarget = closest
    Wrappers.ContextMenu({
        id = 'sobriety_tests',
        title = 'Field Sobriety Tests',
        menuItems = {
            { title = 'Walk-and-Turn Test', onSelect = function() startWalkLine() end },
            { title = 'Alphabet Recitation', onSelect = function() startAlphabet() end },
            { title = 'Horizontal Gaze', onSelect = function() startGaze() end },
            { title = 'End Testing', onSelect = function() testingTarget = nil; Wrappers.Notify('Testing ended', 'info') end },
        }
    })
end, false)
RegisterKeyMapping('sobriety', 'Field Sobriety Tests', 'keyboard', 'u')

function startWalkLine()
    if not testingTarget then return end
    Wrappers.ProgressBar({
        duration = Config.FieldSobriety.tests.walkLine.duration,
        label = 'Walk a straight line — tap W repeatedly',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    }, function(cancelled)
        if cancelled then
            Wrappers.Notify('Test failed: Could not complete', 'error')
            TriggerServerEvent('sobriety:result', testingTarget, 'walkLine', false)
        else
            local success = math.random() > 0.35
            if success then Wrappers.Notify('Test passed', 'success')
            else Wrappers.Notify('Test failed — signs of impairment', 'error') end
            TriggerServerEvent('sobriety:result', testingTarget, 'walkLine', success)
        end
    end)
end

function startAlphabet()
    if not testingTarget then return end
    local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local startIdx = math.random(1, 18)
    local segment = letters:sub(startIdx, startIdx + Config.FieldSobriety.tests.alphabet.letters - 1)
    Wrappers.ProgressBar({
        duration = Config.FieldSobriety.tests.alphabet.duration,
        label = 'Recite: ' .. segment,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    }, function(cancelled)
        if cancelled then
            Wrappers.Notify('Test failed', 'error')
            TriggerServerEvent('sobriety:result', testingTarget, 'alphabet', false)
        else
            local success = math.random() > 0.3
            if success then Wrappers.Notify('Alphabet test passed', 'success')
            else Wrappers.Notify('Alphabet test failed — slurred speech', 'error') end
            TriggerServerEvent('sobriety:result', testingTarget, 'alphabet', success)
        end
    end)
end

function startGaze()
    if not testingTarget then return end
    Wrappers.ProgressBar({
        duration = Config.FieldSobriety.tests.gaze.duration,
        label = 'Follow the light with your eyes',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    }, function(cancelled)
        if cancelled then
            Wrappers.Notify('Test failed', 'error')
            TriggerServerEvent('sobriety:result', testingTarget, 'gaze', false)
        else
            local success = math.random() > 0.25
            if success then Wrappers.Notify('Gaze test passed', 'success')
            else Wrappers.Notify('Gaze test failed — involuntary jerking', 'error') end
            TriggerServerEvent('sobriety:result', testingTarget, 'gaze', success)
        end
    end)
end
