local isPlayingEmote = false
local currentEmoteTimer = nil
local currentWalkStyle = nil

local function stopEmote()
    if isPlayingEmote then
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        ClearPedSecondaryTask(ped)
        if currentEmoteTimer then
            SetTimeout(currentEmoteTimer, function() end)
            currentEmoteTimer = nil
        end
        isPlayingEmote = false
    end
end

local function playEmote(data)
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        exports.ox_lib:notify({ type = 'error', description = 'Cannot emote in a vehicle' })
        return
    end

    stopEmote()

    if data.facial then
        SetFacialIdleAnimOverride(ped, data.dict, data.anim)
        exports.ox_lib:notify({ type = 'success', description = data.label .. ' expression set' })
        return
    end

    RequestAnimDict(data.dict)
    local timeout = 0
    while not HasAnimDictLoaded(data.dict) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasAnimDictLoaded(data.dict) then
        exports.ox_lib:notify({ type = 'error', description = 'Animation failed to load' })
        return
    end

    local duration = data.duration or Config.AnimMenu.defaultDuration
    local flag = data.flag or 1

    TaskPlayAnim(ped, data.dict, data.anim, 8.0, -8.0, duration, flag, 0, false, false, false)
    isPlayingEmote = true

    currentEmoteTimer = SetTimeout(duration, function()
        if isPlayingEmote then
            ClearPedTasks(ped)
            isPlayingEmote = false
        end
    end)
end

local function setWalkStyle(data)
    local ped = PlayerPedId()

    if data.reset then
        ResetPedMovementClipset(ped, 0.0)
        currentWalkStyle = nil
        exports.ox_lib:notify({ type = 'success', description = 'Walk style reset to default' })
        return
    end

    RequestAnimSet(data.style)
    local timeout = 0
    while not HasAnimSetLoaded(data.style) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if HasAnimSetLoaded(data.style) then
        SetPedMovementClipset(ped, data.style, 0.25)
        currentWalkStyle = data.style
        exports.ox_lib:notify({ type = 'success', description = 'Walk style: ' .. data.label })
    else
        exports.ox_lib:notify({ type = 'error', description = 'Walk style failed to load' })
    end
end

--- Cancel emote key
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, Config.AnimMenu.cancelKey) then
            if isPlayingEmote then
                stopEmote()
                exports.ox_lib:notify({ type = 'info', description = 'Emote cancelled' })
            end
        end
    end
end)

--- Open a category's animation list via ox_lib context
local function openEmoteCategory(category, items)
    local contextData = {
        id = 'anim_menu_' .. category:lower():gsub('%s+', '_'),
        title = category,
        menu = 'anim_menu_root',
        options = {},
    }

    for _, anim in ipairs(items) do
        table.insert(contextData.options, {
            title = anim.label,
            description = anim.command,
            icon = 'fa-solid fa-person-walking',
            onSelect = function()
                playEmote(anim)
            end,
        })
    end

    table.insert(contextData.options, {
        title = 'Cancel Emote',
        description = 'Stop current animation',
        icon = 'fa-solid fa-ban',
        onSelect = function()
            stopEmote()
        end,
    })

    lib.registerContext(contextData)
    lib.showContext(contextData.id)
end

--- Open walk style selector
local function openWalkStyles()
    local contextData = {
        id = 'anim_menu_walks',
        title = 'Walking Styles',
        menu = 'anim_menu_root',
        options = {},
    }

    for _, style in ipairs(Config.WalkStyles) do
        table.insert(contextData.options, {
            title = style.label,
            description = style.reset and 'Reset to default' or ('Style: ' .. style.style),
            icon = 'fa-solid fa-person-walking',
            onSelect = function()
                setWalkStyle(style)
            end,
        })
    end

    lib.registerContext(contextData)
    lib.showContext(contextData.id)
end

--- Stop all animations (for radial menu)
local function cancelEmoteAction()
    stopEmote()
    ClearFacialIdleAnimOverride(PlayerPedId())
    exports.ox_lib:notify({ type = 'info', description = 'All animations stopped' })
end

--- Register radial menu event handlers
AddEventHandler('anim-menu:openCategory', function(data)
    local category = data and (data.category or type(data) == 'string' and data or nil)
    if not category then return end
    local items = Config.Emotes[category]
    if items then
        openEmoteCategory(category, items)
    end
end)

AddEventHandler('anim-menu:openWalks', function()
    openWalkStyles()
end)

AddEventHandler('anim-menu:cancelEmote', function()
    cancelEmoteAction()
end)

AddEventHandler('anim-menu:playSpecific', function(emoteCommand)
    for _, cat in pairs(Config.Emotes) do
        for _, anim in ipairs(cat) do
            if anim.command == emoteCommand then
                playEmote(anim)
                return
            end
        end
    end
    exports.ox_lib:notify({ type = 'error', description = 'Unknown emote: ' .. emoteCommand })
end)

--- Commands
RegisterCommand('cancel', function()
    cancelEmoteAction()
end, false)

RegisterCommand('anim', function(_, args)
    if args and args[1] then
        TriggerEvent('anim-menu:playSpecific', args[1])
    else
        TriggerEvent('anim-menu:openCategory', 'Actions')
    end
end, false)

--- Cleanup on resource stop
AddEventHandler('onClientResourceStop', function(res)
    if res == GetCurrentResourceName() then
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        ClearPedSecondaryTask(ped)
        ClearFacialIdleAnimOverride(ped)
        ResetPedMovementClipset(ped, 0.0)
    end
end)

--- Exports
exports('PlayEmote', function(command)
    for _, cat in pairs(Config.Emotes) do
        for _, anim in ipairs(cat) do
            if anim.command == command then
                playEmote(anim)
                return true
            end
        end
    end
    return false
end)

exports('StopEmote', stopEmote)
exports('SetWalkStyle', function(styleName)
    for _, style in ipairs(Config.WalkStyles) do
        if style.label:lower() == styleName:lower() then
            setWalkStyle(style)
            return true
        end
    end
    return false
end)
