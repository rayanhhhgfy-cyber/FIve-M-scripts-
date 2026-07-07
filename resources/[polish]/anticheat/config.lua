Config = Config or {}
Config.Anticheat = {
    detectionInterval = 5000,
    maxHealthChanges = 5,
    maxArmourChanges = 5,
    maxSpectateDistance = 500.0,
    maxVelocity = 250.0,
    maxTeleportDistance = 300.0,
    maxStrikes = 3,
    weaponBlacklist = {
        'WEAPON_RAILGUN',
        'WEAPON_MINIGUN',
        'WEAPON_RPG',
    },
    logWebhook = '',
}
