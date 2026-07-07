local QBox = exports['qbx-core']:GetCoreObject()
local playerJob = nil
local opsOpen = false
local currentGPSThread = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerJob = QBox.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerJob = job
end)

local function isAllowed()
    if not playerJob then return false end
    for _, j in ipairs(Config.OperationsCenter.AllowedJobs) do
        if playerJob.name == j and playerJob.onduty then return true end
    end
    return false
end

--- Briefing room terminal
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isAllowed() then
            local br = Config.OperationsCenter.BriefingRoom
            if not exports.ox_target:isExistingZone('ops_briefing_terminal') then
                exports.ox_target:addBoxZone({
                    coords = br.coords,
                    size = vector3(2.0, 2.0, 2.0),
                    rotation = 0,
                    debug = false,
                    options = {
                        {
                            label = br.label,
                            icon = br.icon,
                            distance = 2.0,
                            canInteract = function() return isAllowed() end,
                            onSelect = function()
                                openOperationsMenu()
                            end,
                        }
                    }
                })
            end
        end
    end
end)

local function openOperationsMenu()
    local menuItems = {
        {
            title = 'New Operation',
            description = 'Create a new CID field operation',
            icon = 'fas fa-plus-circle',
            onSelect = function()
                createNewOperation()
            end,
        },
        {
            title = 'Active Operations',
            description = 'View and manage active operations',
            icon = 'fas fa-list',
            onSelect = function()
                showOperationList('active')
            end,
        },
        {
            title = 'Archived Operations',
            description = 'View completed operation reports',
            icon = 'fas fa-archive',
            onSelect = function()
                showOperationList('completed')
            end,
        },
    }
    lib.registerContext({
        id = 'ops_main_menu',
        title = 'CID Operations Center',
        options = menuItems,
    })
    lib.showContext('ops_main_menu')
end

local function createNewOperation()
    local input = lib.inputDialog('New Operation', {
        { type = 'input', label = 'Operation Name', placeholder = 'e.g. Stingray-7', required = true, max = 200 },
        { type = 'textarea', label = 'Objectives', placeholder = 'Primary objectives...\nSecondary objectives...', required = true },
        { type = 'select', label = 'Threat Level', options = {
            { label = 'Low', value = 'low' },
            { label = 'Medium', value = 'medium' },
            { label = 'High', value = 'high' },
            { label = 'Critical', value = 'critical' },
        }, default = 'medium' },
    })
    if not input or not input[1] or input[1] == '' then return end
    TriggerServerEvent('ops:server:createOperation', input[1], input[2], input[3] or 'medium')
end

local function showOperationList(status)
    QBox.Functions.TriggerCallback('ops:server:getOperations', function(ops)
        if not ops or #ops == 0 then
            Wrappers.Notify('No operations found', 'info')
            return
        end
        local options = {}
        for _, op in ipairs(ops) do
            local threatColor = Config.OperationsCenter.ThreatLevels[op.threat_level] or { color = '#ffffff', label = op.threat_level }
            table.insert(options, {
                title = op.name .. ' (#' .. op.id .. ')',
                description = 'Status: ' .. op.status .. ' | Threat: ' .. threatColor.label,
                icon = 'fas fa-shield-alt',
                iconColor = threatColor.color,
                onSelect = function()
                    openOperationDetail(op)
                end,
            })
        end
        lib.registerContext({
            id = 'ops_list_menu',
            title = status:gsub('^%l', string.upper) .. ' Operations',
            options = options,
        })
        lib.showContext('ops_list_menu')
    end, status)
end

local function openOperationDetail(op)
    local options = {
        {
            title = 'Open Tactical Dashboard',
            description = 'Full-screen operations interface',
            icon = 'fas fa-map-marked-alt',
            onSelect = function()
                opsOpen = true
                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'openDashboard', data = op })
                startGPSThread(op.id)
            end,
        },
        {
            title = 'Assign Members',
            description = 'Add CID officers to this operation',
            icon = 'fas fa-user-plus',
            onSelect = function()
                assignMembers(op)
            end,
        },
    }
    if op.status == 'active' or op.status == 'paused' then
        table.insert(options, {
            title = 'End Operation',
            description = 'Complete and generate debriefing report',
            icon = 'fas fa-flag-checkered',
            onSelect = function()
                endOperation(op)
            end,
        })
    end
    lib.registerContext({
        id = 'ops_detail_menu',
        title = op.name,
        options = options,
    })
    lib.showContext('ops_detail_menu')
end

local function assignMembers(op)
    QBox.Functions.TriggerCallback('admin:getPlayers', function(players)
        local options = {}
        for _, p in ipairs(players) do
            table.insert(options, {
                title = p.name,
                description = 'CID: ' .. p.citizenid .. ' | Job: ' .. p.job,
                icon = 'fas fa-user',
                onSelect = function()
                    TriggerServerEvent('ops:server:assignMember', op.id, p.citizenid)
                end,
            })
        end
        lib.registerContext({
            id = 'ops_assign_menu',
            title = 'Assign Members - ' .. op.name,
            options = options,
        })
        lib.showContext('ops_assign_menu')
    end)
end

local function endOperation(op)
    local input = lib.inputDialog('End Operation', {
        { type = 'textarea', label = 'Debriefing Summary', placeholder = 'Operation outcome, arrests, evidence collected...', required = true },
    })
    if not input or not input[1] then return end
    TriggerServerEvent('ops:server:endOperation', op.id, input[1])
end

local function startGPSThread(opId)
    if currentGPSThread then return end
    currentGPSThread = Citizen.CreateThread(function()
        while opsOpen do
            Citizen.Wait(Config.OperationsCenter.GpsSyncInterval)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            TriggerServerEvent('ops:server:updateGPS', opId, { x = coords.x, y = coords.y, z = coords.z })
            QBox.Functions.TriggerCallback('ops:server:getGPSData', function(gpsData)
                if gpsData and opsOpen then
                    SendNUIMessage({ action = 'updateGPS', data = gpsData })
                end
            end, opId)
        end
        currentGPSThread = nil
    end)
end

--- NUI callbacks
RegisterNUICallback('closeDashboard', function(_, cb)
    opsOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('addTimelineEvent', function(data, cb)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    TriggerServerEvent('ops:server:logActivity', data.opId, player.PlayerData.citizenid, data.event)
    cb('ok')
end)

--- Cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if opsOpen then
            SetNuiFocus(false, false)
        end
    end
end)
