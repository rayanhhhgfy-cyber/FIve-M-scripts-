local QBox = exports['qbx-core']:GetCoreObject()
local ox_target = exports.ox_target
local ox_lib = exports.ox_lib

local isCrafting = false

local function hasParts(recipe)
    local player = QBox.Functions.GetPlayer()
    if not player then return false end
    for part, count in pairs(recipe.parts) do
        local item = player.Functions.GetItemByName(part)
        if not item or item.amount < count then
            return false
        end
    end
    return true
end

local function removeParts(recipe)
    for part, count in pairs(recipe.parts) do
        QBox:RemoveItem(part, count)
    end
end

local function getSkillLevel()
    local player = QBox.Functions.GetPlayer()
    if not player then return 1 end
    local exp = player.PlayerData.metadata.weaponcraft_exp or 0
    for i = #Config.SkillLevels, 1, -1 do
        if exp >= Config.SkillLevels[i].exp then
            return i
        end
    end
    return 1
end

local function addExp(amount)
    local exp = QBox.Functions.GetPlayer().PlayerData.metadata.weaponcraft_exp or 0
    exp = exp + amount
    QBox:SetMetaData('weaponcraft_exp', exp)
end

local function startCrafting(weapon, recipe)
    if isCrafting then return end
    if getSkillLevel() < recipe.skillLevel then
        return Wrappers.Notify('error', 'Skill too low', 'You need ' .. Config.SkillLevels[recipe.skillLevel].label .. ' rank')
    end
    if not hasParts(recipe) then
        return Wrappers.Notify('error', 'Missing Parts', 'You do not have the required weapon parts')
    end
    isCrafting = true
    local success = ox_lib:progressBar({
        duration = Config.Crafting.duration,
        label = 'Crafting ' .. recipe.label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
        prop = {}
    })
    if success then
        local skillPass = ox_lib:skillCheck(Config.Crafting.skillCheck.difficulty, Config.Crafting.skillCheck.areaSize)
        if skillPass then
            removeParts(recipe)
            QBox:AddItem(weapon, 1, nil, { ammo = recipe.ammoCount, ammoType = recipe.ammo })
            addExp(Config.ExpPerCraft)
            Wrappers.Notify('success', 'Crafted', 'Successfully crafted ' .. recipe.label)
            TriggerServerEvent('weapon-manufacturing:server:crafted', weapon)
            if math.random() < Config.Police.alertChance then
                TriggerServerEvent('weapon-manufacturing:server:alertPolice', GetEntityCoords(PlayerPedId()))
            end
        else
            Wrappers.Notify('error', 'Failed', 'You messed up the crafting')
        end
    end
    isCrafting = false
end

local function openCraftingMenu()
    local options = {}
    for weapon, recipe in pairs(Config.Recipes) do
        options[#options + 1] = {
            title = recipe.label,
            description = 'Skill: ' .. Config.SkillLevels[recipe.skillLevel].label,
            onSelect = function()
                startCrafting(weapon, recipe)
            end
        }
    end
    ox_lib:registerContext({
        id = 'weapon_crafting_menu',
        title = 'Weapon Workbench',
        options = options
    })
    ox_lib:showContext('weapon_crafting_menu')
end

local function setupTargets()
    for _, location in ipairs(Config.Locations) do
        local targetId = 'weapon_bench_' .. _.location
        ox_target:removeZone(targetId)
        ox_target:addBoxZone({
            name = targetId,
            coords = location.coords,
            size = vec3(1.5, 1.5, 1.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'craft_weapons',
                    label = 'Craft Weapons',
                    icon = 'fas fa-hammer',
                    onSelect = function()
                        openCraftingMenu()
                    end,
                    canInteract = function()
                        return not isCrafting
                    end
                }
            }
        })
    end
end

Citizen.CreateThread(function()
    setupTargets()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setupTargets()
end)
