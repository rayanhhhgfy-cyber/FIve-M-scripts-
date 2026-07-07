Config = Config or {}

Config.JobName = 'hotdog'
Config.HourlyWage = 100

Config.StandLocations = {
    vector3(-275.0, -710.0, 29.0),
    vector3(170.0, -990.0, 30.0),
    vector3(-1260.0, -900.0, 12.0)
}

Config.StandModels = {
    'prop_hotdogstand_01',
    'prop_hotdogstand_02'
}

Config.Items = {
    hotdog = { label = 'Hot Dog', price = 5, emoji = '🌭' },
    soda = { label = 'Soda', price = 2, emoji = '🥤' },
    chips = { label = 'Chips', price = 3, emoji = '🍟' }
}

Config.SupplyItems = {
    { item = 'hotdog_bun', label = 'Hot Dog Buns', give = 20 },
    { item = 'soda_syrup', label = 'Soda Syrup', give = 15 },
    { item = 'chip_bag', label = 'Chip Bags', give = 25 }
}

Config.StockRefreshTime = 60000
Config.MaxStockPerItem = 50
Config.WagePaymentInterval = 3600000
Config.NPCCustomerInterval = { min = 30000, max = 120000 }

Config.DiscordWebhook = ''
