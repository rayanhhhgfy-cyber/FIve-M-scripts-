local QBox = exports['qbx-core']:GetCoreObject()
local currentStop = nil
local stoppedVehicle = nil

local function isLeo()
    local job = QBox.Functions.GetPlayerData().job
    if not job then return false end
    for _, j in ipairs(Config.TrafficStop.allowedJobs) do
        if job.name == j and job.onduty then return true end
    end
    return false
end

RegisterCommand('trafficstop', function()
    if not isLeo() then Wrappers.Notify('Not on duty', 'error') return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        Wrappers.Notify('Exit your vehicle first', 'error')
        return
    end
    local targetVeh = nil
    local pCoords = GetEntityCoords(ped)
    for _, v in ipairs(GetGamePool('CVehicle')) do
        local dist = #(pCoords - GetEntityCoords(v))
        if dist < Config.TrafficStop.approachDistance then
            targetVeh = v
            break
        end
    end
    if not targetVeh then
        Wrappers.Notify('No vehicle nearby', 'error')
        return
    end
    stoppedVehicle = targetVeh
    local plate = GetVehicleNumberPlateText(targetVeh)
    TriggerServerEvent('trafficstop:initiate', plate)
end, false)
RegisterKeyMapping('trafficstop', 'Initiate Traffic Stop', 'keyboard', 'y')

RegisterNetEvent('trafficstop:started', function(plate, ownerName)
    currentStop = { plate = plate, owner = ownerName }
    Wrappers.Notify('Traffic stop: ' .. plate .. ' | ' .. (ownerName or 'Unknown'), 'info')
    local items = {}
    for _, w in ipairs(Config.TrafficStop.warningTypes) do
        table.insert(items, { title = w, onSelect = function()
            TriggerServerEvent('trafficstop:issueWarning', plate, w)
        end})
    end
    local fineItems = {}
    for fkey, fdata in pairs(Config.TrafficStop.fineCategories) do
        table.insert(fineItems, { title = fdata.label, description = '$' .. fdata.min .. ' - $' .. fdata.max, onSelect = function()
            local input = Wrappers.InputDialog({ title = 'Fine Amount (' .. fdata.label .. ')', options = {
                { type = 'number', label = 'Amount', default = tostring(fdata.min) },
                { type = 'input', label = 'Reason' }
            }})
            if input then
                TriggerServerEvent('trafficstop:issueFine', plate, fkey, tonumber(input[1]), input[2])
            end
        end})
    end
    Wrappers.ContextMenu({
        id = 'traffic_stop',
        title = 'Traffic Stop - ' .. plate,
        menuItems = {
            { title = 'Check License', onSelect = function()
                TriggerServerEvent('trafficstop:checkLicense', plate)
            end},
            { title = 'Issue Warning', menu = 'warnings' },
            { title = 'Issue Fine', menu = 'fines' },
            { title = 'End Stop', onSelect = function()
                currentStop = nil
                stoppedVehicle = nil
                Wrappers.Notify('Traffic stop ended', 'info')
            end},
        }
    })
    Wrappers.RegisterContextMenu('warnings', { title = 'Warnings', menuItems = items })
    Wrappers.RegisterContextMenu('fines', { title = 'Fines', menuItems = fineItems })
end)

RegisterNetEvent('trafficstop:result', function(msg)
    Wrappers.Notify(msg, 'info')
end)

RegisterNetEvent('trafficstop:fineIssued', function(amount, reason)
    Wrappers.Notify('Fine issued: $' .. amount .. ' | ' .. (reason or ''), 'success')
end)
