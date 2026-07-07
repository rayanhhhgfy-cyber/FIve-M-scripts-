local QBCore = exports['qbx_core']:GetCoreObject()
local patientDiagnostics = {}

lib.callback.register('advanced-triage:server:scanPlayer', function(source, target)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return {} end
    if Config.Triage.requireMedicJob and player.PlayerData.job.name ~= Config.Triage.medicJobName then
        return {}
    end
    local damageState = exports['wasabi-ambulance']:GetDamageState(target) or {}
    local bleeding = exports['wasabi-ambulance']:GetBleeding(target)
    local diagnostics = {}
    for _, bodyPart in pairs(damageState) do
        if bodyPart == 'bullet_wounds' then
            table.insert(diagnostics, { type = 'bullet_wounds', severity = 'severe', details = 'Entry/exit wounds detected' })
        end
    end
    if bleeding then
        table.insert(diagnostics, { type = 'hemorrhage', severity = bleeding, details = 'Active bleeding: ' .. bleeding })
    end
    if #diagnostics == 0 then
        table.insert(diagnostics, { type = 'shock', severity = 'mild', details = 'Minor shock, no critical injuries' })
    end
    patientDiagnostics[source .. '_' .. target] = diagnostics
    return diagnostics
end)

lib.callback.register('advanced-triage:server:treatPlayer', function(source, target, treatmentType)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'No player' end
    if Config.Triage.requireMedicJob and player.PlayerData.job.name ~= Config.Triage.medicJobName then
        return false, 'Not authorized'
    end
    local treatment = Config.TreatmentOptions[treatmentType]
    if not treatment then return false, 'Invalid treatment' end
    if treatment.item then
        local hasItem = exports['ox_inventory']:Search(source, 'count', treatment.item)
        if not hasItem or hasItem < 1 then
            return false, 'Missing: ' .. treatment.label
        end
        exports['ox_inventory']:RemoveItem(source, treatment.item, 1)
    end
    TriggerClientEvent('advanced-triage:client:treatPlayer', target, treatment)
    return true, 'Treatment applied'
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[advanced-triage] Triage diagnostic system active.^7')
end)

exports('GetDiagnostics', function(source, target) return patientDiagnostics[source .. '_' .. target] end)
