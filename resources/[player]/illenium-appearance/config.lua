Config = Config or {}

Config.Appearance = {
    enableClothingStores = true,
    enableBarbers = true,
    enableTattooParlors = true,
    enableSurgeons = true,
    enableOutfitSaving = true,
    maxOutfits = 15,
    defaultComponents = {},
    adminAce = 'admin.appearance'
}

Config.ClothingStores = {
    {
        name = 'Binco',
        coords = { x = 425.0, y = -800.0, z = 29.0 },
        blip = { sprite = 73, color = 0 }
    },
    {
        name = 'SubUrban',
        coords = { x = -160.0, y = -300.0, z = 39.0 },
        blip = { sprite = 73, color = 3 }
    },
    {
        name = 'Ponsonbys',
        coords = { x = -715.0, y = -155.0, z = 37.0 },
        blip = { sprite = 73, color = 1 }
    }
}

Config.Barbers = {
    {
        name = 'Barber Shop',
        coords = { x = -815.0, y = -180.0, z = 37.0 },
        blip = { sprite = 71, color = 0 }
    },
    {
        name = 'Bob Mulet',
        coords = { x = -30.0, y = -150.0, z = 57.0 },
        blip = { sprite = 71, color = 0 }
    }
}

Config.TattooParlors = {
    {
        name = 'Tattoo Shop',
        coords = { x = 320.0, y = -200.0, z = 54.0 },
        blip = { sprite = 75, color = 1 }
    }
}

Config.Surgeons = {
    {
        name = 'Plastic Surgeon',
        coords = { x = -550.0, y = -200.0, z = 38.0 },
        blip = { sprite = 78, color = 0 }
    }
}

Config.ClothingCategories = {
    masks = { label = 'Masks', componentId = 1 },
    upper = { label = 'Upper Body', componentId = 11 },
    lower = { label = 'Lower Body', componentId = 4 },
    shoes = { label = 'Shoes', componentId = 6 },
    accessories = { label = 'Accessories', componentId = 7 },
    undershirt = { label = 'Undershirt', componentId = 8 },
    torso = { label = 'Torso', componentId = 3 },
    decals = { label = 'Decals', componentId = 10 },
    hats = { label = 'Hats & Helmets', componentId = 'p0' },
    glasses = { label = 'Glasses', componentId = 'p1' },
    ears = { label = 'Ears', componentId = 'p2' },
    watches = { label = 'Watches', componentId = 'p6' },
    bracelets = { label = 'Bracelets', componentId = 'p7' },
    bags = { label = 'Bags', componentId = 5 }
}

Config.PropCategories = {
    { id = 0, name = 'Hats', max = 50 },
    { id = 1, name = 'Glasses', max = 50 },
    { id = 2, name = 'Ears', max = 50 },
    { id = 6, name = 'Watches', max = 50 },
    { id = 7, name = 'Bracelets', max = 50 }
}
