local AbilityType = require('dota.types').AbilityType;
local Map = require('dota.map');

local function coil(range)
    clearCharTasksImmediately(PLAYER_PED);
    if not hasAnimationLoaded('carry') then
        requestAnimation('carry')
    end
    clearCharTasksImmediately(PLAYER_PED)
    taskPlayAnim(PLAYER_PED, 'putdwn105', 'carry', 0, false, true, true, true, 10000)

    local x, y, z = Map.getPosFromCharVector(range);
    local smoke = createObject(18686, x, y, z - 1);
    Map.dealDamageToPoint(Vector3D(x, y, z));
    wait(3000);
    deleteObject(smoke);
end

local abilities = {}
for i = 3, 9, 3 do
    table.insert(abilities, {
        name = ('Coil (%s)'):format(i),
        manaRequired = 50,
        cooldown = 10,
        useThread = true,
        type = AbilityType.INSTANT,
        onUse = function()
            coil(i);
        end
    });
end
table.insert(abilities, {
    name = 'ULT',
    manaRequired = 50,
    cooldown = 10,
    useThread = true,
    type = AbilityType.INSTANT,
    onUse = function()
        local start = os.clock()
        local ultimate_objects = {}
        
        for i = 0, 360, 30 do
            local angle = math.rad(i) + math.pi / 2
            local posX, posY, posZ = getCharCoordinates(PLAYER_PED)

            local start = Vector3D(1 * math.cos(angle) + posX, 1 * math.sin(angle) + posY, posZ - 1)
            local stop = Vector3D(20 * math.cos(angle) + posX, 20 * math.sin(angle) + posY, posZ - 1)
            local handle = createObject(18686, start.x, start.y, start.z)
            ultimate_objects[handle] = {
                start = start,
                stop = stop
            }
            
        end

        -- create object
        while start + 4 - os.clock() > 0 do
            wait(0)
            for handle, data in pairs(ultimate_objects) do
                if doesObjectExist(handle) then
                    slideObject(handle, data.stop.x, data.stop.y, data.stop.z, 0.5, 0.5, 0.5, false)
                    local result, x, y, z = getObjectCoordinates(handle);
                    if result then
                        Map.dealDamageToPoint(Vector3D(x, y, z), 55);
                    end
                end
            end
        end
        for handle, data in pairs(ultimate_objects) do
            if doesObjectExist(handle) then
                deleteObject(handle)
                ultimate_objects[handle] = nil
            end
        end
    end
});

---@type Hero
local shadow_fiend = {
    type = require('dota.types').HeroType,
    name = 'Shadow Fiend',
    model = 5,
    abilities = abilities,
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

return shadow_fiend;