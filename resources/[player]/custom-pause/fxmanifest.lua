fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'custom-pause'
description 'Custom Pause Menu — replaces default ESC menu with player stats, job info, and quick actions'
author 'FiveM Scripts'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'weathersync',
}
