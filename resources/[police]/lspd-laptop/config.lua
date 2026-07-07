Config = Config or {}
Config.LSPDLaptop = Config.LSPDLaptop or {}

Config.LSPDLaptop = {
  itemName = 'lspd_laptop',
  itemLabel = 'LSPD Laptop',
  toggleKey = 'F2',
  minGradeForHire = 10,
  minGradeForFire = 10,
  minGradeForPromote = 8,
  leadershipGrades = { 10, 11, 12 },
  allowedJob = 'police',
  salaryGrades = {
    [0] = 50,
    [1] = 75,
    [2] = 100,
    [3] = 125,
    [4] = 150,
    [5] = 175,
    [6] = 200,
    [7] = 225,
    [8] = 250,
    [9] = 275,
    [10] = 300,
    [11] = 350,
    [12] = 400,
  },

  applications = {
    roster = { label = 'Roster Management', icon = 'fas fa-users' },
    warrants = { label = 'Active Warrants', icon = 'fas fa-gavel' },
    backgroundCheck = { label = 'Background Check', icon = 'fas fa-search' },
    incidents = { label = 'Incident Reports', icon = 'fas fa-file-alt' },
    crimeCenter = { label = 'Real-Time Crime Center', icon = 'fas fa-map-marked-alt' },
    k9Ops = { label = 'K-9 Ops Center', icon = 'fas fa-dog' },
  },

  crimeCenter = {
    officerGpsPollInterval = 5000,
    callLifetimeMinutes = 120,
    maxLprHitsDisplayed = 50,
    blipColors = {
      officer = 3,
      call911 = 1,
      drone = 5,
      lprHit = 66,
      k9Unit = 47,
    }
  },

  k9Ops = {
    maxActiveK9 = 3,
    deployRank = 2,
    breeds = { 'German Shepherd', 'Belgian Malinois', 'Labrador Retriever', 'Bloodhound' },
    specializations = { 'Patrol', 'Narcotics', 'Explosives', 'Tracking' },
    trackDuration = 120,
    searchRadius = 30.0,
  },

  rateLimits = {
    hire = 3,
    fire = 3,
    promote = 5,
    demote = 5,
    backgroundCheck = 10,
    call911 = 5,
    crimeCenterRefresh = 10,
    k9Deploy = 3,
    k9Command = 10,
  }
}
