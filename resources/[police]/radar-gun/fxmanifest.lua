fx_version 'cerulean'
game 'gta5'

name 'radar-gun'
description 'Handheld radar speed gun with NUI overlay'
author 'Server'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_script 'client/main.lua'

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
}

dependencies {
    'ox_lib',
}
