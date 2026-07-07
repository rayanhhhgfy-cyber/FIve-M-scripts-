fx_version 'cerulean'
game 'gta5'

author 'Player Systems'
description 'F5 Outfit Manager — save/load named outfits anywhere'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/script.js',
    'web/style.css',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'illenium-appearance',
}
