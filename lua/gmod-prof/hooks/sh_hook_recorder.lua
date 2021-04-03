AddCSLuaFile()

Profiler.Hooks.HookBucket = Profiler.Hooks.HookBucket or {}
Profiler.Hooks.HookBucketMT = { __index = Profiler.Hooks.HookBucket }

Profiler.Hooks.CurrentHookNameID = Profiler.Hooks.CurrentHookNameID or 0
Profiler.Hooks.HookNameIDs = Profiler.Hooks.HookNameIDs or {}
Profiler.Hooks.HookNameLookup = Profiler.Hooks.HookNameLookup or {}

function Profiler.Hooks:NewHookBucket(bucketNum)
    local tbl = {}
    tbl.TotalCalls = 0
    tbl.TotalDuration = 0
    tbl.RecordedCalls = {}
    tbl.BucketNum = bucketNum
    return setmetatable(tbl, Profiler.Hooks.HookBucketMT)
end

function Profiler.Hooks.HookBucket:RecordHookCall(eventName, hookName, duration)
    self.RecordedCalls[eventName] = self.RecordedCalls[eventName] or {}

    self.TotalCalls = self.TotalCalls + 1
    self.TotalDuration = self.TotalDuration + duration

    local tbl = self.RecordedCalls[eventName]
    tbl.Name = eventName
    tbl.TotalCalls = (tbl.TotalCalls or 0) + 1
    tbl.TotalDuration = (tbl.TotalDuration or 0) + duration
    tbl.FirstEncounter = tbl.FirstEncounter or UnPredictedCurTime()

    tbl.RecordedCalls = tbl.RecordedCalls or {}
    tbl.RecordedCalls[hookName] = tbl.RecordedCalls[hookName] or {}

    local hookEntry = tbl.RecordedCalls[hookName]
    hookEntry.Name = hookName
    hookEntry.TotalCalls = (hookEntry.TotalCalls or 0) + 1
    hookEntry.TotalDuration = (hookEntry.TotalDuration or 0) + duration
    hookEntry.FirstEncounter = hookEntry.FirstEncounter or UnPredictedCurTime()
end

if (SERVER) then
    util.AddNetworkString("profiler_hook_profiler_update")
end

function Profiler.Hooks.HookBucket:WriteData()
    local hookNamesToSend = {}
    for k, call in pairs(self.RecordedCalls) do
        if (Profiler.Hooks.HookNameIDs[call.Name]) then continue end
        local newID = Profiler.Hooks.CurrentHookNameID
        hookNamesToSend[call.Name] = newID
        Profiler.Hooks.CurrentHookNameID = newID + 1
        Profiler.Hooks.HookNameIDs[call.Name] = newID
        Profiler.Hooks.HookNameLookup[newID] = call.Name
    end

    net.WriteUInt(table.Count(hookNamesToSend), 16)
    for k,v in pairs(hookNamesToSend) do
        net.WriteString(k)
        net.WriteUInt(v, 16)
    end

    net.WriteUInt(self.BucketNum, 32)
    net.WriteUInt(self.TotalCalls, 32)
    net.WriteFloat(self.TotalDuration)

    net.WriteUInt(table.Count(self.RecordedCalls), 32)
    for k, call in pairs(self.RecordedCalls) do
        net.WriteUInt(Profiler.Hooks.HookNameIDs[call.Name] or 0, 16)
        net.WriteUInt(call.TotalCalls, 32)
        net.WriteFloat(call.TotalDuration)
        net.WriteFloat(call.FirstEncounter)
    end
end

function Profiler.Hooks:ReadHookBucket()

    local newIDCount = net.ReadUInt(16)
    for i = 1, newIDCount do
        local name = net.ReadString()
        local id = net.ReadUInt(16)
        Profiler.Hooks.HookNameIDs[name] = id
        Profiler.Hooks.HookNameLookup[id] = name
    end

    local bucketNum = net.ReadUInt(32)
    local bucket = Profiler.Hooks:NewHookBucket(bucketNum)
    bucket.TotalCalls = net.ReadUInt(32)
    bucket.TotalDuration = net.ReadFloat()

    local callCount = net.ReadUInt(32)
    for i = 1, callCount do
        local tbl = {}
        tbl.Name = Profiler.Hooks.HookNameLookup[net.ReadUInt(16)]
        tbl.TotalCalls = net.ReadUInt(32)
        tbl.TotalDuration = net.ReadFloat()
        tbl.FirstEncounter = net.ReadFloat()
        tbl.RecordedCalls = {}
        bucket.RecordedCalls[tbl.Name] = tbl
    end
    return bucket
end

Profiler.Hooks.HookRecorder = Profiler.Hooks.HookRecorder or {}
Profiler.Hooks.HookRecorderMT = { __index = Profiler.Hooks.HookRecorder }

function Profiler.Hooks:NewHookRecorder(bucketDuration, bucketsToKeep)
    local tbl = {}
    tbl.GlobalBucket = Profiler.Hooks:NewHookBucket(0)
    tbl.Buckets = {}
    tbl.BucketDuration = bucketDuration or 2
    tbl.BucketsToKeep = bucketsToKeep or 10
    return setmetatable(tbl, Profiler.Hooks.HookRecorderMT)
end

function Profiler.Hooks.HookRecorder:RecordHookCall(eventName, hookName, duration)
    local bucketNum = math.floor(SysTime() / self.BucketDuration)
    self.GlobalBucket:RecordHookCall(eventName, hookName, duration)
    local currentBucket = self.CurrentBucket
    if (!currentBucket || currentBucket.BucketNum != bucketNum) then
        local oldBucket = self.CurrentBucket
        currentBucket = Profiler.Hooks:NewHookBucket(bucketNum)
        table.insert(self.Buckets, currentBucket)
        if (#self.Buckets > self.BucketsToKeep) then
            table.remove(self.Buckets, 1)
        end
        self.CurrentBucket = currentBucket
        if (oldBucket) then
            self:OnBucketFinished(oldBucket)
        end
    end
    self.CurrentBucket:RecordHookCall(eventName, hookName, duration)
end

function Profiler.Hooks.HookRecorder:OnBucketFinished(bucket)
end