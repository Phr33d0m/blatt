What is this?
=============
Just a very simple script to help Gentoo arch testers find out issues with packages' build systems.
It should find very obvious problems, but is far from perfect. Also, it could (and will probably do for sure) miss issues that is supposed to find out.

How does it work?
-----------------
Currently it only accepts one argument which is the full path to the build log in the PORT_LOGDIR directory (not the one in the package's temp/ dir).

Example:
![alt text](http://i.politeia.in/di-SQZL.png "blatt in action")


Prerequisites
-------------
You must have set `PORT_LOGDIR` in your `make.conf`
You must have `app-portage/eix` installed.

Bugs?
=====
All type of help is appreciated.
I'm a very newbie into Bash so, bug reports, new ideas and patches are ALWAYS welcome!
