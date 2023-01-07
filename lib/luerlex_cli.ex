defmodule LuerlEx.CLI do
  require Logger

  require Record
  Record.defrecord :erl_func, Record.extract(:erl_func, from: "deps/luerl/src/luerl.hrl")

  def main(argv), do: argv |> parse_argv |> process

  def process(%Optimus.ParseResult{args: _args, options: _options, flags: flags} = cli_args) do
    # Setup logger according to debug and verbose
    case flags[:debug] do
      true -> Logger.configure(level: :debug)
      _ -> case flags[:verbosity] do
             0 -> :ok
             1 -> Logger.configure(level: :warning)
             2 -> Logger.configure(level: :notice)
             3 -> Logger.configure(level: :info)
             _ -> Logger.configure(level: :debug)
           end
    end
    Logger.info("Configuration: #{inspect cli_args}")


    # Start a lua state that we'll pass around to all lua calls.
    lua_state = :luerl.init()

    # Register some functions that we'll allow lua scripts to call
    lua_state = Enum.reduce(lua_function_table(), lua_state, fn {name, fun}, lua_state ->
      :luerl.set_table(name, fun, lua_state)
    end)

    # Parse the lua script into a chunk
    {:ok, chunk, lua_state} = :luerl.load(lua_script(), lua_state)

    # Send a message in 5 seconds to test wait_for
    parent = self()
    spawn(fn ->
      Process.sleep(5000)
      IO.puts("(elixir sends message now)")
      send(parent, {:msg, "big whoop"})
    end)

    # Execute the chunk
    {result, _lua_state} = :luerl.do(chunk, lua_state)

    # Print the result of the script
    IO.puts("result: #{inspect result}")
  end

  # You can ignore the optimus arg parsing. This is just my boilerplate escript
  # code since scripts often suddenly need an argument or two.
  def parse_argv(argv) do
    Optimus.new!(
      name: "luerlex",
      description: "Playground for testing luerl from Elixir",
      version: "0.1",
      author: "eskil@eskil.org",
      about: "Playground for testing luerl from Elixir",
      allow_unknown_args: false,
      parse_double_dash: true,
      args: [],
      flags: [
        debug: [
          short: "-d",
          long: "--debug",
          help: "Enable debug output",
          multiple: false
        ],
        verbosity: [
          short: "-v",
          long: "--verbose",
          help: "Enable verbose output, repeat for more",
          multiple: true
        ]
      ],
      options: [
      ]
    )
    |> Optimus.parse!(argv)
  end

  @doc """
  This function simply returns the script we want to execute.
  """
  def lua_script() do
    """
    print("Hello Zak")
    my_table = {}

    function add_to_my_table(elem)
      print("Adding to table.")
      table.insert(my_table, elem)
    end

    function print_table(t)
      for i, n in ipairs(t) do
        print(i.." = " ..n)
      end
    end

    my_dict = {}
    function add_to_my_dict(key, val)
      print("Adding to dict.")
      my_dict[key] = val
    end

    function print_dict(d)
      for k, v in pairs(d) do
        print(k.." = " ..v)
      end
    end

    add_to_my_table("Chuck is a plant.")
    print_table(my_table)

    add_to_my_dict("Chuck", "is a plant.")
    print_dict(my_dict)

    print("")
    print("Calling elixir functions")

    s = hello_world("tuna")
    print("hello_world = "..s)

    x, y = echo(10, 3)
    print("echo = "..x..","..y)

    r = adder(10, 3)
    print("adder = "..r)

    sleep_for(2)

    print("Going to wait 10 seconds for a message...")
    msg = wait_for(10)
    print("message = "..msg)

    print("Done")

    return 3, "heads"
    """
  end

  @doc """
  This function returns a list of function (name and fn pairs) that we
  want to register.

  Note that the function name is a `["list"]`. This is neccesary when
  passing it to luerl.
  """
  def lua_function_table() do
    [
      {["hello_world"], &hello_world/2},
      {["adder"], &adder/2},
      {["echo"], &echo/2},
      {["sleep_for"], &sleep_for/2},
      {["wait_for"], &wait_for/2},
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
  Pause the lua script for a while or receive
  a message and return the contents to lua.

  This demonstrates coordinating lua scripts with elixir but waiting
  for messages.
  """
  def wait_for([seconds], lua_state) do
    receive do
      {:msg, msg} -> {[msg], lua_state}
    after
      1_000 * seconds -> {["three headed monkey"], lua_state}
    end
  end
end
