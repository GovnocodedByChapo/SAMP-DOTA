local imgui = require('mimgui');
-- local Map = require('dota.map');
local Utils = require('dota.utils');
local UI = {};

function UI.drawCreepsHealthBars(pool)
    local BGDL = imgui.GetBackgroundDrawList();
    for team = 1, 2 do
        for index, creep in pairs(pool[team]) do
            local x, y, z = Utils.getBodyPartCoordinates(8, creep.handle);
            local screen = imgui.ImVec2(convert3DCoordsToScreen(x, y, z + 0.5));
            local health, maxHealth = getCharHealth(creep.handle), 300;
            local size = 70;
            local from = imgui.ImVec2(screen.x - size / 2, screen.y - 5);
            local to = imgui.ImVec2(screen.x + size / 2, screen.y);
            BGDL:AddRectFilled(from + imgui.ImVec2(-1, -1), to + imgui.ImVec2(1, 1), 0xFF000000, 2);
            BGDL:AddRectFilled(
                from,
                to + imgui.ImVec2(0, 0),
                team == 1 and 0xFF00ff00 or 0xFF0000ff,
                2
            );
        end
    end
end

function UI.drawGameHud(player, items)
    return imgui.OnFrame(
        function() return true end,
        function(this)
            this.HideCursor = true
        end
    )
end

return UI;