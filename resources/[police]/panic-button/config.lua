Config = Config or {}

Config.PanicButton = {
    Cooldown = 60000,
    AlertDuration = 300000,
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'police', 'sheriff', 'statepolice', 'cid' },
    Keybind = 'P',

    Alerts = {
        OfficerNeedsAssistance = { label = 'Officer Needs Assistance', color = 1, urgent = true }
    },

    Notification = {
        BlipTime = 60000,
        SoundEnabled = true,
        SoundName = 'Event_Start_Text',
        SoundDict = 'GTAO_FM_Events_Soundset',
        ScreenFlash = true,
        DispatchMessage = true,
        DispatchBlip = true
    },

    AutomaticAlerts = {
        OnDeath = true,
        OnAssaulted = true,
        HealthThreshold = 20
    }
}
