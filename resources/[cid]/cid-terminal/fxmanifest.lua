fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'cid-terminal'
description 'CID Management Computer System — Staff, Grades, Payroll, Armory, Cases, Warrants, BOLOs, Vehicle Spawn Tracking'
version '1.0.0'

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

ui_page 'html/cids.html'

files {
    'html/cids.html',
    'html/cids.css',
    'html/cids.js',
}

dependencies {
    'ox_lib',
    'qbx-core',
    'ox_target',
    'oxmysql',
    'admin-commander',
}
