Config = Config or {}
Config.OperationsCenter = Config.OperationsCenter or {}

Config.OperationsCenter = {
    AllowedJobs = { 'cid' },
    MinRank = 3,
    GpsSyncInterval = 3000,
    MaxTeamSize = 8,

    ThreatLevels = {
        low = { label = 'Low', color = '#00ff00' },
        medium = { label = 'Medium', color = '#ffcc00' },
        high = { label = 'High', color = '#ff6600' },
        critical = { label = 'CRITICAL', color = '#ff0000' },
    },

    BriefingRoom = {
        coords = vector3(112.0, -748.0, 45.0),
        label = 'CID Operations Center',
        icon = 'fas fa-map-marked-alt',
    },

    OperationStatuses = {
        'active',
        'paused',
        'completed',
        'archived',
    },
}
