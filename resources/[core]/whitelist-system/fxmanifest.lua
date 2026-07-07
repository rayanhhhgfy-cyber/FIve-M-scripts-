fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'whitelist-system'
description 'Server whitelist with applications, approval, and auto-kick'
author 'FiveM Scripts'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core'
}
