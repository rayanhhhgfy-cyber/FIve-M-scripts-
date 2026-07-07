Config = Config or {}

Config.Hunting = {
    blip = vector3(-688.45, 5831.23, 17.45),
    animals = {
        { model = 'a_c_deer', label = 'Deer', meat = 'venison', meatCount = { 4, 8 }, pelt = 'deer_pelt', price = 45 },
        { model = 'a_c_boar', label = 'Boar', meat = 'pork', meatCount = { 3, 6 }, pelt = 'boar_pelt', price = 35 },
        { model = 'a_c_coyote', label = 'Coyote', meat = 'game_meat', meatCount = { 2, 4 }, pelt = 'coyote_pelt', price = 25 },
        { model = 'a_c_mtlion', label = 'Mountain Lion', meat = 'game_meat', meatCount = { 3, 5 }, pelt = 'lion_pelt', price = 65 },
        { model = 'a_c_rabbit_01', label = 'Rabbit', meat = 'rabbit_meat', meatCount = { 1, 2 }, pelt = 'rabbit_pelt', price = 15 },
    },
    spawnZones = {
        { coords = vector3(-1600.45, 5200.34, 12.45), radius = 800 },
        { coords = vector3(400.67, 6500.23, 28.56), radius = 600 },
    },
    skinTime = 5000,
    sellLocation = vector3(-688.45, 5831.23, 17.45),
}
