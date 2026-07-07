local QBCore = exports['qbx_core']:GetCoreObject()
local currentRadio = nil
local soundId = nil

RegisterNetEvent('rcore-radiocar:client:startRadio', function(netId, url, volume)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then return end
    if soundId then
        StopSound(soundId)
        ReleaseSoundId(soundId)
    end
    soundId = GetSoundId()
    PlaySoundFromEntity(soundId, url, entity, 'radio', true, volume or Config.RadioCar.defaultVolume, Config.RadioCar.maxRange)
    currentRadio = netId
end)

RegisterNetEvent('rcore-radiocar:client:stopRadio', function(netId)
    if soundId then
        StopSound(soundId)
        ReleaseSoundId(soundId)
        soundId = nil
    end
    if currentRadio == netId then
        currentRadio = nil
    end
end)

RegisterNetEvent('rcore-radiocar:client:setVolume', function(netId, volume)
    if soundId then
        SetSoundVolume(soundId, volume)
    end
end)

RegisterNetEvent('rcore-radiocar:client:setUrl', function(netId, url)
    if soundId then
        StopSound(soundId)
        ReleaseSoundId(soundId)
        soundId = nil
    end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then return end
    soundId = GetSoundId()
    PlaySoundFromEntity(soundId, url, entity, 'radio', true, Config.RadioCar.defaultVolume, Config.RadioCar.maxRange)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle and vehicle > 0 then
            local netId = NetworkGetNetworkIdFromEntity(vehicle)
            exports['ox_target']:addLocalEntity(vehicle, {
                {
                    name = 'car_radio_open_' .. netId,
                    label = 'Radio',
                    icon = 'fas fa-radio',
                    distance = 2.0,
                    canInteract = function(entity)
                        return GetPedInVehicleSeat(entity, -1) == ped
                    end,
                    onSelect = function()
                        local options = {}
                        for i, preset in ipairs(Config.Presets) do
                            table.insert(options, {
                                title = preset.name,
                                description = preset.genre .. ' — ' .. preset.url,
                                icon = 'fas fa-music',
                                onSelect = function()
                                    TriggerServerEvent('rcore-radiocar:server:startRadio', netId, preset.url, Config.RadioCar.defaultVolume)
                                end
                            })
                        end
                        table.insert(options, {
                            title = 'Custom URL',
                            icon = 'fas fa-link',
                            onSelect = function()
                                local input = lib.inputDialog('Custom Radio URL', {
                                    { type = 'input', label = 'Stream URL', placeholder = 'https://...', required = true }
                                })
                                if input then
                                    TriggerServerEvent('rcore-radiocar:server:startRadio', netId, input[1], Config.RadioCar.defaultVolume)
                                end
                            end
                        })
                        table.insert(options, {
                            title = 'Volume',
                            icon = 'fas fa-volume-up',
                            onSelect = function()
                                local input = lib.inputDialog('Volume', {
                                    { type = 'number', label = 'Volume (0-100)', value = Config.RadioCar.defaultVolume * 100, min = 0, max = 100 }
                                })
                                if input then
                                    TriggerServerEvent('rcore-radiocar:server:setVolume', netId, tonumber(input[1]) / 100)
                                end
                            end
                        })
                        table.insert(options, {
                            title = 'Stop Radio',
                            icon = 'fas fa-stop',
                            onSelect = function()
                                TriggerServerEvent('rcore-radiocar:server:stopRadio', netId)
                            end
                        })
                        lib.registerContext({
                            id = 'car_radio_menu',
                            title = 'Car Radio',
                            options = options
                        })
                        lib.showContext('car_radio_menu')
                    end
                }
            })
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[rcore-radiocar] Client car radio ready.^7')
end)

exports('IsRadioActive', function() return currentRadio ~= nil end)
