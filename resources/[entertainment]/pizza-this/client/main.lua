local QBCore = exports['qbx-core']:GetCoreObject()
local activeDelivery = false
local currentZone = nil
local currentBlip = nil
local deliveryStart = 0

local function clearBlip()
    if currentBlip then
        RemoveBlip(currentBlip)
        currentBlip = nil
    end
end

local function setDeliveryBlip(zone)
    clearBlip()
    currentBlip = AddBlipForCoord(zone.x, zone.y, zone.z)
    SetBlipSprite(currentBlip, 1)
    SetBlipColour(currentBlip, 5)
    SetBlipRoute(currentBlip, true)
    SetBlipRouteColour(currentBlip, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Locale('pizza_this.deliver_pizza'))
    EndTextCommandSetBlipName(currentBlip)
end

local function isNearCoord(c1, c2, dist)
    dist = dist or 15.0
    return #(vector3(c1.x, c1.y, c1.z) - vector3(c2.x, c2.y, c2.z)) <= dist
end

RegisterNetEvent('pizza:startDeliveryClient', function(zone, netId, plate)
    deliveryStart = GetGameTimer()
    currentZone = zone
    activeDelivery = true
    setDeliveryBlip(zone)
end)

RegisterNetEvent('pizza:newDeliveryClient', function(zone)
    deliveryStart = GetGameTimer()
    currentZone = zone
    setDeliveryBlip(zone)
end)

CreateThread(function()
    exports.ox_target:addBoxZone({
        coords = Config.PizzaJob.shopCoords,
        size = vec3(2.0, 2.0, 2.0),
        rotation = 0,
        options = {
            {
                name = 'pizza_start_delivery',
                label = Locale('pizza_this.start_delivery'),
                icon = 'fas fa-pizza-slice',
                onSelect = function()
                    if activeDelivery then
                        TriggerServerEvent('pizza:cancelDelivery')
                        activeDelivery = false
                        clearBlip()
                        currentZone = nil
                        Wrappers.Notify(Locale('pizza_this.delivery_cancelled'), 'error')
                        return
                    end
                    TriggerServerEvent('pizza:startDelivery')
                end,
            },
        },
    })

    while true do
        Wait(500)
        if activeDelivery and currentZone then
            local ped = PlayerPedId()
            local pedPos = GetEntityCoords(ped)
            local elapsed = (GetGameTimer() - deliveryStart) / 1000
            local remaining = Config.PizzaJob.timeLimitPerDelivery - math.floor(elapsed)

            Wrappers.TextUI(Locale('pizza_this.time_remaining') .. ': ' .. math.max(remaining, 0) .. 's')

            if isNearCoord(pedPos, currentZone) then
                Wrappers.HideTextUI()
                Wrappers.ProgressBar({
                    duration = 3000,
                    label = Locale('pizza_this.deliver_pizza'),
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                }, function(cancelled)
                    if cancelled then
                        Wrappers.Notify(Locale('pizza_this.delivery_cancelled'), 'error')
                        return
                    end
                    activeDelivery = false
                    clearBlip()
                    currentZone = nil
                    TriggerServerEvent('pizza:completeDelivery')
                end)
                Wait(5000)
            end

            if remaining <= 0 then
                Wrappers.HideTextUI()
                Wrappers.Notify(Locale('pizza_this.late_delivery'), 'error')
                TriggerServerEvent('pizza:completeDelivery')
                activeDelivery = false
                clearBlip()
                currentZone = nil
                Wait(2000)
            end
        end
    end
end)
