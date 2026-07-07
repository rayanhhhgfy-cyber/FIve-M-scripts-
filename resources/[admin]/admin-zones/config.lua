Config = Config or {}

Config.AdminZones = {
    defaultRadius = 2.0,
    zoneTypes = {
        armory = { label = 'Armory', icon = 'shield-halved' },
        shop = { label = 'Shop', icon = 'cart-shopping' },
        storage = { label = 'Storage', icon = 'warehouse' },
        wardrobe = { label = 'Wardrobe', icon = 'shirt' },
        duty = { label = 'Duty', icon = 'right-left' },
        garage = { label = 'Garage', icon = 'car' },
    },
    interactionDistance = 3.0,
    armorUniforms = {
        { name = 'police_uniform', label = 'Police Uniform' },
    },
    defaultVehicles = {
        'police', 'police2', 'police3', 'police4',
        'sheriff', 'sheriff2', 'fbi', 'fbi2',
    }
}
