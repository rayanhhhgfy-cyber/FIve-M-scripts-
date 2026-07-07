Config = Config or {}

Config.Bodycam = {
    ItemName = 'bodycam',
    ItemLabel = 'Body Camera',
    ToggleKey = 'L',
    RecordTimeMax = 3600,
    UploadTime = 5000,
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'police', 'sheriff', 'statepolice', 'cid' },
    RecordIndicator = true,
    RecordIndicatorColor = { r = 255, g = 0, b = 0 },
    AutoRecordOnDuty = true,
    StorageLimit = 50,
    VideoQuality = '720p',
    NightVision = false,

    UI = {
        ShowHUD = true,
        HUDPosition = 'top-right',
        RecordBlinkInterval = 500,
        ShowTimestamp = true,
        ShowBattery = true,
        BatteryMax = 100,
        BatteryDrainRate = 1
    },

    Logging = {
        LogUploads = true,
        LogToggle = true,
        WebhookEnabled = true
    }
}
