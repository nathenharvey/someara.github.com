---
layout: post
title: "A Can of Condensed Chef Documentation"
date: 2011-03-15 14:34
comments: true
categories: Chef
---

<h2>
Overview
</h2>

Chef’s documentation is vast and broken up into many pages on the Opscode wiki. The goal here is to index this information and give a brief explanation of each topic without going into too much depth.

<h2>
Architecture
</h2>

<a href= http://wiki.opscode.com/display/chef/Architecture> http://wiki.opscode.com/display/chef/Architecture </a>

Chef is a configuration management platform in the same class of tools as Cfengine, Bcfg2, and Puppet. The idea is to define policy at a centralized, version controlled place, and then have the machines under management pull down their policy and converge onto that state at regular intervals. This gives you a single point of administration allowing for easier change management and disaster recovery. Combined with a compute resource provisioning layer (such as knife’s ability to manipulate EC2 or Rackspace servers), entire complex infrastructures can pop into existence in minutes.

<h2>
Chef Server
</h2>

<a href=http://wiki.opscode.com/display/chef/Chef+Server> http://wiki.opscode.com/display/chef/Chef+Server </a>

Chef server has various components under the hood. Assorted information (cookbooks, databags, client certificates, and node objects), are stored in CouchDB as JSON blobs. CouchDB is indexed by chef-solr-indexer. RabbitMQ sits between the data store and A RESTful API service that exposes all this to the network as chef-server. If you don’t want to run chef-server yourself, Opscode will do it for you for with their Platform service for a meager $5/node/month. The management console is really handy during development, since it provides a nice way to examine JSON data. However, it should be noted that real chefs value knife techniques.

<h2>
Clients
</h2>

<a href=http://wiki.opscode.com/display/chef/API+Clients> http://wiki.opscode.com/display/chef/Api+Clients </a>

In Chef, the term “client” refers to an SSL certificate for an API user of chef-server. This is often a point of confusion, and should not be confused with chef-client. Most of the time, one machine has one client certificate, which corresponds to one node object.

<h2>
Nodes
</h2>

<a href=http://wiki.opscode.com/display/chef/Nodes> http://wiki.opscode.com/display/chef/Nodes </a>

Nodes are JSON representations of machines under Chef management. They live in chef-server. They contain two important things: The node’s run list, and a collection of attributes. The run list is a collection of recipes names that will be ran on the machine when chef-client is invoked. Attributes are various facts about the node, which can be manipulated either by hand, or from recipes.

<h2>
Attributes
</h2>

<a href=http://wiki.opscode.com/display/chef/Attributes> http://wiki.opscode.com/display/chef/Attributes </a>

Attributes are arbitrary values set in a node object. Ohai provides a lot of informational attributes about the node, and arbitrary attributes can be set by the line cooks. They can be set from recipes or roles, and have a precedence system that allow you to override them. Examples of arbitrary attributes are listen ports for network services, or the names of a package on a particular linux distribution (httpd vs apache2).

<h2>
Ohai
</h2>

<a href=http://wiki.opscode.com/display/chef/Ohai> http://wiki.opscode.com/display/chef/Ohai </a>

Ohai is the Chef equivilent of Cfengine’s cf-know and Puppet’s facter. When invoked, it collects a bunch of information about the machine its running on, including Chef related stuff, hostname, FQDN, networking, memory, cpu, platform, and kernel data. This information is then output as JSON and used to update the node object on chef-server. It is possible to write custom Ohai plugins, if your’re interested in something not dug up by default.

<h2>
Chef Client
</h2>

<a href=http://wiki.opscode.com/display/chef/Chef+Client> http://wiki.opscode.com/display/chef/Chef+Client </a>

Managed nodes run an agent called chef-client at regular intervals. This agent can be ran as a daemon or invoked from cron. The agent pulls down policy from chef-server and converges the system to the described state. This lets you introduce changes to machines in your infrastructure by manipulating data in chef-server. The pull (vs push) technique ensures machines that are down for maintenance end up the proper state when turned back on.

<h2>
Resources
</h2>

<a href=http://wiki.opscode.com/display/chef/Resources > http://wiki.opscode.com/display/chef/Resources </a>

Resources are the basic configuration items that are manipulated by Chef recipes. Resources make up the Chef DSL by providing a declarative interface to objects on the machine. Examples of core resources include files, directories, users and groups, links, packages, and services.

<h2>
Recipes
</h2>

<a href=http://wiki.opscode.com/display/chef/Recipes > http://wiki.opscode.com/display/chef/Recipes </a>

Recipes contain the actual code that gets ran on machines by chef-client. Recipes can be made up entirely of declarative resources statements, but rarely are. The real power of Chef stems from a recipes’s ability to search chef-server for information. Recipes can say “give me a list of all the hostnames of my web servers”, and then generate the configuration file for your load balancer. Another recipe might say “give me a list of all my database servers”, so it can configure Nagios to monitor them.

<h2>
Cookbooks
</h2>

<a href=http://wiki.opscode.com/display/chef/Cookbooks> http://wiki.opscode.com/display/chef/Cookbooks </a>

Cookbooks allow you to logically group recipes. Cookbooks come with all the stuff the recipes need to make themselves work, such as files, templates, and custom resources (LWRPs).

<h2>
Roles
</h2>

<a href=http://wiki.opscode.com/display/chef/Roles> http://wiki.opscode.com/display/chef/Roles </a>

Roles allow you to assemble trees of recipe names, which are expanded into run lists. Roles can contain other roles, which serve as vertices, and recipe names, which are the leaves. The tree is walked depth first, which makes ordering intuitive when assembling run lists. It is possible to apply many of these trees to a single node, but you don’t have to. Roles can also contain lists of attributes to apply to nodes, potentially changing recipe behavior.

<h2>
Databags
</h2>

<a href=http://wiki.opscode.com/display/chef/Data+Bags > http://wiki.opscode.com/display/chef/Data+Bags </a>

Databags are arbitrary JSON structures that can be searched for by Chef recipes. They typically contain things like database passwords and other information that needs to be shared between resources on nodes. You can think of them as read only global variables that live on chef-server. They also have a great name that can be used to make various jokes in Campfire.

<h2>
Knife
</h2>

<a href=http://wiki.opscode.com/display/chef/Knife> http://wiki.opscode.com/display/chef/Knife </a>

knife is the CLI interface to the chef-server API. It can manipulate databags, node objects, cookbooks, etc.  It can also be used to provision cloud resources and bootstrap systems.

-s
