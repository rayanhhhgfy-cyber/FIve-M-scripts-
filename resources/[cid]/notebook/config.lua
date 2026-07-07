Config = Config or {}

Config.Notebook = {
    ItemName = 'cid_notebook',
    ItemLabel = 'CID Notebook',
    MaxNotes = 100,
    MaxNoteLength = 1000,
    SyncInterval = 60000,
    RequireDuty = false,
    RequireItem = true,
    AllowedJobs = { 'cid', 'police' },
    EnableTags = true,
    EnableCaseLinking = true,
    EnableAttachments = false,
    EnableSharing = true,
    MaxSharedUsers = 10,

    Categories = {
        general = { label = 'General', color = '#FFFFFF' },
        suspect = { label = 'Suspect Notes', color = '#FF6B6B' },
        evidence = { label = 'Evidence Notes', color = '#FFD93D' },
        surveillance = { label = 'Surveillance', color = '#6BCB77' },
        interview = { label = 'Interview Notes', color = '#4D96FF' },
        timeline = { label = 'Timeline', color = '#9B59B6' },
        lead = { label = 'Leads', color = '#FF8C32' }
    },

    Keybind = 'F5',

    UI = {
        ShowNotifications = true,
        AutoSave = true,
        AutoSaveInterval = 30000
    }
}
