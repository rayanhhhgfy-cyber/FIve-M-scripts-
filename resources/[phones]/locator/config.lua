Config = Config or {}

Config.Locator = {
    AppName = 'Find My',
    ScanRange = 100.0,
    ScanTime = 5000,
    Cooldown = 30000,
    MaxTracked = 10,
    UpdateInterval = 10000,
    BlipTime = 60000,
    RequirePhone = true,
    AllowTracking = true,

    TargetOptions = {
        track = { icon = 'fas fa-search-location', label = 'Track Player', distance = 2.0 },
        share = { icon = 'fas fa-share', label = 'Share Location', distance = 2.0 }
    },

    Colors = {
        friend = 2,
        tracked = 1,
        self = 5
    }
}
