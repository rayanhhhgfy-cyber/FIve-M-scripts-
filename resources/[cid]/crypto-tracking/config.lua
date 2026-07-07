Config = Config or {}

Config.CryptoTracking = {
    Currencies = {
        bitcoin = { label = 'Bitcoin', symbol = 'BTC', decimals = 8 },
        ethereum = { label = 'Ethereum', symbol = 'ETH', decimals = 6 },
        monero = { label = 'Monero', symbol = 'XMR', decimals = 6 },
        litecoin = { label = 'Litecoin', symbol = 'LTC', decimals = 8 }
    },

    WalletTypes = {
        exchange = { label = 'Exchange Wallet', trackable = true },
        private = { label = 'Private Wallet', trackable = false },
        mixer = { label = 'Tumbler/Mixer', trackable = false },
        darknet = { label = 'Darknet Market', trackable = false }
    },

    TrackingLevels = {
        Basic = { label = 'Basic - Public Ledger', rank = 0, maxResults = 10 },
        Advanced = { label = 'Advanced - Cluster Analysis', rank = 2, maxResults = 50 },
        Deep = { label = 'Deep - Chain Tracing', rank = 4, maxResults = 200 }
    },

    AnalysisTime = 15000,
    MaxTrackHistory = 100,
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'cid', 'police' },
    FlagThresholds = {
        largeTransfer = 10000,
        suspiciousFrequency = 5,
        mixerInteraction = true,
        darknetInteraction = true
    },

    TargetOptions = {
        terminal = { icon = 'fas fa-chart-line', label = 'Crypto Tracking Terminal', group = 'cid', distance = 1.5 },
        analyze = { icon = 'fas fa-search', label = 'Analyze Wallet', group = 'cid', distance = 2.0 }
    }
}
