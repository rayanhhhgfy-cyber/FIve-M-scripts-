local QBCore = exports['qbx_core']:GetCoreObject()
local welcomeShown = false

RegisterNetEvent('welcome-system:client:showWelcome', function(isNewPlayer, firstName)
    if welcomeShown then return end
    welcomeShown = true
    if isNewPlayer then
        local message = string.format(Config.Messages.firstJoin, firstName)
        Wrappers.Notify({ type = 'success', description = message, duration = 10000 })
        if Config.StarterKit.enabled then
            SetTimeout(2000, function()
                Wrappers.Notify({ type = 'info', description = string.format(Config.Messages.starterKit, 'B'), duration = 8000 })
            end)
        end
        if Config.LandingPage.enabled then
            SetTimeout(Config.Welcome.displayDelay, function()
                lib.alertDialog({
                    header = Config.LandingPage.title,
                    content = Config.LandingPage.description .. '\n\n**Rules:**\n' .. table.concat(Config.LandingPage.rules, '\n'),
                    centered = true,
                    cancel = false,
                    size = 'lg',
                    labels = { confirm = Config.LandingPage.buttons.accept }
                })
            end)
        end
    else
        local message = string.format(Config.Messages.returnJoin, firstName)
        Wrappers.Notify({ type = 'info', description = message, duration = 5000 })
    end
end)

RegisterNetEvent('welcome-system:client:welcomeComplete', function()
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[welcome-system] Client welcome handler active.^7')
end)
