local QBox = exports['qbx-core']:GetCoreObject()
local activeOperation = nil
local operationMembers = {}
local memberGPSData = {}

--- Create a new operation
RegisterNetEvent('ops:server:createOperation', function(name, objectives, threatLevel)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local timeline = json.encode({
        { timestamp = os.time(), event = 'Operation created by ' .. player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname }
    })

    MySQL.insert('INSERT INTO cid_operations (name, objectives, status, threat_level, leader_cid, timeline) VALUES (?, ?, ?, ?, ?, ?)', {
        name, objectives, 'active', threatLevel, player.PlayerData.citizenid, timeline
    }, function(opId)
        activeOperation = {
            id = opId,
            name = name,
            objectives = objectives,
            status = 'active',
            threatLevel = threatLevel,
            leaderCid = player.PlayerData.citizenid,
            members = {},
        }
        operationMembers[opId] = {}
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Operation "' .. name .. '" created (#' .. opId .. ')' })
        TriggerEvent('ops:server:logActivity', opId, player.PlayerData.citizenid, 'Created operation')
    end)
end)

--- Assign a member to the operation
RegisterNetEvent('ops:server:assignMember', function(opId, targetCid)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    -- Get operation
    MySQL.query('SELECT * FROM cid_operations WHERE id = ? AND status = "active"', { opId }, function(ops)
        if not ops or #ops == 0 then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Operation not found or not active' })
            return
        end

        local op = ops[1]
        local members = json.decode(op.members) or {}
        if #members >= Config.OperationsCenter.MaxTeamSize then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Operation team is full (' .. Config.OperationsCenter.MaxTeamSize .. ' max)' })
            return
        end

        for _, m in ipairs(members) do
            if m.citizenid == targetCid then
                TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player is already assigned' })
                return
            end
        end

        table.insert(members, { citizenid = targetCid, joinedAt = os.time() })
        MySQL.update('UPDATE cid_operations SET members = ? WHERE id = ?', { json.encode(members), opId })
        TriggerEvent('ops:server:logActivity', opId, player.PlayerData.citizenid, 'Assigned member ' .. targetCid)

        if not operationMembers[opId] then operationMembers[opId] = {} end
        operationMembers[opId][targetCid] = true

        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Member assigned to operation' })

        -- Notify the assigned player
        local players = QBox.Functions.GetPlayers()
        for _, s in ipairs(players) do
            local p = QBox.Functions.GetPlayer(s)
            if p and p.PlayerData.citizenid == targetCid then
                TriggerClientEvent('ox_lib:notify', s, { type = 'info', description = 'You have been assigned to operation #' .. opId .. ': ' .. op.name })
                break
            end
        end
    end)
end)

--- GPS position update from team members
RegisterNetEvent('ops:server:updateGPS', function(opId, coords)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    if not memberGPSData[opId] then memberGPSData[opId] = {} end
    memberGPSData[opId][player.PlayerData.citizenid] = {
        cid = player.PlayerData.citizenid,
        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        coords = coords,
        updatedAt = os.time(),
    }
end)

--- Get GPS data for the operation leader
QBox.Functions.CreateCallback('ops:server:getGPSData', function(source, cb, opId)
    cb(memberGPSData[opId] or {})
end)

--- End operation and generate report
RegisterNetEvent('ops:server:endOperation', function(opId, summary)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local reportData = {
        endedBy = player.PlayerData.citizenid,
        endedAt = os.time(),
        summary = summary,
    }

    MySQL.query('SELECT * FROM cid_operations WHERE id = ?', { opId }, function(ops)
        if ops and #ops > 0 then
            local op = ops[1]
            local timeline = json.decode(op.timeline) or {}
            table.insert(timeline, { timestamp = os.time(), event = 'Operation ended by ' .. player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ': ' .. summary })

            MySQL.update('UPDATE cid_operations SET status = "completed", timeline = ?, report = ? WHERE id = ?', {
                json.encode(timeline), json.encode(reportData), opId
            })

            if operationMembers[opId] then operationMembers[opId] = nil end
            if memberGPSData[opId] then memberGPSData[opId] = nil end

            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Operation #' .. opId .. ' ended. Report generated.' })
        end
    end)
end)

--- Get all operations
QBox.Functions.CreateCallback('ops:server:getOperations', function(source, cb, statusFilter)
    local query = 'SELECT * FROM cid_operations'
    local params = {}
    if statusFilter and statusFilter ~= 'all' then
        query = query .. ' WHERE status = ?'
        params = { statusFilter }
    end
    query = query .. ' ORDER BY created_at DESC LIMIT 50'

    MySQL.query(query, params, function(ops)
        cb(ops or {})
    end)
end)

--- Log activity
RegisterNetEvent('ops:server:logActivity', function(opId, cid, event)
    MySQL.query('SELECT timeline FROM cid_operations WHERE id = ?', { opId }, function(ops)
        if ops and #ops > 0 then
            local timeline = json.decode(ops[1].timeline) or {}
            table.insert(timeline, { timestamp = os.time(), event = event })
            MySQL.update('UPDATE cid_operations SET timeline = ? WHERE id = ?', { json.encode(timeline), opId })
        end
    end)
end)

--- GPS sync thread for team members
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.OperationsCenter.GpsSyncInterval)
        local players = QBox.Functions.GetPlayers()
        for opId, members in pairs(operationMembers) do
            for cid, _ in pairs(members) do
                for _, src in ipairs(players) do
                    local p = QBox.Functions.GetPlayer(src)
                    if p and p.PlayerData.citizenid == cid then
                        local ped = GetPlayerPed(src)
                        local coords = GetEntityCoords(ped)
                        if not memberGPSData[opId] then memberGPSData[opId] = {} end
                        memberGPSData[opId][cid] = {
                            cid = cid,
                            name = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname,
                            coords = { x = coords.x, y = coords.y, z = coords.z },
                            updatedAt = os.time(),
                        }
                        break
                    end
                end
            end
        end
    end
end)
