local bodycamActive = false
local bodycamProp = nil
local binocularsActive = false

function useHandcuffs()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local closest = lib.getClosestPlayer(coords, 3.0, false)

    if not closest then
        exports.ox_lib:notify({ type = 'error', description = 'No player nearby' })
        return
    end

    if not lib.progressBar({
        duration = 2000,
        label = 'Applying handcuffs...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mp_arresting', clip = 'a_uncuff' },
    }) then return end

    TriggerServerEvent('item-actions:server:cuffPlayer', closest)
    exports.ox_lib:notify({ type = 'success', description = 'Handcuffs applied' })
end

function useBodycam()
    local ped = cache.ped

    if bodycamActive then
        if bodycamProp then
            DeleteObject(bodycamProp)
            bodycamProp = nil
        end
        bodycamActive = false
        exports.ox_lib:notify({ type = 'info', description = 'Body camera turned off' })
        return
    end

    lib.requestModel(`prop_police_belt`)
    bodycamProp = CreateObject(`prop_police_belt`, 0, 0, 0, true, true, false)
    AttachEntityToEntity(bodycamProp, ped, GetPedBoneIndex(ped, 24818), 0.1, 0.05, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    bodycamActive = true
    exports.ox_lib:notify({ type = 'success', description = 'Body camera turned on' })
end

function usePoliceRam()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, 3.0, true)

    if not vehicle then
        exports.ox_lib:notify({ type = 'error', description = 'No vehicle nearby' })
        return
    end

    if not lib.progressBar({
        duration = 3000,
        label = 'Breaching doors...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a' },
    }) then return end

    TriggerServerEvent('item-actions:server:breachDoor', VehToNet(vehicle))
    exports.ox_lib:notify({ type = 'success', description = 'Doors breached' })
end

function useBinoculars()
    local ped = cache.ped

    if binocularsActive then
        ClearTimecycleModifier()
        SetTimecycleModifier('default')
        SetPedDropsWeaponsWhenDead(ped, true)
        binocularsActive = false
        exports.ox_lib:notify({ type = 'info', description = 'Binoculars stowed' })
        return
    end

    local cam = lib.requestAnimDict('cellphone@')
    TaskPlayAnim(ped, 'cellphone@', 'cellphone_text_read_base', 8.0, 8.0, -1, 49, 0, false, false, false)

    binocularsActive = true
    SetTimecycleModifier('scanline_cam_achievement')
    SetTimecycleModifierStrength(0.3)

    exports.ox_lib:notify({ type = 'success', description = 'Binoculars raised. Use again to stow.' })

    CreateThread(function()
        while binocularsActive do
            Wait(0)
            HideHudComponentThisFrame(14)
            HideHudComponentThisFrame(15)

            if IsControlJustPressed(0, 24) then
                local hit, coords = GetEntityPlayerIsFreeAimingAt(PlayerId(), nil)
                if hit and coords then
                    SetNewWaypoint(coords.x, coords.y)
                    exports.ox_lib:notify({ type = 'success', description = 'Waypoint set' })
                end
            end
        end
    end)
end

function useHammer()
    local ped = cache.ped
    lib.requestAnimDict('melee@hammer@holstered')
    TaskPlayAnim(ped, 'melee@hammer@holstered', 'idle', 8.0, 8.0, -1, 49, 0, false, false, false)
    exports.ox_lib:notify({ type = 'info', description = 'Hammer equipped' })
    Citizen.CreateThread(function()
        Citizen.Wait(3000)
        ClearPedTasks(ped)
    end)
end

function useWrench()
    local ped = cache.ped
    lib.requestAnimDict('melee@tool_wrench@')
    TaskPlayAnim(ped, 'melee@tool_wrench@', 'idle', 8.0, 8.0, -1, 49, 0, false, false, false)
    exports.ox_lib:notify({ type = 'info', description = 'Wrench equipped' })
    Citizen.CreateThread(function()
        Citizen.Wait(3000)
        ClearPedTasks(ped)
    end)
end

exports('useHandcuffs', useHandcuffs)
exports('useBodycam', useBodycam)
exports('usePoliceRam', usePoliceRam)
exports('useBinoculars', useBinoculars)
exports('useHammer', useHammer)
exports('useWrench', useWrench)
