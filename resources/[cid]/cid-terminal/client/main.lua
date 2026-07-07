local QBox = exports['qbx-core']:GetCoreObject()
local terminalOpen = false
local terminalZones = {}

CreateThread(function()
    while true do
        Wait(2000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, loc in ipairs(Config.CIDTerminal.terminalLocations) do
            local dist = #(coords - loc.coords)
            if dist < 5.0 then
                if not terminalZones[loc.name] then
                    terminalZones[loc.name] = exports.ox_target:addBoxZone({
                        coords = loc.coords,
                        size = vec3(1.5, 1.5, 2.0),
                        rotation = loc.heading or 0,
                        debug = false,
                        options = {
                            {
                                name = 'cids_terminal_' .. loc.name,
                                label = 'Open ' .. loc.label,
                                icon = 'fas fa-desktop',
                                distance = 1.5,
                                onSelect = function()
                                    lib.callback('cid-terminal:server:checkAccess', false, function(hasAccess)
                                        if not hasAccess then
                                            Wrappers.Notify('Access denied. CID or Police only.', 'error')
                                            return
                                        end
                                        terminalOpen = true
                                        SetNuiFocus(true, true)
                                        SendNUIMessage({ action = 'openTerminal', terminalName = loc.name })
                                    end)
                                end
                            }
                        }
                    })
                end
            else
                if terminalZones[loc.name] then
                    exports.ox_target:removeZone(terminalZones[loc.name])
                    terminalZones[loc.name] = nil
                end
            end
        end
    end
end)

local function callServer(method, data, cb)
    lib.callback('cid-terminal:server:' .. method, false, data or {}, function(result)
        if cb then cb(result) end
    end)
end

local function nuiCallback(method, data, cb)
    callServer(method, data, function(result)
        if cb then cb(result) end
    end)
end

--- NUI CALLBACKS ---
RegisterNUICallback('nuiDashboard', function(_, cb) nuiCallback('getDashboard', _, cb) end)
RegisterNUICallback('nuiGetStaff', function(_, cb) nuiCallback('getStaff', _, cb) end)
RegisterNUICallback('nuiHireStaff', function(d, cb) nuiCallback('hireStaff', d, cb) end)
RegisterNUICallback('nuiFireStaff', function(d, cb) nuiCallback('fireStaff', d, cb) end)
RegisterNUICallback('nuiSetStaffGrade', function(d, cb) nuiCallback('setStaffGrade', d, cb) end)
RegisterNUICallback('nuiGetGrades', function(_, cb) nuiCallback('getGrades', _, cb) end)
RegisterNUICallback('nuiUpdateGrade', function(d, cb) nuiCallback('updateGrade', d, cb) end)
RegisterNUICallback('nuiTriggerPayroll', function(_, cb) nuiCallback('triggerPayroll', _, cb) end)
RegisterNUICallback('nuiGetPayrollHistory', function(_, cb) nuiCallback('getPayrollHistory', _, cb) end)
RegisterNUICallback('nuiGetArmory', function(_, cb) nuiCallback('getArmoryItems', _, cb) end)
RegisterNUICallback('nuiAddArmoryItem', function(d, cb) nuiCallback('addArmoryItem', d, cb) end)
RegisterNUICallback('nuiUpdateArmoryItem', function(d, cb) nuiCallback('updateArmoryItem', d, cb) end)
RegisterNUICallback('nuiRemoveArmoryItem', function(d, cb) nuiCallback('removeArmoryItem', d, cb) end)
RegisterNUICallback('nuiGetCases', function(_, cb) nuiCallback('getCases', _, cb) end)
RegisterNUICallback('nuiCreateCase', function(d, cb) nuiCallback('createCase', d, cb) end)
RegisterNUICallback('nuiCloseCase', function(d, cb) nuiCallback('closeCase', d, cb) end)
RegisterNUICallback('nuiGetWarrants', function(_, cb) nuiCallback('getWarrants', _, cb) end)
RegisterNUICallback('nuiIssueWarrant', function(d, cb) nuiCallback('issueWarrant', d, cb) end)
RegisterNUICallback('nuiCloseWarrant', function(d, cb) nuiCallback('closeWarrant', d, cb) end)
RegisterNUICallback('nuiGetBOLOs', function(_, cb) nuiCallback('getBOLOs', _, cb) end)
RegisterNUICallback('nuiCreateBOLO', function(d, cb) nuiCallback('createBOLO', d, cb) end)
RegisterNUICallback('nuiRemoveBOLO', function(d, cb) nuiCallback('removeBOLO', d, cb) end)
RegisterNUICallback('nuiSearchPerson', function(d, cb) nuiCallback('searchPerson', d, cb) end)
RegisterNUICallback('nuiGetPersonNotes', function(d, cb) nuiCallback('getPersonNotes', d, cb) end)
RegisterNUICallback('nuiAddPersonNote', function(d, cb) nuiCallback('addPersonNote', d, cb) end)
RegisterNUICallback('nuiGetVehicleSpawns', function(_, cb) nuiCallback('getVehicleSpawns', _, cb) end)
RegisterNUICallback('nuiGetAuditLog', function(_, cb) nuiCallback('getAuditLog', _, cb) end)
RegisterNUICallback('nuiSendAnnouncement', function(d, cb) nuiCallback('sendAnnouncement', d, cb) end)

RegisterNUICallback('closeTerminal', function(_, cb)
    terminalOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)
