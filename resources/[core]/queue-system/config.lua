Config = Config or {}
Config.Queue = Config.Queue or {}

Config.Queue = {
    maxPlayers = 48,
    checkInterval = 3000,
    priorityGroups = { 'admin', 'superadmin', 'god', 'support', 'mod' },
    adminGroups = { 'admin', 'superadmin', 'god' },
    pullCooldown = 5,
}
