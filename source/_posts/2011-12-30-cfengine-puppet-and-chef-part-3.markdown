---
layout: post
title: "CFEngine Puppet and Chef Part 3"
date: 2011-12-30 20:11
comments: true
published: true
categories: [CFEngine, Puppet, Chef]
---

At the end of the last installment, we used Puppet to create a Chef server. That brings us full circle, and the only thing we have left to do is examine how Chef works. We'll do that by looking at the code that gave us our original CFEngine server. 

<h2> Chef </h2>
{% img right http://farm4.staticflickr.com/3024/2417315604_ba73be6be2.jpg 300 300 %}

Since they're both written in Ruby, people tend to compare Puppet and Chef. This is natural since they have a lot in common. Both are convergence based configuration management tools inspired by CFEngine. Both have stand alone discovery agents (facter and ohai, respectively), as well as RESTful APIs for gleaning node information from the server. It turns out, however, that Chef actually has a lot more in common with CFEngine.

Like CFEngine, Chef copies policy from the server and evaluates it on the edges. This allows for high scalability, since the server isn't doing very much. Think of web application that does most of its work in the browser instead of on the server. 

A Chef recipe is a collection of convergent <a href=http://wiki.opscode.com/display/chef/Resources target="_blank">resource</a> statements, and serves as the basic unit of intent. This is analogous to a CFEngine promise bundle. The Chef run list is how recipe ordering is defined, and is directly comparible to CFEngine's bundlesqeuence. Using this approach makes it easy to reason about what's going on when writing infrastructure as code.

<h2> Chef Specials </h2>

<h3> Imperative programming and declarative interface </h3>

While it's true that Chef is just "pure ruby" and therefore imperative, to say that Chef is imperative without considering the declarative interface to resources is disingenuous at best. Using nothing but Chef resources, recipes look very much like their CFEngine and Puppet counterparts. The non-optimally ordered Chef version of NTP converges in the same number of runs as the CFEngine example from the first installment. This is because the <a href=http://www.iu.hio.no/~mark/papers/immune.pdf target="_blank">underlying science</a> of convergent operators is the same.

{% codeblock lang:ruby %}
# service
service "ntp" do
  action [ :enable, :start ]
  ignore_failure true
end

# file 
template "/etc/ntp.conf" do
  source "ntp.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[ntp]"
  ignore_failure true
end

# package 
package "ntp" do
  action :install
  ignore_failure true
end
{% endcodeblock %}

<a href=http://bit.ly/vPixyI target="_blank">When and where order matters</a>, imperative ordering isolated within a recipe is the most intuitive way for sysadmins to accomplish tasks within the convergent model. "Install a package, edit a config file, and start the service" is how most people think about the task. Imperative ordering of declarative statements give the best of both worlds. When order does NOT matter, it's safe to re-arrange recipe ordering in the Chef run list.

<h3> Multiphase execution </h3>
The real trick to effective Chef cookbook development is to understand the <a href=http://wiki.opscode.com/display/chef/Anatomy+of+a+Chef+Run target="_blank">Anatomy of a Chef Run</a>. When a Chef recipe is evaluated in the compilation phase, encountered resources are added to the Resource Collection, which is an array of evaluated resources with deferred execution.

The compile phase of this recipe would add 99 uniquely named, 12 oz, convergent beer_bottles to the collection, and the configure phase would take them down and pass them around. Subsequent runs would do nothing.
{% codeblock lang:ruby thanks jtimberman! %}
size = ((2 * 3) * 4) / 2

99.downto(1) do |i|
  beer_bottle "bottle-#{i}" do
    oz size
    action [ :take_down, :pass_around ]
  end
end
{% endcodeblock %}

The idea is that you can take advantage of the full power of Ruby to make decisions about what to declare about your resources. Most people just use the built in Chef APIs to consult chef-server for topology information about their infrastructure. However, there's nothing stopping you from importing random Ruby modules and accessing existing SQL databases instead. 

Want to name name servers after your Facebook friends? <a href=http://rfacebook.rubyforge.org/ type="_blank">Go for it.</a> Want your MOTD to list all James Brown albums released between 1980 and 1990? <a href=https://github.com/buntine/discogs type="_blank">Not a problem</a>. The important part is that things are ultimately managed with a declarative, idempotent, and convergent resource interface.

<h2> cfengine.rb </h2>

Let's take a look at the recipe that gave us our original CFEngine server.

{% include_code lang:ruby cookbooks/cfengine/recipes/server.rb %}

<h2> Topology management </h2>

When a node is bootstrapped with Chef, a run list of roles or recipes is requested by the node itself. After that, the host is found by recipes running elsewhere in the infrastructure by <a href=http://bit.ly/vI5Z9l target="_blank">searching</a> for roles or attributes. This is contrasted from the CFEngine and Puppet techniques of matching classes based on a hostname, FQDN, IP, or other found information. 

This approach has the effect of decoupling a node's name from its functionality. Line 10 in `cfengine.rb` above searches out node objects and later be passes them to the `promises-server.cf.erb` template for authorization.

<h2> Wrapping up </h2>

So there you have it folks. Chef making CFEngine making Puppet making Chef. These tools can be used to automate literally anything, and they're pretty easy to use once you figure out how they work. I was going to throw some Bcfg2 and LCFG in there just for fun, but I only had some much free time =)

Configuration mangement is like a portal.

-s


