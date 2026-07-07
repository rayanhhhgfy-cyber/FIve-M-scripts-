Config = Config or {}

Config.HouseRobbery = {
    MinPolice = 3,
    Cooldown = 900,
    LockpickTime = 10000,
    SearchTime = 5000,
    PoliceAlertChance = 0.70,

    Houses = {
        { coords = vector3(-680.0, 590.0, 145.0), label = 'Rockford Hills Estate', tier = 3, shellModel = 'xm_lab' },
        { coords = vector3(-150.0, -900.0, 30.0), label = 'South City Bungalow', tier = 1, shellModel = 'xm_lab' },
        { coords = vector3(300.0, -750.0, 42.0), label = 'Mirror Park Townhouse', tier = 2, shellModel = 'xm_lab' },
        { coords = vector3(-1320.0, -150.0, 40.0), label = 'Del Perro Apartment', tier = 1, shellModel = 'xm_lab' },
        { coords = vector3(120.0, 5500.0, 70.0), label = 'Paleto Bay House', tier = 1, shellModel = 'xm_lab' },
        { coords = vector3(-140.0, 620.0, 210.0), label = 'Richman Mansion', tier = 3, shellModel = 'xm_lab' },
        { coords = vector3(360.0, -490.0, 45.0), label = 'El Rancho Bungalow', tier = 2, shellModel = 'xm_lab' },
        { coords = vector3(-850.0, 690.0, 150.0), label = 'Mad Wayne Estate', tier = 3, shellModel = 'xm_lab' }
    },

    TierRewards = {
        [1] = { cash = { min = 200, max = 600 }, items = { 'WEAPON_PISTOL', 'gold_chain', 'phone' }, itemCount = { min = 1, max = 2 } },
        [2] = { cash = { min = 500, max = 1200 }, items = { 'WEAPON_SMG', 'diamond_ring', 'gold_bar', 'tablet' }, itemCount = { min = 2, max = 4 } },
        [3] = { cash = { min = 1000, max = 2500 }, items = { 'WEAPON_CARBINERIFLE', 'diamond_necklace', 'gold_watch', 'painting', 'rare_coin' }, itemCount = { min = 3, max = 5 } }
    },

    RequiredItems = { lockpick = 'Lockpick', advancedlockpick = 'Advanced Lockpick' },

    JobReward = {
        delivery = { label = 'Fencing Delivery', reward = { min = 1000, max = 3000 } }
    },

    TargetOptions = {
        enter = { icon = 'fas fa-door-open', label = 'Break In', distance = 1.5 },
        search = { icon = 'fas fa-search', label = 'Search House', distance = 1.5 },
        leave = { icon = 'fas fa-running', label = 'Leave Quietly', distance = 1.5 }
    }
}
