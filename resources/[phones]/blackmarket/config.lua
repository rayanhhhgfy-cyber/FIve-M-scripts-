Config = Config or {}

Config.BlackMarket = {
    Locations = {
        { coords = vector3(140.0, -1280.0, 29.0), radius = 2.0, label = 'Vespucci BM' },
        { coords = vector3(-750.0, -110.0, 38.0), radius = 2.0, label = 'Mirror Park BM' },
        { coords = vector3(270.0, -1580.0, 28.0), radius = 2.0, label = 'Strawberry BM' },
        { coords = vector3(1650.0, -1050.0, 45.0), radius = 2.0, label = 'Paleto BM' }
    },

    Stocks = {
        { item = 'WEAPON_PISTOL', label = 'Pistol', price = 5000, maxStock = 5, minRank = 0, category = 'weapons' },
        { item = 'WEAPON_KNIFE', label = 'Knife', price = 1000, maxStock = 10, minRank = 0, category = 'weapons' },
        { item = 'WEAPON_SMG', label = 'SMG', price = 12000, maxStock = 3, minRank = 2, category = 'weapons' },
        { item = 'cokebaggy', label = 'Cocaine Bag', price = 800, maxStock = 20, minRank = 0, category = 'drugs' },
        { item = 'weed_skunk', label = 'Skunk Weed', price = 300, maxStock = 30, minRank = 0, category = 'drugs' },
        { item = 'meth', label = 'Meth', price = 1500, maxStock = 15, minRank = 1, category = 'drugs' },
        { item = 'lockpick', label = 'Lockpick', price = 2000, maxStock = 5, minRank = 0, category = 'tools' },
        { item = 'advancedlockpick', label = 'Advanced Lockpick', price = 5000, maxStock = 3, minRank = 2, category = 'tools' },
        { item = 'phone_encrypted', label = 'Encrypted Phone', price = 3000, maxStock = 10, minRank = 0, category = 'electronics' },
        { item = 'usb_drive', label = 'Encrypted USB', price = 1500, maxStock = 10, minRank = 0, category = 'electronics' }
    },

    RestockInterval = 300,
    RepMinPurchase = 0,
    StockRefresh = { min = 1, max = 3 },

    TargetOptions = {
        browse = { icon = 'fas fa-store', label = 'Browse Black Market', distance = 2.0 }
    }
}
