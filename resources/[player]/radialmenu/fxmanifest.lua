fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'QBox Framework'
description 'Radial menu for vehicle controls, clothing, and job interactions'
version '1.5.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/clothing.lua',
    'client/trunk.lua',
    'client/stretcher.lua'
}

server_scripts {
    'server/trunk.lua',
    'server/stretcher.lua'
}

files {
    'html/index.html',
    'html/css/main.css',
    'html/js/main.js',
    'html/js/RadialMenu.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
}