local QBCore = exports['qbx_core']:GetCoreObject()
local currentEmote = nil
local currentWalkingStyle = nil
local emoteProps = {}

function ClearEmote()
    if currentEmote then
        ClearPedTasks(PlayerPedId())
        for _, prop in ipairs(emoteProps) do
            if DoesEntityExist(prop) then
                DeleteEntity(prop)
            end
        end
        emoteProps = {}
        currentEmote = nil
    end
end

function PlayEmote(emoteName)
    ClearEmote()
    local emote = Emotes.List[emoteName]
    if not emote then
        Wrappers.Notify({ type = 'error', description = 'Emote not found' })
        return
    end
    local ped = PlayerPedId()
    local dict = emote.dict
    local clip = emote.clip
    local flag = emote.flag or 0
    RequestAnimDict(dict)
    local attempts = 0
    while not HasAnimDictLoaded(dict) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if not HasAnimDictLoaded(dict) then
        Wrappers.Notify({ type = 'error', description = 'Animation failed to load' })
        return
    end
    TaskPlayAnim(ped, dict, clip, 8.0, 1.0, -1, flag, 0, false, false, false)
    if emote.prop then
        local propModel = GetHashKey(emote.prop)
        RequestModel(propModel)
        local attempts = 0
        while not HasModelLoaded(propModel) and attempts < 100 do
            Citizen.Wait(10)
            attempts = attempts + 1
        end
        if HasModelLoaded(propModel) then
            local prop = CreateObject(propModel, 0, 0, 0, true, true, true)
            local bone = GetPedBoneIndex(ped, emote.propBone or 28422)
            AttachEntityToEntity(prop, ped, bone, 0, 0, 0, 0, 0, 0, true, true, false, true, 2, true)
            table.insert(emoteProps, prop)
            SetModelAsNoLongerNeeded(propModel)
        end
    end
    currentEmote = emoteName
end

function SetWalkingStyle(styleName)
    local ped = PlayerPedId()
    if styleName == 'default' or not styleName then
        ResetPedMovementClipset(ped, 1.0)
        currentWalkingStyle = nil
        Wrappers.Notify({ type = 'info', description = 'Walking style: Default' })
        return
    end
    local style = Emotes.WalkingStyles[styleName]
    if not style then
        Wrappers.Notify({ type = 'error', description = 'Walking style not found' })
        return
    end
    local clipSet = style.style
    RequestClipSet(clipSet)
    local attempts = 0
    while not HasClipSetLoaded(clipSet) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if HasClipSetLoaded(clipSet) then
        SetPedMovementClipset(ped, clipSet, 1.0)
        currentWalkingStyle = styleName
        Wrappers.Notify({ type = 'success', description = 'Walking style: ' .. style.label })
    end
end

local function OpenEmoteMenu()
    local options = {}
    local categories = {
        social = { label = 'Social', emotes = { 'drink', 'smoke', 'cigar', 'phone' } },
        idle = { label = 'Idle', emotes = { 'sitting', 'leaning', 'crossarms' } },
        actions = { label = 'Actions', emotes = { 'surrender', 'handsup', 'kneel', 'flex', 'meditate' } },
        exercise = { label = 'Exercise', emotes = { 'pushup', 'situp', 'yoga' } },
        dance = { label = 'Dance', emotes = { 'dance', 'dance2', 'dance3', 'airguitar' } },
        props = { label = 'Props', emotes = { 'book', 'binoculars', 'camera', 'selfie', 'fishing', 'cleaning', 'weld' } }
    }
    for catId, cat in pairs(categories) do
        table.insert(options, {
            title = cat.label,
            icon = 'fas fa-circle',
            onSelect = function()
                local subOptions = {}
                for _, emoteName in ipairs(cat.emotes) do
                    local emote = Emotes.List[emoteName]
                    if emote then
                        table.insert(subOptions, {
                            title = emote.label,
                            icon = 'fas fa-running',
                            onSelect = function()
                                PlayEmote(emoteName)
                            end
                        })
                    end
                end
                table.insert(subOptions, {
                    title = 'Stop Emote',
                    icon = 'fas fa-stop',
                    onSelect = function()
                        ClearEmote()
                    end
                })
                lib.registerContext({
                    id = 'emote_sub_' .. catId,
                    title = cat.label,
                    options = subOptions,
                    onBack = function() OpenEmoteMenu() end
                })
                lib.showContext('emote_sub_' .. catId)
            end
        })
    end
    table.insert(options, {
        title = 'Walking Styles',
        icon = 'fas fa-walking',
        onSelect = function()
            local styleOptions = {}
            for styleName, style in pairs(Emotes.WalkingStyles) do
                table.insert(styleOptions, {
                    title = style.label,
                    icon = 'fas fa-person-walking',
                    onSelect = function()
                        SetWalkingStyle(styleName)
                    end
                })
            end
            lib.registerContext({
                id = 'walking_style_menu',
                title = 'Walking Styles',
                options = styleOptions,
                onBack = function() OpenEmoteMenu() end
            })
            lib.showContext('walking_style_menu')
        end
    })
    table.insert(options, {
        title = 'Shared Emotes',
        icon = 'fas fa-handshake',
        onSelect = function()
            local sharedOptions = {}
            for emoteName, emote in pairs(Emotes.Shared) do
                table.insert(sharedOptions, {
                    title = emote.label,
                    icon = 'fas fa-users',
                    onSelect = function()
                        local closest = exports['ox_lib']:getClosestPlayer(GetEntityCoords(PlayerPedId()), Config.Emotes.sharedEmoteDistance)
                        if closest then
                            local target = GetPlayerServerId(closest)
                            TriggerServerEvent('dp-emotes:server:playShared', target, emoteName)
                        else
                            Wrappers.Notify({ type = 'error', description = 'No player nearby' })
                        end
                    end
                })
            end
            lib.registerContext({
                id = 'shared_emote_menu',
                title = 'Shared Emotes',
                options = sharedOptions,
                onBack = function() OpenEmoteMenu() end
            })
            lib.showContext('shared_emote_menu')
        end
    })
    lib.registerContext({
        id = 'emote_main_menu',
        title = 'Emotes',
        options = options
    })
    lib.showContext('emote_main_menu')
end

RegisterNetEvent('dp-emotes:client:playShared', function(target, emote, role)
    local emoteData = role == 'initiator' and emote or { dict = emote.targetDict, clip = emote.targetClip }
    local ped = PlayerPedId()
    local dict = emoteData.dict or emote.dict
    local clip = emoteData.clip or emote.clip
    RequestAnimDict(dict)
    local attempts = 0
    while not HasAnimDictLoaded(dict) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, clip, 8.0, 1.0, -1, 0, 0, false, false, false)
    end
end)

RegisterNetEvent('dp-emotes:client:cancelShared', function()
    ClearEmote()
end)

RegisterCommand(Config.Emotes.emoteCommand, function(source, args)
    if not args[1] then
        OpenEmoteMenu()
        return
    end
    local emoteName = args[1]
    if emoteName == 'cancel' then
        ClearEmote()
        return
    end
    PlayEmote(emoteName)
end, false)

RegisterCommand(Config.Emotes.walkingCommand, function(source, args)
    if not args[1] then
        local options = {}
        for styleName, style in pairs(Emotes.WalkingStyles) do
            table.insert(options, { value = styleName, label = style.label })
        end
        local input = lib.inputDialog('Walking Style', {
            { type = 'select', label = 'Style', options = options }
        })
        if input then
            SetWalkingStyle(input[1])
        end
        return
    end
    SetWalkingStyle(args[1])
end, false)

RegisterCommand(Config.Emotes.cancelCommand, function()
    ClearEmote()
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if currentEmote then
            local ped = PlayerPedId()
            if Config.Emotes.cancelEmoteOnVehicle and IsPedInAnyVehicle(ped, false) then
                ClearEmote()
            end
            if Config.Emotes.cancelEmoteOnCombat and IsPedInMeleeCombat(ped) then
                ClearEmote()
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[dp-emotes] Client emote system ready.^7')
end)

exports('PlayEmote', PlayEmote)
exports('ClearEmote', ClearEmote)
exports('SetWalkingStyle', SetWalkingStyle)
exports('GetCurrentEmote', function() return currentEmote end)
exports('GetCurrentWalk', function() return currentWalkingStyle end)
