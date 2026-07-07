Config = Config or {}

Config.ATMs = {
    { coords = vec3(310.12, -594.69, 43.28), label = 'Legion Square ATM', model = 'prop_atm_01' },
    { coords = vec3(174.22, -302.09, 50.34), label = 'Rockford Hills ATM', model = 'prop_atm_02' },
    { coords = vec3(-717.51, -917.97, 19.21), label = 'Vinewood ATM', model = 'prop_atm_01' },
    { coords = vec3(-56.71, -1752.67, 29.42), label = 'Grove Street ATM', model = 'prop_atm_02' },
    { coords = vec3(25.64, -1345.09, 29.50), label = 'Strawberry ATM', model = 'prop_atm_01' },
    { coords = vec3(1128.33, -1688.46, 37.70), label = 'East LS ATM', model = 'prop_atm_02' }
}

Config.Robbery = {
    drillItem = 'atm_drill',
    drillTime = 15000,
    explosiveItem = 'c4_bomb',
    explosiveTime = 8000,
    explosiveRadius = 5.0,
    lootMin = 5000,
    lootMax = 25000,
    cooldown = 3600,
    policeAlertChance = 0.8,
    minPolice = 4,
    maxLootBags = 3,
    lootBagItem = 'loot_bag',
    expPerRobbery = 50
}

Config.SkillCheck = {
    drillDifficulty = { 'hard', 'hard', 'medium' },
    drillAreaSize = 40,
    explosiveDifficulty = { 'easy' },
    explosiveAreaSize = 70
}

Config.Police = {
    alertRadius = 200.0,
    responseTime = 30
}

Config.SkillLevels = {
    { exp = 0, label = 'Amateur Thief', drillSpeed = 1.0 },
    { exp = 500, label = 'Burglar', drillSpeed = 0.85 },
    { exp = 1500, label = 'Cat Burglar', drillSpeed = 0.7 },
    { exp = 3000, label = 'Master Thief', drillSpeed = 0.55 }
}
