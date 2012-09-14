#
# Cookbook Name:: etchosts
# Recipe:: default
#
# Copyright 2010, afistfulofservers
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
#

nodes = search(:node, "hostname:[* TO *]")

# self
localhostentry = [ { "ipv4addr", node[:ipaddress], "fqdn", node[:fqdn] } ]

nodeentries = Array.new

nodes.each do |node|
  nodeentries << { "ipv4addr", node[:cloud][:public_ips][0], "fqdn", node[:fqdn] }
end

## ye ole file
template "/etc/hosts" do
  source "etchosts.erb"
  variables(
    :localhostentry => localhostentry,
    :nodeentries => nodeentries
  )
  mode 0644
end

