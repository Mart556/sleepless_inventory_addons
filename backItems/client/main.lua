local CBackItem = require 'backItems.imports.backitem'
local CBackWeapon = require 'backItems.imports.weapon'
local Utils = require 'backItems.imports.utils'
local plyState = LocalPlayer.state

SetFlashLightKeepOnWhileMoving(true)

local Players = {}

local function deleteBackItemsForPlayer(serverId)
    if not serverId or not Players[serverId] then return end

    for i = 1, #Players[serverId] do
        local backItem = Players[serverId][i]
        if backItem then
            backItem:destroy()
        end
    end

    table.wipe(Players[serverId])
end

local Inventory = exports.ox_inventory;
local function createBackItemsForPlayer(serverId, backItems)
    for i = 1, #backItems do
        local itemData = backItems[i]; if not itemData then return false; end

        table.insert(Players[serverId],
            itemData.isWeapon and CBackWeapon:new(serverId, itemData) or CBackItem:new(serverId, itemData))
    end
end

--[[ local function refreshBackItemsLocal()
    local serverId = cache.serverId
    if Players[serverId] then
        deleteBackItemsForPlayer(serverId)

        local Items = Utils.formatCachedInventory(InvCache)

        createBackItemsForPlayer(serverId, Items)
    end
end ]]

function RefreshBackItems()
    local serverId = cache.serverId

    if not Players[serverId] then
        Players[serverId] = {}
    end

    if plyState.backItems and next(plyState.backItems) then
        plyState:set('backItems', false, true); UpdateBackItems()
    end
end

--[[ AddStateBagChangeHandler('bucket', ('player:%s'):format(cache.serverId), function(_, _, value)
    if value == 0 then
        if plyState.backItems and next(plyState.backItems) then
            refreshBackItemsLocal()
        end
    end
end)

 RegisterNetEvent('txcl:setPlayerMode', function(mode)
    if mode == "noclip" then
        plyState:set("hideAllBackItems", true, true)
    elseif mode == "none" then
        plyState:set("hideAllBackItems", false, true)
    end

    RefreshBackItems()
end) ]]

AddStateBagChangeHandler('backItems', nil, function(bagName, _, backItems, _, replicated)
    if replicated then return end

    local playerId = GetPlayerFromStateBagName(bagName)
    local serverId = GetPlayerServerId(playerId)

    if not Players[serverId] then
        Players[serverId] = {}
    end

    if not backItems then
        return deleteBackItemsForPlayer(serverId)
    end

    local plyPed = playerId == cache.playerId and cache.ped or lib.waitFor(function()
        local ped = GetPlayerPed(playerId)
        if ped > 0 then return ped end
    end, ('%s Player didn`t exsists in time! (%s)'):format(playerId, bagName), 15000)

    if not plyPed or plyPed == 0 then return end

    deleteBackItemsForPlayer(serverId)

    if next(backItems) then
        createBackItemsForPlayer(serverId, backItems)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == cache.resource then
        for serverId, backItems in pairs(Players) do
            if backItems then
                deleteBackItemsForPlayer(serverId)
            end
        end
    end
end)

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(100) end

    while true do
        for serverId, backItems in pairs(Players) do
            local playerIdx = GetPlayerFromServerId(serverId);
            if playerIdx and playerIdx ~= -1 then
                local targetPed = GetPlayerPed(playerIdx);
                if targetPed and DoesEntityExist(targetPed) then
                    for i = 1, #backItems do
                        local backItem = backItems[i]
                        if backItem and not IsEntityAttachedToEntity(backItem.object, targetPed) then
                            backItem:attach()
                        end
                    end
                end
            else
                deleteBackItemsForPlayer(serverId)
            end
        end

        Wait(1500);
    end
end)

RegisterNetEvent('backItems:clearPlayerItems', function(serverId)
    deleteBackItemsForPlayer(serverId)
    Players[serverId] = nil
end)
