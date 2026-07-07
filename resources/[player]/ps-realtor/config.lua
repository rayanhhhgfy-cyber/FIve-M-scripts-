Config = Config or {}

Config.Realtor = {
    enableRealtorJob = true,
    realtorJobName = 'realtor',
    commissionRate = 0.05,
    maxListings = 50,
    listingFee = 500,
    listingDuration = 604800000,
    viewCooldown = 5000,
    adminAce = 'admin.realtor'
}

Config.ListingTypes = {
    house = {
        label = 'House',
        icon = 'fas fa-home',
        maxPrice = 10000000,
        minPrice = 10000
    },
    apartment = {
        label = 'Apartment',
        icon = 'fas fa-building',
        maxPrice = 5000000,
        minPrice = 5000
    },
    commercial = {
        label = 'Commercial',
        icon = 'fas fa-store',
        maxPrice = 20000000,
        minPrice = 50000
    }
}

Config.RealtorLocations = {
    { name = 'Downtown Office', coords = { x = -100.0, y = -620.0, z = 36.0 }, ped = 'csb_tom' },
    { name = 'Sandy Shores Office', coords = { x = 1850.0, y = 3700.0, z = 33.0 }, ped = 'csb_tonya' }
}

Config.ForSaleSigns = {
    model = 'prop_mp_vanity_glass',
    offset = { x = 0.0, y = -2.0, z = 0.0 },
    scale = 1.0
}
