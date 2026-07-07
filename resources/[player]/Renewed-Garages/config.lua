Config = Config or {}

Config.Garages = {
    maxVehicles = 10,
    impoundFee = 500,
    impoundTimer = 86400000,
    enableSharedGarages = true,
    enableImpound = true,
    enableDepots = true,
    enableFuelSync = true,
    enableDamageSync = true,
    enableModSync = true,
    enablePlateSync = true,
    enableStoredLocation = true,
    adminAce = 'admin.garages'
}

Config.GarageTypes = {
    public = { label = 'Public Garage', fee = 0, slots = 10 },
    apartment = { label = 'Apartment Parking', fee = 0, slots = 2 },
    house = { label = 'House Garage', fee = 0, slots = 4 },
    police = { label = 'Police Garage', fee = 0, slots = 20, job = 'police' },
    ambulance = { label = 'EMS Garage', fee = 0, slots = 10, job = 'ambulance' },
    mechanic = { label = 'Mechanic Garage', fee = 0, slots = 10, job = 'mechanic' },
    impound = { label = 'Impound Lot', fee = 500, slots = 50 }
}

Config.GarageLocations = {
    {
        name = 'Legion Square Garage',
        type = 'public',
        coords = { x = 215.0, y = -810.0, z = 30.0 },
        spawn = { x = 220.0, y = -810.0, z = 30.0, h = 180.0 },
        blip = { sprite = 357, color = 3 }
    },
    {
        name = 'PD Impound',
        type = 'impound',
        coords = { x = 440.0, y = -1020.0, z = 28.0 },
        spawn = { x = 445.0, y = -1020.0, z = 28.0, h = 0.0 },
        blip = { sprite = 68, color = 1 }
    },
    {
        name = 'MRPD Garage',
        type = 'police',
        coords = { x = 460.0, y = -1020.0, z = 28.0 },
        spawn = { x = 465.0, y = -1020.0, z = 28.0, h = 0.0 },
        blip = { sprite = 357, color = 1 }
    },
    {
        name = 'Sandy Shores Garage',
        type = 'public',
        coords = { x = 1850.0, y = 3700.0, z = 33.0 },
        spawn = { x = 1855.0, y = 3695.0, z = 33.0, h = 180.0 },
        blip = { sprite = 357, color = 3 }
    },
    {
        name = 'Paleto Bay Garage',
        type = 'public',
        coords = { x = -200.0, y = 6400.0, z = 31.0 },
        spawn = { x = -195.0, y = 6395.0, z = 31.0, h = 180.0 },
        blip = { sprite = 357, color = 3 }
    }
}

Config.VehicleState = {
    saveFuel = true,
    saveEngineDamage = true,
    saveBodyDamage = true,
    saveMods = true,
    savePlate = true,
    saveLocation = true,
    saveDoors = true,
    saveWindows = true,
    saveTyres = true,
    saveNeons = true,
    saveXenon = true,
    saveWheelColour = true,
    saveColour = true,
    saveExtraColour = true,
    saveDashboardColour = true,
    saveInteriorColour = true,
    savePearlescentColour = true,
    saveTint = true
}
