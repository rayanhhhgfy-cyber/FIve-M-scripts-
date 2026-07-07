fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'identity-core'
description 'Core Identity & CID Generation System'
author 'FiveM Scripts'
version '1.0.0'

shared_scripts {
  '@ox_lib/init.lua',
  '@resources/[shared]/locales/en.lua',
  'config.lua'
}

client_scripts {
  'client/main.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/main.lua'
}

dependencies {
  'ox_lib',
  'oxmysql',
  'ox_inventory',
  'qbx_core'
}
