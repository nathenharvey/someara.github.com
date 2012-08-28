---
layout: post
title: "Full stack Chef installers for EL5 and EL6"
date: 2011-06-16 12:24
comments: true
categories: 
---

I started at Opscode this week, just in time for the Velocity Conference in Santa Clara. The amount of brain power in the building right now is absolutely astounding, and I’m having a total blast. Manning the Opscode booth in the exhibition hall, a number attendees have stopped by inquiring about when we’re going to improve Centos and Redhat support. So far, this has largely been a community effort, and the experience tends to lag behind that of Ubuntu users.

One thing coming down the pipe are full stack installers for various distributions. A full stack installer provides everything you need to run Chef, above libc. Telling people about this has generated a lot of excitement and interest, so I went ahead and built them for you, live from the floor of Velocity.

Below are instructions for manual installation on EL5 and EL6, clones and derivatives. I’ll leave the creation of a custom knife bootstrap script as an exercise for the reader.

Enjoy!

-s

<h2> For EL5 users: </h2>
{% codeblock lang:sh %}
curl http://rpm.aegisco.com/aegisco/el5/aegisco.repo > /etc/yum.repos.d/aegisco.repo

yum clean all ; yum install gecode

wget http://yum.afistfulofservers.net/affs/fatty/el5/chef-full-0.10.0-1-centos-5.4-x86_64.sh

chmod +x ./chef-full-0.10.0-1-centos-5.4-x86_64.sh

sudo ./chef-full-0.10.0-1-centos-5.4-x86_64.sh

sudo /opt/opscode/setup.s
{% endcodeblock %}

<h2> For EL6 users: </h2>
{% codeblock lang:sh %}
rpm -Uvh http://mirror.pnl.gov/epel/6/x86_64/epel-release-6-5.noarch.rpm

rpm -Uvh http://yum.afistfulofservers.net/affs/centos/6/noarch/affs-release-el6-6-1.noarch.rpm

yum clean all ; yum -y install gecode

wget http://yum.afistfulofservers.net/affs/fatty/el6/chef-full-0.10.0-1-scientific-6.0-x86_64.sh

chmod +x ./chef-full-0.10.0-1-scientific-6.0-x86_64.sh

sudo ./chef-full-0.10.0-1-scientific-6.0-x86_64.sh 

sudo /opt/opscode/setup.sh 
{% endcodeblock %}

-s
