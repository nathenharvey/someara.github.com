---
layout: post
title: "CFEngine Puppet and Chef Part 2"
date: 2011-12-30 20:10
comments: true
published: true
categories: [CFEngine, Puppet, Chef] 
---

In the previous installment, we used Chef to configure CFEngine to serve policy that allowed us to create a Puppet service. In this one, we'll have Chef use that Puppet service to create a Chef server. If you think this is a ridiculous thing to do, I would be inclined to agree with you. However, this is my blog so I make the rules. 

<h2> Puppet </h2>
Puppet at its core works like CFEngine. Statements in Puppet are convergent operators, in that they are declarative (and therefore idempotent), and convergent in that they check a resource's state before taking any action. Like the NTP example from the CFEngine installment, non-optimally ordered execution will usually work itself out after repeated Puppet runs. 

Unlike CFEngine, where policy is copied and evaluated on the edges, Puppet clients connect to the Puppet server where configuration is determined based on a certificate CN. A catalog of serialized configuration data is shipped back to the client for execution. This catalog is computed based on the contents of the manifests stored on the server, as well as a collection of <a href=http://puppetlabs.com/puppet/related-projects/facter target="_blank">facts</a> collected from the clients. Puppet facts, like CFEngine hard classes, are discoverable things about a node such as OS version, hostname, kernel version, network information, etc.  

{% img left http://images3.wikia.nocookie.net/__cb20050917222913/memoryalpha/en/images/d/d6/Coffee_replicates_then_mug.jpg 300 300 %}

Puppet works a bit like the food replicators in Star Trek. <a href=http://docs.puppetlabs.com/references/stable/type.html target="_blank">Resources</a> make up the basic atoms of a system, and the precise configuration of each must be defined. If a resource is defined twice in a manifest with conflicting states, Puppet refuses to run.

Ordering can be specified though `require` statements that set up relations between resources. These are used to build a <a href=http://en.wikipedia.org/wiki/Directed_graph target="_blank">directed graph</a>, which Puppet sorts <a href=http://en.wikipedia.org/wiki/Topological_sorting>topologically</a> and uses to determine the final ordering. If a resource in a chain fails for some reason, dependent resources down the graph will be skipped.

This allows for isolation of non-related resources collections. For example, if a package repository for some reason fails to deliver the 'httpd' package, its dependent configuration file and service resources will be skipped. This has nothing to do with an SSH resource collection, so the resources concerning that service will be executed even though the httpd collection had previously failed.

Just be careful not to create the coffee without the cup.

<h2> chef.pp </h2>
Let's examine a Puppet manifest that creates a Chef server on Centos 6.

{% include_code lang:ruby cookbooks/cfengine/files/default/server/puppet/manifests/classes/chef.pp %}

<h2> Picking it apart </h2>
Line 1 is a Puppet class definition. This groups the resource statments between together, allowing us to assign `chef-server` to a node based on its hostname. This can be accomplished with an explicit nodes.pp definition, or with an external node classifier.

Line 3 is an `exec` resource, which we can later refer to with its name: `rbel6-release`. When using `exec` resources, it's up to you to specify a convergence check. In this case, we used the `unless` keyword to check the return status of an rpm command. The same goes for `command` promise types in CFEngine, or an `execute` resources in Chef. 

Line 9 is an example of an array variable, which is iterated over in line 21, much like a CFEngine slist.

Everything else is a standard Puppet resource declaration, each of which have a type, a name, and an argument list. Like CFEngine promises, each type has various intentions available under the hood. Packages can be installed. Services can be running or stopped, and files can be present with certain contents and permissions.

Refer to the Puppet <a href=http://docs.puppetlabs.com/ target="_blank">documentation</a> for more details.

<h2> On to Chef </h2>

{% codeblock lang:sh %}
knife bootstrap centos6-3 -r 'role[affs-chef]' -N "affs-chef-1.example.com" -E development -d affs-omnibus-pre -x root
{% endcodeblock %}


