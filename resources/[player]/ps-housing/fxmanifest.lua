fx_version 'cerulean'
game 'gta5'

description 'ps-housing — Instance/Shell Housing with Furniture & Stashes'
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
    'ox_inventory',
    'ox_target',
    'Renewed-Garages'
}

lua54 'yes'
