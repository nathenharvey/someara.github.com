#######################################################
##
## Installs me some cfengine
##
#########################################################

# variables
cfdir = "/var/cfengine"
node.set[:cfengine][:server]=true
cfengine_clients = search(:node, 'cfengine_client:true')

#######################################################
# packages
#######################################################

# cfengine
package "cfengine"

#######################################################
# files, templates, and directories
#######################################################

# masterfiles
directory "#{cfdir}/masterfiles" do
  action :create
end

# cfengine input files
%w{ inputs masterfiles }.each do |dir|
  %w{ failsafe cfengine_stdlib global garbage_collection cfengine }.each { |c|
    template "#{cfdir}/#{dir}/#{c}.cf" do
      source "inputs/#{c}.cf.erb"
      variables( :cfengine_server => node )
    end
  }

  # updates
  template "#{cfdir}/#{dir}/update.cf" do
    source "inputs/update.cf.erb"
  end
end

# promises.cf
template "#{cfdir}/inputs/promises.cf" do
  source "inputs/promises-server.cf.erb"
  variables( :cfengine_clients => cfengine_clients )
  notifies :restart, "service[cf-serverd]"
  notifies :restart, "service[cf-execd]"
end


#######################################################
# Distribution only
#######################################################

# promises.cf
template "#{cfdir}/masterfiles/promises.cf" do
  source "inputs/promises-client.cf.erb"
  variables( :cfengine_clients => cfengine_clients )
end

# puppet.cf
template "#{cfdir}/masterfiles/puppet.cf" do
  source "inputs/puppet.cf.erb"
  variables( :cfengine_clients => cfengine_clients )
end

## puppet server policy distribution
directory "#{cfdir}/masterfiles/puppet" do
  action :create
end

# puppet/site.pp
remote_directory "#{cfdir}/masterfiles/puppet" do
  source "server/puppet"
end


#######################################################
# services
#######################################################

# poke a hole in the firewall
# FIXME Do this properly once COOK-688 is done
service "iptables" do
  action [:disable,:stop]
end

cfengine_services = %w{
  cf-execd
  cf-serverd
}

# services
cfengine_services.each { |s|
  service s do
    action [:enable,:start]
  end
}

