fx_version 'cerulean'
game 'gta5'
lua54 'yes'
description 'Bridge for pefcl(QBOX)'
author 'DevX32'
shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/import.lua',
}
modules {
    'qbx_core:playerdata',
    'qbx_core:utils'
}

client_script 'client.lua'

server_scripts { 
    'server.lua',
    'config.lua'
}
