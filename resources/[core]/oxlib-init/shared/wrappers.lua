if not Wrappers then Wrappers = {} end

function Wrappers.Notify(data)
    if type(data) == 'string' then
        data = { description = data }
    end
    data.type = data.type or 'info'
    data.duration = data.duration or Config.Notify.duration
    data.position = data.position or Config.Notify.position
    TriggerEvent('ox_lib:notify', data)
end

function Wrappers.NotifyServer(data)
    if type(data) == 'string' then
        data = { description = data }
    end
    data.type = data.type or 'info'
    data.duration = data.duration or Config.Notify.duration
    TriggerClientEvent('ox_lib:notify', -1, data)
end

function Wrappers.ProgressBar(data)
    data.duration = data.duration or Config.ProgressBar.duration
    data.label = data.label or Config.ProgressBar.label
    data.useWhileDead = data.useWhileDead or Config.ProgressBar.useWhileDead
    data.canCancel = data.canCancel or Config.ProgressBar.canCancel
    data.disableMovement = data.disableMovement or Config.ProgressBar.disableMovement
    data.disableCarMovement = data.disableCarMovement or Config.ProgressBar.disableCarMovement
    data.disableMouse = data.disableMouse or Config.ProgressBar.disableMouse
    data.disableCombat = data.disableCombat or Config.ProgressBar.disableCombat
    data.anim = data.anim or Config.ProgressBar.anim
    return exports['ox_lib']:progressBar(data)
end

function Wrappers.ContextMenu(data)
    data.position = data.position or Config.ContextMenu.position
    data.canClose = data.canClose or Config.ContextMenu.canClose
    return exports['ox_lib']:registerContext(data)
end

function Wrappers.ShowContextMenu(id)
    exports['ox_lib']:showContext(id)
end

function Wrappers.InputDialog(data)
    data.title = data.title or Config.InputDialog.title
    data.options = data.options or Config.InputDialog.options
    return exports['ox_lib']:inputDialog(data.title, data.options)
end

function Wrappers.SkillCheck(data)
    data.difficulty = data.difficulty or Config.SkillCheck.difficulty
    data.inputs = data.inputs or Config.SkillCheck.inputs
    data.time = data.time or Config.SkillCheck.time
    return exports['ox_lib']:skillCheck(data.difficulty, data.inputs, data.time)
end

function Wrappers.TextUI(data)
    if type(data) == 'string' then
        data = { text = data }
    end
    data.position = data.position or Config.TextUI.position
    data.icon = data.icon or Config.TextUI.icon
    exports['ox_lib']:showTextUI(data.text, data)
end

function Wrappers.HideTextUI()
    exports['ox_lib']:hideTextUI()
end

function Wrappers.AlertDialog(data)
    data.title = data.title or Config.AlertDialog.title
    data.content = data.content or Config.AlertDialog.content
    data.centered = data.centered or Config.AlertDialog.centered
    data.cancel = data.cancel or Config.AlertDialog.cancel
    data.size = data.size or Config.AlertDialog.size
    data.labels = data.labels or Config.AlertDialog.labels
    return exports['ox_lib']:alertDialog(data)
end

function Wrappers.ShowNavButtons(buttons)
    if buttons then
        exports['ox_lib']:showNavButtons(buttons)
    else
        exports['ox_lib']:hideNavButtons()
    end
end

function Wrappers.ToggleRagdoll(toggle)
    exports['ox_lib']:toggleRagdoll(toggle)
end

function Wrappers.GetVehicleSeat(vehicle)
    return exports['ox_lib']:getVehicleSeat(vehicle)
end

function Wrappers.GetClosestVehicle(coords, maxDist, modelFilter)
    return exports['ox_lib']:getClosestVehicle(coords, maxDist, modelFilter)
end

function Wrappers.GetClosestPlayer(coords, maxDist)
    return exports['ox_lib']:getClosestPlayer(coords, maxDist)
end

function Wrappers.RaycastCamera(dist, flags, ignoreEntity)
    return exports['ox_lib']:raycastCamera(dist, flags, ignoreEntity)
end

function Wrappers.GetVehiclePed(vehicle)
    return exports['ox_lib']:getVehiclePed(vehicle)
end

function Wrappers.GetNearbyVehicles(coords, maxDist, maxVehicles)
    return exports['ox_lib']:getNearbyVehicles(coords, maxDist, maxVehicles)
end

function Wrappers.GetNearbyPlayers(coords, maxDist, maxPlayers)
    return exports['ox_lib']:getNearbyPlayers(coords, maxDist, maxPlayers)
end

function Wrappers.GetEntityCoords(entity)
    return exports['ox_lib']:getEntityCoords(entity)
end

function Wrappers.GetEntityBone(entity, boneName)
    return exports['ox_lib']:getEntityBone(entity, boneName)
end

function Wrappers.Wait(time)
    return exports['ox_lib']:wait(time)
end

function Wrappers.GetVehicleType(vehicle)
    return exports['ox_lib']:getVehicleType(vehicle)
end

function Wrappers.VehicleOptions(vehicle)
    return exports['ox_lib']:vehicleOptions(vehicle)
end

function Wrappers.SetRagdoll(ped, toggle)
    SetPedRagdoll(ped, toggle, false, false, false, false)
end

function Wrappers.RequestAnimDict(dict)
    return exports['ox_lib']:requestAnimDict(dict)
end

function Wrappers.RequestModel(model)
    return exports['ox_lib']:requestModel(model)
end

function Wrappers.RequestPtfxAsset(asset)
    return exports['ox_lib']:requestPtfxAsset(asset)
end
