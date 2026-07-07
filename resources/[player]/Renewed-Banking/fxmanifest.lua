fx_version 'cerulean'
game 'gta5'

description 'Renewed-Banking — Multi-account Banking System'
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
    'ox_lib',
    'oxmysql',
    'qbx_core',
    'ox_inventory'
}

lua54 'yes'
