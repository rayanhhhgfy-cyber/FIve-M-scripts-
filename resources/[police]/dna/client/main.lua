local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local closeToPed = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function getClosestPlayerPed()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest, closestDist = nil, Config.DNA.CollectionZones.MRPD.radius
    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= ped then
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(coords - targetCoords)
            if dist < closestDist then
                closest = player
                closestDist = dist
                closeToPed = player
            end
        end
    end
    return closest, closestDist
end

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do
        Citizen.Wait(100)
    end
    playerData = QBox.Functions.GetPlayerData()

    for locName, loc in pairs(Config.DNA.CollectionZones) do
        exports.ox_target:addBoxZone({
            coords = loc.coords,
            size = vec3(loc.radius * 2, loc.radius * 2, 3.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'dna_collect_' .. locName:lower(),
                    icon = Config.DNA.TargetOptions.collect.icon,
                    label = Config.DNA.TargetOptions.collect.label,
                    group = Config.DNA.TargetOptions.collect.group,
                    distance = Config.DNA.TargetOptions.collect.distance,
                    canInteract = function()
                        if Config.DNA.RequireDuty and not isOnDuty() then return false end
                        return QBox.Functions.HasItem(Config.DNA.KitItem)
                    end,
                    onSelect = function()
                        TriggerEvent('dna:collect')
                    end
                }
            }
        })
    end

    for locName, loc in pairs(Config.DNA.AnalysisLabs) do
        exports.ox_target:addBoxZone({
            coords = loc.coords,
            size = vec3(2.0, 2.0, 3.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'dna_analyze_' .. locName:lower(),
                    icon = Config.DNA.TargetOptions.analyze.icon,
                    label = Config.DNA.TargetOptions.analyze.label,
                    group = Config.DNA.TargetOptions.analyze.group,
                    distance = Config.DNA.TargetOptions.analyze.distance,
                    canInteract = function()
                        if Config.DNA.RequireDuty and not isOnDuty() then return false end
                        return QBox.Functions.HasItem(Config.DNA.SwabItem)
                    end,
                    onSelect = function()
                        TriggerEvent('dna:analyze')
                    end
                },
                {
                    name = 'dna_database_' .. locName:lower(),
                    icon = Config.DNA.TargetOptions.database.icon,
                    label = Config.DNA.TargetOptions.database.label,
                    group = Config.DNA.TargetOptions.database.group,
                    distance = Config.DNA.TargetOptions.database.distance,
                    canInteract = function()
                        if Config.DNA.RequireDuty and not isOnDuty() then return false end
                        return true
                    end,
                    onSelect = function()
                        TriggerEvent('dna:database')
                    end
                }
            }
        })
    end
end)

RegisterNetEvent('dna:collect', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    if not QBox.Functions.HasItem(Config.DNA.KitItem) then
        Wrappers.Notify(Locale('police.no_dna_kit'), 'error')
        return
    end
    local closestPlayer, closestDist = getClosestPlayerPed()
    if not closestPlayer or closestDist > 3.0 then
        Wrappers.Notify(Locale('police.no_player_near'), 'error')
        return
    end
    local targetPed = GetPlayerPed(closestPlayer)
    if not IsPedDeadOrDying(targetPed) and not IsEntityPlayingAnim(targetPed, 'missminuteman_1ig_1', 'handsup_base', 3) then
        Wrappers.Notify(Locale('police.player_resisting_dna'), 'error')
        return
    end
    Wrappers.ProgressBar({
        label = Locale('police.collecting_dna'),
        duration = Config.DNA.CollectionTime,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        QBox.Functions.RemoveItem(Config.DNA.KitItem, 1)
        TriggerServerEvent('dna:server:collect', GetPlayerServerId(closestPlayer))
    end)
end)

RegisterNetEvent('dna:client:collectResult', function(sampleId)
    QBox.Functions.AddItem(Config.DNA.SwabItem, 1, nil, sampleId)
    Wrappers.Notify(Locale('police.dna_collected'), 'success')
end)

RegisterNetEvent('dna:analyze', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    if not QBox.Functions.HasItem(Config.DNA.SwabItem) then
        Wrappers.Notify(Locale('police.no_dna_swab'), 'error')
        return
    end
    Wrappers.ProgressBar({
        label = Locale('police.analyzing_dna'),
        duration = Config.DNA.AnalysisTime,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        local itemData = QBox.Functions.GetItemByName(Config.DNA.SwabItem)
        local sampleId = itemData and itemData.info and itemData.info.sampleId
        if not sampleId then
            Wrappers.Notify(Locale('police.no_dna_sample_id'), 'error')
            return
        end
        TriggerServerEvent('dna:server:analyze', sampleId)
    end)
end)

RegisterNetEvent('dna:client:analysisResult', function(result)
    Wrappers.Notify(Locale('police.dna_result', result), 'info')
end)

RegisterNetEvent('dna:database', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    TriggerServerEvent('dna:server:getDatabase')
end)

RegisterNetEvent('dna:client:showDatabase', function(samples)
    local menuItems = {}
    if samples and #samples > 0 then
        for _, sample in ipairs(samples) do
            table.insert(menuItems, {
                title = 'Sample #' .. sample.id,
                description = sample.citizenid .. ' - ' .. (sample.analyzed and 'Analyzed' or 'Pending'),
                onSelect = function()
                    Wrappers.Notify(Locale('police.dna_detail', sample.id, sample.citizenid, sample.analyzed and Locale('police.analyzed') or Locale('police.pending')), 'info')
                end
            })
        end
    else
        table.insert(menuItems, { title = Locale('police.no_dna_samples'), description = '' })
    end
    Wrappers.ContextMenu({ id = 'dna_database_menu', title = Locale('police.dna_database'), menuItems = menuItems })
end)
