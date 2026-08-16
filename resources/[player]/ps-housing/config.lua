Config = Config or {}

Config.Housing = {
    maxProperties = 3,
    maxKeys = 10,
    enableFurniture = true,
    enableDecorating = true,
    enableStashes = true,
    enableGarages = true,
    enableWardrobes = true,
    defaultShell = 'medium',
    buyCooldown = 86400000,
    sellCooldown = 86400000,
    adminAce = 'admin.housing'
}

Config.Shells = {
    small = {
        label = 'Small Apartment',
        price = 50000,
        stashSlots = 20,
        stashWeight = 30000,
        garageSlots = 1,
        furnitureSlots = 10,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        interior = {
            shell = 'shell_v16low',
            ipl = 'apa_v_mp_h_01_a',
            offset = { x = 0.0, y = 0.0, z = 0.0 }
        }
    },
    medium = {
        label = 'Medium House',
        price = 150000,
        stashSlots = 30,
        stashWeight = 50000,
        garageSlots = 2,
        furnitureSlots = 20,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        interior = {
            shell = 'shell_v16mid',
            ipl = 'apa_v_mp_h_01_b',
            offset = { x = 0.0, y = 0.0, z = 0.0 }
        }
    },
    large = {
        label = 'Large Villa',
        price = 500000,
        stashSlots = 50,
        stashWeight = 100000,
        garageSlots = 4,
        furnitureSlots = 40,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        interior = {
            shell = 'shell_v16high',
            ipl = 'apa_v_mp_h_01_c',
            offset = { x = 0.0, y = 0.0, z = 0.0 }
        }
    }
}

Config.Furniture = {
    categories = {
        seating = { label = 'Seating', items = { 'chair', 'sofa', 'bench' } },
        tables = { label = 'Tables', items = { 'table', 'desk', 'coffee_table' } },
        storage = { label = 'Storage', items = { 'cabinet', 'shelf', 'wardrobe' } },
        lighting = { label = 'Lighting', items = { 'lamp', 'ceiling_light', 'floor_lamp' } },
        decor = { label = 'Decor', items = { 'painting', 'rug', 'plant', 'vase' } },
        electronics = { label = 'Electronics', items = { 'tv', 'radio', 'computer' } },
        beds = { label = 'Beds', items = { 'single_bed', 'double_bed', 'queen_bed' } },
        kitchen = { label = 'Kitchen', items = { 'fridge', 'oven', 'microwave' } }
    }
}

Config.HousingLocations = {
    {
        name = 'Popular St Apartment',
        description = 'Affordable studio in the heart of the city',
        shell = 'small',
        coords = { x = 200.0, y = -800.0, z = 30.0 },
        entrance = { x = 200.0, y = -800.0, z = 30.0 },
        exit = { x = 200.0, y = -790.0, z = 30.0 }
    },
    {
        name = 'Del Perro Heights',
        description = 'Modern high-rise with ocean views',
        shell = 'medium',
        coords = { x = -1550.0, y = -550.0, z = 35.0 },
        entrance = { x = -1550.0, y = -550.0, z = 35.0 },
        exit = { x = -1550.0, y = -540.0, z = 35.0 }
    },
    {
        name = 'Rockford Hills Estate',
        description = 'Luxury mansion in the hills',
        shell = 'large',
        coords = { x = -750.0, y = 450.0, z = 85.0 },
        entrance = { x = -750.0, y = 450.0, z = 85.0 },
        exit = { x = -750.0, y = 460.0, z = 85.0 }
    }
}
