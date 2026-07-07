local QBox = exports['qbx-core']:GetCoreObject()
local ox_target = exports.ox_target
local ox_lib = exports.ox_lib

local spawnedTags = {}
local isTagging = false
local tagCooldown = 0

local function hasSprayCan()
    local player = QBox.Functions.GetPlayer()
    if not player then return false end
    local item = player.Functions.GetItemByName(Config.SprayCans.item)
    return item and item.amount > 0
end

local function addExp(amount)
    local exp = QBox.Functions.GetPlayer().PlayerData.metadata.graffiti_exp or 0
    exp = exp + amount
    QBox:SetMetaData('graffiti_exp', exp)
end

local function startTagging(location, color, tagType)
    if isTagging then return end
    if GetGameTimer() < tagCooldown then
        local remaining = math.ceil((tagCooldown - GetGameTimer()) / 1000)
        return Wrappers.Notify('error', 'Cooldown', 'Wait ' .. remaining .. ' seconds')
    end
    if not hasSprayCan() then
        return Wrappers.Notify('error', 'No Spray Can', 'You need a spray can')
    end
    isTagging = true
    local success = ox_lib:progressBar({
        duration = Config.Tagging.duration,
        label = 'Tagging Graffiti...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'switch@michael@sit', clip = 'idle' },
        prop = {}
    })
    if success then
        local skillPass = ox_lib:skillCheck(Config.Tagging.skillCheck.difficulty, Config.Tagging.skillCheck.areaSize)
        if skillPass then
            QBox:RemoveItem(Config.SprayCans.item, 1)
            addExp(Config.Tagging.expPerTag)
            tagCooldown = GetGameTimer() + (Config.Tagging.cooldown * 1000)
            TriggerServerEvent('graffiti:server:tagPlaced', location, color, tagType)
            Wrappers.Notify('success', 'Tagged', 'Graffiti placed successfully')
            if math.random() < Config.Police.alertChance then
                TriggerServerEvent('graffiti:server:alertPolice', GetEntityCoords(PlayerPedId()))
            end
        else
            Wrappers.Notify('error', 'Failed', 'Your tag looks terrible')
        end
    end
    isTagging = false
end

local function openTagMenu(location)
    local options = {}
    for _, color in ipairs(Config.SprayColors) do
        options[#options + 1] = {
            title = color.label,
            description = 'Use ' .. color.label .. ' spray',
            onSelect = function()
                local tagOptions = {}
                for _, tagType in ipairs(Config.TagTypes) do
                    tagOptions[#tagOptions + 1] = {
                        title = tagType.label,
                        onSelect = function()
                            startTagging(location, color, tagType)
                        end
                    }
                end
                ox_lib:registerContext({
                    id = 'graffiti_tag_type_' .. location.label,
                    title = 'Select Tag Type',
                    options = tagOptions
                })
                ox_lib:showContext('graffiti_tag_type_' .. location.label)
            end
        }
    end
    ox_lib:registerContext({
        id = 'graffiti_color_' .. location.label,
        title = 'Select Color',
        options = options
    })
    ox_lib:showContext('graffiti_color_' .. location.label)
end

local function startCleanup(tagId)
    local success = ox_lib:progressBar({
        duration = Config.Cleanup.duration,
        label = 'Cleaning Graffiti...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'amb@world_human_maid_clean@male@idle_a', clip = 'idle_a' },
        prop = {}
    })
    if success then
        TriggerServerEvent('graffiti:server:cleanupTag', tagId)
        Wrappers.Notify('success', 'Cleaned', 'Graffiti removed')
    end
end

local function setupTagLocations()
    for _, location in ipairs(Config.TagLocations) do
        local targetId = 'graffiti_spot_' .. location.label
        ox_target:removeZone(targetId)
        ox_target:addBoxZone({
            name = targetId,
            coords = location.coords,
            size = vec3(1.5, 1.5, 1.5),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'spray_graffiti_' .. location.label,
                    label = 'Spray Graffiti',
                    icon = 'fas fa-spray-can',
                    onSelect = function()
                        openTagMenu(location)
                    end,
                    canInteract = function()
                        return hasSprayCan() and not isTagging
                    end
                }
            }
        })
    end
end

local function spawnTagProp(tagData)
    if spawnedTags[tagData.id] then return end
    local model = tagData.tagType.model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(100)
    end
    local obj = CreateObject(model, tagData.coords.x, tagData.coords.y, tagData.coords.z - 1.0, false, false, false)
    PlaceObjectOnGroundProperly(obj)
    SetEntityAsMissionEntity(obj, true, true)
    spawnedTags[tagData.id] = obj
end

local function cleanupTagProps()
    for id, obj in pairs(spawnedTags) do
        if DoesEntityExist(obj) then
            DeleteObject(obj)
        end
    end
    spawnedTags = {}
end

Citizen.CreateThread(function()
    setupTagLocations()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setupTagLocations()
    TriggerServerEvent('graffiti:server:loadTags')
end)

RegisterNetEvent('graffiti:client:loadTags', function(tags)
    cleanupTagProps()
    for _, tagData in ipairs(tags) do
        spawnTagProp(tagData)
    end
end)

RegisterNetEvent('graffiti:client:tagPlaced', function(tagData)
    spawnTagProp(tagData)
end)

RegisterNetEvent('graffiti:client:tagRemoved', function(tagId)
    if spawnedTags[tagId] then
        if DoesEntityExist(spawnedTags[tagId]) then
            DeleteObject(spawnedTags[tagId])
        end
        spawnedTags[tagId] = nil
    end
end)

RegisterNetEvent('graffiti:client:policeAlert', function(coords)
    Wrappers.Notify('error', 'Police Alert', 'Police have been alerted to graffiti activity')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        cleanupTagProps()
    end
end)
