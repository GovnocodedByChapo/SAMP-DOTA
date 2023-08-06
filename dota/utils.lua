---@meta
---@diagnostic disable:undefined-global

local ffi = require('ffi');
ffi.cdef([[
    typedef struct { float x, y, z; } CVector;
]]);

local Utils = {
    debug = {}
};

local importVars = nil;
function import(items)
    importVars = items;
end

function from(module)
    assert(importVars, 'use importVars {} from "module"');
    local module = require(module);
    for _, var in pairs(importVars) do
        _G[var] = module[var];
    end
    importVars = nil;
end

_G.import, _G.from = import, from;


_G.msg = function(...)
    sampAddChatMessage(table.concat({ ... }, ' '), -1);
end

_G.log = function(...)
    
end

---@param path string directory
---@param ftype string|string[] file extension
---@return string[] files names
function Utils.getFilesInPath(path, ftype)
    assert(path, '"path" is required');
    assert(type(ftype) == 'table' or type(ftype) == 'string', '"ftyp" must be a string or array of strings');
    local result = {};
    for _, thisType in ipairs(type(ftype) == 'table' and ftype or { ftype }) do
        local searchHandle, file = findFirstFile(path..'\\'..thisType);
        table.insert(result, file)
        while file do file = findNextFile(searchHandle) table.insert(result, file) end
    end
    return result;
end

function Utils.bringFloatTo(from, to, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return from + (count * (to - from) / 100), true
    end
    return (timer > duration) and to or from, false
end

function Utils.join_argb(a, r, g, b)
    local argb = b  -- b
    argb = bit.bor(argb, bit.lshift(g, 8))  -- g
    argb = bit.bor(argb, bit.lshift(r, 16)) -- r
    argb = bit.bor(argb, bit.lshift(a, 24)) -- a
    return argb
end
        
function Utils.explode_argb(argb)
    local a = bit.band(bit.rshift(argb, 24), 0xFF)
    local r = bit.band(bit.rshift(argb, 16), 0xFF)
    local g = bit.band(bit.rshift(argb, 8), 0xFF)
    local b = bit.band(argb, 0xFF)
    return a, r, g, b
end
        
function Utils.argb_to_rgba(argb)
    local a, r, g, b = explode_argb(argb)
    return join_argb(r, g, b, a)
end

local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280);
function Utils.getBodyPartCoordinates(id, handle);
    local pedptr = getCharPointer(handle);
    local vec = ffi.new("float[3]");
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true);
    return vec[0], vec[1], vec[2];
end

function Utils.bringFloatTo(from, to, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return from + (count * (to - from) / 100), true
    end
    return (timer > duration) and to or from, false
end


return Utils;