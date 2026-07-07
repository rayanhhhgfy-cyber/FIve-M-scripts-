local QBCore = exports['qbx_core']:GetCoreObject()
local PlayerData = {}
local hasOpened = false
local previewVehicles = {}
local testDriveData = {}

local function openDealership(locationData)
    if hasOpened then return end
    hasOpened = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openDealership',
        data = {
            dealerName = locationData.name,
            categories = locationData.categories,
            categoryLabels = Config.Dealership.Categories,
            vehicles = Config.DealershipVehicles,
            playerMoney = PlayerData.money or 0,
            financingRate = Config.Dealership.Financing.InterestRate
        }
    })
end

local function closeDealership()
    if not hasOpened then return end
    hasOpened = false
    SetNuiFocus(false, false)
end

local function spawnPreviewVehicle(model)
    if #previewVehicles >= Config.Dealership.MaxSpawnedPreviews then
        local old = table.remove(previewVehicles, 1)
        if DoesEntityExist(old) then DeleteEntity(old) end
    end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local offset = Config.Dealership.PreviewSpawnOffset
    local spawnCoords = vec3(coords.x + offset.x, coords.y + offset.y, coords.z + offset.z)
    local heading = GetEntityHeading(ped)
    QBCore.Functions.SpawnVehicle(model, function(vehicle)
        if not vehicle or not DoesEntityExist(vehicle) then
            Wrappers.Notify('Dealership', 'Failed to preview vehicle', 'error')
            return
        end
        SetVehicleOnGroundProperly(vehicle)
        SetEntityInvincible(vehicle, true)
        FreezeEntityPosition(vehicle, true)
        SetVehicleNumberPlateText(vehicle, 'PREVIEW')
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        SetNetworkIdExistsOnAllMachines(netId, true)
        table.insert(previewVehicles, vehicle)
        Wrappers.Notify('Dealership', 'Vehicle previewed - walk around to inspect', 'success')
    end, spawnCoords, heading, true, false)
end

local function clearAllPreviews()
    for _, veh in ipairs(previewVehicles) do
        if DoesEntityExist(veh) then DeleteEntity(veh) end
    end
    previewVehicles = {}
end

local function startTestDrive(model)
    if testDriveData.active then
        Wrappers.Notify('Dealership', 'You already have a test drive active', 'error')
        return
    end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    QBCore.Functions.SpawnVehicle(model, function(vehicle)
        if not vehicle or not DoesEntityExist(vehicle) then
            Wrappers.Notify('Dealership', 'Failed to spawn test drive vehicle', 'error')
            return
        end
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleNumberPlateText(vehicle, 'TESTDRIVE')
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        SetNetworkIdExistsOnAllMachines(netId, true)
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        testDriveData = {
            active = true,
            vehicle = vehicle,
            timer = Config.Dealership.TestDriveDuration,
            model = model
        }
        testDriveData.timerId = Citizen.CreateThread(function()
            while testDriveData.active and testDriveData.timer > 0 do
                Citizen.Wait(1000)
                testDriveData.timer = testDriveData.timer - 1
                if testDriveData.timer <= 30 and testDriveData.timer > 0 and (testDriveData.timer % 10 == 0 or testDriveData.timer <= 10) then
                    Wrappers.Notify('Test Drive', 'Time remaining: ' .. testDriveData.timer .. 's', 'warning')
                end
            end
            if testDriveData.active then
                endTestDrive(true)
            end
        end)
    end, coords, heading, true, false)
end

local function endTestDrive(notify)
    if not testDriveData.active then return end
    testDriveData.active = false
    if testDriveData.timerId then
        testDriveData.timerId = nil
    end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, testDriveData.vehicle, 16)
    end
    Citizen.SetTimeout(2000, function()
        if testDriveData.vehicle and DoesEntityExist(testDriveData.vehicle) then
            DeleteEntity(testDriveData.vehicle)
        end
        testDriveData.vehicle = nil
        testDriveData.timer = 0
    end)
    if notify then
        Wrappers.Notify('Test Drive', 'Test drive ended. Vehicle returned.', 'info')
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    PlayerData.money = PlayerData.money or {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

RegisterNetEvent('vehicle:client:updateMoney', function(money)
    PlayerData.money = money
end)

Citizen.CreateThread(function()
    for _, location in ipairs(Config.Dealership.Locations) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, location.blip.sprite)
        SetBlipColour(blip, location.blip.color)
        SetBlipScale(blip, location.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(location.blip.label)
        EndTextCommandSetBlipName(blip)

        exports['ox_target']:addBoxZone({
            coords = location.coords,
            size = vec3(4.0, 4.0, 3.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'dealership_open_' .. location.name,
                    label = 'Browse Vehicles',
                    icon = 'fas fa-car',
                    onSelect = function()
                        if location.isOpen and not location.isOpen() then
                            Wrappers.Notify('Dealership', 'This dealership is currently closed', 'error')
                            return
                        end
                        openDealership(location)
                    end
                }
            }
        })

        local pedModel = GetHashKey(location.ped)
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do Citizen.Wait(0) end
        local ped = CreatePed(0, pedModel, location.pedCoords.x, location.pedCoords.y, location.pedCoords.z - 1.0, location.pedCoords.w, false, true)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
    end
end)

RegisterNUICallback('dealershipBuy', function(data, cb)
    local result = lib.callback.await('dealership:server:buyVehicle', false, data.category, data.model, data.paymentType)
    if result.success then
        Wrappers.Notify('Dealership', 'Vehicle purchased! Plate: ' .. result.plate, 'success')
        if result.financeInfo then
            Wrappers.Notify('Financing', 'Weekly payment: $' .. result.financeInfo.weekly .. ' for ' .. result.financeInfo.terms .. ' weeks', 'info')
        end
    else
        Wrappers.Notify('Dealership', result.error or 'Purchase failed', 'error')
    end
    cb(result)
end)

RegisterNUICallback('dealershipPreview', function(data, cb)
    spawnPreviewVehicle(data.model)
    cb({ success = true })
end)

RegisterNUICallback('dealershipTestDrive', function(data, cb)
    startTestDrive(data.model)
    cb({ success = true })
end)

RegisterNUICallback('dealershipSell', function(data, cb)
    local result = lib.callback.await('dealership:server:sellVehicle', false, data.plate)
    if result.success then
        Wrappers.Notify('Dealership', 'Vehicle sold for $' .. result.payout, 'success')
    else
        Wrappers.Notify('Dealership', result.error or 'Sale failed', 'error')
    end
    cb(result)
end)

RegisterNUICallback('dealershipGetPlayerVehicles', function(_, cb)
    local vehicles = lib.callback.await('dealership:server:getPlayerVehicles', false)
    cb(vehicles or {})
end)

RegisterNUICallback('dealershipClose', function(_, cb)
    closeDealership()
    clearAllPreviews()
    cb({})
end)

RegisterNUICallback('dealershipGetMoney', function(_, cb)
    PlayerData = QBCore.Functions.GetPlayerData()
    cb({ money = PlayerData.money })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    closeDealership()
    clearAllPreviews()
    endTestDrive(false)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if PlayerData and PlayerData.money then
            SendNUIMessage({ action = 'updateMoney', money = PlayerData.money })
        end
    end
end)
