local QBox = exports['qbx_core']:GetCoreObject()
local PlayerData = QBox.Functions.GetPlayerData()
local currentHeist = nil
local currentPhase = 0
local phaseActive = false
local bankTruckBlip = nil
local hackActive = false

--- Utility
local function drawMarker3D(loc, type, scale, r, g, b, alpha)
    DrawMarker(type, loc.x, loc.y, loc.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, scale, scale, 1.0, r or 255, g or 255, b or 255, alpha or 155, false, false, 2, false, nil, nil, false)
end

--- Heist location markers
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for heistId, heistConfig in pairs(Config.Heists.heists) do
            local entry = heistConfig.locations.entry
            if entry then
                local dist = #(coords - entry)
                if dist < 50.0 then
                    local markerType = 1
                    local color = { r = 255, g = 200, b = 0 }
                    if currentHeist == heistId then
                        color = { r = 0, g = 255, b = 100 }
                    end
                    drawMarker3D(entry, markerType, 1.5, color.r, color.g, color.b, 155)
                    DrawMarker(28, entry.x, entry.y, entry.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0, color.r, color.g, color.b, 60, false, false, 2, false, nil, nil, false)

                    if dist < 3.0 then
                        if currentHeist == heistId then
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to interact with heist phase')
                            EndTextCommandDisplayHelp(0)
                            if IsControlJustReleased(0, 38) then
                                triggerCurrentPhase(heistId)
                            end
                        else
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName('Press ~g~E~w~ to start ' .. heistConfig.label .. ' heist (~y~$' .. heistConfig.lootReward.min / 1000 .. 'k-$' .. heistConfig.lootReward.max / 1000 .. 'k~w~)')
                            EndTextCommandDisplayHelp(0)
                            if IsControlJustReleased(0, 38) then
                                startHeist(heistId)
                            end
                        end
                    end
                end
            end
        end

        if not currentHeist then
            Wait(500)
        end
    end
end)

function startHeist(heistId)
    local heistConfig = Config.Heists.heists[heistId]
    local result = lib.callback.await('multi-heists:startHeist', false, heistId)
    if not result then return end

    if result.success then
        currentHeist = heistId
        currentPhase = 0
        phaseActive = false
        exports.ox_lib:notify({ type = 'success', description = heistConfig.label .. ' heist started! Follow the markers.', duration = 8000 })

        if heistConfig.policeAlertPhase == 0 then
            TriggerServerEvent('multi-heists:completePhase', heistId)
        end
    else
        exports.ox_lib:notify({ type = 'error', description = result.message, duration = 6000 })
    end
end

function triggerCurrentPhase(heistId)
    if phaseActive then
        exports.ox_lib:notify({ type = 'error', description = 'Already performing an action' })
        return
    end

    local heistConfig = Config.Heists.heists[heistId]
    local phaseConfig = heistConfig.phases[currentPhase + 1]
    if not phaseConfig then
        exports.ox_lib:notify({ type = 'error', description = 'No active phase' })
        return
    end

    phaseActive = true

    -- Check required item
    if phaseConfig.item then
        local hasItem = exports.ox_inventory:Search('count', phaseConfig.item) > 0
        if not hasItem then
            exports.ox_lib:notify({ type = 'error', description = 'Need: ' .. phaseConfig.item })
            phaseActive = false
            return
        end
    end

    -- Start phase with progress bar or mini-game
    if phaseConfig.label == 'Hack Security Grid' or phaseConfig.label == 'Hack Terminal' then
        openHackGame(heistId)
    elseif phaseConfig.label == 'Drill Vault' or phaseConfig.label == 'Drill Primary Vault' or phaseConfig.label == 'Drill Inner Vault' then
        doDrillPhase(heistId)
    elseif phaseConfig.label == 'Place C4' or phaseConfig.label == 'Detonate & Loot' then
        doC4Phase(heistId)
    elseif phaseConfig.label == 'Hold Off Police' then
        doHoldPhase(heistId)
    else
        doGenericPhase(heistId)
    end
end

function doGenericPhase(heistId)
    local heistConfig = Config.Heists.heists[heistId]
    local phaseConfig = heistConfig.phases[currentPhase + 1]

    local success = exports.ox_lib:progressBar({
        duration = phaseConfig.time,
        label = phaseConfig.desc,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, mouse = false, combat = true },
        anim = { dict = 'mp_common', clip = 'givetake1_a', flag = 1 },
    })

    if success then
        exports.ox_inventory:RemoveItem(phaseConfig.item, 1)
        TriggerServerEvent('multi-heists:completePhase', heistId)
        exports.ox_lib:notify({ type = 'success', description = phaseConfig.label .. ' - Complete!' })
    else
        exports.ox_lib:notify({ type = 'error', description = 'Phase cancelled' })
    end
    phaseActive = false
end

function doDrillPhase(heistId)
    local heistConfig = Config.Heists.heists[heistId]
    local phaseConfig = heistConfig.phases[currentPhase + 1]

    local ped = PlayerPedId()
    local drill = GetClosestObjectOfType(GetEntityCoords(ped), 5.0, `prop_tool_drill`, false, false, false)
    if not DoesEntityExist(drill) then
        drill = CreateObject(`prop_tool_drill`, heistConfig.locations.vault.x, heistConfig.locations.vault.y, heistConfig.locations.vault.z - 0.5, true, true, true)
        SetEntityHeading(drill, GetEntityHeading(ped))
        FreezeEntityPosition(drill, true)
    end

    local success = exports.ox_lib:progressBar({
        duration = phaseConfig.time,
        label = phaseConfig.desc,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, mouse = false, combat = true },
        anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loob_mechandplayer', flag = 1 },
    })

    if DoesEntityExist(drill) then
        SetEntityAsMissionEntity(drill, true, true)
        DeleteEntity(drill)
    end

    if success then
        exports.ox_inventory:RemoveItem('drill', 1)
        TriggerServerEvent('multi-heists:completePhase', heistId)
        exports.ox_lib:notify({ type = 'success', description = 'Vault drilled successfully!' })
    else
        exports.ox_lib:notify({ type = 'error', description = 'Drilling interrupted' })
    end
    phaseActive = false
end

function doC4Phase(heistId)
    local heistConfig = Config.Heists.heists[heistId]
    local phaseConfig = heistConfig.phases[currentPhase + 1]

    local success = exports.ox_lib:progressBar({
        duration = phaseConfig.time,
        label = phaseConfig.desc,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, mouse = false, combat = true },
        anim = { dict = 'mp_common', clip = 'givetake1_a', flag = 1 },
    })

    if success then
        if currentPhase == 0 then
            exports.ox_inventory:RemoveItem('c4_charge', 1)
        end

        TriggerServerEvent('multi-heists:completePhase', heistId)
        exports.ox_lib:notify({ type = 'success', description = phaseConfig.label .. ' - Complete!' })

        if string.find(phaseConfig.label, 'Detonate') then
            AddExplosion(heistConfig.locations.vault.x, heistConfig.locations.vault.y, heistConfig.locations.vault.z, 2, 5.0, true, false, 1.0)
            ShakeGameplayCam('EXPLOSION_SHAKE', 0.5)
            Wait(1000)
            exports.ox_lib:notify({ type = 'success', description = 'Door breached! Grab the loot!' })
        end
    else
        exports.ox_lib:notify({ type = 'error', description = 'Phase cancelled' })
    end
    phaseActive = false
end

function doHoldPhase(heistId)
    local heistConfig = Config.Heists.heists[heistId]
    local phaseConfig = heistConfig.phases[currentPhase + 1]
    local startTime = GetGameTimer()

    exports.ox_lib:notify({ type = 'warning', description = 'Defend the position for ' .. math.floor(phaseConfig.time / 1000) .. ' seconds!', duration = phaseConfig.time })

    CreateThread(function()
        while phaseActive and currentHeist == heistId do
            Wait(0)
            local elapsed = GetGameTimer() - startTime
            local remaining = math.max(0, math.floor((phaseConfig.time - elapsed) / 1000))

            if remaining > 0 then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Hold position — ' .. remaining .. 's remaining')
                EndTextCommandDisplayHelp(0)

                if elapsed >= phaseConfig.time then
                    phaseActive = false
                    TriggerServerEvent('multi-heists:completePhase', heistId)
                    exports.ox_lib:notify({ type = 'success', description = 'Position held! Escape route ready.' })
                    break
                end
            end

            if IsPlayerDead(PlayerId()) then
                phaseActive = false
                TriggerServerEvent('multi-heists:failHeist', heistId)
                break
            end
        end
    end)

    while phaseActive and currentHeist == heistId do
        Wait(100)
    end
end

--- Hack mini-game (NUI)
function openHackGame(heistId)
    hackActive = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startHack',
        data = {
            heistId = heistId,
            difficulty = currentHeist == 'paleto' and 0.35 or 0.50,
        }
    })
end

RegisterNUICallback('hackResult', function(data, cb)
    cb('ok')
    hackActive = false
    SetNuiFocus(false, false)

    if data.success then
        exports.ox_inventory:RemoveItem('hack_usb', 1)
        TriggerServerEvent('multi-heists:completePhase', currentHeist)
        exports.ox_lib:notify({ type = 'success', description = 'Security bypassed!' })
    else
        exports.ox_lib:notify({ type = 'error', description = 'Hack failed!' })
    end
    phaseActive = false
end)

RegisterNUICallback('cancelHack', function(_, cb)
    cb('ok')
    hackActive = false
    SetNuiFocus(false, false)
    phaseActive = false
end)

--- Police alert handler
RegisterNetEvent('multi-heists:policeAlert', function(coords, title, blipTime)
    if not coords then return end
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(title .. ' — ACTIVE')
    EndTextCommandSetBlipName(blip)
    exports.ox_lib:notify({ type = 'warning', description = 'ALERT: ' .. title .. ' in progress!', duration = 8000 })

    SetTimeout(blipTime * 1000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

--- Bank truck notification
RegisterNetEvent('multi-heists:bankTruckSpawned', function(route)
    if bankTruckBlip and DoesBlipExist(bankTruckBlip) then RemoveBlip(bankTruckBlip) end
    bankTruckBlip = AddBlipForCoord(route.start.x, route.start.y, route.start.z)
    SetBlipSprite(bankTruckBlip, 477)
    SetBlipColour(bankTruckBlip, 5)
    SetBlipScale(bankTruckBlip, 1.2)
    SetBlipAsShortRange(bankTruckBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Armored Bank Truck')
    EndTextCommandSetBlipName(bankTruckBlip)
end)

--- Mask export
exports('wearMask', function()
    local ped = PlayerPedId()
    local mask = GetPedDrawableVariation(ped, 1)
    if mask ~= 0 then
        SetPedComponentVariation(ped, 1, 0, 0, 0)
        exports.ox_lib:notify({ type = 'info', description = 'Mask removed' })
    else
        SetPedComponentVariation(ped, 1, 130, 0, 0)
        exports.ox_lib:notify({ type = 'success', description = 'Mask equipped' })
    end
end)

--- Player loaded event
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key ~= 'all' then return end
    PlayerData = val
end)

--- Cleanup
AddEventHandler('onClientResourceStop', function(res)
    if res == GetCurrentResourceName() then
        if bankTruckBlip and DoesBlipExist(bankTruckBlip) then RemoveBlip(bankTruckBlip) end
        SetNuiFocus(false, false)
    end
end)
