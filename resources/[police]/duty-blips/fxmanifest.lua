fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'duty-blips'
description 'Shows on-duty officers as map blips for other LEOs'
version '1.0.0'
shared_scripts {
    '@ox_lib/init.lua',
    '@qbx-core/shared/locale.lua',
    'config.lua'
}
server_scripts { 'server/main.lua' }
client_scripts { 'client/main.lua' }
dependencies { 'ox_lib', 'qbx-core', 'pma-voice' }
