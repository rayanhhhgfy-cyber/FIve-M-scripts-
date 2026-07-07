Config = Config or {}

Config.TrainHeist = {
    MinPolice = 4,
    Cooldown = 2400,
    PoliceAlertChance = 0.75,

    TrainModels = { 'freight', 'freightcar', 'freightcont1', 'freightcont2', 'freightgrain', 'freighttrailer' },

    CargoTypes = {
        electronics = { label = 'Electronics', items = { 'phone', 'tablet', 'usb_drive' }, cash = { min = 1000, max = 3000 } },
        valuables = { label = 'Valuables', items = { 'gold_chain', 'diamond_ring', 'gold_watch' }, cash = { min = 2000, max = 5000 } },
        weapons = { label = 'Weapons', items = { 'WEAPON_PISTOL', 'WEAPON_SMG', 'WEAPON_CARBINERIFLE' }, cash = { min = 1000, max = 4000 } },
        drugs = { label = 'Drugs', items = { 'cokebaggy', 'weed_skunk', 'meth' }, cash = { min = 3000, max = 7000 } },
        cash = { label = 'Cash Transit', items = {}, cash = { min = 5000, max = 15000 } }
    },

    ContainerOpening = {
        time = 8000,
        requiredItem = 'crowbar'
    },

    Rewards = {
        containersPerTrain = { min = 3, max = 6 },
        lootCount = { min = 1, max = 3 }
    },

    Train = {
        spawnDistance = 200.0,
        speed = 40.0,
        route = {
            vector3(0.0, 6000.0, 0.0),
            vector3(0.0, -2000.0, 0.0)
        }
    },

    TargetOptions = {
        board = { icon = 'fas fa-train', label = 'Board Train', distance = 3.0 },
        pryOpen = { icon = 'fas fa-tools', label = 'Pry Container Open', distance = 2.0 },
        loot = { icon = 'fas fa-hand', label = 'Loot Container', distance = 1.5 }
    }
}
