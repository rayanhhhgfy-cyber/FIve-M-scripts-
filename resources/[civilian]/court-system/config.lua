Config = Config or {}
Config.CourtSystem = {
    courtLocations = {
        {
            id = 'ls_court',
            name = 'Los Santos Superior Court',
            coords = vector3(-547.1, -210.6, 38.2),
            interior = vector3(-547.1, -210.6, 38.2),
            judgeBench = vector3(-547.1, -210.6, 38.2),
            juryBox = vector3(-547.1, -210.6, 38.2),
            prosecutorDesk = vector3(-547.1, -210.6, 38.2),
            defenseDesk = vector3(-547.1, -210.6, 38.2),
            gallery = vector3(-547.1, -210.6, 38.2),
        },
    },
    jobs = {
        judge = { grade = 0, label = 'Judge' },
        prosecutor = { grade = 0, label = 'Prosecutor' },
        defense_lawyer = { grade = 0, label = 'Defense Lawyer' },
        bailiff = { grade = 0, label = 'Bailiff' },
        clerk = { grade = 0, label = 'Court Clerk' },
    },
    sentencing = {
        misdemeanor = { min = 30, max = 300, fineMin = 500, fineMax = 5000 },
        felony = { min = 300, max = 3600, fineMin = 5000, fineMax = 50000 },
        capital = { min = 3600, max = 28800, fineMin = 50000, fineMax = 500000 },
    },
    bailMultiplier = 0.1,
    appealCost = 50000,
    juryPoolSize = 12,
    juryRequired = 8,
    evidenceSlots = 10,
}
