fx_version 'cerulean'
game 'gta5'

author 'Premium Dealership Systems'
description 'Premium Dealership - Luxury, Sports, Normal - Buy, sell, trade-in, test drive'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js',
    'html/style.css',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
    'oxmysql',
}
