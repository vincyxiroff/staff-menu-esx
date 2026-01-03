local ESX = exports["es_extended"]:getSharedObject()
local BansFile = "bans.json"
local PreviousCoords = {} 

--- ===================================================================
--- UTILITY & LOGS
--- ===================================================================

-- Caricamento Ban
local function LoadBans()
    local content = LoadResourceFile(GetCurrentResourceName(), BansFile)
    if not content or content == "" then
        SaveResourceFile(GetCurrentResourceName(), BansFile, "[]", -1)
        return {}
    end
    return json.decode(content)
end

-- Sistema Log Discord
local function SendLog(adminName, action, targetName, extra)
    if not Config.Webhook or Config.Webhook == "" or Config.Webhook == "INSERISCI_QUI" then return end
    
    local embed = {{
        ["color"] = 3447003, -- Blu/Viola
        ["title"] = "🛡️ Staff Action: " .. action,
        ["description"] = string.format("**Staff:** %s\n**Target:** %s\n**Dettagli:** %s", adminName, targetName or "N/A", extra or "Nessuno"),
        ["footer"] = { ["text"] = os.date("%d/%m/%Y %H:%M:%S") },
    }}
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({username = "Admin Logs", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

-- Check Permessi
local function HasPerm(xPlayer, action)
    if not xPlayer then return false end
    local group = xPlayer.getGroup()
    local roles = Config.AdminMenu.Roles[group]
    if roles then
        for _, v in pairs(roles) do 
            if v == action then return true end 
        end
    end
    return false
end

--- ===================================================================
--- CALLBACKS (PONTE CON IL JS)
--- ===================================================================

ESX.RegisterServerCallback('ex_admin:getData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not Config.AdminMenu.Roles[xPlayer.getGroup()] then return cb(false) end

    local players = {}
    for _, id in ipairs(GetPlayers()) do
        local xTarget = ESX.GetPlayerFromId(id)
        if xTarget then
            table.insert(players, { 
                id = id, 
                name = GetPlayerName(id), 
                job = xTarget.job.label, 
                ping = GetPlayerPing(id) 
            })
        end
    end
    
    cb({ 
        players = players, 
        perms = Config.AdminMenu.Roles[xPlayer.getGroup()] 
    })
end)

ESX.RegisterServerCallback('ex_admin:getPlayerDetails', function(source, cb, targetId)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return cb(nil) end
    
    cb({
        name = xTarget.getName(),
        money = xTarget.getAccount('money').money,
        bank = xTarget.getAccount('bank').money,
        job = xTarget.job.label .. " - " .. xTarget.job.grade_label,
        identifier = xTarget.getIdentifier()
    })
end)

ESX.RegisterServerCallback('ex_admin:getBanList', function(source, cb)
    cb(LoadBans())
end)

--- ===================================================================
--- GESTIONE AZIONI (EVENTO PRINCIPALE)
--- ===================================================================

RegisterNetEvent('ex_admin:action', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local action = data.action
    local targetId = tonumber(data.targetId)
    local xTarget = targetId and ESX.GetPlayerFromId(targetId) or nil
    
    local adminName = GetPlayerName(src)
    local targetName = xTarget and GetPlayerName(targetId) or "Sé stesso"

    -- Controllo Permessi
    if not HasPerm(xPlayer, action) then 
        xPlayer.showNotification("~r~Non hai i permessi per: " .. action)
        return 
    end

    -- LOGICA SPECIFICA PER OGNI AZIONE

    if action == "openinv" and xTarget then
        -- OX INVENTORY
        if targetId ~= src then
            exports.ox_inventory:InspectInventory(src, targetId)
            SendLog(adminName, "Inventario", targetName, "Ha ispezionato l'inventario")
        else
            xPlayer.showNotification("Non puoi aprire il tuo stesso inventario da qui.")
        end

    elseif action == "skin" and xTarget then
        -- SKIN MENU
        xTarget.triggerEvent('esx_skin:openSaveableMenu')
        SendLog(adminName, "Skin Menu", targetName, "Ha aperto il menu skin")

    elseif action == "heal" and xTarget then
        -- *** LOGICA CUSTOM UTENTE (HEAL) ***
        local healData = { heal = true }
        TriggerClientEvent('ambulancejob:healPlayer', targetId, healData)
        SendLog(adminName, "Heal", targetName, "Ha curato il giocatore")

    elseif action == "revive" and xTarget then
        -- *** LOGICA CUSTOM UTENTE (REVIVE) ***
        local reviveData = { revive = true }
        TriggerClientEvent('ambulancejob:healPlayer', targetId, reviveData)
        SendLog(adminName, "Revive", targetName, "Ha rianimato il giocatore")

    elseif action == "armor" and xTarget then
        -- ARMOR (Trigger server event come richiesto precedentemente)
        TriggerEvent('armour', targetId) 
        SendLog(adminName, "Armor", targetName, "Ha settato l'armatura")

    elseif action == "spectate" and xTarget then
        -- SPECTATE DIRETTO
        SendLog(adminName, "Spectate", targetName, "Ha iniziato a spectare")

    elseif action == "gotoo" and xTarget then
        -- GOTO
        local coords = xTarget.getCoords(true)
        xPlayer.setCoords(coords)
        SendLog(adminName, "Goto", targetName, "Teletrasporto dal player")

    elseif action == "bring" and xTarget then
        -- BRING
        PreviousCoords[targetId] = xTarget.getCoords(true)
        xTarget.setCoords(xPlayer.getCoords(true))
        SendLog(adminName, "Bring", targetName, "Ha portato il player da sé")

    elseif action == "bringback" and xTarget then
        -- BRING BACK
        if PreviousCoords[targetId] then
            xTarget.setCoords(PreviousCoords[targetId])
            PreviousCoords[targetId] = nil
            SendLog(adminName, "BringBack", targetName, "Riportato alla posizione precedente")
        else
            xPlayer.showNotification("Nessuna posizione precedente salvata per questo ID.")
        end

    elseif action == "kick" and xTarget then
        -- KICK
        local reason = data.reason or "Nessun motivo specificato"
        SendLog(adminName, "Kick", targetName, "Motivo: " .. reason)
        DropPlayer(targetId, "Kickato dallo Staff: " .. reason)

    elseif action == "ban" and xTarget then
        -- BAN AVANZATO (TUTTI GLI IDENTIFICATORI)
        local reason = data.reason or "Ban Permanente"
        local bans = LoadBans()
        local identifiers = GetPlayerIdentifiers(targetId)
        
        -- Salva tutti gli identificatori
        local banData = {
            name = xTarget.getName(),
            reason = reason,
            admin = adminName,
            date = os.date("%d/%m/%Y"),
            identifiers = identifiers
        }
        
        table.insert(bans, banData)
        SaveResourceFile(GetCurrentResourceName(), BansFile, json.encode(bans, {indent = true}), -1)
        SendLog(adminName, "BAN", targetName, "Motivo: " .. reason)
        DropPlayer(targetId, "⛔ SEI STATO BANNATO ⛔\nAdmin: " .. adminName .. "\nMotivo: " .. reason)

    elseif action == "unban" then
        -- UNBAN
        local bans = LoadBans()
        local found = false
        for i, b in ipairs(bans) do
            if b.identifiers then
                for _, id in pairs(b.identifiers) do
                    if id == data.license then
                        SendLog(adminName, "UNBAN", "Player: " .. b.name, "Ha rimosso il ban")
                        table.remove(bans, i)
                        found = true
                        break
                    end
                end
            elseif b.license == data.license then
                SendLog(adminName, "UNBAN", "License: " .. data.license, "Ha rimosso il ban")
                table.remove(bans, i)
                found = true
                break
            end
            if found then break end
        end
        if found then
            SaveResourceFile(GetCurrentResourceName(), BansFile, json.encode(bans, {indent = true}), -1)
        end
    end
end)

--- ===================================================================
--- CONTROLLO CONNESSIONI (BAN CHECK AVANZATO)
--- ===================================================================

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    
    deferrals.defer()
    deferrals.update("🔍 Controllo ban in corso...")
    
    Wait(1000)
    
    local bans = LoadBans()
    
    -- Controlla tutti gli identificatori
    for _, ban in ipairs(bans) do
        if ban.identifiers then
            -- Nuovo sistema: controlla tutti gli identificatori
            for _, playerID in pairs(identifiers) do
                for _, banID in pairs(ban.identifiers) do
                    if playerID == banID then
                        deferrals.done(string.format(
                            "\n🚫 SEI BANNATO DA QUESTO SERVER\n\n" ..
                            "👤 Player: %s\n" ..
                            "👮 Admin: %s\n" ..
                            "📝 Motivo: %s\n" ..
                            "📅 Data: %s\n\n" ..
                            "💬 Contatta lo staff per ricorso",
                            ban.name, ban.admin, ban.reason, ban.date
                        ))
                        return
                    end
                end
            end
        else
            -- Vecchio sistema: solo licenza
            for _, playerID in pairs(identifiers) do
                if playerID == ban.license then
                    deferrals.done(string.format(
                        "\n🚫 SEI BANNATO DA QUESTO SERVER\n\n" ..
                        "👤 Player: %s\n" ..
                        "👮 Admin: %s\n" ..
                        "📝 Motivo: %s\n" ..
                        "📅 Data: %s\n\n" ..
                        "💬 Contatta lo staff per ricorso",
                        ban.name, ban.admin, ban.reason, ban.date
                    ))
                    return
                end
            end
        end
    end
    
    deferrals.update("✅ Controllo completato, accesso consentito")
    Wait(500)
    deferrals.done()
end)