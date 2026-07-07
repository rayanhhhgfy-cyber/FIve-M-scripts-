local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local inTuningZone = false
local currentTuningLoc = nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function showModMenu()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        Wrappers.Notify('Get in a vehicle first', 'error')
        return
    end

    local catItems = {}
    for catId, catLabel in pairs(Config.Tuning.categories) do
        local modItems = {}
        for _, mod in ipairs(Config.Tuning.mods) do
            if mod.cat == catId then
                local levels = {}
                for lvl = 1, mod.max do
                    local price = mod.prices[lvl]
                    local currentMod = GetVehicleMod(vehicle, mod.modType)
                    local check = currentMod == lvl - 1 and '✓ ' or ''
                    table.insert(levels, {
                        title = check .. 'Level ' .. lvl .. ' ($' .. price .. ')',
                        onSelect = function()
                            TriggerServerEvent('tuning:server:installMod', mod.id, lvl)
                        end,
                    })
                end
                table.insert(modItems, { title = mod.label, icon = 'fas fa-wrench', menu = levels })
            end
        end
        if catId == 'colors' then
            local colorItems = {}
            for i, color in ipairs(Config.Tuning.colorPresets) do
                table.insert(colorItems, {
                    title = color.label .. ' ($' .. color.price .. ')',
                    icon = 'fas fa-palette',
                    onSelect = function()
                        TriggerServerEvent('tuning:server:paint', i)
                    end,
                })
            end
            table.insert(modItems, { title = 'Paint Colors', icon = 'fas fa-palette', menu = colorItems })
            table.insert(modItems, { title = 'Wheel Color ($500)', icon = 'fas fa-circle', onSelect = function()
                TriggerServerEvent('tuning:server:installMod', 'wheel_color', 1)
            end})
        end
        if catId == 'extras' then
            table.insert(modItems, { title = 'Reset All Mods ($5000)', icon = 'fas fa-undo', onSelect = function()
                TriggerServerEvent('tuning:server:reset')
            end})
        end
        table.insert(catItems, { title = catLabel, icon = 'fas fa-tag', menu = modItems })
    end
    Wrappers.ContextMenu({ id = 'tuning_menu', title = 'Tuning Garage', menuItems = catItems })
end

--- Apply mod on vehicle
RegisterNetEvent('tuning:client:applyMod', function(modId, level)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    local modConfig = nil
    for _, m in ipairs(Config.Tuning.mods) do
        if m.id == modId then modConfig = m end
    end
    if not modConfig then return end

    if modConfig.modType == 'wheel_color' then
        SetVehicleWheelColour(vehicle, math.random(0, 255))
        return
    elseif modConfig.modType == 'neon' then
        SetVehicleNeonLightEnabled(vehicle, 0, true)
        SetVehicleNeonLightEnabled(vehicle, 1, true)
        SetVehicleNeonLightEnabled(vehicle, 2, true)
        SetVehicleNeonLightEnabled(vehicle, 3, true)
        SetVehicleNeonLightsColour(vehicle, 0, 150, 255)
        return
    elseif modConfig.modType == 'window' then
        SetVehicleWindowTint(vehicle, level)
        return
    elseif modConfig.modType == 'xenon' then
        ToggleVehicleMod(vehicle, 22, true)
        return
    end

    SetVehicleMod(vehicle, modConfig.modType, level - 1, false)
    SetVehicleModKit(vehicle, 0)
end)

--- Apply paint
RegisterNetEvent('tuning:client:applyPaint', function(colorIndex)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    local color = Config.Tuning.colorPresets[colorIndex]
    if not color then return end
    SetVehicleCustomPrimaryColour(vehicle, color.r, color.g, color.b)
    SetVehicleCustomSecondaryColour(vehicle, color.r, color.g, color.b)
end)

--- Reset mods
RegisterNetEvent('tuning:client:reset', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    SetVehicleModKit(vehicle, 0)
    for _, mod in ipairs(Config.Tuning.mods) do
        if type(mod.modType) == 'number' then
            RemoveVehicleMod(vehicle, mod.modType)
        end
    end
    SetVehicleWindowTint(vehicle, 0)
    ToggleVehicleMod(vehicle, 22, false)
    for i = 0, 3 do SetVehicleNeonLightEnabled(vehicle, i, false) end
    SetVehicleColours(vehicle, 0, 0)
end)

--- Create tuning zones
Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    playerData = QBox.Functions.GetPlayerData()

    for _, loc in ipairs(Config.Tuning.locations) do
        exports.ox_target:addBoxZone({
            coords = loc.coords,
            size = vector3(loc.radius * 2, loc.radius * 2, 4.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'tuning_' .. loc.id,
                    icon = 'fas fa-car',
                    label = 'Open Tuning Menu',
                    distance = Config.Tuning.maxDistance,
                    canInteract = function()
                        local ped = PlayerPedId()
                        local vehicle = GetVehiclePedIsIn(ped, false)
                        return vehicle ~= 0
                    end,
                    onSelect = function()
                        currentTuningLoc = loc.id
                        showModMenu()
                    end,
                },
            },
        })
    end
end)

--- Drive-in prompt thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 then
            local pCoords = GetEntityCoords(ped)
            for _, loc in ipairs(Config.Tuning.locations) do
                if #(pCoords - loc.coords) < loc.radius then
                    if not inTuningZone then
                        inTuningZone = true
                        currentTuningLoc = loc.id
                        Wrappers.Notify('Press E to tune your vehicle', 'info')
                    end
                    break
                end
            end
        else
            inTuningZone = false
        end
    end
end)
