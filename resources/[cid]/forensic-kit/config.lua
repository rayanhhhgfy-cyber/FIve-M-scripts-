Config = Config or {}
Config.ForensicKit = {
    allowedJob = 'cid',
    evidenceTypes = {
        fingerprint = { label = 'Fingerprint', collectTime = 5000 },
        dna = { label = 'DNA Sample', collectTime = 6000 },
        photograph = { label = 'Scene Photo', collectTime = 3000 },
        fiber = { label = 'Fiber Sample', collectTime = 4000 },
    },
}
