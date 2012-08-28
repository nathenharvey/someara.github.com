---
layout: page
title: "CFChefiPuppetEngine setup"
date: 2011-12-18 17:06
comments: true
sharing: true
footer: true
---

<h2> Set up Chef </h2>
<h3> Creating a Chef workstation</h3>

Follow the instructions <a href=http://wiki.opscode.com/display/chef/Workstation+Setup target="_blank">here</a> to set up a Chef workstation so you can follow along. Mine is a Macbook Pro with RVM, ruby-1.9.2, and Chef installed from rubygems.

<h3> Create a new Hosted Chef organization or bring up a fresh open source chef-server instance. </h3>

Follow the instructions <a href=http://wiki.opscode.com/display/chef/Installation target="_blank">here</a> to set up a Chef server so you can follow along.

<h3> Clone the affs-blog git repo </h3>

{% codeblock lang:sh %}
git clone https://github.com/someara/affs-blog
git checkout 0.3.2
{% endcodeblock %}

<h3> Configure the affs-blog repo to point to the chef-server </h3>

Download you knife.rb and validation.pem from Hosted Chef interface, or set up your open-source Chef server accordingly. See the knife configuraiton page <a href=http://wiki.opscode.com/display/chef/Knife#Knife-Knifeconfiguration target="_blank">here</a> for help with knife

<h3> Upload the affs-blog repo contents to your Chef server <h3>
{% codeblock lang:sh %}
cd affs-blog
rake install
{% endcodeblock %}

<h3> Verify your Chef infrastructure </h3>

{% codeblock lang:sh %}
knife node list # should be empty
knife node list # show your client cert
knife cookbook list # should list the contents of the affs-blog/cookbooks directory
{% endcodeblock %}

<h2> Provision three Centos6 machines </h2>

The code that powers this article was written against 3 VMWare Fusion Centos 6 base installs with passwordless SSH to root setup. I stuck their IPs in my local /etc/hosts so I could address them as `centos6-1`, `centos6-2`, and `centos6-3` respectively. Bare metal installs should work too.<br>
<br>
WARNING: AWS or Rackspace based instances will NOT work when following along, since the code would grab the wrong IP off the network interfaces.<br>
<br>
Protip: Since Centos6 comes with SELinux enabled by default, don't forget to restorecon -R /root after you write your authorized_keys file.<br>
<br>

