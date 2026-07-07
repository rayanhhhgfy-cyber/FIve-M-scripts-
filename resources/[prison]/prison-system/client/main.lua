local inPrison = false
local remainingTime = 0
local isEscaped = false

RegisterNetEvent('prison:enterPrison', function(timeSeconds)
    inPrison = true
    isEscaped = false
    remainingTime = timeSeconds
    DoScreenFadeOut(500)
    Citizen.Wait(500)
    local coords = Config.Prison.interior.cellBlock
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
    DoScreenFadeIn(500)
    Wrappers.Notify('Sentenced to ' .. timeSeconds .. 's in prison. Do jobs to reduce time!', 'error')
    CreatePrisonTargets()
end)

RegisterNetEvent('prison:release', function()
    inPrison = false
    DoScreenFadeOut(500)
    Citizen.Wait(500)
    SetEntityCoords(PlayerPedId(), Config.Prison.interior.exit.x, Config.Prison.interior.exit.y, Config.Prison.interior.exit.z)
    DoScreenFadeIn(500)
    Wrappers.Notify('Released! Stay out of trouble.', 'success')
end)

RegisterNetEvent('prison:escaped', function()
    isEscaped = true
    Wrappers.Notify('You escaped! Manhunt active. Avoid police for ' .. Config.Prison.breakout.manhuntDuration .. 's.', 'warning')
end)

RegisterNetEvent('prison:manhuntGPS', function(lastSeen)
    SetNewWaypoint(lastSeen.x, lastSeen.y)
end)

RegisterNetEvent('prison:breakoutProgress', function(methodId, duration)
    Wrappers.ProgressBar({ label = 'Planning ' .. methodId .. ' escape...', duration = duration, onFinish = function()
        TriggerServerEvent('prison:completeBreakout', methodId)
    end })
end)

function CreatePrisonTargets()
    -- Inmate jobs
    for _, job in ipairs(Config.Prison.inmateJobs) do
        exports['ox_target']:addBoxZone({
            coords = job.coords,
            size = vector3(1.5, 1.5, 2.0),
            rotation = 0,
            debug = false,
            options = {
                { label = 'Work: ' .. job.name .. ' ($' .. job.pay .. ')', icon = 'fas fa-briefcase', onSelect = function()
                    Wrappers.ProgressBar({ label = 'Doing ' .. job.name .. '...', duration = job.duration, onFinish = function()
                        TriggerServerEvent('prison:doJob', job.id)
                    end })
                end },
            },
        })
    end
    -- Smuggler (hidden area)
    exports['ox_target']:addBoxZone({
        coords = Config.Prison.interior.cafeteria + vector3(0.0, -5.0, 0.0),
        size = vector3(1.0, 1.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            { label = 'Smuggle Item [Criminal]', icon = 'fas fa-box', onSelect = function()
                local items = {}
                for _, c in ipairs(Config.Prison.contraband) do
                    table.insert(items, { title = c.name .. ' ($' .. c.smugglerPrice .. ')', description = 'Risk: ' .. c.risk, onSelect = function()
                        TriggerServerEvent('prison:smuggleContraband', c.id)
                    end })
                end
                Wrappers.ContextMenu({ id = 'prison_smuggle', title = 'Smuggle Items', menuItems = items })
            end },
        },
    })
    -- Breakout planning
    exports['ox_target']:addBoxZone({
        coords = Config.Prison.interior.yard + vector3(0.0, 5.0, 0.0),
        size = vector3(1.0, 1.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            { label = 'Plan Escape [Criminal]', icon = 'fas fa-running', onSelect = function()
                local items = {}
                for id, method in pairs(Config.Prison.breakout.methods) do
                    table.insert(items, { title = method.name .. ' (Risk: ' .. method.risk .. ')', onSelect = function()
                        TriggerServerEvent('prison:startBreakout', id)
                    end })
                end
                Wrappers.ContextMenu({ id = 'prison_breakout', title = 'Plan Escape', menuItems = items })
            end },
        },
    })
end

-- Time display for inmates
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)
        if inPrison and not isEscaped then
            QBox.Functions.TriggerCallback('prison:getRemainingTime', function(time)
                remainingTime = time
                if time > 0 then
                    Wrappers.Notify('Time remaining: ' .. time .. 's. Do jobs to reduce!', 'info')
                else
                    TriggerServerEvent('prison:release')
                end
            end)
        end
    end
end)

-- Manhunt blip
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isEscaped then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            -- Show danger zone
            DrawMarker(28, coords.x, coords.y, coords.z - 10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Prison.breakout.manhuntRadius * 2, Config.Prison.breakout.manhuntRadius * 2, 50.0, 255, 0, 0, 50, false, true, 2, nil, nil, false)
        end
    end
end)
