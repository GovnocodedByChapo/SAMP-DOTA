local Map = require('dota.map');
local Controls = require('dota.controls');

---@type Item
local blink_dagger = {
    type = require('dota.types').ItemType.TARGET_POINT,
    category = 'main',
    subCategory = 'other',
    name = 'Blink Dagger',
    cooldown = 20,
    targetRange = 10,
    onUse = function(point)
        if (point) then
            setCharCoordinates(PLAYER_PED, point.x, point.y, point.z);
            msg('teleported')
            return true;
        end
    end
};

return blink_dagger;