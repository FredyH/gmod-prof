AddCSLuaFile()
Profiler.Hooks = Profiler.Hooks or {}

include("sh_hooks.lua")
AddCSLuaFile("cl_hooks.lua")
if (CLIENT) then
    include("cl_hooks.lua")
else
    include("sv_hooks.lua")
end
include("sh_hook_recorder.lua")