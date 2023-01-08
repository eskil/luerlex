# LuerlEx

Playground sample of using [luerl](https://github.com/rvirding/luerl).

See this excellent post by Kevin Hoffman on how to use luerl in elixir; [Hosting a Lua Script inside an Elixir GenServer for Fun and Games](https://kevinhoffman.medium.com/hosting-a-lua-script-inside-an-elixir-genserver-for-fun-and-games-2c0662660007).

Lua is useful for scripting in a variety of cases, in `src/luerlex.ex`
you'll find an example of how to use `:luerl` directly.

```elixir class:"lineNo"
    # Start a lua state that we'll pass around to all lua calls.
    lua_state = :luerl.init()

    # Register some functions that we'll allow lua scripts to call
    lua_state = Enum.reduce(lua_function_table(), lua_state, fn {name, fun}, lua_state ->
      :luerl.set_table(name, fun, lua_state)
    end)
```
