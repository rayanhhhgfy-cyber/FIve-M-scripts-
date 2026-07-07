local testDriveActive = false
local testDriveTimer = 0
local testDriveVehicle = nil
local purchasingVehicle = false

Citizen.CreateThread(function()
    for _, showroom in ipairs(Config.VehicleShop.Showrooms) do
        local blip = AddBlipForCoord(showroom.coords.x, showroom.coords.y, showroom.coords.z)
        SetBlipSprite(blip, 225)
        SetBlipScale(blip, 0.9)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(showroom.name)
        EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
    for _, showroom in ipairs(Config.VehicleShop.Showrooms) do
        exports.ox_target:addBoxZone({
            coords = showroom.coords,
            size = vec3(3.0, 3.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    icon = Config.VehicleShop.TargetOptions.browse.icon,
                    label = showroom.name .. ' - ' .. Config.VehicleShop.TargetOptions.browse.label,
                    distance = Config.VehicleShop.TargetOptions.browse.distance,
                    canInteract = function()
                        return not testDriveActive and not purchasingVehicle
                    end,
                    onSelect = function()
                        OpenVehicleMenu(showroom)
                    end
                },
                {
                    icon = Config.VehicleShop.TargetOptions.spawn.icon,
                    label = Config.VehicleShop.TargetOptions.spawn.label,
                    distance = Config.VehicleShop.TargetOptions.spawn.distance,
                    canInteract = function()
                        return not testDriveActive
                    end,
                    onSelect = function()
                        local ped = PlayerPedId()
                        local vehicle = GetClosestVehicle(showroom.spawn, 10.0, 0, 70)
                        if vehicle ~= 0 then return end
                        local veh = GetVehiclePedIsIn(ped, false)
                        if veh ~= 0 then
                            Wrappers.Notify(Locale('vehicle_shop', 'exit_vehicle') or 'Please exit the vehicle first', 'error')
                            return
                        end
                        if not showroom.lastPurchased then
                            Wrappers.Notify(Locale('vehicle_shop', 'no_vehicle') or 'No vehicle purchased yet', 'info')
                            return
                        end
                        SpawnPurchasedVehicle(showroom.lastPurchased, showroom)
                    end
                }
            }
        })
    end
end)

local function OpenVehicleMenu(showroom)
    local options = {}
    for _, veh in ipairs(showroom.vehicles) do
        local label = string.format('%s - $%s (%s)', veh.label, FormatNumber(veh.price), veh.category)
        table.insert(options, {
            title = label,
            description = Locale('vehicle_shop', 'select_to_view') or 'Select to view options',
            icon = 'car',
            onSelect = function()
                ShowVehicleOptions(veh, showroom)
            end
        })
    end

    lib.registerContext({
        id = 'vehicle_shop_' .. showroom.name,
        title = showroom.name,
        options = options
    })
    lib.showContext('vehicle_shop_' .. showroom.name)
end

local function ShowVehicleOptions(veh, showroom)
    local options = {
        {
            title = Locale('vehicle_shop', 'purchase') or 'Purchase',
            description = string.format('$%s', FormatNumber(veh.price)),
            icon = 'dollar-sign',
            onSelect = function()
                PurchaseVehicle(veh, showroom)
            end
        },
        {
            title = Locale('vehicle_shop', 'test_drive') or 'Test Drive',
            description = string.format('%d seconds', Config.VehicleShop.TestDriveDuration),
            icon = 'clock',
            onSelect = function()
                StartTestDrive(veh, showroom)
            end
        }
    }

    if Config.VehicleShop.FinanceOptions.enabled then
        table.insert(options, {
            title = Locale('vehicle_shop', 'finance') or 'Finance',
            description = string.format('%d%% down, %d months', Config.VehicleShop.FinanceOptions.minDownPayment, Config.VehicleShop.FinanceOptions.maxPayments),
            icon = 'credit-card',
            onSelect = function()
                FinanceVehicle(veh, showroom)
            end
        })
    end

    lib.registerContext({
        id = 'vehicle_options_' .. veh.model,
        title = veh.label,
        options = options
    })
    lib.showContext('vehicle_options_' .. veh.model)
end

local function PurchaseVehicle(veh, showroom)
    purchasingVehicle = true
    local colorInput = lib.inputDialog(Locale('vehicle_shop', 'select_color') or 'Select Color', {
        { type = 'select', label = Locale('vehicle_shop', 'color') or 'Color', options = Config.VehicleShop.Colors, default = 1 }
    })

    if not colorInput then
        purchasingVehicle = false
        return
    end

    local colorIndex = colorInput[1]
    local success = lib.alertDialog({
        header = Locale('vehicle_shop', 'confirm_purchase') or 'Confirm Purchase',
        content = string.format(Locale('vehicle_shop', 'purchase_confirm_text') or 'Buy %s for $%s?', veh.label, FormatNumber(veh.price)),
        centered = true,
        cancel = true
    })

    if success == 'confirm' then
        TriggerServerEvent('vehicle_shop:purchase', veh.model, veh.label, veh.price, colorIndex, showroom.name, false)
        showroom.lastPurchased = veh
    end

    purchasingVehicle = false
end

local function FinanceVehicle(veh, showroom)
    purchasingVehicle = true
    local downPayment = math.ceil(veh.price * (Config.VehicleShop.FinanceOptions.minDownPayment / 100))
    local monthlyPayment = math.ceil((veh.price - downPayment) * (1 + Config.VehicleShop.FinanceOptions.interestRate) / Config.VehicleShop.FinanceOptions.maxPayments)

    local financeInput = lib.inputDialog(Locale('vehicle_shop', 'finance_details') or 'Finance Details', {
        { type = 'select', label = Locale('vehicle_shop', 'color') or 'Color', options = Config.VehicleShop.Colors, default = 1 }
    })

    if not financeInput then
        purchasingVehicle = false
        return
    end

    local colorIndex = financeInput[1]
    local success = lib.alertDialog({
        header = Locale('vehicle_shop', 'confirm_finance') or 'Confirm Finance',
        content = string.format(Locale('vehicle_shop', 'finance_confirm_text') or '%s\nDown: $%s\nMonthly: $%s x %d', veh.label, FormatNumber(downPayment), FormatNumber(monthlyPayment), Config.VehicleShop.FinanceOptions.maxPayments),
        centered = true,
        cancel = true
    })

    if success == 'confirm' then
        TriggerServerEvent('vehicle_shop:purchase', veh.model, veh.label, veh.price, colorIndex, showroom.name, true)
        showroom.lastPurchased = veh
    end

    purchasingVehicle = false
end

local function StartTestDrive(veh, showroom)
    if testDriveActive then
        Wrappers.Notify(Locale('vehicle_shop', 'test_drive_active') or 'Already on a test drive', 'error')
        return
    end

    testDriveActive = true
    local ped = PlayerPedId()
    local coords = showroom.spawn

    local vehicle = CreateVehicle(GetHashKey(veh.model), coords.x, coords.y, coords.z, showroom.heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, 'TESTDRIVE')
    SetPedIntoVehicle(ped, vehicle, -1)
    SetVehicleFuelLevel(vehicle, 100.0)
    testDriveVehicle = vehicle
    testDriveTimer = Config.VehicleShop.TestDriveDuration

    Wrappers.Notify(Locale('vehicle_shop', 'test_drive_start', testDriveTimer) or string.format('Test drive started - %d seconds', testDriveTimer), 'success')

    Citizen.CreateThread(function()
        while testDriveTimer > 0 and DoesEntityExist(testDriveVehicle) do
            Citizen.Wait(1000)
            testDriveTimer = testDriveTimer - 1
            if testDriveTimer <= 30 and testDriveTimer > 0 and testDriveTimer % 10 == 0 then
                Wrappers.Notify(Locale('vehicle_shop', 'test_drive_time_left', testDriveTimer) or string.format('%d seconds remaining', testDriveTimer), 'warning')
            end
        end

        if DoesEntityExist(testDriveVehicle) then
            local ped = PlayerPedId()
            if GetVehiclePedIsIn(ped, false) == testDriveVehicle then
                TaskLeaveVehicle(ped, testDriveVehicle, 0)
            end
            Citizen.Wait(3000)
            DeleteVehicle(testDriveVehicle)
        end

        testDriveActive = false
        testDriveVehicle = nil
        Wrappers.Notify(Locale('vehicle_shop', 'test_drive_ended') or 'Test drive ended', 'info')
    end)
end

local function SpawnPurchasedVehicle(veh, showroom)
    local ped = PlayerPedId()
    local coords = showroom.spawn
    local vehicle = CreateVehicle(GetHashKey(veh.model), coords.x, coords.y, coords.z, showroom.heading, true, false)
    if vehicle == 0 then
        Wrappers.Notify(Locale('vehicle_shop', 'spawn_failed') or 'Failed to spawn vehicle', 'error')
        return
    end
    SetVehicleOnGroundProperly(vehicle)
    SetPedIntoVehicle(ped, vehicle, -1)
    Wrappers.Notify(Locale('vehicle_shop', 'vehicle_spawned', veh.label) or veh.label .. ' spawned!', 'success')
end

local function FormatNumber(amount)
    local formatted = tostring(amount)
    local k = 3
    while #formatted > k do
        formatted = formatted:sub(1, #formatted - k) .. ',' .. formatted:sub(#formatted - k + 1)
        k = k + 4
    end
    return formatted
end

RegisterNetEvent('vehicle_shop:purchaseSuccess', function(model, label)
    Wrappers.Notify(Locale('vehicle_shop', 'purchased', label) or label .. ' purchased!', 'success')
end)

RegisterNetEvent('vehicle_shop:purchaseFailed', function(reason)
    Wrappers.Notify(reason or Locale('vehicle_shop', 'purchase_failed') or 'Purchase failed', 'error')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if DoesEntityExist(testDriveVehicle) then
            DeleteVehicle(testDriveVehicle)
        end
    end
end)
