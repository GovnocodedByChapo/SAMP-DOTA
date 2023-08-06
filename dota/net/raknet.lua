local RakNet = {
    blockRakNet = false
};

function RakNet.init()
    for _, event in pairs({ 'onSendRpc', 'onReceiveRpc', 'onSendPacket', 'onReceivePacket' }) do
        addEventHandler(event, function()
            if (RakNet.blockRakNet) then
                return false;
            end
        end)
    end
end

return RakNet;