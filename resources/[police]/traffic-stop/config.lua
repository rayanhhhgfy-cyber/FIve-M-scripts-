Config = Config or {}
Config.TrafficStop = {
    allowedJobs = { 'police', 'sheriff', 'statepolice' },
    approachDistance = 5.0,
    fineCategories = {
        speeding = { label = 'Speeding', min = 100, max = 500 },
        reckless = { label = 'Reckless Driving', min = 300, max = 1500 },
        running_red = { label = 'Running Red Light', min = 150, max = 400 },
        expired_reg = { label = 'Expired Registration', min = 100, max = 300 },
        no_license = { label = 'Driving Without License', min = 500, max = 2000 },
        dui = { label = 'DUI', min = 1000, max = 5000 },
        hit_and_run = { label = 'Hit and Run', min = 1000, max = 8000 },
        reckless_endanger = { label = 'Reckless Endangerment', min = 2000, max = 10000 },
    },
    warningTypes = { 'Verbal Warning', 'Written Warning', 'Fix-It Ticket' },
}
