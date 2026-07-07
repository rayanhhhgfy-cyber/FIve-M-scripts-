local QBox = exports['qbx-core']:GetCoreObject()
local isInsideBunker = false
local currentBunkerId = nil

function hasItem(item)
    return QBox.Functions.HasItem(item)
end

function getItemCount(item)
    return QBox.Functions.GetItemCount(item)
end

function notify(msg, type)
    Wrappers.Notify(msg, type or 'info')
end

function isCidOnDuty()
    local job = QBox.Functions.GetPlayerData().job
    if not job then return false end
    if not job.onduty then return false end
    for _, allowed in ipairs(Config.MethLab.cidJobs) do
        if job.name == allowed then return true end
    end
    return false
end

function isAdmin()
    local group = QBox.Functions.GetPlayerData().group
    if not group then return false end
    for _, g in ipairs(Config.MethLab.adminGroups) do
        if group == g then return true end
    end
    return false
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local p = QBox.Functions.GetPlayerData()
    if p and p.citizenid then
        TriggerServerEvent('methlab:playerLoaded', p.citizenid)
    end
end)

RegisterNetEvent('methlab:enterBunker', function(bunkerId)
    isInsideBunker = true
    currentBunkerId = bunkerId
    TriggerEvent('methlab:setupInteriorZones', bunkerId)
end)

RegisterNetEvent('methlab:exitBunker', function()
    isInsideBunker = false
    currentBunkerId = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isInsideBunker then
            SetNuiFocus(false, false)
            DoScreenFadeIn(500)
        end
    end
end)
