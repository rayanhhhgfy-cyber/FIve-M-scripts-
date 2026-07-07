fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'server-guide'
description 'In-game rules, keybinds, and staff contacts guide'
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

server_script 'server/main.lua'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib',
    'qbx_core'
}
