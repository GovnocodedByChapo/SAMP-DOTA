---@diagnostic disable:lowercase-global
--[[
    SAMP-DOTA
    Author: chapo
    Contact:
        - https://vk.com/ya_chapo
        - https://vk.com/chaposcripts
        - https://t.me/chaposcripts

    Special for blast.hk
]]
script_name('SAMP-DOTA');
script_author('chapo');
script_url('N/A');

require('lib.moonloader');
require('dota.utils');
local Camera = require('dota.camera');
local Map = require('dota.map');
local Controls = require('dota.controls');
local Player = require('dota.player');
local Heroes = require('dota.heroes');
local Items = require('dota.items');
local Net = require('dota.net');
local UI = require('dota.ui');
local Lang = require('dota.localization');
local Vector3D = require('lib.vector3d');
local ImGui = require('lib.mimgui');
local ffi = require('ffi');

local f, typeof, label = string.format, type, Lang.label;
local ingame = false;

Lang.setLanguage('ru');

local function msg(...)
    sampAddChatMessage(f('SAMP-DOTA by chapo >> %s', table.concat({ ... }, ' ')), -1);
end

addEventHandler('onScriptTerminate', function(scr, quit)
    if (scr == thisScript()) then
        Map.destroy();
        restoreCameraJumpcut();
        if (not quit) then
            msg(label('script:crash'));
        end
    end
end);


function toggleGame()
    ingame = not ingame;
    if (ingame) then
        for _, ped in pairs(getAllChars()) do
            if (ped ~= PLAYER_PED) then deleteChar(ped) end
        end
        msg(label('game:pedsWasRemoved'));
        Map.createMap('default');
        Map.lastCreepsSpawned = 0--os.clock() + 60;
        lua_thread.create(function()
            wait(100);
            Camera.pointAtPlayer();
        end)
    else
        restoreCameraJumpcut();
    end
end

local testCreep = nil

function main()
    while not isSampAvailable() do wait(0) end
    msg(label('chat:load'));
    restoreCameraJumpcut();
    sampRegisterChatCommand('dot', toggleGame);
    sampRegisterChatCommand('creep.test', function()
        if (testCreep) then
            
            testCreep:destroy();
            testCreep = nil;
            msg('removed')
            return
        end
        local pos = Vector3D(getCharCoordinates(PLAYER_PED));
        testCreep = Map.Creep(2, pos);
        -- testCreep..
        setCharCoordinates(testCreep.handle, pos.x, pos.y, pos.z);
        msg('spawned');
    end);


    Controls.init();
    Camera.init();
    Heroes.init();
    Player.init();
    Items.init();
    Map.init();
    Net.RakNet.init();
    while true do
        wait(0)
        if (Net.RakNet.blockRakNet ~= ingame) then
            Net.RakNet.blockRakNet = ingame;
        end
        if (ingame) then
            Controls.process();
            Camera.process();
            Player.process();
            -- Items.process();
            Map.process();
        end
    end
end

ImGui.OnInitialize(function()
    -- Heroes.loadImages();
    -- Items.loadImages();
end)

ImGui.OnFrame(
    function() return ingame end,
    function(this)
        this.HideCursor = true;
        local res = ImGui.ImVec2(getScreenResolution());
        UI.drawCreepsHealthBars(Map.pool.creep);
    end
)