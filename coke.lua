for i = 1, 10 do
    local token = lib.callback.await('grp_drugs:getDrugsToken', false)
    if token then
        TriggerServerEvent('grp_coke:server:giveitem:cokeuncurred', token)
    end
    Citizen.Wait(20000)
end