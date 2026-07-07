local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local inDavis = false

Citizen.CreateThread(function()
    for _, blip in ipairs(Config.DavisStation.Blips) do
        local blipHandle = AddBlipForCoord(blip.coords)
        SetBlipSprite(blipHandle, blip.sprite)
        SetBlipColour(blipHandle, blip.color)
        SetBlipScale(blipHandle, blip.scale)
        SetBlipAsShortRange(blipHandle, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(blip.label)
        EndTextCommandSetBlipName(blipHandle)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function getMyRank()
    if not playerData.job then return 0 end
    return playerData.job.grade.level or 0
end

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do
        Citizen.Wait(100)
    end
    playerData = QBox.Functions.GetPlayerData()

    for zoneName, zone in pairs(Config.DavisStation.Zones) do
        local options = Config.DavisStation.TargetOptions[zoneName]
        if options then
            exports.ox_target:addBoxZone({
                coords = zone.coords,
                size = vec3(zone.radius * 2, zone.radius * 2, 4.0),
                rotation = 0,
                debug = false,
                options = {
                    {
                        name = 'davis_' .. zoneName:lower(),
                        icon = options.icon,
                        label = options.label,
                        group = options.group,
                        distance = options.distance,
                        canInteract = function()
                            if Config.DavisStation.Restrictions.requireDuty and not isOnDuty() then
                                return false, Locale('police.not_on_duty')
                            end
                            if options.minRank and getMyRank() < options.minRank then
                                return false, Locale('police.rank_too_low')
                            end
                            return true
                        end,
                        onSelect = function()
                            TriggerEvent('davis:' .. zoneName:lower() .. ':open')
                        end
                    }
                }
            })
        end
    end
end)

RegisterNetEvent('davis:armory:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    local rank = getMyRank()
    local menuItems = {}
    for _, weapon in ipairs(Config.DavisStation.Zones.Armory.weapons) do
        if rank >= weapon.rank then
            table.insert(menuItems, {
                title = weapon.label,
                description = Locale('police.rank_required', weapon.rank),
                onSelect = function()
                    TriggerServerEvent('davis:server:removeWeapon', weapon.model)
                end
            })
        end
    end
    if #menuItems > 0 then
        table.insert(menuItems, { title = Locale('police.equipment'), menu = 'davis_equip_menu' })
        Wrappers.ContextMenu({ id = 'davis_armory_menu', title = Locale('police.armory'), menuItems = menuItems })
    end
end)

RegisterNetEvent('davis:garage:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    TriggerEvent('police:garage:openMenu')
end)

RegisterNetEvent('davis:clockin:open', function()
    Wrappers.ContextMenu({
        id = 'davis_duty_menu',
        title = Locale('police.duty_status'),
        menuItems = {
            {
                title = isOnDuty() and Locale('police.clock_out') or Locale('police.clock_in'),
                onSelect = function()
                    TriggerServerEvent('davis:server:toggleDuty')
                end
            }
        }
    })
end)

RegisterNetEvent('davis:cells:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    if getMyRank() < Config.DavisStation.Restrictions.cellsMinRank then
        Wrappers.Notify(Locale('police.rank_too_low'), 'error')
        return
    end
    Wrappers.ContextMenu({
        id = 'davis_cell_menu',
        title = Locale('police.cell_management'),
        menuItems = {
            { title = Locale('police.incarcerate'), onSelect = function() TriggerEvent('police:cells:incarcerate') end },
            { title = Locale('police.release_prisoner'), onSelect = function() TriggerEvent('police:cells:release') end },
            { title = Locale('police.cell_status'), onSelect = function() TriggerServerEvent('davis:server:getCellStatus') end }
        }
    })
end)

RegisterNetEvent('davis:evidencelocker:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    TriggerServerEvent('davis:server:getEvidenceItems')
end)

RegisterNetEvent('davis:server:getEvidenceItems', function(items)
    local menuItems = {}
    if items and #items > 0 then
        for _, item in ipairs(items) do
            table.insert(menuItems, {
                title = item.label,
                description = item.description or '',
                onSelect = function()
                    TriggerServerEvent('davis:server:retrieveEvidence', item.id)
                end
            })
        end
    end
    table.insert(menuItems, {
        title = Locale('police.store_evidence'),
        onSelect = function()
            Wrappers.InputDialog({
                title = Locale('police.evidence_item'),
                inputs = {
                    { type = 'input', label = Locale('police.evidence_label'), name = 'label', required = true },
                    { type = 'textarea', label = Locale('police.evidence_desc'), name = 'description', required = false }
                }
            }, function(values)
                if values then
                    TriggerServerEvent('davis:server:storeEvidence', values.label, values.description)
                end
            end)
        end
    })
    Wrappers.ContextMenu({ id = 'davis_evidence_menu', title = Locale('police.evidence_locker'), menuItems = menuItems })
end)

RegisterNetEvent('davis:briefing:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    Wrappers.ContextMenu({
        id = 'davis_briefing_menu',
        title = Locale('police.briefing'),
        menuItems = {
            { title = Locale('police.active_warrants'), onSelect = function() TriggerServerEvent('police:server:getActiveWarrants') end },
            { title = Locale('police.daily_briefing'), onSelect = function() TriggerServerEvent('police:server:getDailyBriefing') end }
        }
    })
end)
