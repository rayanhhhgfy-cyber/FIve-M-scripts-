local QBCore = exports['qbx-core']:GetCoreObject()
local animalBlip = nil
local carcassObjects = {}

local function clearAnimalBlip()
    if animalBlip then
        RemoveBlip(animalBlip)
        animalBlip = nil
    end
end

local function clearCarcassObjects()
    for _, obj in ipairs(carcassObjects) do
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end
    carcassObjects = {}
end

local function setupNPCTarget()
    local npcModel = GetHashKey('a_m_m_hunter_01')
    RequestModel(npcModel)
    local attempts = 0
    while not HasModelLoaded(npcModel) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end
    local npc = CreatePed(4, npcModel, Config.Hunting.sellLocation.x, Config.Hunting.sellLocation.y, Config.Hunting.sellLocation.z - 1.0, 0.0, false, false)
    SetEntityAsMissionEntity(npc, true, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    local npcNet = NetworkGetNetworkIdFromEntity(npc)

    exports.ox_target:addLocalEntity(npc, {
        {
            name = 'hunting_start_hunt',
            label = Locale('hunting.start_hunt'),
            icon = 'fa-solid fa-crosshairs',
            onSelect = function()
                TriggerServerEvent('hunting:startHunt')
            end,
        },
        {
            name = 'hunting_sell',
            label = Locale('hunting.sell'),
            icon = 'fa-solid fa-dollar-sign',
            onSelect = function()
                TriggerServerEvent('hunting:sellHunt')
            end,
        },
    })
end

RegisterNetEvent('hunting:animalSpawned', function(coords, netId, animalIndex)
    clearAnimalBlip()
    clearCarcassObjects()

    animalBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(animalBlip, 141)
    SetBlipColour(animalBlip, 1)
    SetBlipScale(animalBlip, 1.2)
    SetBlipAsShortRange(animalBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Locale('hunting.animal_tracked'))
    EndTextCommandSetBlipName(animalBlip)

    SetNewWaypoint(coords.x, coords.y)

    Wrappers.Notify(Locale('hunting.hunt_started'), 'success')
end)

RegisterNetEvent('hunting:carcassSpawned', function(coords, animalIndex)
    clearAnimalBlip()
    clearCarcassObjects()

    local animal = Config.Hunting.animals[animalIndex]
    local model = GetHashKey(animal.model)
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    local carcass = CreatePed(0, model, coords.x, coords.y, coords.z - 0.5, 0.0, true, false)
    SetEntityAsMissionEntity(carcass, true, true)
    SetEntityInvincible(carcass, true)
    SetPedDiesWhenInjured(carcass, false)
    FreezeEntityPosition(carcass, true)
    SetPedRagdollOnCollision(carcass, false)

    exports.ox_target:addLocalEntity(carcass, {
        {
            name = 'hunting_skin_animal',
            label = Locale('hunting.skinning'),
            icon = 'fa-solid fa-knife',
            onSelect = function()
                TriggerServerEvent('hunting:skinAnimal')
            end,
        },
    })

    table.insert(carcassObjects, carcass)
end)

RegisterNetEvent('hunting:doSkinProgress', function(skinTime)
    Wrappers.ProgressBar({
        duration = skinTime,
        label = Locale('hunting.skinning'),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'anim@amb@medic@standing@kneel@base', clip = 'base' },
        prop = {},
    })
end)

RegisterNetEvent('hunting:killAnimalFeedback', function()
    Wrappers.Notify(Locale('hunting.animal_killed'), 'success')
end)

CreateThread(function()
    setupNPCTarget()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        clearAnimalBlip()
        clearCarcassObjects()
    end
end)
