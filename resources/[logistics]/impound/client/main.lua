local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function isPolice() return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty end
local function isTow() return playerData.job and playerData.job.name == 'tow' end

Citizen.CreateThread(function()
    for _, b in ipairs(Config.Impound.Blips) do
        local blip = AddBlipForCoord(b.coords)
        SetBlipSprite(blip, b.sprite); SetBlipColour(blip, b.color); SetBlipScale(blip, b.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(b.label); EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
    if not QBox.Functions.GetPlayerData().citizenid then Citizen.Wait(100) end
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    playerData = QBox.Functions.GetPlayerData()

    for locName, loc in pairs(Config.Impound.Locations) do
        exports.ox_target:addBoxZone({
            coords = loc.coords, size = vec3(8.0, 8.0, 3.0), rotation = 0, debug = false,
            options = {{
                name = 'impound_retrieve_' .. locName:lower(),
                icon = Config.Impound.TargetOptions.retrieve.icon,
                label = Config.Impound.TargetOptions.retrieve.label, distance = Config.Impound.TargetOptions.retrieve.distance,
                onSelect = function() TriggerEvent('impound:retrieve', locName) end
            }, {
                name = 'impound_police_' .. locName:lower(),
                icon = Config.Impound.TargetOptions.policeImpound.icon,
                label = Config.Impound.TargetOptions.policeImpound.label,
                group = Config.Impound.TargetOptions.policeImpound.group, distance = Config.Impound.TargetOptions.policeImpound.distance,
                canInteract = function() return isPolice() end,
                onSelect = function() TriggerEvent('impound:policeImpound') end
            }}
        })
    end
end)

RegisterNetEvent('impound:retrieve', function(locName)
    local loc = Config.Impound.Locations[locName]
    if not loc then return end
    TriggerServerEvent('impound:server:getImpounded', locName)
end)

RegisterNetEvent('impound:client:showImpounded', function(vehicles, locName)
    local items = {}
    for _, v in ipairs(vehicles or {}) do
        table.insert(items, { title = v.vehicle .. ' (' .. v.plate .. ')', description = Locale('logistics.impound_fee', v.release_fee),
            onSelect = function() TriggerEvent('impound:payRelease', v.id, v.release_fee, v.plate, locName) end
        })
    end
    if #items == 0 then table.insert(items, { title = Locale('logistics.no_impounded'), description = '' }) end
    Wrappers.ContextMenu({ id = 'impound_list', title = Locale('logistics.impounded_vehicles'), menuItems = items })
end)

RegisterNetEvent('impound:payRelease', function(impoundId, fee, plate, locName)
    Wrappers.AlertDialog({ title = Locale('logistics.release_vehicle'), content = Locale('logistics.confirm_release', fee) }, function(confirmed)
        if confirmed then
            TriggerServerEvent('impound:server:release', impoundId, fee, plate, locName)
        end
    end)
end)

RegisterNetEvent('impound:client:released', function(spawnCoords, heading)
    Wrappers.Notify(Locale('logistics.vehicle_released'), 'success')
end)

RegisterNetEvent('impound:policeImpound', function()
    if not isPolice() then return end
    local closest, dist = QBox.Functions.GetClosestVehicle()
    if closest == 0 or dist > 5.0 then Wrappers.Notify(Locale('logistics.no_vehicle_near'), 'error') return end
    local plate = GetVehicleNumberPlateText(closest)
    local reasonItems = {}
    for _, r in ipairs(Config.Impound.ImpoundReasons) do
        table.insert(reasonItems, { title = r.label .. ' ($' .. r.fee .. ')', onSelect = function()
            TriggerServerEvent('impound:server:policeImpound', plate, r.id, r.fee, r.label)
            DeleteVehicle(closest)
        end})
    end
    Wrappers.ContextMenu({ id = 'impound_reason', title = Locale('logistics.select_reason'), menuItems = reasonItems })
end)
