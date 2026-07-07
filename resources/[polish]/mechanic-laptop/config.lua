Config = Config or {}
Config.MechanicLaptop = Config.MechanicLaptop or {}

Config.MechanicLaptop = {
  itemName = 'mechanic_laptop',
  itemLabel = 'Mechanic Shop Laptop',
  toggleKey = 'F2',
  allowedJob = 'mechanic',
  ownerGrade = 4,
  managerGrades = { 3, 4 },
  ranks = {
    [0] = 'Apprentice',
    [1] = 'Technician',
    [2] = 'Tuner',
    [3] = 'Master Mechanic',
    [4] = 'Shop Owner'
  },
  salaryGrades = {
    [0] = 25, [1] = 50, [2] = 75, [3] = 100, [4] = 150
  },
  partsSupply = {
    { item = 'engine_parts', label = 'Engine Block Kit', cost = 500, stock = 50 },
    { item = 'brake_parts', label = 'Brake Pad Set', cost = 150, stock = 100 },
    { item = 'transmission_parts', label = 'Transmission Gear Set', cost = 800, stock = 30 },
    { item = 'axle_parts', label = 'Axle Assembly', cost = 400, stock = 40 },
    { item = 'fuel_tank_parts', label = 'Fuel Tank Liner', cost = 300, stock = 50 },
    { item = 'body_panels', label = 'Reinforced Body Panels', cost = 600, stock = 25 },
    { item = 'turbo_kits', label = 'Performance Turbo Kit', cost = 2000, stock = 10 },
    { item = 'tire_set', label = 'Racing Tire Set', cost = 350, stock = 60 },
    { item = 'repair_kit_advanced', label = 'Advanced Repair Kit (Case)', cost = 2500, stock = 15 },
  },
  bankAccountName = 'Mechanic Shop',
  rateLimits = { hire = 3, fire = 3, promote = 5, orderParts = 5, sendInvoice = 10 }
}
