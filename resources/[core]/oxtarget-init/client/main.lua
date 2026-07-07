local globalZones = {}
local entityOptions = {}

local function RegisterGlobalTargets()
    for name, zone in pairs(Config.GlobalZones) do
        exports['ox_target']:addGlobalZone(name, zone)
    end
end

local function RegisterEntityTargets()
    for entityType, options in pairs(Config.EntityOptions) do
        for _, option in ipairs(options) do
            exports['ox_target']:addGlobalEntity(entityType, option)
        end
    end
end

local function RemoveAllTargets()
    for name in pairs(Config.GlobalZones) do
        exports['ox_target']:removeZone(name)
    end
    for entityType in pairs(Config.EntityOptions) do
        exports['ox_target']:removeGlobalEntity(entityType)
    end
end

local function InitializeTarget()
    exports['ox_target']:setToggleHotkey(Config.Target.toggleHotkey)
    exports['ox_target']:setDefaultHotkey(Config.Target.defaultHotkey)
    exports['ox_target']:setDrawSprite(Config.Target.drawSprite)
    exports['ox_target']:setLeftClick(Config.Target.leftClick)
    exports['ox_target']:setBoneIndices(Config.Target.boneIndices)
    exports['ox_target']:setDynamicZones(Config.Target.dynamicZones)
    exports['ox_target']:setMaxDistance(Config.Target.maxDistance)
    exports['ox_target']:setShowDistance(Config.Target.showDistance)
    exports['ox_target']:setHighlightTexture(Config.Target.highlightTexture)
    exports['ox_target']:setHighlightColor(Config.Target.highlightColor[1], Config.Target.highlightColor[2], Config.Target.highlightColor[3], Config.Target.highlightColor[4])
    RegisterGlobalTargets()
    RegisterEntityTargets()
end

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    InitializeTarget()
    print('^2[oxtarget-init] Client target system initialized.^7')
end)

AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    RemoveAllTargets()
end)

exports('RegisterLocalTarget', function(entity, options)
    exports['ox_target']:addLocalEntity(entity, options)
end)

exports('RemoveLocalTarget', function(entity)
    exports['ox_target']:removeLocalEntity(entity)
end)

exports('RegisterZoneTarget', function(name, coords, size, heading, options)
    exports['ox_target']:addBoxZone(name, coords, size.x, size.y, {
        heading = heading or 0,
        minZ = (coords.z - (size.z / 2)) or 0.0,
        maxZ = (coords.z + (size.z / 2)) or 0.0
    }, options)
end)

exports('RemoveZoneTarget', function(name)
    exports['ox_target']:removeZone(name)
end)

exports('AddGlobalVehicleOption', function(options)
    exports['ox_target']:addGlobalEntity('vehicle', options)
end)

exports('AddGlobalPedOption', function(options)
    exports['ox_target']:addGlobalEntity('ped', options)
end)

exports('AddGlobalObjectOption', function(options)
    exports['ox_target']:addGlobalEntity('object', options)
end)
