local isDead = false
local respawnTimer = 0
local respawnReady = false
local dialogOpen = false

RegisterNetEvent('death:doRespawn', function(hospital)
    isDead = false
    respawnTimer = 0
    respawnReady = false
    dialogOpen = false
    DoScreenFadeOut(500)
    Wait(500)
    local ped = PlayerPedId()
    SetEntityCoords(ped, hospital.x, hospital.y, hospital.z)
    SetEntityHealth(ped, 200)
    ClearPedTasks(ped)
    ClearPedTasksImmediately(ped)
    DoScreenFadeIn(500)
    Wrappers.Notify('You have been revived at the hospital.', 'success')
end)

RegisterNetEvent('death:emsAlert', function(sender, coords)
    Wrappers.Notify('EMS has been notified of your location.', 'info')
end)

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)

        if health <= 0 and not isDead then
            isDead = true
            respawnTimer = Config.Death.respawnTime
            respawnReady = false
            dialogOpen = false
            DoScreenFadeOut(1000)
            SetEntityHealth(ped, 0)
            SetPedToRagdoll(ped, -1, -1, 0, false, false, false)
            TriggerServerEvent('death:callEMS')
        end

        if isDead then
            HideHudAndRadarThisFrame()
            HideHelpTextThisFrame()

            if not respawnReady then
                if respawnTimer > 0 then
                    respawnTimer = respawnTimer - 1
                    Wrappers.TextUI('You are downed — Respawn in ' .. respawnTimer .. 's')
                else
                    respawnReady = true
                end
            else
                Wrappers.TextUI('Press [E] to respawn at hospital ($' .. Config.Death.respawnPrice .. ')')
                if IsControlJustPressed(0, Config.Death.respawnKey) and not dialogOpen then
                    dialogOpen = true
                    Wrappers.AlertDialog({
                        title = 'Injured',
                        content = 'Wait for EMS or respawn at the hospital for $' .. Config.Death.respawnPrice .. '?',
                        buttons = {
                            { label = 'Respawn ($' .. Config.Death.respawnPrice .. ')', action = function()
                                TriggerServerEvent('death:respawn')
                            end},
                            { label = 'Wait for EMS', action = function()
                                dialogOpen = false
                                Wrappers.Notify('Stay put — EMS is on the way.', 'info')
                            end}
                        }
                    })
                end
            end

            Wait(1000)
        end
    end
end)
