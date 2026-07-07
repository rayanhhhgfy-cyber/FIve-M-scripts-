Config = Config or {}

Config.SprayCans = {
    item = 'spray_can',
    label = 'Spray Can',
    price = 250
}

Config.Tagging = {
    duration = 5000,
    range = 2.0,
    cooldown = 60,
    expPerTag = 25,
    skillCheck = { difficulty = { 'easy', 'medium' }, areaSize = 60 }
}

Config.Police = {
    alertChance = 0.25,
    minPolice = 1,
    alertRadius = 100.0
}

Config.Cleanup = {
    cost = 1000,
    duration = 8000
}

Config.SprayColors = {
    { label = 'Red', r = 255, g = 0, b = 0 },
    { label = 'Blue', r = 0, g = 100, b = 255 },
    { label = 'Green', r = 0, g = 200, b = 0 },
    { label = 'Purple', r = 200, g = 0, b = 255 },
    { label = 'Yellow', r = 255, g = 255, b = 0 },
    { label = 'Orange', r = 255, g = 128, b = 0 }
}

Config.TagLocations = {
    { coords = vec3(245.0, -1820.0, 28.0), label = 'East Side Wall' },
    { coords = vec3(330.0, -2050.0, 21.0), label = 'South Side Underpass' },
    { coords = vec3(-1190.0, -1580.0, 5.0), label = 'Vespucci Boardwalk' },
    { coords = vec3(60.0, -1960.0, 21.0), label = 'Davis Ave Wall' },
    { coords = vec3(410.0, -1610.0, 30.0), label = 'Rancho Bridge' },
    { coords = vec3(980.0, -720.0, 58.0), label = 'Mirror Park Tunnel' }
}

Config.TagTypes = {
    { label = 'Crown', model = 'prop_graffiti_crown' },
    { label = 'Star', model = 'prop_graffiti_star' },
    { label = 'Skull', model = 'prop_graffiti_skull' },
    { label = 'Tag', model = 'prop_graffiti_tag' }
}
