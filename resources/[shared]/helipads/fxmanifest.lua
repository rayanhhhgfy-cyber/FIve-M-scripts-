fx_version 'cerulean'
game 'gta5'

author 'Shared Systems'
description 'Helipad system — aircraft spawn points at locations across the map'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_target',
}
