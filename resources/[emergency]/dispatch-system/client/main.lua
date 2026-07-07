local currentWaypoint = nil
local currentCallChannel = 0
local activeBlips = {}
local hudVisible = false

local function clearBlips()
    for _, blip in ipairs(activeBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    activeBlips = {}
end

-- ==================== VOICE CHANNELS ====================

RegisterNetEvent('dispatch:client:joinCallChannel', function(channel)
    if currentCallChannel > 0 then
        exports['pma-voice']:setCallChannel(0)
    end
    currentCallChannel = channel
    exports['pma-voice']:setCallChannel(channel)
end)

RegisterNetEvent('dispatch:client:leaveCallChannel', function(channel)
    if currentCallChannel == channel then
        exports['pma-voice']:setCallChannel(0)
        currentCallChannel = 0
    end
end)

-- ==================== WAYPOINT ====================

RegisterNetEvent('dispatch:client:setWaypoint', function(coords)
    currentWaypoint = coords
    SetNewWaypoint(coords.x, coords.y)
    Wrappers.Notify('Navigate to call location', 'info')
end)

-- ==================== DISPATCH PANEL (Context Menu) ====================

RegisterNetEvent('dispatch:client:openPanel', function()
    QBox.Functions.TriggerCallback('dispatch:server:getCalls', function(calls)
        if not calls or #calls == 0 then
            Wrappers.Notify('No active calls', 'info')
            return
        end
        local items = {}
        for _, call in ipairs(calls) do
            local statusIcon = call.status == 'pending' and 'NEW' or call.status == 'dispatched' and 'ASS' or 'SCN'
            table.insert(items, {
                title = statusIcon .. ' #' .. call.id .. ' ' .. (call.type or call.description or ''),
                description = call.callerName .. ' | ' .. call.status,
                icon = 'fas fa-phone-alt',
                onSelect = function()
                    local actions = {}
                    if call.status == 'pending' then
                        table.insert(actions, { title = 'Assign Self', icon = 'fas fa-user-plus', onSelect = function() TriggerServerEvent('dispatch:server:assignUnit', call.id) end })
                    end
                    if call.status == 'dispatched' then
                        table.insert(actions, { title = 'On Scene', icon = 'fas fa-map-pin', onSelect = function() TriggerServerEvent('dispatch:server:onScene', call.id) end })
                    end
                    table.insert(actions, { title = 'Set Waypoint', icon = 'fas fa-location-arrow', onSelect = function()
                        SetNewWaypoint(call.coords.x, call.coords.y)
                        Wrappers.Notify('Waypoint set', 'success')
                    end})
                    table.insert(actions, { title = 'Skip Call', icon = 'fas fa-forward', onSelect = function()
                        TriggerServerEvent('dispatch:server:skipCall', call.id)
                    end})
                    table.insert(actions, { title = 'Resolve', icon = 'fas fa-check', onSelect = function()
                        Wrappers.InputDialog({ title = 'Resolve Call #' .. call.id, options = { { type = 'input', label = 'Notes' } } }, function(v)
                            if v then TriggerServerEvent('dispatch:server:resolveCall', call.id, v[1] or '') end
                        end)
                    end})
                    Wrappers.ContextMenu({ id = 'dispatch_call_' .. call.id, title = 'Call #' .. call.id, menuItems = actions })
                end,
            })
        end
        Wrappers.ContextMenu({ id = 'dispatch_panel', title = 'Active Calls (' .. #calls .. ')', menuItems = items })
    end)
end)

-- ==================== DISPATCH HUD (NUI Overlay) ====================

RegisterNUICallback('acceptCall', function(data, cb)
    if data and data.callId then
        TriggerServerEvent('dispatch:server:assignUnit', data.callId)
    end
    cb('ok')
end)

RegisterNUICallback('skipCall', function(data, cb)
    if data and data.callId then
        TriggerServerEvent('dispatch:server:skipCall', data.callId)
    end
    cb('ok')
end)

RegisterNUICallback('sendPanic', function(_, cb)
    TriggerServerEvent('panic:server:sendAlert', 'OfficerNeedsAssistance', 'Officer Needs Assistance', true)
    SendNUIMessage({ action = 'hideHud' })
    Citizen.Wait(500)
    if hudVisible then
        SendNUIMessage({ action = 'showHud', source = GetPlayerServerId(PlayerId()) })
    end
    cb('ok')
end)

local function isDispatchJob(jobName)
    for _, j in ipairs(Config.Dispatch.dispatchJobs) do
        if jobName == j then return true end
    end
    return false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        local playerData = QBox.Functions.GetPlayerData()
        if playerData and playerData.job then
            local onDuty = playerData.job.onduty or false
            local isDisp = isDispatchJob(playerData.job.name)
            if onDuty and isDisp then
                if not hudVisible then
                    hudVisible = true
                    SetNuiFocus(false, false)
                    SendNUIMessage({ action = 'showHud', source = GetPlayerServerId(PlayerId()) })
                end
                QBox.Functions.TriggerCallback('dispatch:server:getCalls', function(calls)
                    SendNUIMessage({ action = 'updateCalls', calls = calls or {} })
                end)
                clearBlips()
                QBox.Functions.TriggerCallback('dispatch:server:getCalls', function(calls)
                    for _, call in ipairs(calls or {}) do
                        local blip = AddBlipForCoord(call.coords.x, call.coords.y, call.coords.z)
                        SetBlipSprite(blip, call.status == 'pending' and 280 or call.status == 'dispatched' and 58 or 60)
                        SetBlipColour(blip, call.status == 'pending' and 1 or call.status == 'dispatched' and 3 or 2)
                        SetBlipScale(blip, 0.8)
                        SetBlipAsShortRange(blip, true)
                        BeginTextCommandSetBlipName('STRING')
                        AddTextComponentSubstringPlayerName('Call #' .. call.id .. ': ' .. (call.type or call.description or ''))
                        EndTextCommandSetBlipName(blip)
                        table.insert(activeBlips, blip)
                    end
                end)
            else
                if hudVisible then
                    hudVisible = false
                    SendNUIMessage({ action = 'hideHud' })
                end
                clearBlips()
            end
        else
            if hudVisible then
                hudVisible = false
                SendNUIMessage({ action = 'hideHud' })
            end
            clearBlips()
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        clearBlips()
        if hudVisible then
            SendNUIMessage({ action = 'hideHud' })
            hudVisible = false
        end
        if currentCallChannel > 0 then
            exports['pma-voice']:setCallChannel(0)
            currentCallChannel = 0
        end
    end
end)
