defmodule LuerlEx do
  def main(_argv) do
    # To keep this example simple, we'll default to lua/example.lua relative
    # to where we're running.
    lua_file = "lua/example.lua"

    # Start a lua state that we'll pass around to all lua calls.
    lua_state = :luerl.init()

    # Register some functions that we'll allow lua scripts to call.
    # Note: I'm not entirely sure this is the right approach. If you
    # look in luerl_emul, you'll see it uses luerl_heap:alloc_table
    # and luerl_emul:set_global_key(module, table).
    # But this works in my example, but as a TODO, I should revisit this.
    lua_state = Enum.reduce(lua_function_table(), lua_state, fn {name, fun}, lua_state ->
      :luerl.set_table(name, fun, lua_state)
    end)

    # Parse the lua script into a chunk - you can parse an embedded string using
    # :luerl.load/2 instead. So we'll just use elixir to load the file into a string
    # See the lurl interface.
    # https://github.com/rvirding/luerl/wiki/0.6-Interface-functions
    lua_script = File.read!(lua_file)
    {:ok, chunk, lua_state} = :luerl.load(lua_script, lua_state)

    # Send a message in 5 seconds to test wait_for
    parent = self()
    spawn(fn ->
      Process.sleep(5000)
      IO.puts("(this is elixir sending a message now)")
      send(parent, {:msg, "big whoop"})
    end)

    # Execute the chunk
    {lua_result, lua_state} = :luerl.do(chunk, lua_state)

    # Print the result of the script
    IO.puts("lua script returned: #{inspect lua_result}")

    # Check the result is what we expect
    [3, "heads"] = lua_result

    # Occasionally you'll have to call the gc
    lua_state = :luerl.gc(lua_state)

    # Let's see what a complicated lua dictionary/map looks like
    {lua_raw, lua_state} = :luerl.call_function([:get_a_map], [], lua_state)
    IO.puts("raw map from lua: #{inspect lua_raw, pretty: true}")
    # Lua functions return a list of results, so get the first and convert to a Map
    lua_map = Map.new(Enum.at(lua_raw, 0))
    IO.puts("parsed map from lua: #{inspect lua_map, pretty: true}")

    {result, lua_state} = :luerl.call_function([:get_existing_address], [], lua_state)
    IO.puts("get_existing_address = #{inspect result}")

    # One of the keys is a lua function pointer. Get that and call it
    # Note: this doesn't take/return a lua state - this is why calls to get_existing_address
    # don't reflect the change. That could become an issue.
    address_function = lua_map["address function"]
    rvx = address_function.(["Basement"])
    IO.puts("address from #{inspect address_function} is: #{inspect rvx}")

    {result, lua_state} = :luerl.call_function([:get_existing_address], [], lua_state)
    IO.puts("get_existing_address = #{inspect result}")

    # Now we'll interact the other way, and call methods in the lua
    # script from elixir. First call Lua to get message we sent earlier earlier.
    {lua_msg, lua_state} = :luerl.call_function([:Messages, :get_lua_msg], [], lua_state)
    IO.puts("lua was sent the msg: #{inspect lua_msg}")

    # Check the message is what we expect (remember that lua returns lists)
    ["big whoop"] = lua_msg

    # Now call lua to set the msg variable in the Messages module.
    {_, lua_state} = :luerl.call_function([:Messages, :set_lua_msg], ["purple tentacle"], lua_state)

    # And check we see it.
    {lua_msg, _lua_state} = :luerl.call_function([:Messages, :get_lua_msg], [], lua_state)
    IO.puts("lua was update to the msg: #{inspect lua_msg}")

    # Check the result, again, lua returns lists
    ["purple tentacle"] = lua_msg
  end

  @doc """
  This function returns a list of function (name and fn pairs) that we
  want to register.

  Note that the function name is a `["list"]`. This is neccesary when
  passing it to luerl.
  """
  def lua_function_table() do
    [
      # Register a function namespace, ie an empty table.
      {[:luerlex], []},
      # Put a function in the luerlx table/namespace
      {[:luerlex, :hello_world], &hello_world/2},

      # Add two functions to the global namespace
      {[:adder], &adder/2},
      {[:echo], &echo/2},

      # Add another namespace (Control) with two functions related
      # to interacting with elixir threads. The case matters, this module
      # is called as Control.sleep_for, _not_ control.sleep_for.
      {[:Control], []},
      {[:Control, :sleep_for], &sleep_for/2},
      {[:Control, :wait_for], &wait_for/2},
    ]
  end

  @doc """
  One example function that is called from lua.

  Functions exposed to lua receive the arguments as a list (`args`)
  and the lua state.

  They must return a tuple of `{[r1, r2...], lua_state}`

  Lua allows binding of multiple result values, so you can call them as
  ```
  r1, r2 = elixir_func(arg)
  ```
  """
  def hello_world(args, lua_state) do
    IO.puts "Hello world and #{inspect args, pretty: true}"
    {["tuna head"], lua_state}
  end

  @doc """
  Another example that just echos the args back. This tests binding
  to mulitple return values.

  ```
  r1, r2 = echo(1, 2)
  ```
  """
  def echo(args, lua_state) do
    {args, lua_state}
  end

  @doc """
  Trivial added function, performs an operation on the input
  and returns the result.
  """
  def adder([a, b] = _args, lua_state) do
    {[a+b], lua_state}
  end

  @doc """
  Pause the lua script for a while.
  """
  def sleep_for([seconds], lua_state) do
    Process.sleep(1_000 * seconds)
    {[], lua_state}
  end

  @doc """
  Pause the lua script for a while or receive a message and return the
  contents to lua.

  This demonstrates coordinating lua scripts with elixir processes.
  """
  def wait_for([seconds], lua_state) do
    receive do
      {:msg, msg} -> {[msg], lua_state}
    after
      1_000 * seconds -> {["by default it's a three headed monkey"], lua_state}
    end
  end
end
