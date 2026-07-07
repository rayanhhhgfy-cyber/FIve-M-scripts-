local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local analyzing = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function isCID() return playerData.job and (playerData.job.name == 'cid' or playerData.job.name == 'police') end
local function isOnDuty() return playerData.job and playerData.job.onduty end

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    playerData = QBox.Functions.GetPlayerData()
    for locName, loc in pairs(Config.EvidenceLab.LabZones) do
        exports.ox_target:addBoxZone({
            coords = loc.coords, size = vec3(loc.radius * 2, loc.radius * 2, 3.0), rotation = 0, debug = false,
            options = {{
                name = 'evidence_analysis_' .. locName:lower(),
                icon = Config.EvidenceLab.TargetOptions.analysis.icon,
                label = Config.EvidenceLab.TargetOptions.analysis.label,
                group = Config.EvidenceLab.TargetOptions.analysis.group,
                distance = Config.EvidenceLab.TargetOptions.analysis.distance,
                canInteract = function()
                    if Config.EvidenceLab.Restrictions.requireDuty and not isOnDuty() then return false end
                    return not analyzing
                end,
                onSelect = function() TriggerEvent('evidence:analysis:menu') end
            }, {
                name = 'evidence_equipment_' .. locName:lower(),
                icon = Config.EvidenceLab.TargetOptions.equipment.icon,
                label = Config.EvidenceLab.TargetOptions.equipment.label,
                group = Config.EvidenceLab.TargetOptions.equipment.group,
                distance = Config.EvidenceLab.TargetOptions.equipment.distance,
                canInteract = function() return isCID() and isOnDuty() end,
                onSelect = function() TriggerEvent('evidence:equipment:menu') end
            }}
        })
    end
end)

RegisterNetEvent('evidence:analysis:menu', function()
    if analyzing then Wrappers.Notify(Locale('cid.analysis_in_progress'), 'error') return end
    local items = {}
    for typeId, tData in pairs(Config.EvidenceLab.AnalysisTypes) do
        if QBox.Functions.HasItem(tData.item) then
            table.insert(items, { title = tData.label, description = Locale('cid.analysis_time', tData.time / 1000), onSelect = function() TriggerEvent('evidence:analyze', typeId) end })
        end
    end
    if #items == 0 then table.insert(items, { title = Locale('cid.no_evidence_items'), description = '' }) end
    Wrappers.ContextMenu({ id = 'evidence_analysis', title = Locale('cid.select_analysis'), menuItems = items })
end)

RegisterNetEvent('evidence:analyze', function(typeId)
    if analyzing then return end
    local tData = Config.EvidenceLab.AnalysisTypes[typeId]
    if not tData then return end
    if not QBox.Functions.HasItem(tData.item) then Wrappers.Notify(Locale('cid.no_item'), 'error') return end
    analyzing = true
    QBox.Functions.Progressbar(tData.label, tData.time, false, true, {
        disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true
    }, {}, {}, {}, function()
        QBox.Functions.RemoveItem(tData.item, 1)
        TriggerServerEvent('evidence:server:analyze', typeId)
    end, function()
        analyzing = false
        Wrappers.Notify(Locale('cid.analysis_cancelled'), 'warning')
    end)
    Citizen.CreateThread(function()
        Citizen.Wait(tData.time)
        analyzing = false
    end)
end)

RegisterNetEvent('evidence:client:analysisResult', function(result, resultType)
    Wrappers.Notify(Locale('cid.analysis_result', result, resultType), Config.EvidenceLab.ResultCategories[resultType] and Config.EvidenceLab.ResultCategories[resultType].color or 'info')
end)

RegisterNetEvent('evidence:equipment:menu', function()
    local items = {}
    for _, eq in ipairs(Config.EvidenceLab.Equipment) do
        table.insert(items, { title = eq.label, description = Locale('cid.rank_required', eq.rank), onSelect = function() TriggerServerEvent('evidence:server:takeEquipment', eq.item) end })
    end
    Wrappers.ContextMenu({ id = 'evidence_equipment', title = Locale('cid.lab_equipment'), menuItems = items })
end)
