Config = Config or {}

Config.Morgue = {
    enabled = true,
    coldStorageSlots = 10,
    autopsyTableCount = 2,
    requireCID = true,
    cidJobName = 'police',
    storageTime = 604800000
}

Config.MorgueLocations = {
    { name = 'Body Storage 1', coords = { x = 280.0, y = -590.0, z = 43.0 }, type = 'storage' },
    { name = 'Body Storage 2', coords = { x = 285.0, y = -590.0, z = 43.0 }, type = 'storage' },
    { name = 'Autopsy Table 1', coords = { x = 275.0, y = -585.0, z = 43.0 }, type = 'autopsy' },
    { name = 'Autopsy Table 2', coords = { x = 275.0, y = -580.0, z = 43.0 }, type = 'autopsy' },
    { name = 'Evidence Locker', coords = { x = 285.0, y = -595.0, z = 43.0 }, type = 'evidence' }
}

Config.AutopsyResults = {
    cause_of_death = { label = 'Cause of Death', icon = 'fas fa-skull' },
    time_of_death = { label = 'Estimated Time of Death', icon = 'fas fa-clock' },
    weapon_type = { label = 'Weapon Classification', icon = 'fas fa-gun' },
    bullet_caliber = { label = 'Bullet Caliber', icon = 'fas fa-circle' },
    toxicology = { label = 'Toxicology Report', icon = 'fas fa-flask' },
    dna_evidence = { label = 'DNA Sample Collected', icon = 'fas fa-dna' },
    fingerprint_evidence = { label = 'Fingerprints Lifted', icon = 'fas fa-fingerprint' }
}
