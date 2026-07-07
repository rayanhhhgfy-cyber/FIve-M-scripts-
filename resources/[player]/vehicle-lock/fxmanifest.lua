fx_version 'cerulean'
game 'gta5'

author 'Vehicle Systems'
description 'Press L to lock/unlock your owned vehicle with honk confirmation'
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
    'qbx_core',
    'oxmysql',
}
