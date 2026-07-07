fx_version 'cerulean'
game 'gta5'

author 'CID Systems'
description 'Undercover Vehicle Pool - Identity management, trackers, signal scanner'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
    'oxmysql',
    'pma-voice',
}
