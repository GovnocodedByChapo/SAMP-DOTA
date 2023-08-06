---@meta
require('lib.moonloader');
local Vector3D = require('lib.vector3d');
local ffi = require('ffi');
local Map = require('dota.map');

ffi.cdef('bool SetCursorPos(int X, int Y);')

local WheelDirection = { Down = 4287102976, Up = 7864320 }
local Camera = {
    pos = Vector3D(0, 0, 0),
    point = Vector3D(0, 0, 0),
    zoom = 20,
    savedCursorPos = { 0, 0 }
};

---@param point Vector3D
---@param cutType number?
function Camera.pointAt(point, cutType)
    Camera.point = point;
    -- cameraResetNewScriptables()
    -- pointCameraAtPoint(point.x, point.y, point.z, cutType or 2)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteFloat(bs, point.x)
    raknetBitStreamWriteFloat(bs, point.y)
    raknetBitStreamWriteFloat(bs, point.z)
    raknetBitStreamWriteInt8(bs, cutType)
    raknetEmulRpcReceiveBitStream(158, bs)
    raknetDeleteBitStream(bs)
end

---@param position Vector3D
function Camera.setPos(position)
    Camera.pos = position;
    -- cameraResetNewScriptables()
    -- setFixedCameraPosition(position.x, position.y, position.z, 0, 0, 0)
    
    local bs = raknetNewBitStream()
    raknetBitStreamWriteFloat(bs, position.x)
    raknetBitStreamWriteFloat(bs, position.y)
    raknetBitStreamWriteFloat(bs, position.z)
    raknetEmulRpcReceiveBitStream(157, bs)
    raknetDeleteBitStream(bs)
end

function Camera.pointAtPlayer()
    local ped = Vector3D(getCharCoordinates(PLAYER_PED))
    Camera.pos.x, Camera.pos.y, Camera.pos.z = ped.x + 15, ped.y, ped.z + 10
end

function Camera.init()
    Camera.pos.z = Camera.pos.z + Camera.zoom;
    addEventHandler('onWindowMessage', function(msg, param)
        if (msg == 0x020a) then
            Camera.pos.z = param == WheelDirection.Down and Camera.pos.z + 2 or Camera.pos.z - 2;
            Camera.pos.x = param == WheelDirection.Down and Camera.pos.x + 1 or Camera.pos.x - 1;
        elseif (msg == 0x0200) then
            if (param == VK_TAB) then
                Camera.pointAtPlayer();
            end
        end
    end);
end

---Call in loop
function Camera.process()
    local resX, resY = getScreenResolution();
    local curX, curY = getCursorPos();

    --// Move camera on screen borders
    if (curX <= 5 or curX >= resX - 5) then
        Camera.pos.y = Camera.pos.y + (curX <= 5 and -0.5 or 0.5);
    elseif (curY <= 5 or curY >= resY - 5) then
        Camera.pos.x = Camera.pos.x + (curY <= 5 and -0.5 or 0.5);
    end

    --// Mouse controls
    if (wasKeyPressed(VK_MBUTTON)) then Camera.savedCursorPos = { x = curX, y = curY } end
    if (wasKeyReleased(VK_MBUTTON)) then ffi.C.SetCursorPos(Camera.savedCursorPos.x, Camera.savedCursorPos.y) end
    if (isKeyDown(VK_MBUTTON)) then
        local mouseDragX, mouseDragY = getPcMouseMovement();
        if (Camera.savedCursorPos) then
            Camera.savedCursorPos = {
                x = Camera.savedCursorPos.x + mouseDragX,
                y = Camera.savedCursorPos.y - mouseDragY
            };
            renderDrawPolygon(Camera.savedCursorPos.x, Camera.savedCursorPos.y, 10, 10, 100, 0, 0xFFffffff);
        end
        if (Camera.savedCursorPos.x > 5 and Camera.savedCursorPos.x < resX - 5) then
            if (Camera.savedCursorPos.y > 5 and Camera.savedCursorPos.y < resY - 5) then
                Camera.pos.y = Camera.pos.y - mouseDragX / 10;
                Camera.pos.x = Camera.pos.x + mouseDragY / 10;
            end
        end
    end
    sampToggleCursor(not isKeyDown(VK_MBUTTON));

    cameraResetNewScriptables();
    Camera.setPos(Camera.pos);
    cameraResetNewScriptables();
    Camera.pointAt(Vector3D(Camera.pos.x - 20, Camera.pos.y, Camera.pos.z - Camera.zoom), 0);
end

return Camera;