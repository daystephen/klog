## NAME

klog - A simple distributed bug tracking system.

## ABOUT

klog is an intentionally simple system which allows bugs to be stored
inside projects, and merged in along with all other changes in exactly the
way that a user of a distributed revision control system would expect.

In short a project will have any and all bugs stored beneath the **.klog**
directory.  These bugs will be stored in random, but hostname-sepcific,
filename such that multiple people merging and commiting will be unlikely
to ever see conflicts.

Any project may have bugs in two states:

* Open.
* Closed.

Each bug will have an associated UID and number.  The UID associated with
a bug will be unchanged and fixed at the time it is created, but the number
is a purely local convience.

## USING IT

Usage of klog is divided into several distinct cases:

* Initialising a new project.
* Adding a bug.
* Searching for bugs.
* Viewing a specific bug.
* Updating a bug, or appending to an existing bug report.
* Closing or re-opening a bug.,

These actions all work in a consistent manner, to avoid unpleasant suprises.

## USAGE EXAMPLES

To initialise a bug database within your project run:

    klog init

Once you've initialised your klog database you will need to ensure that
you add the **.klog** database to your revision control system.

To add a new bug, optionally specifying a title for it, please run:

    klog add This is my bug title

If no title is specified a bug report will be created with a default
title.  This will open an editor for you to enter the bug report text.

The editer may be specified with the **--editor** flag, the EDITOR environmental
variable, and will otherwise default to **vim**.

Once a bug report has been created you should find that it is visible in the
output of "klog list" or "klog open".  In both cases you'll see output which
looks something like this:

    N:0001 [closed] testing me
    N:0002 [closed] This is atest
    N:0003 [  open] This is my bug title

This listing report shows three things:  The number of the bug, the state
of the bug ("open" vs. "closed") and the title of the bug.

Each of the operations that is specific to a single bug report will allow you
to specify the number of the bug.  For example if you wished to update the
last bug, to append some text to it, you could run:

    klog append 3

Similarly you could close the bug by running:

    klog close 3

Note that to close a bug you do not need to give a justification, or add
any content.  A bug may go from freshly opened to closed with no need for
further updates.

## BUG FILE FORMAT

Internally each bug is stored in a file, beneath the **.klog** directory.

Each bug file has a random name which is designed to avoid potential collisions
if a repository is shared between many users, upon different systems, as is
common with distributed revision controls.

Each bug report will have several fixed fields at the beginning, as this
example shows:

    Title: This is atest
    UID: 1269990083.P10668M151020.birthday.my.flat
    Added: Wed Mar 31 00:01:23 2010
    Status: open

    I like pies, but I have none.

The UID is essentially random, but should be unique, and is the portable
sane way to refer to bugs.  When running **klog list** you'll see a number
reported next to each bug, but this number is valid only for the local system
and may change when new bugs are reported.

In short you may use the displayed "bug number" for carrying out local
operations providing you realise that the number associated with a specific
bug will change over time.  By contrast the UID will never change, so you
may always run a command like this:

    klog view 1270024997.P15442M277230.birthday.my.flat

## CUSTOMIZATION

The template which is presented to the user when they report a new bug
may be replaced.  If the file ".klog/new-bug-template" is present the
contents of that file will be inserted in new reports, rather than the
default message.

If the file **.klog/hook** exists, and is executable, it will be invoked
when new bugs are added, bugs are closed, or comments are updated.

The hook will be invoked with two arguments, the first will be a string
defining the action which has caused the invocation, the second will be
the name of the bug file.  For example you might use this to auto-add
new bug reports to the repository with a hook like this:

    #!/bin/sh
    if [ "$1" = "add" ]; then
        hg add "$2"
    fi