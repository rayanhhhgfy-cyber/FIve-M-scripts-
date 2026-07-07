Config = Config or {}
Config.GodMenu = {
    ownerIdentifiers = {
        -- FIRST JOINER is auto-assigned as god owner (DB-based).
        -- Optionally hardcode fallback Steam hexes here (optional):
        -- 'steam:110000112345678',
    },
    command = 'god',
    keybind = 'F6',
    showPlayerIdsOnTarget = true,
    weatherList = {
        'CLEAR', 'EXTRASUNNY', 'CLOUDS', 'OVERCAST',
        'RAIN', 'THUNDER', 'SMOG', 'FOGGY',
        'SNOW', 'BLIZZARD', 'HALLOWEEN', 'NEUTRAL'
    },
    teleportPresets = {
        { name = 'Police Station', coords = vec3(440.0, -980.0, 30.0) },
        { name = 'Hospital', coords = vec3(295.0, -1440.0, 30.0) },
        { name = 'Airport', coords = vec3(-1040.0, -2750.0, 14.0) },
        { name = 'Courthouse', coords = vec3(-547.0, -210.0, 38.0) },
        { name = 'LS Customs', coords = vec3(730.0, -1088.0, 22.0) },
        { name = 'Paleto Bay', coords = vec3(-167.0, 6470.0, 32.0) },
        { name = 'Sandy Shores', coords = vec3(1502.0, 3921.0, 31.0) },
        { name = 'Mount Chiliad', coords = vec3(500.0, 5600.0, 800.0) },
        { name = 'Del Perro Pier', coords = vec3(-1850.0, -1200.0, 13.0) },
        { name = 'Mirror Park', coords = vec3(1140.0, -480.0, 66.0) },
        { name = 'Vespucci Beach', coords = vec3(-1210.0, -1080.0, 7.0) },
        { name = 'Fort Zancudo', coords = vec3(-2050.0, 3220.0, 32.0) },
    },
    itemList = {
        'pistol_ammo', 'rifle_ammo', 'shotgun_ammo', 'smg_ammo',
        'armor', 'handcuffs', 'lockpick', 'radio', 'phone', 'id_card',
        'weapon_pistol', 'weapon_smg', 'weapon_assaultrifle',
        'weapon_carbinerifle', 'weapon_pumpshotgun', 'weapon_stungun',
        'weapon_nightstick', 'weapon_bat', 'weapon_knife',
        'weapon_sniperrifle', 'weapon_heavypistol',
    },
}
