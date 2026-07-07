Config = Config or {}

Config.MedicalBeds = {
    healTime = 15000,
    healInterval = 1000,
    healAmount = 5,
    ivTime = 10000,
    ivHealAmount = 200,
    maxPatientsPerBed = 1,
    bedModel = 'v_med_bed1',
    bedCooldown = 5000
}

Config.BedLocations = {
    { name = 'Pillbox ER Bed 1', coords = { x = 310.0, y = -580.0, z = 43.0 }, heading = 90.0 },
    { name = 'Pillbox ER Bed 2', coords = { x = 315.0, y = -580.0, z = 43.0 }, heading = 90.0 },
    { name = 'Pillbox ER Bed 3', coords = { x = 320.0, y = -580.0, z = 43.0 }, heading = 90.0 },
    { name = 'Pillbox ICU Bed 1', coords = { x = 330.0, y = -570.0, z = 43.0 }, heading = 0.0 },
    { name = 'Pillbox ICU Bed 2', coords = { x = 335.0, y = -570.0, z = 43.0 }, heading = 0.0 },
    { name = 'Sandy ER Bed 1', coords = { x = 1850.0, y = 3680.0, z = 34.0 }, heading = 180.0 },
    { name = 'Sandy ER Bed 2', coords = { x = 1855.0, y = 3680.0, z = 34.0 }, heading = 180.0 },
    { name = 'Sandy ICU Bed 1', coords = { x = 1845.0, y = 3690.0, z = 34.0 }, heading = 0.0 }
}

Config.Reception = {
    enabled = true,
    checkInPrice = 150,
    checkInTime = 5000,
    locations = {
        {
            name = 'Pillbox Hospital',
            coords = { x = 305.0, y = -595.0, z = 43.28 },
            heading = 0.0,
            radius = 2.5,
            spawnBeds = { 'Pillbox ER Bed 1', 'Pillbox ER Bed 2', 'Pillbox ER Bed 3', 'Pillbox ICU Bed 1', 'Pillbox ICU Bed 2' }
        },
        {
            name = 'Sandy Shores Medical',
            coords = { x = 1850.0, y = 3685.0, z = 34.0 },
            heading = 180.0,
            radius = 2.5,
            spawnBeds = { 'Sandy ER Bed 1', 'Sandy ER Bed 2', 'Sandy ICU Bed 1' }
        }
    }
}

Config.IV = {
    enabled = true,
    requireIVBag = true,
    ivBagItem = 'iv_bag',
    healRate = 2,
    tickInterval = 2000,
    duration = 30000
}

Config.BedHealEffects = {
    animDict = 'amb@medic@standing@timeofdeath@base',
    animClip = 'base',
    ivProp = 'prop_iv_bag',
    ivPropBone = 60390
}
