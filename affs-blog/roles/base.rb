name "base"
description "base"
run_list [
  "recipe[selinux::disabled]",
  "recipe[etchosts]",
  "recipe[yum::epel]",
  "recipe[debugtools]"
]
