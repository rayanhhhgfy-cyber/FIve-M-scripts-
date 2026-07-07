Config = Config or {}

Config.Triage = {
    enabled = true,
    scanTime = 5000,
    maxDistance = 2.0,
    requireMedicJob = true,
    medicJobName = 'ambulance'
}

Config.DiagnosticTypes = {
    bullet_wounds = { label = 'Bullet Wounds', icon = 'fas fa-bullseye', priority = 1 },
    hemorrhage = { label = 'Internal Bleeding', icon = 'fas fa-tint', priority = 1 },
    fractures = { label = 'Fractures', icon = 'fas fa-bone', priority = 2 },
    concussion = { label = 'Concussion', icon = 'fas fa-brain', priority = 2 },
    organ_damage = { label = 'Organ Damage', icon = 'fas fa-heart', priority = 1 },
    shock = { label = 'Shock', icon = 'fas fa-bolt', priority = 2 },
    infection = { label = 'Infection Risk', icon = 'fas fa-biohazard', priority = 3 }
}

Config.TreatmentOptions = {
    suture = { label = 'Suture Wound', time = 10000, item = 'suture_kit', fixes = { 'bullet_wounds' } },
    surgery = { label = 'Emergency Surgery', time = 30000, fixes = { 'organ_damage', 'hemorrhage' } },
    cast = { label = 'Apply Cast', time = 15000, item = 'medic_kit', fixes = { 'fractures' } },
    antiseptic = { label = 'Apply Antiseptic', time = 5000, item = 'antiseptic', fixes = { 'infection' } },
    morphine = { label = 'Administer Morphine', time = 3000, item = 'morphine', fixes = { 'shock' } }
}
