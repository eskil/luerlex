-- Let's start with just some printing
print("--------------------------")
print("Greetings Professor Falken")

-- The Message module is used to send/receive a message from elixir
Messages = Messages or {msg = "none"}
function Messages.get_lua_msg()
  return Messages.msg
end
function Messages.set_lua_msg(m)
  Messages.msg = m
end

-- We call this function and print it just as an example
-- of what map
function get_a_map()
   map = {
      room = "hallway",
      actors = {"clock", "plant"},
      locations = {
	 green = "second floor",
	 purple = "sekrit lab",
      },
      substate = {"a", "list"},
   }
   map["address function"] = get_address
   return map
end

-- We can even get a function pointer and call?
address = "1506 Cemetery Lane"
function get_address(str)
   address = "1506 Cemetery Lane, "..str
   return address
end
function get_existing_address()
   return address
end

-- Commented out, but validates that calling get_address via
-- the mapped pointer does in fact update the global address variable.
-- m = get_a_map()
-- f = m["address function"]
-- f("derp")

-- Just some basic lua actions, create tables, dicts and operate on them
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

add_to_my_table("Chuck is a plant.")
print_table(my_table)

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

add_to_my_dict("Chuck", "is a plant.")
print_dict(my_dict)

-- Now let's call the elixir function we setup

print("")
print("--------------------------")
print("Calling elixir functions")

str = luerlex.hello_world("tuna")
print("hello_world = "..str)

x, y = echo(10, 3)
print("echo = "..x..","..y)

rv = adder(10, 3)
print("adder = "..rv)

-- We support argument matching in elixir by looking at the list contents
arg_matching("tuna")
arg_matching("tuna", "head")
arg_matching(1, "car")

-- The Control module does some more "complex" interacting
-- This demonstatres how lua scripts can wait for and interact
-- with elixir processes

print("Sleeping for 2 seconds...")
Control.sleep_for(1)

delay = 10
start_time = os.time()
print("Going to wait "..delay.." seconds for a message starting "..os.date(start_time))
Messages.msg = Control.wait_for(delay)
print("message = "..Messages.msg)
end_time = os.time()
print("Only waited "..os.difftime(end_time, start_time).." seconds")


print("Done")
print("--------------------------")

return 3, "heads"
