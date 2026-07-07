Config = Config or {}

Config.Welcome = {
    enabled = true,
    displayDelay = 5000,
    messageDuration = 10000,
    soundEnabled = true,
    soundName = 'welcome',
    soundVolume = 0.5
}

Config.StarterKit = {
    enabled = true,
    onFirstJoin = true,
    onNewCharacter = false,
    items = {
        { name = 'phone', count = 1, slot = 1, metadata = {} },
        { name = 'id_card', count = 1, slot = 2, metadata = { type = 'personal' } },
        { name = 'driver_license', count = 1, slot = 3, metadata = {} },
        { name = 'bread', count = 3, slot = 4, metadata = {} },
        { name = 'water', count = 3, slot = 5, metadata = {} },
        { name = 'bandage', count = 2, slot = 6, metadata = {} },
        { name = 'lighter', count = 1, slot = 7, metadata = {} }
    },
    money = {
        cash = 5000,
        bank = 5000
    }
}

Config.LandingPage = {
    enabled = true,
    title = 'Welcome to the City',
    subtitle = 'A new life awaits...',
    description = 'You have arrived in a city full of opportunities. Make your mark, build your legacy, and survive.',
    rules = {
        'Respect all players and staff',
        'No cheating, exploiting, or modding',
        'No RDM (Random Deathmatch)',
        'No VDM (Vehicle Deathmatch)',
        'Follow the server rules at all times',
        'Use common sense',
        'Have fun!'
    },
    buttons = {
        accept = 'I Understand',
        decline = nil
    }
}

Config.Messages = {
    firstJoin = 'Welcome to the city, %s! Your journey begins now.',
    returnJoin = 'Welcome back, %s!',
    starterKit = 'You received your starter kit. Check your inventory (%s).',
    newLife = 'A new chapter begins...'
}
