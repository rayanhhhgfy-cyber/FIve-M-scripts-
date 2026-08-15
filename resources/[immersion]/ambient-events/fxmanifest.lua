fx_version 'cerulean'
game 'gta5'

name 'ambient-events'
description 'Ambient unscripted world events system'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
