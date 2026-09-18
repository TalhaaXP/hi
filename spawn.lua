-- CLIENT SIDE ONLY - HARDENED Susano NPC + Inventory Opener
-- Replace the entire content of spawn.lua with this

local Config = {
    RequiredItem = "phone",          -- <<-- CHANGE THIS TO YOUR EXACT ITEM NAME
    PedModel = "a_m_m_business_01",
    InteractionDistance = 2.8,
    ForceOpen = true,                -- set true = ignore item check and force open
}

local npcPed = nil
local lastPress = 0

local function LoadModel(model)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 200 do
        Wait(5)
        t = t + 1
    end
    return HasModelLoaded(hash)
end

local function SpawnNPC()
    if npcPed and DoesEntityExist(npcPed) then
        DeleteEntity(npcPed)
        npcPed = nil
    end

    if not LoadModel(Config.PedModel) then
        print("^1[ERROR] Ped model failed to load^0")
        return
    end

    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)

    local x = c.x + math.sin(math.rad(-h)) * 1.7
    local y = c.y + math.cos(math.rad(-h)) * 1.7

    npcPed = CreatePed(4, GetHashKey(Config.PedModel), x, y, c.z - 1.0, h + 180.0, false, true)

    SetEntityAsMissionEntity(npcPed, true, true)
    SetEntityInvincible(npcPed, true)
    SetEntityProofs(npcPed, true, true, true, true, true, true, true, true)
    SetPedCanRagdoll(npcPed, false)
    SetPedDiesWhenInjured(npcPed, false)
    SetPedFleeAttributes(npcPed, 0, 0)
    SetPedCombatAttributes(npcPed, 46, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    FreezeEntityPosition(npcPed, true)
    SetPedCanBeTargetted(npcPed, false)
    SetPedCanBeTargettedByPlayer(npcPed, PlayerId(), false)
    TaskStartScenarioInPlace(npcPed, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

    print("^2[NPC] Spawned and frozen^0")
end

-- Aggressive inventory open - tries EVERY known method
local function ForceOpenInventory()
    print("^3[INV] Force opening inventory...^0")

    -- ox_inventory
    pcall(function() exports.ox_inventory:openInventory('player') end)
    pcall(function() exports.ox_inventory:openInventory() end)
    pcall(function() exports.ox_inventory:openInventory('player', cache and cache.serverId or GetPlayerServerId(PlayerId())) end)

    -- qb
    pcall(function() exports['qb-inventory']:OpenInventory() end)
    TriggerEvent('qb-inventory:client:openInventory')
    TriggerEvent('inventory:client:OpenInventory')
    TriggerEvent('qb-inventory:client:OpenInventory')

    -- ps / qs / core
    TriggerEvent('ps-inventory:client:openInventory')
    TriggerEvent('qs-inventory:client:openInventory')
    pcall(function() exports.core_inventory:openInventory() end)

    -- ESX
    TriggerEvent('esx_inventoryhud:openPlayerInventory')
    TriggerEvent('esx:openInventory')
    TriggerEvent('esx_inventoryhud:openInventory')

    -- Generic + command
    TriggerEvent('inventory:open')
    TriggerEvent('inventory:client:OpenInventory')
    ExecuteCommand('inventory')
    ExecuteCommand('inv')
    ExecuteCommand('openinv')

    -- Last resort: simulate key if the server uses default keybind
    -- (some servers open inv with F2 / TAB / K)
    print("^2[INV] All open methods fired^0")
end

local function HasItem(item)
    if Config.ForceOpen then return true end

    -- ox
    if GetResourceState('ox_inventory') == 'started' then
        local ok, count = pcall(function() return exports.ox_inventory:Search('count', item) end)
        if ok and count and count > 0 then return true end
    end

    -- qb
    if GetResourceState('qb-core') == 'started' then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and core then
            local data = core.Functions.GetPlayerData()
            if data and data.items then
                for _, v in pairs(data.items) do
                    if v and v.name == item and (v.amount or v.count or 0) > 0 then
                        return true
                    end
                end
            end
        end
    end

    -- esx
    if GetResourceState('es_extended') == 'started' then
        local ok, esx = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and esx then
            local data = esx.GetPlayerData()
            if data and data.inventory then
                for _, v in pairs(data.inventory) do
                    if v.name == item and (v.count or 0) > 0 then return true end
                end
            end
        end
    end

    return false
end

local function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
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
    DrawText(sx, sy)
end

CreateThread(function()
    Wait(600)
    SpawnNPC()

    while true do
        local sleep = 400
        local player = PlayerPedId()
        local pCoords = GetEntityCoords(player)

        if not npcPed or not DoesEntityExist(npcPed) then
            SpawnNPC()
            Wait(1500)
        else
            local nCoords = GetEntityCoords(npcPed)
            local dist = #(pCoords - nCoords)

            if dist < 10.0 then
                sleep = 0

                if dist <= Config.InteractionDistance then
                    DrawText3D(nCoords.x, nCoords.y, nCoords.z + 1.05, "[E] Open Inventory | " .. Config.RequiredItem)

                    -- Multiple ways to detect E (some servers block one)
                    local pressed = IsControlJustPressed(0, 38) 
                        or IsControlJustReleased(0, 38) 
                        or IsDisabledControlJustPressed(0, 38)
                        or IsControlJustPressed(0, 51)   -- also E on some binds
                        or IsControlJustPressed(1, 38)

                    if pressed and (GetGameTimer() - lastPress) > 600 then
                        lastPress = GetGameTimer()
                        print("^3[E] Press detected^0")

                        if HasItem(Config.RequiredItem) then
                            ForceOpenInventory()
                        else
                            BeginTextCommandThefeedPost("STRING")
                            AddTextComponentSubstringPlayerName("~r~Missing item: ~w~" .. Config.RequiredItem)
                            EndTextCommandThefeedPostTicker(false, true)
                            print("^1[E] Missing required item^0")
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

print("^2[SCRIPT] Hardened NPC + Inventory ready^0")
print("^3Item required: " .. Config.RequiredItem .. " | ForceOpen = " .. tostring(Config.ForceOpen) .. "^0")