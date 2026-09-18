-- CLIENT SIDE ONLY - Susano Compatible NPC + E Inventory
-- Paste this full code into your GitHub raw file

local Config = {
    RequiredItem = "phone",              -- <<-- CHANGE TO YOUR ITEM NAME
    PedModel = "a_m_m_business_01",
    InteractionDistance = 2.5,
}

local npcPed = nil

local function LoadModel(model)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 150 do
        Wait(10)
        timeout = timeout + 1
    end
    return HasModelLoaded(hash)
end

local function SpawnNPC()
    if npcPed and DoesEntityExist(npcPed) then
        DeleteEntity(npcPed)
        npcPed = nil
    end

    if not LoadModel(Config.PedModel) then
        print("^1[ERROR] Failed to load ped model^0")
        return
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local spawnX = coords.x + (math.sin(math.rad(-heading)) * 1.8)
    local spawnY = coords.y + (math.cos(math.rad(-heading)) * 1.8)

    npcPed = CreatePed(4, GetHashKey(Config.PedModel), spawnX, spawnY, coords.z - 1.0, heading + 180.0, false, true)

    SetEntityInvincible(npcPed, true)
    SetEntityProofs(npcPed, true, true, true, true, true, true, true, true)
    SetPedCanRagdoll(npcPed, false)
    SetPedDiesWhenInjured(npcPed, false)
    SetPedFleeAttributes(npcPed, 0, false)
    SetPedCombatAttributes(npcPed, 46, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    FreezeEntityPosition(npcPed, true)
    SetEntityAsMissionEntity(npcPed, true, true)
    SetPedCanBeTargetted(npcPed, false)
    SetPedCanBeTargettedByPlayer(npcPed, PlayerId(), false)
    TaskStartScenarioInPlace(npcPed, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

    print("^2[NPC] Invincible NPC spawned successfully^0")
end

local function HasItem(itemName)
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search('count', itemName)
        return (count and count > 0)
    end

    if GetResourceState('qb-core') == 'started' then
        local ok, QBCore = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and QBCore then
            local PlayerData = QBCore.Functions.GetPlayerData()
            if PlayerData and PlayerData.items then
                for _, item in pairs(PlayerData.items) do
                    if item and item.name == itemName and (item.amount or item.count or 0) > 0 then
                        return true
                    end
                end
            end
        end
    end

    if GetResourceState('es_extended') == 'started' then
        local ok, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and ESX then
            local data = ESX.GetPlayerData()
            if data and data.inventory then
                for _, item in pairs(data.inventory) do
                    if item.name == itemName and (item.count or 0) > 0 then
                        return true
                    end
                end
            end
        end
    end

    return true -- fallback allow
end

local function OpenPlayerInventory()
    print("^3[INV] Opening inventory...^0")

    if GetResourceState('ox_inventory') == 'started' then
        pcall(function() exports.ox_inventory:openInventory('player') end)
        pcall(function() exports.ox_inventory:openInventory() end)
        return
    end

    if GetResourceState('qb-inventory') == 'started' then
        pcall(function() exports['qb-inventory']:OpenInventory() end)
        TriggerEvent('qb-inventory:client:openInventory')
        TriggerEvent('inventory:client:OpenInventory')
        return
    end

    if GetResourceState('ps-inventory') == 'started' then
        TriggerEvent('ps-inventory:client:openInventory')
        return
    end

    if GetResourceState('qs-inventory') == 'started' then
        TriggerEvent('qs-inventory:client:openInventory')
        return
    end

    if GetResourceState('core_inventory') == 'started' then
        pcall(function() exports.core_inventory:openInventory() end)
        return
    end

    if GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx_inventoryhud:openPlayerInventory')
        TriggerEvent('esx:openInventory')
        TriggerEvent('inventory:open')
        return
    end

    -- Generic fallbacks
    TriggerEvent('inventory:client:OpenInventory')
    TriggerEvent('inventory:open')
    TriggerEvent('qb-inventory:client:OpenInventory')
    ExecuteCommand('inventory')
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

CreateThread(function()
    Wait(800)
    SpawnNPC()

    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if npcPed and DoesEntityExist(npcPed) then
            local npcCoords = GetEntityCoords(npcPed)
            local dist = #(playerCoords - npcCoords)

            if dist < 8.0 then
                sleep = 0

                if dist < Config.InteractionDistance then
                    DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.05, "[E] Open Inventory  |  Need: " .. Config.RequiredItem)

                    if IsControlJustPressed(0, 38) or IsControlJustReleased(0, 38) then
                        if HasItem(Config.RequiredItem) then
                            OpenPlayerInventory()
                        else
                            BeginTextCommandThefeedPost("STRING")
                            AddTextComponentSubstringPlayerName("~r~You need item: ~w~" .. Config.RequiredItem)
                            EndTextCommandThefeedPostTicker(false, true)
                        end
                        Wait(400)
                    end
                end
            end
        else
            SpawnNPC()
            Wait(2000)
        end

        Wait(sleep)
    end
end)

print("^2[SCRIPT LOADED] Susano-compatible NPC + E Inventory ready.^0")
print("^3Required Item: " .. Config.RequiredItem .. "^0")