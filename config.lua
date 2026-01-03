Config = {}

-- Tasto apertura
Config.OpenKey = 'F9'

Config.Webhook = "https://canary.discord.com/api/webhooks/1264716772695609375/q9aD-6DC0eu5_XJ1WFSDOLuLjOK44YS2ZvAQ82_Mo0KcNSWpXpIhqGfN17foBELqwOgj"

-- Distanza render Nomi (ESP)
Config.EspDistance = 150.0

-- Struttura Permessi (La tua richiesta)
Config.AdminMenu = {
    Roles = {
        owner = {
            'listaply', 'menupers', 'veicoli', 'gserver', 'listaban', 
            'infoply', 'interply', 'setjob', 'kick', 'ban', 'spectate', 
            'gotoo', 'bring', 'bringback', 'openinv', 'revive', 'heal', 
            'armor', 'skin', 'freeze', 'screen', 'wipe', 'givemoney', 
            'giveitem', 'givecar', 'setgroup', 'setnome', 'noclip', 
            'nomi', 'invisibile', 'godmod', 'spawn', 'ripara', 'fullkit', 
            'targa', 'menumeccanico', 'ora', 'tempo', 'pulizia'
        },
        admin = {
            'listaply', 'menupers', 'veicoli', 'gserver', 'infoply', 
            'interply', 'setjob', 'spectate', 'gotoo', 'bring', 'bringback', 
            'openinv', 'revive', 'heal', 'armor', 'skin', 'freeze', 
            'screen', 'givemoney', 'giveitem', 'givecar', 'setgroup', 
            'setnome', 'noclip', 'nomi', 'invisibile', 'godmod', 'spawn', 
            'ripara', 'ora', 'tempo', 'pulizia', 'kick', 'ban', 'unban'
        },
        mod = {
            'listaply', 'menupers', 'infoply', 'interply', 'setjob', 
            'kick', 'spectate', 'gotoo', 'bring', 'bringback', 'revive', 
            'heal', 'noclip', 'nomi', 'ban', 'freeze'
        },
        helper = {
            'listaply', 'nomi', 'menupers', 'infoply', 'interply', 
            'spectate', 'gotoo', 'bring', 'bringback', 'openinv', 
            'revive', 'heal', 'armor', 'skin', 'freeze', 'screen'
        }
    },

    StaffGroups = {
        ['owner'] = 'Owner',
        ['admin'] = 'Admin',
        ['mod'] = 'Moderator',
        ['helper'] = 'Helper'
    }
}