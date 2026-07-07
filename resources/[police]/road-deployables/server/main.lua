local QBCore = exports['qbx_core']:GetCoreObject()
local playerCounts = {}

lib.callback.register('road-deployables:server:canPlace', function(source, itemName)
    local p = QBCore.Functions.GetPlayer(source)
    if not p then return false end
    local cid = p.PlayerData.citizenid
    if not playerCounts[cid] then playerCounts[cid] = { cones = 0, barriers = 0 } end
    local key = itemName == 'traffic_cone' and 'cones' or 'barriers'
    local max = itemName == 'traffic_cone' and Config.RoadDeployables.maxCones or Config.RoadDeployables.maxBarriers
    return playerCounts[cid][key] < max
end)

RegisterNetEvent('road-deployables:server:confirmPlace', function(itemName, netId)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    if not playerCounts[cid] then playerCounts[cid] = { cones = 0, barriers = 0 } end
    local key = itemName == 'traffic_cone' and 'cones' or 'barriers'
    playerCounts[cid][key] = playerCounts[cid][key] + 1
end)

RegisterNetEvent('road-deployables:server:pickup', function(itemName)
    local src = source
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    if not playerCounts[cid] then return end
    local key = itemName == 'traffic_cone' and 'cones' or 'barriers'
    if playerCounts[cid][key] and playerCounts[cid][key] > 0 then
        playerCounts[cid][key] = playerCounts[cid][key] - 1
    end
    p.Functions.AddItem(itemName, 1)
end)
