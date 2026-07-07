Config = Config or {}

Config.Webhooks = {
    ['all'] = '',
    ['kill'] = '',
    ['bank'] = '',
    ['admin'] = '',
    ['inventory'] = '',
    ['joinleave'] = '',
    ['chat'] = '',
    ['anticheat'] = '',
    ['vehicle'] = '',
    ['housing'] = '',
    ['gang'] = '',
    ['phone'] = '',
    ['dispatch'] = '',
    ['command'] = ''
}

Config.DefaultWebhook = 'all'

Config.Embeds = {
    color = 3066993,
    footer = 'FiveM Server Logs',
    timestamp = true
}

Config.LogLevels = {
    info = 3066993,
    success = 5763719,
    warn = 16763904,
    error = 15158332,
    critical = 10038562
}

Config.RateLimits = {
    enabled = true,
    maxPerSecond = 5,
    maxPerMinute = 60,
    maxPerEmbed = 25
}

Config.Filters = {
    enabled = true,
    blacklistKeywords = {},
    minLength = 1,
    maxLength = 2000
}
