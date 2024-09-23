local Utils = require 'backItems.imports.utils'
local Config = require 'backItems.config'
local plyState = LocalPlayer.state

local BACK_ITEMS <const> = Config.BackItems

InvCache = {}
CurrentWeapon = nil

function UpdateBackItems()
    local formattedData = Utils.formatCachedInventory(InvCache)

    if not lib.table.matches(formattedData, plyState.backItems) then
        plyState:set('backItems', formattedData, true)
    end
end

local function shouldUpdate(slot, change)
    local last = InvCache[slot]
    local update = (last and BACK_ITEMS[last.name]) or (change and BACK_ITEMS[change.name])

    return update
end

AddEventHandler('ox_inventory:updateInventory', function(invChanges)
    if not invChanges then return false end

    local shouldUpdateFlag = false;
    for slot, change in pairs(invChanges) do
        if not shouldUpdateFlag then
            shouldUpdateFlag = shouldUpdate(slot, change)
        end

        InvCache[slot] = change or nil
    end

    if shouldUpdateFlag then UpdateBackItems() end
end)

local function flashlightLoop()
    if not CurrentWeapon then return end

    local state = CurrentWeapon.metadata.flashlight

    if state then
        SetFlashLightEnabled(cache.ped, true)
    end

    while CurrentWeapon do
        local currentState = IsFlashLightOn(cache.ped)
        if state ~= currentState then
            state = currentState
            plyState:set('flashlightState', state, true)
        end
        Wait(100)
    end
end

AddEventHandler('ox_inventory:currentWeapon', function(weapon)
    CurrentWeapon = weapon
    UpdateBackItems()

    if weapon and Utils.hasFlashLight(weapon.metadata.components) then
        flashlightLoop()
    end
end)

lib.onCache('ped', RefreshBackItems)

lib.onCache('vehicle', function(vehicle)
    local toggle = vehicle ~= false

    if toggle and Config.allowedVehicleClasses[GetVehicleClass(vehicle)] then
        return
    end

    plyState:set('hideAllBackItems', toggle, true)
    UpdateBackItems()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == cache.resource then
        Wait(100)
        InvCache = exports.ox_inventory:GetPlayerItems()
        CurrentWeapon = exports.ox_inventory:getCurrentWeapon()
        RefreshBackItems()
    end
end)
