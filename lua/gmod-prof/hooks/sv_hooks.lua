Profiler.Hooks.SubscribedClients = Profiler.Hooks.SubscribedClients or {}

util.AddNetworkString("gmod_prof_hooks_profiling")
util.AddNetworkString("gmod_prof_hooks_profiling_sync")

function Profiler.Hooks:UnsubscribeClient(ply)
    if (!table.HasValue(Profiler.Hooks.SubscribedClients, ply)) then return end
    table.RemoveByValue(Profiler.Hooks.SubscribedClients, ply)
    if (#Profiler.Hooks.SubscribedClients == 0) then
        Profiler.Hooks:EnableHookProfiling(false)
    end
end

function Profiler.Hooks:SendHooksUpdate(globalBucket, currentBucket, incoming, bucketDuration)
    net.Start("gmod_prof_hooks_profiling")
    net.WriteFloat(bucketDuration)
    globalBucket:WriteData()
    currentBucket:WriteData()
    net.Send(Profiler.Hooks.SubscribedClients)
end

function Profiler.Hooks:SubscribeClient(ply)
    if (table.HasValue(Profiler.Hooks.SubscribedClients, ply)) then return end
    net.Start("gmod_prof_hooks_profiling_sync")
    net.WriteUInt(table.Count(Profiler.Hooks.HookNameIDs), 16)
    for k,v in pairs(Profiler.Hooks.HookNameIDs) do
        net.WriteString(k)
        net.WriteUInt(v, 16)
    end
    net.Send(ply)

    if (#Profiler.Hooks.SubscribedClients == 0) then
        local bucketDuration = 2
        Profiler.Hooks:EnableHookProfiling(true, bucketDuration, 10)
        function Profiler.Hooks.CurrentRecorder:OnBucketFinished(bucket)
            timer.Simple(0, function()
                Profiler.Hooks:SendHooksUpdate(self.GlobalBucket, bucket, true, bucketDuration)
            end)
        end
    end
    table.insert(Profiler.Hooks.SubscribedClients, ply)
end

net.Receive("gmod_prof_hooks_profiling", function(len, ply)
    if (!Profiler:PlayerAllowedToProfile(ply, "hooks")) then return end
    if (net.ReadBool()) then
        Profiler.Hooks:SubscribeClient(ply)
    else
        Profiler.Hooks:UnsubscribeClient(ply)
    end
end)


hook.Add("PlayerDisconnected", "HooksProfilerHook", function(ply)
    Profiler.Hooks:UnsubscribeClient(ply)
end)
