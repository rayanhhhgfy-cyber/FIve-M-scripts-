Config = Config or {}

Config.Character = {
    maxSlots = 5,
    defaultMoney = { cash = 5000, bank = 5000 },
    defaultJob = { name = 'unemployed', label = 'Unemployed', payment = 10 },
    defaultGang = { name = 'none', label = 'None' },
    starterItems = {
        { name = 'phone', count = 1 },
        { name = 'id_card', count = 1 },
        { name = 'driver_license', count = 1 },
        { name = 'bread', count = 2 },
        { name = 'water', count = 2 }
    },
    deleteCooldown = 86400000,
    allowDelete = true,
    requireDeleteConfirm = true,
    spawnLocations = {
        { name = 'Legion Square', coords = vector4(215.0, -810.0, 30.0, 0.0) },
        { name = 'Beach', coords = vector4(-1550.0, -980.0, 13.0, 0.0) },
        { name = 'Airport', coords = vector4(-1050.0, -3400.0, 14.0, 0.0) },
        { name = 'Sandy Shores', coords = vector4(1850.0, 3700.0, 33.0, 0.0) },
        { name = 'Paleto Bay', coords = vector4(-200.0, 6400.0, 31.0, 0.0) }
    },
    adminAce = 'admin.characters'
}

Config.DefaultMetadata = {
    hunger = 100,
    thirst = 100,
    stress = 0,
    stamina = 100,
    armor = 0
}

Config.DefaultCharInfo = {
    firstname = '',
    lastname = '',
    birthdate = '1990-01-01',
    gender = 0,
    nationality = 'American',
    phone = '',
    account = 0
}
