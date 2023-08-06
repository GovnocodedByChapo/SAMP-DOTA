local snet = require('lib.snet');
local Packet = require('dota.net.packet');
local bstream = snet.bstream;

local MP = {
    snet = {
        snet = snet,
        client = snet.client('127.0.0.1', 7777);
        bstream = bstream
    },
};

return MP;