#!/usr/bin/env coffee

### AUTHOR
# 
# Billy Moon
#
# http://billy.itaccess.org/
#
###

### LICENSE
# 
# Copyright (c) 2012 by Billy Moon.  All rights reserved.
# 
# This module is free software;
# you can redistribute it and/or modify it under the MIT license
# The LICENSE file contains the full text of the license.
# 
###

#
#  Modules
#
fs = require 'fs'
exec = require("child_process").exec

parseArgs = ->
  #
  #  Command line options
  #
  options = 
    s:'state'
    m:'message'
    e:'editor'
    t:'type'

  # simple toggels, don't consume next argument
  switches =
    d:'debug'
    x:'exit'

  args = process.argv
  o = {_:[],$0:[]}
  validOptions = []

  for k, v of options
    validOptions.push v

  i = -2
  na = false # next argument: false/opt/flag

  for arg in args
    if m = arg.match /^--(.+?)(=(.+))?$/
      na = m[1]
      o[m[1]] = m[3] || true
    else if m = arg.match /^-(.+?)(=(.+))?$/
      if na = options[m[1]]
        if na == 'message'
          o[na] = m[3] ? [m[3]] | ['']
        else
          o[na] = m[3] || true
      else if switches[m[1]]
        na = false
        o[switches[m[1]]] = m[3] || true
      else
        console.log 'Unknown flag: '+m[1]
        exit 1
    else if ++i > 0 # ignore first two args which are node and app
      if na == 'message'
        o.message = [arg]
      else if na != false
        o[na] = arg
      else
        if o.message
          o.message.push arg
        else
          o._.push arg
      na = false
    else
      o['$0'].push arg

  if o.message
    o.message = o.message.join ' '

  return o

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

getDate = ->
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
  $uid = opts.date+"."+opts.args.email
  $uid = md5 $uid
  $uid = $uid.replace /(.{4}).+/, "$1"

  return $uid

### 
# 
# Find and return an array of hashes, one for each existing bug.
# 
###
getBugs = ->
  files = fs.readdirSync opts.store
  files.sort()
  $results = []
  $number = 1
  for file in files
    if file.match /\.log$/
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

    # strip lead bug identifier
    $arg = $arg.replace /^%/, ''
    
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
  print "EXIT ~ with code: "+code
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

    $editor = opts.args.editor || process.env.EDITOR || (opts.win ?  'notepad' : "vim");
    exec "#{$editor} #{file}"

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
      -s, --state         - Restrict matches when searching (open/closed).

  '''
  exit 0


#  Custom Modules

#
# MD5 Library
#

md5 = require('../lib/md5.js').MD5.hex_md5

#
#  Core Functions
#

hook = (action, file) ->
  if hooks[action]
    hooks[action].run(file)

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

  fs.appendFileSync opts.store+$bug.file, content

  #
  #  If there is a hook, run it.
  #
  hook $state, $bug.file

#
#  Handlers for the commands.
#
#

get_title = (callback)->
  stdin = process.openStdin()
  process.stdout.write "Title: "
  stdin.addListener "data", (d) ->
    opts.args.title = d.toString().substring(0, d.length-1)
    process.stdin.destroy()
    callback()

get_message = (callback)->
  stdin = process.openStdin()
  process.stdout.write "Message: "
  print stdin.addListener "data", (d) ->
    opts.args.message = d.toString().substring(0, d.length-1)
    process.stdin.destroy()
    callback()

write_file = ->
  fs.writeFileSync opts.args.file, opts.args.template + opts.args.message+ "\n"

get_items = ->
  if ! opts.args.title
    get_title get_items
  else if ! opts.args.message
    get_message get_items
  else
    print "got them all"
  # print opts.args

do_add = ->
  print "Will add with: "+opts.args

###
# Add a new bug.
# 
# The arguments specified are the optional title. 
# 
###
cmd_add = (command) ->

  #
  #  Make a "random" filename, with the same UID as the content.s
  #

  $uid = randomUID()
  $title = command.title
  $type = command.type || 'bug'

  opts.args.file = "#{opts.date}.#{$uid}.log";

  #
  #  Write our template to it
  #
  opts.args.template = """
  UID: #{$uid}
  Type: #{$type}
  Title: #{$title}
  Added: #{opts.date}
  Author: #{opts.args.name}
  Status: open\n\n
  """

  #
  #  If we were given a message, add it to the file, and return without
  #  invoking the editor.
  #
  if command.message
    fs.writeFileSync opts.store+opts.args.file, opts.args.template + command.message+ "\n"
    #
    #  If there is a hook, run it.
    #
    hook "add", opts.args.file
    return

  #
  #  Otherwise add the default text, and show it in an editor.
  #  (ending newline helps in stripping the comments out later)
  else

    opts.args.template += """
    # klog:
    # klog:  Enter your bug report here; it is better to write too much than
    # klog: too little.
    # klog:
    # klog:  Lines beginning with "# klog:" will be ignored, and removed,
    # klog: this file is saved.
    # klog:\n
    """

    fs.writeFileSync opts.args.file, opts.args.template

    #
    #  Open the file in the users' editor.
    #
    editFile opts.args.file

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
    removeClog opts.args.file

    #
    #  If there is a hook, run it.
    #
    hook "add", opts.args.file

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
    $bug = getBugByUIDORNumber args[0]

    #
    #  If we were given a message add it, otherwise spawn the editor.
    #
    if opts.args.message
      $out = "\nModified: #{opts.date}\n#{opts.args.message}\n"
      fs.appendFileSync opts.store+$bug.file, $out
      return
    else
      $out = "\nModified: #{opts.date}\n\n"
      fs.appendFileSync opts.store+$bug.file, $out      

    #
    #  Allow the user to make the edits.
    #
    editFile opts.store+$bug.file

    #
    #  Once it was saved remove the lines that mention "# klog: "
    #
    removeClog opts.store+$bug.file

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
cmd_search = (command) ->

  #
  #  The search terms, if any.
  #
  $terms = command.args.terms

  #
  #  Get all available bugs.
  #
  $bugs = getBugs()

  #
  #  The state of the bugs the user is interested in.
  #
  $state = if command.args.state then command.args.state else 'all'

  #
  #  The type of the bugs the user is interested in.
  #
  $type = command.args.type || "all"

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
    if command.args.terms # there are $terms
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
    # removed number: ##{$b_number} 
    hl = if $b_status == 'open' then glob.clrs.green else glob.clrs.red
    print "%#{hl}#{$b_uid}#{glob.clrs.reset} [#{$b_status}] [#{$b_type}] #{$b_title}"

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

  $value = args.id

  #
  #  Ensure we know what we're operating upon
  #
  if ! $value # there is not a $value
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
  buffer = fs.readFileSync opts.store + $bug.file
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

  $value = args.id

  #
  #  Ensure we know what we're operating upon
  #
  if ! $value
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
  editFile opts.store+$bug.file

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
    
    $value = args.id

    #
    #  Ensure we know what we're operating upon
    #
    if ! $value
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
    fs.unlinkSync opts.store+$file

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
  if ! fs.existsSync opts.store
    fs.mkdirSync opts.store
    fs.writeFileSync "#{opts.store}.gitignore","local"
    fs.mkdirSync "#{opts.store}local"
    fs.writeFileSync "#{opts.store}local/settings.json","""
    {
      "user":"John Doe",
      "email":"john@thedoughfactory.com"
    }
    """
    print "Now you have klogs on!"
    exit 0
  else
    print "There is already a .klog/ directory present here"
    exit 1

get_user_details = (callback) ->
  if opts.args.name && opts.args.email
    callback()
  else
    exec 'git config --get user.email', (se,so,e) ->
      if so.length
        opts.args.email = so.replace /\n/, ''
        exec 'git config --get user.name', (se,so,e) ->
          if so.length
            opts.args.name = so.replace /\n/, ''
          else
            opts.args.name = opts.args.email.replace /@.+$/, ''
          callback()
      else
        print """
        Tried to get email address from Git, but could not determine using:
        \n\tgit config --get user.email\n
        It might be a good idea to set it with:
        \n\tgit options etc...\n
        """
        print "Please enter your details... (leave blank to abort)"
        stdin = process.openStdin()
        process.stdout.write "Name: "
        stdin.addListener "data", (d) ->
          if ! opts.args.name && opts.args.name = d.toString().substring(0, d.length-1)
            process.stdout.write "Email: "
          else if ! opts.args.email && opts.args.email = d.toString().substring(0, d.length-1)
            process.stdin.destroy()
            callback()
          else
            print "Error: tried everything, still no name and email!"
            exit 1

get_confirmation = (callback, message) ->
  stdin = process.openStdin()
  process.stdout.write "Are you sure? [yes/yep/yeah/y|no/nope/nah/n]: "
  stdin.addListener "data", (d) ->
    if d.toString().match /y(e(p|s|ah))?/i    
      callback()
      process.stdin.destroy()
    else
      if message
        print message
      process.stdin.destroy()
      exit 1

get_required = (items, final) ->
  stdin = process.openStdin()
  if ! items?.length
    stdin.pause()
    if ! opts.command.needs?.length
      delete opts.command.needs
    final()
  else
    if ! opts.args[items[0]]
      item = items.shift()
    if ! opts.args[item] && item
      process.stdout.write "#{item}: "
      stdin.once 'data', (d) ->
        line = d.toString().trim()
        if line
          opts.command.args[item] = line
        else
          items.unshift item
        get_required items, final

#
#  parse opts.args and return command object
#  should validate required options, but not their values
#
get_command = ->
  out =
    args: []

  get_id = ->
    if id = opts.args._.shift()
      opts.args.id = id.replace /^%/, ''

  # valid commands defined as obejct tree
  commands =
    add:
      required: ['title','message']
      valid: ['type']
      args: -> opts.args.title = opts.args._.join ' '
    delete:
      required: ['id']
      args: ->
        if id = opts.args._.shift()
          opts.args.id = id.replace /^%/, ''
    help: {}
    init: {}
    search:
      valid: ['type','state']
    view:
      required: ['id']
      args: get_id
    edit:
      required: ['id']
      args: get_id
    close:
      required: ['id']
      args: get_id
  
  commands.list = commands.search

  # figure out what the command is, or assign `help`
  subcommand = opts.args._.shift() || 'help' # if no arguments
  command = commands[subcommand] || subcommand = 'help' # if invalid argument
  out.name = subcommand

  # parse remaining arguments according to subcommand
  if command.args then command.args()    

  # required options
  if command.required
    for requirement in command.required
      if has = opts.args[requirement]
        out.args = {} unless out.args
        out.args[requirement] = has
      else
        out.needs = [] unless out.needs
        out.needs.push requirement

  # optional options
  if command.valid
    for valid in command.valid
      if has = opts.args[valid]
        out.args = {} unless out.args
        out.args[valid] = has

  # superfluous options
  for x of opts.args
    if x != '$0' && x != '_'
      if ! out.args[x]
        rejects = [] unless rejects
        rejects.push x

  if rejects
    message = "Error: unsupported option used"
    print message
    exit 1

  return out

###
#
# The main routine ************************************************************************************************
#
###

main = ->

  # Parse the command line options.
  opts.args = parseArgs()  

  # Generate command from arguments
  opts.command = get_command()

  get_required opts.command.needs, ->
    process.stdout.write "Command: "
    print opts.command

    # temporary fix of args
    opts.args._.unshift opts.command.name
    
    if opts.args.debug
      print opts.args
      
    if opts.args.exit
      exit 0    

    #
    #  Ensure we received an argument.
    #

    if opts.args.help || ! opts.args._.length
      usage()
      exit 1
    else
      opts.cmd = opts.args._.shift()

    #
    #  Decide what to do, based upon the command given.
    #
    if opts.cmd.match /^init$/i

      #
      #  Initialise.
      #
      cmd_init()

    else if opts.cmd.match /^add$/i

      #
      #  Add a bug.
      #

      cmd_add opts.command.args


    else if opts.cmd.match /^append$/i

      #
      #  Append a section of text to an existing bug report.
      #
      cmd_append opts.command

    else if opts.cmd.match /^html$/i

      #
      #  Output bugs as a simple HTML page.
      #
      cmd_html opts.args._

    else if opts.cmd.match /^(list|search)$/i

      #
      #  Find bugs.
      #
      cmd_search opts.command

    else if opts.cmd.match /^open$/i

      #
      #  List only open bugs.
      #
      cmd_search opts.args._, 'open'

    else if opts.cmd.match /^closed$/i

      #
      #  List only closed bugs.
      #
      cmd_search opts.args._, 'closed'

    else if opts.cmd.match /^view$/i

      #
      #  View a single bug.
      #
      cmd_view opts.command.args

    else if opts.cmd.match /^close$/i

      #
      #  Mark a bug as closed.
      #
      cmd_close opts.args._

    else if opts.cmd.match /^reopen$/i

      #
      #  Mark a bug as open.
      #
      cmd_reopen opts.args._

    else if opts.cmd.match /^edit$/i

      #
      #  Edit a bug.
      #
      cmd_edit opts.command.args

    else if opts.cmd.match /^delete$/i

      #
      #  Delete a bug.
      #

      cmd_view opts.command.args
      print "About to delete this bug..."
      get_confirmation ->
        cmd_delete opts.command.args
      , "Phew, that was close!"

    else
      usage()

#
#  Globals
#
opts =
  ext: 'log' # file extension for data files
  date: getDate()
  store: '.klog/'
  win: process.platform == 'win32'

path = process.cwd().split /\//
for folder in path
  sep = if opts.win then "\\" else "/"
  tpath = (path.join sep)+sep
  if fs.existsSync "#{tpath}#{opts.store}"
    opts.path = tpath
    break
  path.pop()

glob = {}
glob.clrs = {

  bright:"\u001b[1m",

  red:"\u001b[31m",
  green:"\u001b[32m",
  blue:"\u001b[34m",

  cyan:"\u001b[36m",
  magenta:"\u001b[35m",
  yellow:"\u001b[33m",
  black:"\u001b[30m",

  silver:"\u001b[30m",
  white:"\u001b[37m",

  back_red:"\u001b[41m",
  back_green:"\u001b[42m",
  back_blue:"\u001b[44m",
  back_cyan:"\u001b[46m",
  back_magenta:"\u001b[45m",
  back_yellow:"\u001b[43m",
  back_black:"\u001b[40m",
  back_silver:"\u001b[47m",

  reset:"\u001b[m\u000f"

}


# get hooks and add them to objects
hooks = {}
if fs.existsSync "#{opts.path+opts.store}hooks"
  fs.readdirSync("#{opts.path+opts.store}hooks").forEach (file) ->
    hooks[file.replace /\.\w+$/,''] = require "#{opts.path+opts.store}hooks/#{file}"

# fire it up
main()

