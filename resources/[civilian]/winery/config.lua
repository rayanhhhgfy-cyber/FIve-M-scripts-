Config = Config or {}

Config.JobName = 'winery'
Config.GrapeItem = 'grapes'
Config.WineBottleItem = 'wine_bottle'
Config.GrapesPerBasket = 20
Config.HarvestTime = 5000
Config.ProcessTime = 30000
Config.MaxGrapes = 50

Config.VineyardLocation = vector3(-1880.0, 2050.0, 140.0)
Config.VineyardHeading = 320.0

Config.GrapeHarvestZones = {
    vector3(-1900.0, 2040.0, 139.0),
    vector3(-1890.0, 2060.0, 139.0),
    vector3(-1870.0, 2070.0, 139.0),
    vector3(-1860.0, 2050.0, 139.0),
    vector3(-1880.0, 2080.0, 139.0),
    vector3(-1910.0, 2060.0, 139.0)
}

Config.WinePressLocation = vector3(-1895.0, 2030.0, 140.0)
Config.WinePressHeading = 0.0

Config.RestaurantSellLocation = vector3(-1830.0, 2060.0, 140.0)
Config.RestaurantSellHeading = 90.0

Config.WineTypes = {
    red = { label = 'Red Wine', grapes = 5, time = 30000, price = 50, qualityMult = 1.0 },
    white = { label = 'White Wine', grapes = 4, time = 25000, price = 40, qualityMult = 0.9 },
    rose = { label = 'Rosé Wine', grapes = 3, time = 20000, price = 35, qualityMult = 0.8 }
}

Config.QualityLevels = {
    { min = 0, max = 33, label = 'Standard', mult = 1.0 },
    { min = 34, max = 66, label = 'Good', mult = 1.2 },
    { min = 67, max = 100, label = 'Premium', mult = 1.5 }
}

Config.DiscordWebhook = ''
