#
# Cookbook Name:: affs-chef
# Recipe:: default
#
# Copyright 2011, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# find puppet server
puppet_servers = search(:node,'role:puppet')

unless puppet_servers.empty? then
  # install rbel repo
  include_recipe "yum::epel"

  # install puppet package
  package "puppet"
  package "ruby-rdoc"

  # configure puppet to point to puppet server

  template "/etc/puppet/puppet.conf" do
    source "puppet.conf.erb"
    owner "root"
    mode "0644"
    variables( :puppet_server => puppet_servers[0] )
  end

  # bootstrap puppet
  execute "run puppet" do
    command "/usr/sbin/puppetd -t -v"
    ignore_failure true
  end
end

