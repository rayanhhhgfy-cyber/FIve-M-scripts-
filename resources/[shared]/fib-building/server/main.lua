local QBox = exports['qbx-core']:GetCoreObject()
local doorStates = {}

local function loadDoorStates()
    local rows = MySQL.query.await('SELECT door_name, is_locked FROM fib_doors')
    if not rows then return end
    for _, row in ipairs(rows) do
        doorStates[row.door_name] = row.is_locked == 1
    end
end

local function saveDoorState(doorName, locked)
    MySQL.insert('INSERT INTO fib_doors (door_name, is_locked) VALUES (?, ?) ON DUPLICATE KEY UPDATE is_locked = ?', { doorName, locked and 1 or 0, locked and 1 or 0 })
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        loadDoorStates()
    end
end)

MySQL.ready(function()
    loadDoorStates()
end)

local function hasAccess(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    local job = p.PlayerData.job.name
    for _, a in ipairs(Config.FIB.allowedJobs) do
        if job == a then return true end
    end
    return false
end

local function canToggleDoor(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    local job = p.PlayerData.job.name
    for _, j in ipairs(Config.FIB.canToggleDoors) do
        if job == j then return true end
    end
    return false
end

local function hasRankAccess(src, minRank)
    if minRank == 0 then return true end
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    if p.PlayerData.job.grade.level >= minRank then return true end
    for _, rj in ipairs(Config.FIB.restrictedJobs) do
        if p.PlayerData.job.name == rj then return true end
    end
    return false
end

lib.callback.register('fib:server:canEnter', function(source)
    if not hasAccess(source) then return false end
    local p = QBox.Functions.GetPlayer(source)
    if not p then return false end
    for _, door in ipairs(Config.FIB.doors) do
        local locked = doorStates[door.name]
        if locked == nil then locked = door.defaultLocked end
        if locked then
            local job = p.PlayerData.job.name
            local allowed = false
            for _, j in ipairs(Config.FIB.canToggleDoors) do
                if job == j then allowed = true; break end
            end
            if not allowed then
                TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Access denied. FIB doors are locked.' })
                return false
            end
        end
    end
    return true
end)

lib.callback.register('fib:server:canAccessFloor', function(source, floorName)
    for _, f in ipairs(Config.FIB.elevator.floors) do
        if f.name == floorName then return hasRankAccess(source, f.minRank) end
    end
    return false
end)

lib.callback.register('fib:server:getElevatorFloors', function(source)
    local a = {}
    for _, f in ipairs(Config.FIB.elevator.floors) do
        if hasRankAccess(source, f.minRank) then
            table.insert(a, { name = f.name, label = f.label, minRank = f.minRank })
        end
    end
    return a
end)

lib.callback.register('fib:server:getFloorCoords', function(source, floorName)
    for _, f in ipairs(Config.FIB.elevator.floors) do
        if f.name == floorName and hasRankAccess(source, f.minRank) then
            return { coords = f.coords, heading = f.heading }
        end
    end
    return nil
end)

lib.callback.register('fib:server:toggleDoor', function(source, doorName)
    if not canToggleDoor(source) then return nil end
    local current = doorStates[doorName]
    if current == nil then
        for _, d in ipairs(Config.FIB.doors) do
            if d.name == doorName then current = d.defaultLocked; break end
        end
    end
    local newState = not current
    doorStates[doorName] = newState
    saveDoorState(doorName, newState)
    local label = doorName
    for _, d in ipairs(Config.FIB.doors) do
        if d.name == doorName then label = d.label; break end
    end
    TriggerClientEvent('fib:client:doorStateChanged', -1, doorName, newState, label)
    return newState
end)

lib.callback.register('fib:server:getDoorStates', function(source)
    local states = {}
    for _, d in ipairs(Config.FIB.doors) do
        local s = doorStates[d.name]
        if s == nil then s = d.defaultLocked end
        states[d.name] = { locked = s, label = d.label }
    end
    return states
end)
