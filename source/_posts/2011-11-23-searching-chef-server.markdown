---
layout: post
title: "Searching Chef Server"
date: 2011-04-07 12:15
comments: true
categories: 
---

<h2> Overview </h2>
Search is Chef’s killer feature for sure. Searching for the IPs or FQDNs of nodes with particular roles or attributes lets you dynamically string together machines within your infrastructure. This eliminates the need for centralized planning of IP addresses among Chef managed resources. This is especially useful on the clouds or in DHCP environments where you are assigned random IPs.

<h2> Munin </h2>
Munin is one of the first cookbooks that I read after finding out about Chef, and is pretty much responsible for selling me on it. Below are the recipes from a simplified version of the munin cookbook.

Munin is a system metrics collection tool that gives you a ton of information out of the box with very little configuration. It’s really great for smaller installations and a great way to get some metrics now if you’re in a hurry. The Opscode apache2 cookbook is included without modification to provide a web console for viewing graphs.

You can view the complete cookbook <a href=https://github.com/someara/affs-blog/tree/0.2.0/cookbooks/munin> here. </a>

<h2> Searching </h2>
The cookbook is broken into two recipes, server.rb and client.rb

The server searches for clients to poll, and the client searches for servers to accept poll connections from. We start out by setting a node attribute in each recipe so the other half has something to search for. 

The search syntax comes from Solr, so a node attribute set with node[:foo][:bar][:baz]=”buzz” is searched for with: search(:node, “foo_bar_baz:buzz”)

Searches return arrays of node objects (JSON blobs), which are then passed into templates where IP information is dug out and rendered into a config file.

<h2> munin::server </h2>
{% codeblock munin/recipes/server.rb %}
node.set[:munin][:server] = true
munin_clients = search(:node, "munin_client:true")

include_recipe "apache2"
include_recipe "apache2::mod_rewrite"
include_recipe "munin::client"

package "munin"

cookbook_file "/etc/cron.d/munin" do
  source "munin-cron"
  mode "0644"
  owner "root"
  group "root"
end

template "/etc/munin/munin.conf" do
  source "munin.conf.erb"
  mode 0644
  variables(:munin_clients => munin_clients)
end

apache_site "000-default" do
  enable false
end

case node[:platform]
  when "fedora", "redhat", "centos", "scientific"
    file "/var/www/html/munin/.htaccess" do
      action [:delete]
    end
end

template "#{node[:apache][:dir]}/sites-available/munin.conf" do
  source "localsystem.apache2.conf.erb"
  mode 0644
  if ::File.symlink?("#{node[:apache][:dir]}/sites-enabled/munin.conf")
    notifies :reload, resources(:service => "apache2")
  end
end

apache_site "munin.conf"
{% endcodeblock %}

<h2> munin::client </h2>
{% codeblock munin/recipes/client.rb %}
node.set[:munin][:client] = true
munin_servers = search(:node, "munin_server:true")

unless munin_servers.empty?
  package "munin-node" do
    action :install
  end

  template "/etc/munin/munin-node.conf" do
    source "munin-node.conf.erb"
    mode 0644
    variables :munin_servers => munin_servers
    notifies :restart, "service[munin-node]"
  end

  service "munin-node" do
    supports :restart => true
    action [ :enable, :start ]
  end
end
{% endcodeblock %}

<h2> Roles vs Attributes </h2>
A number of people have asked me why I used attributes rather than roles. This is to avoid baking convention into the recipe code, which I like to do whenever I can help it.

Consider the following scenario:

You have a role[monitoring], that includes recipe[nagios::server] and recipe[munin::server]. In the Nagios and Munin client cookbooks, you’ve searched for the role[monitoring] are happily populating your configuration files. A few months pass, and you’ve added more machines to your infrastructure. 

One day your monitoring server starts crawling, since it has slow disks and can’t keep up with the IO intensive graph generation. You decide that “monitoring” is an overloaded term, and set off to split your metrics and alerting onto different machines. You edit your role structure and change your node object’s runlist assignment, and bring up some new machines. However, you still have more work to do. Now you have to go into the recipe code and change them to search for their new roles.

Using attributes as above frees you from having to modify the recipe code when editing role definitions. Don’t get me wrong, there are plenty of scenarios where roles are preferable to attributes, but for things like this, I like to avoid them.

-s 

*update* A reader has pointed out that instead of using attributes, I could have used the search syntax search(:node, ‘recipes:”munin::server”’). Good to know!


