Profiler.Hooks.HookProfilingWindow = Profiler.Hooks.HookProfilingWindow or {}

concommand.Add("profile_hooks_server", function(ply, args)
    if (!Profiler:PlayerAllowedToProfile(ply, "hooks")) then return end
    net.Start("gmod_prof_hooks_profiling")
    net.WriteBool(true)
    net.SendToServer()
    local pnl = vgui.Create("gmod_prof_hook_profiler")
    pnl.ServerSide = true
    Profiler.Hooks.HookProfilerPanel = pnl
end)

net.Receive("gmod_prof_hooks_profiling", function()
    local pnl = Profiler.Hooks.HookProfilerPanel
    if (!IsValid(pnl) || !pnl.ServerSide) then return end
    local bucketDuration = net.ReadFloat()
    local globalBucket = Profiler.Hooks:ReadHookBucket()
    local finishedBucket = Profiler.Hooks:ReadHookBucket()
    local millis = math.Round(finishedBucket.TotalDuration * 1000 / bucketDuration, 1)
    pnl:AddHookDuration(millis)
    pnl:UpdateGlobalHooks(globalBucket.RecordedCalls)
end)


concommand.Add("profile_hooks_client", function(ply, cmd, args)
    if (!Profiler:PlayerAllowedToProfile(ply, "hooks")) then return end

    Profiler.Hooks:EnableHookProfiling(true, 5, 10)

    local pnl = vgui.Create("gmod_prof_hook_profiler")
    function Profiler.Hooks.CurrentRecorder:OnBucketFinished(bucket)
        if (!IsValid(pnl)) then return end
        local millis = math.Round(bucket.TotalDuration * 1000 / self.BucketDuration, 1)
        pnl:AddHookDuration(millis)
        pnl:UpdateGlobalHooks(self.GlobalBucket.RecordedCalls)
    end
end)

function Profiler.Hooks.HookProfilingWindow:OnRemove()
    if (self.ServerSide) then
        net.Start("gmod_prof_hooks_profiling")
        net.WriteBool(false)
        net.SendToServer()
    else
        Profiler.Hooks:EnableHookProfiling(false)
    end
end

function Profiler.Hooks.HookProfilingWindow:Init()
    self:SetTitle("Hook Profiling")
    self:SetSize(ScrW() * 0.7, ScrH() * 0.8)
    self.HTML = vgui.Create("DHTML", self)
    self.HTML:OpenURL(PROFILER_DOMAIN_PREFIX .. "hooks/index.html")
    self.HTML:Dock(FILL)

    function self.HTML.ConsoleMessage(_, msg)
    end

    self:Center()
    self:MakePopup()
end

local function callsToJson(calls)
    local rowArr = {}
    for _, call in SortedPairsByMemberValue(calls, "TotalCalls", true) do
        local durationSinceEncounter = (CurTime() - call.FirstEncounter)
        local callsPerSecond = math.Round(call.TotalCalls / durationSinceEncounter, 1)
        local durationPerSec = math.Round((call.TotalDuration * 1000) / durationSinceEncounter, 2)
        local totalDuration = math.Round(call.TotalDuration * 1000, 3)
        table.insert(rowArr, {call.Name, call.TotalCalls, callsPerSecond, totalDuration, durationPerSec})
    end
    return util.TableToJSON(rowArr)
end

function Profiler.Hooks.HookProfilingWindow:UpdateGlobalHooks(calls)
    self.HTML:QueueJavascript("updateHookTableRows(" .. callsToJson(calls) .. ")")
end

function Profiler.Hooks.HookProfilingWindow:AddHookDuration(duration)
    self.HTML:QueueJavascript("addHookDuration(" .. duration .. ")")
end

vgui.Register("gmod_prof_hook_profiler", Profiler.Hooks.HookProfilingWindow, "DFrame")

net.Receive("gmod_prof_hooks_profiling_sync", function(len, ply)
    Profiler.Hooks.HookNameIDs = {}
    Profiler.Hooks.HookNameLookup = {}
    local newIDCount = net.ReadUInt(16)
    for i = 1, newIDCount do
        local name = net.ReadString()
        local id = net.ReadUInt(16)
        Profiler.Hooks.HookNameIDs[name] = id
        Profiler.Hooks.HookNameLookup[id] = name
    end
end)