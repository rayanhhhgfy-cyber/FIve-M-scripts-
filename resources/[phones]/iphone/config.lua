Config = Config or {}

Config.Phone = {
    ItemName = 'iphone17',
    ItemLabel = 'iPhone 17 Pro Max',
    ToggleKey = 'F1',
    BatteryMax = 100,
    BatteryDrain = 0.0,
    SignalRange = 500.0,

    Apps = {
        phone = { label = 'Phone', icon = 'fas fa-phone' },
        messages = { label = 'Messages', icon = 'fas fa-sms' },
        contacts = { label = 'Contacts', icon = 'fas fa-address-book' },
        camera = { label = 'Camera', icon = 'fas fa-camera' },
        gallery = { label = 'Gallery', icon = 'fas fa-images' },
        settings = { label = 'Settings', icon = 'fas fa-cog' },
        gps = { label = 'GPS', icon = 'fas fa-map-marker-alt' },
        clock = { label = 'Clock', icon = 'fas fa-clock' },
        notes = { label = 'Notes', icon = 'fas fa-sticky-note' },
        contact_card = { label = 'Contact Card', icon = 'fas fa-address-card' },
        locator = { label = 'Find My', icon = 'fas fa-search-location' },
        vpn = { label = 'VPN', icon = 'fas fa-shield-alt' },
        taxi = { label = 'Taxi', icon = 'fas fa-taxi' },
        blackchat = { label = 'BlackChat', icon = 'fas fa-user-secret' },
        x = { label = 'X', icon = 'fab fa-x-twitter' },
        tiktok = { label = 'TikTok', icon = 'fab fa-tiktok' },
        ubereats = { label = 'Uber Eats', icon = 'fas fa-utensils' },
        banking = { label = 'Banking', icon = 'fas fa-university' },
        weather = { label = 'Weather', icon = 'fas fa-cloud-sun' },
        gigs = { label = 'Gigs', icon = 'fas fa-briefcase' },
        emergency = { label = '911', icon = 'fas fa-phone-alt' },
        safari = { label = 'Safari', icon = 'fas fa-globe' },
        calculator = { label = 'Calculator', icon = 'fas fa-calculator' },
        calendar = { label = 'Calendar', icon = 'fas fa-calendar' },
        wallet = { label = 'Wallet', icon = 'fas fa-wallet' },
        vehicles = { label = 'Vehicles', icon = 'fas fa-car' }
    },

    Contacts = { maxContacts = 50 },
    Messages = { maxMessages = 200, maxPerContact = 50 },
    Camera = { maxPhotos = 100 },
    Notes = { maxNotes = 50, maxLength = 500 },

    Colors = {
        background = '#1a1a2e',
        primary = '#e94560',
        secondary = '#0f3460',
        text = '#ffffff',
        accent = '#16213e'
    }
}
