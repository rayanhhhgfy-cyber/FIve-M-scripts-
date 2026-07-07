Config = Config or {}

Config.AnonymityBridge = {
    BridgeZones = {
        { coords = vector3(114.0, -745.0, 45.0), radius = 1.5, label = 'Anonymity Terminal' },
        { coords = vector3(434.0, -982.0, 30.0), radius = 1.5, label = 'Anonymity Terminal' }
    },

    QueryTypes = {
        phone = { label = 'Phone Number Lookup', time = 5000, rank = 0 },
        plate = { label = 'Anonymized Plate Lookup', time = 4000, rank = 0 },
        name = { label = 'Name Search (Anonymous)', time = 6000, rank = 1 },
        address = { label = 'Address Lookup', time = 7000, rank = 2 },
        financial = { label = 'Financial Records', time = 10000, rank = 3 },
        deep = { label = 'Deep Background Check', time = 15000, rank = 4 }
    },

    AnonymityLevels = {
        Basic = { label = 'Basic VPN', rank = 0, queriesPerDay = 20, logRetention = 7 },
        Advanced = { label = 'Advanced Proxy Chain', rank = 2, queriesPerDay = 50, logRetention = 30 },
        Total = { label = 'Total Anonymity', rank = 4, queriesPerDay = 100, logRetention = 90 }
    },

    AuditLog = true,
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'cid', 'police' },
    QueryCooldown = 3000,
    ApprovalRequired = false,

    TargetOptions = {
        terminal = { icon = 'fas fa-mask', label = 'Open Anonymity Bridge', group = 'cid', distance = 1.5 },
        history = { icon = 'fas fa-history', label = 'Query History', group = 'cid', distance = 1.5 }
    }
}
