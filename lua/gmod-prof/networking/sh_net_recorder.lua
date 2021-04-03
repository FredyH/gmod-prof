AddCSLuaFile()

Profiler.Net.NetBucket = Profiler.Net.NetBucket or {}
Profiler.Net.NetBucketMT = { __index = Profiler.Net.NetBucket }

function Profiler.Net:NewNetBucket(bucketNum)
    local tbl = {}
    tbl.TotalBits = 0
    tbl.TotalMessages = 0
    tbl.RecordedCalls = {}
    tbl.BucketNum = bucketNum
    return setmetatable(tbl, Profiler.Net.NetBucketMT)
end

function Profiler.Net.NetBucket:RecordNetCall(name, len)
    self.RecordedCalls[name] = self.RecordedCalls[name] or {}

    self.TotalBits = self.TotalBits + len
    self.TotalMessages = self.TotalMessages + 1

    local tbl = self.RecordedCalls[name]
    tbl.Name = name
    tbl.Count = (tbl.Count or 0) + 1
    tbl.Bits = (tbl.Bits or 0) + len
    tbl.FirstEncounter = tbl.FirstEncounter or CurTime()
end

if (SERVER) then
    util.AddNetworkString("profiler_net_profiler_update")
end

function Profiler.Net.NetBucket:WriteData()
    net.WriteUInt(self.BucketNum, 32)
    net.WriteUInt(self.TotalBits, 32)
    net.WriteUInt(self.TotalMessages, 32)
    net.WriteUInt(table.Count(self.RecordedCalls), 32)
    for k, call in pairs(self.RecordedCalls) do
        net.WriteUInt(util.NetworkStringToID(call.Name), 16)
        net.WriteUInt(call.Count, 32)
        net.WriteUInt(call.Bits, 32)
        net.WriteFloat(call.FirstEncounter)
    end
end

function Profiler.Net:ReadNetBucket()
    local bucketNum = net.ReadUInt(32)
    local bucket = Profiler.Net:NewNetBucket(bucketNum)
    bucket.TotalBits = net.ReadUInt(32)
    bucket.TotalMessage = net.ReadUInt(32)
    local callCount = net.ReadUInt(32)
    for i = 1, callCount do
        local tbl = {}
        tbl.Name = util.NetworkIDToString(net.ReadUInt(16))
        tbl.Count = net.ReadUInt(32)
        tbl.Bits = net.ReadUInt(32)
        tbl.FirstEncounter = net.ReadFloat()
        bucket.RecordedCalls[tbl.Name] = tbl
    end
    return bucket
end

function Profiler.Net.NetBucket:Finish()
end

function Profiler.Net.NetBucket:GetTopCalled()
    local copy = Profiler:ShallowCopy(self.RecordedCalls)
    table.SortByMember(copy, "Count")
    return copy
end

function Profiler.Net.NetBucket:GetBiggestCalls()
    local copy = Profiler:ShallowCopy(self.RecordedCalls)
    table.SortByMember(copy, "Bits")
    return copy
end

Profiler.Net.NetRecorder = Profiler.Net.NetRecorder or {}
Profiler.Net.NetRecorderMT = { __index = Profiler.Net.NetRecorder }

function Profiler.Net:NewNetRecorder(bucketDuration, bucketsToKeep)
    local tbl = {}
    tbl.GlobalBucket = Profiler.Net:NewNetBucket(0)
    tbl.Buckets = {}
    tbl.BucketDuration = bucketDuration or 10
    tbl.BucketsToKeep = bucketsToKeep or 10
    return setmetatable(tbl, Profiler.Net.NetRecorderMT)
end

function Profiler.Net.NetRecorder:OnBucketFinished(bucket)
end

function Profiler.Net.NetRecorder:RecordNetCall(name, len)
    local bucketNum = math.floor(SysTime() / self.BucketDuration)
    self.GlobalBucket:RecordNetCall(name, len)
    local currentBucket = self.CurrentBucket
    if (!currentBucket || currentBucket.BucketNum != bucketNum) then
        local oldBucket = self.CurrentBucket
        currentBucket = Profiler.Net:NewNetBucket(bucketNum)
        table.insert(self.Buckets, currentBucket)
        if (#self.Buckets > self.BucketsToKeep) then
            table.remove(self.Buckets, 1)
        end
        self.CurrentBucket = currentBucket
        if (oldBucket) then
            self:OnBucketFinished(oldBucket)
        end
    end
    self.CurrentBucket:RecordNetCall(name, len)
end