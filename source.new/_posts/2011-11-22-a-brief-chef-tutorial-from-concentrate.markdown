---
layout: post
title: "A Brief Chef Tutorial (from concentrate)"
date: 2011-03-16 15:18
comments: true
categories: Chef
---

<h2> Overview </h2> 

Chef is configuration management platform written in Ruby. Configuration management is a large topic that most systems administrators and IT management are just now starting to gain experience with. Historically, infrastructures have been maintained either by hand, with structured scripting, by imagine cloning, or a combination of those. Chef’s usage model rejects the idea of cloning and maintaining “golden images”. Instead, the idea is to start with an embryonic image and grow it into it’s desired state. This works much better as infrastructure complexity increases, and eliminates the problem of image sprawl. The convergent nature of the tool allows you to change the infrastructure over time without much fuss. Chef allows you to express your infrastructure as code, which lets you store it in version control.

“A Can of Condensed Chef Documentation” is available <a href=/post/2011/03/15/a-can-of-condensed-chef-documentation/> here </a>

<h2> Prerequisites </h2>

<h3> Git </h3>

Actually you can use any SCM, but git is the most widely adopted in the Chef community. All Chef Git repos begin their lives as clones of the Opscode chef-repo, found here: https://github.com/opscode/chef-repo There is a nice overview of the repo structure (cookbooks, databags, roles, etc) in the README.

<h3> chef-server up and running at a known IP or FQDN. </h3>
This is easily installed from packages by following the instructions on the opscode wiki. The process amounts to “add a package repository, install the packages, and turn it on” Alternatively, you could use the Opscode Platform and go dancing with space robots.

<h3> Knife installed on your local system </h3>

{% codeblock lang:sh %}
gem install chef net-ssh net-ssh-multi fog highline
{% endcodeblock %}

<h3> Chef git repo checked out on local file system </h3>

{% codeblock lang:sh %}
git clone https://github.com/opscode/chef-repo
{% endcodeblock %}

<h3> Client certificate creation </h3>
A “client” in chef parlance is an SSL certificate used to access the chef-server API. If the client’s CN name is marked “admin” in chef-server, the client can perform restricted operations such as creating and deleting nodes. This is the kind of client needed by knife to manipulate the infrastructure, and normally correspond to actual human being, but by no means has to. Nodes have non-admin client certificates, and can only manipulate their own node objects. To create a client certificate, you’ll need to log into the chef-server webui, click on “clients”, think of a name for it (I use someara), and paste the displayed private key into a local file.

<strong> Copy the validation key </strong><br>
The validation key is a special key that is shared by all freshly bootstrapped nodes. It has the ability to create new client certificates and nodes objects through the API.

{% codeblock lang:sh %}
scp root@chefserver:/etc/chef/validation.pem .chef/
{% endcodeblock %}

<h3> Edit configuration files </h3>

For more details on this section, please visit http://wiki.opscode.com/display/chef/Chef+Configuration+Settings

.chef/client.rb - This file is copied onto the nodes that are bootstrapped with knife, and needs to be configured to point to the IP or FQDN of your chef server

example
{% codeblock $ vim client.rb %}
log_level          :info
log_location       STDOUT
ssl_verify_mode    :verify_none
chef_server_url    "http://y.t.b.d:4000"
file_cache_path    "/var/cache/chef"
pid_file           "/var/run/chef/client.pid"
cache_options({ :path => "/var/cache/chef/checksums", :skip_expires => true})
signing_ca_user "chef"
Mixlib::Log::Formatter.show_time = true
validation_client_name "chef-validator"
validation_key         "/etc/chef/validation.pem"
client_key             "/etc/chef/client.pem"
{% endcodeblock %}

.chef/knife.rb - This file also needs to be configured to point to your chef-server, and also to the client private key that was created earlier.

example
{% codeblock $ vim knife.rb %}
log_level            :info
log_location         STDOUT
node_name           'knife'
cache_type          'BasicFile'
cache_options( :path => "~/.chef/checksums" )
client_key       '~/.chef/knife.key.pem'

cookbook_path       [ "~/mychefrepo/cookbooks" ]
cookbook_copyright "example org"
cookbook_email     "cookbooks@example.net"
cookbook_license   "apachev2"

chef_server_url    "http://y.t.b.d:4000"

validation_key      "~/.chef/validation.pem"

# rackspacecloud
knife[:rackspace_api_key] = '00000000000000000000000000000000'
knife[:rackspace_username] = 'rackspace'

# slicehost
knife[:slicehost_password] = '0000000000000000000000000000000000000000000000000000000000000000'

# AFFS aws
knife[:aws_access_key_id]     = '00000000000000000000'
knife[:aws_secret_access_key] = '0000000000000000000000000000000000000000'

#knife[:region]  = "us-east-1"
#knife[:availability_zone] = "us-west-1b"
#knife[:ssh_user] = "root"
#knife[:flavor] = "t1.micro"
#knife[:image] = "ami-10a55279"
#knife[:use_sudo]  = "false"
#knife[:distro] = "affs-fc13"
{% endcodeblock %}

<h2> Role, recipes, and run lists</h2>
As mentioned earlier, run lists are made up from role trees. Here is an example of how you would create a demo server with a correct clock, managed users, and metrics and monitoring capabilities. In this example, six recipes are executed per run, and an unknown number of resources are managed. (To figure that out, you’d have to read the recipes)

{% codeblock %}
role[demo]
  role[base]                   <---- nested role
  recipe[foo::server]
  recipe[foo::muninplugin]
       
role[base]
  recipe[ntp]
  recipe[localusers::common]
  recipe[munin::client]
  recipe[nagios::client]

expanded run list
  recipe[ntp]
    recipe[localusers::common]
    recipe[munin::client]
    recipe[nagios::client]
    recipe[foo::server]
    recipe[foo::muninplugin]
{% endcodeblock %}

That’s quite a bit of cooking for a beginner tutorial, so we’re just going to focus on a single node running an NTP client for now. Roles can be written either as .rb files or .json files. I prefer to use the .rb format because they’re easier to read and write. Some people prefer to deal with the JSON formatted version directly, since thats the way they’re dumped with knife. At the end of the day, it doesn’t really matter, so do which ever makes you happy.

<h3> Step One : Creating a demo role file </h3>
{% codeblock $ vim roles/demo.rb %}
name "demo"
description "demo role"
run_list [
    "recipe[ntp]"
    ]
{% endcodeblock %}

<h3> Step Two : Installing the role on chef-server </h3>
{% codeblock lang:sh %}
$ knife role from file roles/demo.rb
{% endcodeblock %}

<h2> Writing Recipes </h2>
<h3> Hello, NTP! </h3>
A machine’s NTP client is simple to install and configure. Every systems administrator is already familiar with it, which makes it a great example.

Most software available as a native package in a given linux distribution can be managed with a “package, template, service” design pattern. 

Each of those words refers to a Chef resource, which we pass arguments to.

<h3> Step One : Creating an ntp cookbook </h3>
{% codeblock lang:sh %}
$ knife cookbook create ntp
{% endcodeblock %}
This creates a directory structure for the ntp cookbook. You can check it out with ls:
{% codeblock lang:sh %}
$ ls -la cookbooks/ntp/
total 24
drwxr-xr-x  13 someara  staff   442 Mar 14 17:56 .
drwxr-xr-x  36 someara  staff  1224 Mar 15 19:39 ..
-rw-r--r--   1 someara  staff    58 Mar 14 17:56 README.rdoc
drwxr-xr-x   2 someara  staff    68 Mar 14 17:56 attributes
drwxr-xr-x   2 someara  staff    68 Mar 14 17:56 definitions
drwxr-xr-x   3 someara  staff   102 Mar 14 17:56 files
drwxr-xr-x   2 someara  staff    68 Mar 14 17:56 libraries
-rw-r--r--   1 someara  staff   259 Mar 14 17:56 metadata.rb
drwxr-xr-x   2 someara  staff    68 Mar 14 17:56 providers
drwxr-xr-x   4 someara  staff   136 Mar 14 17:56 recipes
drwxr-xr-x   2 someara  staff    68 Mar 14 17:56 resources
drwxr-xr-x   3 someara  staff   102 Mar 14 17:56 templates
{% endcodeblock %}

<h3> Step Two : Deciding what to name the recipe </h3>
Recipe names are related to cookbook structure. Putting recipe[foo::bar] in a node’s run list results in cookbooks/foo/recipes/bar.rb being downloaded from chef-server and executed. 

There is a special recipe in every cookbook called default.rb. It is executed by every recipe in the cookbook. Specifying recipe[foo::bar] actually results in cookbooks/foo/recipes/default.rb, as well as cookbooks/foo/recipes/bar.rb being executed.

Default.rb is a good place to put common stuff when writing cookbooks with multiple recipes, but we’re going to keep it simple and just use default.rb for everything.

<h3> Step Three : Creating a recipe </h3>
This is where all the fun stuff happens. When using resources, you’re writing things in a declarative fashion. Declarative means you can concentrate on the WHAT without having to worry about the HOW. Chef will take care of that for you with something called a resource provider. When installing a package, it will check to see what your operating system is and use the appropriate methodology. For example, on Debian based systems, it will use apt-get, and on Redhat based systems, it will use yum.

{% codeblock $ vim cookbooks/ntp/recipes/default.rb %}
package "ntp" do
  action [:install]
end

template "/etc/ntp.conf" do
  source "ntp.conf.erb"
  variables( :ntp_server => "time.nist.gov" )
end

service "ntpd" do
  action[:enable,:start]
end
{% endcodeblock %}

Chef recipes are evaluated top down (like a normal ruby program), with each resource being ran in the order it appears. Order is important. In the above example, if we were to reverse the order of those three resources, it would first fail to start the service (as the software is not installed yet), then write the configuration file, then finally clobber the file it just wrote by installing the package.

<h3> Step Four : Creating the ntp.conf.erb template </h3>
{% codeblock $ vim cookbooks/ntp/templates/default/ntp.conf.erb %}

# generated by Chef.
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict -6 ::1
server <%= @ntp_server %>
server  127.127.1.0     # local clock
driftfile /var/lib/ntp/drift
keys /etc/ntp/keys
{% endcodeblock %}

<h3> Step Five : uploading the cookbook to chef-server </h3>
{% codeblock lang:sh %}
$ knife cookbook upload ntp
{% endcodeblock %}

<h2> Bootstraping nodes </h2>
The chef-client needs to somehow get itself installed and running on managed nodes. This process is known as bootstrapping and is accomplished with shell scripting. The method of bootstrap will vary depending on how you go about provisioning your server, and the script will depend on the platform.

<h3> Clouds </h3>
Cloud providers like AWS and Rackspace will let you make an API request, then return the IP of your compute resource.

{% codeblock lang:sh %}
$ knife ec2 server create "role[demo]" -N "demo.example.net" -i ami-3e02f257
{% endcodeblock %}

In this example, knife uses the ruby fog library to talk to ec2 and request a server with an argument of the desired AMI. Knife then uses net-ssh-multi to ssh into the machine and execute a bootstrapping script. There are a number of other arguments that can be passed to knife, such as ec2 region, machine size, what ssh key to use. You can read all about them on the Opscode wiki. 

<h3> Meatclouds </h3>
If your method of provisioning servers is “ask your VMware administrator” or “fill out these forms”, then you’ll probably bootstrap via an IP address.

{% codeblock lang:sh %}
knife boostrap 10.0.0.5 -x root -N demo.example.net -r 'role[demo]' -d pp-centos5
{% endcodeblock %}

<h3> Cobbler / FAI / pxe_dust / Jumpstart / etc </h3>
In these provisioning scenarios, you can skip knife completely and put the contents of a bootstrap script kickstart or equivalent.

<h2> Customizing the bootstrap </h2>
By default (with no arguments), Chef attempts a gem based installation meant to work on Ubuntu. If you’re not using Ubuntu, or are uncomfortable installing gems directly from rubygems.org, you’ll have to change the script to suite your taste. It works by specifying a template name with the -d flag, SSH’ing into the machine and running the rendered script. When using knife to SSH, make sure you have the correct key loaded into your ssh-agent.

<h3> Example </h3>
{% codeblock lang:sh %}
knife boostrap 10.0.0.5 -x root -N demo.example.net -r ‘role[demo]’ -d my-centos5
{% endcodeblock %}
ends up running this

{% codeblock lang:sh %}
ssh root@10.0.0.179 bash -c ‘<contents of rendered .chef/bootstrap/my-centos5.erb template>’
{% endcodeblock %}

What I do in my boot scripts:

* Correctly set the hostname to value of -N argument. (By correctly, I mean that `hostname -f` has to work properly)
* Configure the package repositories
* Install Chef. I like packages using the native package manager
* Copy the validation key
* Write /etc/chef/client.rb (points to server)
* Write a json file with the contents of the -r argument
* chef-client -j bootstrap.json

After the script is ran, chef-client does the following

* Ohai!
* Client registration: SSL CN is FQDN from ohai 
* Node creation: Node name is also FQDN from ohai, run lists are from JSON
* Expands run list
* Downloads needed cookbooks
* Starts executing recipes

There is an example of a custom bootstrap script <a href=https://github.com/someara/affs-blog/blob/v1/.chef/bootstrap/affs-fc13.erb> here </a>

At this point, you should have an ntp client installed, configured, and running.

(It’s actually a little bit more complicated than that. For more information about chef-client runs, see <a href=http://wiki.opscode.com/display/chef/Anatomy+of+a+Chef+Run> http://wiki.opscode.com/display/chef/Anatomy+of+a+Chef+Run </a>)

<h2> Databag Driven Recipes </h2>
Data driven infrastructures are all the rage these days. This allows you to do things like change the NTP server all your nodes use by editing a single JSON value in chef-server. You can get really creative with this, so let your imagination run wild.

<h3> Step One : Create an ntp data bag </h3>

{% codeblock lang:sh %}
$ knife data bag create ntp
$ mkdir -p data_bags/ntp
$ vim data_bags/ntp/default_server.json
{
    "id" : "default_server",
      "value" : "us.pool.ntp.org"
}
{% endcodeblock %}

<h3> Step Two : Upload data bag to chef-server </h3>
{% codeblock lang:sh %}
$ knife data bag from file ntp data_bags/ntp/default_server.json
{% endcodeblock %}

<h3> Step Three : Modify the recipe to take advantage of it </h3>
{% codeblock ntp/recipes/default.rb %}
package "ntp" do
  action [:install]
end

ntp_server = data_bag_item('ntp', 'default_server')

template "/etc/ntp.conf" do
  source "ntp.conf.erb"
  variables( :ntp_server => ntp_server['value'] )
end

service "ntpd" do
  action[:enable,:start]
end
{% endcodeblock %}

You can also access data bag data through the search() interface, which you can read about on the opscode wiki.

<h3>Step Four : uploading the cookbook to chef-server</h3>
{% codeblock lang:sh %}
$ knife cookbook upload ntp
{% endcodeblock %}

<h2> Understanding Idempotence and Convergence </h2>
We’re not quite done yet. Let’s SSH into our shiny new NTP enabled machine and go poking about.

{% codeblock lang:sh %}
$ grep server /etc/ntp.conf | head -n 1
server time.nist.gov
{% endcodeblock %}

Wait a sec, isn’t that supposed to be “us.pool.ntp.org”? Not yet. We haven’t enabled our convergence mechanism yet! If we manually run chef-client on the node, we will indeed see that the file has changed.

<h3> Convergence </h3>
{% codeblock lang:sh %}
# chef-client
$ grep server /etc/ntp.conf | head -n 1
us.pool.ntp.org
{% endcodeblock %}

That file just converged into the correct state. Lets edit the file again, this time filling it with complete garbage.

{% codeblock lang:sh %}
# dd if=/dev/urandom of=/etc/ntp.conf bs=128 count=1
# chef-client
$ grep server /etc/ntp.conf | head -n 1
us.pool.ntp.org
{% endcodeblock %}

Again, the file converged into the correct state. Awesome. Running chef-client by hand on a large cluster of nodes would be a real pain, so it makes sense to set it up automatically. Indeed, often found in a “role[base]” is a “recipe[chef-client]” that configures it to run as a daemon, or from a cron.

<h3> Idempotence </h3>
It is safe to run the recipes on the nodes time and time again because resources are written to be idempotent. You may remember from math class that a function f is idempotent if, for all values of x, f(f(x))=f(x). That means you can run a function over a resource a bajillion times and it will behave as if it was only done once.

This is implemented under the hood as “If it ain’t broke, don’t fix it.” In a file resource, checksums are calculated and compared. In a package resource, the rpm or dpkg databases are consulted to see if the package is installed. The effect of this is that most chef-client runs do absolutely nothing to resources. That is, until you change the function by altering the inputs to the resource providers.

<h2> Notifications and Subscriptions </h2>
Further examination reveals that the ntpd service is still talking to “time.nist.gov”. This is because during the chef-client run, the resource named “ntpd” ran it’s idempotency check, and found that it was, in fact, running. It therefore did nothing. It we want ntpd to restart when the contents /etc/ntp.conf are altered, we have to modify our recipe to set up that relation.

{% codeblock ntp/recipes/default.rb %}
package "ntp" do
  action [:install]
end

ntp_server = data_bag_item('ntp', 'default_server')

template "/etc/ntp.conf" do
  source "ntp.conf.erb"
  variables( :ntp_server => ntp_server['value'] )
  notifies :restart, "service[ntpd]"
end

service "ntpd" do
  action[:enable,:start]
end
{% endcodeblock %}

Alternatively, we could have set up the “service[ntpd]” resource to subscribe to the “template[/etc/ntp.conf]” resource.

Upload the modified ntp cookbook to chef-server and re-run the client on your demo server to check your work.
{% codeblock lang:sh %}
# chef-client
$ lsof -i | grep ntp | grep pool
ntpd       5673    ntp   19u  IPv4 12481380      0t0  UDP us.pool.ntp.org:ntp}
{% endcodeblock %}
Winning.

<h2> Bulk Loading data into chef-server </h2>
To save yourself from writing crazy for loops on command line like

{% codeblock lang:sh %}
for i in `ls cookbooks` ; do knife cookbook upload $i ; done
{% endcodeblock %}

Or even worse,

{% codeblock lang:sh %}
for i in `ls data_bags` ; do 
  for j in `ls data_bags/$i/`; do
    knife data bag create $i
    knife data bag from file $i data_bags/$i/$j ;
  done ;
done
{% endcodeblock %}

... somebody was nice enough to write some rake tasks. List them with rake -T, and then install your repo in chef-server with "rake install"

<h2> Viewing your Infrastructure </h2>
There are two ways to view your infrastructure. The first is through the management console, and the other is from knife. Here is a list of handy commands to get you started.

{% codeblock lang:sh %}
knife node list
knife node show foo.example.net
knife data bag list
knife data bag show whatever
{% endcodeblock %}

<h2> Deleting Clients, Nodes, and Machines </h2>
Remember that nodes, their client certificates, and the machines they’re associated with are three separate entities.

<h3> Nodes </h3>
{% codeblock lang:sh %}
$ knife node delete foo.example.net
{% endcodeblock %}

This just deletes the node object from chef-server. The next time the machine runs chef-client, the node object will be recreated in chef-server. This node object will have an empty run list what will have to be repopulated before chef-client actually does anything.

<h3> Clients </h3>
{% codeblock lang:sh %}
$ knife client delete foo.example.net
{% endcodeblock %}

This deletes a node object’s associated public key from chef-server. The next time the machine runs chef-client, it will get a permission denied error. If this is done on accident, ssh into the machine, delete it’s client key at /etc/chef/client.pem and re-run chef-client. 

<h3> Machines </h3>
Deleting a machine will be specific to how it was provisioned. On AWS, it would look like “knife ec2 server delete i-DEAFBEEF”. On a VMware cluster, it could be by clicking buttons in a GUI. I once deleted a hardware machine by throwing it off a balcony. YMMV.

<h2> nodes.sh </h2>
I like to keep a special directory called “infrastructures” that contain sub-directories and nodes.sh files. A nodes.sh contains a list of knife commands that can be thought of as the highest level view of the infrastructure. for example:

{% codeblock lang:sh %}
knife bootstrap 10.0.0.10 -r 'role[database]'  -N database-01.example.net -x root -d my-fedora13
knife bootstrap 10.0.0.11 -r 'role[database]' -N database-02.example.net -x root -d my-fedora13
knife bootstrap 10.0.0.14 -r 'role[redis]' -N redis01.example.net -x root -d my-fedora13
knife bootstrap 10.0.0.15 -r 'role[redis]' -N redis02.example.net -x root -d my-fedora13
knife bootstrap 10.0.0.14 -r 'role[files]' -N files01.example.net -x root -d my-fedora13
knife bootstrap 10.0.0.15 -r 'role[files]' -N files02.example.net -x root -d my-fedora13
knife bootstrap 10.0.0.16 -r 'role[appdemo]' -N appdemo01.example.net -x root -d my-fedora13
knife bootstrap 10.0.0.17 -r 'role[appdemo]' -N appdemo02.example.net -x root -d my-fedora13
{% endcodeblock %}

This file can eventually be used to bring up entire infrastructures, but during development, lines are typically pasted into a terminal individually.

This is as close as I’ve gotten to replacing myself with a very small shell script so far. Many a sysadmin has been pursuing this for a long time now. It is here. The journey has just begun.

-s

