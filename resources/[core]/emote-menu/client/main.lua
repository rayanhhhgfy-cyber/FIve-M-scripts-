local isEmoteActive = false
local currentEmote = nil
local emoteMenuOpen = false
local favoriteEmotes = {}

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = 50
    while not HasAnimDictLoaded(dict) do
        timeout = timeout - 1
        if timeout <= 0 then return false end
        Citizen.Wait(10)
    end
    return true
end

local function playEmote(emoteData)
    stopEmote()
    if not loadAnimDict(emoteData.dict) then
        Wrappers.Notify('Emote', 'Failed to load animation', 'error')
        return
    end
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    Citizen.Wait(100)
    local flags = emoteData.duration == -1 and 1 or 0
    TaskPlayAnim(ped, emoteData.dict, emoteData.anim, 8.0, -8.0, emoteData.duration, flags, 0, false, false, false)
    RemoveAnimDict(emoteData.dict)
    isEmoteActive = true
    currentEmote = emoteData
end

function stopEmote()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    isEmoteActive = false
    currentEmote = nil
end

exports('playEmote', playEmote)
exports('stopEmote', stopEmote)

local function openEmoteMenu()
    if emoteMenuOpen then return end
    emoteMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openEmoteMenu',
        data = {
            categories = Config.Emotes,
            favorites = favoriteEmotes
        }
    })
end

local function closeEmoteMenu()
    if not emoteMenuOpen then return end
    emoteMenuOpen = false
    SetNuiFocus(false, false)
end

RegisterNUICallback('emotePlay', function(data, cb)
    local category = data.category
    local emoteName = data.name
    for _, emote in ipairs(Config.Emotes[category]) do
        if emote.name == emoteName then
            playEmote(emote)
            closeEmoteMenu()
            break
        end
    end
    cb({})
end)

RegisterNUICallback('emoteStop', function(_, cb)
    stopEmote()
    cb({})
end)

RegisterNUICallback('emoteFavorite', function(data, cb)
    local emoteKey = data.category .. '|' .. data.name
    if data.favorited then
        favoriteEmotes[emoteKey] = true
    else
        favoriteEmotes[emoteKey] = nil
    end
    cb({})
end)

RegisterNUICallback('emoteClose', function(_, cb)
    closeEmoteMenu()
    cb({})
end)

RegisterNUICallback('emoteGetFavorites', function(_, cb)
    cb(favoriteEmotes)
end)

RegisterCommand(Config.EmoteOpenCommand, function()
    openEmoteMenu()
end, false)

RegisterCommand(Config.EmoteOpenCommandAlt, function()
    openEmoteMenu()
end, false)

RegisterKeyMapping('+' .. Config.EmoteOpenCommand, 'Open Emote Menu', 'keyboard', Config.EmoteKeybind)

RegisterCommand('+emotemenu', function()
    openEmoteMenu()
end, false)

RegisterCommand('cancel', function()
    stopEmote()
    Wrappers.Notify('Emote', 'Animation cancelled', 'info')
end, false)

RegisterCommand('e', function()
    stopEmote()
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isEmoteActive and IsControlJustPressed(0, 73) then
            stopEmote()
        end
        if isEmoteActive and IsControlJustPressed(0, 38) then
            stopEmote()
        end
    end
end)

if Config.EnableRagdollCancel then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(100)
            if isEmoteActive and IsPedRagdoll(PlayerPedId()) then
                stopEmote()
            end
        end
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    stopEmote()
    closeEmoteMenu()
end)
