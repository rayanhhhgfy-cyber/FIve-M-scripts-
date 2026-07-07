local QBox = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('forensic:collect', function(evidenceType)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p or not (p.PlayerData.job.name == Config.ForensicKit.allowedJob and p.PlayerData.job.onduty) then return end
    local eConfig = Config.ForensicKit.evidenceTypes[evidenceType]
    if not eConfig then return end
    p.Functions.AddItem('evidence_' .. evidenceType, 1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = eConfig.label .. ' bagged and logged' })
end)
