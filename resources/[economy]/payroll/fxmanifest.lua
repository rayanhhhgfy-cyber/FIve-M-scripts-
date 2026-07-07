fx_version 'cerulean'
game 'gta5'

author 'Economy Systems'
description 'Salary payroll every 25 game days with phone notification'
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

dependencies {
    'ox_lib',
    'qbx_core',
    'oxmysql',
}
