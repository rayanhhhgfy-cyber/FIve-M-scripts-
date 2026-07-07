Config = Config or {}

Config.BankHeist = {
    MinPolice = 6,
    Cooldown = 3600,
    PoliceAlertChance = 0.90,

    Banks = {
        { coords = vector3(313.5, -278.7, 54.2), label = 'Fleeca Legion Square', type = 'fleeca' },
        { coords = vector3(351.2, 295.6, 103.3), label = 'Fleeca Hawick Ave', type = 'fleeca' },
        { coords = vector3(-1212.7, -330.7, 37.8), label = 'Fleeca Popular St', type = 'fleeca' },
        { coords = vector3(-2957.6, 481.7, 15.7), label = 'Fleeca Paleto Bay', type = 'fleeca' },
        { coords = vector3(1175.0, 2710.0, 38.0), label = 'Fleeca Sandy Shores', type = 'fleeca' }
    },

    Thermite = {
        time = 12000,
        item = 'thermite',
        required = 2
    },

    Drill = {
        time = 25000,
        item = 'drill',
        durability = 3
    },

    Vault = {
        time = 40000,
        cash = { min = 15000, max = 40000 },
        goldBars = { min = 2, max = 6 },
        rareItems = { 'diamond_bag', 'gold_watch', 'rare_coin' }
    },

    Escape = {
        vehicle = { model = 'kuruma', label = 'Armored Kuruma' },
        timeLimit = 600
    },

    RequiredItems = {
        thermite = 'Thermite',
        drill = 'Advanced Drill',
        lockpick = 'Advanced Lockpick'
    },

    TargetOptions = {
        thermite = { icon = 'fas fa-fire', label = 'Place Thermite', distance = 1.5 },
        drill = { icon = 'fas fa-tools', label = 'Drill Vault Door', distance = 1.5 },
        vault = { icon = 'fas fa-vault', label = 'Loot Vault', distance = 1.5 },
        escapeKey = { icon = 'fas fa-key', label = 'Take Escape Key', distance = 1.5 }
    }
}
