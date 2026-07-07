Config = Config or {}

Config.Diving = {
    gearItem = 'scuba_gear',
    tankItem = 'air_tank',
    maxDepth = 100.0,
    oxygenPerTank = 120,
    locations = {
        vector3(-3056.45, -58.34, 3.50),
        vector3(2442.67, -40.45, 3.50),
        vector3(460.34, 5555.67, 3.50),
    },
    treasure = {
        { name = 'rusty_coin', label = 'Rusty Coin', price = 10, rarity = 'common' },
        { name = 'old_bottle', label = 'Old Bottle', price = 15, rarity = 'common' },
        { name = 'silver_ring', label = 'Silver Ring', price = 40, rarity = 'uncommon' },
        { name = 'gold_bar_small', label = 'Small Gold Bar', price = 200, rarity = 'rare' },
        { name = 'pearl_necklace', label = 'Pearl Necklace', price = 500, rarity = 'legendary' },
    },
    searchTime = 5000,
    sellLocation = vector3(-1650.45, -1070.34, 4.00),
}
