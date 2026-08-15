fx_version 'cerulean'
game 'gta5'

author 'Opencode'
description 'God Menu - Private owner dashboard with full server control'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
    'ox_target'
}

lua54 'yes'
