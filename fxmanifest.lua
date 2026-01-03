server_script '@ElectronAC/src/include/server.lua'
client_script '@ElectronAC/src/include/client.lua'
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Admin Panel'
version '2.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'bans.json'
}

dependencies {
    'es_extended',
    'ox_inventory',
    'fivem-appearance'
}

ui_page 'html/index.html'