local QBox = exports['qbx-core']:GetCoreObject()
local doorCache = {}
local doorStates = {}
local pendingPasscodeDoor = nil

RegisterNetEvent('passcodedoor:addDoor', function(door)
    doorCache[door.id] = door
    if doorCache[door.id] then doorCache[door.id].coords = door.coords end
end)

RegisterNetEvent('passcodedoor:removeDoor', function(doorId)
    doorCache[doorId] = nil
    doorStates[doorId] = nil
end)

RegisterNetEvent('passcodedoor:sync', function(doorId, locked)
    doorStates[doorId] = locked
end)

RegisterNetEvent('passcodedoor:requestPasscode', function(doorId)
    pendingPasscodeDoor = doorId
    local input = Wrappers.InputDialog({
        title = 'Passcode Required',
        options = {
            { type = 'password', label = 'Enter passcode', placeholder = '****', required = true }
        }
    })
    if input and input[1] then
        TriggerServerEvent('passcodedoor:submitPasscode', doorId, input[1])
    end
    pendingPasscodeDoor = nil
end)

--- Door system sync thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for id, state in pairs(doorStates) do
            local door = doorCache[id]
            if door then
                local hash = GetHashKey(door.model)
                DoorSystemSetDoorState(hash, state and 1 or 0, false, false)
            end
        end
    end
end)

--- Request initial sync
Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    TriggerServerEvent('passcodedoor:requestSync')
end)

--- Show label text above doors
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        for id, door in pairs(doorCache) do
            local dCoords = vector3(door.coords.x, door.coords.y, door.coords.z)
            local dist = #(pCoords - dCoords)
            if dist < 5.0 then
                local state = doorStates[id]
                local name = door.label or 'Door'
                local icon = state == false and '~g~Unlocked' or '~r~Locked'
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('~w~[' .. name .. '] ' .. icon)
                EndTextCommandDisplayHelp(0, false, true, -1)
            end
        end
    end
end)
