# LuerlEx

Playground sample of using [luerl](https://github.com/rvirding/luerl).

See this excellent post by Kevin Hoffman on how to use luerl in elixir; [Hosting a Lua Script inside an Elixir GenServer for Fun and Games](https://kevinhoffman.medium.com/hosting-a-lua-script-inside-an-elixir-genserver-for-fun-and-games-2c0662660007).

Lua is useful for scripting in a variety of cases, in `src/luerlex.ex`
you'll find an example of how to use `:luerl` directly. I tried using
[exlua](https://github.com/dryex/exlua) but found that it depends on a
luerl fork and seems outdated.

This example demonstrates a few key elixir and lua interaction aspects.
* Evaluate and run a lua script from lua
* Get the lua's script return value
* Call lua functions from elixir
* Setup and call elixir functions from lua
* Wrap those in "namespaces"
* Have lua call elixir functions that suspend lua pending elixir process messages
* Return complex maps from lua to elixir
* Get lua function pointers and call from elixir
