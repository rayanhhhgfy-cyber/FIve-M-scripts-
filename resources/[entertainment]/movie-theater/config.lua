Config = Config or {}

Config.MovieTheater = {
    locations = {
        {
            entrance = vector3(-435.67, 2810.45, 27.00),
            interior = vector3(-435.67, 2810.45, 27.00),
            label = 'Cinema - Paleto Bay',
            screenCoords = vector3(-438.00, 2812.00, 27.00),
            seatCoords = vector3(-435.00, 2815.00, 27.00),
            ticketPrice = 15,
        },
        {
            entrance = vector3(244.00, 304.00, 105.00),
            interior = vector3(244.00, 304.00, 105.00),
            label = 'Cinema - Vinewood',
            screenCoords = vector3(242.00, 306.00, 105.00),
            seatCoords = vector3(246.00, 304.00, 105.00),
            ticketPrice = 20,
        },
    },
    movies = {
        { id = 1, name = 'The Last Heist', duration = 120, genre = 'Action' },
        { id = 2, name = 'Ocean Drive', duration = 105, genre = 'Drama' },
        { id = 3, name = 'Pinewood Express', duration = 95, genre = 'Comedy' },
        { id = 4, name = 'Midnight Chase', duration = 110, genre = 'Thriller' },
    },
    snacks = {
        { name = 'popcorn', label = 'Popcorn', price = 5 },
        { name = 'soda_m', label = 'Medium Soda', price = 3 },
        { name = 'soda_l', label = 'Large Soda', price = 4 },
        { name = 'candy', label = 'Candy', price = 2 },
    },
    seatAnims = {
        sitDict = 'anim@amb@cigarsmoke@',
        sitAnim = 'enter_front_crowd',
    },
}
