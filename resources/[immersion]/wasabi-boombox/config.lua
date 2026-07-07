Config = Config or {}

Config.Boombox = {
    enabled = true,
    itemName = 'boombox',
    maxRange = 30.0,
    maxVolume = 1.0,
    defaultVolume = 0.5,
    maxBoomboxes = 1,
    boomboxModel = 'prop_boombox_01',
    boomboxDestroyable = true,
    boomboxDespawnTime = 3600000
}

Config.Presets = {
    { name = 'Radio LS', url = 'https://radio.stream/la' },
    { name = 'Rock FM', url = 'https://radio.stream/rock' },
    { name = 'Hip Hop', url = 'https://radio.stream/hiphop' },
    { name = 'Electronic', url = 'https://radio.stream/electronic' }
}
