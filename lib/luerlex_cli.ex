defmodule LuerlEx.CLI do
  require Logger

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

    script = """
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

    return 12, "hello"
    """

    state = :luerl.init()
    {:ok, chunk, state} = :luerl.load(script, state)
    {result, _state} = :luerl.do(chunk, state)
    Logger.info("result: #{inspect result}")
  end

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
end
