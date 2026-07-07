fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mini-games'
description 'Darts, pool, chess, and other table games'
author 'QBox Framework'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx-core/shared/locale.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_script 'client/main.lua'

dependencies {
    'ox_lib',
    'qbx-core',
    'oxmysql',
    'ox_target'
}
