-- Let's start with just a prints
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

-- The Control module does some more "complex" interacting
-- This demonstatres how lua scripts can wait for and interact
-- with elixir processes

print("Sleeping for 2 seconds...")
Control.sleep_for(2)

delay = 10
print("Going to wait "..delay.." seconds for a message...")
Messages.msg = Control.wait_for(delay)
print("message = "..Messages.msg)

print("Done")
print("--------------------------")

return 3, "heads"
