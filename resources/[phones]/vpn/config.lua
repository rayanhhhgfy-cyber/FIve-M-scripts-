Config = Config or {}

Config.VPN = {
    AppName = 'VPN Anonymizer',
    ItemName = 'vpn_license',
    ItemLabel = 'VPN License',

    Servers = {
        usa = { label = 'USA - East', latency = 30, anonymous = false },
        netherlands = { label = 'Netherlands', latency = 50, anonymous = false },
        switzerland = { label = 'Switzerland', latency = 60, anonymous = true },
        panama = { label = 'Panama', latency = 80, anonymous = true },
        russia = { label = 'Russia', latency = 100, anonymous = true },
        darknet = { label = 'DarkNet Relay', latency = 150, anonymous = true, maxSecurity = true }
    },

    Features = {
        HideIP = true,
        EncryptTraffic = true,
        SpoofLocation = false,
        KillSwitch = true,
        NoLogPolicy = true
    },

    Subscription = {
        Cost = 500,
        Duration = 2592000,
        AutoRenew = true
    },

    UI = {
        ColorConnected = { r = 0, g = 255, b = 0 },
        ColorDisconnected = { r = 255, g = 0, b = 0 },
        ShowStatus = true,
        StatusPosition = 'top-left'
    }
}
