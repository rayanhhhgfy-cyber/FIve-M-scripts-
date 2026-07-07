local preview = {}
preview.entity = nil
preview.active = false
preview.type = nil
preview.callback = nil
preview.offset = 3.0
preview.rotation = 0.0
local QBox = exports['qbx-core']:GetCoreObject()

function preview.startObject(model, onConfirm)
    preview.cleanup()
    preview.type = 'object'
    preview.callback = onConfirm
    preview.rotation = 0.0
    preview.offset = 3.0

    RequestModel(model)
    local tries = 0
    while not HasModelLoaded(model) and tries < 100 do
        Citizen.Wait(10)
        tries = tries + 1
    end
    if not HasModelLoaded(model) then
        Wrappers.Notify('Failed to load model: ' .. model, 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local camRot = GetGameplayCamRot(0)
    local _, _, z = table.unpack(camRot)
    local dx = -math.sin(z * math.pi / 180.0) * preview.offset
    local dy = math.cos(z * math.pi / 180.0) * preview.offset
    local pos = vector3(coords.x + dx, coords.y + dy, coords.z)

    preview.entity = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
    SetEntityAlpha(preview.entity, Config.GodDashboard.previewAlpha, false)
    FreezeEntityPosition(preview.entity, true)
    SetEntityCollision(preview.entity, false, false)
    SetEntityInvincible(preview.entity, true)
    preview.active = true

    Wrappers.Notify('WASD=move | Q/E=rotate | Scroll=distance | Enter=confirm | Backspace=cancel', 'info')
end

function preview.startVehicle(model, onConfirm)
    preview.cleanup()
    preview.type = 'vehicle'
    preview.callback = onConfirm
    preview.rotation = 0.0
    preview.offset = 3.0

    local hash = GetHashKey(model)
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 200 do
        Citizen.Wait(10)
        tries = tries + 1
    end
    if not HasModelLoaded(hash) then
        Wrappers.Notify('Failed to load vehicle: ' .. model, 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local camRot = GetGameplayCamRot(0)
    local _, _, z = table.unpack(camRot)
    local dx = -math.sin(z * math.pi / 180.0) * preview.offset
    local dy = math.cos(z * math.pi / 180.0) * preview.offset
    local pos = vector3(coords.x + dx, coords.y + dy, coords.z)

    preview.entity = CreateVehicle(hash, pos.x, pos.y, pos.z, 0.0, false, false)
    SetEntityAlpha(preview.entity, Config.GodDashboard.previewAlpha, false)
    FreezeEntityPosition(preview.entity, true)
    SetEntityCollision(preview.entity, false, false)
    SetEntityInvincible(preview.entity, true)
    SetVehicleDoorsLocked(preview.entity, 2)
    SetVehicleEngineOn(preview.entity, false, true, false)
    preview.active = true

    Wrappers.Notify('WASD=move | Q/E=rotate | Scroll=distance | Enter=confirm | Backspace=cancel', 'info')
end

function preview.cleanup()
    preview.active = false
    preview.callback = nil
    preview.type = nil
    if preview.entity and DoesEntityExist(preview.entity) then
        if preview.type == 'vehicle' then
            DeleteVehicle(preview.entity)
        else
            DeleteObject(preview.entity)
        end
    end
    preview.entity = nil
end

function preview.updatePosition()
    if not preview.active or not preview.entity or not DoesEntityExist(preview.entity) then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    if IsControlJustPressed(0, 96) then preview.offset = math.max(1.0, preview.offset - 0.5) end
    if IsControlJustPressed(0, 97) then preview.offset = math.min(Config.GodDashboard.maxPreviewDistance, preview.offset + 0.5) end
    if IsControlPressed(0, 44) then preview.rotation = preview.rotation - Config.GodDashboard.rotateSpeed end
    if IsControlPressed(0, 38) then preview.rotation = preview.rotation + Config.GodDashboard.rotateSpeed end

    local camRot = GetGameplayCamRot(0)
    local _, _, z = table.unpack(camRot)
    local dx = -math.sin(z * math.pi / 180.0) * preview.offset
    local dy = math.cos(z * math.pi / 180.0) * preview.offset
    local targetPos = vector3(coords.x + dx, coords.y + dy, coords.z)

    local forward = GetEntityForwardVector(ped)
    local right = GetEntityRightVector(ped)
    local moved = false

    if IsControlPressed(0, 87) then
        targetPos = targetPos + forward * Config.GodDashboard.moveSpeed
        moved = true
    end
    if IsControlPressed(0, 83) then
        targetPos = targetPos - forward * Config.GodDashboard.moveSpeed
        moved = true
    end
    if IsControlPressed(0, 65) then
        targetPos = targetPos - right * Config.GodDashboard.moveSpeed
        moved = true
    end
    if IsControlPressed(0, 68) then
        targetPos = targetPos + right * Config.GodDashboard.moveSpeed
        moved = true
    end

    SetEntityCoords(preview.entity, targetPos.x, targetPos.y, targetPos.z)
    SetEntityHeading(preview.entity, preview.rotation)

    if IsControlJustPressed(0, 18) then
        local pos = GetEntityCoords(preview.entity)
        local h = GetEntityHeading(preview.entity)
        preview.active = false
        if preview.callback then
            preview.callback({ coords = { x = pos.x, y = pos.y, z = pos.z }, heading = h })
        end
        preview.cleanup()
    end

    if IsControlJustPressed(0, 106) then
        preview.active = false
        preview.cleanup()
        Wrappers.Notify('Preview cancelled', 'info')
    end
end

return preview
