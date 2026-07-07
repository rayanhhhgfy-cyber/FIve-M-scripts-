Config = Config or {}

Config.GangCreation = {
    cost = 50000,
    minMembers = 3,
    cooldown = 7 * 24 * 60 * 60,
    npcCoords = vec3(-565.62, -169.55, 38.78),
    npcLabel = 'Gang Recruiter'
}

Config.Hierarchy = {
    { grade = 0, label = 'Recruit', permissions = { 'invite', 'stash_browse' } },
    { grade = 1, label = 'Member', permissions = { 'invite', 'stash_browse', 'deposit' } },
    { grade = 2, label = 'Enforcer', permissions = { 'invite', 'kick', 'stash_browse', 'deposit', 'withdraw' } },
    { grade = 3, label = 'Underboss', permissions = { 'invite', 'kick', 'promote', 'demote', 'stash_browse', 'deposit', 'withdraw' } },
    { grade = 4, label = 'Leader', permissions = { 'all' } }
}

Config.Reputation = {
    killsPerPoint = 5,
    turfsPerPoint = 2,
    heistBonus = 50,
    ranks = {
        { rep = 0, title = 'Street Rat' },
        { rep = 100, title = 'Hustler' },
        { rep = 300, title = 'Gangster' },
        { rep = 600, title = 'Shot Caller' },
        { rep = 1000, title = 'Kingpin' }
    }
}

Config.Stash = {
    slots = 50,
    weight = 100000
}

Config.GangLabels = {
    'The Lost Ones',
    'Vagos Locos',
    'East Side Riders',
    'North Avenue Kings',
    'Los Santos Vipers',
    'The Ballas'
}

Config.Blip = {
    sprite = 284,
    color = 1,
    scale = 0.8,
    label = 'Gang HQ'
}

Config.GangHQs = {
    { coords = vec3(15.13, -1101.45, 29.95), label = 'East LS HQ' },
    { coords = vec3(320.72, -2048.14, 20.98), label = 'South LS HQ' },
    { coords = vec3(90.13, -1935.91, 20.87), label = 'Vespucci HQ' }
}
