Config = Config or {}
Config.LegalSystem = Config.LegalSystem or {}

Config.LegalSystem = {
  courtApp = {
    allowedJobs = { 'police', 'cid', 'judge', 'lawyer' },
    districtAttorneyJob = 'judge',
    maxSentences = { fine = 100000, prison = 240 },
  },
  retainerFees = { min = 500, max = 50000, contingencyMax = 0.35 },
  seizedAuctions = { bidIncrement = 100, duration = 86400 },
  businessLicense = { cost = 5000, renewalDays = 365 },
  ballisticRegistry = { enabled = true },
  bailBonds = { baseRate = 0.1, recidivismWindow = 48 },
  backgroundCheck = { allowedJobs = { 'police', 'cid', 'mechanic', 'ambulance' } },
  taxedItems = { 'food', 'clothing', 'electronics', 'weapons' },
  taxDefaults = { sales = 8.0, property = 1.5 },
  wireTransferThreshold = 100000,
  rateLimits = { caseFile = 3, retainer = 3, bid = 5, license = 2, bail = 2, backgroundCheck = 10, taxChange = 1, transferCheck = 10 }
}
