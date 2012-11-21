---
layout: post
title: "Promises, Lies, and Dry-Run Mode"
date: 2012-12-27 4:20
comments: true
published: false
categories: [CFEngine, Puppet, Chef, Promise Theory, dry-run, noop]
---

<h2>Introduction</h2>

{% img right http://i.imgur.com/Ftyot.jpg 300 %}

"I need to know what this will do to my production system before I run
it." -- Ask 1000 people why they want dry-run mode in a configuration
management tool, and this is the answer you'll get almost every single time.

Many tools in a sysadmin's tool belt have a dry-run mode. Common
utilities like rsync, make, rpm, apt, svn, and git all have it.
Many databases will let you simulate updates, and most disk utilities
can show you changes before making them.

"People have been doing this for years! It should be easy to get a
list of what actions a tool will take! As a matter of fact, NOT 
performing a dry-run on a system is just plain irresponsible!"

Not exactly. 

Systems administrators have historically been able to use dry-run as a
risk mitigation strategy before applying changes to their machines.
The idea is to test a command to determine if it is safe to run.
Unfortunately, this only works if a tool's dry-run reporting can be 
trusted as accurate.

In this post, I'll break down how modern configuration management tools
like CFEngine, Puppet, and Chef are very different animals than the 
classical tool set, and why dry-run mode is less than completely trustworthy. 
I'll provide real world examples of dry-run saying one thing, and
real-run doing another. The takeaway should be that dry-run, while
useful for development, should never be used alone in the place of
proper testing.

<h2> make -n </h2>

{% img left http://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Ford_assembly_line_-_1913.jpg/566px-Ford_assembly_line_-_1913.jpg 300 %}

The <a href=http://pubs.opengroup.org/onlinepubs/009695399/utilities/make.html">make</a>
utility is the earliest example I can find of an automation tool with
a dry-run option. Make is usually used to build software. It calls
compilers, assemblers, linkers, check timestamps, and copy files around the filesystem. 

Dry-run mode in `make -n` works by building a list of commands, then
printing instead of executing them. This is super useful because it
can be trusted that `make` will always execute the exact same list in 
real-run mode. Every. Single. Time. 

Rsync's dry-run mode behaves the same way. The command `rsync -n` will 
print a list of files it needs to copy, and `rsync` will copy the
exact same list. The procedural nature of `rsync` and `make` allow this
to work. Build a list of actions to take, then print them out. Build a
list of actions and execute them instead. Easy.

Configuration Management tools, however, don't build lists of raw
commands. They build sets of convergent operators instead.

<h2> Convergent Operators </h2>

{% img right http://i.imgur.com/x3uWr.png 300 %}

The base building blocks of configuration management systems are executable
data structures known as "convergent operators". Puppet and Chef refer
to them as resources, while CFEngine calls them promises. 

They are composed of a subject and two sets of instructions. The first 
set are tests that determine if the subject is in the desired state,
and the second set are actions that will fix it if it's not. We make 
"types" by grouping common sets of tests and actions. This allows us
to zoom out a level and talk about things like files, services, users, 
groups and jobs abstractly.

CFEngine promise bundles, Puppet manifests, and Chef resource
collections are all sets of these data structures. Putting them into a
<a href="http://en.wikipedia.org/wiki/Control_theory">feedback loop</a>
allows for cooperation over multiple runs, as well as enabling the 
self-healing properties that are essential when dealing with large 
amounts of complexity.

<h2> Promises and Lies </h2>

{% img left http://i.imgur.com/rUk4d.png 350 %}
CFEngine 3 introduced
<a href="http://en.wikipedia.org/wiki/Promise_theory">Promise Theory</a> 
as a way of modeling systems management. In this model, convergent
operators are described as autonomous agents that make "promises" and 
cooperate with each other to configure machines.

While Puppet and Chef are not directly modeling promise theory
(they both lack the formal notion of "promiser and promisee"), the are 
both inspired by CFEngine 2, and therefore share the same convergent DNA. 
It is still very useful to think of a Chef resource statement as an individual, 
stand-alone agent that promises to fix the thing it's concerned about.

When writing my day-to-day Chef cookbooks, I personally imagine every resource
statement I make (or generate) as a little Lego man. Each time the
feedback loop runs, the Lego man's left hand runs tests that interrogate
package managers, inspect files, and examine processes tables. The
right hand  moves only when it needs to make corrections. Recipes
unleash swarms of these little robotic promise makers, each spinning
around dizzily repairing machines.

By personifying our configuration agents, it is easier to imagine them
lying to you. "Why would they lie to me?", you might ask yourself.
Under what circumstances are they likely to lie? What exactly is a lie anyway?

It turns out that a <a href="http://cfengine.com/markburgess/BookOfPromises.pdf">formal</a>
examination of promises does indeed include the notion of lies. Lies
can be outright deceptions, which are the lies of the rarely-encountered evil
robots. Lies can also be "non-deceptions", which are the lies of
occasionally-encountered broken robots. Most often though, we experience lies from the
often-encountered "merely mis-informed" robots.

<h2> Sets and Sequence </h2>
During a run, each tool applies *ordered sets* of convergent
operators against the system. How this order is determined varies from
tool to tool, but it is ordered none the less.

{% img right http://i.imgur.com/g4fcW.png 300 %}

CFEngine uses a system called 'normal ordering' to determine sequence, while Puppet 
sorts graphs. Chef compiles a resource collection by building by evaluatiing.

{% img right http://i.imgur.com/uKQHY.png 300 %}

Sequence ordering is typically important within promise bundles,
modules, and recipes. Ordering is sometimes important between the sets 
themselves, but not usually. Thinking at this level allows us to
effectively reason about the mechanics of dry-run mode.

<h2> The Best You Can Do </h2>

{% img left http://i.imgur.com/oyf5b.png 300 %}

The best you can possibly hope to do in a dry-run mode is to build the operator
sequences, run all the tests, then report back what each agent would
do at that exact moment. The problem with this is, in real-run mode, the
*The system is changing between the tests*. Quite often, the results
of any given test will be affected by a preceeding action.

Configuration operations can have rather large side effects on machine
state. Sending signals to processes can result in files being changed
on disk. Mounting a disks change entire branchs of directory trees.
Packages can drop off one or a million different files and will often
execute arbitrary commands contained in 'pre' and 'post' scripts.
Installing the Postfix package on an Ubuntu system will not only write
the package contents to disk, but also create users and disable Exim
before automatically starting the service.
 
Throw in some resource notifications and random boolean checks and things get really interesting.

<h2> Lies of the Legomen </h2>

{% img right http://i.imgur.com/4ORuB.jpg 250 350 %}

To experiment with dry-run mode, I made a Chef cookbook that
configures a machine with initial conditions, then drops off CFEngine
and Puppet policies for dry-running.

We will see CFEngine Puppet and Chef running in their respective
dry-run modes, stating that they will do some things, immediately
followed by real-run doing some other things.

If you already have Vagrant setup and would like to follow along,
feel free. If not, you can setup a workstation on OSX by following the
instructions <a href="http://somewheregood">here</a>.
Otherwise you can just read the code examples by clicking on the
provided links as we go.

Begin by checking out the dry-run cookbook from git, then configure a
Vagrant box with Chef.

{% codeblock %}
~/src/$ git clone https://github.com/someara/dry-run-lies-cookbook dry-run-lies
~/src/$ cd dry-run-lies
~/src/dry-run-lies$ bundle exec vagrant up
~/src/dry-run-lies$ bundle exec vagrant ssh
{% endcodeblock %}
x
<h2> CFEngine Example </h2>

{% codeblock CFEngine dry-run  %}
root@dry-run-lies:~# cf-agent -K -f /tmp/lies-1.cf -n
-> Would execute script /bin/echo hello from bundle_one. puppet_bin_does_not_exist
 -> Need to execute /usr/bin/aptitude update...
{% endcodeblock %}

Here we see that blah.

{% codeblock CFEngine real-run  %}
root@dry-run-lies:~# cf-agent -K -f /tmp/lies-1.cf 
Q: ".../bin/echo hello": hello from bundle_one.
puppet_bin_does_not_exist
I: Last 1 quoted lines were generated by promiser "/bin/echo hello from bundle_one. puppet_bin_does_not_exist"
Q: ".../bin/echo hello": hello from bundle_three. puppet_bin_exists
I: Last 1 quoted lines were generated by promiser "/bin/echo hello from bundle_three. puppet_bin_exists"
{% endcodeblock %}

<h2> Puppet Example </h2>

{% codeblock Puppet dry-run  %}
root@dry-run-lies:~# puppet apply /tmp/lies-1.pp --noop
notice: /Stage[main]//Mount[/mnt/nfsmount]/ensure: current_value ghost, should be unmounted (noop)
notice: /Stage[main]//Mount[/mnt/nfsmount]: Would have triggered 'refresh' from 1 events
notice: Class[Main]: Would have triggered 'refresh' from 3 events
notice: Stage[main]: Would have triggered 'refresh' from 1 events
notice: Finished catalog run in 0.30 seconds
{% endcodeblock %}

{% codeblock Puppet real-run %}
root@dry-run-lies:~# puppet apply /tmp/lies-1.pp
notice: /Stage[main]//Mount[/mnt/nfsmount]/ensure: ensure changed 'ghost' to 'unmounted'
notice: /Stage[main]//Mount[/mnt/nfsmount]: Triggered 'refresh' from 1 events
notice: /Stage[main]//File[/mnt/nfsmount/file-1]/ensure: created
notice: /Stage[main]//File[/mnt/nfsmount/file-2]/ensure: created
notice: /Stage[main]//File[/mnt/nfsmount/file-3]/ensure: created
notice: Finished catalog run in 4.37 seconds
{% endcodeblock %}

It should be noted here that Puppet's resource graph model does
nothing to enable noop functionality, nor can it effect its
accuracy.

<h2> Chef Example </h2>

{% codeblock %}
root@dry-run-lies:~# chef-solo -c
/tmp/vagrant-chef-1/solo.rb -j /tmp/vagrant-chef-1/dna.json -Fmin --why-run
Starting Chef Client, version 10.16.4
Compiling cookbooks .......done.
Converging 32 resources .........................U.......UUUUUS
System converged.

resources updated this run:
* mount[/mnt/nfsmount]
- mount 127.0.0.1:/srv/nfssrv to /mnt/nfsmount

* package[nmap]
- install version 5.21-1.1ubuntu1 of package nmap

* package[puppet]
- remove  package puppet
- purge  package puppet

* package[puppet-common]
- remove  package puppet-common
- purge  package puppet-common

chef client finished, 4 resources updated
{% endcodeblock %}  

blah blah

{% codeblock %}
root@dry-run-lies:~# chef-solo -c
/tmp/vagrant-chef-1/solo.rb -j /tmp/vagrant-chef-1/dna.json -Fmin 
Starting Chef Client, version 10.16.4
Compiling cookbooks .......done.
Converging 32 resources .........................U.......UU.U.U
System converged.

resources updated this run:
* mount[/mnt/nfsmount]
- mount 127.0.0.1:/srv/nfssrv to /mnt/nfsmount

* package[nmap]
- install version 5.21-1.1ubuntu1 of package nmap

* package[puppet]
- remove  package puppet

* package[puppet-common]
- remove  package puppet-common

* execute[hack the planet]
- execute /bin/echo HACKING THE PLANET

chef client finished, 5 resources updated
{% endcodeblock %}


{% codeblock lies lies and lies lang:bash %}
cf-agent -K -f /tmp/lies-1.cf -n
cf-agent -K -f /tmp/lies-1.cf
puppet apply /tmp/lies-1.pp --noop
puppet apply /tmp/lies-1.pp
chef-solo -c /tmp/vagrant-chef-1/solo.rb -j /tmp/vagrant-chef-1/dna.json -Fmin --why-run
chef-solo -c /tmp/vagrant-chef-1/solo.rb -j /tmp/vagrant-chef-1/dna.json -Fmin
{% endcodeblock %}

<h2> Light At The End of The Tunnel </h2>

We have documented
