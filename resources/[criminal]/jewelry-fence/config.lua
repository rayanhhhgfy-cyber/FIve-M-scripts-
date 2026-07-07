Config = Config or {}

Config.FenceLocations = {
    {
        coords = vec3(-1650.12, -1030.45, 13.15),
        label = 'Pawn Shop - Vespucci',
        npcModel = 'cs_bankman',
        npcLabel = 'Dodgy Pawn Broker'
    },
    {
        coords = vec3(820.30, -760.48, 26.18),
        label = 'Pawn Shop - Mirror Park',
        npcModel = 'cs_bankman',
        npcLabel = 'Underground Fence'
    },
    {
        coords = vec3(1090.50, -2000.30, 31.48),
        label = 'Pawn Shop - East LS',
        npcModel = 'cs_bankman',
        npcLabel = 'Back Alley Dealer'
    }
}

Config.Items = {
    ['stolen_jewelry'] = {
        label = 'Stolen Jewelry',
        basePrice = 500,
        priceVariance = 0.2,
        weight = 200,
        rarity = 'common'
    },
    ['stolen_watch'] = {
        label = 'Rolex Watch',
        basePrice = 2000,
        priceVariance = 0.3,
        weight = 100,
        rarity = 'uncommon'
    },
    ['stolen_necklace'] = {
        label = 'Gold Necklace',
        basePrice = 1500,
        priceVariance = 0.25,
        weight = 150,
        rarity = 'uncommon'
    },
    ['stolen_diamond'] = {
        label = 'Diamond',
        basePrice = 5000,
        priceVariance = 0.4,
        weight = 50,
        rarity = 'rare'
    },
    ['stolen_painting'] = {
        label = 'Stolen Painting',
        basePrice = 8000,
        priceVariance = 0.35,
        weight = 500,
        rarity = 'rare'
    },
    ['stolen_antique'] = {
        label = 'Antique Vase',
        basePrice = 3500,
        priceVariance = 0.3,
        weight = 300,
        rarity = 'uncommon'
    },
    ['stolen_phone'] = {
        label = 'Stolen Phone',
        basePrice = 300,
        priceVariance = 0.15,
        weight = 50,
        rarity = 'common'
    },
    ['stolen_laptop'] = {
        label = 'Stolen Laptop',
        basePrice = 1200,
        priceVariance = 0.2,
        weight = 400,
        rarity = 'common'
    }
}

Config.Fencing = {
    sellTime = 4000,
    cooldown = 30,
    reputationGain = 5,
    policeAlertChance = 0.1,
    minPolice = 1,
    reputationLevels = {
        { rep = 0, title = 'Unknown', multiplier = 0.6 },
        { rep = 50, title = 'Acquaintance', multiplier = 0.75 },
        { rep = 150, title = 'Trusted', multiplier = 0.85 },
        { rep = 300, title = 'Partner', multiplier = 0.95 },
        { rep = 500, title = 'Kingpin', multiplier = 1.1 }
    }
}

Config.SkillCheck = {
    difficulty = { 'easy', 'medium' },
    areaSize = 60
}

Config.Police = {
    alertRadius = 100.0
}
