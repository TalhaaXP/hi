-- Loop 1: Give Coke Brick (10 times with 5-7 min random delay)
for i = 1, 10 do
    local token = lib.callback.await('grp_drugs:getDrugsToken', false)
    if token then
        TriggerServerEvent('grp_coke:give:coke:brick', token)
    end
    -- Random delay between 5 to 7 minutes (300 to 420 seconds)
    Citizen.Wait(math.random(300, 420) * 1000)
end

-- Loop 2: Give Uncured Coke (10 times with 20 sec delay)
for i = 1, 10 do
    local token = lib.callback.await('grp_drugs:getDrugsToken', false)
    if token then
        TriggerServerEvent('grp_coke:server:giveitem:cokeuncurred', token)
    end
    -- 20 seconds delay
    Citizen.Wait(20000)
end

-- Loop 3: Give Coke Doll (10 times with 40 sec delay)
for i = 1, 10 do
    local token = lib.callback.await('grp_drugs:getDrugsToken', false)
    if token then
        TriggerServerEvent('grp_coke:server:giveitem:doll', token)
    end
    -- 40 seconds delay
    Citizen.Wait(40000)
end