fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'meth-lab-empire'
description 'Meth Lab Empire - Bunker chemistry cooking & street dealing'
author 'FiveM Scripts'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@resources/[shared]/locales/en.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/bunker-access.lua',
    'client/cooking.lua',
    'client/dealing.lua',
    'client/heat.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/bunker-manager.lua',
    'server/cooking.lua',
    'server/dealing.lua',
    'server/police.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_target',
    'qbx_core',
    'bunker-builder',
}
