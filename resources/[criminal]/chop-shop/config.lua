Config = Config or {}

Config.ChopLocations = {
    {
        coords = vec3(478.12, -1321.45, 29.26),
        label = 'Davis Chop Shop',
        spotCount = 2
    },
    {
        coords = vec3(-438.60, -1679.15, 19.07),
        label = 'Strawberry Garage',
        spotCount = 2
    },
    {
        coords = vec3(1008.43, -1495.85, 31.13),
        label = 'East LS Scrapyard',
        spotCount = 3
    }
}

Config.Stripping = {
    duration = 15000,
    skillCheck = { difficulty = { 'medium', 'hard' }, areaSize = 50 },
    policeAlertChance = 0.3,
    minPolice = 2
}

Config.Parts = {
    ['vehicle_engine'] = { label = 'Engine Block', weight = 5000, basePrice = 1500 },
    ['vehicle_transmission'] = { label = 'Transmission', weight = 3000, basePrice = 1000 },
    ['vehicle_doors'] = { label = 'Set of Doors', weight = 2000, basePrice = 800 },
    ['vehicle_bumper'] = { label = 'Bumper', weight = 1500, basePrice = 500 },
    ['vehicle_wheels'] = { label = 'Set of Wheels', weight = 4000, basePrice = 1200 },
    ['vehicle_catalytic'] = { label = 'Catalytic Converter', weight = 500, basePrice = 2000 },
    ['vehicle_battery'] = { label = 'Car Battery', weight = 1000, basePrice = 300 },
    ['vehicle_radio'] = { label = 'Radio System', weight = 200, basePrice = 400 },
    ['vehicle_seats'] = { label = 'Set of Seats', weight = 3000, basePrice = 600 }
}

Config.VINRemoval = {
    duration = 20000,
    skillCheck = { difficulty = { 'hard', 'hard', 'medium' }, areaSize = 40 },
    policeAlertChance = 0.5,
    reward = 5000,
    grindTime = 10000
}

Config.Scrap = {
    scrapItem = 'vehicle_scrap',
    scrapDuration = 8000,
    scrapPerVehicle = 5,
    scrapPrice = 200,
    policeAlertChance = 0.15
}

Config.Tools = {
    crowbarItem = 'crowbar',
    grindstoneItem = 'angle_grinder'
}

Config.Police = {
    alertRadius = 150.0
}

Config.SkillLevels = {
    { exp = 0, label = 'Novice', stripSpeed = 1.0 },
    { exp = 300, label = 'Apprentice', stripSpeed = 0.85 },
    { exp = 800, label = 'Mechanic', stripSpeed = 0.7 },
    { exp = 1500, label = 'Expert', stripSpeed = 0.55 },
    { exp = 2500, label = 'Master', stripSpeed = 0.4 }
}
