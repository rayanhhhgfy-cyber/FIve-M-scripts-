Config = Config or {}
Config.VoiceComms = Config.VoiceComms or {}

Config.VoiceComms = {
  policeFrequencies = { min = 1.0, max = 10.0 },
  cidFrequencies = { min = 11.0, max = 20.0 },
  policeJob = 'police',
  cidJob = 'cid',

  cidSilentMode = true,

  phoneSpeaker = {
    distance = 5.0,
    toggleCommand = 'speakerphone'
  },

  panicButton = {
    waypointDuration = 60000,
    autoBlipForChannel = true
  },

  militaryRadioClicks = true,

  rateLimits = {
    joinChannel = 5,
    leaveChannel = 5,
    speakerToggle = 5,
    panicWaypoint = 3
  }
}
