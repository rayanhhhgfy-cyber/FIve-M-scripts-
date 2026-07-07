Config = Config or {}
Config.VehicleShop = {
    Showrooms = {
        {
            coords = vector3(-40.0, -1110.0, 26.4),
            name = 'Premium Showroom',
            spawn = vector3(-50.0, -1115.0, 26.4),
            heading = 180.0,
            vehicles = {
                { model = 'adder', label = 'Adder', price = 900000, category = 'super', financeAmount = 50000 },
                { model = 'zentorno', label = 'Zentorno', price = 750000, category = 'super', financeAmount = 40000 },
                { model = 'osiris', label = 'Osiris', price = 650000, category = 'super', financeAmount = 35000 },
                { model = 't20', label = 'T20', price = 800000, category = 'super', financeAmount = 45000 },
                { model = 'nero', label = 'Nero', price = 720000, category = 'super', financeAmount = 40000 }
            }
        },
        {
            coords = vector3(-31.0, -1110.0, 26.4),
            name = 'Sports Showroom',
            spawn = vector3(-40.0, -1115.0, 26.4),
            heading = 180.0,
            vehicles = {
                { model = 'banshee', label = 'Banshee', price = 350000, category = 'sports', financeAmount = 20000 },
                { model = 'carbonizzare', label = 'Carbonizzare', price = 280000, category = 'sports', financeAmount = 15000 },
                { model = 'jester', label = 'Jester', price = 300000, category = 'sports', financeAmount = 18000 },
                { model = 'ninef', label = 'Ninef', price = 250000, category = 'sports', financeAmount = 14000 },
                { model = 'elegy', label = 'Elegy', price = 200000, category = 'sports', financeAmount = 12000 }
            }
        }
    },
    TestDriveDuration = 120,
    FinanceOptions = { enabled = true, minDownPayment = 10, maxPayments = 12, interestRate = 0.05 },
    TargetOptions = {
        browse = { icon = 'fas fa-car', label = 'Browse Vehicles', distance = 2.5 },
        spawn = { icon = 'fas fa-arrow-right', label = 'Spawn Vehicle', distance = 5.0 }
    },
    Colors = {
        { label = 'Red', value = 27 },
        { label = 'Blue', value = 64 },
        { label = 'Green', value = 35 },
        { label = 'Black', value = 0 },
        { label = 'White', value = 134 },
        { label = 'Yellow', value = 88 },
        { label = 'Orange', value = 38 },
        { label = 'Purple', value = 116 },
        { label = 'Pink', value = 135 },
        { label = 'Silver', value = 111 }
    }
}
