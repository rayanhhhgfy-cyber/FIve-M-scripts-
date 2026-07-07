local QBox = exports['qbx-core']:GetCoreObject()
local trainEntities = {}
local openedContainers = {}
local trainActive = false

local function hasItem(item) return QBox.Functions.HasItem(item) end

local function canHeist()
    local police = QBox.Functions.GetPlayersFromJob('police')
    if #police < Config.TrainHeist.MinPolice then Wrappers.Notify('Not enough police', 'error') return false end
    return true
end

local function findNearbyTrain()
    for _, v in ipairs(GetGamePool('CVehicle')) do
        local model = GetEntityModel(v)
        for _, m in ipairs(Config.TrainHeist.TrainModels) do
            if model == GetHashKey(m) then
                local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(v))
                if dist < Config.TrainHeist.Train.spawnDistance then return v end
            end
        end
    end
    return nil
end

Citizen.CreateThread(function()
    exports.ox_target:addModelZone(Config.TrainHeist.TrainModels, {
        name = 'train_board',
        debug = false,
        options = {{
            name = 'train_board_option',
            icon = Config.TrainHeist.TargetOptions.board.icon,
            label = Config.TrainHeist.TargetOptions.board.label,
            distance = Config.TrainHeist.TargetOptions.board.distance,
            canInteract = function(entity) return not trainActive and IsEntityAVehicle(entity) end,
            onSelect = function(entity) TriggerEvent('train:board', entity) end
        }, {
            name = 'train_container_open',
            icon = Config.TrainHeist.TargetOptions.pryOpen.icon,
            label = Config.TrainHeist.TargetOptions.pryOpen.label,
            distance = Config.TrainHeist.TargetOptions.pryOpen.distance,
            canInteract = function(entity) return trainActive and not openedContainers[entity] end,
            onSelect = function(entity) TriggerEvent('train:openContainer', entity) end
        }, {
            name = 'train_loot',
            icon = Config.TrainHeist.TargetOptions.loot.icon,
            label = Config.TrainHeist.TargetOptions.loot.label,
            distance = Config.TrainHeist.TargetOptions.loot.distance,
            canInteract = function(entity) return trainActive and openedContainers[entity] end,
            onSelect = function(entity) TriggerEvent('train:loot', entity) end
        }}
    })
end)

RegisterNetEvent('train:board', function(entity)
    if not canHeist() then return end
    trainActive = true
    local ped = PlayerPedId()
    SetPedIntoVehicle(ped, entity, -1)
    Wrappers.Notify('You boarded the train', 'info')
end)

RegisterNetEvent('train:openContainer', function(entity)
    if not hasItem(Config.TrainHeist.ContainerOpening.requiredItem) then
        Wrappers.Notify('You need a crowbar', 'error') return
    end
    Wrappers.ProgressBar({ label = 'Prying container open...', duration = Config.TrainHeist.ContainerOpening.time, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        openedContainers[entity] = true
        Wrappers.Notify('Container opened', 'success')
    end)
end)

RegisterNetEvent('train:loot', function(entity)
    Wrappers.ProgressBar({ label = 'Looting container...', duration = 4000, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('train:server:loot')
    end)
end)

RegisterNetEvent('train:client:lootResult', function(data)
    local msg = 'Found $' .. data.cash
    if data.items and #data.items > 0 then msg = msg .. ' and items' end
    Wrappers.Notify(msg, 'success')
end)

RegisterNetEvent('train:client:policeAlert', function(street)
    Wrappers.Notify('Train robbery reported near ' .. street, 'warning')
end)
