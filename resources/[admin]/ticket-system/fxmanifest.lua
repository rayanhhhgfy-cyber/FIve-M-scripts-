fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Jules'
description 'Interactive Support Ticket System with Admin Dashboard'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core'
}
