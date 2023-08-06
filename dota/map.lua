---@meta
local ffi = require('ffi');
local Vector3D = require('lib.vector3d');
local Utils = require('dota.utils');

local CPed_SetModelIndex = ffi.cast('void(__thiscall *)(void*, unsigned int)', 0x5E4880)

local Map = {
    mapsPath = getWorkingDirectory() .. '\\dota\\maps',
    pos = Vector3D(0, 0, 250),
    requiredModels = { 0, 49 },
    requiredAnimations = {  },
    pool = {
        object = {},
        creep = {
            [1] = {},
            [2] = {}
        }
    },
    lastCreepsSpawned = os.clock(),
    currentMap = 'undefined'
};

local CONST_CREEP_TEAM_MODEL = {
    [1] = 0,
    [2] = 49
};
Map.creepModel = CONST_CREEP_TEAM_MODEL;

function Map.setCharModel(ped, model)
    assert(doesCharExist(ped), 'ped not found')
    if not hasModelLoaded(model) then
        requestModel(model)
        loadAllModelsNow()
    end
    CPed_SetModelIndex(ffi.cast('void*', getCharPointer(ped)), ffi.cast('unsigned int', model))
end


function Map.init()
    for _, animation in pairs(Map.requiredAnimations) do requestAnimation(animation) end
    for _, model in pairs(Map.requiredModels) do requestModel(model) end
    loadAllModelsNow();
end

function Map.process()
    
    printStringNow(tostring(Map.lastCreepsSpawned + 60 - os.clock()), 10);
    if (Map.lastCreepsSpawned + 60 - os.clock() <= 0) then
        Map.lastCreepsSpawned = os.clock();
        Map.spawnCreepsWave();
        msg('CREEPS SPAWNED');
    end

    for team = 1, 2 do
        for _, creep in pairs(Map.pool.creep[team]) do

        end
    end
end
local memory = require('memory');
function Map.setCharHealth(ped, hp)
    assert(doesCharExist(ped), 'ped not found (incorrect handle)')
    local ptr = getCharPointer(ped)
    memory.setfloat(ptr + 0x540, hp, false)
    memory.setfloat(ptr + 0x544, hp, false)
    if getCharHealth(ped) <= 0 then
        setCharCoordinates(ped, 0, 0, -10)
    end
    return getCharHealth(ped) <= 0
end

function Map.spawnCreepsWave()
    local data = Map.loadMapData(Map.currentMap);
    assert(data.creepsSpawnPoints, 'field "creepsSpawnPoints" not found in ' .. Map.currentMap);
    assert(data.creepsSpawnPoints[1] and data.creepsSpawnPoints[2], 'field "creepsSpawnPoints" must be array of arrays of numbers');
    for team = 1, 2 do
        for creepIndex = 1, #data.creepsSpawnPoints[team] do
            local pos = Vector3D(table.unpack(data.creepsSpawnPoints[team][creepIndex][1]));
            local endPoint = Vector3D(table.unpack(data.creepsSpawnPoints[team][creepIndex][2]));
            print('spawn creep', team, creepIndex);
            local creep = Map.Creep(
                team,
                Vector3D(pos.x + Map.pos.x, pos.y + Map.pos.y, pos.z + Map.pos.z + math.random(0.1, 1)),
                Vector3D(endPoint.x + Map.pos.x, endPoint.y + Map.pos.y, endPoint.z + Map.pos.z)
            );
            setCharCoordinates(creep.handle, pos.x + Map.pos.x, pos.y + Map.pos.y, pos.z + Map.pos.z)
            clearCharTasksImmediately(creep.handle);
            Map.setCharHealth(creep.handle, 300);
            setCharCollision(creep.handle, true);
            creep:taskGoTo(Vector3D(endPoint.x + Map.pos.x, endPoint.y + Map.pos.y, endPoint.z + Map.pos.z));
        end
    end
end

---@return number | nil
function Map.getCharTeam(handle)
    for teamIndex, peds in pairs(Map.pool.creep) do
        for k, v in pairs(peds) do
            if (handle == v.handle) then
                return v.team;
            end
        end
    end
end

function Map.Creep(team, pos, finishPos, specialModel, isTower)
    local handle = createChar(6, specialModel or CONST_CREEP_TEAM_MODEL[team], pos.x, pos.y, pos.z);
    Map.setCharModel(handle, specialModel or CONST_CREEP_TEAM_MODEL[team]);
    taskWanderStandard(handle);
    setCharHealth(handle, 100);
    local index = #Map.pool.creep[team] + 1;
    local new = setmetatable(
        {
            handle = handle,
            index = index,
            hp = 100,
            team = team,
            lastAttack = 0,
            target = nil,
            goTo = nil,
            finishPos = finishPos,
            specialModel = specialModel,
            isTower = isTower,
            towerObject = nil,
            lastGoToUpdate = 0
        },
        {
            __index = {
                setHealth = function(self, health)
                    self.health = health;
                    if (self.health <= 0) then
                        self:destroy();
                    end
                end,
                taskGoTo = function(self, pos, angle, withinRadius)
                    self.goTo = pos;
                    taskCharSlideToCoord(handle, pos.x, pos.y, pos.z, angle or 0, withinRadius or 0.3);
                end,
                destroy = function(self)
                    deleteChar(self.handle);
                    Map.pool.creep[team][index] = nil;
                end
            }
        }
    );
    table.insert(Map.pool.creep[team], new);
    return new;
end

--- Destroy all map objects
function Map.destroy()
    for _, object in pairs(Map.pool.object) do
        object:destroy();
    end
    for team = 1, 2 do
        for _, creep in pairs(Map.pool.creep[team]) do
            creep:destroy();
        end
    end
end

---@return string[]
function Map.getMaps()
    return Utils.getFilesInPath(getWorkingDirectory() .. '\\dota\\maps', { '.json' });
end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param color number
---@param width number
---@param polygons number?
function Map.drawCircleIn3d(x, y, z, radius, color, width, polygons)
    local step = math.floor(360 / (polygons or 36));
    local sX_old, sY_old;
    for angle = 0, 360, step do
        ---@diagnostic disable-next-line
        local _, sX, sY, sZ, _, _ = convert3DCoordsToScreenEx(radius * math.cos(math.rad(angle)) + x , radius * math.sin(math.rad(angle)) + y , z);
        if (sZ > 1) then
            if sX_old and sY_old then
                renderDrawLine(sX, sY, sX_old, sY_old, width, color);
            end
            sX_old, sY_old = sX, sY;
        end
    end
end

---@class Map
---@field objects { comment?: string, pos: number[], scale?: number, model: number, rotation: number[], collision?: boolean }[]
---@field name string
---@field author string
---@field creepsSpawnDelay number
---@field spawnPoint Vector3D
---@field creepsSpawnPoints number[][]

---@param mapName string
---@return Map
function Map.loadMapData(mapName)
    local path = ('%s\\%s.json'):format(Map.mapsPath, mapName);
    assert(doesFileExist(path), 'Map not found!'..path);
    local file = io.open(path, 'r');
    assert(file, 'could not open map json');
    local content = file:read('a');
    file:close();

    local result, data = pcall(decodeJson, content);
    assert(result and data, 'error decoding map');
    return data;
end

---@param mapName string
function Map.createMap(mapName, dontSpawnPlayer)
    Map.currentMap = mapName;
    local data = Map.loadMapData(mapName);
    for index, object in pairs(data.objects) do
        -- msg('created map object', type(object.pos[3]));
        local obj = Map.Object(
            object.model,
            Vector3D(object.pos[1] or 0, object.pos[2] or 0, object.pos[3] or 0),
            Vector3D(object.rotation[1] or 0, object.rotation[2] or 0, object.rotation[3] or 0),
            data.collision or true,
            data.scale or 1
        );
    end

    if (not dontSpawnPlayer) then
        setCharCoordinates(PLAYER_PED, Map.pos.x + data.spawnPoint.x, Map.pos.y + data.spawnPoint.y, Map.pos.z + data.spawnPoint.z);
    end
end

---@param model number
---@param pos Vector3D
---@param rotation Vector3D?
---@param collision boolean?
---@param scale number?
---@return table
function Map.Object(model, pos, rotation, collision, scale)
    local handle = createObject(model, Map.pos.x + pos.x, Map.pos.y + pos.y, Map.pos.z + pos.z);
    local rotation = rotation or Vector3D(0, 0, 0);
    setObjectRotation(handle, rotation.x, rotation.y, rotation.z);
    setObjectCollision(handle, collision or true);
    setObjectScale(handle, scale or 1);
    local index = #Map.pool.object + 1;
    local new = setmetatable(
        {
            handle = handle,
            model = model,
            pos = pos,
            rotation = rotation,
            collision = collision,
            scale = scale
        }, {
            __index = {
                heading = getObjectHeading(handle),
                pos = (function()
                    local result, x, y, z = getObjectCoordinates(handle);
                    return result and Vector3D(x, y, z) or Vector3D(0, 0, 0);
                end)(),
                destroy = function()
                    deleteObject(handle);
                    Map.pool.object[index] = nil;
                end
            }
        }
    );
    table.insert(Map.pool.object, new);
    return new;
end

---@param pos Vector3D
---@param maxDist number?
---@param filter fun(handle: number): boolean ?
---@param dontIgnorePlayerPed boolean?
---@return number? handle
---@return number? dist
function Map.getNearestPedFromPos(pos, maxDist, filter, dontIgnorePlayerPed)
    local result = {
        handle = nil,
        minDist = math.huge
    };
    for _, ped in pairs(getAllChars()) do
        if (ped ~= PLAYER_PED or dontIgnorePlayerPed) then
            local x, y, z = getCharCoordinates(ped);
            local dist = getDistanceBetweenCoords3d(x, y, z, pos.x, pos.y, pos.z);
            if (dist < result.minDist and (not maxDist or dist < maxDist) and (type(filter) ~= 'function' or filter(ped))) then
                result = {
                    handle = ped,
                    minDist = dist
                };
            end
        end
    end
    return result.handle, result.minDist;
end

return Map;