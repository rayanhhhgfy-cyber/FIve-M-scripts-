local QBox = nil

Citizen.CreateThread(function()
    if GetResourceState('qbx_core') == 'started' then
        QBox = exports.qbx_core:GetCoreObject()
    elseif GetResourceState('qb-core') == 'started' then
        QBox = exports['qb-core']:GetCoreObject()
    end
end)

-- Fetch player across QBox, QBCore, ESX, or Standalone
local function GetPlayerServer(source)
    if GetResourceState('qbx_core') == 'started' then
        return exports.qbx_core:GetPlayer(source)
    elseif GetResourceState('qb-core') == 'started' then
        return exports['qb-core']:GetCoreObject().Functions.GetPlayer(source)
    elseif GetResourceState('es_extended') == 'started' then
        return exports['es_extended']:getSharedObject().GetPlayerFromId(source)
    else
        return nil
    end
end

-- Get player name and callsign
local function GetPlayerNameServer(src)
    local p = GetPlayerServer(src)
    if not p then return GetPlayerName(src) or 'Unknown' end

    if GetResourceState('qbx_core') == 'started' or GetResourceState('qb-core') == 'started' then
        if p.PlayerData and p.PlayerData.charinfo then
            return (p.PlayerData.charinfo.firstname or '') .. ' ' .. (p.PlayerData.charinfo.lastname or '')
        end
    elseif GetResourceState('es_extended') == 'started' then
        return p.getName() or GetPlayerName(src) or 'Unknown'
    end
    return GetPlayerName(src) or 'Unknown'
end

local function GetPlayerCallsignServer(src)
    local p = GetPlayerServer(src)
    if not p then return 'None' end

    if GetResourceState('qbx_core') == 'started' or GetResourceState('qb-core') == 'started' then
        if p.PlayerData and p.PlayerData.metadata then
            return p.PlayerData.metadata.callsign or 'None'
        end
    end
    return 'None'
end

-- ox_lib Callback to retrieve all active on-duty cops
lib.callback.register('police-suite:server:getOnlineCops', function(source)
    local activeCops = {}
    local players = GetPlayers()

    for _, pid in ipairs(players) do
        local sid = tonumber(pid)
        local player = GetPlayerServer(sid)
        if player then
            local isCop = false
            local jobName = nil

            if GetResourceState('qbx_core') == 'started' or GetResourceState('qb-core') == 'started' then
                jobName = player.PlayerData.job.name
            elseif GetResourceState('es_extended') == 'started' then
                jobName = player.getJob().name
            end

            isCop = (jobName == 'police' or jobName == 'leo' or jobName == 'sheriff')
            if isCop then
                local ped = GetPlayerPed(sid)
                local coords = GetEntityCoords(ped)

                table.insert(activeCops, {
                    id = sid,
                    name = GetPlayerNameServer(sid),
                    callsign = GetPlayerCallsignServer(sid),
                    coords = { x = coords.x, y = coords.y, z = coords.z }
                })
            end
        end
    end

    return activeCops
end)
