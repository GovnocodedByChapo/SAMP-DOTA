---@meta

local Utils = require('dota.utils');
local mimgui = require('mimgui');
local ffi = require('ffi');

local PLACEHOLDER_IMAGE = '';
local Heroes = {
    basePath = getWorkingDirectory() .. '\\dota\\heroes',
    list = {}
};

--- Load heroes images (avatars) and abilities icons
--- CALL IN mimgui.OnInitialize
function Heroes.loadImages()
    for codename, data in pairs(Heroes.list) do
        local imageBase85 = data.imageBase85 or PLACEHOLDER_IMAGE;
        Heroes.list[codename].image = imgui.CreateTextureFromFileInMemory(imgui.new('const char*', imageBase85), #imageBase85);

        --// abilities
        for abilityCodename, ability in pairs(data.abilities) do
            local imageBase85 = data.imageBase85 or PLACEHOLDER_IMAGE;
            Heroes.list[codename].abilities[abilityCodename] = imgui.CreateTextureFromFileInMemory(imgui.new('const char*', imageBase85), #imageBase85);
        end
    end
end

--- Load heroes list in <HEROES>.list
function Heroes.init()
    for _, heroFile in pairs(Utils.getFilesInPath(Heroes.basePath, '.lua')) do
        local hero = require(Heroes.basePath .. '\\' .. heroFile:gsub('.lua', ''));
        Heroes.list[hero.codename] = hero;
    end
end

return Heroes;