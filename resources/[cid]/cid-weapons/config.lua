Config = Config or {}
Config.CIDWeapons = Config.CIDWeapons or {}

Config.CIDWeapons = {
    allowedJobs = { 'cid' },
    requireDuty = true,
    adminGroups = { 'admin', 'superadmin', 'god' },
    maxDistance = 2.5,

    -- CID HQ secret armory
    hqArmory = {
        coords = vector3(115.0, -755.0, 45.0),
        radius = 3.0,
        label = 'CID Secret Armory',
    },

    -- Rank-gated weapon cache
    weapons = {
        { weapon = 'WEAPON_PISTOL50', label = 'Pistol .50', rank = 0, count = 1 },
        { weapon = 'WEAPON_COMBATPDW', label = 'Combat PDW', rank = 0, count = 1 },
        { weapon = 'WEAPON_SMG', label = 'SMG', rank = 1, count = 1 },
        { weapon = 'WEAPON_ASSAULTRIFLE', label = 'Assault Rifle', rank = 1, count = 1 },
        { weapon = 'WEAPON_CARBINERIFLE', label = 'Carbine Rifle', rank = 2, count = 1 },
        { weapon = 'WEAPON_SPECIALCARBINE', label = 'Special Carbine', rank = 2, count = 1 },
        { weapon = 'WEAPON_HEAVYSNIPER', label = 'Heavy Sniper', rank = 3, count = 1 },
        { weapon = 'WEAPON_PUMPSHOTGUN', label = 'Pump Shotgun', rank = 1, count = 1 },
        { weapon = 'WEAPON_ASSAULTSHOTGUN', label = 'Assault Shotgun', rank = 2, count = 1 },
        { weapon = 'WEAPON_BULLPUPRIFLE', label = 'Bullpup Rifle', rank = 3, count = 1 },
        { weapon = 'WEAPON_ADVANCEDRIFLE', label = 'Advanced Rifle', rank = 3, count = 1 },
        { weapon = 'WEAPON_MG', label = 'MG', rank = 4, count = 1 },
        { weapon = 'WEAPON_COMBATMG', label = 'Combat MG', rank = 4, count = 1 },
        { weapon = 'WEAPON_SNIPERRIFLE', label = 'Sniper Rifle', rank = 2, count = 1 },
        { weapon = 'WEAPON_MARKSMANRIFLE', label = 'Marksman Rifle', rank = 3, count = 1 },
        { weapon = 'WEAPON_RPG', label = 'RPG', rank = 4, count = 1 },
        -- Melee
        { weapon = 'WEAPON_NIGHTSTICK', label = 'Nightstick', rank = 0, count = 1 },
        { weapon = 'WEAPON_STUNGUN', label = 'Stun Gun', rank = 0, count = 1 },
        { weapon = 'WEAPON_BZGAS', label = 'BZ Tear Gas', rank = 1, count = 3 },
        -- Tactical Equipment
        { weapon = 'WEAPON_GRENADE', label = 'Grenade', rank = 1, count = 3 },
        { weapon = 'WEAPON_STICKYBOMB', label = 'Sticky Bomb', rank = 2, count = 2 },
        { weapon = 'WEAPON_MOLOTOV', label = 'Molotov Cocktail', rank = 3, count = 3 },
        { weapon = 'WEAPON_SMOKEGRENADE', label = 'Smoke Grenade', rank = 0, count = 2 },
        { weapon = 'WEAPON_FLARE', label = 'Flare', rank = 0, count = 3 },
    },
}
