Config = Config or {}
Config.Taxi = {
    driverJob = 'taxi',
    baseFare = 3.50,
    perMileRate = 2.00,
    tipBaseMultiplier = 1.0,
    tipMaxMultiplier = 1.5,
    smoothBonus = 2.0,

    dispatchLocations = {
        { name = 'LS International Airport', coords = vector3(-1040.0, -2750.0, 14.0) },
        { name = 'Downtown LS Depot', coords = vector3(895.0, -180.0, 74.0) },
        { name = 'Sandy Shores Station', coords = vector3(1502.0, 3921.0, 31.0) },
        { name = 'Paleto Bay Stand', coords = vector3(-167.0, 6470.0, 32.0) },
        { name = 'Vespucci Beach', coords = vector3(-1210.0, -1510.0, 4.0) },
        { name = 'Mirror Park', coords = vector3(1180.0, -330.0, 69.0) },
    },

    npcFareRoutes = {
        { pickup = { name = 'Airport', coords = vector3(-1040.0, -2750.0, 14.0) }, dropoff = { name = 'Downtown', coords = vector3(250.0, -750.0, 30.0) }, distance = 8.5 },
        { pickup = { name = 'Downtown', coords = vector3(250.0, -750.0, 30.0) }, dropoff = { name = 'Airport', coords = vector3(-1040.0, -2750.0, 14.0) }, distance = 8.5 },
        { pickup = { name = 'Sandy Shores', coords = vector3(1502.0, 3921.0, 31.0) }, dropoff = { name = 'Paleto Bay', coords = vector3(-167.0, 6470.0, 32.0) }, distance = 25.0 },
        { pickup = { name = 'Paleto Bay', coords = vector3(-167.0, 6470.0, 32.0) }, dropoff = { name = 'Sandy Shores', coords = vector3(1502.0, 3921.0, 31.0) }, distance = 25.0 },
        { pickup = { name = 'Vespucci', coords = vector3(-1210.0, -1510.0, 4.0) }, dropoff = { name = 'Mirror Park', coords = vector3(1180.0, -330.0, 69.0) }, distance = 12.0 },
        { pickup = { name = 'Rockford Hills', coords = vector3(-750.0, -30.0, 43.0) }, dropoff = { name = 'Airport', coords = vector3(-1040.0, -2750.0, 14.0) }, distance = 14.0 },
        { pickup = { name = 'La Mesa', coords = vector3(800.0, -1000.0, 26.0) }, dropoff = { name = 'Sandy Shores', coords = vector3(1502.0, 3921.0, 31.0) }, distance = 22.0 },
    },

    crashThreshold = 15.0,
    maxSpeedLimit = 60.0,
    smoothAccelDelta = 3.0,
}
