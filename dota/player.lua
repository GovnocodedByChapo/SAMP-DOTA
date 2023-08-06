require('lib.moonloader');
local Utils = require('dota.utils');
local Map = require('dota.map');
local AbilityType = require('dota.types').AbilityType;
local Controls = require('dota.controls');
local Player = {
    stats = {
        maxHealth = 1,
        maxMana = 1,
        healthRegen = 1,
        manaRegen = 1,
        damage = 1,
        attackSpeed = 1,
        speed = 1,
        attackRange = 1
    },
    health = 1,
    mana = 0,
    lastUpdate = 0,
    gold = 600,
    goldRegen = 1,
    abilityAvailable = true,
    itemsAvailable = true,
    effects = {},
    inventory = {},
    hero = nil
};

local Utils = require('dota.utils');

local Binds = {
    [1] = VK_Q,
    [2] = VK_W,
    [3] = VK_E,
    [4] = VK_R,
    [6] = nil
};

---@param ability Ability
---@param slot number
---@param ... any
function useAbility(ability, slot, ...)
    print(ability.storage)
    if (ability.cooldown) then
        Player.hero.abilities[slot].lastUsed = os.clock();
    end
    if (ability.useThread) then
        ---@diagnostic disable-next-line
        return lua_thread.create(ability.onUse, ability.storage or {}, ...);
    end
    print(ability.storage, ...);
    return ability.onUse(ability.storage or {},...);
end

function Player.setAbilityStorage(index, key, value)
    Player.hero.abilities[index][key] = value;
end

--- load all items
function Player.init()
    addEventHandler('onScriptTerminate', function(scr, quit)
        if (scr == thisScript()) then
            for index, ability in pairs(Player.hero.abilities) do
                if (type(ability.onScriptUnload) == 'function') then
                    ability.onScriptUnload();
                end
            end
        end
    end);
    addEventHandler('onWindowMessage', function(winMsg, param)
        if (winMsg == 0x0100) then
            for slot, key in pairs(Binds) do
                if (param == key) then
                    if (not Player.hero.abilities[slot]) then
                        return msg('no ability with index', slot);
                    end
                    local ability = Player.hero.abilities[slot];
                    ------------------------------
                    if (ability.cooldown) then
                        if (not ability.lastUsed) then Player.hero.abilities[slot].lastUsed = os.clock() - ability.cooldown end
                        if (ability.lastUsed + ability.cooldown - os.clock() > 0) then
                            return msg('Ability ' .. ability.name .. ' is on cooldown (', ability.lastUsed + ability.cooldown - os.clock(), ' sec left)!');
                        end
                    end

                    if (ability.type == AbilityType.INSTANT) then
                        useAbility(ability, slot);
                    elseif (ability.type == AbilityType.TOGGLEABLE) then
                        Player.hero.abilities[slot].toggled = not Player.hero.abilities[slot].toggled;
                        useAbility(ability, slot, Player.hero.abilities[slot].toggled);
                    elseif (ability.type == AbilityType.VECTOR or ability.type == AbilityType.TARGET_ENEMY or ability.type == AbilityType.TARGET_ENTITY or ability.type == AbilityType.TARGET_TEAM or ability.type == AbilityType.TARGET_POINT) then
                        lua_thread.create(function()
                            while true do
                                wait(0);
                                local pedX, pedY, pedZ = getCharCoordinates(PLAYER_PED);
                                local pedScreenX, pedScreenY = convert3DCoordsToScreen(pedX, pedY, pedZ);

                                local pointer = Controls.getCursorMapPos();
                                local pointerScreenX, pointerScreenY = convert3DCoordsToScreen(pointer.x, pointer.y, pointer.z);

                                local dist = getDistanceBetweenCoords3d(pedX, pedY, pedZ, pointer.x, pointer.y, pedZ)

                                if (ability.targetRange) then
                                    Map.drawCircleIn3d(pedX, pedY, pedZ, ability.targetRange, 0xFF00FF00, 5, 50);
                                end

                                if (not ability.targetRange or dist <= ability.targetRange) then
                                    renderDrawLine(pedScreenX, pedScreenY, pointerScreenX, pointerScreenY, 5, 0xFF00FF00);
                                end

                                if ((not ability.targetRange or dist <= ability.targetRange) and wasKeyPressed(VK_LBUTTON)) then
                                    local args = {};
                                    if (ability.type == AbilityType.TARGET_POINT) then
                                        table.insert(args, pointer);
                                    else
                                        local handle, dist = Map.getNearestPedFromPos(
                                            pointer,
                                            1.5,
                                            function(pedHandle)
                                                if (ability.type == AbilityType.TARGET_ENTITY) then
                                                    return true;
                                                elseif ((ability.type == AbilityType.TARGET_TEAM and Map.getCharTeam(pedHandle) == 1) or (ability.type == AbilityType.TARGET_ENEMY and Map.getCharTeam(pedHandle) == 2)) then
                                                    return true;
                                                end
                                            end
                                        );
                                        if (handle) then
                                            table.insert(args, handle);
                                            table.insert(args, dist);
                                            table.insert(args, ability.type == AbilityType.TARGET_ENTITY and (Map.getCharTeam(handle) or 0) or nil);
                                            -- args = { handle, dist,  };
                                        end
                                    end
                                    if (useAbility(ability, slot, table.unpack(args)) ~= nil) then
                                        msg('player->break');
                                        break;
                                    end
                                end
                                if (wasKeyPressed(VK_RBUTTON)) then
                                    break;
                                end
                            end
                        end)
                    else
                        return msg('Item type handler for type', ability.type, 'not found');
                    end
                    return msg('abi used', ability.name);
                    ------------------------------
                end
            end
        end
    end);
end

---@param hero Hero
function Player.applyHero(hero)
    Player.inventory = {};
    Player.hero = hero;
    Map.setCharModel(PLAYER_PED, hero.model);
    if (hero.weapon) then
        giveWeaponToChar(PLAYER_PED, hero.weapon, 1);
        setCurrentCharWeapon(PLAYER_PED, hero.weapon);
    end
    Player.stats = hero.stats;
    Player.health = hero.stats.maxHealth;
    Player.mana = hero.stats.maxMana;
end

function Player.process()
    for index, ability in pairs(Player.hero.abilities) do
        if (ability.type == AbilityType.TOGGLEABLE) then
            if (ability.toggled) then
                if (type(ability.whileActive)) then
                    ability.whileActive(ability.storage);
                end
            end
        end
    end
    if (Player.lastUpdate + 1 - os.clock() <= 0) then
        Player.lastUpdate = os.clock();

        --// regen hp
        Player.health = Player.health + Player.stats.healthRegen;
        if (Player.health > Player.stats.maxHealth) then Player.health = Player.stats.maxHealth end

        --// regen mana
        Player.mana = Player.mana + Player.stats.manaRegen;
        if (Player.mana > Player.stats.maxMana) then Player.mana = Player.stats.maxMana end

        Player.gold = Player.gold + Player.goldRegen;
    end
end

return Player;