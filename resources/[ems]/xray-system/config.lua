Config = Config or {}

Config.XRay = {
    enabled = true,
    scanTime = 8000,
    resultTime = 3000,
    maxDistance = 2.0,
    requireMedicJob = true,
    medicJobName = 'ambulance'
}

Config.XRayLocations = {
    { name = 'Pillbox X-Ray Room 1', coords = { x = 320.0, y = -590.0, z = 43.0 }, heading = 0.0 },
    { name = 'Pillbox X-Ray Room 2', coords = { x = 325.0, y = -590.0, z = 43.0 }, heading = 0.0 }
}

Config.ScanResults = {
    bone_fractures = { label = 'Bone Fractures', icon = 'fas fa-bone', treatable = true },
    bullet_fragments = { label = 'Bullet Fragments', icon = 'fas fa-bullseye', treatable = true },
    internal_bleeding = { label = 'Internal Bleeding', icon = 'fas fa-tint', treatable = true },
    shrapnel = { label = 'Shrapnel', icon = 'fas fa-shield-halved', treatable = true },
    organ_perforation = { label = 'Organ Perforation', icon = 'fas fa-heart', treatable = true },
    no_issues = { label = 'No Issues Detected', icon = 'fas fa-check', treatable = false }
}
