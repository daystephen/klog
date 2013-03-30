## klog issue tracking that works on a submarine!

klog is designed to be a distributed issue tracking tool. as such, it should
integrate with any distributed version control system. I use git, but klog is
vcs agnostic - simply track the issue files along with your code!

### Get the code!

  * view the project on [GitHub : billymoon/klog](https://github.com/billymoon/klog)
  * [Download ZIP File](https://github.com/billymoon/klog/zipball/master)
  * [Download TAR Ball](https://github.com/billymoon/klog/tarball/master)
  * [npm page](https://npmjs.org/package/klog)

### Installation

klog is currently a node.js app, written in javascript (actually coffee-
script) and is available via npm.

_it is worth putting the `-g` on there so the binary (`klog`) becomes
available after install!_

    $ npm install klog -g

### Basic usage

klog is designed to make your issue tracking easier by having a simple command
line interface

_there is a proof-of-method imlementation of a web interface, fancy one coming
soon!_

    $ klog init
    $ klog add IE6 not rendering page correctly -m "ie6 needs special treatment to render the page correctly"
    $ klog list %a6a0 [ 0] [open] [bug] IE6 not rendering page correctly
    $ klog view a6a0
    UID: a6a0
    Type: bug
    Title: IE6 not rendering page correctly
    Added: 2012-09-12_22-09-13.966
    Author: Billy Moon
    Status: open

    ie6 needs special treatment to render the page correctly
    $ # business as usual

### Issue tracking

files are stored as plain text files, with a filename (bug id) which uses a
hash based on the exact time the issue was raised (millisecond precision) and
the author's email address. these firstbits become the UID of the issue,
preventing colision with other issues being raised by other developers at the
same time.

by keeping all the issues with the git repo, it becomes a great offline tool
for managing a project. any developer who has the repo, also has the tools
needed to track progress, pick a task to work on, and read the rationale
behind chages to the code. this feature is also great for archiving projects,
with the confidence that all the related discussion and material is all in one
place!

_this project is very much in it's early stages and should be considered a
development project, not yet fit for production. watch out for version 1.0.0!_

