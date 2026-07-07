fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'field-sobriety'
description 'Field Sobriety Tests — walk line, alphabet, gaze for DUI stops'
author 'FiveM Scripts'
version '1.0.0'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_script 'client/main.lua'
server_script 'server/main.lua'
dependencies { 'ox_lib', 'qbx_core' }
