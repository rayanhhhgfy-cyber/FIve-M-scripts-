fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'QBox Framework'
description 'Heads-up display with hunger, thirst, stress, compass and more'
version '2.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/*',
    'html/index.html',
    'html/styles.css',
    'html/responsive.css',
    'html/app.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'pma-voice'
}