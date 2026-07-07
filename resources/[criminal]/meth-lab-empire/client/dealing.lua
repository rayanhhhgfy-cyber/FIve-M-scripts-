local QBox = exports['qbx-core']:GetCoreObject()
local zoneNPCs = {}
local activeNPCTables = {}
local inDeal = false
local currentZoneId = nil
local currentCustomerData = nil

Citizen.CreateThread(function()
    Citizen.Wait(3000)
    for i, zone in ipairs(Config.MethLab.dealing.zones) do
        setupDealingZone(i, zone)
    end
end)

function setupDealingZone(zoneId, zone)
    exports.ox_target:addBoxZone({
        coords = zone.coords,
        size = vec3(zone.radius, zone.radius, 4.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'deal_zone_' .. zoneId,
                icon = Config.MethLab.targetOptions.approachCustomer.icon,
                label = zone.label .. ' - ' .. Config.MethLab.targetOptions.approachCustomer.label,
                distance = Config.MethLab.targetOptions.approachCustomer.distance,
                onSelect = function()
                    approachCustomers(zoneId, zone)
                end,
            }
        }
    })
end

function approachCustomers(zoneId, zone)
    if inDeal then return end
    local methItem = findMethItem()
    if not methItem then notify('You have no meth to sell', 'error') return end
    QBox.Functions.TriggerCallback('methlab:canDealHere', function(canDeal)
        if not canDeal then notify('Too quiet, no customers around', 'error') return end
        inDeal = true
        currentZoneId = zoneId
        exports.ox_lib:progressBar({
            duration = 3000,
            label = 'Looking for customers...',
            useWhileDead = false,
            canCancel = true,
        })
        TriggerServerEvent('methlab:findCustomer', zoneId, methItem)
    end)
end

function findMethItem()
    local methItems = { 'meth_blue_sky', 'meth_crystal', 'meth_street' }
    for _, item in ipairs(methItems) do
        if hasItem(item) then
            return item
        end
    end
    return nil
end

RegisterNetEvent('methlab:customerFound', function(data)
    inDeal = false
    if data.undercover then
        notify('THAT WAS A COP! You\'ve been busted!', 'error')
        return
    end
    if data.leave then
        notify('Customer walked away. Try a different spot.', 'error')
        return
    end
    currentCustomerData = data
    local itemData = Config.MethLab.ingredients[data.methItem] or {}
    local buyerType = data.buyerType or 'regular'
    local buyerConfig = Config.MethLab.dealing.buyerTypes[buyerType] or Config.MethLab.dealing.buyerTypes.regular
    local pricePerUnit = data.pricePerUnit or 500
    local items = {
        {
            title = 'Sell ' .. (buyerConfig.maxQty or 8) .. 'x for $' .. (pricePerUnit * (buyerConfig.maxQty or 8)),
            description = 'Quick sale, no negotiation',
            onSelect = function()
                local qty = math.random(buyerConfig.minQty or 1, buyerConfig.maxQty or 8)
                TriggerServerEvent('methlab:sellMeth', currentZoneId, data.methItem, qty, pricePerUnit, false)
            end
        }
    }
    if Config.MethLab.dealing.negotiation.enabled then
        table.insert(items, {
            title = 'Negotiate Price',
            description = 'Try for a better deal (risk: they walk away)',
            onSelect = function()
                local success = exports.ox_lib:skillCheck({ 'easy', 'medium' }, 50)
                if success then
                    local bonus = pricePerUnit * Config.MethLab.dealing.negotiation.priceBonus
                    notify('Negotiated +$' .. math.floor(bonus) .. ' per unit!', 'success')
                    local qty = math.random(buyerConfig.minQty or 1, buyerConfig.maxQty or 8)
                    TriggerServerEvent('methlab:sellMeth', currentZoneId, data.methItem, qty, pricePerUnit + bonus, true)
                else
                    notify('Customer walked away', 'error')
                end
            end
        })
    end
    Wrappers.ContextMenu({ id = 'customer_menu', title = 'Customer (' .. (string.upper(buyerType)) .. ')', menuItems = items })
end)

RegisterNetEvent('methlab:saleResult', function(data)
    inDeal = false
    if data.success then
        notify('Sold ' .. data.qty .. 'x for $' .. data.total, 'success')
    elseif data.busted then
        notify('BUSTED! Fined $' .. (data.fine or 0), 'error')
    elseif data.robbed then
        notify('Got robbed! Lost some product', 'error')
    end
end)
