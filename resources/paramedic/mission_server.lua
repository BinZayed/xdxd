function activateMissionSystem()
    local availableMissions = {}
    local activeMedics = {}
    local acceptMultiple = true
    local callstatus = {
        onHold = 2,
        accepted = 1,
        none = 0,
    }

    function ms_setMission(target)
        target = target or -1
        TriggerClientEvent('paramedic:changeMission', target, availableMissions)
    end

    function ms_cancelMission(source)
        TriggerClientEvent('paramedic:cancelMission', source)
    end

    function ms_updateMedics(target)
        target = target or -1
        TriggerClientEvent('paramedic:updateactiveMedics', target,  ms_getAllMedics(), ms_getAvailableMedics())
     end

    function ms_messageMedics(msg)
        TriggerClientEvent('paramedic:notifyallMedics', -1, msg)
    end

    function ms_messageMedic(source, msg)
        TriggerClientEvent('paramedic:notifyallMedics', source, msg)
    end

    function ms_messageClient(source, msg)
        TriggerClientEvent('paramedic:notifyClient', source, msg)
    end

    function ms_messageClients(msg)
        TriggerClientEvent('paramedic:notifyClient', -1 , msg)
    end

    function ms_setCallstatus(source, status)
        TriggerClientEvent('paramedic:callStatus', source, status)
    end

    function ms_addMission(source, position, reason)
        local sMission = availableMissions[source]
        if sMission == nil then
            availableMissions[source] = {
                id = source,
                name = GetPlayerName(source),
                pos = position,
                acceptBy = {},
                type = reason
            }
            ms_messageClient(source, 'Confirmation\nYour call has been registered')
            ms_setCallstatus(source, callstatus.onHold)
            ms_messageMedics('A new alert has been posted, it has been added to your list of missions')
            ms_setMission()
        else
            ms_messageClient(source, 'You already have a request ...')
        end
    end

    function ms_closeMission(source, missionId)
        if availableMissions[missionId] ~= nil then
            for _, v in pairs(availableMissions[missionId].acceptBy) do 
                if v ~= source then
                    ms_messageMedic(v, 'Your customer s\'has canceled')
                    ms_cancelMission(v)
                end
                ms_setMedicAvailable(v)
            end
            availableMissions[missionId] = nil
            ms_messageClient(missionId, 'Your call has been resolved')
            ms_setCallstatus(missionId, callstatus.none)
            ms_setMission()
            ms_updateMedics()
        end
    end

    function ms_acceptMission(source, missionId)
        local sMission = availableMissions[missionId]
        if sMission == nil then
            ms_messageMedic(source,'The mission is no longer current')
        elseif #sMission.acceptBy ~= 0  and not acceptMultiple then 
            ms_messageMedic(source, 'This mission is already under way')
        else
            ms_exitMission(source)
            if #sMission.acceptBy >= 1 then
                if sMission.acceptBy[1] ~= source then
                    for _, m in pairs(sMission.acceptBy) do
                        ms_messageMedic(m, 'You are several on the spot')
                    end
                    table.insert(sMission.acceptBy, source)
                end
            else
                table.insert(sMission.acceptBy, source)
                ms_messageClient(sMission.id, 'Your call has been accepted, a Paramedic is on the way')
                ms_messageMedic(source, 'Mission accepted, get started')
            end
            TriggerClientEvent('paramedic:acceptMission', source, sMission)
            ms_setCallstatus(missionId, callstatus.accepted)
            ms_setMedicBusy(source)
            ms_setMission()
            ms_updateMedics()
        end
    end

    function ms_exitMission(personnelId)
        for _, mission in pairs(availableMissions) do 
            for k, v in pairs(mission.acceptBy) do 
                if v == personnelId then
                    table.remove(mission.acceptBy, k)
                    if #mission.acceptBy == 0 then
                        ms_messageClient(mission.id, 'The paramedic has just abandoned your call')
                        TriggerClientEvent('paramedic:callStatus', mission.id, 2)
                        ms_setCallstatus(mission.id, callstatus.onHold)
                        ms_messageMedics('A new alert has been posted, it has been added to your list of missions')
                    end
                    break
                end
            end
        end
        ms_removeMedic(personnelId)
        ms_updateMedics()
    end

    function ms_cancelMissionclient(clientId)
        if availableMissions[clientId] ~= nil then
            for _, v in pairs(availableMissions[clientId].acceptBy) do 
                ms_messageMedic(v, 'Your customer s\'has canceled')
                ms_cancelMission(v)
                ms_setMedicAvailable(v)
            end
            availableMissions[clientId] = nil
            ms_setCallstatus(clientId, callstatus.none)
            ms_setMission()
            ms_updateMedics()
        end
    end

    function ms_addMedic(source)
        activeMedics[source] = false
    end
    
    function ms_removeMedic(source)
        activeMedics[source] = nil
    end

    function ms_setMedicBusy(source)
        activeMedics[source] = true        
    end

    function ms_setMedicAvailable(source)
        activeMedics[source] = false
    end

    function ms_getAllMedics()
        local count = 0
        for _, v in pairs(activeMedics) do 
            count = count + 1
        end
        return count
    end

    function ms_getAvailableMedics()
        local count = 0
        for _, v in pairs(activeMedics) do 
            if v == false then
                count = count + 1
            end
        end
        return count
    end

    function ms_getBusyMedics()
        local count = 0
        for _, v in pairs(activeMedics) do 
            if v == true then
                count = count + 1
            end
        end
        return count
    end


    RegisterServerEvent('paramedic:takeService')
    AddEventHandler('paramedic:takeService', function ()
        ms_addMedic(source)
        ms_updateMedics()
    end)

    RegisterServerEvent('paramedic:breakService')
    AddEventHandler('paramedic:breakService', function ()
        ms_exitMission(source)
        ms_removeMedic(source)
    end)

    RegisterServerEvent('paramedic:requestMission')
    AddEventHandler('paramedic:requestMission', function ()
        ms_setMission(source)
    end)

    RegisterServerEvent('paramedic:getactiveMedics')
    AddEventHandler('paramedic:getactiveMedics', function ()
        ms_updateMedics(source)
    end)

    RegisterServerEvent('paramedic:Call')
    AddEventHandler('paramedic:Call',function(posX,posY,posZ,type)
        ms_addMission(source, {posX, posY, posZ}, type)
    end)

    RegisterServerEvent('paramedic:CallCancel')
    AddEventHandler('paramedic:CallCancel', function ()
        ms_cancelMissionclient(source)
    end)

    RegisterServerEvent('paramedic:acceptMission')
    AddEventHandler('paramedic:acceptMission', function (id)
        ms_acceptMission(source, id)
    end)

    RegisterServerEvent('paramedic:finishMission')
    AddEventHandler('paramedic:finishMission', function (id)
        ms_closeMission(source, id)
    end)

    RegisterServerEvent('paramedic:cancelCall')
    AddEventHandler('paramedic:cancelCall', function ()
        ms_cancelMissionclient(source)
    end)

    RegisterServerEvent('paramedic:respawn')
    AddEventHandler('paramedic:respawn', function()
        local source = tonumber(source)
        local online = ms_getAllMedics()
        if online == 0 then
            ms_cancelMissionclient(source)
            TriggerClientEvent('paramedic:respawn', source)
        else
            TriggerClientEvent("pNotify:SendNotification", source, {text = GetPlayerName(source).." you cannot respawn as there are "..online.." paramedic(s) online!",type = "error",queue = "left",timeout = 3000,layout = "centerRight"})
        end
    end)

    RegisterServerEvent('paramedic:respawn_rip')
    AddEventHandler('paramedic:respawn_rip', function()
        local source = tonumber(source)
        ms_cancelMissionclient(source)
        TriggerEvent('f:getPlayer', source, function(user)
            user.setMoney(0)
            user.setDirtyMoney(0)
            user.removeWeapons()
            user.setInventory()
        end)
        TriggerClientEvent("ws:removeWeapons", source)
        TriggerClientEvent('paramedic:respawn', source)
    end)

    RegisterServerEvent('paramedic:doa')
    AddEventHandler('paramedic:doa', function(target)
        local source = tonumber(source)
        ms_cancelMissionclient(target)
        TriggerEvent('f:getPlayer', target, function(t)
            t.setMoney(0)
            t.setDirtyMoney(0)
            t.removeWeapons()
            t.setInventory()
        end)
        TriggerClientEvent("ws:removeWeapons", target)
        TriggerClientEvent('paramedic:respawn',target)
        TriggerClientEvent("pNotify:SendNotification", target, {text = GetPlayerName(source).." you were pronounced dead on arrival! <br>So your cash, weapons and inventory have been wiped.",type = "error",queue = "left",timeout = 3000,layout = "centerRight"})
        TriggerEvent('f:getPlayer', source, function(user)
            local pay = math.random(50,100)
            user.addMoney(pay)
            TriggerClientEvent("pNotify:SendNotification", source, {text = GetPlayerName(source).." you have been paid <span style='color:lime'>$</span><span style='color:white'>"..pay.."</span> for doing the best you could!",type = "error",queue = "left",timeout = 3000,layout = "centerRight"})
        end)
    end)

    RegisterServerEvent("paramedic:revive")
    AddEventHandler("paramedic:revive",function(t)
        local source = tonumber(source)
        ms_cancelMissionclient(source)
        TriggerClientEvent("paramedic:heal", t)
        TriggerEvent('f:getPlayer', source, function(user)
            local pay = math.random(150,250)
            user.addMoney(math.floor(pay))
            TriggerClientEvent("pNotify:SendNotification", source, {text = GetPlayerName(source).." you have been paid <span style='color:lime'>$</span><span style='color:white'>"..math.floor(pay).."</span> for rescuing "..GetPlayerName(t).."!",type = "error",queue = "left",timeout = 3000,layout = "centerRight"})
        end)
    end)

    AddEventHandler('playerDropped', function()
        ms_exitMission(source)
        ms_cancelMissionclient(source)
    end)
end

activateMissionSystem()