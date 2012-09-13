#!/usr/bin/env coffee

### AUTHOR
# 
# Billy Moon
#
# http://billy.itaccess.org/
#
###

### DERIVED FROM
# 
#  milli
#   by
#  Steve
#  --
#  http://www.steve.org.uk/
# 
###

### LICENSE
# 
# Copyright (c) 2012 by Billy Moon.  All rights reserved.
# 
# This module is free software;
# you can redistribute it and/or modify it under
# the same terms as Perl itself.
# The LICENSE file contains the full text of the license.
# 
###

#
#  Modules
#
fs = require 'fs'
#sys = require("sys")
exec = require("child_process").exec
execSync = require('exec-sync')
argv = require('optimist')
  .alias('t','type')
  .alias('m','message')
  .argv

###
#
#  Utility functions.
#
###

#
#  Pad a string (with 0 or specified)
#
pad=`function(e,t,n){n=n||"0",t=t||2;while((""+e).length<t)e=n+e;return e}`

###
#
# return date in format
#
#    yyyy-mm-dd_hh-ii-ss
#
###

date = ->
  c = new Date()
  return c.getFullYear()+"-"+pad(c.getMonth()+1)+"-"+pad(c.getDate()-5)+"_"+c.toLocaleTimeString().replace(/\D/g,'-')+"."+pad(c.getMilliseconds(),3)

### 
# Generate a system UID.  This should be created with the hostname and
# time included, such that collisions when running upon multiple systems
# are unlikely.
# 
# (A bug will be uniquely referenced by the UID, even though in practise
# people will use bug numbers they are prone to change.)
# 
# 
###

randomUID = ->
    #
    #  The values that feed into the filename.
    #
    $email = execSync 'git config --get user.email'
    $uid = opts.date+"."+$email
    $uid = md5 $uid
    $uid = $uid.replace /(.{4}).+/, "$1"

    return $uid

### 
# 
# Find and return an array of hashes, one for each existing bug.
# 
###
getBugs = ->
  #files = execSync "ls .klog/*.#{opts.ext}"
  files = fs.readdirSync '.klog'
  files.sort()
  $results = []
  for file in files
    buffer = fs.readFileSync ".klog/#{file}"
    lines = buffer.toString().split /\n/
    # console.log content
    $body = []
    $number = 1
    for line in lines
      if m = line.match /^Title: (.*)/
        $title = m[1]
      else if m = line.match /^Type: (.*)/
        $type = m[1]
      else if m = line.match /^(Added|Modified):(.*)/
        # ignored
      else if m = line.match /^UID: (.*)/
        $uid = m[1]
      else if m = line.match /^Status: (.*)/i
        $status = m[1]
      else
        $body.push line
    $results.push
      file: file
      body: $body
      number: $number++
      uid: $uid
      status: $status
      type: $type
      title: $title

  return $results

#
#  Print to console
#
print = (txt) ->
  console.log txt

###
# 
# Get the data for a given bug, either by number of UID.
# 
###
getBugByUIDORNumber = ($arg) ->
  #
  #  Get all bugs.
  #
  $bugs = getBugs()
  #
  #  For each one.
  #
  for $possible in $bugs
    #
    # If the argument was NNNN then look for that bug number.
    #
    if m = $arg.match /^([0-9]{1,3})$/i
      $bug = $possible if m[1] == $possible.number
    else
      #
      #  Otherwise look for it by UID
      #
      $bug = $possible if $arg.toLowerCase() == $possible.uid.toLowerCase()

    if $bug
      return $bug
  print "Bug not found: #{$arg}\n"
  exit 1

#
#  Exit app
#

exit = (code) ->
  process.exit code

### 
# 
# Open the given file with either the users editor, the systems editor,
# or as a last resort vim.
# 
###

editFile = (file) ->

    #
    #  Open the editor
    #

    # $editor = $CONFIG{ 'editor' } || $ENV{ 'EDITOR' } || "vim";
    execSync "sub #{file}"

### 
# 
# Remove the "# klog: " prefix from the given file.
# 
###

removeClog = ($file) ->

  #
  #  Open the source file for reading.
  #
  try
    buffer = fs.readFileSync $file
  catch e
    console.log "Failed to open #{$file}"
    exit 

  content = buffer.toString().replace /^# klog:.*\n/mg, ''

  #
  #  Write the contents, removing any lines matching our marker-pattern
  #
  fs.writeFileSync $file, content

#  Constants
opts =
  ext: 'log' # file extension for data files
  date: date()

###
#
# Parse the command line options.
# 
###

parseCommandLineArguments = ->
  if argv.help
    usage()
###  #
  #  Parse options.
  #
  if (
      !GetOptions(

          # Help options
          "help",    \$HELP,
          "verbose", \$CONFIG{ 'verbose' }, # only used when creating init directory

          # Type of bug (feature / bug / task / etc...)
          "type=s", \$CONFIG{ 'type' },

          # Editor & message.
          "editor=s",  \$CONFIG{ 'editor' },
          "message=s", \$CONFIG{ 'message' },

          # state, used for search/list
          "state=s",  \$CONFIG{ 'state' }
      ) )
  {
      exit;
  }
  usage() if HELP;
###

### 
#
# Show the usage of this script and exit.
# 
###

usage = ->
  console.log '''

  klog [options] sub-command [args]

    Available sub-commands:

      add                 - Add a new bug.
      append              - Append text to an existing bug.
      close               - Change an open bug to closed.
      closed              - List all currently closed bugs.
      edit                - Allow a bug to be edited.
      delete              - Allow a bug to be deleted.
      init                - Initialise the system.
      list|search         - Display existing bugs.
      open                - List all currently open bugs.
      reopen              - Change a closed bug to open.
      view                - Show all details about a specific bug.

    Options:
      -e, --editor        - Specify which editor to use.
      -m, --message       - Use the given message rather than spawning an editor.
      -s, --state         - Restrict matches when searching.

  '''
  exit 0

#
#  Parse any command line options.
#
parseCommandLineArguments()

#  Custom Modules

#
# MD5 Library
#

md5 = require('./md5.js').MD5.hex_md5


#
#  Core Functions
#

hook = (action, file) ->
  console.log action, file

#
#  Handlers for the commands.
#
#

###
# Add a new bug.
# 
# The arguments specified are the optional title. 
# 
###
cmd_add = (args, type) ->

  if args.length
    $title = args.join " "
  else
    $title = "Untitled bug report"

  $type = type || 'bug'

  #
  #  Make a "random" filename, with the same UID as the content.s
  #

  $uid  = randomUID()

  $file = ".klog/#{opts.date}.#{$uid}.log";

  #
  #  Write our template to it
  #
  $template = """
  UID: #{$uid}
  Type: #{$type}
  Title: #{$title}
  Added: #{opts.date}
  Status: open

  """

  #
  #  If we were given a message, add it to the file, and return without
  #  invoking the editor.
  #
  if argv.message
    fs.writeFileSync $file, $template + argv.message+ "\n\n"
    #
    #  If there is a hook, run it.
    #
    hook "add", $file
    return
  #
  #  Otherwise add the default text, and show it in an editor.
  #  (ending newline helps in stripping the comments out later)
  else
    $template += """

    # klog:
    # klog:  Enter your bug report here; it is better to write too much than
    # klog: too little.
    # klog:
    # klog:  Lines beginning with "# klog:" will be ignored, and removed,
    # klog: this file is saved.
    # klog:\n
    """

    fs.writeFileSync $file, $template

    #
    #  Open the file in the users' editor.
    #
    editFile $file

    ### one day we could use a bug template file
    if ( -e ".klog/new-bug-template" )
    {
        open( TMP, "<", ".klog/new-bug-template" ) or
          die "Failed to open file $!";
        while ( my $line = <TMP> )
        {
            print FILE $line;
        }
        close(TMP);
    }
    ###

  #
  #  Once it was saved remove the lines that mention "# klog: "
  #
  removeClog $file

  #
  #  If there is a hook, run it.
  #
  hook "add", $file

### 
# Open an editor with a new block appended to the end of the file.
# 
# This mostly means:
# 
#    1.  find the file associated with a given bug.
# 
#    2.  Append the new text.
# 
#    3.  Allow the user to edit that file.
# 
# 
###
cmd_append = (args) ->

    #
    #  Ensure we know what we're operating upon
    #
    if !args.length
      console.log """
      You must specify a bug to append to, either by the UID, or via the number.
      For example to append text to bug number 3 you'd run:
      \n\tklog append 3\n
      """
      exit 1

    #
    #  Get the bug
    #
    $bug = getBugByUIDORNumber $args[0]
    console.log $bug

    #
    #  If we were given a message add it, otherwise spawn the editor.
    #
    if argv.message
      $out = "\nModified: #{opts.date}\n#{argv.message}\n"
      fs.appendFileSync '.klog/'+$bug.file, $out
      return
    #
    #  Allow the user to make the edits.
    #
    editFile ".klog/"+$bug.file

    #
    #  Once it was saved remove the lines that mention "# klog: "
    #
    removeClog ".klog/"+$bug.file

    #
    #  If there is a hook, run it.
    #
    hook "append", $bug.file


cmd_html = (args) ->
  console.log 'will html with ' + args

cmd_search = (args, state) ->
  state ?= 'all'
  console.log 'will search ('+state+') with ' + args

cmd_view = (args) ->
  console.log 'will view with ' + args

cmd_close = (args) ->
  console.log 'will close with ' + args

cmd_reopen = (args) ->
  console.log 'will reopen with ' + args

cmd_edit = (args) ->
  console.log 'will edit with ' + args

cmd_delete = (args) ->
  console.log 'will delete with ' + args

###
# 
# Inititalise a new .klog directory.
# 
###
cmd_init = ->
  if ! fs.existsSync ".klog"
    fs.mkdirSync ".klog"
    exit 0
  else
    console.log "There is already a .klog/ directory present here.\n"
    exit 1

#
#  Ensure we received an argument.
#
if ! argv._.length
  usage()
else
  $cmd = argv._.shift()
  $args = argv._

#
#  Decide what to do, based upon the command given.
#
if $cmd.match /^init$/i

  #
  #  Initialise.
  #
  cmd_init()
  exit 0

else if $cmd.match /^add$/i

  #
  #  Add a bug.
  #
  cmd_add $args, argv.type
  exit 0
else if $cmd.match /^append$/i

  #
  #  Append a section of text to an existing bug report.
  #
  cmd_append $args
  exit 0
else if $cmd.match /^html$/i

  #
  #  Output bugs as a simple HTML page.
  #
  cmd_html $args
  exit 0
else if $cmd.match /^(list|search)$/i

  #
  #  Find bugs.
  #
  cmd_search $args
  exit 0
else if $cmd.match /^open$/i

  #
  #  List only open bugs.
  #
  cmd_search $args, 'open'
  exit 0
else if $cmd.match /^closed$/i

  #
  #  List only closed bugs.
  #
  cmd_search $args, 'closed'
  exit 0
else if $cmd.match /^view$/i

  #
  #  View a single bug.
  #
  cmd_view $args
  exit 0
else if $cmd.match /^close$/i

  #
  #  Mark a bug as closed.
  #
  cmd_close $args
  exit 0
else if $cmd.match /^reopen$/i

  #
  #  Mark a bug as open.
  #
  cmd_reopen $args
  exit 0
else if $cmd.match /^edit$/i

  #
  #  Edit a bug.
  #
  cmd_edit $args
  exit 0
else if $cmd.match /^delete$/i

  #
  #  Delete a bug.
  #
  cmd_delete $args
  exit 0
else
  usage()

exit 0


debug =
  opts: opts
  argv: argv
  cmd: $cmd
  args: $args
console.log debug
old_code = """


# 
# Output a HTML page for the bugs.
# 
# 
###

sub cmd_html
{
    my (@args) = (@_);

    #
    #  Get all bugs.
    #
    my $bugs = getBugs();


    #
    #  Open + closed bugs.
    #
    my $open;
    my $closed;

    foreach my $b (@$bugs)
    {
        if ( $b->{ 'status' } =~ /open/i )
        {
            push( @$open, $b );
        }
        else
        {
            push( @$closed, $b );
        }
    }

    #
    #  Sort both lists by date.
    #

    #
    #  Counts
    #
    my $open_count   = $open   ? scalar(@$open)   : 0;
    my $closed_count = $closed ? scalar(@$closed) : 0;


    print <<EOH;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" dir="ltr">
 <head>
  <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
  <title>Bug reports</title>
    <script type="text/javascript" src="http://static.steve.org.uk/js/jquery/jquery.js"></script>
    <script type="text/javascript" src="http://www.steve.org.uk/jquery/dltoggle/jquery.dltoggle.js"></script>
    <script type="text/javascript">
   \$('.toggle').dltoggle( { "open-image"   : "http://steve.org.uk/jquery/dltoggle/open.gif",
                         "closed-image" : "http://steve.org.uk/jquery/dltoggle/closed.gif" } );
    </script>
</head>

 <body>
  <div style="text-align: center;"><h1>Bug Reports</h1></div>
EOH

    print <<EOT;
  <table>
  <tr><td><b><a href="#open">Open bugs</a></b></td><td>$open_count</td></tr>
  <tr><td><b><a href="#closed">Closed bugs</a></b></td><td>$closed_count</td></tr>
  </table>
EOT

    print "<h2 id=\"open\">Open bugs</h2>\n";
    print "<blockquote>\n";
    print "<dl class=\"toggle\">\n";
    foreach my $b (@$open)
    {
        print "<dt>$b->{'title'}</dt>\n";
        print "<dd><pre>$b->{'body'}</pre></dd>\n";

    }
    print "</dl>\n";
    print "</blockquote>\n";

    print "<h2 id=\"closed\">Closed bugs</h2>\n";
    print "<blockquote>\n";
    print "<dl class=\"toggle\">\n";
    foreach my $b (@$closed)
    {
        print "<dt>$b->{'title'}</dt>\n";
        print "<dd><pre>$b->{'body'}</pre></dd>\n";
    }
    print "</dl>\n";
    print "</blockquote>\n";

    print <<EOF;
 <hr />
 <p style="text-align:right;">Produced by <a href="http://steve.org.uk/Software/klog/">klog</a>.</p>
 </body>
</html>
EOF
}

# 
# Search the existing bugs.
# 
# Here search means "match against title and status".  Either of which
# is optional.
# 
# 
###

sub cmd_search
{
    my (@args) = (@_);

    #
    #  The search terms, if any.
    #
    my $terms = join( " ", @args );

    #
    #  Get all available bugs.
    #
    my $bugs = getBugs();

    #
    #  The state of the bugs the user is interested in.
    #
    my $status = $CONFIG{ 'state' } || "all";

    #
    #  The type of the bugs the user is interested in.
    #
    my $type = $CONFIG{ 'type' } || "all";

    #
    #  For each bug
    #
    foreach my $bug (@$bugs)
    {

        #
        #  Find basic meta-data.
        #
        my $b_title  = $bug->{ 'title' };
        my $b_type   = $bug->{ 'type' };
        my $b_status = $bug->{ 'status' };
        my $b_uid    = $bug->{ 'uid' };
        my $b_file   = $bug->{ 'file' };
        my $b_number = $bug->{ 'number' };

        #
        #  If the user is being specific about status then
        # skip ones that don't match, as this is cheap.
        #
        if ( $status ne "all" )
        {
            next if ( lc($status) ne lc($b_status) );
        }

        #
        #  If the user is being specific about status then
        # skip ones that don't match, as this is cheap.
        #
        if ( $type ne "all" )
        {
            next if ( lc($type) ne lc($b_type) );
        }

        #
        #  If there are search terms then search the title.
        #
        #  All terms must match.
        #
        my $match = 1;
        if ( length $terms )
        {
            foreach my $term ( split( /[ \t]/, $terms ) )
            {
                if ( $b_title !~ /\Q$term\E/i )
                {
                    $match = 0;
                }
            }
        }

        #
        #  If we didn't find a match move on.
        #
        next unless ($match);

        #
        #  Otherwise show a summary of the bug.
        #
        print sprintf "%-4s %s %-8s %-9s %s", "#".$b_number, $b_uid, "[".$b_status."]", "[".$b_type."]", $b_title . "\n";
    }
}

# 
# Allow a bug to be updated.
# 
# This mostly means:
# 
# 1.  find the file associated with a given bug.
# 2.  Allow the user to edit that file.
# 
# 
###

sub cmd_edit
{
    my (@args) = (@_);

    my $value = join( "", @args );

    #
    #  Ensure we know what we're operating upon
    #
    if ( !length($value) )
    {
        print
          "You must specify a bug to edit, either by the UID, or via the number.\n";
        print "\nFor example to edit bug number 3 you'd run:\n";
        print "\tklog edit 3\n\n";
        exit 1;
    }

    #
    #  Find the bug.
    #
    my $bug = getBugByUIDORNumber($value);

    #
    #  Edit the file the bug is stored in.
    #
    editFile( $bug->{ 'file' } );

    #
    #  If there is a hook, run it.
    #
    if ( -x ".klog/hook" )
    {
        system( ".klog/hook", "edit", $bug->{ 'file' } );
    }
}

# 
# Allow a bug to be deleted.
# 
# This mostly means:
# 
# 1.  find the file associated with a given bug.
# 2.  delete that file.
# 
###

sub cmd_delete
{
    my (@args) = (@_);

    my $value = join( "", @args );

    #
    #  Ensure we know what we're operating upon
    #
    if ( !length($value) )
    {
        print
          "You must specify a bug to delete, either by the UID, or via the number.\n";
        print "\nFor example to delete bug number 3 you'd run:\n";
        print "\tklog delete 3\n\n";
        exit 1;
    }

    #
    #  Find the bug.
    #
    my $bug = getBugByUIDORNumber($value);

    #
    #  Delete the file the bug is stored in.
    #
    my $file = $bug->{ 'file' };
    `rm $file`;

    #
    #  If there is a hook, run it.
    #
    if ( -x ".klog/hook" )
    {
        system( ".klog/hook", "delete", $bug->{ 'file' } );
    }
}

# 
# View a specific bug.
# 
# This means:
# 
#    1.  Find the file associated with the bug.
#    2.  Open it and print it to the console.
# 
# 
###

sub cmd_view
{
    my (@args) = (@_);

    my $value = join( "", @args );

    #
    #  Ensure we know what we're operating upon
    #
    if ( !length($value) )
    {
        print
          "You must specify a bug to view, either by the UID, or via the number.\n";
        print "\nFor example to view bug number 3 you'd run:\n";
        print "\tklog view 3\n\n";

        print "Maybe a list of open bugs will help you:\n\n";

        cmd_search();

        print "\n";

        exit 1;
    }

    #
    #  Get the bug.
    #
    my $bug = getBugByUIDORNumber($value);

    #
    #  Show it to the console
    #
    open( FILE, "<", $bug->{ 'file' } ) or
      die "Failed to open file for reading $bug->{'file'} $!";

    while ( my $line = <FILE> )
    {
        print $line;
    }
    close(FILE);

}


# 
# Close a given bug.
# 
# 
###

sub cmd_close
{
    my (@args) = (@_);

    #
    #  Get the bug.
    #
    my $value = join( "", @args );

    #
    #  Ensure we know what we're operating upon
    #
    if ( !length($value) )
    {
        print
          "You must specify a bug to close, either by the UID, or via the number.\n";
        print "\nFor example to close bug number 3 you'd run:\n";
        print "\tklog close 3\n\n";
        exit 1;
    }

    changeBugState( $value, "closed" );
}

# 
# Reopen a bug.
# 
# 
###

sub cmd_reopen
{
    my (@args) = (@_);

    #
    #  Get the bug.
    #
    my $value = join( "", @args );

    #
    #  Ensure we know what we're operating upon
    #
    if ( !length($value) )
    {
        print
          "You must specify a bug to reopen, either by the UID, or via the number.\n";
        print "\nFor example to reopen bug number 3 you'd run:\n";
        print "\tklog reopen 3\n\n";
        exit 1;
    }

    changeBugState( $value, "open" );

}

# 
# Change the statues of an existing bug.  Valid statuses are
# "open" and "closed".
# 
# 
###

sub changeBugState
{
    my ( $value, $state ) = (@_);

    #
    #  Ensure the status is valid.
    #
    die "Invalid status $state" unless ( $state =~ /^(open|closed)$/i );


    #
    #  Get the bug.
    #
    my $bug = getBugByUIDORNumber($value);

    #
    #  Ensure the bug isn't already in the specified state.
    #
    if ( lc( $bug->{ 'status' } ) eq lc($state) )
    {
        print "The bug is already $state!\n";
        exit 1;
    }

    #
    #  Open the file
    #
    open( NEW, ">>", $bug->{ 'file' } ) or
      die "Failed to open file $bug->{'file'} for appending: $!";

    #
    #  Now write out the new status section.
    #
    my $date = date();
    print NEW <<EOF;

Modified: $date
Status: $state

EOF

    close(NEW);

    #
    #  If there is a hook, run it.
    #
    if ( -x ".klog/hook" )
    {
        system( ".klog/hook", $state, $bug->{ 'file' } );
    }
}

"""