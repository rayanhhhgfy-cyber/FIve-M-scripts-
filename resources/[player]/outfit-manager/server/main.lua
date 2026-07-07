--- Outfit Manager - Server
--- Relays to illenium-appearance callbacks for outfit persistence

lib.callback.register('outfit-manager:server:getOutfits', function(source)
    return lib.callback.await('illenium-appearance:server:getOutfits', false, source)
end)

lib.callback.register('outfit-manager:server:saveOutfit', function(source, outfitName, outfitData)
    return lib.callback.await('illenium-appearance:server:saveOutfit', false, source, outfitName, outfitData)
end)

lib.callback.register('outfit-manager:server:deleteOutfit', function(source, outfitIndex)
    return lib.callback.await('illenium-appearance:server:deleteOutfit', false, source, outfitIndex)
end)
