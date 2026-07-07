fx_version 'cerulean'
game 'gta5'

description 'Multi-Character Slots — Up to 5 Profiles Per Player'
version '1.0.0'
author 'Elite FiveM Architecture'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'qbx_core'
}

lua54 'yes'
