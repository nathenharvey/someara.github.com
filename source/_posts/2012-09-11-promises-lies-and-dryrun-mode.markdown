---
layout: post
title: "Promises, Lies, and Dry-Run Mode"
date: 2012-09-11 16:40
comments: true
published: false
categories: [CFEngine, Puppet, Chef]
---

<h2>Introduction</h2>

{% img right http://i.imgur.com/Ftyot.jpg 300 %}

"I need to know what this will do to my production system before I run
it." -- Ask 100 people why they want a dry-run mode in a configuration
management tool, and this is the answer you'll get almost every single time.

On the surface, this seems like a perfectly reasonable feature. After
all, many tools in a sysadmin's tool belt have a dry-run. Rsync, 
make, rpm, apt, svn, and git all have it. Databases will let you
simulate updates, and most disk utilities will show you changes before actually making them.

People have been doing this for years! It should be easy to get an
list of what actions a tool will take! As a matter of fact, NOT performing a dry-run on a system is just plain irresponsible!

Not exactly. 

In this post, I aim to break down how  configuration management tools like CFEngine, Puppet, or Chef are very different
animals than the classical tool set, and why dry-run mode is less than
completely trustworthy. I'll provide real world examples of dry-run saying one thing, and a real-run doing another. 
The takeaway here should be that dry-run, while super useful for development, should never be used in place of proper testing.

<h2> make -n </h2>

{% img left http://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Ford_assembly_line_-_1913.jpg/566px-Ford_assembly_line_-_1913.jpg 300 %}

The <a href=http://pubs.opengroup.org/onlinepubs/009695399/utilities/make.html">make</a>
utility is the earliest example I can find of an automation tool with
a dry-run option. Make reads a descriptor file, then typically
generates highly complex sets of commands to build sofware. It calls
compilers, assemblers, linkers, check timestamps, and copy files around the filesystem. 

Dry-run mode in make works by building a procedure of functions to be
executed, and simply printing them instead of running them. This is
super useful because make will actually execute all the things it says
it will in a real-run mode. Every. Single. Time. 

Likewise, rsync's dry-run mode behaves the same way. Rsync will print
a list of files it needs to copy, and, assuming no changes between
dry-run and real-run, do the exact same thing at real-run time. The procedural nature of these tools is what enables this to work so
well. Build a list of raw commands to execute, and print them. Build the same list, and execute them instead. Easy.

Configuration management tools, however, don't build lists of raw
commands. They build lists of convergent operators instead. Convergent
operators, it turns out, are a little trickier to deal with.

<h2> Convergent Operators </h2>

{% img right http://i.imgur.com/x3uWr.png 300 %}

In our last installment, blah, blah, blah. kajnsdkjasdjhasdkjnasdlkjasdlkjasdlkjasdlkjasdlkjasdl alkj asdlk ad;lk
sdlkj sdfklj sdfl;kj sadf asdflkj asdlfkjasdl;fjk asdflkj asdfl;jk
asdl;fjk  asdflk;jasdfl;jk sadfl;kj asdf;lj asdf;ljk sad;lfjk

kajnsdkjasdjhasdkjnasdlkjasdlkjasdlkjasdlkjasdlkjasdl alkj asdlk ad;lk
sdlkj sdfklj sdfl;kj sadf asdflkj asdlfkjasdl;fjk asdflkj asdfl;jk
asdl;fjk  asdflk;jasdfl;jk sadfl;kj asdf;lj asdf;ljk sad;lfjk as
sdfl;kjsdf;lkjasd f;ljsa dfl;kj asdf;lkj sadflkj asdf asdfjkl;asdf;lkj
asdf;lkj asdf;ljk asdf;ljk asdf asd;fjasdfjk asdf;ljk sadf;ljk
asdf;lkj sadf;lkj as;ldfjkasdf;lkj asdf;ljk asdf;lj asdf;ljasd
asdfjasdf;lkjasdf;lkj asdf;lasdf;ljk asdfl;jk asdfl;jk asdf;lj
asdf;lkj asdf;lkj asdf;lkj asdf;lkj asdf;lkj sadf


Desired State -> Actual State<br>
Test for a condition -> Take corrective action<br>

Check out Usenix papers.

<h2> Promises and Lies </h2>
{% img left http://i.imgur.com/rUk4d.png 350 %}
Mark Burgess, CFEngine 3.
Promises as a way of thinking about convergent operators.
Lego men yo.
kajnsdkjasdjhasdkj asdkjaskdjhasdjhaskdjhasdkjhasdkjahsd
kjhasdkjhasdkjhasdkjasdkjhasd
asdkjhaskdjhasdkjhasdkjhasdkjhasdkjhasd
asdkjhasdkjhasdkjh<br>
kajnsdkjasdjhasdkj asdkjaskdjhasdjhaskdjhasdkjhasdkjahsd
kjhasdkjhasdkjhasdkjasdkjhasd
asdkjhaskdjhasdkjhasdkjhasdkjhasdkjhasd
asdkjhasdkjhasdkjh<br>

<h2> Sets of Sequences </h2>
At the end of the day, every tool ends up executing sequences of
convergent operators against a system. 

{% img right http://i.imgur.com/uKQHY.png 300 %}
{% img right http://i.imgur.com/g4fcW.png 300 %}

kajnsdk jasdjhasdkj nasdlkjas dlkjasdlkja sdlkj asdlkjasdl alkj asdlk ad;lk
sdlkj sdfklj sdfl;kj sadf asdflkj asdlfkjasdl;fjk asdflkj asdfl;jk
asdl;fjk  asdflk;jasdfl;jk sadfl;kj asdf;lj asdf;ljk sad;lfjk as
sdfl;kjsdf;lkjasd f;ljsa dfl;kj asdf;lkj sadflkj asdf asdfjkl;asdf;lkj
asdf;lkj asdf;ljk asdf;ljk asdf asd;fjasdfjk asdf;ljk sadf;ljk
asdf;lkj sadf;lkj as;ldfjkasdf;lkj asdf;ljk asdf;lj asdf;ljasd
asdfjasdf;lkjasdf;lkj asdf;lasdf;ljk asdfl;jk asdfl;jk asdf;lj
asdf;lkj asdf;lkj asdf;lkj asdf;lkj asdf;lkj sadf

Here is some more text

<h2> The Best You Can Do </h2>

{% img left http://i.imgur.com/oyf5b.png 300 %}

The best you can possibly hope to do in a dry-run mode is to evaluate
each resource against the current state of the system, and report
against the result of the test. 

kajnsdkjasdjhasdkjnasdlkjasdl kjasdlkjasd lkjasdlkjasdl alkj asdlk ad;lk
sdlkj sdfklj sdfl;kj sadf asdflkj asdlfkjasdl;fjk asdflkj asdfl;jk
asdl;fjk  asdflk;jasdfl;jk sadfl;kj asdf;lj asdf;ljk sad;lfjk as
sdfl;kjsdf;lkjasd f;ljsa dfl;kj asdf;lkj sadflkj asdf asdfjkl;asdf;lkj
asdf;lkj asdf;ljk asdf;ljk asdf asd;fjasdfjk asdf;ljk sadf;ljk
asdf;lkj sadf;lkj as;ldfjkasdf;lkj asdf;ljk asdf;lj asdf;ljasd
asdfjasdf;lkjasdf;lkj asdf;lasdf;ljk asdfl;jk asdfl;jk asdf;lj
asdf;lkj asdf;lkj asdf;lkj asdf;lkj asdf;lkj sadf

<h2> Lies of the Legomen </h2>

{% img right http://i.imgur.com/4ORuB.jpg 250 350 %}

kajnsdk jasdjhasdkj nasdlkjas dlkjasdlkja sdlkj asdlkjasdl alkj asdlk ad;lk
sdlkj sdfklj sdfl;kj sadf asdflkj asdlfkjasdl;fjk asdflkj asdfl;jk
asdl;fjk  asdflk;jasdfl;jk sadfl;kj asdf;lj asdf;ljk sad;lfjk as
sdfl;kjsdf;lkjasd f;ljsa dfl;kj asdf;lkj sadflkj asdf asdfjkl;asdf;lkj
asdf;lkj asdf;ljk asdf;ljk asdf asd;fjasdfjk asdf;ljk sadf;ljk
asdf;lkj sadf;lkj as;ldfjkasdf;lkj asdf;ljk asdf;lj asdf;ljasd
asdfjasdf;lkjasdf;lkj asdf;lasdf;ljk asdfl;jk asdfl;jk asdf;lj
asdf;lkj asdf;lkj asdf;lkj asdf;lkj asdf;lkj sadf

CFEngine example<br>
Puppet example<br>
Chef example<br>

<h2> Turn it around and spin positive </h2>

kajnsdk jasdjhasdkj nasdlkjas dlkjasdlkja sdlkj asdlkjasdl alkj asdlk ad;lk
sdlkj sdfklj sdfl;kj sadf asdflkj asdlfkjasdl;fjk asdflkj asdfl;jk
asdl;fjk  asdflk;jasdfl;jk sadfl;kj asdf;lj asdf;ljk sad;lfjk as
sdfl;kjsdf;lkjasd f;ljsa dfl;kj asdf;lkj sadflkj asdf asdfjkl;asdf;lkj
asdf;lkj asdf;ljk asdf;ljk asdf asd;fjasdfjk asdf;ljk sadf;ljk
asdf;lkj sadf;lkj as;ldfjkasdf;lkj asdf;ljk asdf;lj asdf;ljasd
asdfjasdf;lkjasdf;lkj asdf;lasdf;ljk asdfl;jk asdfl;jk asdf;lj
asdf;lkj asdf;lkj asdf;lkj asdf;lkj asdf;lkj sadf
