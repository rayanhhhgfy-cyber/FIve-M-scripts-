Config = Config or {}
Config.Tuning = Config.Tuning or {}

Config.Tuning = {
    locations = {
        {
            id = 'ls_customs',
            label = 'LS Customs',
            coords = vector3(-369.0, -115.0, 23.0),
            radius = 6.0,
            spawn = vector4(-364.0, -108.0, 22.0, 0.0),
        },
        {
            id = 'sandy_tuning',
            label = 'Sandy Shores Tuning',
            coords = vector3(1055.0, 2665.0, 39.0),
            radius = 6.0,
            spawn = vector4(1050.0, 2660.0, 38.0, 0.0),
        },
    },

    maxDistance = 3.0,
    useBank = true,

    categories = {
        visual = 'Visual Mods',
        performance = 'Performance',
        colors = 'Colors & Paint',
        extras = 'Extras',
    },

    mods = {
        -- === VISUAL ===
        { id = 'spoiler', label = 'Spoiler', cat = 'visual', modType = 0, max = 3, prices = { 500, 750, 1000 } },
        { id = 'front_bumper', label = 'Front Bumper', cat = 'visual', modType = 1, max = 3, prices = { 800, 1200, 1500 } },
        { id = 'rear_bumper', label = 'Rear Bumper', cat = 'visual', modType = 2, max = 3, prices = { 800, 1200, 1500 } },
        { id = 'side_skirt', label = 'Side Skirt', cat = 'visual', modType = 3, max = 3, prices = { 600, 900, 1200 } },
        { id = 'exhaust', label = 'Exhaust', cat = 'visual', modType = 4, max = 3, prices = { 400, 700, 1000 } },
        { id = 'grille', label = 'Grille', cat = 'visual', modType = 6, max = 3, prices = { 300, 500, 800 } },
        { id = 'hood', label = 'Hood', cat = 'visual', modType = 7, max = 3, prices = { 600, 1000, 1400 } },
        { id = 'fender', label = 'Fender', cat = 'visual', modType = 8, max = 2, prices = { 500, 800 } },
        { id = 'roof', label = 'Roof', cat = 'visual', modType = 10, max = 3, prices = { 400, 700, 1000 } },
        -- === PERFORMANCE ===
        { id = 'engine', label = 'Engine', cat = 'performance', modType = 11, max = 4, prices = { 2000, 4000, 8000, 15000 } },
        { id = 'brakes', label = 'Brakes', cat = 'performance', modType = 12, max = 3, prices = { 1000, 2000, 4000 } },
        { id = 'transmission', label = 'Transmission', cat = 'performance', modType = 13, max = 3, prices = { 1500, 3000, 6000 } },
        { id = 'suspension', label = 'Suspension', cat = 'performance', modType = 15, max = 3, prices = { 1200, 2500, 5000 } },
        { id = 'turbo', label = 'Turbo', cat = 'performance', modType = 18, max = 1, prices = { 5000 } },
        -- === WHEELS ===
        { id = 'wheels', label = 'Wheels', cat = 'visual', modType = 23, max = 5, prices = { 500, 1000, 1500, 2500, 4000 } },
        { id = 'wheel_color', label = 'Wheel Color', cat = 'colors', modType = 'wheel_color', max = 1, prices = { 500 } },
        -- === LIGHTING ===
        { id = 'neon', label = 'Neon Lights', cat = 'extras', modType = 'neon', max = 1, prices = { 2000 } },
        { id = 'window_tint', label = 'Window Tint', cat = 'extras', modType = 'window', max = 4, prices = { 300, 500, 800, 1200 } },
        { id = 'xenon', label = 'Xenon Headlights', cat = 'extras', modType = 'xenon', max = 1, prices = { 1000 } },
    },

    colorPresets = {
        { label = 'Classic Black', r = 10, g = 10, b = 10, price = 0 },
        { label = 'Pure White', r = 255, g = 255, b = 255, price = 0 },
        { label = 'Race Red', r = 200, g = 20, b = 20, price = 500 },
        { label = 'Ocean Blue', r = 20, g = 100, b = 200, price = 500 },
        { label = 'Lime Green', r = 50, g = 200, b = 50, price = 500 },
        { label = 'Sunset Orange', r = 230, g = 120, b = 20, price = 500 },
        { label = 'Deep Purple', r = 100, g = 20, b = 150, price = 500 },
        { label = 'Gold', r = 200, g = 170, b = 20, price = 1000 },
        { label = 'Chrome Silver', r = 180, g = 180, b = 190, price = 1500 },
        { label = 'Matte Army Green', r = 70, g = 90, b = 50, price = 2000 },
    },
}
