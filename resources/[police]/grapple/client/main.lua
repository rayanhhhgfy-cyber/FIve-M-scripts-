local QBox = exports['qbx-core']:GetCoreObject()
local isGrappling = false
local ropeHandle = nil
local grappleTarget = nil
local grappleCooldown = false

local function hasGrapple()
    return QBox.Functions.HasItem(Config.Grapple.ItemName)
end

RegisterCommand('+grapple', function()
    TriggerEvent('grapple:use')
end, false)

RegisterKeyMapping('+grapple', 'Use Grappling Hook', 'keyboard', 'g')

RegisterNetEvent('grapple:use', function()
    if grappleCooldown then
        Wrappers.Notify(Locale('police.cooldown_active'), 'error')
        return
    end
    if isGrappling then
        TriggerEvent('grapple:release')
        return
    end
    if not hasGrapple() then
        Wrappers.Notify(Locale('police.no_grapple'), 'error')
        return
    end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local camCoords = GetGameplayCamCoord()
    local direction = GetCamForwardVector()
    local hit, hitCoords, hitEntity, hitNormal = GetShapeTestResult(StartShapeTestCapsule(coords.x, coords.y, coords.z, coords.x + direction.x * Config.Grapple.MaxRange, coords.y + direction.y * Config.Grapple.MaxRange, coords.z + direction.z * Config.Grapple.MaxRange, 0.3, 1, ped, 4))
    if not hit or hit == 0 then
        Wrappers.Notify(Locale('police.grapple_no_target'), 'error')
        return
    end
    if hit and GetEntityType(hitEntity) == 0 then
        hitCoords = hitCoords or coords + direction * Config.Grapple.MaxRange
    end
    local dist = #(coords - hitCoords)
    if dist > Config.Grapple.MaxRange then
        Wrappers.Notify(Locale('police.grapple_too_far'), 'error')
        return
    end
    Wrappers.ProgressBar({
        label = Locale('police.throwing_grapple'),
        duration = Config.Grapple.ThrowTime,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('grapple:server:used')
        isGrappling = true
        grappleTarget = hitCoords
        ropeHandle = AddRope(hitCoords.x, hitCoords.y, hitCoords.z, 0.0, 0.0, 0.0, Config.Grapple.RopeLength, 1, Config.Grapple.RopeLength, 0.05, 0.05, false, false, false, 1.0, false)
        ActivatePhysics(ropeHandle)
        local pedCoords = GetEntityCoords(ped)
        AttachEntitiesToRope(ropeHandle, ped, 0, 0, 0, hitCoords.x, hitCoords.y, hitCoords.z, Config.Grapple.RopeLength, false, false, nil, nil)
        Wrappers.Notify(Locale('police.grapple_attached'), 'success')
        grappleCooldown = true
        SetTimeout(Config.Grapple.Cooldown.throw, function()
            grappleCooldown = false
        end)
    end)
end)

RegisterNetEvent('grapple:release', function()
    if not isGrappling then return end
    if ropeHandle then
        DeleteRope(ropeHandle)
        ropeHandle = nil
    end
    isGrappling = false
    grappleTarget = nil
    local ped = PlayerPedId()
    SetPedGravity(ped, true)
    DeleteRope(ropeHandle)
    Wrappers.Notify(Locale('police.grapple_released'), 'info')
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isGrappling and grappleTarget then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - grappleTarget)
            if dist < 2.0 then
                TriggerEvent('grapple:release')
                Wrappers.Notify(Locale('police.grapple_reached'), 'success')
                Citizen.Wait(100)
            end
            if IsControlPressed(0, 32) then
                local direction = GetCamForwardVector()
                local moveVec = grappleTarget - coords
                local moveDir = moveVec / dist
                SetEntityVelocity(ped, moveDir * Config.Grapple.ReelSpeed + direction * 2.0)
                SetPedGravity(ped, false)
            elseif IsControlPressed(0, 33) then
                local direction = GetCamForwardVector()
                local moveVec = coords - grappleTarget
                local moveDir = moveVec / #(moveVec)
                SetEntityVelocity(ped, moveDir * Config.Grapple.ReelSpeed * 0.5 + vector3(0.0, 0.0, -2.0))
                SetPedGravity(ped, false)
            elseif IsControlPressed(0, 34) then
                SetEntityVelocity(ped, vector3(0.0, 0.0, 0.0))
            else
                SetPedGravity(ped, true)
            end
            if IsPedFalling(ped) then
                SetPedGravity(ped, false)
            end
        else
            Citizen.Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if ropeHandle then
            DeleteRope(ropeHandle)
        end
    end
end)
