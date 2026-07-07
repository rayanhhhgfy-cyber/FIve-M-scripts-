fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cid-weapons'
description 'CID secret weapons cache — rank-gated vanilla weapons at HQ + bunkers'
author 'FiveM Scripts'
version '1.0.0'

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

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_target',
    'qbx_core'
}
