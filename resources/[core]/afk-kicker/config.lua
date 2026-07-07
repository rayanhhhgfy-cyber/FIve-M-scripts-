Config = Config or {}

Config.AFK = {
    enabled = true,
    gracePeriod = 600000,
    warningTime = 60000,
    warningInterval = 30000,
    checkInterval = 15000,
    exemptAce = 'admin.afk',
    exemptJobs = { 'police', 'ambulance', 'mechanic' },
    maxAFKTime = 7200000,
    kickOnAFK = true,
    priorityLevel = 0
}

Config.ActivityTriggers = {
    movement = true,
    movementThreshold = 2.0,
    combat = true,
    vehicle = true,
    chat = true,
    voice = true,
    menu = true,
    targeting = true,
    inventory = true
}

Config.Messages = {
    afk_warning = 'You will be kicked for being AFK in %s seconds. Move or interact to stay.',
    afk_kick = 'You were kicked for being AFK for too long.',
    afk_additional = 'AFK Time: %s minutes'
}
