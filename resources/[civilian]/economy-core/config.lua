Config = Config or {}
Config.EconomyCore = Config.EconomyCore or {}

Config.EconomyCore = {
  stockIndex = { enabled = true, fluctuationInterval = 3600, maxFluctuation = 0.1 },
  autoDebit = { enabled = true, gracePeriod = 72, lateFee = 0.1 },
  supplyChain = { enabled = true, depletionRate = 0.01, restockInterval = 3600 },
  vaultBoxes = { enabled = true, monthlyRent = 500, maxSlots = 10 },
  playerInsurance = { enabled = true, premiumRate = 0.05, coverageRate = 0.8, payoutOnTotalLoss = true },
  municipalGrid = { enabled = true, maintenanceInterval = 7200, luminosityDrop = 0.3 },
  laborAgreements = { enabled = true, minDuration = 168, severanceRate = 0.5 },
  franchiseSystem = { enabled = true, franchiseCost = 25000, maxFranchises = 3 },
  fuelMarket = { enabled = true, adjustmentInterval = 86400, basePrice = 2.50 },
  rateLimits = { buyShares = 5, openVault = 3, payInvoice = 5, franchise = 2 }
}
