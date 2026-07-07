local QBox = exports['qbx-core']:GetCoreObject()
local playerJob = nil
local searchActive = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerJob = QBox.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerJob = job
end)

local function isAllowed()
    if not playerJob then return false end
    for _, j in ipairs(Config.PersonSearch.AllowedJobs) do
        if playerJob.name == j and playerJob.onduty then return true end
    end
    return false
end

exports.ox_target:addGlobalPlayer({
    label = 'Search Person',
    icon = 'fas fa-search',
    distance = Config.PersonSearch.SearchDistance,
    canInteract = function()
        return isAllowed() and not searchActive
    end,
    onSelect = function(data)
        local entity = data.entity
        if not entity or not IsPedAPlayer(entity) then return end
        local targetSrc = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
        if not targetSrc then return end
        searchActive = true
        TriggerServerEvent('personsearch:server:openInventory', targetSrc)
        Citizen.SetTimeout(1000, function()
            searchActive = false
        end)
    end
})

exports.ox_target:addGlobalVehicle({
    label = 'Search Vehicle',
    icon = 'fas fa-car',
    distance = Config.PersonSearch.SearchDistance,
    canInteract = function()
        return isAllowed() and not searchActive
    end,
    onSelect = function(data)
        local entity = data.entity
        if not entity then return end
        local plate = GetVehicleNumberPlateText(entity)
        if not plate or plate == '' then return end
        searchActive = true
        QBox.Functions.TriggerCallback('personsearch:server:searchVehicle', plate, function(result)
            searchActive = false
            if result then
                SendNUIMessage({ action = 'showVehicleCard', data = result })
            else
                Wrappers.Notify('Vehicle not found in DMV records', 'error')
            end
        end)
        Citizen.Wait(Config.PersonSearch.VehicleSearchDuration)
    end
})

exports.ox_target:addGlobalVehicle({
    label = 'Impound Vehicle',
    icon = 'fas fa-truck',
    distance = Config.PersonSearch.SearchDistance,
    canInteract = function()
        return isAllowed() and not searchActive
    end,
    onSelect = function(data)
        local entity = data.entity
        if not entity then return end
        local plate = GetVehicleNumberPlateText(entity)
        if not plate or plate == '' then return end
        local vehicle = QBox.Functions.GetVehicleProperties(entity)
        if not vehicle then return end
        searchActive = true
        local input = lib.inputDialog('Impound Vehicle', {
            { type = 'input', label = 'Reason for impound', placeholder = 'e.g. No insurance, stolen plates...', required = true, max = 200 },
            { type = 'number', label = 'Impound fee ($)', default = 500, min = 0, max = 10000 },
        })
        searchActive = false
        if not input or not input[1] or input[1] == '' then
            Wrappers.Notify('Impound cancelled', 'error')
            return
        end
        local reason = input[1]
        local fee = tonumber(input[2]) or 500
        Wrappers.ProgressBar({
            label = 'Impounding vehicle...',
            duration = 4000,
            useWhileDead = false,
            canCancel = false,
            anim = { dict = 'mp_arrest_paired', clip = 'cop_p2_back_to_p1' },
        }, function(cancelled)
            if cancelled then return end
            TriggerServerEvent('personsearch:server:impoundVehicle', plate, reason, fee, vehicle)
        end)
    end
})

RegisterNUICallback('closeInfoCard', function(_, cb)
    searchActive = false
    cb('ok')
end)
