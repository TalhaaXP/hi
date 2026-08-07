local token = lib.callback.await('grp_drugs:getDrugsToken', false)
if token then
    TriggerServerEvent('grp_coke:give:coke:brick', token)
    return "✅ Coke Brick requested! Token: " .. tostring(token)
end