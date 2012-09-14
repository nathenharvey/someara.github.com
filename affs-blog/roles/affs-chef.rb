name "affs-chef"
description "affs-chef server"
run_list [
  "role[base]",
  "recipe[affs-chef::server]"
]
