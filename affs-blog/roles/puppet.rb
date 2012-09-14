name "puppet"
description "puppet server"
run_list [
  "role[base]",
  "recipe[puppet::server]"
]
