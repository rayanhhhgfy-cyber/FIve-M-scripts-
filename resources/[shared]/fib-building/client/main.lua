local QBox = exports['qbx-core']:GetCoreObject()
local inside = false
local insideElevator = false
local entranceZone = nil
local exitZone = nil
local doorZones = {}

--- ENTRANCE / EXIT ---
CreateThread(function()
    while true do
        Wait(2000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        if not inside then
            local dist = #(coords - Config.FIB.entrance.coords)
            if dist < 5.0 then
                if not entranceZone then
                    entranceZone = exports.ox_target:addBoxZone({
                        coords = Config.FIB.entrance.coords,
                        size = vec3(2.0, 2.0, 3.0),
                        rotation = Config.FIB.entrance.heading,
                        debug = false,
                        options = {
                            {
                                name = 'fib_enter',
                                label = 'Enter FIB Building',
                                icon = 'fas fa-building',
                                distance = 2.0,
                                onSelect = function()
                                    lib.callback('fib:server:canEnter', false, function(hasAccess)
                                        if not hasAccess then return end
                                        local state = GetEntityCoords(ped)
                                        SetEntityCoords(ped, Config.FIB.interior.coords.x, Config.FIB.interior.coords.y, Config.FIB.interior.coords.z, false, false, false, false)
                                        SetEntityHeading(ped, Config.FIB.interior.heading)
                                        inside = true
                                        Wait(100)
                                        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
                                    end)
                                end
                            }
                        }
                    })
                end
            else
                if entranceZone then exports.ox_target:removeZone(entranceZone); entranceZone = nil end
            end
        else
            local dist = #(coords - Config.FIB.interior.coords)
            if dist > 20.0 then inside = false end
            if not exitZone then
                exitZone = exports.ox_target:addBoxZone({
                    coords = Config.FIB.interior.coords,
                    size = vec3(2.0, 2.0, 3.0),
                    rotation = Config.FIB.interior.heading,
                    debug = false,
                    options = {
                        {
                            name = 'fib_exit',
                            label = 'Leave FIB Building',
                            icon = 'fas fa-door-open',
                            distance = 2.0,
                            onSelect = function()
                                SetEntityCoords(ped, Config.FIB.entrance.coords.x, Config.FIB.entrance.coords.y, Config.FIB.entrance.coords.z, false, false, false, false)
                                SetEntityHeading(ped, Config.FIB.entrance.heading)
                                inside = false
                                if exitZone then exports.ox_target:removeZone(exitZone); exitZone = nil end
                            end
                        }
                    }
                })
            end
        end
    end
end)

--- DOOR LOCKS ---
local function setupDoorZones()
    for _, door in ipairs(Config.FIB.doors) do
        if not doorZones[door.name] then
            local zone = exports.ox_target:addBoxZone({
                coords = door.coords,
                size = vec3(2.0, 2.0, 3.0),
                rotation = 0,
                debug = false,
                options = {
                    {
                        name = 'fib_door_lock_' .. door.name,
                        label = 'Lock / Unlock Door',
                        icon = 'fas fa-lock',
                        distance = 2.0,
                        job = Config.FIB.canToggleDoors,
                        onSelect = function()
                            lib.callback('fib:server:toggleDoor', false, door.name, function(newState)
                                if newState == nil then
                                    Wrappers.Notify('Access denied.', 'error')
                                elseif newState then
                                    Wrappers.Notify(door.label .. ' LOCKED', 'warning')
                                else
                                    Wrappers.Notify(door.label .. ' UNLOCKED', 'success')
                                end
                            end)
                        end
                    },
                }
            })
            doorZones[door.name] = zone
        end
    end
end

CreateThread(function()
    setupDoorZones()
end)

RegisterNetEvent('fib:client:doorStateChanged', function(doorName, locked, label)
    if not label then
        for _, d in ipairs(Config.FIB.doors) do
            if d.name == doorName then label = d.label; break end
        end
    end
    local icon = locked and '🔴' or '🟢'
    Wrappers.Notify(icon .. ' ' .. label .. (locked and ' LOCKED' or ' UNLOCKED'), locked and 'warning' or 'success')
end)

--- ELEVATOR ---
local elevatorZone = nil

CreateThread(function()
    while true do
        Wait(2000)
        if inside then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - Config.FIB.elevator.coords)
            if dist < 5.0 then
                if not elevatorZone then
                    elevatorZone = exports.ox_target:addBoxZone({
                        coords = Config.FIB.elevator.coords,
                        size = vec3(2.0, 2.0, 3.0),
                        rotation = Config.FIB.elevator.heading,
                        debug = false,
                        options = {
                            {
                                name = 'fib_elevator',
                                label = 'Use Elevator',
                                icon = 'fas fa-elevator',
                                distance = 2.0,
                                onSelect = function()
                                    lib.callback('fib:server:getElevatorFloors', false, function(floors)
                                        if not floors or #floors == 0 then
                                            Wrappers.Notify('No accessible floors.', 'error')
                                            return
                                        end
                                        SetNuiFocus(true, true)
                                        SendNUIMessage({ action = 'openElevator', floors = floors, currentFloor = 'lobby' })
                                    end)
                                end
                            }
                        }
                    })
                end
            else
                if elevatorZone then exports.ox_target:removeZone(elevatorZone); elevatorZone = nil end
            end
        else
            if elevatorZone then exports.ox_target:removeZone(elevatorZone); elevatorZone = nil end
        end
    end
end)

RegisterNUICallback('selectFloor', function(data, cb)
    local floorName = data.floor
    lib.callback('fib:server:getFloorCoords', false, function(floorData)
        if not floorData then
            Wrappers.Notify('Access denied to this floor.', 'error')
            cb('denied')
            return
        end
        local ped = PlayerPedId()
        insideElevator = true

        RequestAmbientAudioBank('DLC_HEI_HEIST_SERIES_ELEVATOR', false)
        PlaySoundFromCoord(-1, 'elevator_door_close', Config.FIB.elevator.coords.x, Config.FIB.elevator.coords.y, Config.FIB.elevator.coords.z, 'DLC_HEI_ELEVATOR_SOUNDS', false, 100, false)

        DoScreenFadeOut(800)
        Wait(800)

        local travelTime = Config.FIB.elevator.travelTimePerFloor or 1200
        Wait(travelTime)

        SetEntityCoords(ped, floorData.coords.x, floorData.coords.y, floorData.coords.z, false, false, false, false)
        SetEntityHeading(ped, floorData.heading)

        DoScreenFadeIn(800)

        PlaySoundFromCoord(-1, 'elevator_door_open', floorData.coords.x, floorData.coords.y, floorData.coords.z, 'DLC_HEI_ELEVATOR_SOUNDS', false, 100, false)

        insideElevator = false
        SetNuiFocus(false, false)
        Wrappers.Notify('Arrived at ' .. data.label, 'success')
        cb('ok')
    end)
end)

RegisterNUICallback('closeElevator', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

--- COMPUTER TERMINALS ---
local computerZones = {}

CreateThread(function()
    while true do
        Wait(2000)
        if inside then
            for _, comp in ipairs(Config.FIB.computers) do
                if not computerZones[comp.name] then
                    local zone = exports.ox_target:addBoxZone({
                        coords = comp.coords,
                        size = vec3(1.0, 1.0, 1.5),
                        rotation = comp.heading or 0,
                        debug = false,
                        options = {
                            {
                                name = 'fib_computer_' .. comp.name,
                                label = 'Use ' .. comp.label,
                                icon = 'fas fa-terminal',
                                distance = 1.5,
                                onSelect = function()
                                    SetNuiFocus(true, true)
                                    SendNUIMessage({ action = 'openComputer', terminalName = comp.name })
                                end
                            }
                        }
                    })
                    computerZones[comp.name] = zone
                end
            end
        else
            for name, zone in pairs(computerZones) do
                exports.ox_target:removeZone(zone)
                computerZones[name] = nil
            end
        end
    end
end)

RegisterNUICallback('runCommand', function(data, cb)
    local cmd = data.command
    if cmd == 'help' then
        cb({ lines = { 'Available commands:', '  help     - Show this help', '  clear    - Clear terminal', '  date     - Show current date/time', '  status   - Show building status', '  bolos    - View active BOLOs', '  exit     - Close terminal' }})
    elseif cmd == 'clear' then
        cb({ clear = true })
    elseif cmd == 'date' then
        cb({ lines = { 'Current system time: ' .. os.date('%Y-%m-%d %H:%M:%S') }})
    elseif cmd == 'status' then
        cb({ lines = { '=== FIB BUILDING STATUS ===', 'Power:    ONLINE', 'Network:  SECURE', 'Elevator: OPERATIONAL', 'Armory:   LOCKED', 'Server:   NOMINAL', 'All systems operational.' }})
    elseif cmd == 'bolos' then
        cb({ lines = { 'BOLO terminal not yet linked to dispatch.', 'Use /bolo command in-game for now.' }})
    elseif cmd == 'exit' then
        SetNuiFocus(false, false)
        cb({ exit = true })
    else
        cb({ lines = { "Unknown command: '" .. cmd .. "'. Type 'help'." } })
    end
end)

RegisterNUICallback('closeComputer', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
