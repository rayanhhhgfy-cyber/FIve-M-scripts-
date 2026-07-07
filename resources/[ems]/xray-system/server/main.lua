local QBCore = exports['qbx_core']:GetCoreObject()

lib.callback.register('xray-system:server:performScan', function(source, target)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return {} end
    if Config.XRay.requireMedicJob and player.PlayerData.job.name ~= Config.XRay.medicJobName then
        return {}
    end
    local damageState = exports['wasabi-ambulance']:GetDamageState(target) or {}
    local results = {}
    for bodyPart, state in pairs(damageState) do
        if state == 'fracture' then
            table.insert(results, { type = 'bone_fractures', bodyPart = bodyPart, severity = 'moderate' })
        elseif state == 'bullet_wound' then
            table.insert(results, { type = 'bullet_fragments', bodyPart = bodyPart, severity = 'severe' })
        elseif state == 'internal_bleeding' then
            table.insert(results, { type = 'internal_bleeding', bodyPart = bodyPart, severity = 'critical' })
        end
    end
    if #results == 0 then
        table.insert(results, { type = 'no_issues', bodyPart = 'none', severity = 'none' })
    end
    return results
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[xray-system] X-ray diagnostic system active. %d scan locations.^7', #Config.XRayLocations)
end)
