local QBox = exports['qbx_core']:GetCoreObject()
local PlayerData = QBox.Functions.GetPlayerData()
local inRadialMenu = false

local jobIndex = nil
local vehicleIndex = nil

local DynamicMenuItems = {}
local FinalMenuItems = {}
local controlsToToggle = { 24, 0, 1, 2, 142, 257, 346 }

local controlThreadRunning = false

local function controlToggle(bool)
    if bool then
        if not controlThreadRunning then
            controlThreadRunning = true
            CreateThread(function()
                while controlThreadRunning do
                    for i = 1, #controlsToToggle do
                        DisableControlAction(0, controlsToToggle[i], true)
                    end
                    Wait(0)
                end
            end)
        end
    else
        controlThreadRunning = false
    end
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if not orig.canOpen or orig.canOpen() then
            local toRemove = {}
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                if type(orig_value) == 'table' then
                    if not orig_value.canOpen or orig_value.canOpen() then
                        copy[deepcopy(orig_key)] = deepcopy(orig_value)
                    else
                        toRemove[orig_key] = true
                    end
                else
                    copy[deepcopy(orig_key)] = deepcopy(orig_value)
                end
            end
            for i = 1, #toRemove do table.remove(copy, i) end
            if copy and next(copy) then setmetatable(copy, deepcopy(getmetatable(orig))) end
        end
    elseif orig_type ~= 'function' then
        copy = orig
    end
    return copy
end

local function getNearestVeh()
    local pos = GetEntityCoords(PlayerPedId())
    local entityWorld = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 20.0, 0.0)
    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, PlayerPedId(), 0)
    local _, _, _, _, vehicleHandle = GetRaycastResult(rayHandle)
    return vehicleHandle
end

local function AddOption(data, id)
    local menuID = id ~= nil and id or (#DynamicMenuItems + 1)
    DynamicMenuItems[menuID] = deepcopy(data)
    DynamicMenuItems[menuID].res = GetInvokingResource()
    return menuID
end

local function RemoveOption(id)
    DynamicMenuItems[id] = nil
end

local function SetupJobMenu()
    local JobInteractionCheck = PlayerData.job.name
    if PlayerData.job.type == 'leo' then JobInteractionCheck = 'police' end
    local JobMenu = {
        id = 'jobinteractions',
        title = 'Work',
        icon = 'briefcase',
        items = {}
    }
    if Config.JobInteractions[JobInteractionCheck] and next(Config.JobInteractions[JobInteractionCheck]) and PlayerData.job.onduty then
        JobMenu.items = Config.JobInteractions[JobInteractionCheck]
    end

    if #JobMenu.items == 0 then
        if jobIndex then
            RemoveOption(jobIndex)
            jobIndex = nil
        end
    else
        jobIndex = AddOption(JobMenu, jobIndex)
    end
end

local function SetupVehicleMenu()
    local VehicleMenu = {
        id = 'vehicle',
        title = 'Vehicle',
        icon = 'car',
        items = {}
    }

    local ped = PlayerPedId()
    local Vehicle = GetVehiclePedIsIn(ped) ~= 0 and GetVehiclePedIsIn(ped) or getNearestVeh()
    if Vehicle ~= 0 then
        VehicleMenu.items[#VehicleMenu.items + 1] = Config.VehicleDoors
        if Config.EnableExtraMenu then VehicleMenu.items[#VehicleMenu.items + 1] = Config.VehicleExtras end

        if not IsVehicleOnAllWheels(Vehicle) then
            VehicleMenu.items[#VehicleMenu.items + 1] = {
                id = 'vehicle-flip',
                title = 'Flip Vehicle',
                icon = 'car-burst',
                type = 'client',
                event = 'qb-radialmenu:flipVehicle',
                shouldClose = true
            }
        end

        if IsPedInAnyVehicle(ped) then
            local seatIndex = #VehicleMenu.items + 1
            VehicleMenu.items[seatIndex] = deepcopy(Config.VehicleSeats)

            local seatTable = {
                [1] = 'Drivers Seat',
                [2] = 'Passenger Seat',
                [3] = 'Rear Left Seat',
                [4] = 'Rear Right Seat',
            }

            local AmountOfSeats = GetVehicleModelNumberOfSeats(GetEntityModel(Vehicle))
            for i = 1, AmountOfSeats do
                local newIndex = #VehicleMenu.items[seatIndex].items + 1
                VehicleMenu.items[seatIndex].items[newIndex] = {
                    id = i - 2,
                    title = seatTable[i] or 'Other Seat',
                    icon = 'caret-up',
                    type = 'client',
                    event = 'qb-radialmenu:client:ChangeSeat',
                    shouldClose = false,
                }
            end
        end
    end

    if #VehicleMenu.items == 0 then
        if vehicleIndex then
            RemoveOption(vehicleIndex)
            vehicleIndex = nil
        end
    else
        vehicleIndex = AddOption(VehicleMenu, vehicleIndex)
    end
end

local function SetupSubItems()
    SetupJobMenu()
    SetupVehicleMenu()
end

local function selectOption(t, t2)
    for _, v in pairs(t) do
        if v.items then
            local found, hasAction, val = selectOption(v.items, t2)
            if found then return true, hasAction, val end
        else
            if v.id == t2.id and ((v.event and v.event == t2.event) or v.action) and (not v.canOpen or v.canOpen()) then
                return true, v.action, v
            end
        end
    end
    return false
end

local function IsPoliceOrEMS()
    return (PlayerData.job.name == 'police' or PlayerData.job.type == 'leo' or PlayerData.job.name == 'ambulance')
end

local function IsDowned()
    return (PlayerData.metadata['isdead'] or PlayerData.metadata['inlaststand'])
end

local function SetupRadialMenu()
    FinalMenuItems = {}
    if (IsDowned() and IsPoliceOrEMS()) then
        FinalMenuItems = {
            [1] = {
                id = 'emergencybutton2',
                title = 'Emergency Button',
                icon = 'circle-exclamation',
                type = 'client',
                event = 'police:client:SendPoliceEmergencyAlert',
                shouldClose = true,
            },
        }
    else
        SetupSubItems()
        FinalMenuItems = deepcopy(Config.MenuItems)
        for _, v in pairs(DynamicMenuItems) do
            FinalMenuItems[#FinalMenuItems + 1] = v
        end
    end
end

local function setRadialState(bool, sendMessage, delay)
    if Config.UseWhilstWalking then
        if bool then
            TriggerEvent('qb-radialmenu:client:onRadialmenuOpen')
            SetupRadialMenu()
            PlaySoundFrontend(-1, 'NAV', 'HUD_AMMO_SHOP_SOUNDSET', 1)
            controlToggle(true)
        else
            TriggerEvent('qb-radialmenu:client:onRadialmenuClose')
            controlToggle(false)
        end
        SetNuiFocus(bool, bool)
        SetNuiFocusKeepInput(bool, true)
    else
        if bool then
            TriggerEvent('qb-radialmenu:client:onRadialmenuOpen')
            SetupRadialMenu()
        else
            TriggerEvent('qb-radialmenu:client:onRadialmenuClose')
        end
        SetNuiFocus(bool, bool)
    end

    if sendMessage then
        SendNUIMessage({
            action = 'ui',
            radial = bool,
            items = FinalMenuItems,
            toggle = Config.Toggle,
            keybind = Config.Keybind
        })
    end
    if delay then Wait(500) end
    inRadialMenu = bool
end

RegisterCommand('radialmenu', function()
    if ((IsDowned() and IsPoliceOrEMS()) or not IsDowned()) and not PlayerData.metadata['ishandcuffed'] and not IsPauseMenuActive() and not inRadialMenu then
        setRadialState(true, true)
        SetCursorLocation(0.5, 0.5)
    end
end)

RegisterKeyMapping('radialmenu', 'Open Radial Menu', 'keyboard', Config.Keybind)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key ~= 'all' then return end
    PlayerData = val
end)

RegisterNetEvent('qb-radialmenu:client:noPlayers', function()
    exports.ox_lib:notify({ type = 'error', description = 'No players nearby' })
end)

RegisterNetEvent('qb-radialmenu:client:openDoor', function(data)
    local string = data.id
    local replace = string:gsub('door', '')
    local door = tonumber(replace)
    local ped = PlayerPedId()
    local closestVehicle = GetVehiclePedIsIn(ped) ~= 0 and GetVehiclePedIsIn(ped) or getNearestVeh()
    if closestVehicle ~= 0 then
        if closestVehicle ~= GetVehiclePedIsIn(ped) then
            local plate = GetVehicleNumberPlateText(closestVehicle)
            if GetVehicleDoorAngleRatio(closestVehicle, door) > 0.0 then
                if not IsVehicleSeatFree(closestVehicle, -1) then
                    TriggerServerEvent('qb-radialmenu:trunk:server:Door', false, plate, door)
                else
                    SetVehicleDoorShut(closestVehicle, door, false)
                end
            else
                if not IsVehicleSeatFree(closestVehicle, -1) then
                    TriggerServerEvent('qb-radialmenu:trunk:server:Door', true, plate, door)
                else
                    SetVehicleDoorOpen(closestVehicle, door, false, false)
                end
            end
        else
            if GetVehicleDoorAngleRatio(closestVehicle, door) > 0.0 then
                SetVehicleDoorShut(closestVehicle, door, false)
            else
                SetVehicleDoorOpen(closestVehicle, door, false, false)
            end
        end
    else
        exports.ox_lib:notify({ type = 'error', description = 'No vehicle found' })
    end
end)

RegisterNetEvent('qb-radialmenu:client:setExtra', function(data)
    local string = data.id
    local replace = string:gsub('extra', '')
    local extra = tonumber(replace)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped)
    if veh ~= nil then
        if GetPedInVehicleSeat(veh, -1) == ped then
            SetVehicleAutoRepairDisabled(veh, true)
            if DoesExtraExist(veh, extra) then
                if IsVehicleExtraTurnedOn(veh, extra) then
                    SetVehicleExtra(veh, extra, 1)
                    exports.ox_lib:notify({ type = 'error', description = 'Extra ' .. extra .. ' has been deactivated' })
                else
                    SetVehicleExtra(veh, extra, 0)
                    exports.ox_lib:notify({ type = 'success', description = 'Extra ' .. extra .. ' has been activated' })
                end
            else
                exports.ox_lib:notify({ type = 'error', description = 'Extra ' .. extra .. ' is not present on this vehicle' })
            end
        else
            exports.ox_lib:notify({ type = 'error', description = "You're not the driver of the vehicle" })
        end
    end
end)

RegisterNetEvent('qb-radialmenu:trunk:client:Door', function(plate, door, open)
    local veh = GetVehiclePedIsIn(PlayerPedId())
    if veh ~= 0 then
        local pl = GetVehicleNumberPlateText(veh)
        if pl == plate then
            if open then
                SetVehicleDoorOpen(veh, door, false, false)
            else
                SetVehicleDoorShut(veh, door, false)
            end
        end
    end
end)

RegisterNetEvent('qb-radialmenu:client:ChangeSeat', function(data)
    local Veh = GetVehiclePedIsIn(PlayerPedId())
    local IsSeatFree = IsVehicleSeatFree(Veh, data.id)
    local speed = GetEntitySpeed(Veh)
    local HasHarness = exports.ox_inventory:Search('count', 'harness') > 0
    if not HasHarness then
        local kmh = speed * 3.6
        if IsSeatFree then
            if kmh <= 100.0 then
                SetPedIntoVehicle(PlayerPedId(), Veh, data.id)
                exports.ox_lib:notify({ description = 'You are now on the ' .. data.title })
            else
                exports.ox_lib:notify({ type = 'error', description = 'This vehicle is going too fast' })
            end
        else
            exports.ox_lib:notify({ type = 'error', description = 'This seat is occupied' })
        end
    else
        exports.ox_lib:notify({ type = 'error', description = "You have a race harness on, you can't switch" })
    end
end)

RegisterNetEvent('qb-radialmenu:radio:frequencies', function()
    local job = PlayerData.job
    local jobChannels = {
        police = { { label = 'LSPD Main', channel = 1 }, { label = 'LSPD Secondary', channel = 2 }, { label = 'LSPD Tactical', channel = 3 }, { label = 'LSPD Air', channel = 9 }, { label = 'LSPD Events', channel = 10 } },
        cid = { { label = 'CID Main', channel = 4 }, { label = 'CID Tactical', channel = 5 } },
        ambulance = { { label = 'EMS Main', channel = 6 }, { label = 'EMS Secondary', channel = 7 }, { label = 'EMS Tactical', channel = 8 } },
    }

    local channels = jobChannels[job.name]
    if channels and job.onduty then
        local options = {}
        for _, ch in ipairs(channels) do
            options[#options + 1] = { label = ch.label .. ' (' .. ch.channel .. ')', channel = ch.channel }
        end
        options[#options + 1] = { label = 'Custom Frequency', channel = 'custom' }

        local selected = lib.inputDialog('Radio Frequencies', {
            { type = 'select', label = 'Select Frequency', options = options, required = true },
        })

        if selected then
            local ch = tonumber(selected[1])
            if ch then
                TriggerEvent('qb-radio:connectToChannel', ch)
            else
                local custom = lib.inputDialog('Custom Frequency', {
                    { type = 'number', label = 'Channel (1-500)', min = 1, max = 500, required = true },
                })
                if custom then
                    TriggerEvent('qb-radio:connectToChannel', custom[1])
                end
            end
        end
    else
        local input = lib.inputDialog('Radio Frequency', {
            { type = 'number', label = 'Channel (1-500)', min = 1, max = 500, required = true },
        })
        if input then
            TriggerEvent('qb-radio:connectToChannel', input[1])
        end
    end
end)

RegisterNetEvent('qb-radialmenu:flipVehicle', function()
    local success = exports.ox_lib:progressBar({
        duration = Config.Fliptime,
        label = 'Flipping vehicle...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true,
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped',
            flag = 1,
        },
    })
    if success then
        local vehicle = getNearestVeh()
        SetVehicleOnGroundProperly(vehicle)
        StopAnimTask(PlayerPedId(), 'mini@repair', 'fixing_a_ped', 1.0)
    else
        exports.ox_lib:notify({ type = 'error', description = 'Task canceled' })
        StopAnimTask(PlayerPedId(), 'mini@repair', 'fixing_a_ped', 1.0)
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    for k, v in pairs(DynamicMenuItems) do
        if v.res == resource then
            DynamicMenuItems[k] = nil
        end
    end
end)

RegisterNUICallback('closeRadial', function(data, cb)
    setRadialState(false, false, data.delay)
    cb('ok')
end)

RegisterNUICallback('selectItem', function(inData, cb)
    local itemData = inData.itemData
    local found, action, data = selectOption(FinalMenuItems, itemData)
    if data and found then
        if action then
            action(data)
        elseif data.type == 'client' then
            TriggerEvent(data.event, data)
        elseif data.type == 'server' then
            TriggerServerEvent(data.event, data)
        elseif data.type == 'command' then
            ExecuteCommand(data.event)
        elseif data.type == 'qbcommand' then
            TriggerServerEvent('QBox:CallCommand', data.event, data)
        end
    end
    cb('ok')
end)

exports('AddOption', AddOption)
exports('RemoveOption', RemoveOption)
