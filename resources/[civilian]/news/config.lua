Config = Config or {}

Config.JobName = 'news'
Config.VanModel = 'burrito'
Config.VanSpawn = vector3(-600.0, -930.0, 23.0)
Config.VanSpawnHeading = 180.0
Config.PaymentPerBroadcast = 100
Config.BroadcastDuration = 15000
Config.MinBroadcastInterval = 60000

Config.Equipment = {
    camera = 'news_camera',
    mic = 'news_mic'
}

Config.BroadcastLocations = {
    {
        name = 'Legion Square',
        coords = vector3(200.0, -900.0, 30.0),
        description = 'City center area'
    },
    {
        name = 'Vespucci Beach',
        coords = vector3(-1200.0, -1500.0, 10.0),
        description = 'Popular beach location'
    },
    {
        name = 'Rockford Hills',
        coords = vector3(-750.0, -300.0, 36.0),
        description = 'Wealthy district'
    },
    {
        name = 'Sandy Shores',
        coords = vector3(1700.0, 3700.0, 34.0),
        description = 'Rural desert area'
    },
    {
        name = 'Paleto Bay',
        coords = vector3(120.0, 6600.0, 31.0),
        description = 'Northern coastal town'
    }
}

Config.CameraAnim = {
    dict = 'anim@scripted@freemode@ig27@cam@var_a@base@',
    clip = 'base',
    prop = 'prop_v_rock_cam'
}

Config.MicAnim = {
    dict = 'anim@scripted@freemode@ig27@mic@var_a@base@',
    clip = 'base',
    prop = 'prop_v_rock_mic'
}

Config.DiscordWebhook = ''
