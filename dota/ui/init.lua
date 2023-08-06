local ImGui = require('mimgui');
local Utils = require('dota.utils');

local Page = {
    MAIN = 0,
    HEROES = 1,
    HERO_SELETION = 2
}

local UI = {
    ImGui = ImGui,
    main = {
        state = false,
        page = 0
    }
};

function UI.drawCreepsHealthBars(pool)
    local BGDL = ImGui.GetBackgroundDrawList();
    for team = 1, 2 do
        for index, creep in pairs(pool[team]) do
            local x, y, z = Utils.getBodyPartCoordinates(8, creep.handle);
            local screen = ImGui.ImVec2(convert3DCoordsToScreen(x, y, z + 0.5));
            local health, maxHealth = getCharHealth(creep.handle), 300;
            local size = 60;
            local from = ImGui.ImVec2(screen.x - size / 2, screen.y - 5);
            local to = ImGui.ImVec2(screen.x + size / 2, screen.y);
            BGDL:AddRectFilled(from + ImGui.ImVec2(-1, -1), to + ImGui.ImVec2(1, 1), 0xFF000000, 2);
            BGDL:AddRectFilled(
                from,
                to + ImGui.ImVec2((health <= maxHealth and health or maxHealth) * ((to.x - from.x) / maxHealth ), 0),
                team == 1 and 0xFF00ff00 or 0xFF0000ff,
                2
            );
        end
    end
end

local label = require('dota.localization').label;

function UI.drawMainMenu()
    local res = ImGui.ImVec2(getScreenResolution());
    ImGui.SetNextWindowSize(res, ImGui.Cond.Always);
    ImGui.SetNextWindowPos(ImGui.ImVec2(0, 0), ImGui.Cond.Always, ImGui.ImVec2(0, 0));
    if (ImGui.Begin('SAMP-DOTA by chapo', nil, ImGui.WindowFlags.NoResize + ImGui.WindowFlags.NoTitleBar)) then
        -- Header
        ImGui.SetCursorPos(ImGui.ImVec2(0, 0));
        local headerHeight = res.y / 15;
        if (imgui.BeginChild('header', imgui.ImVec2(res.x, headerHeight), true)) then
            imgui.SetCursorPos(imgui.ImVec2(res.x / 5, 10));
            if (imgui.Button(label('menu:heroes'), imgui.ImVec2(200, headerHeight - 20))) then

            end

            imgui.SetCursorPos(imgui.ImVec2(res.x - (headerHeight - 20) - 10, 10));
            if (imgui.Button('X', imgui.ImVec2(headerHeight - 20, headerHeight - 20))) then

            end
        end
        imgui.EndChild();

        
        local playButtonSize = imgui.ImVec2(res.x / 4, res.y / 10);
        imgui.SetCursorPos(imgui.ImVec2((res.x - playButtonSize.x) / 2, res.y / 1.3));
        if (imgui.Button(label('menu:play'), playButtonSize)) then

        end
    end
    ImGui.End();
end

function UI.drawHeroSelection()

end


---@param player table
---@param items table
---@return any
function UI.drawGameHud(player, items)
    return ImGui.OnFrame(
        function() return true end,
        function(this)
            this.HideCursor = true;
            local FGDL = ImGui.GetForegroundDrawList();

        end
    )
end

return UI;