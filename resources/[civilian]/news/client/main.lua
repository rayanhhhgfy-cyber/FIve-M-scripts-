local isOnShift = false
local currentVan = nil
local currentBroadcast = nil
local hasCamera = false
local hasMic = false
local isBroadcasting = false
local broadcastCooldown = false
local playerPed = PlayerPedId()

local function Notify(msg, type)
    lib.notify({ title = 'News', description = msg, type = type or 'info' })
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
    end
end

local function SpawnVan()
    if currentVan and DoesEntityExist(currentVan) then
        Notify('Van already deployed', 'error')
        return false
    end
    if not IsModelInCdimage(Config.VanModel) or not IsModelAVehicle(Config.VanModel) then
        Notify('Invalid van model', 'error')
        return false
    end
    RequestModel(Config.VanModel)
    local attempts = 0
    while not HasModelLoaded(Config.VanModel) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if not HasModelLoaded(Config.VanModel) then
        Notify('Failed to load van model', 'error')
        return false
    end
    currentVan = CreateVehicle(Config.VanModel, Config.VanSpawn.x, Config.VanSpawn.y, Config.VanSpawn.z, Config.VanSpawnHeading, true, false)
    SetVehicleNumberPlateText(currentVan, 'NEWS' .. tostring(math.random(100, 999)))
    SetVehicleColours(currentVan, 131, 131)
    TaskWarpPedIntoVehicle(playerPed, currentVan, -1)
    SetModelAsNoLongerNeeded(Config.VanModel)
    Notify('News van deployed!', 'success')
    return true
end

local function ReturnVan()
    if not currentVan or not DoesEntityExist(currentVan) then
        Notify('No van to return', 'error')
        return
    end
    DeleteVehicle(currentVan)
    currentVan = nil
    Notify('Van returned', 'success')
end

local function EquipCamera()
    if hasCamera then
        Notify('Camera already equipped', 'info')
        return
    end
    local Player = exports.ox_lib:GetPlayer()
    if not Player then return end
    if not Player.Functions.GetItemByName(Config.Equipment.camera) then
        Notify('You need a news camera', 'error')
        return
    end
    hasCamera = true
    Notify('Camera equipped', 'success')
end

local function EquipMic()
    if hasMic then
        Notify('Mic already equipped', 'info')
        return
    end
    local Player = exports.ox_lib:GetPlayer()
    if not Player then return end
    if not Player.Functions.GetItemByName(Config.Equipment.mic) then
        Notify('You need a news microphone', 'error')
        return
    end
    hasMic = true
    Notify('Microphone equipped', 'success')
end

local function UnequipCamera()
    if not hasCamera then return end
    hasCamera = false
    if IsPedUsingAnyScenario(playerPed) then
        ClearPedTasks(playerPed)
    end
    Notify('Camera unequipped', 'info')
end

local function UnequipMic()
    if not hasMic then return end
    hasMic = false
    Notify('Microphone unequipped', 'info')
end

local function StartBroadcast(location)
    if isBroadcasting then
        Notify('Already broadcasting', 'error')
        return
    end
    if broadcastCooldown then
        Notify('Broadcast on cooldown', 'error')
        return
    end
    if not hasCamera or not hasMic then
        Notify('Equip both camera and mic first', 'error')
        return
    end
    local playerPos = GetEntityCoords(playerPed)
    local dist = #(playerPos - location.coords)
    if dist > 10.0 then
        Notify('Get closer to the broadcast location', 'error')
        return
    end
    isBroadcasting = true
    currentBroadcast = location
    LoadAnimDict(Config.CameraAnim.dict)
    LoadAnimDict(Config.MicAnim.dict)
    TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_PAPARAZZI', 0, true)
    local camProp = CreateObject(GetHashKey(Config.CameraAnim.prop), 0, 0, 0, true, true, true)
    AttachEntityToEntity(camProp, playerPed, GetPedBoneIndex(playerPed, 28422), 0.1, 0.05, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    local micProp = CreateObject(GetHashKey(Config.MicAnim.prop), 0, 0, 0, true, true, true)
    AttachEntityToEntity(micProp, playerPed, GetPedBoneIndex(playerPed, 60302), 0.1, 0.03, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    -- Show a progress bar instead of an on-screen prompt
    Citizen.Wait(1000)

    lib.progressBar({
        duration = Config.BroadcastDuration,
        label = 'Broadcasting live from ' .. location.name,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = Config.CameraAnim.dict,
            clip = Config.CameraAnim.clip,
            flags = 49
        }
    }, function(cancelled)
        if cancelled then
            Notify('Broadcast cancelled', 'warning')
        else
            Notify('Broadcast complete!', 'success')
            TriggerServerEvent('news:server:completeBroadcast', location.name)
            broadcastCooldown = true
            Citizen.SetTimeout(Config.MinBroadcastInterval, function()
                broadcastCooldown = false
            end)
        end
        if DoesEntityExist(camProp) then
            DeleteEntity(camProp)
        end
        if DoesEntityExist(micProp) then
            DeleteEntity(micProp)
        end
        ClearPedTasks(playerPed)
        isBroadcasting = false
        currentBroadcast = nil
    end)
end

local function StartShift()
    if isOnShift then
        Notify('Already on shift', 'error')
        return
    end
    TriggerServerEvent('news:server:startShift')
end

local function EndShift()
    if not isOnShift then
        Notify('Not on shift', 'error')
        return
    end
    if isBroadcasting then
        Notify('Finish your broadcast first', 'error')
        return
    end
    UnequipCamera()
    UnequipMic()
    ReturnVan()
    TriggerServerEvent('news:server:endShift')
end

RegisterNetEvent('news:client:startShift', function()
    isOnShift = true
    if SpawnVan() then
        Notify('News shift started! Head to broadcast locations.', 'success')
        local blips = {}
        for _, loc in ipairs(Config.BroadcastLocations) do
            local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
            SetBlipSprite(blip, 311)
            SetBlipColour(blip, 3)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(loc.name)
            EndTextCommandSetBlipName(blip)
            table.insert(blips, blip)
        end
        Citizen.CreateThread(function()
            while isOnShift do
                Citizen.Wait(0)
                for _, loc in ipairs(Config.BroadcastLocations) do
                    DrawText3D(loc.coords.x, loc.coords.y, loc.coords.z + 1.0, '~b~Broadcast:~w~ ' .. loc.name)
                end
                if currentVan and DoesEntityExist(currentVan) then
                    local vanPos = GetEntityCoords(currentVan)
                    DrawText3D(vanPos.x, vanPos.y, vanPos.z + 2.0, '~b~News Van')
                end
            end
            for _, blip in ipairs(blips) do
                RemoveBlip(blip)
            end
        end)
    else
        isOnShift = false
        TriggerServerEvent('news:server:endShift')
    end
end)

RegisterNetEvent('news:client:endShift', function()
    isOnShift = false
    Notify('Shift ended', 'info')
end)

RegisterNetEvent('news:client:forceEndShift', function()
    if isBroadcasting then
        isBroadcasting = false
        ClearPedTasks(playerPed)
    end
    hasCamera = false
    hasMic = false
    if currentVan and DoesEntityExist(currentVan) then
        DeleteVehicle(currentVan)
        currentVan = nil
    end
    isOnShift = false
    Notify('Shift forcefully ended', 'error')
end)

exports.ox_target:addSphereZone({
    coords = Config.VanSpawn,
    radius = 3.0,
    debug = false,
    options = {
        {
            name = 'news_start_shift',
            label = 'Start News Shift',
            icon = 'fas fa-newspaper',
            distance = 2.5,
            canInteract = function()
                return not isOnShift
            end,
            onSelect = function()
                StartShift()
            end
        },
        {
            name = 'news_end_shift',
            label = 'End News Shift',
            icon = 'fas fa-stop-circle',
            distance = 2.5,
            canInteract = function()
                return isOnShift
            end,
            onSelect = function()
                EndShift()
            end
        },
        {
            name = 'news_return_van',
            label = 'Return Van',
            icon = 'fas fa-truck',
            distance = 2.5,
            canInteract = function()
                return isOnShift and currentVan and DoesEntityExist(currentVan)
            end,
            onSelect = function()
                ReturnVan()
            end
        },
        {
            name = 'news_spawn_van',
            label = 'Spawn Van',
            icon = 'fas fa-truck',
            distance = 2.5,
            canInteract = function()
                return isOnShift and (not currentVan or not DoesEntityExist(currentVan))
            end,
            onSelect = function()
                SpawnVan()
            end
        },
        {
            name = 'news_equip_camera',
            label = 'Equip Camera',
            icon = 'fas fa-camera',
            distance = 2.5,
            canInteract = function()
                return isOnShift and not hasCamera
            end,
            onSelect = function()
                EquipCamera()
            end
        },
        {
            name = 'news_equip_mic',
            label = 'Equip Microphone',
            icon = 'fas fa-microphone',
            distance = 2.5,
            canInteract = function()
                return isOnShift and not hasMic
            end,
            onSelect = function()
                EquipMic()
            end
        },
        {
            name = 'news_unequip_camera',
            label = 'Unequip Camera',
            icon = 'fas fa-camera-slash',
            distance = 2.5,
            canInteract = function()
                return isOnShift and hasCamera
            end,
            onSelect = function()
                UnequipCamera()
            end
        },
        {
            name = 'news_unequip_mic',
            label = 'Unequip Microphone',
            icon = 'fas fa-microphone-slash',
            distance = 2.5,
            canInteract = function()
                return isOnShift and hasMic
            end,
            onSelect = function()
                UnequipMic()
            end
        }
    }
})

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isOnShift and not isBroadcasting then
            if IsControlJustPressed(0, 38) then
                local playerPos = GetEntityCoords(playerPed)
                for _, loc in ipairs(Config.BroadcastLocations) do
                    local dist = #(playerPos - loc.coords)
                    if dist < 10.0 then
                        StartBroadcast(loc)
                        break
                    end
                end
            end
        end
        if isOnShift and isBroadcasting then
            local playerPos = GetEntityCoords(playerPed)
            if currentBroadcast then
                DrawText3D(currentBroadcast.coords.x, currentBroadcast.coords.y, currentBroadcast.coords.z + 2.0, '~b~Broadcasting Live~w~ at ' .. currentBroadcast.name)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if currentVan and DoesEntityExist(currentVan) then
            DeleteVehicle(currentVan)
        end
        if isBroadcasting then
            ClearPedTasks(playerPed)
        end
    end
end)
