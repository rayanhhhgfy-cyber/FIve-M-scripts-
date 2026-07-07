Config = Config or {}
Config.GodDashboard = Config.GodDashboard or {}

Config.GodDashboard = {
    adminGroups = { 'admin', 'superadmin', 'god' },

    vehicleCategories = {
        {
            name = 'Super',
            icon = 'fas fa-rocket',
            models = { 'adder', 'zentorno', 't20', 'osiris', 'reaper', 'nero', 'pfister811', 'tempesta', 'italirsx', 'vagner' },
        },
        {
            name = 'Sports',
            icon = 'fas fa-car',
            models = { 'elegy2', 'comet2', 'banshee', 'buffalo', 'carbonizzare', 'jester', 'massacro', 'feltzer2', 'khamelion', 'ninef' },
        },
        {
            name = 'Muscle',
            icon = 'fas fa-car-side',
            models = { 'blade', 'buccaneer', 'clique', 'dominator', 'dukes', 'gauntlet', 'hotknife', 'nightshade', 'phoenix', 'sabregt' },
        },
        {
            name = 'Off-Road',
            icon = 'fas fa-truck',
            models = { 'bifta', 'bf400', 'blazer', 'dubsta3', 'kamacho', 'mesa3', 'rancherxl', 'rebel2', 'sandking', 'trophytruck' },
        },
        {
            name = 'Motorcycles',
            icon = 'fas fa-motorcycle',
            models = { 'akuma', 'bati', 'carbonrs', 'double', 'hakuchou', 'pcj', 'ruffian', 'sanctus', 'sovereign', 'thrust' },
        },
        {
            name = 'Emergency',
            icon = 'fas fa-ambulance',
            models = { 'police', 'police2', 'police3', 'police4', 'sheriff', 'ambulance', 'firetruk', 'polbike', 'polmav', 'predator' },
        },
        {
            name = 'Commercial',
            icon = 'fas fa-truck-moving',
            models = { 'benson', 'bobcatxl', 'boxville', 'mule', 'packer', 'phantom', 'pounder', 'rubble', 'stockade', 'tiptruck' },
        },
        {
            name = 'Helicopters',
            icon = 'fas fa-helicopter',
            models = { 'buzzard', 'frogger', 'maverick', 'seasparrow', 'supervolito', 'swift', 'valkyrie', 'volatus', 'savage', 'hydra' },
        },
    },

    maxPreviewDistance = 10.0,
    previewAlpha = 120,
    rotateSpeed = 5.0,
    moveSpeed = 0.5,
}
