local QBox = exports['qbx-core']:GetCoreObject()
local nearNPC = nil
local inDeal = false
local currentZone = nil

local function hasDrug()
    for drug, _ in pairs(Config.DrugDealing.Drugs) do
        if QBox.Functions.HasItem(drug) then return drug end
    end
    return nil
end

local function getRepLevel()
    local rep = QBox.Functions.GetMetaData('drug_rep') or 0
    local level = 0
    for i, v in ipairs(Config.DrugDealing.Reputation.levels) do
        if rep >= v then level = i - 1 end
    end
    return level, rep
end

Citizen.CreateThread(function()
    for i, zone in ipairs(Config.DrugDealing.DealZones) do
        exports.ox_target:addBoxZone({
            coords = zone.coords, size = vec3(zone.radius, zone.radius, 4.0), rotation = 0, debug = false,
            options = {{
                name = 'deal_zone_' .. i,
                icon = Config.DrugDealing.TargetOptions.approach.icon,
                label = zone.label .. ' - ' .. Config.DrugDealing.TargetOptions.approach.label,
                distance = Config.DrugDealing.TargetOptions.approach.distance,
                onSelect = function() TriggerEvent('deal:approach', i) end
            }}
        })
    end
end)

RegisterNetEvent('deal:approach', function(zoneId)
    if inDeal then return end
    local drug = hasDrug()
    if not drug then Wrappers.Notify('You have no drugs to sell', 'error') return end
    local police = QBox.Functions.GetPlayersFromJob('police')
    if #police < Config.DrugDealing.MinPolice then Wrappers.Notify('Too quiet, no customers around', 'error') return end
    currentZone = zoneId
    inDeal = true
    Wrappers.ProgressBar({ label = 'Approaching customer...', duration = 4000, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then inDeal = false return end
        TriggerServerEvent('deal:server:approach', zoneId, drug)
    end)
end)

RegisterNetEvent('deal:client:customerFound', function(data)
    local drugs = {}
    for k, v in pairs(Config.DrugDealing.Drugs) do
        if QBox.Functions.HasItem(k) then
            local level, rep = getRepLevel()
            local perks = Config.DrugDealing.Reputation.perks[level] or Config.DrugDealing.Reputation.perks[0]
            local price = math.floor((math.random(v.minPrice, v.maxPrice) * perks.priceModifier))
            table.insert(drugs, { title = v.label .. ' ($' .. price .. ')', description = 'Rep: ' .. rep, onSelect = function()
                Wrappers.InputDialog({ title = 'Sell ' .. v.label, inputs = {
                    { type = 'number', label = 'Quantity', name = 'qty', default = 1, min = 1, max = perks.maxDealSize }
                }}, function(result)
                    if result and result.qty then
                        TriggerServerEvent('deal:server:sell', k, tonumber(result.qty), price)
                    end
                end)
            end})
        end
    end
    if #drugs == 0 then Wrappers.Notify('No drugs to sell', 'error') inDeal = false return end
    Wrappers.ContextMenu({ id = 'drug_sell', title = 'Sell to Customer', menuItems = drugs })
end)

RegisterNetEvent('deal:client:result', function(data)
    inDeal = false
    if data.success then
        Wrappers.Notify('Sold ' .. data.qty .. 'x for $' .. data.total, 'success')
    elseif data.busted then
        Wrappers.Notify('Police bust! You were fined $' .. data.fine, 'error')
    elseif data.robbed then
        Wrappers.Notify('You got robbed! Lost some product', 'error')
    end
end)

RegisterNetEvent('deal:client:policeAlert', function(street)
    Wrappers.Notify('Suspicious activity near ' .. street, 'warning')
end)
