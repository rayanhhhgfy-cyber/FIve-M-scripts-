Config = Config or {}

Config.DrugDealing = {
    MinPolice = 2,
    Cooldown = 60,
    PoliceAlertChance = 0.25,

    DealZones = {
        { coords = vector3(110.0, -1280.0, 29.0), label = 'Vespucci Beach', radius = 20.0 },
        { coords = vector3(-180.0, -900.0, 30.0), label = 'South Central', radius = 25.0 },
        { coords = vector3(320.0, -200.0, 54.0), label = 'Mirror Park', radius = 20.0 },
        { coords = vector3(-750.0, -70.0, 38.0), label = 'Rockford Hills', radius = 20.0 },
        { coords = vector3(1850.0, 3700.0, 34.0), label = 'Sandy Shores', radius = 30.0 },
        { coords = vector3(1700.0, 6400.0, 32.0), label = 'Paleto Bay', radius = 25.0 },
        { coords = vector3(270.0, -1580.0, 28.0), label = 'Strawberry', radius = 20.0 },
        { coords = vector3(-1200.0, -890.0, 13.0), label = 'Textile City', radius = 20.0 }
    },

    Drugs = {
        weed_skunk = { label = 'Weed', minPrice = 200, maxPrice = 400, reputationGain = 1, policeAttention = 0.1 },
        cokebaggy = { label = 'Cocaine', minPrice = 500, maxPrice = 900, reputationGain = 2, policeAttention = 0.3 },
        meth = { label = 'Meth', minPrice = 800, maxPrice = 1500, reputationGain = 3, policeAttention = 0.5 }
    },

    NPCs = {
        models = { 'a_m_y_skater_01', 'a_m_y_stwhi_02', 'a_m_y_stbla_02', 'a_m_y_stlat_01', 'a_m_o_ktown_01', 'a_f_y_skater_01' },
        spawnCount = { min = 3, max = 6 },
        approachRange = 3.0,
        despawTime = 120
    },

    Reputation = {
        levels = { 0, 10, 25, 50, 100 },
        perks = {
            [0] = { priceModifier = 1.0, maxDealSize = 5 },
            [1] = { priceModifier = 1.1, maxDealSize = 10 },
            [2] = { priceModifier = 1.25, maxDealSize = 15 },
            [3] = { priceModifier = 1.5, maxDealSize = 25 },
            [4] = { priceModifier = 2.0, maxDealSize = 50 }
        }
    },

    Police = {
        undercoverChance = 0.15,
        bustChance = 0.30,
        fine = { min = 500, max = 2000 }
    },

    Risk = {
        robberyChance = 0.10,
        robberyLoss = 0.5
    },

    TargetOptions = {
        approach = { icon = 'fas fa-handshake', label = 'Approach Customer', distance = 2.0 },
        sell = { icon = 'fas fa-dollar-sign', label = 'Sell Drugs', distance = 2.0 },
        intimidate = { icon = 'fas fa-skull', label = 'Intimidate', distance = 2.0 }
    }
}
