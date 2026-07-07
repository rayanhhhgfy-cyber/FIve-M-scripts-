local QBCore = exports['qbx_core']:GetCoreObject()

local function ScanPlayer(target)
    local progress = exports['ox_lib']:progressBar({
        duration = Config.Triage.scanTime,
        label = 'Scanning patient...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
        anim = {
            dict = 'mini_cpr',
            clip = 'cpr_pumpchest'
        }
    })
    if progress then
        local diagnostics = lib.callback.await('advanced-triage:server:scanPlayer', false, target)
        if #diagnostics == 0 then
            Wrappers.Notify({ type = 'info', description = 'No critical injuries found.' })
            return
        end
        local options = {}
        for _, diag in ipairs(diagnostics) do
            local diagConfig = Config.DiagnosticTypes[diag.type]
            if diagConfig then
                table.insert(options, {
                    title = diagConfig.label,
                    description = diag.details .. ' (Severity: ' .. diag.severity .. ')',
                    icon = diagConfig.icon,
                    readOnly = true
                })
            end
        end
        for treatmentType, treatment in pairs(Config.TreatmentOptions) do
            table.insert(options, {
                title = treatment.label,
                description = 'Requires: ' .. (treatment.item or 'none') .. ' | Time: ' .. (treatment.time / 1000) .. 's',
                icon = 'fas fa-syringe',
                onSelect = function()
                    local success, msg = lib.callback.await('advanced-triage:server:treatPlayer', false, target, treatmentType)
                    Wrappers.Notify({ type = success and 'success' or 'error', description = msg })
                end
            })
        end
        lib.registerContext({
            id = 'triage_results',
            title = 'Triage Results',
            options = options
        })
        lib.showContext('triage_results')
    end
end

RegisterNetEvent('advanced-triage:client:treatPlayer', function(treatment)
    local progress = exports['ox_lib']:progressBar({
        duration = treatment.time,
        label = treatment.label,
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableMouse = false,
        disableCombat = true
    })
    if progress then
        Wrappers.Notify({ type = 'success', description = treatment.label .. ' applied.' })
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local closest, dist = exports['ox_lib']:getClosestPlayer(coords, Config.Triage.maxDistance)
        if closest and dist < Config.Triage.maxDistance then
            local target = GetPlayerServerId(closest)
            exports['ox_target']:addLocalEntity(ped, {
                {
                    name = 'triage_scan_' .. target,
                    label = 'Triage Scan',
                    icon = 'fas fa-stethoscope',
                    distance = Config.Triage.maxDistance,
                    onSelect = function()
                        ScanPlayer(target)
                    end
                }
            })
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[advanced-triage] Client triage ready.^7')
end)
