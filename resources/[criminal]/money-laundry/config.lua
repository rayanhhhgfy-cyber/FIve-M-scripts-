Config = Config or {}

Config.LaundryLocations = {
    {
        coords = vec3(113.84, -1296.54, 29.42),
        label = '24/7 Laundromat',
        business = 'laundromat_1',
        washTime = 30000
    },
    {
        coords = vec3(-1400.58, -520.49, 32.53),
        label = 'San Andreas Car Wash',
        business = 'car_wash_1',
        washTime = 45000
    },
    {
        coords = vec3(820.32, -820.45, 26.32),
        label = 'Mirror Park Dry Cleaners',
        business = 'dry_cleaners_1',
        washTime = 35000
    }
}

Config.Washing = {
    dirtyMoneyItem = 'dirty_money',
    minAmount = 1000,
    maxAmount = 100000,
    feePercent = 20,
    duration = 60000,
    cooldown = 120,
    policeAlertChance = 0.15,
    minPolice = 2,
    maxDailyWash = 500000
}

Config.Risk = {
    low = { label = 'Low Risk', multiplier = 0.75, chanceWithPapers = 0.95 },
    medium = { label = 'Medium Risk', multiplier = 0.85, chanceWithPapers = 0.80 },
    high = { label = 'High Risk', multiplier = 0.95, chanceWithPapers = 0.60 }
}

Config.Papers = {
    item = 'laundering_papers',
    label = 'Laundering Papers',
    price = 5000,
    uses = 3
}

Config.SkillCheck = {
    difficulty = { 'easy', 'medium', 'hard' },
    areaSize = 50
}
