What is this?
=============
Just a very simple script to help Gentoo arch testers find out issues with packages' build systems.  
It should find very obvious problems, but is far from perfect. Also, it could (and will probably do for sure) miss issues that is supposed to find out.

How does it work?
=================

Prerequisites
-------------
You *should* have set `PORT_LOGDIR` in your `make.conf` like this: `PORT_LOGDIR="/path/to/logs"`, otherwise build logs won't get saved for later use.

You can perfectly use **blatt** without having `PORT_LOGDIR` set, of course.

Dependencies
------------
**blatt** depends on:
* app-portage/eix
* app-portage/gentoolkit

Usage
-----
Just pass `blatt.sh`, as arguments, a list of build logs. Usually all build logs will be in PORT_LOGDIR.
* ./blatt.sh /var/log/portage/*.log

Example:
![alt text](http://i.politeia.in/di-SQZL.png "blatt in action")

Bugs?
=====
All type of help is appreciated.  Bug reports, new ideas and patches are ALWAYS welcome!