fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'money-laundry'
author 'Criminal Scripts'
version '1.0.0'
description 'Money laundering through businesses, washing dirty cash'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/shared/locale.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'config.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
    'oxmysql'
}
