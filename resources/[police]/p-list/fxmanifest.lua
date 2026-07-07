fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'p-list'
description 'Personnel List — active duty officers, radio freqs, call signs'
version '1.0.0'
author 'QBox Framework'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx-core/shared/locale.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
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
    'qbx-core',
    'pma-voice'
}
