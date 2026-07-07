CreateThread(function()
    while true do
        if NetworkIsSessionStarted() then
            ShutdownLoadingScreenNui()
            return
        end
        Wait(100)
    end
end)
