AddCSLuaFile()

Profiler.Hooks.OldHookAdd = Profiler.Hooks.OldHookAdd or hook.Add
Profiler.Hooks.OldHookRemove = Profiler.Hooks.OldHookRemove or hook.Remove

Profiler.Hooks.HookProfilingEnabled = Profiler.Hooks.HookProfilingEnabled or false

Profiler.Hooks.OriginalHookFuncs = Profiler.Hooks.OriginalHookFuncs or {}
Profiler.Hooks.OriginalEntityHookFuncs = Profiler.Hooks.OriginalEntityHookFuncs or {}
Profiler.Hooks.EntHooksToMonitor = {"Think", "Draw"}

function Profiler.Hooks:EnableHookProfiling(enabled, bucketDuration, bucketsToKeep)
    if (enabled) then
        Profiler.Hooks.CurrentRecorder = Profiler.Hooks:NewHookRecorder(bucketDuration, bucketsToKeep)
        hook.Add = Profiler.Hooks.HookAdd
        hook.Remove = Profiler.Hooks.HookRemove
        Profiler.Hooks.DetourHooks()
    else
        hook.Add = Profiler.Hooks.OldHookAdd
        hook.Remove = Profiler.Hooks.OldHookRemove
        Profiler.Hooks.CurrentRecorder = nil
        Profiler.Hooks.RestoreHooks()
    end
end

local function createReporterFunction(eventName, hookName, func)
    return function(...)
        local start = SysTime()
        local a, b, c, d, e, f = func(...)
        local duration = SysTime() - start
        if (Profiler.Hooks.CurrentRecorder) then
            Profiler.Hooks.CurrentRecorder:RecordHookCall(eventName, hookName, duration)
        end
        return a, b, c, d, e, f
    end
end

function Profiler.Hooks.RestoreHooks()
    //Restore regular hooks
    for eventName, hookEntry in pairs(hook.GetTable()) do
        Profiler.Hooks.OriginalHookFuncs[eventName] = Profiler.Hooks.OriginalHookFuncs[eventName] or {}
        for hookName, func in pairs(Profiler:ShallowCopy(hookEntry)) do
            hookEntry[hookName] = Profiler.Hooks.OriginalHookFuncs[eventName][hookName]
        end
    end
    Profiler.Hooks.OriginalHookFuncs = {}
    //Restore entity hooks
    for entIndex, entry in pairs(Profiler.Hooks.OriginalEntityHookFuncs) do
        local ent = Entity(entIndex)
        if (!IsValid(ent)) then continue end
        for eventName, func in pairs(entry) do
            ent[eventName] = func
        end
    end
    Profiler.Hooks.OriginalEntityHookFuncs = {}
end

hook.Add("EntityRemoved", "ProfilerCleanupHook", function(ent)
    Profiler.Hooks.OriginalEntityHookFuncs[ent:EntIndex()] = nil
end)

function Profiler.Hooks.DetourHooks()
    //Detour regular hooks
    for eventName, hookEntry in pairs(hook.GetTable()) do
        Profiler.Hooks.OriginalHookFuncs[eventName] = Profiler.Hooks.OriginalHookFuncs[eventName] or {}
        for hookName, func in pairs(Profiler:ShallowCopy(hookEntry)) do
            Profiler.Hooks.OriginalHookFuncs[eventName][hookName] = func
            hookEntry[hookName] = createReporterFunction(eventName, hookName, func)
        end
    end
    //Detour entity hooks
    local allEntities =  ents.GetAll()
    for _, ent in pairs(allEntities) do
        local entIndex = ent:EntIndex()
        Profiler.Hooks.OriginalEntityHookFuncs[entIndex] = Profiler.Hooks.OriginalEntityHookFuncs[entIndex] or {}
        for _, eventName in pairs(Profiler.Hooks.EntHooksToMonitor) do
            local originalFunc = ent[eventName]
            if (!originalFunc) then continue end
            Profiler.Hooks.OriginalEntityHookFuncs[entIndex][eventName] = originalFunc
            ent[eventName] = createReporterFunction("ENT_" .. eventName, ent:GetClass(), originalFunc)
        end
    end
end

function Profiler.Hooks.HookAdd(eventName, hookName, func)
    Profiler.Hooks.OriginalHookFuncs[eventName] = Profiler.Hooks.OriginalHookFuncs[eventName] or {}
    Profiler.Hooks.OriginalHookFuncs[eventName][hookName] = func
    Profiler.Hooks.OldHookAdd(eventName, hookName, createReporterFunction(eventName, hookName, func))
end

function Profiler.Hooks.HookRemove(eventName, hookName)
    Profiler.Hooks.OriginalHookFuncs[eventName] = Profiler.Hooks.OriginalHookFuncs[eventName] or {}
    Profiler.Hooks.OriginalHookFuncs[eventName][hookName] = nil
    Profiler.Hooks.OldHookRemove(eventName, hookName)
end