Config = Config or {}
Config.Immersion = Config.Immersion or {}

Config.Immersion = {
  carrySystem = {
    enabled = true,
    carryBone = 'SKEL_Pelvis',
    escortBone = 'R_Hand',
    carryAnim = { dict = 'missfinale_c2mcs_1', clip = 'fin_c2_mcs_1_loaded', flag = 49 },
    escortAnim = { dict = 'mp_arresting', clip = 'idle', flag = 49 },
    unstickCommand = 'unstick-carry',
    carryDistance = 0.8,
  },
  avMediaShacks = {
    enabled = true,
    syncInterval = 1000,
  },
  djLighting = {
    enabled = true,
    venues = {
      { coords = vector3(-1550.0, -980.0, 13.0), label = 'Tequi-La-La', linkedDJS = { 'dj_deck_1' } },
    }
  },
  instashots = {
    enabled = true,
    maxPostsPerDay = 10,
    famePerLike = 1,
    famePerFollower = 5,
  },
  camping = {
    enabled = true,
    tentItem = 'camping_tent',
    campfireItem = 'campfire_kit',
    chairItem = 'camping_chair',
    deployDuration = 5000,
  },
  racing = {
    enabled = true,
    escrowRequired = true,
    minPrizePool = 1000,
    maxRacers = 8,
  },
  rcToys = {
    enabled = true,
    vehicles = {
      'rcbandito',
    },
    controlDuration = 120,
  },
  forensicCamera = { enabled = true },
  outdoorFurniture = { enabled = true },
  meteorologicalApp = { enabled = true },
  rateLimits = { carry = 5, deploy = 3, startRace = 2, rcControl = 3 }
}
