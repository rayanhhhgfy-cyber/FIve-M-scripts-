Config = Config or {}

Config.Workbench = {
    coords = vec3(716.14, -962.78, 30.4),
    radius = 2.0,
    label = 'Weapon Workbench',
    icon = 'fas fa-hammer'
}

Config.Police = {
    minPolice = 3,
    alertChance = 0.65,
    alertRadius = 150.0
}

Config.Crafting = {
    duration = 8000,
    skillCheck = { difficulty = { 'easy', 'medium', 'hard' }, areaSize = 50 }
}

Config.Recipes = {
    ['WEAPON_PISTOL'] = {
        label = 'Pistol',
        parts = {
            ['weapon_part_frame'] = 1,
            ['weapon_part_barrel'] = 1,
            ['weapon_part_spring'] = 2,
            ['weapon_part_grip'] = 1
        },
        ammo = 'AMMO_PISTOL',
        ammoCount = 24,
        skillLevel = 1
    },
    ['WEAPON_SMG'] = {
        label = 'SMG',
        parts = {
            ['weapon_part_frame'] = 2,
            ['weapon_part_barrel'] = 2,
            ['weapon_part_spring'] = 3,
            ['weapon_part_grip'] = 2,
            ['weapon_part_mechanism'] = 1
        },
        ammo = 'AMMO_SMG',
        ammoCount = 30,
        skillLevel = 2
    },
    ['WEAPON_ASSAULTRIFLE'] = {
        label = 'Assault Rifle',
        parts = {
            ['weapon_part_frame'] = 3,
            ['weapon_part_barrel'] = 3,
            ['weapon_part_spring'] = 4,
            ['weapon_part_grip'] = 3,
            ['weapon_part_mechanism'] = 2,
            ['weapon_part_scope_rail'] = 1
        },
        ammo = 'AMMO_RIFLE',
        ammoCount = 30,
        skillLevel = 3
    }
}

Config.PartItems = {
    weapon_part_frame = { label = 'Weapon Frame', weight = 500 },
    weapon_part_barrel = { label = 'Weapon Barrel', weight = 400 },
    weapon_part_spring = { label = 'Spring Kit', weight = 100 },
    weapon_part_grip = { label = 'Pistol Grip', weight = 200 },
    weapon_part_mechanism = { label = 'Firing Mechanism', weight = 300 },
    weapon_part_scope_rail = { label = 'Scope Rail', weight = 250 }
}

Config.SkillLevels = {
    { exp = 0, label = 'Amateur' },
    { exp = 500, label = 'Apprentice' },
    { exp = 1500, label = 'Journeyman' },
    { exp = 3000, label = 'Expert' },
    { exp = 5000, label = 'Master' }
}

Config.ExpPerCraft = 100

Config.Locations = {
    { coords = vec3(716.14, -962.78, 30.4), label = 'Sewer Workshop' },
    { coords = vec3(1088.68, -3196.83, -38.99), label = 'Abandoned Bunker' }
}
