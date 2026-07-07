fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'forensics'
description 'Crime scene investigation — fingerprint, casing, DNA collection and analysis terminal'
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
