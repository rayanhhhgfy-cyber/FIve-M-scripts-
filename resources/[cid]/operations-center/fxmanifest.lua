fx_version 'cerulean'
game 'gta5'

author 'CID Systems'
description 'Operations Center - Briefing room, team tracking, timeline, debriefing reports'
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

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/script.js',
    'web/style.css',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
    'oxmysql',
}
