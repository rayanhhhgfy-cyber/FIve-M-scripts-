Config = Config or {}

Config.JobName = 'taxi'
Config.Garage = vector3(895.0, -179.0, 74.0)
Config.GarageHeading = 320.0
Config.TaxiModels = { 'taxi', 'xls' }
Config.SpawnRadius = 5.0
Config.MaxDistance = 5000
Config.BaseFare = 5
Config.MeterRate = 5
Config.MeterUpdateInterval = 1000
Config.HailKey = 38
Config.HailRange = 10.0

Config.NPCFares = {
    {
        name = 'Legion Square',
        coords = vector3(200.0, -900.0, 30.0),
        payment = 25
    },
    {
        name = 'Vespucci Beach',
        coords = vector3(-1200.0, -1500.0, 10.0),
        payment = 35
    },
    {
        name = 'Rockford Hills',
        coords = vector3(-750.0, -300.0, 36.0),
        payment = 30
    },
    {
        name = 'Paleto Bay',
        coords = vector3(120.0, 6600.0, 31.0),
        payment = 60
    },
    {
        name = 'Sandy Shores',
        coords = vector3(1700.0, 3700.0, 34.0),
        payment = 40
    },
    {
        name = 'Airport',
        coords = vector3(-1050.0, -3300.0, 14.0),
        payment = 20
    },
    {
        name = 'Mirror Park',
        coords = vector3(1150.0, -450.0, 66.0),
        payment = 15
    },
    {
        name = 'Davis',
        coords = vector3(120.0, -1950.0, 21.0),
        payment = 20
    }
}

Config.LocaleColor = { r = 255, g = 200, b = 0 }

Config.DiscordWebhook = ''
Config.ShiftCooldown = 5000
Config.MaxShiftDuration = 28800
