AddCSLuaFile()
Profiler.Net = Profiler.Net or {}

include("sh_networking.lua")
if (SERVER) then
    include("sv_networking.lua")
end
include("sh_net_recorder.lua")
AddCSLuaFile("cl_net_profiling.lua")
if (CLIENT) then
    include("cl_net_profiling.lua")
end