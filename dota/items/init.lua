require('lib.moonloader');
local ItemType = require('dota.types').ItemType;
local Utils = require('dota.utils');
local Map = require('dota.map');
local Controls = require('dota.controls');

---@type { inventory: Item[], basePath: string, list: Item[] }
local Items = {
    inventory = {},
    basePath = getWorkingDirectory() .. '\\dota\\items',
    list = {},
    initialized = false
};

local Binds = {
    [1] = VK_Z,
    [2] = VK_X,
    [3] = VK_C,
    [4] = nil,
    [6] = nil
};


local function useItem(item, slot, ...)
    if (item.cooldown) then
        Items.inventory[slot].lastUsed = os.clock();
    end
    if (item.onUseThread) then
        ---@diagnostic disable-next-line
        return lua_thread.create(item.onUse, ...);
    end
    return item.onUse(...);
end

function Items.loadImages()
    assert(Items.initialized, 'Items are not initialized!');
    for codeName, item in pairs(Items.list) do
        Items.list[codeName].icon = '';
    end
end

function Items.init()
    assert(not Items.initialized, 'Items are already initialized!');
    Items.initialized = true;
    for _, fileName in pairs(Utils.getFilesInPath(Items.basePath, '*.lua')) do
        if (fileName ~= 'init.lua') then
            print(fileName);
            local codeName = fileName:gsub('.lua', '');
            Items.list[codeName] = require('dota.items.' .. codeName);
            print('item loaded', codeName)
        end
    end
    Items.inventory[1] = Items.list.blink_dagger; -- just for test

    addEventHandler('onWindowMessage', function(winMsg, param)
        if (winMsg == 0x0100) then
            for slot, key in pairs(Binds) do
                if (param == key) then
                    if (not Items.inventory[slot]) then
                        return msg('cannot use item in slot', slot, 'slot is empty');
                    end

                    local item = Items.inventory[slot];
                    if (item.cooldown) then
                        if (not item.lastUsed) then Items.inventory[slot].lastUsed = os.clock() - item.cooldown end
                        if (item.lastUsed + item.cooldown - os.clock() > 0) then
                            return msg('Item ' .. item.name .. ' is on cooldown (', item.lastUsed + item.cooldown - os.clock(), ' sec left)!');
                        end
                    end

                    if (item.type == ItemType.INSTANT) then
                        useItem(item, slot);
                    elseif (item.type == ItemType.TOGGLEABLE) then
                        Items.inventory[slot].toggled = not Items.inventory[slot].toggled;
                        useItem(item, slot, Items.inventory[slot].toggled);
                    elseif (item.type == ItemType.VECTOR or item.type == ItemType.TARGET_ENEMY or item.type == ItemType.TARGET_ENTITY or item.type == ItemType.TARGET_TEAM or item.type == ItemType.TARGET_POINT) then
                        lua_thread.create(function()
                            while true do
                                wait(0);
                                local pedX, pedY, pedZ = getCharCoordinates(PLAYER_PED);
                                local pedScreenX, pedScreenY = convert3DCoordsToScreen(pedX, pedY, pedZ);

                                local pointer = Controls.getCursorMapPos();
                                local pointerScreenX, pointerScreenY = convert3DCoordsToScreen(pointer.x, pointer.y, pointer.z);

                                local dist = getDistanceBetweenCoords3d(pedX, pedY, pedZ, pointer.x, pointer.y, pedZ)

                                if (item.targetRange) then
                                    Map.drawCircleIn3d(pedX, pedY, pedZ, item.targetRange, 0xFF00FF00, 5, 50);
                                end

                                if (not item.targetRange or dist <= item.targetRange) then
                                    renderDrawLine(pedScreenX, pedScreenY, pointerScreenX, pointerScreenY, 5, 0xFF00FF00);
                                end

                                if ((not item.targetRange or dist <= item.targetRange) and wasKeyPressed(VK_LBUTTON)) then
                                    local args = {};
                                    if (item.type == ItemType.TARGET_POINT) then
                                        args = { pointer };
                                    else
                                        local handle, dist = Map.getNearestPedFromPos(
                                            pointer,
                                            1.5,
                                            function(pedHandle)
                                                if (item.type == ItemType.TARGET_ENTITY) then
                                                    return true;
                                                elseif ((item.type == ItemType.TARGET_TEAM and Map.getCharTeam(pedHandle) == 1) or (item.type == ItemType.TARGET_ENEMY and Map.getCharTeam(pedHandle) == 2)) then
                                                    return true;
                                                end
                                            end
                                        );
                                        if (handle) then
                                            args = { handle, dist, item.type == ItemType.TARGET_ENTITY and (Map.getCharTeam(handle) or 0) or nil };
                                        end
                                    end
                                    if (useItem(item, slot, table.unpack(args))) then
                                        break;
                                    end
                                end
                                if (wasKeyPressed(VK_RBUTTON)) then
                                    break;
                                end
                            end
                        end)
                    else
                        return msg('Item type handler for type', item.type, 'not found');
                    end
                    return msg('item used', Items.inventory[slot].name);
                end
            end
        end
    end);
end

function Items.process()
    assert(Items.initialized, 'Items are not initialized!');
end

return Items;