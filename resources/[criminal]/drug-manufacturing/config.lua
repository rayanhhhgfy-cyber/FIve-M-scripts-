Config = Config or {}

Config.DrugManufacturing = {
    MinPolice = 0,
    Cooldown = 300,
    PoliceAlertChance = 0.20,

    Labs = {
        { coords = vector3(1400.0, 3600.0, 35.0), label = 'Sandy Shores Lab', type = 'meth' },
        { coords = vector3(-1150.0, -1520.0, 4.0), label = 'Docks Lab', type = 'coke' },
        { coords = vector3(1700.0, 4800.0, 42.0), label = 'Grapeseed Lab', type = 'weed' },
        { coords = vector3(100.0, -1920.0, 21.0), label = 'La Mesa Lab', type = 'meth' },
        { coords = vector3(2200.0, 5600.0, 53.0), label = 'Paleto Lab', type = 'coke' }
    },

    Recipes = {
        meth = {
            label = 'Methamphetamine',
            outputItem = 'meth',
            outputMin = 1,
            outputMax = 3,
            cookTime = 30000,
            requiredItems = {
                { item = 'chemicals', label = 'Chemicals', amount = 3 },
                { item = 'acetone', label = 'Acetone', amount = 2 },
                { item = 'lithium', label = 'Lithium', amount = 1 }
            },
            skillCheck = { difficulty = 'medium', attempts = 3 }
        },
        coke = {
            label = 'Cocaine',
            outputItem = 'cokebaggy',
            outputMin = 1,
            outputMax = 4,
            cookTime = 35000,
            requiredItems = {
                { item = 'coca_leaves', label = 'Coca Leaves', amount = 5 },
                { item = 'chemicals', label = 'Chemicals', amount = 3 },
                { item = 'gasoline', label = 'Gasoline', amount = 2 }
            },
            skillCheck = { difficulty = 'hard', attempts = 4 }
        },
        weed = {
            label = 'Weaponized Weed',
            outputItem = 'weed_skunk',
            outputMin = 2,
            outputMax = 6,
            cookTime = 20000,
            requiredItems = {
                { item = 'weed_plant', label = 'Weed Plant', amount = 3 },
                { item = 'fertilizer', label = 'Fertilizer', amount = 2 },
                { item = 'water', label = 'Water', amount = 1 }
            },
            skillCheck = { difficulty = 'easy', attempts = 2 }
        }
    },

    Ingredients = {
        { item = 'chemicals', label = 'Chemicals', buyPrice = 500, canBuy = true },
        { item = 'acetone', label = 'Acetone', buyPrice = 300, canBuy = true },
        { item = 'lithium', label = 'Lithium', buyPrice = 800, canBuy = true },
        { item = 'coca_leaves', label = 'Coca Leaves', buyPrice = 200, canBuy = false },
        { item = 'gasoline', label = 'Gasoline', buyPrice = 100, canBuy = true },
        { item = 'weed_plant', label = 'Weed Plant', buyPrice = 150, canBuy = false },
        { item = 'fertilizer', label = 'Fertilizer', buyPrice = 100, canBuy = true },
        { item = 'water', label = 'Water', buyPrice = 50, canBuy = true }
    },

    Processing = {
        time = 5000,
        maxQuality = 100
    },

    LabUpgrades = {
        { label = 'Better Ventilation', cost = 5000, effect = 'reduces police chance by 50%' },
        { label = 'Industrial Mixer', cost = 8000, effect = 'increases output by 1' },
        { label = 'Security System', cost = 10000, effect = 'early police warning' }
    },

    Risk = {
        explosionChance = 0.05,
        fireChance = 0.08,
        poisonChance = 0.10
    },

    TargetOptions = {
        cook = { icon = 'fas fa-flask', label = 'Start Cooking', distance = 1.5 },
        collect = { icon = 'fas fa-hand', label = 'Collect Product', distance = 1.5 },
        buyIngredients = { icon = 'fas fa-shopping-cart', label = 'Buy Ingredients', distance = 2.0 }
    }
}
