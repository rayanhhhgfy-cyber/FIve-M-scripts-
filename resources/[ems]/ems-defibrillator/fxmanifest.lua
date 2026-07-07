fx_version 'cerulean'
game 'gta5'

description 'EMS Defibrillator — Physical CPR & Cardiac Resuscitation'
version '1.0.0'
author 'Elite FiveM Architecture'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
    'ox_target',
    'wasabi-ambulance'
}

lua54 'yes'
