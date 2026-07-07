local function InitializeLib()
    print('^2[oxlib-init] ox_lib wrappers registered. UI component system active.^7')
end

lib.callback.register('oxlib-init:server:getConfig', function(source)
    return Config
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    InitializeLib()
end)

exports('GetConfig', function() return Config end)
