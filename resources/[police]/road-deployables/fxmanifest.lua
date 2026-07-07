fx_version 'cerulean'
game 'gta5'

name 'road-deployables'
description 'Deployable traffic cones and barriers for police/CID'
author 'Server'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
}
