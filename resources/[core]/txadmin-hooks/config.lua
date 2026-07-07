Config = Config or {}

Config.AutoRestartWarning = true
Config.RestartWarningTime = 10
Config.RestartWarningMessage = 'Server restart in %s minutes. Please find a safe location and log out.'

Config.ScheduledRestartInterval = 6
Config.ScheduledRestartTime = '06:00'

Config.AdminAcePermission = 'admin.txadmin'

Config.Commands = {
    restart_warning = 'serverwarning',
    force_restart = 'forcerestart',
    server_status = 'serverstatus',
    player_list = 'plist',
    resource_health = 'reshealth'
}

Config.ResourceHealthCheckInterval = 60000
Config.HealthCriticalResources = {
    'oxmysql',
    'ox_lib',
    'qbx_core',
    'ox_target',
    'ox_inventory',
    'pma-voice'
}

Config.TxAdminApiPort = 40120
Config.TxAdminApiEnabled = true
