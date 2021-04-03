Profiler.Net.NetProfilingWindow = Profiler.Net.NetProfilingWindow or {}

concommand.Add("profile_net_server", function(ply, args)
    if (!Profiler:PlayerAllowedToProfile(ply, "net")) then return end
    net.Start("gmod_prof_network_profiling")
    net.WriteBool(true)
    net.SendToServer()
    local pnl = vgui.Create("gmod_prof_net_profiler")
    pnl.ServerSide = true
    Profiler.Net.NetProfilerPanel = pnl
end)

net.Receive("gmod_prof_network_profiling", function()
    local pnl = Profiler.Net.NetProfilerPanel
    if (!IsValid(pnl) || !pnl.ServerSide) then return end
    local bucketDuration = net.ReadFloat()
    local incoming = net.ReadBool()
    local globalBucket = Profiler.Net:ReadNetBucket()
    local finishedBucket = Profiler.Net:ReadNetBucket()
    if (incoming) then
        pnl:AddIncomingData(math.floor(finishedBucket.TotalBits / 8 / bucketDuration))
        pnl:UpdateGlobalIncomingCalls(globalBucket.RecordedCalls)
    else
        pnl:AddOutgoingData(math.floor(finishedBucket.TotalBits / 8 / bucketDuration))
        pnl:UpdateGlobalOutgoingCalls(globalBucket.RecordedCalls)
    end
end)


concommand.Add("profile_net_client", function(ply, args)
    if (!Profiler:PlayerAllowedToProfile(ply, "net")) then return end

    Profiler.Net:EnableNetworkProfiling(true, 2, 10)

    local pnl = vgui.Create("gmod_prof_net_profiler")
    function Profiler.Net.IncomingNetRecorder:OnBucketFinished(bucket)
        if (!IsValid(pnl)) then return end
        pnl:AddIncomingData(math.floor(bucket.TotalBits / 8 / self.BucketDuration))
        pnl:UpdateGlobalIncomingCalls(self.GlobalBucket.RecordedCalls)
    end
    function Profiler.Net.OutgoingNetRecorder:OnBucketFinished(bucket)
        if (!IsValid(pnl)) then return end
        pnl:AddOutgoingData(math.floor(bucket.TotalBits / 8 / self.BucketDuration))
        pnl:UpdateGlobalOutgoingCalls(self.GlobalBucket.RecordedCalls)
    end
end)

function Profiler.Net.NetProfilingWindow:OnRemove()
    if (self.ServerSide) then
        net.Start("gmod_prof_network_profiling")
        net.WriteBool(false)
        net.SendToServer()
    else
        Profiler.Net:EnableNetworkProfiling(false)
    end
end

function Profiler.Net.NetProfilingWindow:Init()
    self:SetTitle("Network Profiling")
    self:SetSize(ScrW() * 0.7, ScrH() * 0.8)
    self.HTML = vgui.Create("DHTML", self)
    self.HTML:OpenURL(PROFILER_DOMAIN_PREFIX .. "net/index.html")
    self.HTML:Dock(FILL)

    function self.HTML.ConsoleMessage(_, msg)
    end

    self:Center()
    self:MakePopup()
end

local function callsToJson(calls)
    local rowArr = {}
    for _, call in SortedPairsByMemberValue(calls, "Count", true) do
        local bytes = math.floor(call.Bits / 8)
        local duration = (CurTime() - call.FirstEncounter)
        local bytesPerSecond = math.Round(bytes / duration, 1)
        local countPerSecond = math.Round(call.Count / duration, 1)
        table.insert(rowArr, {call.Name, call.Count, countPerSecond, bytes, bytesPerSecond})
    end
    return util.TableToJSON(rowArr)
end

function Profiler.Net.NetProfilingWindow:UpdateGlobalIncomingCalls(calls)
    self.HTML:QueueJavascript("updateIncomingTableRows(" .. callsToJson(calls) .. ")")
end

function Profiler.Net.NetProfilingWindow:AddIncomingData(bytes)
    self.HTML:QueueJavascript("addIncomingData(" .. bytes .. ")")
end

function Profiler.Net.NetProfilingWindow:UpdateGlobalOutgoingCalls(calls)
    self.HTML:QueueJavascript("updateOutgoingTableRows(" .. callsToJson(calls) .. ")")
end

function Profiler.Net.NetProfilingWindow:AddOutgoingData(bytes)
    self.HTML:QueueJavascript("addOutgoingData(" .. bytes .. ")")
end

vgui.Register("gmod_prof_net_profiler", Profiler.Net.NetProfilingWindow, "DFrame")