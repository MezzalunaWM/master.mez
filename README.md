# master.mez

master.mez is meant to be part of the default config of any [Mezzaluna](https://github.com/MezzalunaWM/Mezzaluna) install. It provides basic window management in the master and stack style, simmilar to default dwm. As of right now, since Mezzaluna is in early development, this plugin does a little more than just managing windows. To be fair though, this is more for seeing how a plugin might work and seeing what would be required of plugin developers, and what they have the freedom to customize.

There is **NO WAY** to officially install this right now sooooooo, maybe just copy or simlink files where they need to go. Sorry lol.

## Configuration

How configuration works exactly is still up for debate as of now. Peronally I don't think that things like binds for spawning windows are necessary for a window manager plugin, so those are left for the user to still define. But here is what configuring master.mez would hopefully look like.

Also don't know if constructs like workspaces or tags should really be the responsibility of the window manager plugin either, but those will stay for now.

```lua
local master = requre("master")

master.setup({
    master_ratio = 0.5,
    tag_count = 5
})
```
