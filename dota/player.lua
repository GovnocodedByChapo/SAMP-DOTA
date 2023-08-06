require('lib.moonloader');
local Player = {
    health = 0,
    mana = 0,
    healthRegen = 1.3,
    manaRegen = 2.7,
    maxHealth = 960,
    maxMana = 340,
    lastUpdate = 0,
    gold = 600,
    goldRegen = 1,
    inventory = {},
    abilityAvailable = true,
    effets = {},
    itemAvailable = true,
    hero = {}
};

local Utils = require('dota.utils');

--- load all items
function Player.init()

end

function Player.process()
    if (Player.lastUpdate + 1 - os.clock() <= 0) then
        Player.lastUpdate = os.clock();

        --// regen hp
        Player.health = Player.health + Player.healthRegen;
        if (Player.health > Player.maxHealth) then Player.health = Player.maxHealth end

        --// regen mana
        Player.mana = Player.mana + Player.manaRegen;
        if (Player.mana > Player.maxMana) then Player.mana = Player.maxMana end

        Player.gold = Player.gold + Player.goldRegen;
    end
end

return Player;