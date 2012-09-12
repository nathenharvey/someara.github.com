---
layout: post
title: "Configuration Management Strategies"
date: 2011-07-27 12:32
comments: true
categories: 
---
I just watched the “To Package or Not to Package” video from DevOps days Mountain View. The discussion was great, and there were some moments of hilarity. If you haven’t watched it yet, check it out <a href=http://goo.gl/KdDyf> here </a>

Stephen Nelson Smith, I salute you, sir.

I’m quite firmly in the “Let your CM tool handle your config files” camp. To explain why, I think it’s worth briefly examining the evolution of configuration management strategies.

In order to keep this post as vague and heady as possible, no distinction between “system” and “application” configurations shall be made.

<h2> What is a configuration file? </h2>
Configuration files are text files that control the behavior of programs on a machine. That’s it. They are usually read once, when a program is started from a prompt or init script. A process restart or HUP is typically required for changes to take effect.

<h2> What is configuration management, really? </h2>
When thinking about configuration management, especially across multiple machines, it is easy to equate the task to file management. Configs do live in files, after all. Packages are remarkably good at file management, so it’s natural to want to use them.

However, the task goes well beyond that.

An important attribute of an effective management strategy, config or otherwise, is that it reduces the amount of complexity (aka work) that humans need to deal with. But what is the work that we’re trying to avoid?

<h2> Dependency Analysis and Runtime Configuration </h2>
{% img right http://farm8.staticflickr.com/7239/7389252518_7c27eb1472_n.jpg %}
Two tasks that systems administrators concern themselves with doing are dependency analysis and runtime configuration. 

Within the context of a single machine, dependency analysis usually concerns software installation. Binaries depend on libraries and scripts depend on binaries. When building things from source, headers and compilers are needed. Keeping the details of all this straight is no small task. Packages capture these relationships in their metadata, the construction of which is painstaking and manual. Modern linux distributions can be described as collections of packages and the metadata that binds them. Go out and hug a package maintainer today.

Within the context of infrastructure architecture, dependency analysis involves stringing together layers of services and making individual software components act in concert. A typical web application might depend on database, caching, and email relay services being available on a network. A VPN or WiFi service might rely on PKI, Radius, LDAP and Kerberos services.

Runtime configuration is the process of taking all the details gathered from dependency analysis and encoding them into the system. Appropriate software needs to be installed, configuration files need to be populated, and kernels need to be tuned. Processes need to be started, and of course, it should all still work after a reboot.

<h2> Manual Configuration </h2>
{% img left http://farm5.staticflickr.com/4139/4805330106_926dfc074f_m.jpg %}

Once upon a time, all systems were configured manually. This strategy is the easiest to understand, but the hardest one to execute. It typically happens in development and small production environments where configuration details are small enough to fit into a wiki or spreadsheet. As a network’s size and scope increases, management efforts became massive, time consuming, and prone to human error. Details end up in the heads of a few key people and reproducibility is abysmal. This is obviously unsustainable.


<h2> Scripting </h2>
{% img right http://farm4.staticflickr.com/3101/2428706650_d1fc862fdc_m.jpg %}
The natural progression away from manual configuration was custom scripting. Scripting reduced management complexity by automating things using languages like Bash and Perl. Tutorials and documentation instruction like “add the following line to your /etc/sshd_config” were turned into automated scripts that grepped, sed’ed, appended, and clobbered. These scripts were typically very brittle and would only produce desired outcome after their first run.

<h2> File Distribution </h2>
{% img left http://farm5.staticflickr.com/4068/4317655660_61a60f6576_m.jpg %}
File distribution was the next logical tactic. In this scheme, master copies of important configuration files are kept in a centralized location and distributed to machines. Distribution is handled in various ways. RDIST, NFS mounts, scp-on-a-for-loop, and rsync pulls are all popular methods.

This is nice for a lot of reasons. Centralization enables version control and reduces the time it takes to make changes across large groups of hosts. Like scripting, file distribution lowers the chance of human error by automating repetitive tasks.

However, these methods have their drawbacks. NFS mounts introduce single points of failure and brittleness. Push based methods miss hosts that happen to be down for maintenance. Pulling via rsync on a cron is better, but lacks the ability to notify services when files change.

Managing configs with packages falls into this category, and is attractive for a number of reasons. Packages can be written to take actions in their post-install sections, creating a way to restart services. It’s also pretty handy to be able to query package managers to see installed versions. However, you still need a way to manage config content, as well as initiate their installation in the first place.

<h2> Declarative Syntax </h2>
{% img right http://farm4.staticflickr.com/3144/2591838509_1fdbc46db7_m.jpg %}
In this scheme, autonomous agents run on hosts under management. The word autonomous is important, because it stresses that the <strong>machines manage themselves</strong> by interpreting policy remotely set by administrators. The policy could state any number of things about installed software and configuration files.

Policy written as code is run through an agent, letting the manipulation of packages, configuration files, and services all be handled by the same process. Brittle scripts behaving badly are eliminated by exploiting the idempotent nature of a declarative interface.

When first encountered, this is often perceived as overly complex and confusing by some administrators. I believe this is because they have equated the task of configuration management to file management for such a long time. After the initial learning curve and picking up some tools, management is dramatically simplified by allowing administrators to spend time focusing on policy definition rather than implementation.

<h2> Configuration File Content Management </h2>
This is where things get interesting. We have programs under our command running on every node in an infrastructure, so what should we make them to do concerning configuration files?

“Copy this file from its distribution point” is very common, since it allows for versioning of configuration files. Packaging configs also accomplishes this, and lets you make declarations about dependency. But how are the contents of the files determined?

It’s actually possible to do this by hand. Information can be gathered from wikis, spreadsheets, grey matter, and stick-it notes. Configuration files can then be assembled by engineers, distributed, and manually modified as an infrastructure changes.

File generation is a much better idea. Information about the nodes in an infrastructure can be encoded into a database, then fed into templates by small utility programs that handle various aspects of dependency analysis. When a change is made, such as adding or removing a node from a cluster, configurations concerning themselves with that cluster can be updated with ease.

<h2> Local Configuration Generation </h2>
{% img left http://farm5.staticflickr.com/4140/4753170413_f3488f6586_m.jpg %}
The logic that generates configuration files has to be executed somewhere. This is often done on the machine responsible for hosting the file distribution. A better place is directly on the nodes that need the configurations. This eliminates the need for distribution entirely.

Modifications to the node database now end up in all the correct places during the next agent run. Packaging the configs is completely unnecessary, since they don’t need to be moved from anywhere. Management complexity is reduced by eliminating the task entirely. Instead of worrying about file versioning, all that needs to be ensured is code correctness and the accuracy of the database.

Don’t edit config files. Instead, edit the truth.

-s

