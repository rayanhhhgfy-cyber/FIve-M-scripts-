local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local queryCooldown = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function isCID() return playerData.job and (playerData.job.name == 'cid' or playerData.job.name == 'police') end
local function isOnDuty() return playerData.job and playerData.job.onduty end
local function rank() return playerData.job and playerData.job.grade.level or 0 end

Citizen.CreateThread(function()
    for i, zone in ipairs(Config.AnonymityBridge.BridgeZones) do
        exports.ox_target:addBoxZone({
            coords = zone.coords, size = vec3(zone.radius * 2, zone.radius * 2, 2.0), rotation = 0, debug = false,
            options = {{
                name = 'anonymity_terminal_' .. i,
                icon = Config.AnonymityBridge.TargetOptions.terminal.icon,
                label = Config.AnonymityBridge.TargetOptions.terminal.label,
                group = Config.AnonymityBridge.TargetOptions.terminal.group,
                distance = Config.AnonymityBridge.TargetOptions.terminal.distance,
                canInteract = function() return isCID() and isOnDuty() end,
                onSelect = function() TriggerEvent('anonymity:open') end
            }, {
                name = 'anonymity_history_' .. i,
                icon = Config.AnonymityBridge.TargetOptions.history.icon,
                label = Config.AnonymityBridge.TargetOptions.history.label,
                group = Config.AnonymityBridge.TargetOptions.history.group,
                distance = Config.AnonymityBridge.TargetOptions.history.distance,
                canInteract = function() return isCID() and isOnDuty() end,
                onSelect = function() TriggerServerEvent('anonymity:server:getHistory') end
            }}
        })
    end
end)

RegisterNetEvent('anonymity:open', function()
    if not isCID() or not isOnDuty() then Wrappers.Notify(Locale('cid.not_authorized'), 'error') return end
    local queryItems = {}
    for qId, qData in pairs(Config.AnonymityBridge.QueryTypes) do
        if rank() >= qData.rank then
            table.insert(queryItems, { title = qData.label, description = Locale('cid.query_time', qData.time / 1000) .. ' | ' .. Locale('cid.rank_required', qData.rank), onSelect = function() TriggerEvent('anonymity:query', qId) end })
        end
    end
    Wrappers.ContextMenu({ id = 'anonymity_bridge', title = Locale('cid.anonymity_bridge'), menuItems = queryItems })
end)

RegisterNetEvent('anonymity:query', function(queryId)
    if queryCooldown then Wrappers.Notify(Locale('cid.query_cooldown'), 'error') return end
    local qData = Config.AnonymityBridge.QueryTypes[queryId]
    if not qData then return end
    local inputs = {}
    if queryId == 'phone' then
        inputs = { { type = 'input', label = Locale('cid.phone_number'), name = 'value', required = true } }
    elseif queryId == 'plate' then
        inputs = { { type = 'input', label = Locale('cid.plate'), name = 'value', required = true } }
    elseif queryId == 'name' then
        inputs = { { type = 'input', label = Locale('cid.name'), name = 'value', required = true } }
    elseif queryId == 'address' then
        inputs = { { type = 'input', label = Locale('cid.address_query'), name = 'value', required = true } }
    elseif queryId == 'financial' then
        inputs = { { type = 'input', label = Locale('cid.citizenid_or_name'), name = 'value', required = true } }
    elseif queryId == 'deep' then
        inputs = { { type = 'input', label = Locale('cid.citizenid_or_name'), name = 'value', required = true } }
    end
    Wrappers.InputDialog({ title = qData.label, inputs = inputs }, function(v)
        if v then
            queryCooldown = true
            Wrappers.ProgressBar({ label = Locale('cid.processing_query'), duration = qData.time, useWhileDead = false, canCancel = true }, function(cancelled)
                if cancelled then queryCooldown = false; return end
                TriggerServerEvent('anonymity:server:query', queryId, v.value)
                SetTimeout(Config.AnonymityBridge.QueryCooldown, function() queryCooldown = false end)
            end)
        end
    end)
end)

RegisterNetEvent('anonymity:client:result', function(data)
    Wrappers.Notify(data, 'info')
end)

RegisterNetEvent('anonymity:client:history', function(queries)
    local items = {}
    for _, q in ipairs(queries or {}) do
        table.insert(items, { title = q.query_type .. ': ' .. q.query_value:sub(1, 30), description = q.timestamp })
    end
    if #items == 0 then table.insert(items, { title = Locale('cid.no_queries'), description = '' }) end
    Wrappers.ContextMenu({ id = 'anonymity_history', title = Locale('cid.query_history'), menuItems = items })
end)
