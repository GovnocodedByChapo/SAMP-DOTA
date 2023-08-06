local AbilityType = require('dota.types').AbilityType;
local Map = require('dota.map');
local Utils = require('dota.utils');
---@type Hero
---@diagnostic disable-next-line
local pudge = {
    name = 'Pudge',
    model = 10,
    storage = {
        t = 1,
        smokeObject = nil,
        rotParticleCreatedAt = nil
    },
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

local function checkROT()
    msg('createdSmoke');
    pudge.storage.rotParticleCreatedAt = os.clock();
    if (pudge.storage.smokeObject and doesObjectExist(pudge.storage.smokeObject)) then
        deleteObject(pudge.storage.smokeObject);
        pudge.storage.smokeObject = nil;
    end
    pudge.storage.smokeObject = createObject(18748, getCharCoordinates(PLAYER_PED));
    attachObjectToChar(pudge.storage.smokeObject, PLAYER_PED, 0, 0, -2, 0, 0, 0);
end

pudge.abilities = {
    {
        name = 'Meat Hook',
        type = AbilityType.VECTOR,
        cooldown = 15,
        useThread = false,
        onUse = function()
            freezeCharPosition(PLAYER_PED, true);
            local hookTime = os.clock();
            local x, y, z = Map.getPosFromCharVector(1.5);
            local hookObject = createObject(2590, x, y, z - 0.5);
            local hookedPed = nil;
            setObjectCollision(hookObject, true);
            lua_thread.create(function()
                while (true) do
                    wait(0);
                    clearCharTasksImmediately(PLAYER_PED);
                    local time = hookTime + 2 - os.clock();
                    local STEP = time > 1 and Utils.bringFloatTo(1, 15, hookTime, 1) or Utils.bringFloatTo(15, 1, hookTime + 1, 1);
                    local x, y, z = Map.getPosFromCharVector(STEP);
                    local hx, hy = convert3DCoordsToScreen(x, y, z);
                    local pedxx, pedy = convert3DCoordsToScreen(Utils.getBodyPartCoordinates(26, PLAYER_PED));
                    renderDrawLine(hx, hy, pedxx, pedy, 3, 0xCC333333);
    
                    setObjectCoordinates(hookObject, x, y, z);
                    setObjectRotation(hookObject, 90, 90, getCharHeading(PLAYER_PED) - 90);
                    setObjectScale(hookObject, 3);
                    for _, ped in ipairs(getAllChars()) do
                        if ped ~= PLAYER_PED and isCharTouchingObject(ped, hookObject) then
                            printStyledString('~g~+HOOKED', 750, 7);
                            attachCharToObject(ped, hookObject, 0, 0, 0, 0, 0, 0);
                        end
                    end
                    
                    if time <= 0 then
                        freezeCharPosition(PLAYER_PED, false);
                        deleteObject(hookObject);
                        break
                    end
                end
            end);
            return true;
        end
    },
    {
        name = 'ROT',
        type = AbilityType.TOGGLEABLE,
        toggled = false,
        useThread = false,
        onScriptUnload = function()
            if (pudge.storage.smokeObject) then
                if (pudge.storage.smokeObject and doesObjectExist(pudge.storage.smokeObject)) then
                    deleteObject(pudge.storage.smokeObject);
                    pudge.storage.smokeObject = nil;
                end
            end
        end,
        whileActive = function()
            if (pudge.storage.rotParticleCreatedAt + 5 - os.clock() <= 0) then
                checkROT();
            end
        end,
        onUse = function(storage, state)
            if (state) then
                checkROT();
            else
                if (pudge.storage.smokeObject and doesObjectExist(pudge.storage.smokeObject)) then
                    deleteObject(pudge.storage.smokeObject);
                    pudge.smokeObject = nil;
                end
            end
            return true;
        end
    }
}

return pudge;