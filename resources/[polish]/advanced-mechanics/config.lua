Config = Config or {}
Config.AdvancedMechanics = Config.AdvancedMechanics or {}

Config.AdvancedMechanics = {
  fieldRepairs = {
    basicKit = {
      item = 'repair_kit_basic',
      duration = 30000,
      maxEngineRestore = 300.0,
      canFixTires = false,
      allowedJobs = {},
    },
    advancedKit = {
      item = 'repair_kit_advanced',
      duration = 45000,
      maxEngineRestore = 600.0,
      canFixTires = true,
      allowedJobs = { 'mechanic' },
    }
  },

  workshopZones = {
    {
      name = 'LS Auto Repair',
      coords = vector3(-339.67, -135.23, 39.01),
      radius = 8.0,
      lifts = {
        { coords = vector3(-339.67, -135.23, 38.5), heading = 180.0, label = 'Bay 1' },
        { coords = vector3(-342.45, -128.78, 38.5), heading = 0.0, label = 'Bay 2' },
        { coords = vector3(-345.0, -132.0, 38.5), heading = 90.0, label = 'Bay 3' },
      }
    }
  },

  components = {
    engine = { label = 'Engine Block', restoreItem = 'engine_parts', maxHealth = 1000.0, costPerUnit = 100 },
    body = { label = 'Body Panels', restoreItem = 'body_panels', maxHealth = 1000.0, costPerUnit = 50 },
    fuel_tank = { label = 'Fuel Tank', restoreItem = 'fuel_tank_parts', maxHealth = 1000.0, costPerUnit = 75 },
    axle = { label = 'Axle Assembly', restoreItem = 'axle_parts', maxHealth = 1000.0, costPerUnit = 80 },
    transmission = { label = 'Transmission', restoreItem = 'transmission_parts', maxHealth = 1000.0, costPerUnit = 120 },
    brakes = { label = 'Brake Pads', restoreItem = 'brake_parts', maxHealth = 1000.0, costPerUnit = 40 },
  },

  fieldKitAnim = { dict = 'mini@repair', clip = 'fixing_a_player', flag = 16 },
  workshopAnim = { dict = 'amb@prop_human_movie_bulb@base', clip = 'base', flag = 16 },

  rateLimits = {
    fieldRepair = 3,
    diagnose = 5,
    workshopRepair = 3
  }
}
