Config = Config or {}
Config.GangLaptop = Config.GangLaptop or {}

Config.GangLaptop = {
  itemName = 'gang_laptop',
  itemLabel = 'Gang Operations Laptop',
  toggleKey = 'F3',
  bossRank = 4,
  underbossRank = 3,
  enforcerRank = 2,
  recruitRank = 1,
  ranks = {
    [0] = 'Hanger-On',
    [1] = 'Recruit',
    [2] = 'Enforcer',
    [3] = 'Underboss',
    [4] = 'Boss'
  },
  applications = {
    roster = { label = 'Member Roster', icon = 'fas fa-users' },
    territory = { label = 'Territory Map', icon = 'fas fa-map-marked-alt' },
    stash = { label = 'Gang Stash', icon = 'fas fa-box' },
    contracts = { label = 'Contracts', icon = 'fas fa-file-contract' },
  },
  rateLimits = { recruit = 3, exile = 3, promote = 5, demote = 5 }
}
