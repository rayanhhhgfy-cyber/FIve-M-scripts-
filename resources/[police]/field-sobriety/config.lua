Config = Config or {}
Config.FieldSobriety = {
    allowedJobs = { 'police', 'sheriff', 'statepolice' },
    tests = {
        walkLine = { label = 'Walk-and-Turn Test', duration = 8000, keys = { 'W', 'A', 'S', 'D' } },
        alphabet = { label = 'Alphabet Recitation', duration = 6000, letters = 8 },
        gaze = { label = 'Horizontal Gaze Nystagmus', duration = 5000 },
    },
}
