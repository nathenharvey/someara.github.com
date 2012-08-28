# cfengine puppet chef
time knife bootstrap centos6-1  \
  -r 'role[cfengine]'           \
  -N "cfengine-1.example.com"   \
  -E development                \
  -d affs-omnibus-pre           \
  -x root

time knife bootstrap centos6-2  \
  -r 'role[puppet]'             \
  -N "puppet-1.example.com"     \
  -E development                \
  -d affs-omnibus-pre           \
  -x root

time knife bootstrap centos6-3  \
  -r 'role[affs-chef]'          \
  -N "affs-chef-1.example.com"  \
  -E development                \
  -d affs-omnibus-pre           \
  -x root
