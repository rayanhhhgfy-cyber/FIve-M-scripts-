local myProps = {}
local myCounts = { cones = 0, barriers = 0 }

local function placeProp(itemName, model)
    local ped = cache.ped
    local ok = lib.callback.await('road-deployables:server:canPlace', false, itemName)
    if not ok then
        local max = itemName == 'traffic_cone' and Config.RoadDeployables.maxCones or Config.RoadDeployables.maxBarriers
        exports.ox_lib:notify({ type = 'error', description = 'Max ' .. max .. ' placed already' })
        return
    end
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = GetEntityForwardVector(ped)
    local placePos = coords + forward * 2.0
    lib.requestModel(model)
    local obj = CreateObject(model, placePos.x, placePos.y, placePos.z - 0.5, false, true, false)
    SetEntityHeading(obj, heading)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, true, true)
    local netId = ObjToNet(obj)
    local key = itemName == 'traffic_cone' and 'cones' or 'barriers'
    myCounts[key] = myCounts[key] + 1
    local propId = #myProps + 1
    myProps[propId] = { obj = obj, netId = netId, item = itemName }
    TriggerServerEvent('road-deployables:server:confirmPlace', itemName, netId)
    exports.ox_target:addLocalEntity(obj, {
        {
            name = 'pickup_' .. propId,
            label = 'Pick Up ' .. (itemName == 'traffic_cone' and 'Cone' or 'Barrier'),
            icon = 'fas fa-hand',
            distance = 2.5,
            onSelect = function()
                if DoesEntityExist(obj) then
                    DeleteObject(obj)
                end
                myProps[propId] = nil
                myCounts[key] = math.max(0, myCounts[key] - 1)
                TriggerServerEvent('road-deployables:server:pickup', itemName)
                exports.ox_lib:notify({ type = 'info', description = 'Picked up' })
            end
        }
    })
end

function useTrafficCone()
    placeProp('traffic_cone', Config.RoadDeployables.models.traffic_cone)
end

function useBarrier()
    placeProp('barrier', Config.RoadDeployables.models.barrier)
end

exports('useTrafficCone', useTrafficCone)
exports('useBarrier', useBarrier)
