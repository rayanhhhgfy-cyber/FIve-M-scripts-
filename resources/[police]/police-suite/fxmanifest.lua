fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Jules'
description 'Immersive Police Drone, Dashcam, P-List, and Real-Time GPS Tracking Suite'
version '1.0.0'

shared_script '@ox_lib/init.lua'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
