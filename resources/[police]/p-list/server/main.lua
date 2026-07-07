local QBox = exports['qbx-core']:GetCoreObject()
local activeOfficers = {}

local function getRadioFreq(src)
    local success, freq = pcall(function()
        return exports['pma-voice']:getPlayerRadio(src)
    end)
    if success and freq then return freq end
    return nil
end

local function getCallChannel(src)
    local success, channel = pcall(function()
        return exports['pma-voice']:getCallChannel(src)
    end)
    if success and channel and channel > 0 then return tostring(channel) end
    return nil
end

local function buildOfficerList()
    local list = {}
    for src, data in pairs(activeOfficers) do
        if data.onduty then
            table.insert(list, {
                src = src,
                name = data.name,
                job = data.job,
                grade = data.grade,
                gradeName = data.gradeName,
                radio = data.radio,
                callChannel = data.callChannel,
                status = data.status,
            })
        end
    end
    table.sort(list, function(a, b)
        if a.job ~= b.job then return a.job < b.job end
        return (a.name or '') < (b.name or '')
    end)
    return list
end

local function updateOfficer(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then
        activeOfficers[src] = nil
        return
    end
    local job = player.PlayerData.job
    if not job or job.type ~= 'leo' then
        activeOfficers[src] = nil
        return
    end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    activeOfficers[src] = {
        name = (player.PlayerData.charinfo.firstname or '') .. ' ' .. (player.PlayerData.charinfo.lastname or ''),
        job = job.name,
        grade = job.grade.level,
        gradeName = job.grade.name or 'Officer',
        onduty = job.onduty or false,
        radio = getRadioFreq(src),
        callChannel = getCallChannel(src),
        status = 'Active',
        coords = { x = coords.x, y = coords.y, z = coords.z },
        citizenid = player.PlayerData.citizenid,
    }
end

RegisterNetEvent('p-list:server:requestList', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local job = player.PlayerData.job
    if not job or job.type ~= 'leo' then return end
    TriggerClientEvent('p-list:client:receiveList', src, buildOfficerList())
end)

local syncTimer = 0
CreateThread(function()
    while true do
        Wait(1000)
        syncTimer = syncTimer + 1
        local players = QBox.Functions.GetPlayers()
        for _, src in ipairs(players) do
            updateOfficer(src)
        end
        for src, _ in pairs(activeOfficers) do
            local found = false
            for _, s in ipairs(players) do
                if s == src then found = true end
            end
            if not found then activeOfficers[src] = nil end
        end
        if syncTimer >= 3 then
            syncTimer = 0
            local list = buildOfficerList()
            for _, src in ipairs(players) do
                local player = QBox.Functions.GetPlayer(src)
                if player and player.PlayerData.job and player.PlayerData.job.type == 'leo' then
                    TriggerClientEvent('p-list:client:receiveList', src, list)
                end
            end
        end
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    activeOfficers[src] = nil
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    activeOfficers[src] = nil
end)

QBox.Commands.Add(Config.PList.command, 'Open Personnel List', {}, false, function(source)
    TriggerClientEvent('p-list:client:open', source)
end)
