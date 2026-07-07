Config = Config or {}
Config.AdminCommander = Config.AdminCommander or {}

Config.AdminCommander = {
    adminGroups = { 'admin', 'superadmin', 'god' },
    logAllActions = true,
    ownerIdentifiers = {
        --[[
            Add your Steam hex here to auto-grant god admin on connect.
            Example: 'steam:110000112345678'

            If BOTH this and server_owners DB table are empty, the first player
            to join is permanently saved as god admin in the database.

            Once at least one owner exists (config or DB), only owners can
            promote to god rank.

            Use /addowner [server_id] in-game to add permanent owners to DB.
            Use /removeowner [server_id] to remove them.
            Use /listowners to view all saved owners.
        ]]
    },

    -- Default items for /giveitem menu
    quickItems = {
        { name = 'pistol_ammo', label = 'Pistol Ammo' },
        { name = 'rifle_ammo', label = 'Rifle Ammo' },
        { name = 'armor', label = 'Body Armor' },
        { name = 'handcuffs', label = 'Handcuffs' },
        { name = 'lockpick', label = 'Lockpick' },
        { name = 'radio', label = 'Radio' },
        { name = 'phone', label = 'Phone' },
        { name = 'id_card', label = 'ID Card' },
        { name = 'weapon_pistol', label = 'Pistol' },
        { name = 'weapon_smg', label = 'SMG' },
        { name = 'weapon_assaultrifle', label = 'Assault Rifle' },
    },

    -- Default vehicles for /givecar menu
    quickVehicles = {
        { model = 'adder', label = 'Adder' },
        { model = 'zentorno', label = 'Zentorno' },
        { model = 'police', label = 'Police Cruiser' },
        { model = 'police2', label = 'Police SUV' },
        { model = 'police3', label = 'Police Interceptor' },
        { model = 'ambulance', label = 'Ambulance' },
        { model = 'firetruk', label = 'Fire Truck' },
        { model = 'bevo', label = 'G-Wagon' },
        { model = '1200RT', label = 'Police Bike R1200RT' },
        { model = 'zzninja33', label = 'Kawasaki Ninja' },
    },

    -- Teleport presets for dashboard
    teleportPresets = {
        { name = 'Police Station', coords = vector3(440.0, -980.0, 30.0) },
        { name = 'CID HQ', coords = vector3(110.0, -750.0, 45.0) },
        { name = 'Hospital', coords = vector3(295.0, -1440.0, 30.0) },
        { name = 'Airport', coords = vector3(-1040.0, -2750.0, 14.0) },
        { name = 'Courthouse', coords = vector3(-547.0, -210.0, 38.0) },
        { name = 'LS Customs', coords = vector3(730.0, -1088.0, 22.0) },
        { name = 'Paleto Bay', coords = vector3(-167.0, 6470.0, 32.0) },
        { name = 'Sandy Shores', coords = vector3(1502.0, 3921.0, 31.0) },
        { name = 'Mount Chiliad', coords = vector3(500.0, 5600.0, 800.0) },
        { name = 'Del Perro Pier', coords = vector3(-1850.0, -1200.0, 13.0) },
    },

    -- Server management
    server = {
        maxPlayers = 64,
        enableAnnounce = true,
    },

    -- Player admin ranks
    adminRanks = { 'admin', 'superadmin', 'god' },
}
