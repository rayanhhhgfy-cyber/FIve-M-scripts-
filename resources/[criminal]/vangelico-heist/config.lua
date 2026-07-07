Config = Config or {}

Config.VangelicoHeist = {
    MinPolice = 5,
    Cooldown = 3600,
    PoliceAlertChance = 0.85,

    Location = {
        coords = vector3(-630.0, -235.0, 38.0),
        label = 'Vangelico Jewelry',
        interior = vector3(-630.0, -235.0, 38.0),
        model = 'gabz_vangelico'
    },

    GlassCases = {
        { coords = vector3(-630.0, -238.0, 38.5), label = 'Ring Display', item = 'diamond_ring', value = { min = 2000, max = 5000 }, time = 8000, model = 'prop_glass_case_01' },
        { coords = vector3(-633.0, -235.0, 38.5), label = 'Necklace Display', item = 'diamond_necklace', value = { min = 3000, max = 7000 }, time = 8000, model = 'prop_glass_case_01' },
        { coords = vector3(-627.0, -235.0, 38.5), label = 'Watch Display', item = 'gold_watch', value = { min = 2500, max = 6000 }, time = 8000, model = 'prop_glass_case_01' },
        { coords = vector3(-630.0, -232.0, 38.5), label = 'Bracelet Display', item = 'gold_chain', value = { min = 1500, max = 4000 }, time = 8000, model = 'prop_glass_case_01' },
        { coords = vector3(-636.0, -238.0, 38.5), label = 'Crown Display', item = 'rare_coin', value = { min = 5000, max = 10000 }, time = 12000, model = 'prop_glass_case_01' },
        { coords = vector3(-636.0, -232.0, 38.5), label = 'Earring Display', item = 'diamond_ring', value = { min = 2000, max = 4500 }, time = 8000, model = 'prop_glass_case_01' }
    },

    Smash = {
        item = 'hammer',
        time = 5000
    },

    Alarm = {
        panels = 3,
        disableTime = 10000,
        triggerDelay = 120
    },

    Rewards = {
        cash = { min = 5000, max = 15000 },
        extraItems = { 'gold_bar', 'diamond_bag' }
    },

    RequiredItems = {
        hammer = 'Hammer',
        hackingDevice = 'Hacking Device',
        bag = 'Duffel Bag'
    },

    TargetOptions = {
        smashCase = { icon = 'fas fa-hammer', label = 'Smash Glass Case', distance = 1.5 },
        lootCase = { icon = 'fas fa-hand', label = 'Take Jewelry', distance = 1.5 },
        disableAlarm = { icon = 'fas fa-shield-alt', label = 'Disable Alarm', distance = 2.0 }
    }
}
