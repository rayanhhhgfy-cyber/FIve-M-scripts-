local QBox = exports['qbx-core']:GetCoreObject()
local ox_target = exports.ox_target
local ox_lib = exports.ox_lib

local isSelling = false
local fenceRep = 0

local function getRepMultiplier()
    for i = #Config.Fencing.reputationLevels, 1, -1 do
        if fenceRep >= Config.Fencing.reputationLevels[i].rep then
            return Config.Fencing.reputationLevels[i].multiplier, Config.Fencing.reputationLevels[i].title
        end
    end
    return Config.Fencing.reputationLevels[1].multiplier, Config.Fencing.reputationLevels[1].title
end

local function getStolenItems()
    local player = QBox.Functions.GetPlayer()
    if not player then return {} end
    local items = {}
    for itemName, itemData in pairs(Config.Items) do
        local item = player.Functions.GetItemByName(itemName)
        if item and item.amount > 0 then
            items[#items + 1] = { name = itemName, label = itemData.label, amount = item.amount, price = itemData.basePrice }
        end
    end
    return items
end

local function sellItem(fence, itemName, amount)
    if isSelling then return end
    local itemConfig = Config.Items[itemName]
    if not itemConfig then return end
    local multiplier, repTitle = getRepMultiplier()
    local pricePerUnit = math.floor(itemConfig.basePrice * multiplier * (1 + math.random(-itemConfig.priceVariance, itemConfig.priceVariance)))
    local totalPrice = pricePerUnit * amount
    isSelling = true
    local success = ox_lib:progressBar({
        duration = Config.Fencing.sellTime,
        label = 'Selling ' .. itemConfig.label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mp_common', clip = 'givetake1_a' },
        prop = {}
    })
    if success then
        local skillPass = ox_lib:skillCheck(Config.SkillCheck.difficulty, Config.SkillCheck.areaSize)
        if skillPass then
            TriggerServerEvent('jewelry-fence:server:sellItem', fence, itemName, amount, totalPrice)
        else
            local lowball = math.floor(totalPrice * 0.5)
            Wrappers.Notify('warning', 'Lowballed', 'Fence offered only $' .. lowball)
            TriggerServerEvent('jewelry-fence:server:sellItem', fence, itemName, amount, lowball)
        end
        if math.random() < Config.Fencing.policeAlertChance then
            TriggerServerEvent('jewelry-fence:server:alertPolice', GetEntityCoords(PlayerPedId()))
        end
    end
    isSelling = false
end

local function openFenceMenu(fence)
    local items = getStolenItems()
    if #items == 0 then
        return Wrappers.Notify('error', 'No Items', 'You have nothing to sell')
    end
    local multiplier, repTitle = getRepMultiplier()
    local options = {}
    for _, item in ipairs(items) do
        options[#options + 1] = {
            title = item.label .. ' (x' .. item.amount .. ')',
            description = 'Est. $' .. math.floor(item.price * multiplier) .. ' - $' .. math.floor(item.price * multiplier * 1.2) .. ' each',
            onSelect = function()
                if item.amount > 1 then
                    local input = ox_lib:inputDialog('Sell ' .. item.label, {
                        { type = 'slider', label = 'Amount', min = 1, max = item.amount, default = 1 }
                    })
                    if input then
                        sellItem(fence, item.name, tonumber(input[1]))
                    end
                else
                    sellItem(fence, item.name, 1)
                end
            end
        }
    end
    options[#options + 1] = {
        title = 'Reputation: ' .. repTitle .. ' (' .. fenceRep .. ')',
        description = 'Higher rep = better prices',
        disabled = true
    }
    ox_lib:registerContext({
        id = 'fence_menu_' .. fence.label,
        title = fence.npcLabel,
        options = options
    })
    ox_lib:showContext('fence_menu_' .. fence.label)
end

local function setupFences()
    for _, fence in ipairs(Config.FenceLocations) do
        local targetId = 'fence_' .. _.label
        ox_target:removeZone(targetId)
        ox_target:addBoxZone({
            name = targetId,
            coords = fence.coords,
            size = vec3(1.5, 1.5, 1.5),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'sell_to_fence_' .. _.label,
                    label = fence.npcLabel,
                    icon = 'fas fa-gem',
                    onSelect = function()
                        openFenceMenu(fence)
                    end,
                    canInteract = function()
                        return not isSelling
                    end
                }
            }
        })
    end
end

local function createBlips()
    for _, fence in ipairs(Config.FenceLocations) do
        local blip = AddBlipForCoord(fence.coords)
        SetBlipSprite(blip, 527)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 5)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(fence.npcLabel)
        EndTextCommandSetBlipName(blip)
    end
end

Citizen.CreateThread(function()
    setupFences()
    createBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setupFences()
    TriggerServerEvent('jewelry-fence:server:getRep')
end)

RegisterNetEvent('jewelry-fence:client:setRep', function(rep)
    fenceRep = rep
end)

RegisterNetEvent('jewelry-fence:client:soldItem', function(itemLabel, price)
    Wrappers.Notify('success', 'Sold', itemLabel .. ' sold for $' .. price)
end)

RegisterNetEvent('jewelry-fence:client:policeAlert', function(coords)
    Wrappers.Notify('error', 'Police Alert', 'Fencing activity reported')
end)
