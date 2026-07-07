Config = Config or {}

Config.CriminalLaptop = {
    ItemName = 'criminal_laptop',
    ItemLabel = 'Criminal Laptop',
    ToggleKey = 'F3',
    BatteryMax = 100,
    BatteryDrain = 0.5,

    DarkWebCategories = {
        weapons = { label = 'Illegal Weapons', rank = 0 },
        drugs = { label = 'Narcotics', rank = 0 },
        documents = { label = 'Fake Documents', rank = 1 },
        malware = { label = 'Malware & Tools', rank = 2 },
        data = { label = 'Stolen Data', rank = 2 },
        services = { label = 'Illegal Services', rank = 3 },
        contracts = { label = 'Contracts', rank = 4 }
    },

    Applications = {
        browser = { label = 'Dark Web Browser', icon = 'fas fa-globe' },
        market = { label = 'Black Market', icon = 'fas fa-shopping-cart' },
        chat = { label = 'Encrypted Chat', icon = 'fas fa-comment-dots' },
        wallet = { label = 'Crypto Wallet', icon = 'fas fa-wallet' },
        tools = { label = 'Hacking Tools', icon = 'fas fa-skull' },
        settings = { label = 'Settings', icon = 'fas fa-cog' }
    },

    Colors = { background = '#0a0a0a', primary = '#00ff41', secondary = '#003b00', text = '#00ff41', danger = '#ff0000' }
}
