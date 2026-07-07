local QBCore = exports['qbx_core']:GetCoreObject()
local boomboxId = 0
local currentSound = nil

RegisterNetEvent('wasabi-boombox:client:spawnBoombox', function(coords, url, volume)
    boomboxId = boomboxId + 1
    local model = GetHashKey(Config.Boombox.boomboxModel)
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if not HasModelLoaded(model) then return end
    local boombox = CreateObject(model, coords.x, coords.y, coords.z - 0.5, true, false, false)
    PlaceObjectOnGroundProperly(boombox)
    SetModelAsNoLongerNeeded(model)
    local soundId = GetSoundId()
    PlaySoundFromEntity(soundId, url, boombox, 'boombox', true, volume or Config.Boombox.defaultVolume, Config.Boombox.maxRange)
    currentSound = soundId
    exports['ox_target']:addLocalEntity(boombox, {
        {
            name = 'boombox_stop',
            label = 'Pick Up Boombox',
            icon = 'fas fa-hand',
            distance = 2.0,
            onSelect = function()
                if currentSound then
                    StopSound(currentSound)
                    ReleaseSoundId(currentSound)
                    currentSound = nil
                end
                TriggerServerEvent('wasabi-boombox:server:removeBoombox', boomboxId)
                DeleteEntity(boombox)
            end
        },
        {
            name = 'boombox_volume',
            label = 'Change Volume',
            icon = 'fas fa-volume-up',
            distance = 2.0,
            onSelect = function()
                local input = lib.inputDialog('Boombox Volume', {
                    { type = 'number', label = 'Volume (0-100)', value = tonumber(Config.Boombox.defaultVolume * 100), min = 0, max = 100 }
                })
                if input and currentSound then
                    SetSoundVolume(currentSound, tonumber(input[1]) / 100)
                end
            end
        }
    })
    TriggerServerEvent('wasabi-boombox:server:registerBoombox', boomboxId, coords)
end)

RegisterNetEvent('wasabi-boombox:client:removeBoombox', function(id)
    if currentSound then
        StopSound(currentSound)
        ReleaseSoundId(currentSound)
        currentSound = nil
    end
end)

RegisterNetEvent('wasabi-boombox:client:useBoombox', function()
    local options = {}
    for i, preset in ipairs(Config.Presets) do
        table.insert(options, {
            title = preset.name,
            icon = 'fas fa-music',
            onSelect = function()
                TriggerServerEvent('wasabi-boombox:server:placeBoombox', preset.url, Config.Boombox.defaultVolume)
            end
        })
    end
    table.insert(options, {
        title = 'Custom URL',
        icon = 'fas fa-link',
        onSelect = function()
            local input = lib.inputDialog('Custom Stream URL', {
                { type = 'input', label = 'URL', placeholder = 'https://...', required = true }
            })
            if input then
                TriggerServerEvent('wasabi-boombox:server:placeBoombox', input[1], Config.Boombox.defaultVolume)
            end
        end
    })
    lib.registerContext({
        id = 'boombox_use_menu',
        title = 'Boombox',
        options = options
    })
    lib.showContext('boombox_use_menu')
end)

AddEventHandler('ox_inventory:itemUsed', function(itemName)
    if itemName == Config.Boombox.itemName then
        TriggerEvent('wasabi-boombox:client:useBoombox')
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[wasabi-boombox] Client boombox ready.^7')
end)
