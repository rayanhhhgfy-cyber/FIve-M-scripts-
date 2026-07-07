fx_version 'cerulean'
game 'gta5'

name 'repair-kit'
description 'Vehicle repair kit item handler'
author 'Server'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/shared/locale.lua',
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
}
