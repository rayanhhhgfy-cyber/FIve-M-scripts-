fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'vehicle-keys'
description 'Vehicle key system with lockpick mini-game, lock/unlock, and key transfer'
author 'Server Team'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
}
