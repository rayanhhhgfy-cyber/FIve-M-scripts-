Config = Config or {}

Config.StoreRobbery = {
    PoliceAlertChance = 0.80,
    MinPolice = 3,
    Cooldown = 600,
    RobberyTime = 60000,

    Locations = {
        { coords = vector3(24.36, -1346.71, 29.50), registerId = 1, label = '24/7 Vespucci' },
        { coords = vector3(-3041.06, 585.34, 7.91), registerId = 2, label = '24/7 Paleto' },
        { coords = vector3(-3244.31, 1001.12, 12.83), registerId = 3, label = '24/7 Route 68' },
        { coords = vector3(1728.93, 6416.28, 35.04), registerId = 4, label = '24/7 Sandy Shores' },
        { coords = vector3(1959.82, 3749.19, 32.34), registerId = 5, label = '24/7 Harmony' },
        { coords = vector3(1134.34, -983.56, 46.42), label = 'Rob\'s Liquor' },
        { coords = vector3(-1221.58, -908.13, 12.33), label = '24/7 Popular St' }
    },

    Registers = {
        { coords = vector3(24.36, -1346.71, 29.50), robbed = false, reward = { min = 100, max = 500 } },
        { coords = vector3(-3041.06, 585.34, 7.91), robbed = false, reward = { min = 100, max = 500 } },
        { coords = vector3(-3244.31, 1001.12, 12.83), robbed = false, reward = { min = 100, max = 500 } },
        { coords = vector3(1728.93, 6416.28, 35.04), robbed = false, reward = { min = 100, max = 500 } },
        { coords = vector3(1959.82, 3749.19, 32.34), robbed = false, reward = { min = 100, max = 500 } }
    },

    Items = {
        scratch_card = { label = 'Scratch Card', chance = 0.30 },
        cigar = { label = 'Cigar', chance = 0.20 },
        lottery_ticket = { label = 'Lottery Ticket', chance = 0.10 },
        phone = { label = 'Cheap Phone', chance = 0.15 },
        chips = { label = 'Chip Bag', chance = 0.25 }
    },

    LootTime = 5000,
    RequiredItem = 'lockpick',

    TargetOptions = {
        register = { icon = 'fas fa-cash-register', label = 'Rob Register', distance = 1.5 },
        shelf = { icon = 'fas fa-box', label = 'Search Shelves', distance = 1.5 }
    },

    Rewards = {
        cash = { min = 50, max = 200 },
        item = { min = 1, max = 3 }
    }
}
