local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local isInPrison = false
local remainingTime = 0
local isLaboring = false
local laborTimer = 0

Citizen.CreateThread(function()
    local blip = AddBlipForCoord(Config.Prison.PrisonBlip.coords)
    SetBlipSprite(blip, Config.Prison.PrisonBlip.sprite)
    SetBlipColour(blip, Config.Prison.PrisonBlip.color)
    SetBlipScale(blip, Config.Prison.PrisonBlip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.Prison.PrisonBlip.label)
    EndTextCommandSetBlipName(blip)
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

RegisterNetEvent('police:client:incarcerate', function(cellNumber, time, charges)
    isInPrison = true
    remainingTime = time * 60
    Wrappers.Notify(Locale('police.incarcerated', time, charges), 'error')
    TriggerEvent('prison:client:teleport')
end)

RegisterNetEvent('prison:client:teleport', function()
    local ped = PlayerPedId()
    SetEntityCoords(ped, Config.Prison.SpawnPoint.coords)
    SetEntityHeading(ped, Config.Prison.SpawnPoint.heading)
    QBox.Functions.ClearInventory()
    Wrappers.Notify(Locale('police.prison_orientation'), 'info')
end)

RegisterNetEvent('police:client:releasePrisoner', function()
    isInPrison = false
    remainingTime = 0
    isLaboring = false
    laborTimer = 0
    local ped = PlayerPedId()
    SetEntityCoords(ped, Config.Prison.ReleasePoint.coords)
    SetEntityHeading(ped, Config.Prison.ReleasePoint.heading)
    Wrappers.Notify(Locale('police.released_from_prison'), 'success')
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isInPrison and remainingTime > 0 then
            remainingTime = remainingTime - 1
            if isLaboring then
                laborTimer = laborTimer + 1
                local reduction = laborTimer / Config.Prison.BaseTimeReductionRatio
                remainingTime = remainingTime - 1
                if laborTimer >= Config.Prison.BreakTime then
                    isLaboring = false
                    laborTimer = 0
                    Wrappers.Notify(Locale('police.labor_break'), 'info')
                end
            end
            if remainingTime <= 0 then
                TriggerServerEvent('prison:server:sentenceServed')
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isInPrison then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - Config.Prison.Location)
            if dist > 200.0 then
                SetEntityCoords(ped, Config.Prison.SpawnPoint.coords)
                Wrappers.Notify(Locale('police.escape_attempt'), 'error')
                TriggerServerEvent('prison:server:escapeAttempt')
            end
            local minutes = math.floor(remainingTime / 60)
            local seconds = remainingTime % 60
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(Locale('police.prison_time_remaining', string.format('%02d:%02d', minutes, seconds)))
            DrawText(0.5, 0.05)
            if isLaboring then
                SetTextFont(4)
                SetTextScale(0.4, 0.4)
                SetTextColour(255, 200, 0, 255)
                SetTextCentre(true)
                SetTextEntry('STRING')
                AddTextComponentString(Locale('police.laboring'))
                DrawText(0.5, 0.1)
            end
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            if coords.z < 40.0 then
                SetEntityCoords(ped, Config.Prison.SpawnPoint.coords)
            end
        else
            Citizen.Wait(1000)
        end
        Citizen.Wait(0)
    end
end)

for i, laborPoint in ipairs(Config.Prison.LaborPoints) do
    exports.ox_target:addBoxZone({
        coords = laborPoint.coords,
        size = vec3(3.0, 3.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'prison_labor_' .. i,
                icon = Config.Prison.TargetOptions.labor.icon,
                label = Config.Prison.TargetOptions.labor.label,
                distance = Config.Prison.TargetOptions.labor.distance,
                canInteract = function()
                    return isInPrison and not isLaboring
                end,
                onSelect = function()
                    TriggerEvent('prison:startLabor', i)
                end
            }
        }
    })
end

exports.ox_target:addBoxZone({
    coords = Config.Prison.ReleasePoint,
    size = vec3(5.0, 5.0, 3.0),
    rotation = 0,
    debug = false,
    options = {
        {
            name = 'prison_release',
            icon = Config.Prison.TargetOptions.release.icon,
            label = Config.Prison.TargetOptions.release.label,
            group = Config.Prison.TargetOptions.release.group,
            distance = Config.Prison.TargetOptions.release.distance,
            canInteract = function()
                return isOnDuty() and playerData.job.grade.level >= Config.Prison.GuardMinRank
            end,
            onSelect = function()
                local closestPlayer, closestDist = QBox.Functions.GetClosestPlayer()
                if closestPlayer ~= -1 and closestDist < 3.0 then
                    TriggerServerEvent('prison:server:guardRelease', GetPlayerServerId(closestPlayer))
                else
                    Wrappers.Notify(Locale('police.no_player_near'), 'error')
                end
            end
        }
    }
})

RegisterNetEvent('prison:startLabor', function(laborId)
    local labor = Config.Prison.LaborPoints[laborId]
    if not labor then return end
    isLaboring = true
    laborTimer = 0
    Wrappers.Notify(Locale('police.labor_started', labor.label), 'info')
end)
