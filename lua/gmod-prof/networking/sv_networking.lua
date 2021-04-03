Profiler.Net.SubscribedClients = Profiler.Net.SubscribedClients or {}

util.AddNetworkString("gmod_prof_network_profiling")

function Profiler.Net:UnsubscribeClient(ply)
    if (!table.HasValue(Profiler.Net.SubscribedClients, ply)) then return end
    table.RemoveByValue(Profiler.Net.SubscribedClients, ply)
    if (#Profiler.Net.SubscribedClients == 0) then
        Profiler.Net:EnableNetworkProfiling(false)
    end
end

function Profiler.Net:SendNetUpdate(globalBucket, currentBucket, incoming, bucketDuration)
    net.Start("gmod_prof_network_profiling")
    net.WriteFloat(bucketDuration)
    net.WriteBool(incoming)
    globalBucket:WriteData()
    currentBucket:WriteData()
    net.Send(Profiler.Net.SubscribedClients)
end

function Profiler.Net:SubscribeClient(ply)
    if (table.HasValue(Profiler.Net.SubscribedClients, ply)) then return end
    if (#Profiler.Net.SubscribedClients == 0) then
        local bucketDuration = 2
        Profiler.Net:EnableNetworkProfiling(true, bucketDuration, 10)
        function Profiler.Net.IncomingNetRecorder:OnBucketFinished(bucket)
            timer.Simple(0, function()
                Profiler.Net:SendNetUpdate(self.GlobalBucket, bucket, true, bucketDuration)
            end)
        end
        function Profiler.Net.OutgoingNetRecorder:OnBucketFinished(bucket)
            timer.Simple(0, function()
                Profiler.Net:SendNetUpdate(self.GlobalBucket, bucket, false, bucketDuration)
            end)
        end
    end
    table.insert(Profiler.Net.SubscribedClients, ply)
end

net.Receive("gmod_prof_network_profiling", function(len, ply)
    if (!Profiler:PlayerAllowedToProfile(ply, "net")) then return end
    if (net.ReadBool()) then
        Profiler.Net:SubscribeClient(ply)
    else
        Profiler.Net:UnsubscribeClient(ply)
    end
end)


hook.Add("PlayerDisconnected", "NetProfilerHook", function(ply)
    Profiler.Net:UnsubscribeClient(ply)
end)
