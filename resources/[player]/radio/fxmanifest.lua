fx_version 'cerulean'
game 'gta5'

description 'QB-Radio'
version '1.2.2'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua'
}

client_scripts {
  'client.lua',
}

server_script 'server.lua'

ui_page 'html/ui.html'

files {
  'html/ui.html',
  'html/js/script.js',
  'html/css/style.css',
  'html/img/radio*.png'
}

dependencies {
  'ox_lib',
  'qbx_core',
  'pma-voice'
}

lua54 'yes'
