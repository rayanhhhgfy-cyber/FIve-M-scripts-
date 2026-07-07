fx_version 'cerulean'
game 'gta5'

description 'ox_inventory Configuration — Weapon Serials & Metadata'
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
    'ox_inventory',
    'ox_lib',
    'oxmysql',
    'qbx_core'
}

lua54 'yes'
