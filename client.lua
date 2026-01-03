local ESX = exports["es_extended"]:getSharedObject()
local noclip, esp, godmode, invisible, spectating = false, false, false, false, false
local spectateTarget = nil

-- Mapping Tasto
RegisterKeyMapping('staffmenu', 'Apri Staff Menu', 'keyboard', 'F9')

RegisterCommand('staffmenu', function()
    ESX.TriggerServerCallback('ex_admin:getData', function(data)
        if data then
            SetNuiFocus(true, true)
            SendNUIMessage({ type = "OPEN", players = data.players, perms = data.perms })
        end
    end)
end)

-- CALLBACKS PER JS (FIX FETCH)
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('getPlayerDetails', function(data, cb)
    ESX.TriggerServerCallback('ex_admin:getPlayerDetails', function(details)
        cb(details)
    end, data.targetId)
end)

RegisterNUICallback('getBanList', function(data, cb)
    ESX.TriggerServerCallback('ex_admin:getBanList', function(bans)
        cb(bans)
    end)
end)

RegisterNUICallback('doAction', function(data, cb)
    if data.action == "noclip" then ToggleNoclip()
    elseif data.action == "nomi" then ToggleESP()
    elseif data.action == "godmod" then 
        godmode = not godmode
        SetEntityInvincible(PlayerPedId(), godmode)
        ESX.ShowNotification("Godmode: " .. (godmode and "~g~ON" or "~r~OFF"))
    elseif data.action == "invisibile" then
        invisible = not invisible
        SetEntityVisible(PlayerPedId(), not invisible, false)
    elseif data.action == "ripara" then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then SetVehicleFixed(veh) end
    else
        TriggerServerEvent('ex_admin:action', data)
    end
    cb('ok')
end)

-- ESP NOMI
function ToggleESP()
    esp = not esp
    ESX.ShowNotification("ESP: " .. (esp and "~g~ON" or "~r~OFF"))
    CreateThread(function()
        while esp do
            local sleep = 5
            local myPos = GetEntityCoords(PlayerPedId())
            for _, player in ipairs(GetActivePlayers()) do
                local tid = GetPlayerServerId(player)
                local tped = GetPlayerPed(player)
                if tped ~= PlayerPedId() then
                    local tpos = GetEntityCoords(tped)
                    if #(myPos - tpos) < 50.0 then
                        DrawText3D(tpos.x, tpos.y, tpos.z + 1.2, "["..tid.."] " .. GetPlayerName(player))
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- NOCLIP CON GUIDA
function ToggleNoclip()
    noclip = not noclip
    local ped = PlayerPedId()
    
    if noclip then
        SetEntityCollision(ped, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityAlpha(ped, 150, false)
        SetEntityVisible(ped, true, false)
        ESX.ShowNotification("~g~NOCLIP ON~n~~w~W/S: Avanti/Indietro~n~A/D: Sinistra/Destra~n~Shift: Su | Ctrl: Giù")
        
        CreateThread(function()
            while noclip do
                Wait(0)
                local pPos = GetEntityCoords(ped)
                local speed = 1.0
                local camRot = GetGameplayCamRot(2)
                
                -- Ruota il personaggio nella direzione del movimento
                local moved = false
                
                -- W - Avanti
                if IsControlPressed(0, 32) then
                    local x = pPos.x + math.sin(-camRot.z * math.pi / 180) * speed
                    local y = pPos.y + math.cos(-camRot.z * math.pi / 180) * speed
                    SetEntityCoordsNoOffset(ped, x, y, pPos.z, true, true, true)
                    SetEntityRotation(ped, 0.0, 0.0, camRot.z, 0, true)
                    moved = true
                end
                -- S - Indietro
                if IsControlPressed(0, 33) then
                    local x = pPos.x - math.sin(-camRot.z * math.pi / 180) * speed
                    local y = pPos.y - math.cos(-camRot.z * math.pi / 180) * speed
                    SetEntityCoordsNoOffset(ped, x, y, pPos.z, true, true, true)
                    SetEntityRotation(ped, 0.0, 0.0, camRot.z + 180, 0, true)
                    moved = true
                end
                -- A - Sinistra
                if IsControlPressed(0, 34) then
                    local x = pPos.x - math.cos(-camRot.z * math.pi / 180) * speed
                    local y = pPos.y + math.sin(-camRot.z * math.pi / 180) * speed
                    SetEntityCoordsNoOffset(ped, x, y, pPos.z, true, true, true)
                    SetEntityRotation(ped, 0.0, 0.0, camRot.z - 90, 0, true)
                    moved = true
                end
                -- D - Destra
                if IsControlPressed(0, 35) then
                    local x = pPos.x + math.cos(-camRot.z * math.pi / 180) * speed
                    local y = pPos.y - math.sin(-camRot.z * math.pi / 180) * speed
                    SetEntityCoordsNoOffset(ped, x, y, pPos.z, true, true, true)
                    SetEntityRotation(ped, 0.0, 0.0, camRot.z + 90, 0, true)
                    moved = true
                end
                -- Shift - Su
                if IsControlPressed(0, 21) then
                    SetEntityCoordsNoOffset(ped, pPos.x, pPos.y, pPos.z + speed, true, true, true)
                end
                -- Ctrl - Giù
                if IsControlPressed(0, 36) then
                    SetEntityCoordsNoOffset(ped, pPos.x, pPos.y, pPos.z - speed, true, true, true)
                end
            end
        end)
    else
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityAlpha(ped, 255, false)
        ESX.ShowNotification("Noclip: ~r~OFF")
    end
end

