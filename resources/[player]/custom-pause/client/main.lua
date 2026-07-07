local QBox = exports['qbx_core']:GetCoreObject()
local pauseOpen = false
local lastEsc = 0
local stats = { playTime = 0, deaths = 0, arrests = 0 }

--- BINDING MANAGER ---
local currentBindings = {}
local rebindingTarget = nil
local rebindingThread = nil

local function defaultBindings()
    local t = {}
    for _, b in ipairs(Config.Bindings) do
        t[b.name] = { vk = b.default, control = b.control }
    end
    return t
end

local function initBindings()
    currentBindings = defaultBindings()
    local data = GetResourceKvpString('custom_pause_bindings')
    if data then
        local ok, saved = pcall(json.decode, data)
        if ok and type(saved) == 'table' then
            for name, v in pairs(saved) do
                if currentBindings[name] then
                    currentBindings[name] = v
                end
            end
        end
    end
end

local function saveBindings()
    SetResourceKvpString('custom_pause_bindings', json.encode(currentBindings))
end

function GetBinding(name)
    if currentBindings[name] then
        return currentBindings[name].vk, currentBindings[name].control
    end
    for _, b in ipairs(Config.Bindings) do
        if b.name == name then return b.default, b.control end
    end
    return nil, nil
end

function IsBindingPressed(name)
    local vk, control = GetBinding(name)
    if vk then
        return IsKeyPressed(vk) or (control and IsControlJustPressed(0, control))
    end
    return false
end

exports('GetBinding', GetBinding)
exports('IsBindingPressed', IsBindingPressed)
exports('GetAllBindings', function() return currentBindings end)
exports('ResetAllBindings', function()
    currentBindings = defaultBindings()
    saveBindings()
    return currentBindings
end)
exports('SetBinding', function(name, vk)
    if currentBindings[name] then
        currentBindings[name].vk = vk
        saveBindings()
        return true
    end
    return false
end)

local function getKeyName(vk)
    local name = Config.KeyNames[vk]
    if name then return name end
    if vk >= 65 and vk <= 90 then return string.char(vk) end
    return 'KEY#' .. vk
end

local function startRebindListener()
    if rebindingThread then return end
    rebindingThread = Citizen.CreateThread(function()
        local time = GetGameTimer()
        while rebindingTarget and GetGameTimer() - time < 5000 do
            Citizen.Wait(0)
            for vk = 1, 255 do
                if IsKeyPressed(vk) and GetGameTimer() - time > 200 then
                    rebindingThread = nil
                    local name = getKeyName(vk)
                    currentBindings[rebindingTarget].vk = vk
                    currentBindings[rebindingTarget].control = nil
                    saveBindings()
                    local target = rebindingTarget
                    rebindingTarget = nil
                    if pauseOpen then
                        SendNUIMessage({ action = 'bindComplete', binding = target, key = name, vk = vk })
                    end
                    return
                end
            end
            Citizen.Wait(10)
        end
        rebindingTarget = nil
        rebindingThread = nil
        if pauseOpen then
            SendNUIMessage({ action = 'bindTimedOut' })
        end
    end)
end

initBindings()

--- PAUSE MENU ---
local function getPlayerData()
    local p = QBox.Functions.GetPlayerData()
    if not p or not p.charinfo then return nil end
    local name = (p.charinfo.firstname or '') .. ' ' .. (p.charinfo.lastname or '')
    return {
        citizenid = p.citizenid or '',
        name = name,
        phone = p.charinfo.phone or '',
        job = {
            name = p.job and p.job.label or 'Unemployed',
            grade = p.job and p.job.grade and p.job.grade.name or '',
            onduty = p.job and p.job.onduty or false,
            payment = p.job and p.job.payment or 0,
        },
        money = {
            cash = p.money and p.money.cash or 0,
            bank = p.money and p.money.bank or 0,
        },
    }
end

local function getServerInfo()
    local weather = 'EXTRASUNNY'
    local time = { hour = 12, minute = 0 }
    local success, w = pcall(function() return exports['weathersync']:GetWeather() end)
    if success then weather = w end
    local success2, t = pcall(function() return exports['weathersync']:GetTime() end)
    if success2 then time = t end
    local count = 0
    pcall(function() count = #GetPlayers() end)
    local uptime = GetGameTimer()
    local hours = math.floor(uptime / 3600000)
    local mins = math.floor((uptime % 3600000) / 60000)
    return {
        weather = weather,
        hour = time.hour,
        minute = time.minute,
        players = count,
        uptime = ('%dh %dm'):format(hours, mins),
    }
end

local function getQuickActions()
    local p = QBox.Functions.GetPlayerData()
    local onduty = p and p.job and p.job.onduty or false
    return { onduty = onduty }
end

local function getBindingsForNUI()
    local list = {}
    for _, b in ipairs(Config.Bindings) do
        local vk = currentBindings[b.name] and currentBindings[b.name].vk or b.default
        table.insert(list, { name = b.name, label = b.label, key = getKeyName(vk), vk = vk })
    end
    return list
end

function openPauseMenu()
    if pauseOpen then return end
    pauseOpen = true
    local pd = getPlayerData()
    local si = getServerInfo()
    local qa = getQuickActions()
    local binds = getBindingsForNUI()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openPause', player = pd, server = si, actions = qa, stats = stats, bindings = binds })
end

function closePauseMenu()
    if not pauseOpen then return end
    pauseOpen = false
    rebindingTarget = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closePause' })
end

RegisterNUICallback('pauseResume', function(_, cb)
    closePauseMenu()
    cb('ok')
end)

RegisterNUICallback('pauseToggleDuty', function(_, cb)
    local p = QBox.Functions.GetPlayerData()
    if p and p.job then
        local newState = not p.job.onduty
        p.Functions.SetJobDuty(newState)
        TriggerServerEvent('QBCore:ToggleDuty')
        cb({ onduty = newState })
    else
        cb({ onduty = false })
    end
    Citizen.SetTimeout(200, function() openPauseMenu() end)
end)

RegisterNUICallback('pauseDisconnect', function(_, cb)
    closePauseMenu()
    Citizen.Wait(200)
    TriggerServerEvent('player:disconnect')
    cb('ok')
end)

RegisterNUICallback('startRebind', function(data, cb)
    if rebindingTarget then
        cb({ ok = false, reason = 'already rebinding' })
        return
    end
    for _, b in ipairs(Config.Bindings) do
        if b.name == data.binding then
            rebindingTarget = data.binding
            startRebindListener()
            cb({ ok = true })
            return
        end
    end
    cb({ ok = false, reason = 'not found' })
end)

RegisterNUICallback('resetBindings', function(_, cb)
    currentBindings = defaultBindings()
    saveBindings()
    local binds = getBindingsForNUI()
    cb({ bindings = binds })
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsPauseMenuActive() then
            ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_EMPTY'), false, -1)
        end
        if IsControlJustPressed(0, Config.Pause.toggleKey) and GetGameTimer() - lastEsc > 400 then
            lastEsc = GetGameTimer()
            if pauseOpen then
                closePauseMenu()
            elseif not IsNuiFocused() then
                openPauseMenu()
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if GetCurrentResourceName() == r and pauseOpen then SetNuiFocus(false, false) end
end)
