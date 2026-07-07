local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}

Citizen.CreateThread(function()
    for _, blip in ipairs(Config.CIDHQ.Blips) do
        local b = AddBlipForCoord(blip.coords)
        SetBlipSprite(b, blip.sprite)
        SetBlipColour(b, blip.color)
        SetBlipScale(b, blip.scale)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(blip.label)
        EndTextCommandSetBlipName(b)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isCID()
    return playerData.job and (playerData.job.name == 'cid' or playerData.job.name == 'police')
end

local function isOnDuty()
    return playerData.job and playerData.job.onduty
end

local function rank()
    return playerData.job and playerData.job.grade.level or 0
end

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    playerData = QBox.Functions.GetPlayerData()

    for zoneName, zone in pairs(Config.CIDHQ.Zones) do
        local opt = Config.CIDHQ.TargetOptions[zoneName]
        if opt then
            exports.ox_target:addBoxZone({
                coords = zone.coords,
                size = vec3(zone.radius * 2, zone.radius * 2, 4.0),
                rotation = 0, debug = false,
                options = {{
                    name = 'cid_' .. zoneName:lower(),
                    icon = opt.icon, label = opt.label, group = opt.group, distance = opt.distance,
                    canInteract = function()
                        if not isCID() then return false, Locale('cid.not_cid') end
                        if Config.CIDHQ.Restrictions.requireDuty and not isOnDuty() then return false, Locale('cid.not_on_duty') end
                        if opt.minRank and rank() < opt.minRank then return false, Locale('cid.rank_too_low') end
                        return true
                    end,
                    onSelect = function() TriggerEvent('cid:' .. zoneName:lower() .. ':open') end
                }}
            })
        end
    end
end)

RegisterNetEvent('cid:armory:open', function()
    if not isOnDuty() or not isCID() then Wrappers.Notify(Locale('cid.not_authorized'), 'error') return end
    local items = {}
    for _, eq in ipairs(Config.CIDHQ.Zones.Armory.equipment) do
        if rank() >= eq.rank then
            table.insert(items, { title = eq.label, onSelect = function() TriggerServerEvent('cid:server:takeEquipment', eq.item) end })
        end
    end
    Wrappers.ContextMenu({ id = 'cid_armory', title = Locale('cid.armory'), menuItems = items })
end)

RegisterNetEvent('cid:serverroom:open', function()
    if rank() < Config.CIDHQ.Restrictions.serverRank then Wrappers.Notify(Locale('cid.rank_too_low'), 'error') return end
    Wrappers.ContextMenu({ id = 'cid_server', title = Locale('cid.server_room'),
        menuItems = {
            { title = Locale('cid.access_database'), onSelect = function() TriggerEvent('cid:database:search') end },
            { title = Locale('cid.crypto_ledger'), onSelect = function() TriggerEvent('crypto:tracking:open') end },
            { title = Locale('cid.wiretap_console'), onSelect = function() TriggerEvent('wiretaps:console:open') end }
        }
    })
end)

RegisterNetEvent('cid:archive:open', function()
    TriggerServerEvent('cid:server:getCases')
end)

RegisterNetEvent('cid:client:showCases', function(cases)
    local items = {}
    for _, c in ipairs(cases or {}) do
        table.insert(items, { title = '#' .. c.id .. ' ' .. c.title, description = c.status, onSelect = function() TriggerEvent('cid:case:view', c.id) end })
    end
    table.insert(items, { title = Locale('cid.new_case'), onSelect = function() TriggerEvent('cid:case:create') end })
    Wrappers.ContextMenu({ id = 'cid_archive', title = Locale('cid.case_archive'), menuItems = items })
end)

RegisterNetEvent('cid:interrogation:open', function()
    if rank() < Config.CIDHQ.Restrictions.interrogationRank then Wrappers.Notify(Locale('cid.rank_too_low'), 'error') return end
    local closest, dist = QBox.Functions.GetClosestPlayer()
    Wrappers.ContextMenu({ id = 'cid_interrogation', title = Locale('cid.interrogation'),
        menuItems = {
            { title = Locale('cid.begin_interrogation'), onSelect = function()
                if closest ~= -1 and dist < 3.0 then TriggerServerEvent('cid:server:interrogate', GetPlayerServerId(closest)) else Wrappers.Notify(Locale('cid.no_player_near'), 'error') end
            end},
            { title = Locale('cid.view_footage'), onSelect = function() TriggerEvent('cid:surveillance:view') end }
        }
    })
end)

RegisterNetEvent('cid:surveillance:open', function()
    Wrappers.ContextMenu({ id = 'cid_surveillance', title = Locale('cid.surveillance'),
        menuItems = {
            { title = Locale('cid.live_feeds'), onSelect = function() TriggerEvent('cid:surveillance:live') end },
            { title = Locale('cid.recorded_footage'), onSelect = function() TriggerServerEvent('cid:server:getFootage') end },
            { title = Locale('cid.deploy_drone'), onSelect = function() TriggerEvent('drone:deploy') end }
        }
    })
end)

RegisterNetEvent('cid:lab:open', function()
    Wrappers.ContextMenu({ id = 'cid_lab', title = Locale('cid.forensic_lab'),
        menuItems = {
            { title = Locale('cid.analyze_dna'), onSelect = function() TriggerEvent('dna:analyze') end },
            { title = Locale('cid.analyze_digital'), onSelect = function() TriggerEvent('cid:digital:analyze') end },
            { title = Locale('cid.recover_data'), onSelect = function() TriggerEvent('cid:data:recovery') end }
        }
    })
end)

RegisterNetEvent('cid:garage:open', function()
    if not isOnDuty() then
        Wrappers.Notify('Not on duty', 'error')
        return
    end
    TriggerEvent('cid:garage:openMenu')
end)

RegisterNetEvent('cid:dutyboard:open', function()
    Wrappers.ContextMenu({ id = 'cid_duty', title = Locale('cid.duty_status'),
        menuItems = {
            { title = isOnDuty() and Locale('cid.clock_out') or Locale('cid.clock_in'), onSelect = function() TriggerServerEvent('cid:server:toggleDuty') end },
            { title = Locale('cid.view_team'), onSelect = function() TriggerServerEvent('cid:server:getTeamStatus') end }
        }
    })
end)

RegisterNetEvent('cid:case:create', function()
    Wrappers.InputDialog({ title = Locale('cid.new_case'), inputs = {
        { type = 'input', label = Locale('cid.case_title'), name = 'title', required = true },
        { type = 'textarea', label = Locale('cid.case_description'), name = 'description', required = true },
        { type = 'select', label = Locale('cid.case_type'), name = 'type', options = { { value = 'homicide', label = 'Homicide' }, { value = 'theft', label = 'Theft' }, { value = 'fraud', label = 'Fraud' }, { value = 'cyber', label = 'Cyber Crime' }, { value = 'narcotics', label = 'Narcotics' }, { value = 'other', label = 'Other' } } }
    }}, function(v)
        if v then TriggerServerEvent('cid:server:createCase', v.title, v.description, v.type) end
    end)
end)

RegisterNetEvent('cid:client:caseCreated', function(id)
    Wrappers.Notify(Locale('cid.case_created', id), 'success')
end)
