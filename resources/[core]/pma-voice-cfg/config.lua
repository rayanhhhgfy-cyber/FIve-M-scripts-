Config = Config or {}

Config.Voice = {
    enableProximity = true,
    enableRadio = true,
    enableMegaphone = true,
    enablePhone = true,
    enable3dAudio = true,
    defaultRange = 5.0,
    ranges = { 3.0, 5.0, 10.0, 20.0, 50.0 },
    radioRange = 60.0,
    megaphoneRange = 100.0,
    megaphoneVolume = 0.9,
    voiceModes = {
        { name = 'Whisper',     range = 3.0,   grid = 1 },
        { name = 'Normal',      range = 5.0,   grid = 2 },
        { name = 'Loud',        range = 10.0,  grid = 3 },
        { name = 'Shouting',    range = 20.0,  grid = 4 },
        { name = 'Outside',     range = 50.0,  grid = 5 }
    }
}

Config.Radio = {
    enableRadio = true,
    maxFrequencies = 20,
    defaultFrequency = 1,
    frequencyRangeMin = 1,
    frequencyRangeMax = 999,
    radioItem = 'radio',
    requireRadioItem = true,
    radioItemDeleteOnLeave = false,
    enableRadioClicks = true,
    clickSounds = {
        join = { audio = 'audio_on', volume = 0.3 },
        leave = { audio = 'audio_off', volume = 0.3 }
    },
    allowedJobs = {
        police = {
            frequencies = { 1, 2, 3 },
            encrypted = true
        },
        ambulance = {
            frequencies = { 4, 5 },
            encrypted = true
        },
        mechanic = {
            frequencies = { 6 },
            encrypted = false
        }
    }
}

Config.Megaphone = {
    toggleCommand = 'megaphone',
    rangeMultiplier = 2.0,
    soundEffect = 'megaphone',
    enableInVehicle = true,
    requirePoliceVehicle = true,
    policeVehicleClasses = { 18, 19, 20 }
}

Config.Zones = {
    interiorDropoff = 0.5,
    exteriorRange = 2.0
}

Config.Phone = {
    enableProximityOverride = false,
    phoneRange = 3.0
}
