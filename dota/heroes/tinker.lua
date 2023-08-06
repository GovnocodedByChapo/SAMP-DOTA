local AbilityType = require('dota.types').AbilityType;
local Map = require('dota.map');
local Utils = require('dota.utils');

---@type Hero
local tinker = {
    name = 'Tinker',
    model = 7,
    storage = {
        matrixObject = nil,
        matrixCreatedAt = nil
    },
    abilities = {},
    stats = {
        maxHealth = 1300,
        maxMana = 200,
        healthRegen = 2,
        manaRegen = 3,
        damage = 10,
        attackSpeed = 10,
        speed = 0,
        attackRange = 1,
    }
};

tinker.abilities = {
    {
        name = 'Laser',
        type = AbilityType.TARGET_ENTITY,
        targetRange = 10,
        onUse = function(_, ped)
            if (ped) then
                tinker.storage.laserStartAt = os.clock();
                lua_thread.create(function()
                    while (true) do
                        wait(0);
                        local time = tinker.storage.laserStartAt + 1 - os.clock();
                        local screenX, screenY = convert3DCoordsToScreen(getCharCoordinates(ped));
                        local selfX, selfY = convert3DCoordsToScreen(getCharCoordinates(PLAYER_PED));
                        renderDrawLine(screenX, screenY, selfX, selfY, 3, 0xCC00ffff);
                        clearCharTasksImmediately(PLAYER_PED);
                        if (time <= 0) then
                            tinker.storage.laserStartAt = 0;
                            break;
                        end
                    end
                end);
                return true;
            else
                msg('not ped')
            end
        end
    },
    {
        name = 'Missles',
        type = AbilityType.INSTANT,
        onUse = function(_, ped)
            local pos = Vector3D(getCharCoordinates(PLAYER_PED));
            local target1, dist1 = Map.getNearestPedFromPos(pos);
            if (target1) then
                local target2, dist2 = Map.getNearestPedFromPos(pos, dist2 + 0.1);
                if (target2) then
                    
                end
            end
        end
    },
    {
        name = 'Matrix Shield',
        type = AbilityType.INSTANT,
        manaRequired = 90,
        cooldown = 12,
        useThread = false,
        onScriptUnload = function()
            if (tinker.storage.matrixObject and doesObjectExist(tinker.storage.matrixObject)) then
                deleteObject(tinker.storage.matrixObject);
            end
        end,
        onUse = function(_, ped)
            lua_thread.create(function()
                while (true) do
                    wait(0);
                    tinker.storage.matrixObject = createObject(18843, 0, 0, 0);
                    setObjectCollision(tinker.storage.matrixObject, false);
                    setObjectScale(tinker.storage.matrixObject, 0.05);
                    attachObjectToChar(tinker.storage.matrixObject, PLAYER_PED, 0, 0, 0, 0, 0, 0);
                    wait(15000);
                    deleteObject(tinker.storage.matrixObject);
                    tinker.storage.matrixObject = nil;
                    break;
                end
            end);
            return true;
        end
    }
};

return tinker;