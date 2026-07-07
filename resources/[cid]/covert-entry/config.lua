Config = Config or {}
Config.CovertEntry = Config.CovertEntry or {}

Config.CovertEntry = {
    AllowedJobs = { 'cid' },
    MinRank = 1,
    Cooldown = 30000,
    PlantEvidenceChance = 80,

    Lockpick = {
        duration = 4000,
        minigameDifficulty = 'medium',
        jamDuration = 30000,
        vehicleDuration = 5000,
    },

    AlarmBypass = {
        duration = 5000,
        bypassDuration = 60000,
        maxAttempts = 3,
    },

    FailAutoDispatch = true,

    DoorModels = {
        'v_ilev_ph_gendoor',
        'v_ilev_ph_gendoor2',
        'v_ilev_ph_door01',
        'v_ilev_ph_door02',
        'v_ilev_ph_door03',
        'v_ilev_bankdoors',
        'v_ilev_fib_door1',
        'v_ilev_fib_door2',
        'prop_door4_door',
        'prop_door3_door',
    },

    AlarmModels = {
        'v_ilev_ph_gendoor',
        'v_ilev_bankdoors',
        'v_ilev_fib_door1',
    },
}
