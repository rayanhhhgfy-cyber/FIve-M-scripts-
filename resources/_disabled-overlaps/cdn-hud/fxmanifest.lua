fx_version 'cerulean'
game 'gta5'

description 'CDN-HUD — Modern NUI HUD with Speedometer, Seatbelt, Fuel & Status'
version '2.0.0'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/script.js'
}

dependencies {
    'ox_lib',
    'qbx_core'
}

lua54 'yes'