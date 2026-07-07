Config = Config or {}
Config.FleetManagement = Config.FleetManagement or {}

Config.FleetManagement = {
  componentDegradation = { enabled = true, ratePerKm = 0.5, checkInterval = 5000 },
  p2pVehicleLots = {
    enabled = true,
    lotCoords = vector3(120.0, -1080.0, 29.0),
    maxListingsPerPlayer = 3,
    listingFee = 100,
    salesTax = 0.05
  },
  cargoFreight = {
    enabled = true,
    weightStations = {
      { coords = vector3(450.0, -1970.0, 25.0), label = 'LS Freight Scale' },
      { coords = vector3(1200.0, -3100.0, 20.0), label = 'Port Weigh Station' },
    },
    maxWeight = 50000,
    overWeightFine = 1000
  },
  odometer = { enabled = true, persistenceInterval = 300 },
  blowoutPhysics = { enabled = true, velocityThreshold = 30.0, debrisDmgChance = 0.2 },
  mobileWorkshop = { enabled = true, toolKitItem = 'mechanic_toolkit', jobRestriction = 'mechanic' },
  carChopping = { enabled = true, chopZones = {
    { coords = vector3(1000.0, -2000.0, 30.0), label = 'Sandy Shores Chop Shop' },
  }},
  towCitations = { enabled = true, citationFine = 150, impoundTime = 86400 },
  windowTint = { enabled = true, occlusionLevels = { none = 0.0, light = 0.3, medium = 0.5, dark = 0.8, limo = 1.0 } },
  rateLimits = { listVehicle = 3, buyVehicle = 3, weigh = 10, chop = 3, cite = 5 }
}
