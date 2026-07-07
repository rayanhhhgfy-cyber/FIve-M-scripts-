Config = Config or {}

Config.DNA = {
    CollectionTime = 5000,
    AnalysisTime = 8000,
    SwabItem = 'dna_swab',
    SwabLabel = 'DNA Swab',
    KitItem = 'dna_kit',
    KitLabel = 'DNA Collection Kit',
    StorageTime = 3600,
    MaxSamples = 100,
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'police', 'sheriff', 'statepolice' },

    CollectionZones = {
        MRPD = { coords = vector3(444.0, -980.0, 30.0), radius = 2.0 },
        Davis = { coords = vector3(365.0, -1604.0, 25.0), radius = 2.0 }
    },

    AnalysisLabs = {
        MRPD = { coords = vector3(443.0, -978.0, 30.0), radius = 1.5 },
        Davis = { coords = vector3(364.0, -1602.0, 25.0), radius = 1.5 }
    },

    TargetOptions = {
        collect = {
            icon = 'fas fa-vial',
            label = 'Collect DNA Sample',
            group = 'police',
            distance = 2.0
        },
        analyze = {
            icon = 'fas fa-microscope',
            label = 'Analyze DNA',
            group = 'police',
            distance = 1.5
        },
        database = {
            icon = 'fas fa-database',
            label = 'DNA Database',
            group = 'police',
            distance = 1.5
        }
    }
}
