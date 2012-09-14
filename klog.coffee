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
  $number = 1
  for file in files
    buffer = fs.readFileSync ".klog/#{file}"
    lines = buffer.toString().split /\n/
    # print content
    $body = []
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
      $bug = $possible if parseInt(m[1]) == $possible.number
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
    print "Failed to open #{$file}"
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
  print '''

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
  print "hooked #{action} with #{file}"

### 
# 
# Change the statues of an existing bug.  Valid statuses are
# "open" and "closed".
# 
###
changeBugState = ($value, $state) ->

  #
  #  Ensure the status is valid.
  #
  if ! $state.match /^(open|closed)$/i
    print "Invalid status #{$state}"
    exit 1

  #
  #  Get the bug.
  #
  $bug = getBugByUIDORNumber $value

  #
  #  Ensure the bug isn't already in the specified state.
  #
  if $bug.status == $state
    print "The bug is already $state!\n"
    exit 1

  #
  #  Now write out the new status section.
  #
  
  content = """\n
  Modified: #{opts.date}
  Status: #{$state}\n
  """

  fs.appendFileSync '.klog/'+$bug.file, content

  #
  #  If there is a hook, run it.
  #
  hook $state, $bug.file

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
  Status: open\n\n
  """

  #
  #  If we were given a message, add it to the file, and return without
  #  invoking the editor.
  #
  if argv.message
    fs.writeFileSync $file, $template + argv.message+ "\n"
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
      print """
      You must specify a bug to append to, either by the UID, or via the number.
      For example to append text to bug number 3 you'd run:
      \n\tklog append 3\n
      """
      exit 1

    #
    #  Get the bug
    #
    $bug = getBugByUIDORNumber $args[0]
    print $bug

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


### 
# 
# Output a HTML page for the bugs.
# 
###
cmd_html = (args) ->

  #
  #  Get all bugs.
  #
  $bugs = getBugs()

  #
  #  Open + closed bugs.
  #
  $open = []
  $closed = []

  for $b in $bugs
    if $b.status.match /open/i
      $open.push $b
    else
      $closed.push $b

  #
  #  Counts
  #
  $open_count   = $open.length
  $closed_count = $closed.length

  print """
  <!DOCTYPE HTML>
  <html lang="en-US">
  <head>
    <meta charset="UTF-8">
    <title>klog : issue tracking and time management</title>
  </head>
  <body>
    
    <h1>Klog : issue tracking and time management</h1>

    <table>
    <tr><td><b><a href="#open">Open bugs</a></b></td><td>#{$open_count}</td></tr>
    <tr><td><b><a href="#closed">Closed bugs</a></b></td><td>#{$closed_count}</td></tr>
    </table>

      <h2 id="open">Open bugs</h2>
  """
  for $b in $open
    print """
      <blockquote>
      <dl class="toggle">
      <dt>#{$b.title}</dt>
      <dd><pre>#{$b.body}</pre></dd>
      </dl>
      </blockquote>
    """
  print """
    <h2 id="closed">Closed bugs</h2>
    <blockquote>
    <dl class="toggle">
  """
  for $b in $closed
    print """
      <dt>#{$b.title}</dt>
      <dd><pre>#{$b.body}</pre></dd>
      </dl>
      </blockquote>
    """
  print """
   <hr />
   <p style="text-align:right;">Generated by <a href="http://billymoon.github.com/klog/">klog</a>.</p>
   </body>
  </html>
  """

### 
# 
# Search the existing bugs.
# 
# Here search means "match against title and status".  Either of which
# is optional.
# 
###
cmd_search = (args, $state) ->

  #
  #  The search terms, if any.
  #
  $terms = args.join ' '

  #
  #  Get all available bugs.
  #
  $bugs = getBugs()

  #
  #  The state of the bugs the user is interested in.
  #
  $state ?= 'all'

  #
  #  The type of the bugs the user is interested in.
  #
  $type = argv.type || "all"

  # print "will search for `#{$terms}` with state `#{$state}` and type `#{$type}`"

  #
  #  For each bug
  #
  for $bug in $bugs

    #
    #  Find basic meta-data.
    #
    $b_title  = $bug.title
    $b_type   = $bug.type
    $b_status = $bug.status
    $b_uid    = $bug.uid
    $b_file   = $bug.file
    $b_number = $bug.number

    #
    #  If the user is being specific about status then
    # skip ones that don't match, as this is cheap.
    #
    if $state != "all" and $state.toLowerCase() != $b_status.toLowerCase()
      continue

    #
    #  If the user is being specific about type then
    #  skip ones that don't match
    #
    if $type != "all" and $type.toLowerCase() != $b_type.toLowerCase()
      continue

    #
    #  If there are search terms then search the title.
    #
    #  All terms must match.
    #
    $match = 1
    if args.length # there are $terms
      for $term in $terms.split /[ \t]/
        if ! $b_title.match new RegExp $term, 'i'
          $match = 0
    #
    #  If we didn't find a match move on.
    #
    continue unless $match

    #
    #  Otherwise show a summary of the bug.
    #
    # print sprintf "%-4s %s %-8s %-9s %s", "#".$b_number, $b_uid, "[".$b_status."]", "[".$b_type."]", $b_title . "\n";
    print "##{$b_number} #{$b_uid} [#{$b_status}] [#{$b_type}] #{$b_title}"

### 
# 
# View a specific bug.
# 
# This means:
# 
#    1.  Find the file associated with the bug.
#    2.  Open it and print it to the console.
# 
###
cmd_view = (args) ->

  $value = args.join ''

  #
  #  Ensure we know what we're operating upon
  #
  if ! args.length # there is not a $value
    print "You must specify a bug to view, either by the UID, or via the number.\n"
    print "\nFor example to view bug number 3 you'd run:\n"
    print "\tklog view 3\n\n";

    print "Maybe a list of open bugs will help you:\n\n"

    cmd_search()

    print "\n"

    exit 1

  #
  #  Get the bug.
  #
  $bug = getBugByUIDORNumber $value

  #
  #  Show it to the console
  #
  buffer = fs.readFileSync '.klog/' + $bug.file
  print buffer.toString()


### 
# 
# Close a given bug.
# 
###
cmd_close = (args) ->

  #
  #  Get the bug.
  #
  $value = args.join ' '

  #
  #  Ensure we know what we're operating upon
  #
  if ! args.length # has $value
    print """
    You must specify a bug to close, either by the UID, or via the number.
    For example to close bug number 3 you'd run:
    \n\tklog close 3\n\n
    """
    exit 1

  changeBugState $value, "closed"

### 
# 
# Reopen a bug.
# 
###

cmd_reopen = (args) ->

    #
    #  Get the bug.
    #
    $value = args.join ''

    #
    #  Ensure we know what we're operating upon
    #
    if ! args.length
      print """
      You must specify a bug to reopen, either by the UID, or via the number.
      For example to reopen bug number 3 you'd run:
      \n\tklog reopen 3
      """
      exit 1

    changeBugState $value, "open"


### 
# 
# Allow a bug to be updated.
# 
# This mostly means:
# 
# 1.  find the file associated with a given bug.
# 2.  Allow the user to edit that file.
# 
###
cmd_edit = (args) ->

  $value = args.join ''

  #
  #  Ensure we know what we're operating upon
  #
  if ! args.length
    print """
    You must specify a bug to edit, either by the UID, or via the number.
    For example to edit bug number 3 you'd run:
    \n\tklog edit 3\n\n
    """
    exit 1

  #
  #  Find the bug.
  #
  $bug = getBugByUIDORNumber $value

  #
  #  Edit the file the bug is stored in.
  #
  editFile '.klog/'+$bug.file

  #
  #  If there is a hook, run it.
  #
  hook "edit", $bug.file

### 
# Allow a bug to be deleted.
# 
# This mostly means:
# 
# 1.  find the file associated with a given bug.
# 2.  delete that file.
# 
###
cmd_delete = (args) ->
    
    $value = args.join ''

    #
    #  Ensure we know what we're operating upon
    #
    if ! args.length
        print """
        You must specify a bug to delete, either by the UID, or via the number.
        For example to delete bug number 3 you'd run:
        \n\tklog delete 3\n
        """
        exit 1

    #
    #  Find the bug.
    #
    $bug = getBugByUIDORNumber $value

    #
    #  Delete the file the bug is stored in.
    #
    $file = $bug.file
    fs.unlinkSync '.klog/'+$file

    #
    #  If there is a hook, run it.
    #
    hook "delete", $bug.file

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
    print "There is already a .klog/ directory present here.\n"
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