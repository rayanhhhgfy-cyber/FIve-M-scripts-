Config = Config or {}

Config.Skimming = {
    deviceItem = 'card_skimmer',
    devicePrice = 2500,
    installTime = 8000,
    collectTime = 5000,
    dataPerCollect = 1,
    policeAlertChance = 0.2,
    minPolice = 2
}

Config.ATM_Locations = {
    { coords = vec3(310.12, -594.69, 43.28), label = 'Legion Square ATM' },
    { coords = vec3(174.22, -302.09, 50.34), label = 'Rockford Hills ATM' },
    { coords = vec3(-717.51, -917.97, 19.21), label = 'Vinewood ATM' },
    { coords = vec3(-56.71, -1752.67, 29.42), label = 'Grove Street ATM' },
    { coords = vec3(25.64, -1345.09, 29.50), label = 'Strawberry ATM' },
    { coords = vec3(1128.33, -1688.46, 37.70), label = 'East LS ATM' }
}

Config.CardFraud = {
    blankCardItem = 'blank_card',
    blankCardPrice = 500,
    encodedCardItem = 'encoded_card',
    encodeTime = 10000,
    fraudTime = 5000,
    minPayout = 500,
    maxPayout = 5000,
    traceChance = 0.15,
    maxDailyFraud = 50000
}

Config.SkillCheck = {
    difficulty = { 'easy', 'medium' },
    areaSize = 60
}

Config.Police = {
    alertRadius = 100.0
}

Config.LaptopLocations = {
    { coords = vec3(1274.20, -1710.43, 54.77), label = 'Abandoned Garage Laptop' }
}
