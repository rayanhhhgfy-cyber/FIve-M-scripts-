local QBox = exports['qbx-core']:GetCoreObject()

local function isAdmin()
    local group = QBox.Functions.GetPlayerData().group
    if not group then return false end
    for _, g in ipairs(Config.BunkerBuilder.adminGroups) do
        if group == g then return true end
    end
    return false
end

local function notify(msg, type)
    Wrappers.Notify(msg, type or 'info')
end

RegisterNetEvent('bunker-builder:openMenu', function()
    if not isAdmin() then return end
    local items = {
        { title = 'Add New Bunker', icon = 'fas fa-plus-circle', description = 'Create a new bunker location', onSelect = function()
            startBuilder()
        end },
        { title = 'List / Edit Bunkers', icon = 'fas fa-list', description = 'View, edit passcode, or delete bunkers', onSelect = function()
            QBox.Functions.TriggerCallback('bunker-builder:getList', function(list)
                if not list or #list == 0 then notify('No custom bunkers exist', 'info') return end
                local items = {}
                for _, b in ipairs(list) do
                    table.insert(items, { title = b.label, description = (b.passcode or '2193') .. ' | ' .. (b.interiorName or 'none') .. ' | Locked: ' .. (b.locked and 'Yes' or 'No'), onSelect = function()
                        openBunkerActions(b)
                    end })
                end
                Wrappers.ContextMenu({ id = 'bunker_list', title = 'Custom Bunkers (' .. #list .. ')', menuItems = items })
            end)
        end },
    }
    Wrappers.ContextMenu({ id = 'bunker_builder_menu', title = 'BUNKER BUILDER', menuItems = items })
end)

function openBunkerActions(bunker)
    local items = {
        { title = 'Edit Bunker', icon = 'fas fa-edit', description = 'Change label, passcode, lock state', onSelect = function()
            SetNuiFocus(true, true)
            local interiorTypes = Config.BunkerBuilder.interiorTypes or {}
            SendNUIMessage({
                action = 'openEditor',
                bunker = bunker,
                interiors = Config.BunkerBuilder.interiors,
                interiorTypes = interiorTypes,
            })
        end },
        { title = 'Teleport to Entrance', icon = 'fas fa-map-marker-alt', onSelect = function()
            SetEntityCoords(PlayerPedId(), bunker.entrance.x, bunker.entrance.y, bunker.entrance.z + 1.0)
            notify('Teleported to ' .. bunker.label)
        end },
        { title = 'Duplicate Bunker', icon = 'fas fa-copy', description = 'Create a copy with same settings', onSelect = function()
            TriggerServerEvent('bunker-builder:duplicate', bunker.id)
        end },
        { title = 'Delete Bunker', icon = 'fas fa-trash', description = 'Permanently remove this bunker', onSelect = function()
            Wrappers.ConfirmDialog({ title = 'Delete Bunker?', content = 'Are you sure you want to delete "' .. bunker.label .. '"? This cannot be undone.' }, function(confirmed)
                if confirmed then
                    TriggerServerEvent('bunker-builder:delete', bunker.id)
                end
            end)
        end },
    }
    Wrappers.ContextMenu({ id = 'bunker_actions', title = bunker.label, menuItems = items })
end

function startBuilder()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openBuilder',
        interiors = Config.BunkerBuilder.interiors,
        interiorTypes = Config.BunkerBuilder.interiorTypes,
        rockPresets = Config.BunkerBuilder.rockPresets,
    })
end

RegisterNUICallback('getPlayerCoords', function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb({ coords = { x = coords.x, y = coords.y, z = coords.z }, heading = heading })
end)

RegisterNUICallback('saveBunker', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('bunker-builder:save', {
        label = data.label,
        entranceCoords = data.entranceCoords,
        entranceHeading = data.entranceHeading,
        interiorName = data.interiorName,
        interiorCoords = data.interiorCoords,
        interiorHeading = data.interiorHeading,
        interiorType = data.interiorType or 'bunker_meth_lab',
        passcode = data.passcode or '2193',
        locked = data.locked ~= false,
        cidBypass = data.cidBypass ~= false,
        allowedJobs = data.allowedJobs,
        minRank = data.minRank,
        vehicleSpawn = data.vehicleSpawn,
        heliSpawn = data.heliSpawn,
        rocks = data.rocks,
        roofProps = data.roofProps,
    })
    cb({ success = true })
end)

RegisterNUICallback('updateBunker', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('bunker-builder:update', data.id, data.data)
    cb({ success = true })
end)

RegisterNUICallback('cancelBuilder', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNetEvent('bunker-builder:reloadTargets', function()
    notify('Bunkers reloaded', 'success')
end)
