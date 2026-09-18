-- CLIENT SIDE ONLY - One-time Lua Executor Script
-- Paste this entire block into any client-side Lua executor
-- Works on every server (client-side only, no resource needed)

local Config = {
    -- CHANGE THIS TO THE ITEM NAME YOU WANT TO USE TO OPEN THE NPC INVENTORY
    RequiredItem = "phone",          -- <<-- PUT YOUR ITEM NAME HERE (example: "phone", "id_card", "keycard")

    -- NPC Settings
    PedModel = "a_m_m_business_01",  -- Change model if you want
    SpawnCoords = vector4(0.0, 0.0, 0.0, 0.0), -- Will spawn at your current position + heading
    InteractionDistance = 2.5,
}

-- ==================== DO NOT TOUCH BELOW UNLESS YOU KNOW WHAT YOU'RE DOING ====================

local npcPed = nil
local isNearNPC = false
local hasRequiredItem = false

-- Force spawn coordinates to player's current position
Citizen.CreateThread(function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    Config.SpawnCoords = vector4(coords.x + 1.5, coords.y, coords.z, heading + 180.0)
end)

-- Load model
local function LoadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end
    return HasModelLoaded(hash)
end

-- Spawn invincible NPC
local function SpawnNPC()
    if npcPed and DoesEntityExist(npcPed) then
        DeleteEntity(npcPed)
    end

    if not LoadModel(Config.PedModel) then
        print("^1[ERROR] Failed to load ped model^0")
        return
    end

    local c = Config.SpawnCoords
    npcPed = CreatePed(4, GetHashKey(Config.PedModel), c.x, c.y, c.z - 1.0, c.w, false, true)

    -- Make fully invincible + frozen
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

    -- Optional idle anim
    TaskStartScenarioInPlace(npcPed, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

    print("^2[NPC] Invincible NPC spawned successfully^0")
end

-- Check if player has the required item (works with most inventories)
local function HasItem(itemName)
    -- Try ox_inventory first
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search('count', itemName)
        return count and count > 0
    end

    -- Try qb-inventory / qb-core
    if GetResourceState('qb-core') == 'started' or GetResourceState('qb-inventory') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore then
            local PlayerData = QBCore.Functions.GetPlayerData()
            if PlayerData and PlayerData.items then
                for _, item in pairs(PlayerData.items) do
                    if item and item.name == itemName and item.amount > 0 then
                        return true
                    end
                end
            end
        end
    end

    -- Try ESX
    if GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        if ESX then
            local inventory = ESX.GetPlayerData().inventory
            if inventory then
                for _, item in pairs(inventory) do
                    if item.name == itemName and item.count > 0 then
                        return true
                    end
                end
            end
        end
    end

    -- Fallback: always allow if no inventory detected (for testing)
    return true
end

-- Open player inventory (tries every common inventory system)
local function OpenPlayerInventory()
    -- ox_inventory
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:openInventory('player')
        return
    end

    -- qb-inventory
    if GetResourceState('qb-inventory') == 'started' then
        TriggerEvent('qb-inventory:client:openInventory')
        exports['qb-inventory']:OpenInventory()
        return
    end

    -- ps-inventory
    if GetResourceState('ps-inventory') == 'started' then
        TriggerEvent('ps-inventory:client:openInventory')
        return
    end

    -- qs-inventory
    if GetResourceState('qs-inventory') == 'started' then
        TriggerEvent('qs-inventory:client:openInventory')
        return
    end

    -- core_inventory
    if GetResourceState('core_inventory') == 'started' then
        exports.core_inventory:openInventory()
        return
    end

    -- ESX default
    if GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx_inventoryhud:openPlayerInventory')
        TriggerEvent('esx:openInventory')
        return
    end

    -- Last resort
    print("^3[INFO] No known inventory system detected. Trying generic open.^0")
    TriggerEvent('inventory:client:OpenInventory')
    TriggerEvent('inventory:open')
end

-- Main loop
Citizen.CreateThread(function()
    Citizen.Wait(500)
    SpawnNPC()

    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if npcPed and DoesEntityExist(npcPed) then
            local npcCoords = GetEntityCoords(npcPed)
            local dist = #(playerCoords - npcCoords)

            if dist < Config.InteractionDistance + 5.0 then
                sleep = 0

                if dist < Config.InteractionDistance then
                    isNearNPC = true

                    -- Draw 3D text
                    DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, "[E] Open Inventory  |  Need: " .. Config.RequiredItem)

                    if IsControlJustReleased(0, 38) then -- E key
                        if HasItem(Config.RequiredItem) then
                            OpenPlayerInventory()
                        else
                            -- Notification
                            BeginTextCommandThefeedPost("STRING")
                            AddTextComponentSubstringPlayerName("~r~You need item: ~w~" .. Config.RequiredItem)
                            EndTextCommandThefeedPostTicker(false, true)
                        end
                    end
                else
                    isNearNPC = false
                end
            end
        else
            -- Respawn if deleted somehow
            SpawnNPC()
            Citizen.Wait(2000)
        end

        Citizen.Wait(sleep)
    end
end)

-- 3D Text helper
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(x, y, z))

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.35 * scale)
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

print("^2[SCRIPT LOADED] Invincible NPC + E Inventory Opener ready.^0")
print("^3Required Item set to: " .. Config.RequiredItem .. "^0")
print("^3Change Config.RequiredItem at the top if needed.^0")