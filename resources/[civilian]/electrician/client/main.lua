local isOnJob = false
local currentStop = 1
local currentVehicle = nil
local isBusy = false
local repairedCount = 0

local function spawnVan()
    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
    end

    local model = joaat(Config.VanModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(100)
    end

    currentVehicle = CreateVehicle(model, Config.Spawn.x, Config.Spawn.y, Config.Spawn.z, 0.0, true, false)
    SetVehicleNumberPlateText(currentVehicle, 'ELECTRIC')
    TaskWarpPedIntoVehicle(cache.ped, currentVehicle, -1)
    SetModelAsNoLongerNeeded(model)
end

local function setJobGPS()
    ClearGpsMultiRoute()
    SetGpsMultiRoute(true)
    StartGpsMultiRoute(6, true, true)
    for _, coord in ipairs(Config.RepairLocations) do
        AddPointToGpsMultiRoute(coord.x, coord.y, coord.z)
    end
    AddPointToGpsMultiRoute(Config.Depot.x, Config.Depot.y, Config.Depot.z)
    SetGpsMultiRoute(false)
end

local function hasRepairKit()
    local item = exports.ox_inventory:Search('count', Config.ToolItem)
    return item and item >= 1
end

local function removeRepairKit()
    exports.ox_inventory:RemoveItem(cache.ped, Config.ToolItem, 1)
end

local function startJob()
    if isOnJob then
        return lib.notify({ title = 'Already Working', description = 'Complete your current jobs first.', type = 'error' })
    end

    if not hasRepairKit() then
        return lib.notify({ title = 'Missing Tools', description = 'You need a ' .. Config.ToolItem .. ' to start.', type = 'error' })
    end

    isOnJob = true
    currentStop = 1
    repairedCount = 0
    spawnVan()
    setJobGPS()
    TriggerServerEvent('electrician:startJob')

    lib.notify({
        title = 'Electrician',
        description = 'Drive to each repair location and fix the electrical panels. Each repair uses one repair kit.',
        type = 'info',
        duration = 5000,
    })
end

local function repairPanel()
    if isBusy then return end
    isBusy = true

    if not hasRepairKit() then
        isBusy = false
        return lib.notify({ title = 'No Tools', description = 'You need a ' .. Config.ToolItem .. ' to repair this panel.', type = 'error' })
    end

    local coords = GetEntityCoords(cache.ped)
    local target = Config.RepairLocations[currentStop]

    if #(coords - target) > 5.0 then
        isBusy = false
        return lib.notify({ title = 'Too Far', description = 'Get closer to the panel.', type = 'error' })
    end

    TaskTurnPedToFaceCoord(cache.ped, target.x, target.y, 500)

    local panelPos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 0.8, -0.5)
    local panelObj = CreateObject(joaat('prop_elecbox_01a'), panelPos.x, panelPos.y, panelPos.z, true, false, false)
    SetEntityHeading(panelObj, GetEntityHeading(cache.ped))
    FreezeEntityPosition(panelObj, true)

    lib.requestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
    TaskPlayAnim(cache.ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'idle_a', 8.0, -8.0, Config.RepairTime, 49, 0, false, false, false)

    local skillSuccess = lib.skillCheck({'easy', 'easy', 'medium'}, {'w'})

    ClearPedTasks(cache.ped)

    if panelObj and DoesEntityExist(panelObj) then
        DeleteObject(panelObj)
    end

    if not skillSuccess then
        isBusy = false
        return lib.notify({ title = 'Failed', description = 'You messed up the repair. Try again.', type = 'error' })
    end

    local barSuccess = lib.progressCircle({
        duration = Config.RepairTime,
        position = 'bottom',
        label = 'Repairing electrical panel...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
    })

    if barSuccess then
        removeRepairKit()
        repairedCount = repairedCount + 1
        currentStop = currentStop + 1

        TriggerServerEvent('electrician:completeJob', currentStop - 1)

        if currentStop > #Config.RepairLocations then
            lib.notify({
                title = 'All Repairs Complete',
                description = 'Return to the depot to collect your payment!',
                type = 'success',
            })
            ClearGpsMultiRoute()
            SetNewWaypoint(Config.Depot.x, Config.Depot.y)
        else
            lib.notify({
                title = 'Panel Repaired',
                description = repairedCount .. '/' .. #Config.RepairLocations .. ' completed.',
                type = 'success',
            })
        end
    end

    isBusy = false
end

local function collectPayment()
    if isBusy then return end

    if currentStop <= #Config.RepairLocations then
        return lib.notify({ title = 'Incomplete', description = 'Repair all panels before collecting payment.', type = 'error' })
    end

    local coords = GetEntityCoords(cache.ped)
    if #(coords - Config.Depot) > 10.0 then
        return lib.notify({ title = 'Wrong Location', description = 'Return to the depot.', type = 'error' })
    end

    isBusy = true

    local success = lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        label = 'Collecting payment...',
        useWhileDead = false,
        canCancel = false,
        disableMovement = true,
        disableCarMovement = true,
    })

    if success then
        local totalPayment = repairedCount * Config.PaymentPerJob
        TriggerServerEvent('electrician:collectPayment', repairedCount, totalPayment)

        isOnJob = false
        currentStop = 1
        repairedCount = 0
        ClearGpsMultiRoute()

        if currentVehicle and DoesEntityExist(currentVehicle) then
            DeleteVehicle(currentVehicle)
            currentVehicle = nil
        end

        lib.notify({
            title = 'Payment Collected',
            description = 'You earned $' .. totalPayment .. ' for ' .. repairedCount .. ' repairs.',
            type = 'success',
        })
    end

    isBusy = false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isOnJob and not isBusy then
            local coords = GetEntityCoords(cache.ped)

            if currentStop <= #Config.RepairLocations then
                local target = Config.RepairLocations[currentStop]
                if #(coords - target) < 5.0 then
                    lib.showTextUI('[E] Repair Electrical Panel')
                    if IsControlJustPressed(0, 38) then
                        repairPanel()
                    end
                else
                    lib.hideTextUI()
                end
            end

            if currentStop > #Config.RepairLocations and #(coords - Config.Depot) < 10.0 then
                lib.showTextUI('[E] Collect Payment')
                if IsControlJustPressed(0, 38) then
                    collectPayment()
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)

local depotZone = lib.target.addZone({
    coords = Config.Depot,
    size = vec3(4.0, 4.0, 2.0),
    debug = false,
    options = {
        {
            name = 'start_electrician',
            label = 'Start Electrical Work',
            onSelect = startJob,
            icon = 'fas fa-bolt',
            canInteract = function()
                return not isOnJob
            end,
        }
    }
})

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if depotZone then
            lib.target.removeZone(depotZone)
        end
    end
end)
