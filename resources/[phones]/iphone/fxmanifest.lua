fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'iphone'
description 'iPhone 17 Pro Max Smartphone System — includes Taxi app'
author 'FiveM Scripts'
version '2.0.0'

shared_scripts { '@ox_lib/init.lua', '@resources/[shared]/locales/en.lua', '@resources/[shared]/locales/ar.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }
provide 'phone-system'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'taxi-system'
}
