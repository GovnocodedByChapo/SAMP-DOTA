local Utils = require('dota.utils');
local Localization = {
    path = getWorkingDirectory() .. '\\dota\\localization\\',
    language = {},
    current = 'ru',
    text = {}
};

function Localization.init()
    for _, fileName in pairs(Utils.getFilesInPath(Localization.path, '.json')) do
        local file = io.open(Localization.path .. fileName, 'r');
        if (file) then
            local content = file:read('a');
            file:close();

            local status, result = pcall(decodeJson, content);
            if (status and result) then
                local code = fileName:gsub('.json', '');
                table.insert(Localization.language, code);
                Localization.text[code] = result;
            else
                print('[WARNING] error reading localization file', fileName);
            end
        end
    end
end

---@param index string
function Localization.setLanguage(index)
    Localization.current = index;
end

---@param tag string
function Localization.label(tag)
    local fallback = ('LANG$' .. tag);
    local dict = Localization.text[Localization.current]
    return dict and (dict[tag] or fallback) or fallback;
end

return Localization;