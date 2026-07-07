Config = Config or {}
Config.Whitelist = Config.Whitelist or {}

Config.Whitelist = {
    enabled = true,
    bypassGroups = { 'admin', 'superadmin', 'god' },
    adminGroups = { 'admin', 'superadmin', 'god' },
    requireApplication = true,
    discordWebhook = '',
}
