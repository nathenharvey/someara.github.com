---
layout: post
title: "CFEngine Puppet and Chef Part 1"
date: 2011-12-30 20:09
comments: true
published: true
categories: [CFEngine, Puppet, Chef]
---

<h2> Introduction </h2>
Over the past few years, the topic of Infrastructure Automation has received a huge amount of attention. The three most commonly used tools for doing this (in order of appearance) are CFEngine, Puppet, and Chef. This article explores each of them by using one to set up another. If you have a chef-server or Hosted Chef account, you can follow along by following the instructions in the setup section. (Full disclosure: I work for Opscode, creators of Chef.)

<h2> Infrastructure </h2>
<a href=http://www.infrastructures.org target="_blank">“Infrastructure”</a> turns out to be the hardest thing to explain when discussing automation, yet is the most critical to understand. In this context, Infrastructure isn’t anything physical (or virtualized) like servers or networks. Instead, what we’re talking about is all the “stuff” that is configured across machines to enable an application or service.

In practice, “stuff” translates to operating system baselines, kernel settings, disk mounts, OS user accounts, directories, symlinks, software installations, configuration files, running processes, etc. People of the ITIL persuasion may think of these as Configuration Items. Units of management are composed into larger constructs, and complexity arises as these arrangements become more intricate.

Services running in an Infrastructure need to communicate with each other, and do so via networks. Even when running on a single node, things still communicate over a loopback address or a Unix domain socket. This means that Infrastructure has a topology, which is in itself yet another thing to manage.

<h2> Automation </h2>
{% img left http://upload.wikimedia.org/wikipedia/commons/7/75/Duck_of_Vaucanson.jpg %}

Here is a picture of a duck.

This duck happens to be an <a href=http://en.wikipedia.org/wiki/Automaton target="_blank">automaton</a>. An automaton is a self-operating machine. This one pretends to digest grain. It interacts with its environment by taking input and producing output. To continue operating, the duck requires maintenance. It needs to be wound, cleaned, and repaired. Automated services running on a computer are no different. 

Once turned on, an automated service takes input, does something useful, then leaves logs and other data in its wake. Its machinery is the arrangement of software installation, configuration, and the running state of a process. Maintenance is performed in a <a href=http://en.wikipedia.org/wiki/Autonomic_Computing target="_blank">control loop</a>, where an agent comes around at regular intervals inspecting its parts and fixing anything that’s broken.

In automated configuration management, the name of the game is hosting policy. The agents that build and maintain systems pull down blueprints and set to work building our automatons. When systems come back up from maintenance or new ones spring into existence, they configure themselves by downloading policy from the server.

<h2> Setup </h2>

If you'd like to follow along by configuring your own machines with knife, follow the setup instructions <a href=/cfchefipuppetengine-setup target="_blank">here</a>. The setup will get your Chef workstation configured, code checked out from my blog git repo, and uploaded to chef-server for use. Otherwise, you can just browse the source <a href=https://github.com/someara/affs-blog target="_blank">here</a>

<h2> CFEngine </h2>

{% img right http://farm1.staticflickr.com/120/293693669_59574a7640_m.jpg A picture of what a cloud may look like %}

CFEngine is a system based on <a href=http://research.iu.hio.no/papers/rosegarden.pdf target="_blank">promise</a> <a href=http://project.iu.hio.no/papers/origin2.pdf target="_blank">theory</a>. Promises are the basic atoms of the CFEngine universe. They have names, types, and intentions (among other things), and each acts as a convergent operator to move its subject toward an intended state. Like the parts in our duck, promises are assembled to create a larger whole. 

Promises of various types are capable of different things. Promises of type "package" can interact with a package manager to make sure somthing is installed or removed, while a promise of type "file", can copy, edit, and set permissions. Processes can be started or stopped, and commands can be ran if needed. Read all about them in the CFEngine <a href=http://cfengine.com/manuals/cf3-reference.html target="_blank">reference manual</a>.


Promises provide a <a href=http://c2.com/cgi/wiki?DeclarativeDefinition target="_blank">declarative</a> interface to resources under management, which has the remarkably handy attribute of being <a href=http://en.wikipedia.org/wiki/Idempotence target="_blank">idempotent</a>. An idempotent function gives the same result when applied multiple times. This allows our duck repairing maintence loop (in the form of cf-agent on a cron) to come around and safely execute instructions without having to worry about side effects. Consider "the line 'foo' should exist in the file" vs "append 'foo' to the end of the file"; the non-declarative 'append' would not be safe to repeat.

<a href=http://en.wikipedia.org/wiki/Convergence_(mathematics) target="_blank">Convergent</a> maintenance refers to the continuous repair of a system towards a desired state. At the individual promise level, convergence happens in a single run of the maintenance loop. If a package is supposed to be installed but isn't, action will be taken to fix it. If a process is not running but should be, action will be taken again. Convergence in a larger system of promises can take multiple runs if things are processed in a non-optimal order. Consider the following:

{% codeblock %}
Start the NTP service.
Make sure the NTP configuration file is correct, restart the NTP service if repaired.
Install the NTP package.
{% endcodeblock %}

Assuming a system with a base install, the first promise would fail to be kept. The NTP binary is not available, since we haven't installed its package yet. The second promise would write the configuration file, but fail to restart the service. The third promise would succeed, assuming an appropriate package repo was available and functioning properly. After the first run is complete, the system has converged closer to where we want it to be, but isn't quite there yet. Applying the functions again gets us closer to our goal.

The second run of the loop would succeed in starting the service, but would be using the wrong configuration file. The package install from the previous loop clobbered the one written previously. Promise number two would fix the config and restart the service, and the third would do nothing because the package is already installed. Finally, we've converged to our desired system state. A third loop would take no actions at all.

<h2> Kicking things off </h2>
To set up a CFEngine server, invoke the following Chef command:

{% codeblock lang:sh %}
knife bootstrap centos6-1 -r 'role[cfengine]' -N "cfengine-1.example.com" -E development -d affs-omnibus-pre -x root
{% endcodeblock %}

When Chef is done doing its thing, you'll end up with a functioning CFEngine policy host, happily promising to serve policy. Log into the freshly configured machine and check it out. Three things have happened. First, the cfengine package itself has been installed. Second, two directories have been created and populated: `/var/cfengine/inputs`, and `/var/cfengine/masterfiles`.

The `inputs` directory contains configuration for the CFEngine itself, which includes a promise to make the contents of `masterfiles` available for distribution. When a CFEngine client comes up, it will copy the contents of `/var/cfengine/masterfiles` from the server into its own `inputs` directory.


<h2> Examining policy </h2>
CFEngine's main configuration file is `promises.cf`, from which everything else flows.  Here's a short snippet:

{% codeblock promises.cf snippet lang:ruby %}
body common control
{
  bundlesequence  => {
    "update",
    "garbage_collection",
    "cfengine",
    "puppet_server",
  };

  inputs  => {
    "update.cf",
    "cfengine_stdlib.cf",
    "cfengine.cf",
    "garbage_collection.cf",
    "puppet.cf",
  };
}
{% endcodeblock %}

The bundlesequence section tells cf-agent what promise bundles to execute, and in what order. The one we're examining today is named puppet_server, found in `puppet.cf`

{% include_code lang:ruby cookbooks/cfengine/templates/default/inputs/puppet.cf.erb %}

A promise bundle is CFEngine's basic unit of intent. It's a place to logically group related promises. Within a bundle, CFEngine processes things with <a href=http://cfengine.com/manuals/cf3-reference.html#Normal-ordering target="_blank">normal ordering</a>. That is, variables are converged first, then classes, then files, then packages, and so on. I wrote the bundle sections in normal order to make it easier to read, but they could be rearranged and still have the same effect. Without going into too much detail about the language, I'll give a couple hints to help with groking the example. 

First, in CFEngine, the word 'class' does not mean what it normally does in other programming languages. Instead, classes are boolean flags that describe context. Classes can be 'hard classes', which are discovered attributes about the environment (hostname, operating system, time, etc), or 'soft classes', which are defined by the programmer. In the above example, puppetmaster_enabled and iptables_enabled are soft classes set based on the return status of a command. In the place of `if` or `case` statements, boolean checks on classes are used.

Second, there are no control statements like `for` or `while`. Instead, when lists are encountered they are automatically iterated. Check out the packages section for examples of both class decisions and list iteration. Given those two things, you should be able to work your way through the example. However, there's really no getting around reading the reference manual if you want to learn CFEngine.

<h2> On to Puppet </h2>
Finally, let's go ahead and use Chef to bring up a CFEngine client, which will be turned into a Puppet server.

{% codeblock lang:sh %}
knife bootstrap centos6-2 -r 'role[puppet]' -N "puppet-1.example.com" -E development -d affs-omnibus-pre -x root
{% endcodeblock %}

The first run will fail, since the host's IP isn't yet in the cfengine server's allowed hosts lists. Complete the convergence by running these commands:

{% codeblock lang:sh %}
knife ssh "role:cfengine" -a ipaddress chef-client
knife ssh "role:puppet" -a ipaddress chef-client
knife ssh "role:puppet" -a ipaddress chef-client
{% endcodeblock %}

And viola! A working Puppet server, serving policy.


