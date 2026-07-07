RegisterCommand(Config.ServerGuide.command, function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = {
            title = Config.ServerGuide.title,
            tabs = Config.ServerGuide.tabs,
            rules = Config.ServerGuide.rules,
            keybinds = Config.ServerGuide.keybinds,
            staff = Config.ServerGuide.staff,
            colors = Config.ServerGuide.colors,
        }
    })
end, false)

RegisterNUICallback('closeGuide', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
