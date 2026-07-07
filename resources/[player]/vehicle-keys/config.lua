Config = Config or {}

Config.VehicleKeys = {
    lockRange = 8.0,
    giveKeyRange = 3.0,
    lockpickDifficulty = {
        [0] = 0.50,  -- Coupes
        [1] = 0.50,  -- Sedans
        [2] = 0.45,  -- SUVs
        [3] = 0.50,  -- Coupes
        [4] = 0.45,  -- Muscle
        [5] = 0.40,  -- Sports Classics
        [6] = 0.35,  -- Sports
        [7] = 0.30,  -- Super
        [8] = 0.55,  -- Motorcycles
        [9] = 0.45,  -- Off-road
        [10] = 0.40, -- Industrial
        [11] = 0.45, -- Utility
        [12] = 0.45, -- Vans
        [13] = 0.55, -- Cycles
        [14] = 0.40, -- Boats
        [15] = 0.35, -- Helicopters
        [16] = 0.35, -- Planes
        [17] = 0.40, -- Service
        [18] = 0.35, -- Emergency
        [19] = 0.30, -- Military
        [20] = 0.40, -- Commercial
        [21] = 0.55, -- Trains
    },
    lockpickRounds = 4,
    maxLockpickFails = 3,
    lockpickAlarmChance = 0.60,
    needleSpeed = 0.75,
    minSweetSpot = 0.12,
    maxSweetSpot = 0.35,
    lockpickAnim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loob_mechandplayer' },
    lockpickTime = 2000,
    lockedDoorStates = {
        [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true,
    },
}
