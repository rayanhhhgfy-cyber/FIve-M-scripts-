fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'anim-menu'
description 'Animation menu integrated with radial menu — emotes, walks, expressions'
author 'Server Team'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'ox_lib',
    'qbx_core',
}
