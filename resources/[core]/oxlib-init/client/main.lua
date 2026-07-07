local function InitializeClientLib()
    print('^2[oxlib-init] Client wrappers initialized.^7')
end

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    InitializeClientLib()
end)

exports('Notify', Wrappers.Notify)
exports('ProgressBar', Wrappers.ProgressBar)
exports('ContextMenu', Wrappers.ContextMenu)
exports('ShowContextMenu', Wrappers.ShowContextMenu)
exports('InputDialog', Wrappers.InputDialog)
exports('SkillCheck', Wrappers.SkillCheck)
exports('TextUI', Wrappers.TextUI)
exports('HideTextUI', Wrappers.HideTextUI)
exports('AlertDialog', Wrappers.AlertDialog)
exports('ShowNavButtons', Wrappers.ShowNavButtons)
exports('ToggleRagdoll', Wrappers.ToggleRagdoll)
exports('GetClosestVehicle', Wrappers.GetClosestVehicle)
exports('GetClosestPlayer', Wrappers.GetClosestPlayer)
exports('RaycastCamera', Wrappers.RaycastCamera)
