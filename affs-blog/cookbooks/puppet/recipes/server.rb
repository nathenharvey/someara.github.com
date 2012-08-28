#

node.set[:puppet][:server]=true
node.set[:cfengine][:client]=true

cfengine_servers = search(:node, 'role:cfengine')

package "cfengine"

Chef::Log.info("DEBUG: cfengine_server: #{cfengine_servers[0]}")

#######################################################
# Promises for initial bootstrap. Will be overwritten by Cfengine.
#######################################################

# cfengine input files
%w{ cfengine_stdlib global garbage_collection cfengine }.each { |c|
  template "/var/cfengine/inputs/#{c}.cf" do
    source "inputs/#{c}.cf.erb"
    variables( :cfengine_server => cfengine_servers[0] )
    cookbook "cfengine"
  end
}

# failsafe.cf
template "/var/cfengine/inputs/failsafe.cf" do
  source "inputs/failsafe.cf.erb"
  variables( :cfengine_server => cfengine_servers[0] )
  cookbook "cfengine"
end

# update.cf
template "/var/cfengine/inputs/update.cf" do
  source "inputs/update.cf.erb"
  variables( :cfengine_server => cfengine_servers[0] )
  cookbook "cfengine"
end

# promises.cf
template "/var/cfengine/inputs/promises.cf" do
  source "inputs/promises-client.cf.erb"
  cookbook "cfengine"
end

#######################################################
# Go button
#######################################################

# bootstrap that sukka
execute "bootstrap cf-agent against #{cfengine_servers[0][:fqdn]}" do
  command "/var/cfengine/bin/cf-agent -K"
end

