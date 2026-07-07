Config = Config or {}

Config.Fishing = {
    rodItem = 'fishing_rod',
    baitItem = 'fishing_bait',
    spots = {
        vector3(-1800.34, -1220.56, 1.50),
        vector3(1298.45, 4223.67, 1.50),
        vector3(-795.22, 5590.34, 1.50),
        vector3(-345.67, 4321.89, 1.50),
    },
    fish = {
        { name = 'trout', label = 'Trout', minWeight = 0.5, maxWeight = 3.0, price = 8, rarity = 'common' },
        { name = 'bass', label = 'Bass', minWeight = 0.5, maxWeight = 5.0, price = 12, rarity = 'common' },
        { name = 'salmon', label = 'Salmon', minWeight = 1.0, maxWeight = 6.0, price = 18, rarity = 'uncommon' },
        { name = 'tuna', label = 'Tuna', minWeight = 2.0, maxWeight = 20.0, price = 30, rarity = 'rare' },
        { name = 'goldfish', label = 'Goldfish', minWeight = 0.1, maxWeight = 0.3, price = 50, rarity = 'legendary' },
    },
    castTime = 3000,
    catchTime = { min = 5000, max = 15000 },
    skillCheckDifficulty = { 'easy', 'medium' },
}
