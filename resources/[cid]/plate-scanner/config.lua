Config = Config or {}

Config.PlateScanner = {
    ScanRange = 50.0,
    ScanInterval = 2000,
    AutoScan = true,
    ManualScan = true,
    ScanCooldown = 1000,
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'cid', 'police' },
    RequireItem = false,
    ItemName = 'plate_scanner',
    AlertOnStolen = true,
    AlertOnWanted = true,
    AlertOnExpired = true,
    StoreLogs = true,
    MaxLogsPerDay = 1000,

    Flags = {
        Stolen = { label = 'STOLEN', color = 1, action = 'pullover' },
        Wanted = { label = 'WANTED', color = 1, action = 'apprehend' },
        Expired = { label = 'EXPIRED REGISTRATION', color = 3, action = 'fine' },
        NoInsurance = { label = 'NO INSURANCE', color = 3, action = 'fine' },
        Suspended = { label = 'SUSPENDED REGISTRATION', color = 3, action = 'impound' },
        Clean = { label = 'CLEAN', color = 2, action = 'none' }
    },

    UI = {
        ShowOverlay = true,
        OverlayPosition = 'top-center',
        OverlayDuration = 4000,
        SoundEnabled = true,
        SoundMatch = 'Event_Start_Text',
        SoundDict = 'GTAO_FM_Events_Soundset',
        ColorClean = { r = 0, g = 255, b = 0 },
        ColorAlert = { r = 255, g = 0, b = 0 }
    }
}
