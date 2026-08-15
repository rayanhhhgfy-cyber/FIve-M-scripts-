fx_version 'cerulean'
game 'gta5'

name 'shop-ownership'
description 'Player-owned shops system'

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
