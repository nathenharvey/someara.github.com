---
layout: post
title: "Promises, Lies, and Dry-Run Mode"
date: 2012-12-21 4:20
comments: true
published: false
categories: [CFEngine, Puppet, Chef, Promise Theory, dry-run, noop]
---

<h2>Introduction</h2>

{% img right http://i.imgur.com/Ftyot.jpg 300 %}

"I need to know what this will do to my production system before I run
it." -- Ask a Systems Administrator why they want dry-run mode in a configuration
management tool, and this is the answer you'll get almost every single time.

Historically, we have been able to use dry-run as a risk mitigation
strategy before applying changes to machines. Dry-run is supposed to
report what a tool would do, so that the administrator can determine
if it is safe to run. Unfortunately, this only works if the reporting
can be trusted as accurate.

In this post, I'll show why modern configuration management tools
behave differently than the classical tool set, and why their dry-run
reporting is untrustworthy. While useful for development, it should
never be used in place of proper testing.

<h2> make -n </h2>

{% img left http://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Ford_assembly_line_-_1913.jpg/566px-Ford_assembly_line_-_1913.jpg 300 %}

Many tools in a sysadmin's belt have a dry-run mode. Common
utilities like make, rsync, rpm, and apt all have it.  Many databases
will let you simulate updates, and most disk utilities can show you
changes before making them.

The <a href=http://pubs.opengroup.org/onlinepubs/009695399/utilities/make.html">make</a>
utility is the earliest example I can find of an automation tool with
a dry-run option. Dry-run in `make -n` works by building a list of
commands, then printing instead of executing them. This is useful
because it can be trusted that `make` will always run the exact same
list in real-run mode. Rsync and others behave the same way.

Convergence based tools, however, don't build sets commands. They
build sets of convergent operators instead.

<h2> Convergent Operators, Sets and Sequence </h2>

{% img right http://i.imgur.com/x3uWr.png 300 %}

Convergent ensure state. They have a subject, and two sets of
instructions. The first set are tests that determine if the subject is
in the desired state, and the second set take corrective actions if
needed. Types are made by grouping common tests and actions. This
allows us to talk about things like users, groups, files, and services
abstractly.

CFEngine promise bundles, Puppet manifests, and Chef recipes are all
sets of these data structures. Putting them into a <a
href="http://en.wikipedia.org/wiki/Control_theory">feedback loop</a>
lets them cooperate over multiple runs, and enables the self-healing
behavior that is essential when dealing with large amounts of
complexity.

{% img left http://i.imgur.com/g4fcW.png 300 %}

During each run, *ordered sets* of convergent operators are applied
against the system. How order is determined varies from tool to tool,
but it is ordered none the less. Thinking at this level allows us to
effectively reason about the mechanics of dry-run.

<h2> Promises and Lies </h2>

{% img left http://i.imgur.com/rUk4d.png 350 %}
CFEngine 3 models <a href="http://en.wikipedia.org/wiki/Promise_theory">Promise Theory</a> 
as a way of doing systems management. Puppet and Chef do not model
promise theory explicitly, but it's still very useful to borrow its
vocabulary and and metaphors, and think about individual, autonomous
agents that promise to fix the things they're concerened with.

While writing Chef cookbooks, I imagine every resource statement I
make to be a little robot. Each time the chef-client runs, the robot's
left hand runs tests that interrogate package managers, inspect files,
and examine processes tables. The right hand moves only when it needs
to make corrections. Recipes unleash swarms of these little robotic
promise makers, each spinning around repairing machines.

{% img right http://i.imgur.com/uKQHY.png 300 %}

By personifying our configuration agents, it is easier to imagine them
lying to you. This raises a few questions. "Why would they lie to
me?", you might ask yourself. Under what circumstances are they likely
to lie? What exactly is a lie anyway?

It turns out that a <a
href="http://cfengine.com/markburgess/BookOfPromises.pdf">formal</a>
examination of promises does indeed include the notion of lies. Lies
can be outright deceptions, which are the lies of the
rarely-encountered Evil Robots. Lies can also be "non-deceptions",
which are the lies of occasionally-encountered Broken Robots. Most
often though, we experience lies from the often-encountered Merely
Mis-informed Robots. 

<h2> The Best You Can Do </h2>

{% img left http://i.imgur.com/oyf5b.png 300 %}

The best you can possibly hope to do in a dry-run mode is to build the operator
sequences, run all the tests, then report back what each agent would
do at that exact moment. The problem with this is, in real-run mode, the
*The system is changing between the tests*. Quite often, the results
of any given test will be affected by a preceeding action.

Configuration operations can have rather large side effects on machine
state. Sending signals to processes can result in files being changed
on disk. Mounting a disk changes an entire branch of a directory tree.
Packages can drop off one or a million different files and will often
execute arbitrary commands contained in 'pre' and 'post' scripts.
Installing the Postfix package on an Ubuntu system will not only write
the package contents to disk, but also create users and disable Exim
before automatically starting the service.
 
Throw in some resource notifications and random boolean checks and
things can get really interesting.

<h2> Enter the Robots </h2>

{% img right http://i.imgur.com/4ORuB.jpg 250 350 %}

To experiment with dry-run mode, I made a Chef cookbook that
configures a machine with initial conditions, then drops off CFEngine
and Puppet policies for dry-running.

We will see CFEngine, Puppet, and Chef running in their respective
dry-run modes, stating that they will take some actions, immediately
followed by real-run doing mode taking some others.

Three configuration management systems, each with conflicting
policies, wreaking havoc on a single machine sounds like a fun way to
spend the evening. Lets get weird.

If you already have Vagrant setup and would like to follow along, feel free.
Check out the cookbook
<a href='https://github.com/someara/dry-run-lies-cookbook'>here</a>. Otherwise,
you can just read the code examples by clicking on the provided links as we go.

Begin by checking out the dry-run cookbook from git, then configure a
Vagrant box with Chef.

{% codeblock %}
~/src/$ git clone https://github.com/someara/dry-run-lies-cookbook dry-run-lies
~/src/$ cd dry-run-lies
~/src/dry-run-lies$ bundle exec vagrant up
~/src/dry-run-lies$ bundle exec vagrant ssh
{% endcodeblock %}

<h2> CFEngine Example </h2>

After Chef has configured our machine, we can log into it, switch to
root, then run `cf-agent` with the `-n` flag to see what dry-run thinks
it will do to the system.

{% codeblock CFEngine dry-run  %}
root@dry-run-lies:~# cf-agent -K -f /tmp/lies-1.cf -n
-> Would execute script /bin/echo hello from bundle_one. puppet_bin_does_not_exist
 -> Need to execute /usr/bin/aptitude update...
{% endcodeblock %}

Here we see that there is a promise yet to be kept in bundle_one. Very
good. Let's remove `-n` and watch it do just that.

{% codeblock CFEngine real-run  %}
root@dry-run-lies:~# cf-agent -K -f /tmp/lies-1.cf 
Q: ".../bin/echo hello": hello from bundle_one.
puppet_bin_does_not_exist
I: Last 1 quoted lines were generated by promiser "/bin/echo hello from bundle_one. puppet_bin_does_not_exist"
Q: ".../bin/echo hello": hello from bundle_three. puppet_bin_exists
I: Last 1 quoted lines were generated by promiser "/bin/echo hello from bundle_three. puppet_bin_exists"
{% endcodeblock %}

Wait a sec... Whats all this bundle_three business? Did dry-run just
lie to me?

Let's look at a CFEngine code snippet and see what happened. You can view the entire `lies-1.cf` file <a
href="http://bit.ly/RVnV38">here</a>.

{% codeblock lies-1.cf lang:ruby %}
bundle agent bundle_one
{
classes:
  "puppet_bin_exists" expression =>
    returnszero("/usr/bin/test -e /usr/bin/puppet", "noshell");
      
commands:
  "/bin/echo"
    args => "hello from bundle_one.
    puppet_bin_does_not_exist.",
    ifvarclass => "!puppet_bin_exists";
}
            
bundle agent bundle_two
{
packages:
  "puppet"
    comment => "puppet",
    package_policy => "add",
    package_method => apt,
    classes => if_repaired("puppet_bin_exists");
}
           
bundle agent bundle_three
{
classes:
  "puppet_bin_exists" expression =>
    returnszero("/usr/bin/test -e /usr/bin/puppet", "noshell");

commands:
  "/bin/echo"
    args => "hello from bundle_three. puppet_bin_exists.",
    ifvarclass => "puppet_bin_exists";
}
{% endcodeblock %}

During the dry-run, the test in the bundle_three came back negative.
The actions in bundle_two had yet to change the state of the machine.
By the time it got to bundle_three in the real-run, the system had
changed enough to affect the outcome of the tests. 

<h2> Puppet Example </h2>

Let's give Puppet a spin. We can apply a local policy with the
`--noop` flag to see what Puppet thinks it will do.

{% codeblock Puppet dry-run  %}
root@dry-run-lies:~# puppet apply /tmp/lies-1.pp --noop
notice: /Stage[main]//Mount[/mnt/nfsmount]/ensure: current_value ghost, should be unmounted (noop)
notice: /Stage[main]//Mount[/mnt/nfsmount]: Would have triggered 'refresh' from 1 events
notice: Class[Main]: Would have triggered 'refresh' from 3 events
notice: Stage[main]: Would have triggered 'refresh' from 1 events
notice: Finished catalog run in 0.30 seconds
{% endcodeblock %}

One resource to fix. Excellent. A very small, safe change to the
system for sure. Let's remove the `--noop`.

{% codeblock Puppet real-run %}
root@dry-run-lies:~# puppet apply /tmp/lies-1.pp
notice: /Stage[main]//Mount[/mnt/nfsmount]/ensure: ensure changed 'ghost' to 'unmounted'
notice: /Stage[main]//Mount[/mnt/nfsmount]: Triggered 'refresh' from 1 events
notice: /Stage[main]//File[/mnt/nfsmount/file-1]/ensure: created
notice: /Stage[main]//File[/mnt/nfsmount/file-2]/ensure: created
notice: /Stage[main]//File[/mnt/nfsmount/file-3]/ensure: created
notice: Finished catalog run in 4.37 seconds
{% endcodeblock %}

"What the....?" Real-run created three files! Luckily it didn't do
anything too crazy on my Very Important Production System. Let's take
a look at some <a href="http://bit.ly/V87wom">code</a> and figure out
whats going on.

{% codeblock lies-1.pp lang:ruby %}
package { "nmap":
  ensure => absent;
}
  
mount { "/mnt/nfsmount":
  device => "127.0.0.1:/srv/nfssrv",
  fstype => "nfs",
  ensure  => "unmounted",
  options => "defaults",
  atboot  => true,
 }

file { "/mnt/nfsmount/file-1":
  ensure => present,
  require => Mount["/mnt/nfsmount"];
}

file { "/mnt/nfsmount/file-2":
  ensure => present,
  require => Mount["/mnt/nfsmount"];
}

file { "/mnt/nfsmount/file-3":
  ensure => present;
}
{% endcodeblock %}

Again, as with the CFEngine example, we have Puppet changing machine
state between tests. The Chef recipe that set up the initial machine
state exported and mounted an NFS share. Puppet unmounts the
directory, changing the view of the filesystem.

It should be noted that Puppet's resource graph model does nothing to
enable noop functionality, nor can it affect its accuracy. It used
only for the purposes of ordering and ensuring non-conflicting node
names within its model.

<h2> Chef Example </h2>

Finally, we'll run the original Chef policy that set up the machine
with the `-W` flag and see if it lies like the others.

{% codeblock %}
root@dry-run-lies:~# chef-solo -c /tmp/vagrant-chef-1/solo.rb -j /tmp/vagrant-chef-1/dna.json -Fmin --why-run
Starting Chef Client, version 10.16.4
Compiling cookbooks .......done.
Converging 32 resources .........................U.......UUUS
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

Seems reasonable. Let's remove the `--why-run` flag and do it for real.

{% codeblock %}
root@dry-run-lies:~# chef-solo -c /tmp/vagrant-chef-1/solo.rb -j /tmp/vagrant-chef-1/dna.json -Fmin 
Starting Chef Client, version 10.16.4
Compiling cookbooks .......done.
Converging 32 resources .........................U.......UUUU
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

Right. "HACKING THE PLANET" was definitely not in the dry-run output.
Let's go figure out what happened. See the entire Chef recipe <a href="http://bit.ly/WXr8k0">here</a>.

{% codeblock recipes/default.rb %}
# <snip>

package "nmap" do
  only_if "/usr/bin/test -f /usr/bin/puppet"
end
  
package "puppet" do
  action [:remove, :purge]
end
    
package "puppet-common" do
  action [:remove, :purge]
end
      
#
execute "hack the planet" do
  command "/bin/echo HACKING THE PLANET"
  only_if "/usr/bin/test -f /usr/bin/nmap"
end
{% endcodeblock %}

Previously, our CFEngine policy had installed Puppet on the machine.
Our Puppet policy ensured nmap was absent. Chef will install nmap,
but only if the Puppet binary is present in /usr/bin. 

In `--why-run` mode, the test for the `'package[nmap]'` resource
succeeds because of the pre-conditions set up by the CFEngine policy.
Had we not applied that policy, the `'execute[hack the planet]'`
resource would still not have fired because nothing had installed the
nmap package along the way. In real-run mode, it succeeds because Chef
changes the machine state between tests, but would have failed if we
had never ran the Puppet policy.

Yikes.

<h2> Okay, So What? </h2>

The robots were not trying to be deceptive. Each autonomous agent
told us what it honestly thought it should do in order to fix the
system. As far as they could see, everything was fine when we asked
them.

As we automate the world around us, it is important to know how the
systems we build fail. We are going to need to fix them, after all.
It is even more important to know when and how our machines lie to us.
The last thing we need is an army of lying robots wandering around.

Luckily, there are a number of techniques for testing and introducing
change that can be used to help ensure nothing bad happens.

<h2> Keeping the Machines Honest </h2>

{% img right http://farm8.staticflickr.com/7171/6809694353_7bdba3a38a_n.jpg 280 %}

In each case, the system converged to the prescribed policy, regardless of
whether dry-run got confused or not. If we can reproduce a system's
pre-conditions, we can simply real-run the policy and observe the behavior. Tests
can then be ran to ensure that the new machine state is doing what it's supposed to.

Ideally, test machines are modeled with CM policy from the ground up, starting
with Just Enough Operating System to allow them to run a CM tool. This ensures
all the details of the system have been captured and are reproducable.

Other ways of reproducing pre-conditons work, but come with the
burden of having to drag that knowledge around with you. Snapshots,
kickstart or bootstrap scripts, and even manual configuration will all
work so long as you can promise they're accurate.

There are some situations where reproducing a test system is impossible, or
modeling it from the ground up is not an option. In this case, a slow, careful,
incremental application of policy, aided by dry-run mode and human intuition is
the safest way to start to bring order to chaos. Chef's why-run mode
can help aide intuition by publishing assumptions about what's going
on. "I would start the service, assuming the software had been
previously installed" helps, but is no panacea. At some point you have
to blindly trust fate.

Finally, increasing the resolution of our policies will help the most in the long
term. The more robots, the better. Ensuring the contents of configuration files
is good. Making sure that they are only ones present in a conf.d directory is
better. As a community, we need to produce as much high quality, trusted, tested,
and reuseable policy as possible.

Good luck, and be careful out there.

-s
