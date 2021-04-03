AddCSLuaFile()

Profiler.Net.OldNetIncoming = Profiler.Net.OldNetIncoming or net.Incoming
Profiler.Net.OldNetStart = Profiler.Net.OldNetStart or net.Start
if (CLIENT) then
    Profiler.Net.OldNetOutgoing = Profiler.Net.OldNetOutgoing or net.SendToServer
else
    Profiler.Net.OldNetOutgoing = Profiler.Net.OldNetOutgoing or net.Send
end

function Profiler.Net:EnableNetworkProfiling(enabled, bucketDuration, bucketsToKeep)
    self.OutgoingNetRecorder = Profiler.Net:NewNetRecorder(bucketDuration, bucketsToKeep)
    self.IncomingNetRecorder = Profiler.Net:NewNetRecorder(bucketDuration, bucketsToKeep)
    if (enabled) then
        net.Start = Profiler.Net.NetStart
        net.Incoming = Profiler.Net.NetIncoming
        if (CLIENT) then
            net.SendToServer = Profiler.Net.NetOutgoing
        else
            net.Send = Profiler.Net.NetOutgoing
        end
    else
        net.Start = Profiler.Net.OldNetStart
        net.Incoming = Profiler.Net.OldNetIncoming
        if (CLIENT) then
            net.SendToServer = Profiler.Net.OldNetOutgoing
        else
            net.Send = Profiler.Net.OldNetOutgoing
        end
    end
end

function Profiler.Net.NetStart(name, unreliable)
    Profiler.Net.CurrentMessageName = name
    Profiler.Net.OldNetStart(name, unreliable)
end

function Profiler.Net.NetOutgoing(...)
    if (Profiler.Net.CurrentMessageName && Profiler.Net.OutgoingNetRecorder) then
        local _, bitsWritten = net.BytesWritten()
        Profiler.Net.OutgoingNetRecorder:RecordNetCall(Profiler.Net.CurrentMessageName, bitsWritten)
        Profiler.Net.CurrentMessageName = nil
    end
    return Profiler.Net.OldNetOutgoing(...)
end

function Profiler.Net.NetIncoming(len, client)
    local i = net.ReadHeader()
    local strName = util.NetworkIDToString(i)

    if (!strName) then return end
    if (Profiler.Net.IncomingNetRecorder) then
        Profiler.Net.IncomingNetRecorder:RecordNetCall(strName ,len)
    end

    local func = net.Receivers[strName:lower()]
    if (!func) then return end

    --
    -- len includes the 16 bit int which told us the message name
    --
    len = len - 16
    func(len, client)
end