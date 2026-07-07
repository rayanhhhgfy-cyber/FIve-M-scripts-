Config = Config or {}
Config.BOLO = Config.BOLO or {}

Config.BOLO = {
    allowedJobs = { 'police', 'sheriff', 'state_police', 'cid' },
    adminGroups = { 'admin', 'superadmin', 'god' },

    types = {
        vehicle = { label = 'Vehicle', icon = 'fas fa-car' },
        person = { label = 'Person', icon = 'fas fa-user' },
        warrant = { label = 'Warrant', icon = 'fas fa-gavel' },
        property = { label = 'Property', icon = 'fas fa-home' },
    },
}
