RegisterNetEvent('player:disconnect', function()
    local src = source
    if src then
        DropPlayer(src, 'Disconnected from pause menu')
    end
end)
