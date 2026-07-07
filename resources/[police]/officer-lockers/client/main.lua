local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    playerData = QBox.Functions.GetPlayerData()

    for locId, location in pairs(Config.OfficerLockers.locations) do
        exports.ox_target:addBoxZone({
            coords = location.coords,
            size = vector3(location.radius * 2, location.radius * 2, 4.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'locker_' .. locId,
                    icon = 'fas fa-locker',
                    label = 'Open Locker (' .. location.label .. ')',
                    distance = Config.OfficerLockers.maxDistance,
                    canInteract = function()
                        if not playerData.job then return false end
                        for _, j in ipairs(location.allowedJobs) do
                            if playerData.job.name == j then return true end
                        end
                        return false
                    end,
                    onSelect = function()
                        TriggerServerEvent('officerlocker:open', locId)
                    end,
                },
            },
        })
    end
end)
