local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function isCID() return playerData.job and (playerData.job.name == 'cid' or playerData.job.name == 'police') end
local function isOnDuty() return playerData.job and playerData.job.onduty end
local function rank() return playerData.job and playerData.job.grade.level or 0 end

Citizen.CreateThread(function()
    for i, zone in ipairs(Config.Wiretaps.ConsoleZones) do
        exports.ox_target:addBoxZone({
            coords = zone.coords, size = vec3(zone.radius * 2, zone.radius * 2, 3.0), rotation = 0, debug = false,
            options = {{
                name = 'wiretap_console_' .. i,
                icon = Config.Wiretaps.TargetOptions.console.icon,
                label = Config.Wiretaps.TargetOptions.console.label,
                group = Config.Wiretaps.TargetOptions.console.group,
                distance = Config.Wiretaps.TargetOptions.console.distance,
                canInteract = function() return isCID() and isOnDuty() and rank() >= Config.Wiretaps.MinRank end,
                onSelect = function() TriggerEvent('wiretaps:console:open') end
            }, {
                name = 'wiretap_review_' .. i,
                icon = Config.Wiretaps.TargetOptions.review.icon,
                label = Config.Wiretaps.TargetOptions.review.label,
                group = Config.Wiretaps.TargetOptions.review.group,
                distance = Config.Wiretaps.TargetOptions.review.distance,
                canInteract = function() return isCID() and isOnDuty() end,
                onSelect = function() TriggerServerEvent('wiretaps:server:getRecordings') end
            }}
        })
    end

    exports.ox_target:addGlobalPlayer({
        options = {{
            name = 'wiretap_install',
            icon = Config.Wiretaps.TargetOptions.install.icon,
            label = Config.Wiretaps.TargetOptions.install.label,
            group = Config.Wiretaps.TargetOptions.install.group,
            distance = Config.Wiretaps.TargetOptions.install.distance,
            canInteract = function()
                if Config.Wiretaps.RequireDuty and not isOnDuty() then return false end
                if rank() < Config.Wiretaps.MinRank then return false end
                return QBox.Functions.HasItem(Config.Wiretaps.KitItem)
            end,
            onSelect = function(entity)
                local pid = NetworkGetPlayerIndexFromPed(entity)
                if pid and pid ~= -1 then TriggerEvent('wiretaps:install', GetPlayerServerId(pid)) end
            end
        }}
    })
end)

RegisterNetEvent('wiretaps:install', function(targetId)
    if not isCID() or not isOnDuty() then Wrappers.Notify(Locale('cid.not_authorized'), 'error') return end
    if rank() < Config.Wiretaps.MinRank then Wrappers.Notify(Locale('cid.rank_too_low'), 'error') return end
    if not QBox.Functions.HasItem(Config.Wiretaps.KitItem) then Wrappers.Notify(Locale('cid.no_wiretap_kit'), 'error') return end
    local closest, dist = QBox.Functions.GetClosestPlayer()
    if closest == -1 or dist > 3.0 then Wrappers.Notify(Locale('cid.no_player_near'), 'error') return end
    Wrappers.ProgressBar({ label = Locale('cid.installing_tap'), duration = Config.Wiretaps.InstallTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        QBox.Functions.RemoveItem(Config.Wiretaps.KitItem, 1)
        TriggerServerEvent('wiretaps:server:install', targetId or GetPlayerServerId(closest))
    end)
end)

RegisterNetEvent('wiretaps:console:open', function()
    Wrappers.ContextMenu({ id = 'wiretap_console', title = Locale('cid.wiretap_console'),
        menuItems = {
            { title = Locale('cid.active_taps'), onSelect = function() TriggerServerEvent('wiretaps:server:getActiveTaps') end },
            { title = Locale('cid.view_transcripts'), onSelect = function() TriggerServerEvent('wiretaps:server:getTranscripts') end },
            { title = Locale('cid.locate_target'), onSelect = function() TriggerEvent('wiretaps:locate') end },
            { title = Locale('cid.request_warrant'), onSelect = function() TriggerEvent('wiretaps:warrant') end }
        }
    })
end)

RegisterNetEvent('wiretaps:locate', function()
    Wrappers.InputDialog({ title = Locale('cid.locate_target'), inputs = {
        { type = 'input', label = Locale('cid.phone_number'), name = 'number', required = true }
    }}, function(v)
        if v then TriggerServerEvent('wiretaps:server:locate', v.number) end
    end)
end)

RegisterNetEvent('wiretaps:warrant', function()
    Wrappers.InputDialog({ title = Locale('cid.wiretap_warrant'), inputs = {
        { type = 'input', label = Locale('cid.target_name'), name = 'target', required = true },
        { type = 'textarea', label = Locale('cid.cause'), name = 'cause', required = true }
    }}, function(v)
        if v then TriggerServerEvent('wiretaps:server:requestWarrant', v.target, v.cause) end
    end)
end)

RegisterNetEvent('wiretaps:client:activeTaps', function(taps)
    local items = {}
    for _, tap in ipairs(taps or {}) do
        table.insert(items, { title = tap.target_name .. ' (' .. tap.phone_number .. ')', description = Locale('cid.tap_status', tap.status), onSelect = function() TriggerEvent('wiretaps:viewTap', tap.id) end })
    end
    if #items == 0 then table.insert(items, { title = Locale('cid.no_active_taps'), description = '' }) end
    Wrappers.ContextMenu({ id = 'wiretap_list', title = Locale('cid.active_taps'), menuItems = items })
end)

RegisterNetEvent('wiretaps:client:recordings', function(recordings)
    local items = {}
    for _, rec in ipairs(recordings or {}) do
        table.insert(items, { title = rec.target_name .. ' - ' .. rec.timestamp, description = rec.duration .. 's', onSelect = function() TriggerEvent('wiretaps:playRecording', rec) end })
    end
    if #items == 0 then table.insert(items, { title = Locale('cid.no_recordings'), description = '' }) end
    Wrappers.ContextMenu({ id = 'wiretap_recordings', title = Locale('cid.recordings'), menuItems = items })
end)

RegisterNetEvent('wiretaps:client:location', function(coords)
    if coords then
        local blip = AddBlipForCoord(coords)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 5)
        SetBlipScale(blip, 1.2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Locale('cid.target_location'))
        EndTextCommandSetBlipName(blip)
        SetTimeout(30000, function() if blip then RemoveBlip(blip) end end)
        Wrappers.Notify(Locale('cid.target_located'), 'success')
    else
        Wrappers.Notify(Locale('cid.target_offline'), 'error')
    end
end)
