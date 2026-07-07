-- ox_inventory item definitions for meth-lab-empire
-- Add these to your ox_inventory/data/items.lua or run the SQL insert

local items = {
    -- Precursor Chemicals
    ['pseudoephedrine'] = {
        label = 'Pseudoephedrine',
        weight = 100,
        stack = true,
        close = true,
        description = 'Common cold medicine. Also a key meth precursor.'
    },
    ['lithium'] = {
        label = 'Lithium',
        weight = 200,
        stack = true,
        close = true,
        description = 'Light metal used in batteries and chemistry.'
    },
    ['anhydrous_ammonia'] = {
        label = 'Anhydrous Ammonia',
        weight = 300,
        stack = true,
        close = true,
        description = 'Concentrated ammonia. Volatile and suspicious.'
    },
    ['red_phosphorus'] = {
        label = 'Red Phosphorus',
        weight = 150,
        stack = true,
        close = true,
        description = 'Reactive chemical. Heavily monitored by authorities.'
    },
    ['p2p'] = {
        label = 'P2P',
        weight = 200,
        stack = true,
        close = true,
        description = 'Phenyl-2-propanone. Precursor for high-grade meth.'
    },
    ['methylamine'] = {
        label = 'Methylamine',
        weight = 250,
        stack = true,
        close = true,
        description = 'Industrial chemical. 55 gallon drum not included.'
    },
    ['battery_acid'] = {
        label = 'Battery Acid',
        weight = 400,
        stack = true,
        close = true,
        description = 'Sulfuric acid from car batteries. Nasty stuff.'
    },
    ['lye'] = {
        label = 'Lye',
        weight = 100,
        stack = true,
        close = true,
        description = 'Sodium hydroxide. Drain cleaner and meth ingredient.'
    },
    ['toxic_waste'] = {
        label = 'Toxic Waste',
        weight = 500,
        stack = true,
        close = false,
        description = 'Chemical byproduct. Must be disposed of properly!'
    },

    -- Finished Products
    ['meth_blue_sky'] = {
        label = 'Blue Sky Meth',
        weight = 50,
        stack = true,
        close = true,
        description = 'High-purity methamphetamine. Premium product.'
    },
    ['meth_crystal'] = {
        label = 'Crystal Meth',
        weight = 40,
        stack = true,
        close = true,
        description = 'Ultra-pure crystal meth. Top of the line.'
    },
    ['meth_street'] = {
        label = 'Street Meth',
        weight = 60,
        stack = true,
        close = true,
        description = 'Average quality street meth. Gets the job done.'
    },
}

return items
