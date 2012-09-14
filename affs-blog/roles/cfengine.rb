name "cfengine"
description "cfengine server"
run_list [
  "role[base]",
  "recipe[cfengine::server]"
]
