local stretcherObj = nil
local stretcherNetId = nil
local isPushing = false
local patientOnStretcher = false

local function spawnStretcher(coords, heading)
    lib.requestModel(Config.Stretcher.model)
    local obj = CreateObject(Config.Stretcher.model, coords.x, coords.y, coords.z - 0.5, false, true, false)
    SetEntityHeading(obj, heading)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, true, true)
    stretcherObj = obj
    stretcherNetId = ObjToNet(obj)
    createStretcherTarget()
    return obj
end

local function createStretcherTarget()
    if not stretcherObj or not DoesEntityExist(stretcherObj) then return end
    exports.ox_target:addLocalEntity(stretcherObj, {
        {
            name = 'stretcher_fold',
            label = 'Fold Stretcher',
            icon = 'fas fa-compress',
            distance = 2.5,
            onSelect = function()
                if patientOnStretcher then
                    exports.ox_lib:notify({ type = 'error', description = 'Remove patient first' })
                    return
                end
                if isPushing then
                    isPushing = false
                end
                if stretcherObj and DoesEntityExist(stretcherObj) then
                    DeleteObject(stretcherObj)
                end
                stretcherObj = nil
                stretcherNetId = nil
                TriggerServerEvent('stretcher-system:server:fold')
                exports.ox_lib:notify({ type = 'info', description = 'Stretcher folded' })
            end
        },
        {
            name = 'stretcher_load',
            label = 'Load into Ambulance',
            icon = 'fas fa-ambulance',
            distance = 5.0,
            canInteract = function()
                local ped = cache.ped
                local coords = GetEntityCoords(ped)
                local veh = lib.getClosestVehicle(coords, 6.0, true)
                if not veh then return false end
                local model = GetEntityModel(veh)
                for _, m in ipairs(Config.Stretcher.ambulanceModels) do
                    if model == m then return true end
                end
                return false
            end,
            onSelect = function()
                local ped = cache.ped
                local coords = GetEntityCoords(ped)
                local veh = lib.getClosestVehicle(coords, 6.0, true)
                if not veh then
                    exports.ox_lib:notify({ type = 'error', description = 'No ambulance nearby' })
                    return
                end
                local heading = GetEntityHeading(veh)
                local offset = Config.Stretcher.loadOffset
                local loadPos = GetOffsetFromEntityInWorldCoords(veh, offset.x, offset.y, offset.z)
                SetEntityCoords(stretcherObj, loadPos.x, loadPos.y, loadPos.z)
                FreezeEntityPosition(stretcherObj, true)
                AttachEntityToEntity(stretcherObj, veh, -1, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                exports.ox_lib:notify({ type = 'success', description = 'Stretcher loaded into ambulance' })
            end
        },
    })
end

function useStretcher()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    spawnStretcher(coords, heading)
    exports.ox_lib:notify({ type = 'success', description = 'Stretcher deployed' })
end

exports('useStretcher', useStretcher)
