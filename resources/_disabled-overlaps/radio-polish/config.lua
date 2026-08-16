Config = Config or {}
Config.Radio = {
    defaultChannel = 1,
    maxChannels = 50,
    restrictedChannels = {
        { channel = 1, groups = { 'police', 'sheriff', 'ems' } },
        { channel = 2, groups = { 'police', 'sheriff' } },
        { channel = 3, groups = { 'ems' } },
        { channel = 4, groups = { 'police' } },
        { channel = 5, groups = { 'police' } },
        { channel = 6, groups = { 'police' } },
    },
    toggleKey = 'N',
    cycleKey = 'M',
    voiceRange = 50.0,

    policeFrequencies = { 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 },
    policeJob = 'police',

    cidFrequencies = { 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0 },
    cidJob = 'cid',
    cidSilentMode = true,

    militaryRadioClicks = true,
    panicBlipOnChannel = true,
    useVoiceCommsIntegration = true,
}
