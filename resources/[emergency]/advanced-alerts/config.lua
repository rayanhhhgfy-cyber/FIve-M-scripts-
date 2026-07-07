Config = Config or {}
Config.AdvancedAlerts = {
    alertTypes = {
        weather = { icon = 'fas fa-cloud', color = '#FFC107', label = 'Weather Warning' },
        amber = { icon = 'fas fa-child', color = '#FF5722', label = 'AMBER Alert' },
        emergency = { icon = 'fas fa-exclamation-triangle', color = '#F44336', label = 'Emergency Alert' },
        evacuation = { icon = 'fas fa-people-arrows', color = '#FF9800', label = 'Evacuation Order' },
        shelter = { icon = 'fas fa-home', color = '#4CAF50', label = 'Shelter Notice' },
        fema = { icon = 'fas fa-shield-alt', color = '#2196F3', label = 'FEMA Coordination' },
    },
    weatherEvents = {
        tornado = { path = { vector3(-1500.0, -500.0, 30.0), vector3(-500.0, 500.0, 30.0), vector3(500.0, 0.0, 30.0) }, speed = 50.0, damageRadius = 100.0 },
        hurricane = { path = { vector3(-3000.0, -1000.0, 10.0), vector3(-1500.0, 500.0, 10.0), vector3(0.0, 1000.0, 10.0) }, speed = 30.0, damageRadius = 200.0 },
    },
    evacuationZones = {
        { id = 'zone_beach', name = 'Vespucci Beach', coords = vector3(-1800.0, -1200.0, 13.0), radius = 500.0, shelter = vector3(-300.0, -700.0, 32.0) },
        { id = 'zone_docks', name = 'Port of LS', coords = vector3(-300.0, -2500.0, 10.0), radius = 400.0, shelter = vector3(200.0, -1000.0, 30.0) },
        { id = 'zone_airport', name = 'LS Airport', coords = vector3(-1040.0, -2750.0, 14.0), radius = 600.0, shelter = vector3(500.0, -1500.0, 30.0) },
    },
    shelters = {
        { id = 'shelter_cityhall', name = 'City Hall Shelter', coords = vector3(-300.0, -700.0, 32.0), capacity = 100 },
        { id = 'shelter_hospital', name = 'Hospital Bunker', coords = vector3(200.0, -1000.0, 30.0), capacity = 150 },
        { id = 'shelter_pd', name = 'Police Station Shelter', coords = vector3(500.0, -1500.0, 30.0), capacity = 80 },
    },
    adminGroups = { 'admin', 'superadmin', 'god' },
}
