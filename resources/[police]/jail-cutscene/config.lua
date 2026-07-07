Config = Config or {}

Config.JailCutscene = {
    Duration = 10000,
    FadeOutDuration = 1500,
    FadeInDuration = 1500,

    BookingStages = {
        { label = 'Processing', duration = 3000 },
        { label = 'Fingerprinting', duration = 2500 },
        { label = 'Mugshot', duration = 2000 },
        { label = 'Uniform Issue', duration = 1500 },
        { label = 'Cell Assignment', duration = 1000 }
    },

    Camera = {
        Position = vector3(1695.0, 2538.0, 46.5),
        Target = vector3(1697.0, 2540.0, 45.5),
        FOV = 50.0
    },

    Props = {
        { model = 'prop_cs_ram_shoes', bone = 57005, offset = vec3(0.0, 0.0, 0.0), rotation = vec3(0.0, 0.0, 0.0) }
    },

    Sound = {
        Enabled = true,
        Name = 'DLC_HEIST_BIOLAB_DOOR_OPEN',
        Dict = 'DLC_HEIST_BIOLAB_DOOR_SOUNDS'
    },

    SkipKey = 38
}
