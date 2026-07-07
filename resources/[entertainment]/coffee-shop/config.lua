Config = Config or {}

Config.CoffeeShop = {
    locations = {
        {
            coords = vector3(113.36, -1083.27, 29.19),
            label = 'Coffee Shop - Downtown',
            takeCoords = vector3(116.58, -1080.45, 29.19),
            serveCoords = vector3(110.23, -1085.67, 29.19),
        },
    },
    drinks = {
        { name = 'espresso', label = 'Espresso', price = 4, caffeine = 20 },
        { name = 'latte', label = 'Latte', price = 5, caffeine = 15 },
        { name = 'cappuccino', label = 'Cappuccino', price = 5, caffeine = 15 },
        { name = 'mocha', label = 'Mocha', price = 6, caffeine = 18 },
        { name = 'cold_brew', label = 'Cold Brew', price = 5, caffeine = 25 },
    },
    paymentPerCoffee = 10,
}
