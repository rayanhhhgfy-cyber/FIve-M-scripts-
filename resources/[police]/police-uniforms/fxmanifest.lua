fx_version 'cerulean'
game 'gta5'

author 'Police Systems'
description 'Apply rank/district-named LSPD and CID uniforms from inventory items'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'illenium-appearance',
}

provides {
    'police-uniforms',
}
