local QBCore = exports['qbx_core']:GetCoreObject()

local function PerformXRay(target)
    local progress = exports['ox_lib']:progressBar({
        duration = Config.XRay.scanTime,
        label = 'Performing X-Ray...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
        anim = {
            dict = 'amb@medic@standing@timeofdeath@base',
            clip = 'base'
        }
    })
    if progress then
        local results = lib.callback.await('xray-system:server:performScan', false, target)
        Citizen.Wait(Config.XRay.resultTime)
        local options = {}
        for _, result in ipairs(results) do
            local resultConfig = Config.ScanResults[result.type]
            if resultConfig then
                table.insert(options, {
                    title = resultConfig.label,
                    description = 'Body Part: ' .. (result.bodyPart or 'N/A') .. ' | Severity: ' .. (result.severity or 'N/A'),
                    icon = resultConfig.icon,
                    readOnly = true
                })
            end
        end
        lib.registerContext({
            id = 'xray_results',
            title = 'X-Ray Results',
            options = options
        })
        lib.showContext('xray_results')
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, room in ipairs(Config.XRayLocations) do
            local dist = #(coords - vector3(room.coords.x, room.coords.y, room.coords.z))
            if dist < 2.0 then
                exports['ox_target']:addLocalEntity(ped, {
                    {
                        name = 'xray_scan_' .. room.name,
                        label = 'Use X-Ray Machine',
                        icon = 'fas fa-x-ray',
                        distance = 2.0,
                        onSelect = function()
                            local closest, dist = exports['ox_lib']:getClosestPlayer(coords, Config.XRay.maxDistance)
                            if closest then
                                PerformXRay(GetPlayerServerId(closest))
                            else
                                Wrappers.Notify({ type = 'error', description = 'No patient nearby' })
                            end
                        end
                    }
                })
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[xray-system] Client X-ray ready.^7')
end)
