Config = Config or {}

Config.Pharmacy = {
    enabled = true,
    requireNoEMS = true,
    emsJobName = 'ambulance',
    maxItemsPerPurchase = 5,
    cooldown = 30000
}

Config.PharmacyLocations = {
    { name = 'Pillbox Pharmacy', coords = { x = 300.0, y = -570.0, z = 43.0 }, ped = 's_f_y_scrubs_01', heading = 180.0 },
    { name = 'Sandy Shores Pharmacy', coords = { x = 1850.0, y = 3680.0, z = 34.0 }, ped = 's_f_y_scrubs_01', heading = 0.0 }
}

Config.PharmacyItems = {
    bandage = { label = 'Bandage', price = 50, weight = 100, stock = 50 },
    painkillers = { label = 'Painkillers', price = 100, weight = 50, stock = 30 },
    antiseptic = { label = 'Antiseptic', price = 75, weight = 150, stock = 20 },
    medical_tape = { label = 'Medical Tape', price = 25, weight = 50, stock = 40 },
    splint = { label = 'Splint', price = 150, weight = 200, stock = 15 },
    suture_kit = { label = 'Suture Kit', price = 300, weight = 300, stock = 10 },
    iv_bag = { label = 'IV Bag', price = 200, weight = 200, stock = 10 },
    morphine = { label = 'Morphine', price = 500, weight = 50, stock = 5 }
}
