Config = Config or {}

Config.Crutches = {
    itemName = 'crutches',
    speedMultiplier = 0.4,
    maxUseTime = 300000,
    brokenBoneRequired = true,
    autoRemoveOnHeal = true
}

Config.BrokenBones = {
    left_leg = { label = 'Left Leg Fracture', crutchTime = 300000 },
    right_leg = { label = 'Right Leg Fracture', crutchTime = 300000 },
    pelvis = { label = 'Pelvis Fracture', crutchTime = 600000 },
    foot = { label = 'Foot Fracture', crutchTime = 120000 }
}

Config.Animations = {
    walk = 'move_m@injured',
    idle = 'amb@world_human_crutch@male@idle_a'
}
