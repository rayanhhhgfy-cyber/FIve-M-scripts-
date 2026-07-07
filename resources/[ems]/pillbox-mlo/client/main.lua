local currentZone = nil

local function LoadIPLs()
    if not Config.Pillbox.loadIPLs then return end
    for _, ipl in ipairs(Config.IPLs) do
        RequestIpl(ipl)
    end
end

local function GetInteriorAtCoords(coords)
    local interior = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if interior and interior > 0 then
        PinInteriorInMemory(interior)
        SetInteriorActive(interior, true)
    end
    return interior
end

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    LoadIPLs()
    local interior = GetInteriorAtCoords(vector3(Config.Pillbox.InteriorZones.emergency_room.coords.x, Config.Pillbox.InteriorZones.emergency_room.coords.y, Config.Pillbox.InteriorZones.emergency_room.coords.z))
    if interior and interior > 0 then
        LoadInterior(interior)
        RefreshInterior(interior)
    end
    print('^2[pillbox-mlo] Hospital interior loaded.^7')
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for name, zone in pairs(Config.Pillbox.InteriorZones) do
            local dist = #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
            if dist < zone.radius then
                currentZone = name
                break
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, portal in ipairs(Config.Pillbox.InteriorPortals) do
            local dist = #(coords - vector3(portal.coords.x, portal.coords.y, portal.coords.z))
            if dist < 2.0 then
                exports['ox_target']:addLocalEntity(ped, {
                    {
                        name = 'portal_' .. portal.name,
                        label = 'Enter ' .. Config.Pillbox.InteriorZones[portal.interior].label,
                        icon = 'fas fa-door-open',
                        distance = 2.0,
                        onSelect = function()
                            SetEntityCoords(ped, Config.Pillbox.InteriorZones[portal.interior].coords.x, Config.Pillbox.InteriorZones[portal.interior].coords.y, Config.Pillbox.InteriorZones[portal.interior].coords.z)
                        end
                    }
                })
            end
        end
        for _, healZone in ipairs(Config.Pillbox.HealingZones) do
            local dist = #(coords - vector3(healZone.coords.x, healZone.coords.y, healZone.coords.z))
            if dist < 2.0 then
                exports['ox_target']:addLocalEntity(ped, {
                    {
                        name = 'heal_bed_' .. healZone.label,
                        label = 'Rest (' .. healZone.label .. ')',
                        icon = 'fas fa-bed',
                        distance = 2.0,
                        onSelect = function()
                            local progress = exports['ox_lib']:progressBar({
                                duration = 10000,
                                label = 'Resting...',
                                useWhileDead = true,
                                canCancel = false,
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                                anim = {
                                    dict = 'amb@medic@standing@timeofdeath@base',
                                    clip = 'base'
                                }
                            })
                            if progress then
                                SetEntityHealth(ped, GetEntityMaxHealth(ped))
                                Wrappers.Notify({ type = 'success', description = 'Fully healed!' })
                            end
                        end
                    }
                })
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[pillbox-mlo] Client hospital map loaded.^7')
end)

exports('GetCurrentZone', function() return currentZone end)
