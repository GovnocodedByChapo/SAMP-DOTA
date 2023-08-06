require('lib.moonloader');
local Map = require('dota.map');
local Utils = require('dota.utils');

local Controls = {
    goTo = {
        state = false,
        pos = Vector3D(0, 0, 0),
        target = nil,
        pointer = {
            radius = 2,
            alpha = 255,
            start = os.clock()
        }
    },
    ---@type { start: number, pos: Vector3D }[]
    circles = {}
};

function Controls.init()
    
end

--- Disable movement keys
--- Player mouse movement
--- Draw player movement circle animation
function Controls.process()
    --// Disable game keys
    for gameKeyId = 0, 20 do
        if (gameKeyId ~= 16 and isButtonPressed(Player, gameKeyId)) then
            setGameKeyState(gameKeyId, 0);
        end
    end
    setGameKeyState(16, 256);

    --// Draw circles
    for index, circle in pairs(Controls.circles) do
        local radius, alpha = Utils.bringFloatTo(0.5, 0, circle.start, 0.5), Utils.bringFloatTo(255, 0, circle.start, 0.5);
        local color = Utils.join_argb(alpha, 0, 255, 0);
        Map.drawCircleIn3d(
            circle.pos.x,
            circle.pos.y,
            circle.pos.z,
            radius,
            color,
            4,
            50
        );
        if (alpha == 0) then
            table.remove(Controls.circles[index]);
        end
    end

    

    --// Mouse movement
    if (wasKeyPressed(VK_RBUTTON)) then
        Controls.goTo.pos = Controls.getCursorMapPos();
        Controls.goTo.state = true;
        
        local target, _ = Map.getNearestPedFromPos(
            Controls.goTo.pos,
            1.5,
            function(ped)
                return getCharModel(ped) ~= Map.creepModel[1];
            end
        );
        if (target) then
            msg('TARGET DETECTED', tostring(target))
        end
        Controls.goTo.target = target or nil;
        
        table.insert(Controls.circles, {
            pos = Controls.goTo.pos,
            start = os.clock()
        });
    end
    if (Controls.goTo.state) then
        local toPos = Controls.goTo.target and (doesCharExist(Controls.goTo.target) and Vector3D(getCharCoordinates(Controls.goTo.target)) or Controls.goTo.pos ) or Controls.goTo.pos;
        taskCharSlideToCoord(PLAYER_PED, toPos.x, toPos.y, toPos.z);
        local x, y, _ = getCharCoordinates(PLAYER_PED);
        if (getDistanceBetweenCoords3d(toPos.x, toPos.y, toPos.z, x, y, toPos.z) < 2) then
            Controls.goTo.state = false;
        end
    end
end

---@param x number?
---@param y number?
---@param custom boolean[]?
---@return Vector3D
---@return table
function Controls.getCursorMapPos(x, y, custom)
    local args = custom or {true, true, false, true, false, false, false}
    local curX, curY = getCursorPos()
    local resX, resY = getScreenResolution()
    local posX, posY, posZ = convertScreenCoordsToWorld3D(x or curX, y or curY, 700.0)
    local camX, camY, camZ = getActiveCameraCoordinates()
    local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, table.unpack(args))
    if result and colpoint.entity ~= 0 then
        local normal = colpoint.normal
        local pos = Vector3D(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]) - (Vector3D(normal[1], normal[2], normal[3]) * 0.1)
        local zOffset = 300
        if normal[3] >= 0.5 then zOffset = 1 end
        local result, colpoint2 = processLineOfSight(pos.x, pos.y, pos.z + zOffset, pos.x, pos.y, pos.z - 0.3, table.unpack(args))
        if result then
            return Vector3D(colpoint2.pos[1], colpoint2.pos[2], colpoint2.pos[3]), colpoint2
        end
    end
    return Vector3D(0, 0, 0), colpoint
end

return Controls;