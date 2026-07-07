Config = Config or {}
Config.CharacterSystem = {
    maxCharacters = 5,
    spawnLocations = {
        last = { label = 'Last Location', icon = 'fas fa-history', description = 'Continue where you left off' },
        apartment = { label = 'Your Apartment', icon = 'fas fa-home', description = 'Spawn at your personal residence', coords = vector3(327.0, -205.0, 53.0) },
        hospital = { label = 'Hospital', icon = 'fas fa-hospital', description = 'Spawn at Pillbox Medical Center', coords = vector3(295.0, -1440.0, 30.0) },
        airport = { label = 'LS Airport', icon = 'fas fa-plane', description = 'Spawn at Los Santos International', coords = vector3(-1040.0, -2750.0, 14.0) },
        police = { label = 'Police Station', icon = 'fas fa-building', description = 'Spawn at Mission Row PD (LEO only)', coords = vector3(440.0, -980.0, 30.0) },
    },
    defaultSpawn = vector3(295.0, -1440.0, 30.0),
    saveInterval = 60000,
    newCharacterDefaults = {
        cash = 5000,
        bank = 10000,
    },
    appearanceModels = {
        male = 'mp_m_freemode_01',
        female = 'mp_f_freemode_01',
    },
    -- Interactive spawn map
    SpawnMap = {
        bounds = { minX = -3000, maxX = 3000, minY = -3000, maxY = 7000 },
        common = {
            { label = 'LS Hospital', type = 'hospital', coords = { x = 295.0, y = -1440.0, z = 30.0 }, icon = 'hospital' },
            { label = 'LS Airport', type = 'airport', coords = { x = -1040.0, y = -2750.0, z = 14.0 }, icon = 'plane' },
            { label = 'Mission Row PD', type = 'police', coords = { x = 440.0, y = -980.0, z = 30.0 }, icon = 'police' },
            { label = 'Motels', type = 'apartment', coords = { x = 327.0, y = -205.0, z = 53.0 }, icon = 'home' },
            { label = 'Legion Square', type = 'legion', coords = { x = 195.0, y = -934.0, z = 29.7 }, icon = 'star' },
            { label = 'Paleto Bay', type = 'paleto', coords = { x = 80.0, y = 6424.0, z = 31.7 }, icon = 'town' },
            { label = 'Sandy Shores', type = 'sandy', coords = { x = 1840.0, y = 3680.0, z = 34.0 }, icon = 'desert' },
            { label = 'Grapeseed', type = 'grapeseed', coords = { x = 2140.0, y = 4780.0, z = 40.0 }, icon = 'farm' },
        },
        jobs = {
            ['police'] = {
                { label = 'Sandy Shores PD', coords = { x = 1850.0, y = 3690.0, z = 34.0 }, icon = 'police' },
                { label = 'Paleto Bay PD', coords = { x = -450.0, y = 6010.0, z = 31.0 }, icon = 'police' },
                { label = 'Davis PD', coords = { x = 360.0, y = -1600.0, z = 30.0 }, icon = 'police' },
                { label = 'Vinewood PD', coords = { x = 630.0, y = 0.0, z = 32.0 }, icon = 'police' },
            },
            ['fib'] = {
                { label = 'FIB Building', coords = { x = 135.0, y = -760.0, z = 45.0 }, icon = 'shield' },
                { label = 'CID HQ', coords = { x = -1450.0, y = -520.0, z = 30.0 }, icon = 'bunker' },
                { label = 'IAA Building', coords = { x = -200.0, y = -2000.0, z = 30.0 }, icon = 'shield' },
            },
            ['ambulance'] = {
                { label = 'Sandy Medical', coords = { x = 1820.0, y = 3690.0, z = 34.0 }, icon = 'medical' },
                { label = 'Paleto Medical', coords = { x = -270.0, y = 6030.0, z = 31.0 }, icon = 'medical' },
            },
            ['mechanic'] = {
                { label = 'LS Customs Airport', coords = { x = -1095.0, y = -2800.0, z = 14.0 }, icon = 'wrench' },
                { label = 'LS Customs Harmony', coords = { x = 1150.0, y = 2650.0, z = 34.0 }, icon = 'wrench' },
                { label = 'LS Customs Paleto', coords = { x = -320.0, y = 6080.0, z = 31.0 }, icon = 'wrench' },
                { label = 'Benny\'s Motors', coords = { x = -215.0, y = -1325.0, z = 30.0 }, icon = 'wrench' },
            },
        },
    },
}
