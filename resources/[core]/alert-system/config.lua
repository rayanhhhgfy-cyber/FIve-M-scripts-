Config = Config or {}
Config.Alerts = Config.Alerts or {}

Config.Alerts = {
    adminGroups = { 'admin', 'superadmin', 'god' },
    defaultDuration = 15000,

    presets = {
        { id = 'weather', label = 'Weather Alert', color = 16753920 },
        { id = 'emergency', label = 'Emergency', color = 15158332 },
        { id = 'news', label = 'News Bulletin', color = 3066993 },
        { id = 'maintenance', label = 'Server Maintenance', color = 10181046 },
        { id = 'event', label = 'Event Announcement', color = 15277667 },
    },
}
