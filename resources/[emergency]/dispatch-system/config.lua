Config = Config or {}
Config.Dispatch = Config.Dispatch or {}

Config.Dispatch = {
    dispatchJobs = { 'police', 'sheriff', 'state_police', 'ems', 'cid' },
    adminGroups = { 'admin', 'superadmin', 'god' },
    callTimeouts = {
        pending = 120,
        dispatched = 600,
        on_scene = 900,
    },
    maxDistance = 2.5,
    cooldown = 10,
}
