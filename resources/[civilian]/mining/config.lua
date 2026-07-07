Config = Config or {}
Config.Mining = {
    Locations = {
        mining = { coords = vector3(2975.0, 2800.0, 42.0), radius = 50.0, label = 'Mining Zone' },
        processing = { coords = vector3(1140.0, -2000.0, 32.0), radius = 5.0, label = 'Smelter' },
        buyer = { coords = vector3(-590.0, -2800.0, 6.0), radius = 5.0, label = 'Ore Buyer' }
    },
    Ores = {
        iron = { label = 'Iron Ore', price = 25, skillReq = 0, color = { 180, 180, 180 }, weight = 1.0 },
        copper = { label = 'Copper Ore', price = 40, skillReq = 2, color = { 180, 120, 60 }, weight = 1.0 },
        gold = { label = 'Gold Ore', price = 100, skillReq = 5, color = { 255, 215, 0 }, weight = 0.8 },
        diamond = { label = 'Diamond', price = 300, skillReq = 10, color = { 0, 255, 255 }, weight = 0.3 }
    },
    ProcessedOres = {
        iron = { label = 'Iron Ingot', price = 50, weight = 2.0 },
        copper = { label = 'Copper Ingot', price = 80, weight = 2.0 },
        gold = { label = 'Gold Ingot', price = 200, weight = 1.5 },
        diamond = { label = 'Cut Diamond', price = 600, weight = 0.5 }
    },
    PickaxeItem = 'pickaxe',
    MiningTime = 8000,
    ProcessingTime = 5000,
    YieldMin = 1,
    YieldMax = 3,
    SkillMultiplier = 0.05,
    TargetOptions = {
        mine = { icon = 'fas fa-hard-hat', label = 'Mine', distance = 2.0 },
        process = { icon = 'fas fa-fire', label = 'Process Ore', distance = 2.0 },
        sell = { icon = 'fas fa-dollar-sign', label = 'Sell Ore', distance = 2.0 }
    }
}
