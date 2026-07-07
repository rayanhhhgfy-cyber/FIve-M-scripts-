AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[cdn-hud] HUD server bridge active.^7')
end)
