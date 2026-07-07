fx_version 'cerulean'
game 'gta5'

author 'Civilian Systems'
description 'City Hall — ID replacement and bank card issuing NPC in custom interior'
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
    'ox_target',
    'oxmysql',
}
