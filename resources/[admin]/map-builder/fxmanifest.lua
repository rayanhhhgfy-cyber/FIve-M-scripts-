fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Jules / Principal Full-Stack Game Systems Developer'
description 'Production-Grade Interactive Map Builder & World Engine'
version '1.0.0'

ui_page 'nui/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/cl_builder.lua',
    'client/cl_interact.lua'
}

server_scripts {
    'server/sv_builder.lua',
    'server/sv_interact.lua'
}

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
    'nui/prop_db.json'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
