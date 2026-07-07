Config = Config or {}

Config.Weather = {
    enabled = true,
    syncInterval = 10000,
    forceWeather = false,
    forcedWeatherType = 'EXTRASUNNY',
    dynamicWeather = true,
    weatherChangeTime = 600000,
    blackoutEnabled = true,
    blackoutChance = 0.001,
    blackoutMinDuration = 120000,
    blackoutMaxDuration = 600000,
    adminAce = 'admin.weather'
}

Config.WeatherTypes = {
    'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'SMOG',
    'FOGGY', 'OVERCAST', 'RAIN', 'THUNDER',
    'CLEARING', 'NEUTRAL', 'SNOW', 'BLIZZARD',
    'SNOWLIGHT', 'XMAS', 'HALLOWEEN'
}

Config.WeatherWeights = {
    EXTRASUNNY = 20,
    CLEAR = 25,
    CLOUDS = 15,
    SMOG = 5,
    FOGGY = 5,
    OVERCAST = 10,
    RAIN = 8,
    THUNDER = 3,
    CLEARING = 5,
    NEUTRAL = 2,
    SNOW = 1,
    BLIZZARD = 0.5,
    SNOWLIGHT = 0.5
}

Config.Time = {
    enabled = true,
    syncInterval = 30000,
    freezeTime = false,
    frozenHour = 12,
    frozenMinute = 0,
    timeScaleMultiplier = 1.0,
    enableNightCycle = true,
    sunriseHour = 6,
    sunsetHour = 20,
    nightBrightness = 0.1
}

Config.Blackout = {
    enabled = true,
    triggerOnAdminCommand = true,
    minDuration = 120000,
    maxDuration = 600000,
    affectStreetLights = true,
    affectBuildingLights = true,
    affectNeonLights = true
}
