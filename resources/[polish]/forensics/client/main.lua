local QBox = exports['qbx_core']:GetCoreObject()
local PlayerData = QBox.Functions.GetPlayerData()
local terminalOpen = false

local function collectEvidence(evidenceType, metadata)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local nearby = GetClosestObjectOfType(coords.x, coords.y, coords.z, Config.Forensics.collectionRange, metadata.model or 0, false, false, false)

    if evidenceType ~= 'fingerprint' and not DoesEntityExist(nearby) then
        exports.ox_lib:notify({ type = 'error', description = 'No evidence source found nearby' })
        return false
    end

    local success = exports.ox_lib:progressBar({
        duration = 3000,
        label = 'Collecting ' .. evidenceType .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, mouse = false, combat = true },
        anim = { dict = 'mp_common', clip = 'givetake1_a', flag = 1 },
    })
    if not success then
        exports.ox_lib:notify({ type = 'error', description = 'Collection cancelled' })
        return false
    end

    local evData = {
        type = evidenceType,
        data = metadata.data or 'No data',
        coords = coords,
        timestamp = os.time(),
        evidenceId = 'EVD-' .. math.random(100000, 999999),
        playerName = GetPlayerName(cache.serverId),
    }

    local hasBag = exports.ox_inventory:Search('count', 'evidence_bag') > 0
    if hasBag then
        exports.ox_inventory:AddItem('evidence_bag', 1, evData)
        exports.ox_lib:notify({ type = 'success', description = evidenceType:gsub('^%l', string.upper) .. ' collected and stored in evidence bag' })
    else
        exports.ox_lib:notify({ type = 'info', description = 'No evidence bag — evidence stored loose' })
        local itemName = 'evidence_' .. evidenceType
        exports.ox_inventory:AddItem(itemName, 1, evData)
    end

    if DoesEntityExist(nearby) then
        SetEntityAsMissionEntity(nearby, true, true)
        DeleteEntity(nearby)
    end

    return true
end

--- Exports for ox_inventory item use

exports('collectFingerprint', function(data, slot)
    collectEvidence('fingerprint', { data = 'Lifted from surface at ' .. GetEntityCoords(PlayerPedId()), model = 0 })
end)

exports('collectCasing', function(data, slot)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local casing = GetClosestObjectOfType(coords.x, coords.y, coords.z, Config.Forensics.collectionRange, `prop_shell_casing`, false, false, false)
    if not DoesEntityExist(casing) then
        casing = GetClosestObjectOfType(coords.x, coords.y, coords.z, Config.Forensics.collectionRange, `prop_shell_casing_02`, false, false, false)
    end
    collectEvidence('casing', { data = 'Shell casing collected', model = `prop_shell_casing` })
end)

exports('collectDNA', function(data, slot)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local blood = GetClosestObjectOfType(coords.x, coords.y, coords.z, Config.Forensics.collectionRange, `prop_blood_pool`, false, false, false)
    if not DoesEntityExist(blood) then
        blood = GetClosestObjectOfType(coords.x, coords.y, coords.z, Config.Forensics.collectionRange, `p_bloodpool`, false, false, false)
    end
    collectEvidence('dna', { data = 'DNA swab collected from blood sample', model = `prop_blood_pool` })
end)

--- Terminal interaction

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - Config.Forensics.terminalLocation)

        if dist < 3.0 then
            DrawMarker(Config.Forensics.markers.terminal.type, Config.Forensics.terminalLocation.x, Config.Forensics.terminalLocation.y, Config.Forensics.terminalLocation.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Forensics.markers.terminal.scale, Config.Forensics.markers.terminal.scale, 1.0, Config.Forensics.markers.terminal.color.r, Config.Forensics.markers.terminal.color.g, Config.Forensics.markers.terminal.color.b, 155, false, false, 2, false, nil, nil, false)

            if dist < 1.5 then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to open Forensics Terminal')
                EndTextCommandDisplayHelp(0)
                if IsControlJustReleased(0, 38) then -- E key
                    openTerminal()
                end
            end
        else
            Wait(500)
        end
    end
end)

function openTerminal()
    if terminalOpen then return end
    terminalOpen = true
    SetNuiFocus(true, true)

    local evidenceItems = lib.callback.await('forensics:getEvidence', false)
    SendNUIMessage({
        action = 'openTerminal',
        data = {
            evidence = evidenceItems,
            location = Config.Forensics.terminalLocation,
        }
    })
end

RegisterNUICallback('closeTerminal', function(_, cb)
    terminalOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('analyzeEvidence', function(data, cb)
    cb('ok')
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    if #(coords - Config.Forensics.terminalLocation) > 5.0 then
        exports.ox_lib:notify({ type = 'error', description = 'You moved too far from the terminal' })
        return
    end

    local success = exports.ox_lib:progressBar({
        duration = Config.Forensics.analysisTime,
        label = 'Analyzing evidence...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, mouse = false, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 1 },
    })
    if not success then
        exports.ox_lib:notify({ type = 'error', description = 'Analysis cancelled' })
        return
    end

    local result = lib.callback.await('forensics:analyzeEvidence', false, data.evidenceId)
    SendNUIMessage({
        action = 'analysisResult',
        data = result,
    })
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBox.Functions.GetPlayerData()
end)
