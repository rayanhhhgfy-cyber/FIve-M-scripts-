AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ragdoll-system] Server bridge active.^7')
end)
