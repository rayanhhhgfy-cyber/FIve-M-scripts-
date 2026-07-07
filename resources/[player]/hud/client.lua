local QBox = exports['qbx_core']:GetCoreObject()
local PlayerData = QBox.Functions.GetPlayerData()
local speedMultiplier = Config.UseMPH and 2.23694 or 3.6
local seatbeltOn = false
local cruiseOn = false
local showAltitude = false
local showSeatbelt = false
local nos = 0
local stress = 0
local hunger = 100
local thirst = 100
local cashAmount = 0
local bankAmount = 0
local nitroActive = 0
local harness = 0
local hp = 100
local armed = 0
local parachute = -1
local oxygen = 100
local dev = false
local playerDead = false
local showMenu = false
local showCircleB = false
local showSquareB = false
local Menu = Config.Menu
local CinematicHeight = 0.2
local w = 0
local radioActive = false

DisplayRadar(false)

local function CinematicShow(bool)
    SetBigmapActive(true, false)
    Wait(0)
    SetBigmapActive(false, false)
    if bool then
        for i = CinematicHeight, 0, -1.0 do Wait(10) w = i end
    else
        for i = 0, CinematicHeight, 1.0 do Wait(10) w = i end
    end
end

local function loadSettings(settings)
    for k, v in pairs(settings) do
        if k == 'isToggleMapShapeChecked' then
            Menu.isToggleMapShapeChecked = v
            SendNUIMessage({ test = true, event = k, toggle = v })
        elseif k == 'isCinematicModeChecked' then
            Menu.isCinematicModeChecked = v
            CinematicShow(v)
            SendNUIMessage({ test = true, event = k, toggle = v })
        elseif k == 'isChangeFPSChecked' then
            Menu[k] = v
            SendNUIMessage({ test = true, event = k, toggle = v and 'Optimized' or 'Synced' })
        else
            Menu[k] = v
            SendNUIMessage({ test = true, event = k, toggle = v })
        end
    end
    exports.ox_lib:notify({ type = 'success', description = 'HUD settings loaded' })
    Wait(1000)
    TriggerEvent('hud:client:LoadMap')
end

local function saveSettings()
    SetResourceKvp('hudSettings', json.encode(Menu))
end

local function hasHarness(items)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end
    local _harness = false
    if items then
        for _, v in pairs(items) do
            if v.name == 'harness' then _harness = true break end
        end
    end
    harness = _harness
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    local hudSettings = GetResourceKvpString('hudSettings')
    if hudSettings then loadSettings(json.decode(hudSettings)) end
    PlayerData = QBox.Functions.GetPlayerData()
    Wait(3000)
    SetEntityHealth(PlayerPedId(), 200)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key ~= 'all' then return end
    PlayerData = val
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(2000)
    local hudSettings = GetResourceKvpString('hudSettings')
    if hudSettings then loadSettings(json.decode(hudSettings)) end
end)

AddEventHandler('pma-voice:radioActive', function(data)
    radioActive = data
end)

RegisterCommand('menu', function()
    Wait(50)
    if showMenu then return end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    showMenu = true
end)

RegisterNUICallback('closeMenu', function(_, cb)
    Wait(50)
    showMenu = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterKeyMapping('menu', 'Open HUD Settings Menu', 'keyboard', Config.OpenMenu)

local function restartHud()
    exports.ox_lib:notify({ type = 'error', description = 'Restarting HUD...' })
    if IsPedInAnyVehicle(PlayerPedId()) then
        Wait(2600)
        SendNUIMessage({ action = 'car', show = false })
        SendNUIMessage({ action = 'car', show = true })
    end
    Wait(2600)
    SendNUIMessage({ action = 'hudtick', show = false })
    SendNUIMessage({ action = 'hudtick', show = true })
    Wait(2600)
    exports.ox_lib:notify({ type = 'success', description = 'HUD restarted' })
end

RegisterNUICallback('restartHud', function(_, cb)
    Wait(50)
    restartHud()
    cb('ok')
end)

RegisterCommand('resethud', function()
    Wait(50)
    restartHud()
end)

RegisterNUICallback('resetStorage', function(_, cb)
    Wait(50)
    TriggerEvent('hud:client:resetStorage')
    cb('ok')
end)

RegisterNetEvent('hud:client:resetStorage', function()
    Wait(50)
    lib.callback('hud:server:getMenu', false, function(menu)
        loadSettings(menu)
        SetResourceKvp('hudSettings', json.encode(menu))
    end)
end)

--- Notification callbacks (menu settings toggles)
local function makeToggleCallback(name)
    return function(_, cb)
        Wait(50)
        Menu[name] = not Menu[name]
        saveSettings()
        cb('ok')
    end
end

RegisterNUICallback('openMenuSounds', makeToggleCallback('isOpenMenuSoundsChecked'))
RegisterNUICallback('resetHudSounds', makeToggleCallback('isResetSoundsChecked'))
RegisterNUICallback('checklistSounds', function(_, cb)
    Wait(50)
    Menu.isListSoundsChecked = not Menu.isListSoundsChecked
    saveSettings()
    cb('ok')
end)
RegisterNUICallback('showOutMap', makeToggleCallback('isOutMapChecked'))
RegisterNUICallback('showOutCompass', makeToggleCallback('isOutCompassChecked'))
RegisterNUICallback('showFollowCompass', makeToggleCallback('isCompassFollowChecked'))
RegisterNUICallback('showMapNotif', makeToggleCallback('isMapNotifChecked'))
RegisterNUICallback('showFuelAlert', makeToggleCallback('isLowFuelChecked'))
RegisterNUICallback('showCinematicNotif', makeToggleCallback('isCinematicNotifChecked'))
RegisterNUICallback('dynamicHealth', makeToggleCallback('isDynamicHealthChecked'))
RegisterNUICallback('dynamicArmor', makeToggleCallback('isDynamicArmorChecked'))
RegisterNUICallback('dynamicHunger', makeToggleCallback('isDynamicHungerChecked'))
RegisterNUICallback('dynamicThirst', makeToggleCallback('isDynamicThirstChecked'))
RegisterNUICallback('dynamicStress', makeToggleCallback('isDynamicStressChecked'))
RegisterNUICallback('dynamicOxygen', makeToggleCallback('isDynamicOxygenChecked'))
RegisterNUICallback('dynamicEngine', makeToggleCallback('isDynamicEngineChecked'))
RegisterNUICallback('dynamicNitro', makeToggleCallback('isDynamicNitroChecked'))
RegisterNUICallback('changeFPS', makeToggleCallback('isChangeFPSChecked'))
RegisterNUICallback('ToggleMapBorders', makeToggleCallback('isToggleMapBordersChecked'))
RegisterNUICallback('showCompassBase', makeToggleCallback('isCompassShowChecked'))
RegisterNUICallback('showStreetsNames', makeToggleCallback('isShowStreetsChecked'))
RegisterNUICallback('showPointerIndex', makeToggleCallback('isPointerShowChecked'))
RegisterNUICallback('showDegreesNum', makeToggleCallback('isDegreesShowChecked'))
RegisterNUICallback('changeCompassFPS', makeToggleCallback('isChangeCompassFPSChecked'))

RegisterNUICallback('HideMap', function(_, cb)
    Wait(50)
    Menu.isHideMapChecked = not Menu.isHideMapChecked
    DisplayRadar(not Menu.isHideMapChecked)
    saveSettings()
    cb('ok')
end)

RegisterNetEvent('hud:client:LoadMap', function()
    Wait(50)
    local defaultAspectRatio = 1920 / 1080
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end
    if Menu.isToggleMapShapeChecked == 'square' then
        RequestStreamedTextureDict('squaremap', false)
        if not HasStreamedTextureDictLoaded('squaremap') then Wait(150) end
        if Menu.isMapNotifChecked then exports.ox_lib:notify({ type = 'info', description = 'Loading square map...' }) end
        SetMinimapClipType(0)
        AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
        AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')
        SetMinimapComponentPosition('minimap', 'L', 'B', 0.0 + minimapOffset, -0.047, 0.1638, 0.183)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0 + minimapOffset, 0.0, 0.128, 0.20)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + minimapOffset, 0.025, 0.262, 0.300)
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetBigmapActive(true, false)
        SetMinimapClipType(0)
        Wait(50)
        SetBigmapActive(false, false)
        if Menu.isToggleMapBordersChecked then showCircleB = false; showSquareB = true end
        Wait(1200)
        if Menu.isMapNotifChecked then exports.ox_lib:notify({ type = 'success', description = 'Square map loaded' }) end
    elseif Menu.isToggleMapShapeChecked == 'circle' then
        RequestStreamedTextureDict('circlemap', false)
        if not HasStreamedTextureDictLoaded('circlemap') then Wait(150) end
        if Menu.isMapNotifChecked then exports.ox_lib:notify({ type = 'info', description = 'Loading circle map...' }) end
        SetMinimapClipType(1)
        AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'circlemap', 'radarmasksm')
        AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'circlemap', 'radarmasksm')
        SetMinimapComponentPosition('minimap', 'L', 'B', -0.0100 + minimapOffset, -0.030, 0.180, 0.258)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.200 + minimapOffset, 0.0, 0.065, 0.20)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.00 + minimapOffset, 0.015, 0.252, 0.338)
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetMinimapClipType(1)
        SetBigmapActive(true, false)
        Wait(50)
        SetBigmapActive(false, false)
        if Menu.isToggleMapBordersChecked then showSquareB = false; showCircleB = true end
        Wait(1200)
        if Menu.isMapNotifChecked then exports.ox_lib:notify({ type = 'success', description = 'Circle map loaded' }) end
    end
end)

RegisterNUICallback('ToggleMapShape', function(_, cb)
    Wait(50)
    if not Menu.isHideMapChecked then
        Menu.isToggleMapShapeChecked = Menu.isToggleMapShapeChecked == 'circle' and 'square' or 'circle'
        Wait(50)
        TriggerEvent('hud:client:LoadMap')
    end
    saveSettings()
    cb('ok')
end)

RegisterNUICallback('cinematicMode', function(_, cb)
    Wait(50)
    if Menu.isCinematicModeChecked then
        CinematicShow(false)
        Menu.isCinematicModeChecked = false
        if Menu.isCinematicNotifChecked then exports.ox_lib:notify({ type = 'error', description = 'Cinematic mode off' }) end
        DisplayRadar(1)
    else
        CinematicShow(true)
        Menu.isCinematicModeChecked = true
        if Menu.isCinematicNotifChecked then exports.ox_lib:notify({ type = 'success', description = 'Cinematic mode on' }) end
    end
    saveSettings()
    cb('ok')
end)

RegisterNetEvent('hud:client:ToggleAirHud', function()
    showAltitude = not showAltitude
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    hunger = newHunger
    thirst = newThirst
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress)
    stress = newStress
end)

RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
    showSeatbelt = not showSeatbelt
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function()
    seatbeltOn = not seatbeltOn
end)

RegisterNetEvent('seatbelt:client:ToggleCruise', function()
    cruiseOn = not cruiseOn
end)

RegisterNetEvent('hud:client:UpdateNitrous', function(nitroLevel, bool)
    nos = nitroLevel
    nitroActive = bool
end)

RegisterNetEvent('hud:client:UpdateHarness', function(harnessHp)
    hp = harnessHp
end)

RegisterNetEvent('qb-admin:client:ToggleDevmode', function()
    dev = not dev
end)

-- Fuel reading: state bag first, native fallback
local function getFuelLevel(vehicle)
    local fuel = Entity(vehicle).state.fuel
    if not fuel then fuel = GetVehicleFuelLevel(vehicle) end
    if not fuel or fuel < 0 then fuel = 100.0 end
    return math.floor(fuel)
end

local prevPlayerStats = {}
local prevVehicleStats = {}
local prevBaseplateStats = {}

local function updatePlayerHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevPlayerStats[k] ~= v then shouldUpdate = true; break end
    end
    prevPlayerStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = 'hudtick', show = data[1],
            dynamicHealth = data[2], dynamicArmor = data[3], dynamicHunger = data[4],
            dynamicThirst = data[5], dynamicStress = data[6], dynamicOxygen = data[7],
            dynamicEngine = data[8], dynamicNitro = data[9],
            health = data[10], playerDead = data[11], armor = data[12],
            thirst = data[13], hunger = data[14], stress = data[15],
            voice = data[16], radio = data[17], talking = data[18],
            armed = data[19], oxygen = data[20], parachute = data[21],
            nos = data[22], cruise = data[23], nitroActive = data[24],
            harness = data[25], hp = data[26], speed = data[27],
            engine = data[28], cinematic = data[29], dev = data[30],
            radioActive = data[31],
        })
    end
end

local function updateVehicleHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevVehicleStats[k] ~= v then shouldUpdate = true; break end
    end
    prevVehicleStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = 'car', show = data[1], isPaused = data[2],
            seatbelt = data[3], speed = data[4], fuel = data[5],
            altitude = data[6], showAltitude = data[7], showSeatbelt = data[8],
            showSquareB = data[9], showCircleB = data[10],
        })
    end
end

-- Main HUD Update Loop
CreateThread(function()
    local wasInVehicle = false
    while true do
        if Menu.isChangeFPSChecked then Wait(500) else Wait(50) end
        if LocalPlayer.state.isLoggedIn then
            local show = true
            local player = PlayerPedId()
            local playerId = PlayerId()
            local weapon = GetSelectedPedWeapon(player)
            if not Config.WhitelistedWeaponArmed[weapon] then armed = weapon ~= `WEAPON_UNARMED` else armed = false end
            playerDead = IsEntityDead(player) or PlayerData.metadata['inlaststand'] or PlayerData.metadata['isdead'] or false
            parachute = GetPedParachuteState(player)
            if not IsEntityInWater(player) then oxygen = 100 - GetPlayerSprintStaminaRemaining(playerId) end
            if IsEntityInWater(player) then oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10 end
            local talking = NetworkIsPlayerTalking(playerId)
            local voice = 0
            if LocalPlayer.state['proximity'] then voice = LocalPlayer.state['proximity'].distance end
            if IsPauseMenuActive() then show = false end
            local vehicle = GetVehiclePedIsIn(player)
            if not (IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle)) then
                updatePlayerHud({
                    show, Menu.isDynamicHealthChecked, Menu.isDynamicArmorChecked,
                    Menu.isDynamicHungerChecked, Menu.isDynamicThirstChecked,
                    Menu.isDynamicStressChecked, Menu.isDynamicOxygenChecked,
                    Menu.isDynamicEngineChecked, Menu.isDynamicNitroChecked,
                    GetEntityHealth(player) - 100, playerDead, GetPedArmour(player),
                    thirst, hunger, stress, voice, LocalPlayer.state['radioChannel'],
                    talking, armed, oxygen, parachute, -1, cruiseOn, nitroActive,
                    harness, hp, math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    -1, Menu.isCinematicModeChecked, dev, radioActive,
                })
            end
            if IsPedInAnyHeli(player) or IsPedInAnyPlane(player) then showAltitude = true; showSeatbelt = false end
            if IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle) then
                if not wasInVehicle then DisplayRadar(true) end
                wasInVehicle = true
                local engineHealth = GetVehicleEngineHealth(vehicle)
                if engineHealth ~= engineHealth then engineHealth = 0 end
                updatePlayerHud({
                    show, Menu.isDynamicHealthChecked, Menu.isDynamicArmorChecked,
                    Menu.isDynamicHungerChecked, Menu.isDynamicThirstChecked,
                    Menu.isDynamicStressChecked, Menu.isDynamicOxygenChecked,
                    Menu.isDynamicEngineChecked, Menu.isDynamicNitroChecked,
                    GetEntityHealth(player) - 100, playerDead, GetPedArmour(player),
                    thirst, hunger, stress, voice, LocalPlayer.state['radioChannel'],
                    talking, armed, oxygen, GetPedParachuteState(player),
                    nos, cruiseOn, nitroActive, harness, hp,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    (engineHealth / 10), Menu.isCinematicModeChecked, dev, radioActive,
                })
                updateVehicleHud({
                    show, IsPauseMenuActive(), seatbeltOn,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    getFuelLevel(vehicle), math.ceil(GetEntityCoords(player).z * 0.5),
                    showAltitude, showSeatbelt, showSquareB, showCircleB,
                })
                showAltitude = false
                showSeatbelt = true
            else
                if wasInVehicle then
                    wasInVehicle = false
                    SendNUIMessage({ action = 'car', show = false, seatbelt = false, cruise = false })
                    seatbeltOn = false
                    cruiseOn = false
                    harness = false
                end
                DisplayRadar(Menu.isOutMapChecked)
            end
        else
            SendNUIMessage({ action = 'hudtick', show = false })
        end
    end
end)

-- Low fuel alert
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) and not IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(ped, false))) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local fuel = getFuelLevel(vehicle)
                if fuel <= 20 and Menu.isLowFuelChecked then
                    exports.ox_lib:notify({ type = 'error', description = 'Low fuel: ' .. fuel .. '%' })
                    Wait(60000)
                end
            end
        end
        Wait(10000)
    end
end)

-- Money HUD
RegisterNetEvent('hud:client:ShowAccounts', function(type, amount)
    amount = math.floor(amount)
    if type == 'cash' then
        SendNUIMessage({ action = 'show', type = 'cash', cash = amount })
    else
        SendNUIMessage({ action = 'show', type = 'bank', bank = amount })
    end
end)

RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, isMinus)
    local money = PlayerData.money or {}
    cashAmount = money.cash or 0
    bankAmount = money.bank or 0
    SendNUIMessage({
        action = 'updatemoney', cash = math.floor(cashAmount), bank = math.floor(bankAmount),
        amount = math.floor(amount), minus = isMinus, type = type
    })
end)

-- Harness check
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            harness = exports.ox_inventory:Search('count', 'harness') > 0
        else
            harness = false
        end
    end
end)

-- Stress gain (speeding + shooting)
if not Config.DisableStress then
    CreateThread(function()
        while true do
            if LocalPlayer.state.isLoggedIn then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local veh = GetVehiclePedIsIn(ped, false)
                    local vehClass = GetVehicleClass(veh)
                    local speed = GetEntitySpeed(veh) * speedMultiplier
                    local vehHash = GetEntityModel(veh)
                    if Config.VehClassStress[tostring(vehClass)] and not Config.WhitelistedVehicles[vehHash] then
                        local stressSpeed = vehClass == 8 and Config.MinimumSpeed or (seatbeltOn and Config.MinimumSpeed or Config.MinimumSpeedUnbuckled)
                        if speed >= stressSpeed then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                end
            end
            Wait(10000)
        end
    end)

    CreateThread(function()
        while true do
            if LocalPlayer.state.isLoggedIn then
                local ped = PlayerPedId()
                local weapon = GetSelectedPedWeapon(ped)
                if weapon ~= `WEAPON_UNARMED` then
                    if IsPedShooting(ped) and not Config.WhitelistedWeaponStress[weapon] then
                        if math.random() < Config.StressChance then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                else Wait(1000) end
            end
            Wait(0)
        end
    end)
end

-- Stress visual effects
local function GetBlurIntensity(stresslevel)
    for _, v in pairs(Config.Intensity['blur']) do
        if stresslevel >= v.min and stresslevel <= v.max then return v.intensity end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    for _, v in pairs(Config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then return v.timeout end
    end
    return 60000
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local effectInterval = GetEffectInterval(stress)
        if stress >= 100 then
            local BlurIntensity = GetBlurIntensity(stress)
            local FallRepeat = math.random(2, 4)
            local RagdollTimeout = FallRepeat * 1750
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)
            if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            end
            Wait(1000)
            for _ = 1, FallRepeat, 1 do
                Wait(750)
                DoScreenFadeOut(200)
                Wait(1000)
                DoScreenFadeIn(200)
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
        elseif stress >= Config.MinimumStress then
            local BlurIntensity = GetBlurIntensity(stress)
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)
        end
        Wait(effectInterval)
    end
end)

-- Minimap update
CreateThread(function()
    while true do
        SetBigmapActive(false, false)
        SetRadarZoom(1000)
        Wait(500)
    end
end)

-- Cinematic black bars
local function BlackBars()
    DrawRect(0.0, 0.0, 2.0, w, 0, 0, 0, 255)
    DrawRect(0.0, 1.0, 2.0, w, 0, 0, 0, 255)
end

CreateThread(function()
    local minimap = RequestScaleformMovie('minimap')
    if not HasScaleformMovieLoaded(minimap) then
        RequestScaleformMovie(minimap)
        while not HasScaleformMovieLoaded(minimap) do Wait(1) end
    end
    while true do
        if w > 0 then
            BlackBars()
            DisplayRadar(0)
            SendNUIMessage({ action = 'hudtick', show = false })
            SendNUIMessage({ action = 'car', show = false })
        end
        Wait(0)
    end
end)

-- Street/Compass loop
local function updateBaseplateHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevBaseplateStats[k] ~= v then shouldUpdate = true; break end
    end
    prevBaseplateStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = 'baseplate', show = data[1], street1 = data[2], street2 = data[3],
            showCompass = data[4], showStreets = data[5], showPointer = data[6], showDegrees = data[7],
        })
    end
end

local lastCrossroadUpdate = 0
local lastCrossroadCheck = {}

local function getCrossroads(player)
    local updateTick = GetGameTimer()
    if updateTick - lastCrossroadUpdate > 1500 then
        local pos = GetEntityCoords(player)
        local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        lastCrossroadUpdate = updateTick
        lastCrossroadCheck = { GetStreetNameFromHashKey(street1), GetStreetNameFromHashKey(street2) }
    end
    return lastCrossroadCheck
end

CreateThread(function()
    local lastHeading = 1
    while true do
        if Menu.isChangeCompassFPSChecked then Wait(50) else Wait(0) end
        if LocalPlayer.state.isLoggedIn then
            local show = true
            local player = PlayerPedId()
            local camRot = GetGameplayCamRot(0)
            local heading
            if Menu.isCompassFollowChecked then
                heading = tostring(math.floor(360.0 - ((camRot.z + 360.0) % 360.0) + 0.5))
            else
                heading = tostring(math.floor(360.0 - GetEntityHeading(player) + 0.5))
            end
            if heading == '360' then heading = '0' end
            if heading ~= tostring(lastHeading) then
                if IsPedInAnyVehicle(player) then
                    local crossroads = getCrossroads(player)
                    SendNUIMessage({ action = 'update', value = heading })
                    updateBaseplateHud({ show, crossroads[1], crossroads[2], Menu.isCompassShowChecked, Menu.isShowStreetsChecked, Menu.isPointerShowChecked, Menu.isDegreesShowChecked })
                else
                    if Menu.isOutCompassChecked then
                        SendNUIMessage({ action = 'update', value = heading })
                        SendNUIMessage({ action = 'baseplate', show = true, showCompass = true })
                    else
                        SendNUIMessage({ action = 'baseplate', show = false })
                    end
                end
            end
            lastHeading = tonumber(heading)
        end
    end
end)