AddCSLuaFile()

Profiler = Profiler or {}

function Profiler:PlayerAllowedToProfile(ply, action)
    //Override this using functions from your favourite admin
    return true
end

function Profiler:ShallowCopy(tbl)
    local copy = {}
    for k,v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

PROFILER_DOMAIN_PREFIX = PROFILER_DOMAIN_PREFIX or "asset://garrysmod/addons/gmod-prof/html/"

include("networking/sh_init.lua")
include("hooks/sh_init.lua")