require "sugar"
fs = require "fs"

lorem = "Lorem ipsum Consectetur ut esse exercitation id aute aute voluptate est pariatur aliqua deserunt veniam ea eiusmod ad pariatur proident quis amet Duis Ut fugiat irure laboris do commodo consectetur minim id ullamco consectetur labore labore labore ut commodo ut nisi labore amet sit in in nostrud elit consectetur laboris consectetur est do ut minim proident esse qui minim elit sit minim commodo pariatur deserunt dolor qui sint dolor fugiat in sint in sed eu dolore dolore velit sunt enim Excepteur ut adipisicing ut ut aute nostrud deserunt magna in mollit do enim.".toLowerCase().match /\w+/g
b32 = "0123456789abcdefghjkmnpqrstvwxyz"

str = (len)->
  out = []
  for i in [1..len]
    out.push lorem[Number.random(0,lorem.length)]
  out.join ' '

hash = (len)->
  out = ""
  for i in [1..len]
    out += b32[Number.random(0,31)]
  out

type = ->
  if Number.random(0,100) > 30
    return "bug"
  else if Number.random(0,100) > 50
    return "feature"
  else
    return "strategy"

ids = []

for i in [0..100]

  issue = """
  ## #{str 8}
  + id: #{id = hash 4}
  + type: #{type()}
  + added: #{date = Date.create().addSeconds(1000000-Number.random(0,100000000))}

  #{str Number.random(50,200)}

  - #{str Number.random(3,10)}
  - #{str Number.random(3,10)}
  - #{str Number.random(3,10)}

  #{str Number.random(50,200)}

  ---
  + modified: #{Date.create( date.addSeconds(Number.random(100000,1000000)) )}
  + status: closed

  #{str 50}
  """

  ids.push id

  fs.writeFileSync "gens/klog.#{id}.issue.md", issue

fs.writeFileSync "gens/index.txt", ids.join " "
console.log "done..."