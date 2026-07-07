Config = Config or {}
Config.CIDLaptop = Config.CIDLaptop or {}

Config.CIDLaptop = {
  itemName = 'cid_laptop',
  itemLabel = 'CID Operations Laptop',
  toggleKey = 'F2',
  allowedJob = 'cid',
  leadershipGrades = { 5, 6, 7, 8, 9, 10 },
  minGradeForHire = 5,
  minGradeForFire = 5,
  minGradeForPromote = 4,
  salaryGrades = {
    [0] = 100, [1] = 125, [2] = 150, [3] = 175, [4] = 200,
    [5] = 250, [6] = 300, [7] = 350, [8] = 400, [9] = 450, [10] = 500
  },
  applications = {
    roster = { label = 'Agent Roster', icon = 'fas fa-user-secret' },
    wiretaps = { label = 'Wiretap Monitoring', icon = 'fas fa-headphones' },
    flaggedTransfers = { label = 'Flagged Transactions', icon = 'fas fa-money-check-alt' },
    forensicCaseView = { label = 'Forensic Cases', icon = 'fas fa-microscope' },
    seizedAuctions = { label = 'Seized Asset Auctions', icon = 'fas fa-gavel' },
  },
  rateLimits = { hire = 3, fire = 3, promote = 5, demote = 5 }
}
