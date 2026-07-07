Config = Config or {}
Config.DutyBlips = {
    updateInterval = 5000,
    allowedJobs = { 'police', 'sheriff', 'statepolice', 'cid' },
    blips = {
        police = { sprite = 1, color = 3, scale = 0.7 },
        sheriff = { sprite = 1, color = 5, scale = 0.7 },
        statepolice = { sprite = 1, color = 17, scale = 0.7 },
        cid = { sprite = 1, color = 57, scale = 0.7 },
    },
    defaultSprite = 1,
    defaultColor = 3,
    showLabel = true,
    labelFormat = '{name} [{job}]',
    showOnRadar = true,
}
