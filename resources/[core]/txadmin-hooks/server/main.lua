local QBCore = exports['qbx_core']:GetCoreObject()
local resourceHealth = {}
local restartTimer = nil

local function Log(message, type)
    local colors = { info = 3066993, warn = 16763904, error = 15158332, success = 3066993 }
    local webhook = Config.DiscordWebhook
    if webhook then
        PerformHttpRequest(webhook, function() end, 'POST', json.encode({
            embeds = {{
                title = 'txAdmin Hooks',
                description = message,
                color = colors[type] or colors.info,
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }}
        }), { ['Content-Type'] = 'application/json' })
    end
end

local function BroadcastWarning(minutes)
    local message = string.gsub(Config.RestartWarningMessage, '%%s', tostring(minutes))
    TriggerClientEvent('txadmin-hooks:client:notification', -1, message, 'warning', 10000)
    Log(string.format('Restart warning broadcast: %s minutes', minutes), 'warn')
end

local function ScheduleRestart()
    if Config.AutoRestartWarning then
        BroadcastWarning(Config.RestartWarningTime)
        SetTimeout(60000 * (Config.RestartWarningTime - 5), function()
            BroadcastWarning(5)
        end)
        SetTimeout(60000 * (Config.RestartWarningTime - 1), function()
            BroadcastWarning(1)
        end)
        SetTimeout(60000 * Config.RestartWarningTime, function()
            Log('Initiating scheduled server restart', 'warn')
            ExecuteCommand('say Server restarting now. Please rejoin in a moment.')
            SetTimeout(10000, function()
                os.exit(0)
            end)
        end)
    end
end

local function CheckResourceHealth()
    local allHealthy = true
    for i = 1, #Config.HealthCriticalResources do
        local resName = Config.HealthCriticalResources[i]
        local status = GetResourceState(resName)
        if status ~= 'started' then
            allHealthy = false
            resourceHealth[resName] = 'CRITICAL'
            Log(string.format('Critical resource %s is %s!', resName, status), 'error')
        else
            resourceHealth[resName] = 'OK'
        end
    end
    return allHealthy
end

local function GetServerUptime()
    return GetGameTimer()
end

local function GetPlayerCount()
    local count = 0
    for _ in pairs(GetPlayers()) do
        count = count + 1
    end
    return count
end

lib.callback.register('txadmin-hooks:server:getStatus', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return nil end
    if not IsPlayerAceAllowed(source, Config.AdminAcePermission) then
        return { error = 'No permission' }
    end
    local players = {}
    for _, id in ipairs(GetPlayers()) do
        local p = QBCore.Functions.GetPlayer(tonumber(id))
        if p then
            table.insert(players, {
                id = id,
                name = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname,
                citizenid = p.PlayerData.citizenid,
                ping = GetPlayerPing(id),
                source = id
            })
        end
    end
    return {
        uptime = GetServerUptime(),
        playerCount = GetPlayerCount(),
        maxPlayers = GetConvarInt('sv_maxclients', 48),
        resourceHealth = resourceHealth,
        players = players,
        serverTime = os.date('%H:%M:%S'),
        serverDate = os.date('%Y-%m-%d')
    }
end)

RegisterCommand(Config.Commands.restart_warning, function(source, args)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminAcePermission) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Locales['no_permission'] })
        return
    end
    local minutes = tonumber(args[1]) or Config.RestartWarningTime
    BroadcastWarning(minutes)
end, true)

RegisterCommand(Config.Commands.force_restart, function(source, args)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminAcePermission) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Locales['no_permission'] })
        return
    end
    Log('Forced restart initiated by ' .. tostring(source), 'warn')
    ExecuteCommand('say Server restarting now by admin request.')
    SetTimeout(5000, function()
        os.exit(0)
    end)
end, true)

RegisterCommand(Config.Commands.server_status, function(source)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminAcePermission) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Locales['no_permission'] })
        return
    end
    local status = CheckResourceHealth()
    local uptimeMs = GetServerUptime()
    local uptimeHours = math.floor(uptimeMs / 3600000)
    local uptimeMin = math.floor((uptimeMs % 3600000) / 60000)
    local msg = string.format('Server Uptime: %dh %dm | Players: %d/%d | Resources: %s',
        uptimeHours, uptimeMin, GetPlayerCount(), GetConvarInt('sv_maxclients', 48),
        status and 'All Healthy' or 'ISSUES DETECTED')
    if source > 0 then
        TriggerClientEvent('ox_lib:notify', source, { type = status and 'success' or 'error', description = msg })
    else
        print(msg)
    end
end, true)

RegisterCommand(Config.Commands.player_list, function(source)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminAcePermission) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Locales['no_permission'] })
        return
    end
    local lines = {}
    for _, id in ipairs(GetPlayers()) do
        local p = QBCore.Functions.GetPlayer(tonumber(id))
        if p then
            table.insert(lines, string.format('[%s] %s %s — %s',
                id,
                p.PlayerData.charinfo.firstname,
                p.PlayerData.charinfo.lastname,
                p.PlayerData.citizenid))
        end
    end
    local result = table.concat(lines, '\n')
    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, { args = { 'Player List', result } })
    else
        print(result)
    end
end, true)

RegisterCommand(Config.Commands.resource_health, function(source)
    if source > 0 and not IsPlayerAceAllowed(source, Config.AdminAcePermission) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Locales['no_permission'] })
        return
    end
    local msg = ''
    for resName, status in pairs(resourceHealth) do
        msg = msg .. string.format('%s: %s\n', resName, status)
    end
    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, { args = { 'Resource Health', msg } })
    end
end, true)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    Log(string.format('txAdmin scheduled restart: %s minutes', eventData.secondsRemaining / 60), 'info')
end)

AddEventHandler('txAdmin:events:serverShutdown', function()
    Log('Server shutting down via txAdmin', 'warn')
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    Log('txAdmin hooks initialized', 'success')
    resourceHealth = {}
    for i = 1, #Config.HealthCriticalResources do
        resourceHealth[Config.HealthCriticalResources[i]] = 'OK'
    end
    SetTimeout(Config.ResourceHealthCheckInterval, function()
        CheckResourceHealth()
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.ResourceHealthCheckInterval)
                CheckResourceHealth()
            end
        end)
    end)
end)

AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    Log('txAdmin hooks shutting down', 'warn')
end)

print('^2[txadmin-hooks] Loaded successfully. Server command & control active.^7')
