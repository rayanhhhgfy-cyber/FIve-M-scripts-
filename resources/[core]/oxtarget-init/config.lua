Config = Config or {}

Config.Target = {
    toggleHotkey = 'LMENU',
    defaultHotkey = 'LMENU',
    drawSprite = true,
    leftClick = true,
    boneIndices = true,
    dynamicZones = true,
    maxDistance = 2.5,
    showDistance = true,
    highlightTexture = true,
    highlightColor = { 255, 255, 255, 100 }
}

Config.GlobalZones = {
    hospitals = {
        label = 'Hospital',
        icon = 'fas fa-hospital',
        distance = 1.5,
        canInteract = function(entity, distance, coords, player)
            local playerData = exports['qbx_core']:GetPlayer(PlayerId())
            local job = playerData and playerData.PlayerData and playerData.PlayerData.job.name
            return job == 'ambulance' or job == 'police'
        end
    },
    police_stations = {
        label = 'Police Station',
        icon = 'fas fa-shield-halved',
        distance = 1.5,
        canInteract = function(entity, distance, coords, player)
            local playerData = exports['qbx_core']:GetPlayer(PlayerId())
            local job = playerData and playerData.PlayerData and playerData.PlayerData.job.name
            return job == 'police'
        end
    }
}

Config.EntityOptions = {
    vehicle = {
        {
            name = 'vehicle_lock',
            label = 'Lock / Unlock',
            icon = 'fas fa-lock',
            distance = 2.0,
            canInteract = function(entity, distance, coords, player)
                return true
            end,
            onSelect = function(entity)
                local plate = exports['qbx_core']:GetVehiclePlate(entity)
                TriggerServerEvent('oxtarget-init:server:lockVehicle', NetworkGetNetworkIdFromEntity(entity))
            end
        },
        {
            name = 'vehicle_engine',
            label = 'Toggle Engine',
            icon = 'fas fa-key',
            distance = 2.0,
            canInteract = function(entity, distance, coords, player)
                return GetPedInVehicleSeat(entity, -1) == PlayerPedId()
            end,
            onSelect = function(entity)
                SetVehicleEngineOn(entity, not GetIsVehicleEngineRunning(entity), true, true)
            end
        }
    },
    ped = {
        {
            name = 'ped_inspect',
            label = 'Inspect',
            icon = 'fas fa-search',
            distance = 2.0,
            canInteract = function(entity, distance, coords, player)
                return IsPedAPlayer(entity)
            end,
            onSelect = function(entity)
                local playerId = NetworkGetPlayerIndexFromPed(entity)
                local target = GetPlayerServerId(playerId)
                TriggerServerEvent('oxtarget-init:server:inspectPlayer', target)
            end
        }
    },
    object = {
        {
            name = 'object_pickup',
            label = 'Pick Up',
            icon = 'fas fa-hand',
            distance = 2.0,
            canInteract = function(entity, distance, coords, player)
                return true
            end,
            onSelect = function(entity)
                DeleteEntity(entity)
            end
        }
    }
}
