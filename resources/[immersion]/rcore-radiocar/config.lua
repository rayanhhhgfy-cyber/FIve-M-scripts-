Config = Config or {}

Config.RadioCar = {
    enabled = true,
    maxRange = 50.0,
    maxVolume = 1.0,
    defaultVolume = 0.5,
    radioItem = 'radio_car',
    requireItem = true,
    enableUrlInput = true,
    enablePresets = true,
    enableVolumeControl = true,
    enableWhileDriving = true,
    enableWhileParked = true,
    enableForAllPassengers = true,
    enableExternalAudio = true,
    maxRadioCars = 1
}

Config.Presets = {
    { name = 'Radio LS', url = 'https://radio.stream/la', genre = 'Pop' },
    { name = 'Rock FM', url = 'https://radio.stream/rock', genre = 'Rock' },
    { name = 'Hip Hop', url = 'https://radio.stream/hiphop', genre = 'Hip Hop' },
    { name = 'Electronic', url = 'https://radio.stream/electronic', genre = 'Electronic' },
    { name = 'Jazz', url = 'https://radio.stream/jazz', genre = 'Jazz' },
    { name = 'Classical', url = 'https://radio.stream/classical', genre = 'Classical' },
    { name = 'Country', url = 'https://radio.stream/country', genre = 'Country' },
    { name = 'Reggae', url = 'https://radio.stream/reggae', genre = 'Reggae' }
}
