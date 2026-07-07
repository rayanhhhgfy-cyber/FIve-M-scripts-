Config = Config or {}
Config.OfficerLockers = Config.OfficerLockers or {}

Config.OfficerLockers = {
    locations = {
        lspd = {
            label = 'LSPD Locker Room',
            coords = vector3(460.0, -1000.0, 25.0),
            radius = 8.0,
            allowedJobs = { 'police', 'sheriff', 'state_police' },
            stashSlots = 20,
            stashWeight = 10000,
        },
        cid = {
            label = 'CID Locker Room',
            coords = vector3(110.0, -750.0, 45.0),
            radius = 5.0,
            allowedJobs = { 'cid' },
            stashSlots = 15,
            stashWeight = 7500,
        },
    },

    adminGroups = { 'admin', 'superadmin', 'god' },
    maxDistance = 2.5,
}
