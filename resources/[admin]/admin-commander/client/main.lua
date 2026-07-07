local QBox = exports['qbx-core']:GetCoreObject()
local frozen = false
local isNoclipping = false

RegisterNetEvent('admin:showMenu', function()
    local items = {
        { title = 'Player Management', icon = 'fas fa-users', onSelect = function() TriggerEvent('admin:playerManagement') end },
        { title = 'Vehicle Spawner', icon = 'fas fa-car', onSelect = function() TriggerEvent('admin:vehicleSpawner') end },
        { title = 'Item Giver', icon = 'fas fa-box', onSelect = function() TriggerEvent('admin:itemGiver') end },
        { title = 'Teleport Options', icon = 'fas fa-map-marker-alt', onSelect = function() TriggerEvent('admin:teleportOptions') end },
        { title = 'Toggle Noclip', icon = 'fas fa-ghost', onSelect = function() TriggerServerEvent('admin:toggleNoclip') end },
        { title = 'Print Coords', icon = 'fas fa-crosshairs', onSelect = function() TriggerServerEvent('admin:printCoords') end },
    }
    Wrappers.ContextMenu({ id = 'admin_menu', title = 'Admin Commander', menuItems = items })
end)

RegisterNetEvent('admin:playerManagement', function()
    TriggerServerEvent('admin:getPlayers')
end)

RegisterNetEvent('admin:showPlayers', function(players)
    local items = {}
    for _, p in ipairs(players) do
        table.insert(items, {
            title = p.name .. ' (' .. p.src .. ')',
            description = p.job .. ' | Grade ' .. p.grade,
            icon = 'fas fa-user',
            onSelect = function() TriggerEvent('admin:playerActions', p) end
        })
    end
    Wrappers.ContextMenu({ id = 'admin_players', title = 'Online Players (' .. #players .. ')', menuItems = items })
end)

RegisterNetEvent('admin:playerActions', function(player)
    local items = {
        { title = 'Kick Player', icon = 'fas fa-user-slash', onSelect = function()
            Wrappers.InputDialog({ title = 'Kick ' .. player.name, options = { { type = 'input', label = 'Reason', placeholder = 'Enter kick reason' } } }, function(v)
                if v then TriggerServerEvent('admin:kickPlayer', player.src, v[1] or 'No reason') end
            end)
        end},
        { title = 'Freeze/Unfreeze', icon = 'fas fa-snowflake', onSelect = function() TriggerServerEvent('admin:freezePlayer', player.src) end },
        { title = 'Teleport To', icon = 'fas fa-arrow-right', onSelect = function() TriggerServerEvent('admin:gotoPlayer', player.src) end },
        { title = 'Bring Player', icon = 'fas fa-arrow-left', onSelect = function() TriggerServerEvent('admin:bringPlayer', player.src) end },
        { title = 'Give Item', icon = 'fas fa-box', onSelect = function() TriggerEvent('admin:giveItemTo', player) end },
        { title = 'Give Vehicle', icon = 'fas fa-car', onSelect = function() TriggerEvent('admin:giveVehicleTo', player) end },
        { title = 'Set Job', icon = 'fas fa-briefcase', onSelect = function() TriggerEvent('admin:setJobFor', player) end },
    }
    Wrappers.ContextMenu({ id = 'admin_player_actions', title = player.name, menuItems = items })
end)

RegisterNetEvent('admin:giveItemTo', function(player)
    local quickItems = {}
    for _, item in ipairs(Config.AdminCommander.quickItems) do
        table.insert(quickItems, { title = item.label .. ' (x1)', icon = 'fas fa-box', onSelect = function()
            TriggerServerEvent('admin:giveItem', player.src, item.name, 1)
        end})
        table.insert(quickItems, { title = item.label .. ' (x5)', icon = 'fas fa-boxes', onSelect = function()
            TriggerServerEvent('admin:giveItem', player.src, item.name, 5)
        end})
        table.insert(quickItems, { title = item.label .. ' (x25)', icon = 'fas fa-cubes', onSelect = function()
            TriggerServerEvent('admin:giveItem', player.src, item.name, 25)
        end})
    end
    table.insert(quickItems, { title = 'Custom Item...', icon = 'fas fa-edit', onSelect = function()
        Wrappers.InputDialog({ title = 'Give Custom Item', options = {
            { type = 'input', label = 'Item Name', placeholder = 'e.g. weapon_pistol' },
            { type = 'number', label = 'Count', default = 1 },
        }}, function(v)
            if v and v[1] then TriggerServerEvent('admin:giveItem', player.src, v[1], tonumber(v[2]) or 1) end
        end)
    end})
    Wrappers.ContextMenu({ id = 'admin_give_item', title = 'Give Item to ' .. player.name, menuItems = quickItems })
end)

RegisterNetEvent('admin:giveVehicleTo', function(player)
    local quickVehicles = {}
    for _, v in ipairs(Config.AdminCommander.quickVehicles) do
        table.insert(quickVehicles, { title = v.label, icon = 'fas fa-car', onSelect = function() TriggerServerEvent('admin:giveVehicle', player.src, v.model) end })
    end
    table.insert(quickVehicles, { title = 'Custom Vehicle...', icon = 'fas fa-edit', onSelect = function()
        Wrappers.InputDialog({ title = 'Give Custom Vehicle', options = { { type = 'input', label = 'Model Name', placeholder = 'e.g. adder' } } }, function(v)
            if v and v[1] then TriggerServerEvent('admin:giveVehicle', player.src, v[1]) end
        end)
    end})
    Wrappers.ContextMenu({ id = 'admin_give_vehicle', title = 'Spawn Vehicle for ' .. player.name, menuItems = quickVehicles })
end)

RegisterNetEvent('admin:setJobFor', function(player)
    Wrappers.InputDialog({ title = 'Set Job for ' .. player.name, options = {
        { type = 'input', label = 'Job Name', placeholder = 'e.g. police' },
        { type = 'number', label = 'Grade', default = 0 },
    }}, function(v)
        if v and v[1] then TriggerServerEvent('admin:setJob', player.src, v[1], tonumber(v[2]) or 0) end
    end)
end)

RegisterNetEvent('admin:vehicleSpawner', function()
    local items = {}
    for _, v in ipairs(Config.AdminCommander.quickVehicles) do
        table.insert(items, { title = v.label, icon = 'fas fa-car', onSelect = function() TriggerServerEvent('admin:spawnVehicle', v.model) end })
    end
    table.insert(items, { title = 'Custom Vehicle...', icon = 'fas fa-edit', onSelect = function()
        Wrappers.InputDialog({ title = 'Spawn Vehicle', options = { { type = 'input', label = 'Model Name', placeholder = 'e.g. adder' } } }, function(v)
            if v and v[1] then TriggerServerEvent('admin:spawnVehicle', v[1]) end
        end)
    end})
    Wrappers.ContextMenu({ id = 'admin_vehicles', title = 'Vehicle Spawner', menuItems = items })
end)

RegisterNetEvent('admin:itemGiver', function()
    local items = {}
    for _, item in ipairs(Config.AdminCommander.quickItems) do
        table.insert(items, { title = item.label .. ' (x1)', icon = 'fas fa-box', onSelect = function() TriggerServerEvent('admin:giveItem', item.name, 1) end })
        table.insert(items, { title = item.label .. ' (x5)', icon = 'fas fa-boxes', onSelect = function() TriggerServerEvent('admin:giveItem', item.name, 5) end })
    end
    table.insert(items, { title = 'Custom Item...', icon = 'fas fa-edit', onSelect = function()
        Wrappers.InputDialog({ title = 'Spawn Custom Item', options = {
            { type = 'input', label = 'Item Name' },
            { type = 'number', label = 'Count', default = 1 },
        }}, function(v) if v then TriggerServerEvent('admin:giveItem', v[1], tonumber(v[2]) or 1) end end)
    end})
    Wrappers.ContextMenu({ id = 'admin_items', title = 'Item Giver', menuItems = items })
end)

RegisterNetEvent('admin:teleportOptions', function()
    Wrappers.ContextMenu({ id = 'admin_tp', title = 'Teleport Options', menuItems = {
        { title = 'Police Station', icon = 'fas fa-building', onSelect = function() SetEntityCoords(PlayerPedId(), 440.0, -980.0, 30.0) end },
        { title = 'CID HQ', icon = 'fas fa-building', onSelect = function() SetEntityCoords(PlayerPedId(), 110.0, -750.0, 45.0) end },
        { title = 'Hospital', icon = 'fas fa-hospital', onSelect = function() SetEntityCoords(PlayerPedId(), 295.0, -1440.0, 30.0) end },
        { title = 'Airport', icon = 'fas fa-plane', onSelect = function() SetEntityCoords(PlayerPedId(), -1040.0, -2750.0, 14.0) end },
        { title = 'Custom Coords...', icon = 'fas fa-edit', onSelect = function()
            Wrappers.InputDialog({ title = 'Teleport to Coords', options = {
                { type = 'number', label = 'X' }, { type = 'number', label = 'Y' }, { type = 'number', label = 'Z' },
            }}, function(v) if v then SetEntityCoords(PlayerPedId(), tonumber(v[1]), tonumber(v[2]), tonumber(v[3])) end end)
        end},
    }})
end)

RegisterNetEvent('admin:spawnVehicle', function(vehicleModel)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local model = GetHashKey(vehicleModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(10) end
    local veh = CreateVehicle(model, coords.x + 3.0, coords.y + 3.0, coords.z, heading, true, false)
    SetPedIntoVehicle(ped, veh, -1)
    SetModelAsNoLongerNeeded(model)
    Wrappers.Notify('Spawned ' .. vehicleModel, 'success')
end)

RegisterNetEvent('admin:toggleFreeze', function()
    frozen = not frozen
    SetPlayerControl(PlayerId(), not frozen, false)
    if frozen then
        FreezeEntityPosition(PlayerPedId(), true)
    else
        FreezeEntityPosition(PlayerPedId(), false)
    end
    Wrappers.Notify(frozen and 'Frozen' or 'Unfrozen', 'info')
end)

RegisterNetEvent('admin:teleportTo', function(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
end)

RegisterNetEvent('admin:printCoords', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    Wrappers.Notify('Coords: ' .. math.floor(coords.x) .. ', ' .. math.floor(coords.y) .. ', ' .. math.floor(coords.z) .. ' | Heading: ' .. math.floor(heading), 'info')
    print('^3[Admin] Coords: vector3(' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z .. ') | Heading: ' .. heading .. '^7')
end)

RegisterNetEvent('admin:noclip', function()
    isNoclipping = not isNoclipping
    if isNoclipping then
        Wrappers.Notify('Noclip ON', 'info')
    else
        Wrappers.Notify('Noclip OFF', 'info')
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isNoclipping then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            local entity = vehicle ~= 0 and vehicle or ped
            SetEntityInvincible(entity, true)
            SetEntityVisible(entity, true)
            FreezeEntityPosition(entity, false)
            SetEntityCollision(entity, false, false)

            local speed = 1.0
            if IsControlPressed(0, 21) then speed = 5.0 end -- SHIFT
            local flags = 0
            local up = IsControlPressed(0, 32)
            local down = IsControlPressed(0, 33)

            local camRot = GetGameplayCamRot(0)
            local _, _, z = table.unpack(camRot)
            local _, _, roll = table.unpack(camRot)

            local dx = -math.sin(z * math.pi / 180.0) * speed
            local dy = math.cos(z * math.pi / 180.0) * speed
            local dz = 0.0

            if up then dz = speed end
            if down then dz = -speed end

            local x, y, z = table.unpack(GetEntityCoords(entity))
            if IsControlPressed(0, 87) then -- W
                SetEntityCoords(entity, x + dx, y + dy, z + dz)
            elseif IsControlPressed(0, 65) then -- A
                SetEntityCoords(entity, x - dy, y + dx, z)
            elseif IsControlPressed(0, 83) then -- S
                SetEntityCoords(entity, x - dx, y - dy, z - dz)
            elseif IsControlPressed(0, 68) then -- D
                SetEntityCoords(entity, x + dy, y - dx, z)
            end
        end
    end
end)

--- Request player list
RegisterNetEvent('admin:requestPlayers', function()
    TriggerServerEvent('admin:getPlayers')
end)

-- Sync
RegisterNetEvent('admin:getPlayers')
AddEventHandler('admin:getPlayers', function()
    TriggerServerEvent('admin:getPlayers')
end)

RegisterNetEvent('admin:setJob')
AddEventHandler('admin:setJob', function(targetSrc, jobName, grade)
    TriggerServerEvent('admin:setJob', targetSrc, jobName, grade)
end)

--- Spectate
local isSpectating = false

RegisterNetEvent('admin:startSpectate', function(targetSrc)
    local targetPed = GetPlayerPed(targetSrc)
    if not targetPed or targetPed == 0 then
        Wrappers.Notify('Target not found', 'error')
        return
    end
    isSpectating = true
    SetEntityVisible(PlayerPedId(), false)
    SetEntityCollision(PlayerPedId(), false, false)
    FreezeEntityPosition(PlayerPedId(), true)
    NetworkSetInSpectatorMode(true, targetPed)
    Wrappers.Notify('Spectating player ' .. targetSrc, 'info')
end)

RegisterNetEvent('admin:stopSpectate', function()
    if not isSpectating then return end
    isSpectating = false
    local ped = PlayerPedId()
    NetworkSetInSpectatorMode(false, ped)
    SetEntityVisible(ped, true)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    Wrappers.Notify('Spectating ended', 'info')
end)

--- Vanish
local isVanished = false

RegisterNetEvent('admin:toggleVanish', function()
    isVanished = not isVanished
    local ped = PlayerPedId()
    SetEntityVisible(ped, not isVanished, false)
    SetEntityCollision(ped, not isVanished, not isVanished)
    if isVanished then
        NetworkSetEntityInvisibleToNetwork(ped, true)
        SetEntityLocallyInvisible(ped)
        Wrappers.Notify('Vanished (invisible)', 'success')
    else
        NetworkSetEntityInvisibleToNetwork(ped, false)
        SetEntityLocallyVisible(ped)
        Wrappers.Notify('Visible', 'info')
    end
end)

--- Admin log viewer
RegisterNetEvent('admin:showLogs', function(cid, logs)
    if not logs or #logs == 0 then
        Wrappers.Notify('No logs found for ' .. cid, 'info')
        return
    end
    local items = {}
    for _, row in ipairs(logs) do
        table.insert(items, { title = row.action .. ' | ' .. row.target, description = row.created_at })
    end
    Wrappers.ContextMenu({ id = 'admin_logs', title = 'Admin Logs: ' .. cid, menuItems = items })
end)

RegisterNetEvent('admin:showLogStats', function(stats)
    if not stats or #stats == 0 then
        Wrappers.Notify('No admin log stats', 'info')
        return
    end
    local items = {}
    for _, row in ipairs(stats) do
        table.insert(items, { title = row.admin_cid .. ' (' .. row.count .. ' actions)' })
    end
    Wrappers.ContextMenu({ id = 'admin_log_stats', title = 'Top Admin Log Activity', menuItems = items })
end)

--- Full Admin Dashboard (/admindash2)
RegisterNetEvent('admin:showDashboard', function()
    local items = {
        { title = 'Player Management', icon = 'fas fa-users', description = 'Kick, freeze, teleport, manage', onSelect = function() OpenDashPlayerMenu() end },
        { title = 'Spawn Vehicle', icon = 'fas fa-car', description = 'Spawn any vehicle', onSelect = function() OpenDashVehicleMenu() end },
        { title = 'Give Items', icon = 'fas fa-box', description = 'Give items to players', onSelect = function() OpenDashItemMenu() end },
        { title = 'Make Admin', icon = 'fas fa-crown', description = 'Promote player to admin', onSelect = function() OpenDashMakeAdminMenu() end },
        { title = 'Teleport', icon = 'fas fa-map-marker-alt', description = 'Teleport around the map', onSelect = function() OpenDashTPMenu() end },
        { title = 'Server Controls', icon = 'fas fa-server', description = 'Weather, time, announce, revive', onSelect = function() OpenDashServerMenu() end },
        { title = 'Spectate / Vanish', icon = 'fas fa-eye', description = 'Spectate players or go invisible', onSelect = function() OpenDashSpectateMenu() end },
        { title = 'Admin Logs', icon = 'fas fa-history', description = 'View admin action logs', onSelect = function() OpenDashLogsMenu() end },
        { title = 'Server Info', icon = 'fas fa-chart-bar', description = 'View server statistics', onSelect = function() OpenDashInfoMenu() end },
    }
    local playerData = QBox.Functions.GetPlayerData()
    if playerData and playerData.group == 'god' then
        table.insert(items, { title = 'Bunker Builder', icon = 'fas fa-mountain', description = 'Create/edit bunkers in-game (god only)', onSelect = function()
            TriggerEvent('bunker-builder:openMenu')
        end })
    end
    Wrappers.ContextMenu({ id = 'admin_dashboard', title = 'ADMIN DASHBOARD 2.0', menuItems = items })
end)

function OpenDashPlayerMenu()
    TriggerServerEvent('admin:getPlayers')
end

-- Override showPlayers to include Make Admin action
local origShowPlayers = admin_showPlayers or function() end
RegisterNetEvent('admin:showPlayers', function(players)
    local items = {}
    for _, p in ipairs(players) do
        table.insert(items, {
            title = p.name .. ' [' .. p.src .. ']',
            description = p.job .. ' | ' .. p.citizenid,
            icon = 'fas fa-user',
            onSelect = function() OpenDashPlayerActions(p) end
        })
    end
    Wrappers.ContextMenu({ id = 'dash_players', title = 'Players Online (' .. #players .. ')', menuItems = items })
end)

function OpenDashPlayerActions(player)
    local items = {
        { title = 'Kick', icon = 'fas fa-user-slash', onSelect = function()
            Wrappers.InputDialog({ title = 'Kick ' .. player.name, options = { { type = 'input', label = 'Reason', placeholder = 'Enter reason' } }}, function(v)
                if v then TriggerServerEvent('admin:kickPlayer', player.src, v[1] or 'No reason') end
            end)
        end },
        { title = 'Freeze / Unfreeze', icon = 'fas fa-snowflake', onSelect = function() TriggerServerEvent('admin:freezePlayer', player.src) end },
        { title = 'Teleport To', icon = 'fas fa-arrow-right', onSelect = function() TriggerServerEvent('admin:gotoPlayer', player.src) end },
        { title = 'Bring Here', icon = 'fas fa-arrow-left', onSelect = function() TriggerServerEvent('admin:bringPlayer', player.src) end },
        { title = 'Give Item', icon = 'fas fa-box', onSelect = function() TriggerEvent('admin:giveItemTo', player) end },
        { title = 'Give Vehicle', icon = 'fas fa-car', onSelect = function() TriggerEvent('admin:giveVehicleTo', player) end },
        { title = 'Set Job', icon = 'fas fa-briefcase', onSelect = function() TriggerEvent('admin:setJobFor', player) end },
        { title = 'Set Group', icon = 'fas fa-shield-alt', onSelect = function()
            Wrappers.InputDialog({ title = 'Set Group for ' .. player.name, options = {
                { type = 'select', label = 'Group', options = { { value = 'user', label = 'User' }, { value = 'admin', label = 'Admin' }, { value = 'superadmin', label = 'Super Admin' }, { value = 'god', label = 'God' } } },
            }}, function(v) if v then TriggerServerEvent('admin:setGroup', player.src, v[1]) end end)
        end },
        { title = 'Slap', icon = 'fas fa-hand', onSelect = function() TriggerServerEvent('admin:dashSlap', player.src) end },
        { title = 'Revive', icon = 'fas fa-heart', onSelect = function() TriggerServerEvent('admin:dashRevive', player.src) end },
    }
    Wrappers.ContextMenu({ id = 'dash_player_actions', title = player.name, menuItems = items })
end

function OpenDashVehicleMenu()
    local items = {}
    for _, v in ipairs(Config.AdminCommander.quickVehicles) do
        table.insert(items, { title = v.label, icon = 'fas fa-car', onSelect = function() TriggerServerEvent('admin:spawnVehicle', v.model) end })
    end
    table.insert(items, { title = 'Custom Model...', icon = 'fas fa-edit', onSelect = function()
        Wrappers.InputDialog({ title = 'Spawn Vehicle', options = { { type = 'input', label = 'Model', placeholder = 'adder' } }}, function(v)
            if v and v[1] then TriggerServerEvent('admin:spawnVehicle', v[1]) end
        end)
    end })
    Wrappers.ContextMenu({ id = 'dash_vehicles', title = 'Spawn Vehicle', menuItems = items })
end

function OpenDashItemMenu()
    local items = {}
    for _, item in ipairs(Config.AdminCommander.quickItems) do
        table.insert(items, { title = item.label .. ' x1', icon = 'fas fa-box', onSelect = function() TriggerServerEvent('admin:giveItem', item.name, 1) end })
        table.insert(items, { title = item.label .. ' x5', icon = 'fas fa-boxes', onSelect = function() TriggerServerEvent('admin:giveItem', item.name, 5) end })
        table.insert(items, { title = item.label .. ' x25', icon = 'fas fa-cubes', onSelect = function() TriggerServerEvent('admin:giveItem', item.name, 25) end })
    end
    table.insert(items, { title = 'Custom Item...', icon = 'fas fa-edit', onSelect = function()
        Wrappers.InputDialog({ title = 'Spawn Item', options = { { type = 'input', label = 'Item Name' }, { type = 'number', label = 'Count', default = 1 } }}, function(v)
            if v then TriggerServerEvent('admin:giveItem', v[1], tonumber(v[2]) or 1) end
        end)
    end })
    table.insert(items, { title = 'Give to ALL Players', icon = 'fas fa-globe', onSelect = function()
        Wrappers.InputDialog({ title = 'Give to All', options = { { type = 'input', label = 'Item Name' }, { type = 'number', label = 'Count', default = 1 } }}, function(v)
            if v then TriggerServerEvent('admin:dashGiveAllItems', v[1], tonumber(v[2]) or 1) end
        end)
    end })
    Wrappers.ContextMenu({ id = 'dash_items', title = 'Give Items', menuItems = items })
end

function OpenDashMakeAdminMenu()
    TriggerServerEvent('admin:getPlayers')
end

-- Note: Make Admin uses the same player menu but with a specific flow
-- handled by the server's admin:setAdmin event

function OpenDashTPMenu()
    local items = {}
    for _, preset in ipairs(Config.AdminCommander.teleportPresets) do
        table.insert(items, { title = preset.name, icon = 'fas fa-map-pin', onSelect = function()
            SetEntityCoords(PlayerPedId(), preset.coords.x, preset.coords.y, preset.coords.z)
            Wrappers.Notify('Teleported to ' .. preset.name, 'success')
        end })
    end
    table.insert(items, { title = 'Noclip Mode', icon = 'fas fa-ghost', onSelect = function() TriggerServerEvent('admin:toggleNoclip') end })
    table.insert(items, { title = 'Custom Coords...', icon = 'fas fa-edit', onSelect = function()
        Wrappers.InputDialog({ title = 'Teleport to Coords', options = {
            { type = 'number', label = 'X' }, { type = 'number', label = 'Y' }, { type = 'number', label = 'Z' },
        }}, function(v) if v then SetEntityCoords(PlayerPedId(), tonumber(v[1]), tonumber(v[2]), tonumber(v[3])) end end)
    end })
    table.insert(items, { title = 'Print Current Coords', icon = 'fas fa-crosshairs', onSelect = function() TriggerServerEvent('admin:printCoords') end })
    Wrappers.ContextMenu({ id = 'dash_tp', title = 'Teleport', menuItems = items })
end

function OpenDashServerMenu()
    local items = {
        { title = 'Change Weather', icon = 'fas fa-cloud-sun', onSelect = function()
            Wrappers.InputDialog({ title = 'Set Weather', options = { { type = 'select', label = 'Weather', options = {
                { value = 'EXTRASUNNY', label = 'Extra Sunny' },
                { value = 'CLEAR', label = 'Clear' },
                { value = 'CLOUDS', label = 'Clouds' },
                { value = 'SMOG', label = 'Smog' },
                { value = 'FOGGY', label = 'Foggy' },
                { value = 'OVERCAST', label = 'Overcast' },
                { value = 'RAIN', label = 'Rain' },
                { value = 'THUNDER', label = 'Thunder' },
                { value = 'CLEARING', label = 'Clearing' },
                { value = 'NEUTRAL', label = 'Neutral' },
                { value = 'SNOW', label = 'Snow' },
                { value = 'BLIZZARD', label = 'Blizzard' },
                { value = 'SNOWLIGHT', label = 'Snowlight' },
                { value = 'XMAS', label = 'Xmas' },
                { value = 'HALLOWEEN', label = 'Halloween' },
            }}}}, function(v) if v then TriggerServerEvent('admin:dashWeather', v[1]) end end)
        end },
        { title = 'Set Time', icon = 'fas fa-clock', onSelect = function()
            Wrappers.InputDialog({ title = 'Set Time', options = { { type = 'number', label = 'Hour (0-23)', default = 12 } }}, function(v)
                if v then TriggerServerEvent('admin:dashTime', tonumber(v[1])) end
            end)
        end },
        { title = 'Announcement', icon = 'fas fa-bullhorn', onSelect = function()
            Wrappers.InputDialog({ title = 'Server Announcement', options = { { type = 'input', label = 'Message', placeholder = 'Enter announcement...' } }}, function(v)
                if v and v[1] then TriggerServerEvent('admin:dashAnnounce', v[1]) end
            end)
        end },
        { title = 'Revive Self', icon = 'fas fa-heart', onSelect = function() TriggerServerEvent('admin:dashRevive') end },
        { title = 'Clear Area (100m)', icon = 'fas fa-broom', onSelect = function() TriggerServerEvent('admin:dashClearArea') end },
        { title = 'Toggle Noclip', icon = 'fas fa-ghost', onSelect = function() TriggerServerEvent('admin:toggleNoclip') end },
        { title = 'Vanish / Unvanish', icon = 'fas fa-eye-slash', onSelect = function() TriggerServerEvent('admin:vanish') end },
    }
    Wrappers.ContextMenu({ id = 'dash_server', title = 'Server Controls', menuItems = items })
end

function OpenDashSpectateMenu()
    TriggerServerEvent('admin:getPlayers')
end

-- Override the player list for spectate menu
local origShowPlayers2 = admin_showPlayers2 or function() end
RegisterNetEvent('admin:showPlayers', function(players)
    -- Already handled above for dashboard, but needs both flows
end)

-- Create a separate event for spectate player selection
RegisterNetEvent('admin:showSpectatePlayers', function(players)
    local items = {}
    for _, p in ipairs(players) do
        table.insert(items, { title = p.name .. ' [' .. p.src .. ']', icon = 'fas fa-eye', onSelect = function()
            TriggerServerEvent('admin:spectate', p.src)
        end })
    end
    table.insert(items, { title = 'Stop Spectating', icon = 'fas fa-stop', onSelect = function() TriggerServerEvent('admin:unspectate') end })
    Wrappers.ContextMenu({ id = 'dash_spectate', title = 'Spectate Player', menuItems = items })
end)

function OpenDashLogsMenu()
    local items = {
        { title = 'View Logs by CID', icon = 'fas fa-search', onSelect = function()
            Wrappers.InputDialog({ title = 'Admin Logs', options = { { type = 'input', label = 'Citizen ID' } }}, function(v)
                if v and v[1] then TriggerServerEvent('admin:adminlogs', v[1]) end
            end)
        end },
        { title = 'View Log Stats', icon = 'fas fa-chart-bar', onSelect = function() TriggerServerEvent('admin:adminlogstats') end },
    }
    Wrappers.ContextMenu({ id = 'dash_logs', title = 'Admin Logs', menuItems = items })
end

function OpenDashInfoMenu()
    QBox.Functions.TriggerCallback('admin:dashServerInfo', function(info)
        if not info then return end
        Wrappers.AlertDialog({
            title = 'Server Information',
            content = 'Players Online: ' .. info.players .. '/' .. info.maxPlayers .. '\nAdmins Online: ' .. info.admins,
            icon = 'fas fa-chart-bar',
            color = '#4CAF50',
        })
    end)
end

--- Weather and time sync
RegisterNetEvent('admin:setWeather', function(weather)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypeNow(weather)
end)

RegisterNetEvent('admin:setTime', function(hour)
    NetworkOverrideClockTime(hour, 0, 0)
end)

--- Slap player
RegisterNetEvent('admin:slapPlayer', function()
    local ped = PlayerPedId()
    ApplyForceToEntity(ped, 1, 0.0, 0.0, 20.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    SetEntityHealth(ped, GetEntityHealth(ped) - 10)
    Wrappers.Notify('You were slapped by an admin', 'error')
end)

-- Override the Make Admin player list (different from regular player mgmt)
RegisterNetEvent('admin:showPlayers', function(players)
    -- This is overwritten above to support dashboard flow
    -- The Make Admin flow uses a separate client event
end)

RegisterNetEvent('admin:showMakeAdminPlayers', function(players)
    local items = {}
    for _, p in ipairs(players) do
        table.insert(items, { title = p.name .. ' [' .. p.src .. ']', description = 'Group: ' .. (p.group or 'user'), icon = 'fas fa-crown', onSelect = function()
            Wrappers.InputDialog({ title = 'Promote ' .. p.name, options = {
                { type = 'select', label = 'Rank', options = {
                    { value = 'admin', label = 'Admin' },
                    { value = 'superadmin', label = 'Super Admin' },
                    { value = 'god', label = 'God' },
                }},
            }}, function(v) if v then TriggerServerEvent('admin:setAdmin', p.src, v[1]) end end)
        end })
    end
    Wrappers.ContextMenu({ id = 'dash_make_admin', title = 'Make Player Admin', menuItems = items })
end)
