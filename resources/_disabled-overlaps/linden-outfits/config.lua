Config = Config or {}

Config.Outfits = {
    maxOutfits = 30,
    enableInHouses = true,
    enableInApartments = true,
    enableInLockers = true,
    defaultCategory = 'casual'
}

Config.OutfitCategories = {
    casual = { label = 'Casual', icon = 'fas fa-tshirt' },
    formal = { label = 'Formal', icon = 'fas fa-user-tie' },
    sport = { label = 'Sport', icon = 'fas fa-running' },
    tactical = { label = 'Tactical', icon = 'fas fa-shield-halved' },
    medical = { label = 'Medical', icon = 'fas fa-medkit' },
    police = { label = 'Police', icon = 'fas fa-badge-police' },
    mechanic = { label = 'Mechanic', icon = 'fas fa-wrench' }
}
