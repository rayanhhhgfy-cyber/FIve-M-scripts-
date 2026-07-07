AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[pillbox-mlo] Pillbox Hill Medical Center mapped. %d zones, %d portals, %d healing beds.^7',
        #Config.InteriorZones, #Config.InteriorPortals, #Config.HealingZones)
end)
