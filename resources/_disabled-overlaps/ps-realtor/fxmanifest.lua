fx_version 'cerulean'
game 'gta5'

description 'ps-realtor — In-Game Real Estate Agent'
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
    'ps-housing',
    'Renewed-Banking'
}

lua54 'yes'
