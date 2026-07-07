Config = Config or {}

Config.Wiretaps = {
    InstallTime = 15000,
    TapRange = 50.0,
    MaxActiveTaps = 5,
    TapDuration = 604800,
    RequireDuty = true,
    MinRank = 2,
    AllowedJobs = { 'cid', 'police' },
    RequireWarrant = true,
    KitItem = 'wiretap_kit',
    KitLabel = 'Wiretap Kit',
    WarrantyTime = 7200,

    Audio = {
        Enabled = false,
        InterceptRange = 30.0,
        Quality = 'medium'
    },

    SMSIntercept = true,
    CallLogIntercept = true,
    GPSIntercept = true,
    AutoRecord = true,

    EvidenceStorage = {
        AutoFile = true,
        RetentionDays = 90,
        MaxEvidencePerTap = 1000
    },

    TargetOptions = {
        install = { icon = 'fas fa-phone-tap', label = 'Install Wiretap', group = 'cid', distance = 2.0, minRank = 2 },
        console = { icon = 'fas fa-headset', label = 'Wiretap Console', group = 'cid', distance = 1.5, minRank = 2 },
        review = { icon = 'fas fa-file-audio', label = 'Review Recordings', group = 'cid', distance = 1.5 }
    },

    ConsoleZones = {
        { coords = vector3(112.0, -770.0, 45.0), radius = 2.0 },
        { coords = vector3(434.0, -980.0, 30.0), radius = 2.0 }
    }
}
