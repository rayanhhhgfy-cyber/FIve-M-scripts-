fx_version 'cerulean'
game 'gta5'

author 'Opencode'
description 'Emote/Animation Menu with categories and favorites'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib',
    'qbx_core'
}

lua54 'yes'
