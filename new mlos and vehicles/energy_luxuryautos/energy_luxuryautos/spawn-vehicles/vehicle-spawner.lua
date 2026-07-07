local REQUEST_TIMEOUT   = 5000
local SPAWN_DISTANCE    = 50.0
local DESPAWN_DISTANCE  = 65.0
local POLL_INTERVAL     = 1000
local ROTATION_SPEED    = 20.0
local BONE_RETRY_DELAY  = 250

local MLO_ORIGIN = vector3(-789.337341, -221.439163, 49.32575)
local MLO_QUAT   = { x = 0.004213052, y = -0.00113519, z = 0.2601649, w = 0.9655544 }

local HEIGHT_LOWER = 36.9684
local HEIGHT_UPPER = 43.9134

local PROP = {
    big    = { model = "energy_c_conce_giro",      bone = "energy_conce_giro",      rotates = true  },
    mini   = { model = "energy_c_conce_mini_giro", bone = "energy_conce_mini_giro", rotates = true  },
    static = { model = "energy_c_conce_static_g",  bone = nil,                      rotates = false },
}

local LAYOUT = {
    { type = "big",    floor = "lower", height =  0.60, rel = vector3(-5.746121,  -11.7101183, -13.0072927) },
    { type = "big",    floor = "lower", height =  0.60, rel = vector3(-5.746121,    1.96964347, -13.0072927) },
    { type = "mini",   floor = "lower", height =  0.56, rel = vector3(-9.948801,   -1.1618613,  -13.0101194) },
    { type = "mini",   floor = "lower", height =  0.40, rel = vector3(-9.948801,   -8.705504,   -13.0101194) },
    { type = "static",                  height =  0.00, world = vector3(-800.994, -217.969, 36.9684), heading = 134.81 },
    { type = "static",                  height = -0.28, world = vector3(-803.050, -213.796, 37.0048), heading = 135.02 },
    { type = "static",                  height =  0.01, world = vector3(-791.957, -212.935, 37.0121), heading = 103.86 },
    { type = "static",                  height = -0.15, world = vector3(-794.703, -208.654, 37.0488), heading = 104.29 },
    { type = "big",    floor = "upper", height =  0.58, rel = vector3(-1.431704, -22.5035419,  -6.27428436) },
    { type = "big",    floor = "upper", height =  0.33, rel = vector3( 7.38866472, -23.518692, -6.285261)  },
    { type = "mini",   floor = "upper", height =  0.54, rel = vector3(-9.74408,  -10.0474682,  -6.273309)  },
    { type = "mini",   floor = "upper", height =  0.54, rel = vector3(-9.74408,    0.0,        -6.273309)  },
    { type = "mini",   floor = "upper", height =  0.58, rel = vector3(-9.74408,    6.35534573, -6.273309)  },
}

local function normalizeQuat(q)
    local len = math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w)
    if len == 0 then return { x = 0, y = 0, z = 0, w = 1 } end
    return { x = q.x / len, y = q.y / len, z = q.z / len, w = q.w / len }
end

local NQUAT = normalizeQuat(MLO_QUAT)

local function rotateByQuat(q, v)
    local tx = 2 * (q.y * v.z - q.z * v.y)
    local ty = 2 * (q.z * v.x - q.x * v.z)
    local tz = 2 * (q.x * v.y - q.y * v.x)
    return vector3(
        v.x + q.w * tx + (q.y * tz - q.z * ty),
        v.y + q.w * ty + (q.z * tx - q.x * tz),
        v.z + q.w * tz + (q.x * ty - q.y * tx)
    )
end

local MLO_HEADING = math.deg(math.atan(
    2 * (NQUAT.w * NQUAT.z + NQUAT.x * NQUAT.y),
    1 - 2 * (NQUAT.y * NQUAT.y + NQUAT.z * NQUAT.z)
))

local SPOTS = {}

local function buildSpots()
    if #Config.PLATFORMS ~= #LAYOUT then
        print(("[showroom] Config has %d platforms but layout has %d. They must match.")
            :format(#Config.PLATFORMS, #LAYOUT))
    end
    for i, cfg in ipairs(Config.PLATFORMS) do
        local lay = LAYOUT[i]
        if lay then
            local prop = PROP[lay.type]
            local search
            if lay.world then
                search = lay.world
            else
                local w  = MLO_ORIGIN + rotateByQuat(NQUAT, lay.rel)
                local hz = (lay.floor == "upper") and HEIGHT_UPPER or HEIGHT_LOWER
                search   = vector3(w.x, w.y, hz)
            end
            SPOTS[i] = {
                car     = cfg.car,
                color   = cfg.color or 0,
                plate   = cfg.plate or "PDM",
                height  = lay.height or 0.0,
                heading = lay.heading or 0.0,
                prop    = prop.model,
                bone    = prop.bone,
                rotates = prop.rotates,
                world   = lay.world,
                search  = search,
            }
        end
    end
end

local function loadModel(model)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local startTime = GetGameTimer()
    while GetGameTimer() - startTime < REQUEST_TIMEOUT do
        if HasModelLoaded(model) then return true end
        Wait(0)
    end
    return false
end

local function createVehicle(spot)
    local model = type(spot.car) == "string" and GetHashKey(spot.car) or spot.car
    if not IsModelValid(model) or not loadModel(model) then return nil end

    local c = spot.search
    RequestCollisionAtCoord(c.x, c.y, c.z)
    local vehicle = CreateVehicle(model, c.x, c.y, c.z, 0.0, false, true)
    SetModelAsNoLongerNeeded(model)
    if not DoesEntityExist(vehicle) then return nil end

    FreezeEntityPosition(vehicle, true)
    SetEntityVisible(vehicle, false, false)
    SetVehicleNumberPlateText(vehicle, spot.plate)
    SetVehicleNumberPlateTextIndex(vehicle, 3)
    SetVehicleColours(vehicle, spot.color, spot.color)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleDoorsLocked(vehicle, 2)
    SetEntityInvincible(vehicle, true)
    return vehicle
end

local function readBone(spot)
    local obj = GetClosestObjectOfType(spot.search.x, spot.search.y, spot.search.z,
        5.0, GetHashKey(spot.prop), false, false, false)
    if obj == 0 then return nil end
    local idx = GetEntityBoneIndexByName(obj, spot.bone)
    if idx == -1 then return nil end
    return GetWorldPositionOfEntityBone(obj, idx)
end

local function spinVehicle(spot)
    if spot.spinning then return end
    spot.spinning = true
    CreateThread(function()
        local bp
        while spot.spinning and spot.entity and DoesEntityExist(spot.entity) do
            RequestCollisionAtCoord(spot.search.x, spot.search.y, spot.search.z)
            bp = readBone(spot)
            if bp then break end
            Wait(BONE_RETRY_DELAY)
        end

        if not bp then
            spot.spinning = false
            return
        end

        local px = bp.x
        local py = bp.y
        local pz = bp.z + spot.height

        if not spot.spinning or not spot.entity or not DoesEntityExist(spot.entity) then
            spot.spinning = false
            return
        end

        SetEntityCoordsNoOffset(spot.entity, px, py, pz, false, false, false)
        SetEntityVisible(spot.entity, true, false)

        while spot.spinning and spot.entity and DoesEntityExist(spot.entity) do
            local angle = (MLO_HEADING + (GetGameTimer() / 1000.0) * ROTATION_SPEED) % 360.0
            SetEntityHeading(spot.entity, angle)
            Wait(0)
        end
        spot.spinning = false
    end)
end

local function placeStatic(spot)
    SetEntityCoordsNoOffset(spot.entity,
        spot.world.x, spot.world.y, spot.world.z + spot.height,
        false, false, false)
    SetEntityHeading(spot.entity, spot.heading % 360.0)
    FreezeEntityPosition(spot.entity, true)
    SetEntityVisible(spot.entity, true, false)
end

local function deleteVehicle(spot)
    spot.spinning = false
    spot.placed   = false
    if spot.entity and DoesEntityExist(spot.entity) then
        SetEntityAsMissionEntity(spot.entity, true, true)
        DeleteVehicle(spot.entity)
    end
    spot.entity = nil
end

CreateThread(function()
    buildSpots()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, spot in ipairs(SPOTS) do
            local hasCar = spot.car and spot.car ~= ""
            local dist   = #(playerCoords - spot.search)

            if hasCar and dist <= SPAWN_DISTANCE then
                if not spot.entity or not DoesEntityExist(spot.entity) then
                    spot.entity   = createVehicle(spot)
                    spot.spinning = false
                    spot.placed   = false
                end
                if spot.entity then
                    if spot.rotates then
                        spinVehicle(spot)
                    elseif not spot.placed then
                        placeStatic(spot)
                        spot.placed = true
                    end
                end
            elseif spot.entity and dist > DESPAWN_DISTANCE then
                deleteVehicle(spot)
            end
        end
        Wait(POLL_INTERVAL)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, spot in ipairs(SPOTS) do deleteVehicle(spot) end
end)
