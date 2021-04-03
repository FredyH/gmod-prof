# Gmod Prof - A sensible Garry's Mod Profiler

**Note:** This repository is WIP and none of the code in it will work yet.

**Warning:** When the profiler is enabled it overrides functions that are critical for the gamemode to work. If any errors occur during this process, the gamemode will likely end up in an unusable state which can only be recovered from by reloading the server (e.g. changing the map). This is especially likely when using third party addons that modify the behaviour of default Garry's Mod libraries such as hook or net.



## Usage

**Note:** This repository is WIP and the code is not in a functional state yet.

To use Gmod Prof simply place this addon in your addon folder.

When ingame you can open the profiler using the following four console commands: profile_hooks_client, profile_hooks_server,
profile_net_client, profiler_net_server

You will have to adapt some functions to ensure that only authorized clients can use the profiler, namely you have to override the following function to return true if and only if the player should be allowed to profile (action can be either "hook" or "net").
```LUA
function Profiler:PlayerAllowedToProfile(ply, action)
    return true
end
```
Currently the default behaviour is to allow anyone to profile, which will be changed when the profiler is in a more complete state. It should be noted that the profiler does not leak any overly sensitive information (other than file names, line numbers and hook/event names), so even if unauthorized clients do have access to the profiler it should not be a massive security risk.


## Documentation

**TODO:** Add Documentation for each window and what the columns mean and how to use the page in general.

## Reasons to use this profiler (incomplete)

- More modern UI with more information (some of which is still TODO)
- Performance hit when using the profiler is negligible, even in production
- Actually allows pinpointing performance issues (unlike other profilers)


## Comparisons to other Profilers
### FProfiler
**TODO:**
### DBugR
**TODO:**

## Incomplete TODO List
- Load the included webpages even if you do not have the addon in your addon folder (i.e. similarly to how gmod sends lua files to the clients even though they don't have them locally)
- UI Improvements
    - Add all the different menus into one big menu (with tabs?)
    - Easy start/stop profiling buttons, etc.
    - Allow clicking a point in the graph to see the information for that time period
    - Allow clicking an event name to see information about the hooks of that event (drilling down)
- Make it so you can let the profiler collect data in the background and not just when the window is open
- Add timer profiling (this will likely require overriding the timer functions)
- Drill down into
- Possibly exclude the profiler's net messages from being included in the net profiler?
- Different permission for client/server profiling
- Make detouring hooks/net messages an overridable function, so that the behaviour can be modified in case of using custom hook/net libraries
- Add garbage collection statistic to the hook profiler (i.e. how much memory was allocated per hook)
