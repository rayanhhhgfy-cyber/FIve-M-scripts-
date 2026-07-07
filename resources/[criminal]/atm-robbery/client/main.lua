local QBox = exports['qbx-core']:GetCoreObject()
local ox_target = exports.ox_target
local ox_lib = exports.ox_lib

local isRobbing = false
local robberiesToday = 0

local function hasItem(itemName)
    local player = QBox.Functions.GetPlayer()
    if not player then return false end
    local item = player.Functions.GetItemByName(itemName)
    return item and item.amount > 0
end

local function getSkillMultiplier()
    local exp = QBox.Functions.GetPlayer().PlayerData.metadata.atmrob_exp or 0
    for i = #Config.SkillLevels, 1, -1 do
        if exp >= Config.SkillLevels[i].exp then
            return Config.SkillLevels[i].drillSpeed
        end
    end
    return 1.0
end

local function addExp(amount)
    local exp = QBox.Functions.GetPlayer().PlayerData.metadata.atmrob_exp or 0
    exp = exp + amount
    QBox:SetMetaData('atmrob_exp', exp)
end

local function drillATM(atm)
    if isRobbing then return end
    if not hasItem(Config.Robbery.drillItem) then
        return Wrappers.Notify('error', 'No Drill', 'You need an ATM drill')
    end
    isRobbing = true
    local speedMulti = getSkillMultiplier()
    local drillTime = Config.Robbery.drillTime * speedMulti
    local success = ox_lib:progressBar({
        duration = math.floor(drillTime),
        label = 'Drilling ATM...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'anim@heists@fleeca_bank@drilling', clip = 'drill_straight_idle' },
        prop = { model = 'prop_tool_drill', pos = vec3(0.15, 0.05, 0.0), rot = vec3(0.0, 0.0, 0.0) }
    })
    if success then
        local skillPass = ox_lib:skillCheck(Config.SkillCheck.drillDifficulty, Config.SkillCheck.drillAreaSize)
        if skillPass then
            TriggerServerEvent('atm-robbery:server:robATM', atm, 'drill')
            addExp(Config.Robbery.expPerRobbery)
        else
            Wrappers.Notify('error', 'Failed', 'The drill slipped and broke!')
            QBox:RemoveItem(Config.Robbery.drillItem, 1)
        end
    end
    isRobbing = false
end

local function bombATM(atm)
    if isRobbing then return end
    if not hasItem(Config.Robbery.explosiveItem) then
        return Wrappers.Notify('error', 'No Explosives', 'You need C4')
    end
    isRobbing = true
    Wrappers.Notify('warning', 'Planting', 'Planting explosives...')
    local success = ox_lib:progressBar({
        duration = Config.Robbery.explosiveTime,
        label = 'Planting Explosives...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'anim@heists@fleeca_bank@drilling', clip = 'drill_straight_idle' },
        prop = {}
    })
    if success then
        Wrappers.Notify('warning', 'Take Cover', 'Explosives armed! Get back!')
        SetPlayerControl(PlayerId(), false, 0)
        Citizen.Wait(3000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        AddExplosion(atm.coords.x, atm.coords.y, atm.coords.z, 4, Config.Robbery.explosiveRadius, true, false, 1.0)
        ShakeGameplayCam('EXPLOSION_SHAKE', 1.0)
        Citizen.Wait(1000)
        SetPlayerControl(PlayerId(), true, 0)
        local skillPass = ox_lib:skillCheck(Config.SkillCheck.explosiveDifficulty, Config.SkillCheck.explosiveAreaSize)
        if skillPass then
            TriggerServerEvent('atm-robbery:server:robATM', atm, 'explosive')
            addExp(Config.Robbery.expPerRobbery * 2)
        else
            Wrappers.Notify('error', 'Too Much', 'The explosion destroyed the cash!')
            QBox:RemoveItem(Config.Robbery.explosiveItem, 1)
        end
    end
    isRobbing = false
end

local function openRobberyMenu(atm)
    local options = {
        {
            title = 'Drill ATM',
            description = 'Requires: ATM Drill',
            onSelect = function()
                drillATM(atm)
            end,
            disabled = not hasItem(Config.Robbery.drillItem)
        },
        {
            title = 'Blow ATM',
            description = 'Requires: C4 (Loud)',
            onSelect = function()
                bombATM(atm)
            end,
            disabled = not hasItem(Config.Robbery.explosiveItem)
        }
    }
    ox_lib:registerContext({
        id = 'atm_robbery_' .. atm.label,
        title = 'ATM Robbery - ' .. atm.label,
        options = options
    })
    ox_lib:showContext('atm_robbery_' .. atm.label)
end

local function setupATMs()
    for _, atm in ipairs(Config.ATMs) do
        local targetId = 'atm_robbery_' .. _.label
        ox_target:removeZone(targetId)
        ox_target:addBoxZone({
            name = targetId,
            coords = atm.coords,
            size = vec3(1.2, 1.2, 1.5),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'rob_atm_' .. _.label,
                    label = 'Rob ATM',
                    icon = 'fas fa-money-bill',
                    onSelect = function()
                        openRobberyMenu(atm)
                    end,
                    canInteract = function()
                        return (hasItem(Config.Robbery.drillItem) or hasItem(Config.Robbery.explosiveItem)) and not isRobbing
                    end
                }
            }
        })
    end
end

Citizen.CreateThread(function()
    setupATMs()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setupATMs()
end)

RegisterNetEvent('atm-robbery:client:robberyResult', function(success, loot)
    if success then
        Wrappers.Notify('success', 'ATM Robbed', 'You got $' .. loot .. ' worth of loot')
    end
end)

RegisterNetEvent('atm-robbery:client:lootReceived', function(amount)
    Wrappers.Notify('success', 'Loot', 'Received $' .. amount .. ' from loot bag')
end)

RegisterNetEvent('atm-robbery:client:policeAlert', function(coords, atmLabel)
    Wrappers.Notify('error', 'Police Alert', 'ATM robbery reported at ' .. atmLabel)
end)

RegisterNetEvent('atm-robbery:client:onCooldown', function(remaining)
    Wrappers.Notify('error', 'Cooldown', 'ATM on cooldown: ' .. math.ceil(remaining / 60) .. ' minutes')
end)
