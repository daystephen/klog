#!/usr/bin/env coffee

# START HEADER COMMENTS
###

Author: Billy Moon (http://billy.itaccess.org/)

LICENSE:

  Copyright (c) 2012 by Billy Moon.  All rights reserved.

  This module is free software;
  you can redistribute it and/or modify it under the MIT license
  The LICENSE file contains the full text of the license.

###
# END HEADER COMMENTS

## Modules

fs = require 'fs'
exec = require("child_process").exec

# MD5 Library
_ = require('../lib/underscore-min.js')

# MD5 Library
md5 = require('../lib/md5.js').MD5.hex_md5

## Functions

parseArgs = ->

  # Command line options
  options = 
    s:'state'
    m:'message'
    e:'editor'
    t:'type'

  # simple toggels, don't consume next argument
  switches =
    d:'debug'
    x:'exit'
    f:'force'

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

## Utility functions.

# Pad a string (with 0 or specified)
pad=`function(e,t,n){n=n||"0",t=t||2;while((""+e).length<t)e=n+e;return e}`

# return date in format yyyy-mm-dd_hh-ii-ss
getDate = ->
  c = new Date()
  return c.getFullYear()+"-"+pad(c.getMonth()+1)+"-"+pad(c.getDate()-5)+"_"+c.toLocaleTimeString().replace(/\D/g,'-')+"."+pad(c.getMilliseconds(),3)

# Generate a system UID.  This should be created with the username and
# time included, such that collisions when running upon multiple systems
# are unlikely.
randomUID = ->
  # The values that feed into the filename.
  $uid = opts.date+"."+opts.email
  $uid = md5 $uid
  $uid = $uid.replace /(.{4}).+/, "$1"
  return $uid

# Find and return an array of hashes, one for each existing bug.
getBugs = ->
  files = fs.readdirSync "#{opts.path+opts.store}"
  files.sort()
  $results = []
  $number = 1
  for file in files
    if file.match /\.log$/
      $status = 'open'
      buffer = fs.readFileSync "#{opts.path+opts.store}#{file}"
      lines = buffer.toString().split /[\r\n]+/
      # print content
      $body = []
      for line in lines
        if m = line.match /^Title: (.*)/
          $title = m[1]
        else if m = line.match /^Type: (.*)/
          $type = m[1]
        else if m = line.match /^(Added|Modified):(.*)/
          # ignored
        else if m = line.match /^Author: (.*)/
          $author = m[1]
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
        author: $author || 'unspecified'

  return $results

# Print to console
print = (txt) ->
  console.log txt

# Get the data for a given bug, either by number of UID.
getBugByUIDORNumber = ($arg) ->
  # Get all bugs.
  $bugs = getBugs()
  # For each one.
  for $possible in $bugs
    # If the argument was NNNN then look for that bug number.
    # strip lead bug identifier
    $arg = $arg.replace /^%/, ''
    
    if m = $arg.match /^([0-9]{1,3})$/i
      $bug = $possible if parseInt(m[1]) == $possible.number
    else
      # Otherwise look for it by UID
      $bug = $possible if $arg.toLowerCase() == $possible.uid.toLowerCase()

    if $bug
      return $bug
  print "Bug not found: #{$arg}\r\n"
  exit 1

# Exit app with error code
exit = (code) ->

  # print "#{glob.clrs.red}EXIT ~ with code: #{glob.clrs.bright}#{code}#{glob.clrs.reset}"

  # only if we are not in server mode
  if ! opts.server
    process.exit code

# Open the given file with either the users editor, the systems editor,
# or as a last resort vim or notepad depending on platform.
editFile = (file) ->
  # Open the editor
  $editor = if opts.args.editor then opts.args.editor else if  process.env.EDITOR then process.env.EDITOR else if opts.win then "notepad" else "vim"
  exec "#{$editor} #{file}"

# Remove the "# klog: " prefix from the given file.
remove_comments = ($file) ->
  # Open the source file for reading.
  try
    buffer = fs.readFileSync $file
  catch e
    print "Failed to open #{$file}"
    exit 

  content = buffer.toString().replace /^# klog:.*(\r\n|\n|\r)/mg, ''
  # Write the contents, removing any lines matching our marker-pattern
  fs.writeFileSync $file, content

# Show the usage of this script and exit.
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
      server              - HTTP server displays bugs, and accepts commands

    Options:
      -f, --force         - no confirmation when deleting
      -t, --type          - issue type (default:bug) i.e. feature/enhance/task
      -m, --message       - Use the given message rather than spawning an editor.
      -s, --state         - Restrict matches when searching (open/closed).

  '''
     # -e, --editor        - Specify which editor to use.
  exit 0

hook = (action, file) ->
  if hooks[action]
    hooks[action].run file

# Change the statues of an existing bug.  Valid statuses are
# "open" and "closed".
changeBugState = ($value, $state) ->

  # Ensure the status is valid.
  if ! $state.match /^(open|closed)$/i
    print "Invalid status #{$state}"
    exit 1

  # Get the bug.
  $bug = getBugByUIDORNumber $value

  # Ensure the bug isn't already in the specified state.
  if $bug.status == $state
    print "The bug is already $state!\r\n"
    exit 1

  # Now write out the new status section.
  content = """\r\n\r\n
  Modified: #{opts.date}
  Status: #{$state}\r\n
  """

  fs.appendFileSync opts.path+opts.store+$bug.file, content

  # If there is a hook, run it.
  hook $state, $bug.file

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
  fs.writeFileSync opts.args.file, opts.args.template + opts.args.message+ "\r\n"

get_items = ->
  if ! opts.args.title
    get_title get_items
  else if ! opts.args.message
    get_message get_items
  else
    print "got them all"

get_user_details = (callback) ->
  if opts.user && opts.email
    callback()
  else
    exec 'git config --get user.email', (se,so,e) ->
      if so.length
        opts.email = so.replace /[\r\n]+/, ''
        exec 'git config --get user.name', (se,so,e) ->
          if so.length
            opts.user = so.replace /[\r\n]+/, ''
          else
            opts.user = opts.email.replace /@.+$/, ''
          callback()
      else
        print """
        Tried to get email address from Git, but could not determine using:
        \r\n\tgit config --get user.email\r\n
        It might be a good idea to set it with:
        \r\n\tgit config etc...\r\n
        """
        print "Please enter your details... (leave blank to abort)"
        stdin = process.openStdin()
        process.stdout.write "Name: "
        stdin.addListener "data", (d) ->
          if ! opts.user && opts.user = d.toString().trim()
            process.stdout.write "Email: "
          else if ! opts.email && opts.email = d.toString().trim()
            process.stdin.destroy()
            callback()
          else
            print "Error: tried everything, still no name and email!"
            exit 1

get_confirmation = (callback, message) ->
  stdin = process.openStdin()
  process.stdout.write "Are you sure? [yep/nope]: "
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
  stdin = process.stdin
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
      stdin.resume()
      stdin.once 'data', (d) ->
        stdin.pause()
        line = d.toString().trim()
        if line
          opts.command.args[item] = line
        else
          items.unshift item
        get_required items, final

## Handlers for the commands.
cmd = {}

# Add a new bug.
cmd.add = (args) ->

  # Make a "random" filename, with the same UID as the content.
  $uid = randomUID()
  $title = args.title
  $type = args.type || 'bug'

  opts.args.file = "#{opts.date}.#{$uid}.log";

  # Write our template to it
  opts.args.template = """
  UID: #{$uid}
  Type: #{$type}
  Title: #{$title}
  Added: #{opts.date}
  Author: #{opts.user}
  \r\n
  """
  # Status: open\r\n\r\n

  # If we were given a message, add it to the file, and return without
  # invoking the editor.
  if args.message
    fs.writeFileSync opts.path+opts.store+opts.args.file, opts.args.template + args.message+ "\r\n"
    # If there is a hook, run it.
    hook "add", opts.args.file
    return

  # Otherwise add the default text, and show it in an editor.
  #  (ending newline helps in stripping the comments out later)
  else

    opts.args.template += """
    # klog:
    # klog:  Enter your bug report here; it is better to write too much than
    # klog: too little.
    # klog:
    # klog:  Lines beginning with "# klog:" will be ignored, and removed,
    # klog: this file is saved.
    # klog:\r\n
    """

    fs.writeFileSync opts.args.file, opts.args.template

    # Open the file in the users' editor.
    editFile opts.args.file

    # Once it was saved remove the lines that mention "# klog: "
    remove_comments opts.args.file

    # If there is a hook, run it.
    hook "add", opts.args.file

# Open an editor with a new block appended to the end of the file.
# This mostly means:
#    1.  find the file associated with a given bug.
#    2.  Append the new text.
#    3.  Allow the user to edit that file.
cmd.append = (args) ->

    # Ensure we know what we're operating upon
    if ! args.id
      print """
      You must specify a bug to append to, either by the UID, or via the number.
      For example to append text to bug number 3 you'd run:
      \r\n\tklog append 3\r\n
      """
      exit 1

    # Get the bug
    $bug = getBugByUIDORNumber args.id

    # If we were given a message add it, otherwise spawn the editor.
    if args.message
      $out = "\r\nModified: #{opts.date}\r\n#{opts.args.message}\r\n"
      fs.appendFileSync opts.path+opts.store+$bug.file, $out
      return
    else
      $out = "\r\nModified: #{opts.date}\r\n\r\n"
      fs.appendFileSync opts.path+opts.store+$bug.file, $out      

    # Allow the user to make the edits.
    editFile opts.path+opts.store+$bug.file

    ## BROKEN due to separate process ##
    # # Once it was saved remove the lines that mention "# klog: "
    # remove_comments opts.store+$bug.file

    # If there is a hook, run it.
    hook "append", $bug.file


# Output a HTML page for the bugs.
cmd.html = (args) ->

  # Get all bugs.
  $bugs = getBugs()

  # Open + closed bugs.
  $open = []
  $closed = []

  for $b in $bugs
    if $b.status.match /open/i
      $open.push $b
    else
      $closed.push $b

  # Counts
  $open_count   = $open.length
  $closed_count = $closed.length

  out = """
  <!DOCTYPE HTML>
  <html lang="en-US">
  <head>
    <meta charset="UTF-8">
    <title>klog : issue tracking and time management</title>
    <style type='text/css'>
    body{
      font-family: century gothic;
    }
    .bug {
      background-color: silver;
      border-radius: 0.5em 0.5em 0.5em 0.5em;
      margin: 0.5em 0;
      padding: 0.3em 1em;
    }
    #command-intro {
      padding-left: 0.5em;
      width: 37px;
    }
    input {
      background-color: black;
      border: medium none;
      color: silver;
      float: left;
      height: 2em;
      margin: 0;
      padding: 0;
    }
    h1, h2, h3, h4, h5, h6, p, ul{
      clear: both;
    }
    #command{
      width: 40em
    }
    #execute{
      border-left: 1px solid red
    }
    </style>
  </head>
  <body onload="document.getElementById('command').focus()">
    
    <h1>Klog : issue tracking and time management</h1>

    <ul>
      <li><a href='#open' class='button'>#{$open_count} : open bugs</a></li>
      <li><a href='#closed' class='button'>#{$closed_count} : closed bugs</a></li>
    </ul>

    <form action='.' method='POST'>
      <input type="text" value="$ klog" readonly="readonly" name="intro" id="command-intro">
      <input type="text" name="command" id="command">
      <input type="submit" id="execute" value="execute!">
    </form>

    <a name='open'></a>
    <h2 id="open">Open bugs</h2>
  """
  for $b in $open
    out += """
      <div class='bug'>
        <h3>#{$b.title}</h3>
        <ul>
          <li>UID: #{$b.uid}</li>
          <li>Added: #{$b.added}</li>
          <li>Author: #{$b.author}</li>
          <li>Type: #{$b.type}</li>
        </ul>
        <p>#{$b.body.join "\r\n"}</p>
      </div>
    """
  out += """
    <h2 id="closed">Closed bugs</h2>
  """
  for $b in $closed
    out += """
      <div class='bug'>
        <h3>#{$b.title}</h3>
        <ul>
          <li>UID: #{$b.uid}</li>
          <li>Added: #{$b.added}</li>
          <li>Author: #{$b.author}</li>
          <li>Type: #{$b.type}</li>
        </ul>
        <p>#{$b.body.join "\r\n"}</p>
      </div>
    """
  out += """
    <div id="foot">
      Generated by <a href="http://billymoon.github.com/klog/">klog</a>.
    </div>
  </body>
  </html>
  """
  if args.return
    return out
  else
    print out

# Search the existing bugs.
# Here search means "match against title and status".  Either of which
# is optional.
cmd.search = (args) ->

  # The search terms, if any.
  $terms = args.terms

  # Get all available bugs.
  $bugs = getBugs()

  # The state of the bugs the user is interested in.
  $state = if args.state then args.state else 'all'

  # The type of the bugs the user is interested in.
  $type = args.type || "all"

  # print "will search for `#{$terms}` with state `#{$state}` and type `#{$type}`"

  # For each bug
  for $bug in $bugs

    # Find basic meta-data.
    $b_title  = $bug.title
    $b_type   = $bug.type
    $b_status = $bug.status
    $b_uid    = $bug.uid
    $b_file   = $bug.file
    $b_number = $bug.number

    # If the user is being specific about status then
    # skip ones that don't match, as this is cheap.
    if $state != "all" and $state.toLowerCase() != $b_status.toLowerCase()
      continue

    # If the user is being specific about type then
    # skip ones that don't match
    if $type != "all" and $type.toLowerCase() != $b_type.toLowerCase()
      continue

    # If there are search terms then search the title.
    # All terms must match.
    $match = 1
    if args.terms # there are $terms
      for $term in $terms.split /[ \t]/
        if ! $b_title.match new RegExp $term, 'i'
          $match = 0
    # If we didn't find a match move on.
    continue unless $match

    # Otherwise show a summary of the bug.
    # print sprintf "%-4s %s %-8s %-9s %s", "#".$b_number, $b_uid, "[".$b_status."]", "[".$b_type."]", $b_title . "\r\n";
    # removed number: ##{$b_number} 
    hl = if $b_status == 'open' then glob.clrs.green else glob.clrs.red
    cb = glob.clrs.bright
    ch = glob.clrs.yellow
    cr = glob.clrs.reset
    print "%#{hl}#{$b_uid}#{glob.clrs.reset} [#{ch}#{$b_status}#{cr}] [#{ch+cb}#{$b_type}#{cr}] #{$b_title}"

# View a specific bug.
# This means:
#    1.  Find the file associated with the bug.
#    2.  Open it and print it to the console.
cmd.view = (args) ->

  $value = args.id

  # Ensure we know what we're operating upon
  if ! $value # there is not a $value
    print "You must specify a bug to view, either by the UID, or via the number.\r\n"
    print "\r\nFor example to view bug number 3 you'd run:\r\n"
    print "\tklog view 3\r\n\r\n";

    print "Maybe a list of open bugs will help you:\r\n\r\n"

    cmd.search()

    print "\r\n"

    exit 1

  # Get the bug.
  $bug = getBugByUIDORNumber $value

  # Show it to the console
  buffer = fs.readFileSync opts.path+opts.store + $bug.file
  print buffer.toString().replace /^(\w+): /gm, "#{glob.clrs.yellow}$1#{glob.clrs.reset}: "


# Close a given bug.
cmd.close = (args) ->

  # Get the bug.
  $value = args.id

  # Ensure we know what we're operating upon
  if ! $value # has $value
    print """
    You must specify a bug to close, either by the UID, or via the number.
    For example to close bug number 3 you'd run:
    \r\n\tklog close 3\r\n\r\n
    """
    exit 1

  changeBugState $value, "closed"

# Reopen a bug.
cmd.reopen = (args) ->

    # Get the bug.
    $value = args.id

    # Ensure we know what we're operating upon
    if ! $value
      print """
      You must specify a bug to reopen, either by the UID, or via the number.
      For example to reopen bug number 3 you'd run:
      \r\n\tklog reopen 3
      """
      exit 1

    changeBugState $value, "open"


# Allow a bug to be updated.
# This mostly means:
# 1.  find the file associated with a given bug.
# 2.  Allow the user to edit that file.
cmd.edit = (args) ->

  $value = args.id

  # Ensure we know what we're operating upon
  if ! $value
    print """
    You must specify a bug to edit, either by the UID, or via the number.
    For example to edit bug number 3 you'd run:
    \r\n\tklog edit 3\r\n\r\n
    """
    exit 1

  # Find the bug.
  $bug = getBugByUIDORNumber $value

  # Edit the file the bug is stored in.
  editFile opts.path+opts.store+$bug.file

  # If there is a hook, run it.
  hook "edit", $bug.file

# Allow a bug to be deleted.
# This mostly means:
# 1.  find the file associated with a given bug.
# 2.  delete that file.
cmd.delete = (args) ->
    cmd.view opts.command.args
    do_delete = ->
      $value = args.id

      # Ensure we know what we're operating upon
      if ! $value
          print """
          You must specify a bug to delete, either by the UID, or via the number.
          For example to delete bug number 3 you'd run:
          \r\n\tklog delete 3\r\n
          """
          exit 1

      # Find the bug.
      $bug = getBugByUIDORNumber $value

      # Delete the file the bug is stored in.
      $file = $bug.file
      fs.unlinkSync opts.path+opts.store+$file

      # If there is a hook, run it.
      hook "delete", $bug.file

    if ! args.force
      get_confirmation ->
        print "About to delete this bug..."
        do_delete()
      , "Phew, that was close!"    
    else
      do_delete()

# Inititalise a new .klog directory.
cmd.init = ->
  if ! fs.existsSync opts.path+opts.store
    fs.mkdirSync opts.path+opts.store
    print "#{glob.clrs.gunmetal}Now you have klogs on#{glob.clrs.reset}#{glob.clrs.red}!#{glob.clrs.reset}"
    cmd.setup()
  else
    print "There is already a .klog/ directory present here"
    exit 1

cmd.setup = ->
  if opts.user && opts.email
    settings = """
    {
      "user":"#{opts.path+opts.user || 'John Doe'}",
      "email":"#{opts.path+opts.email || 'john@thedoughfactory.com'}"
    }
    """
    fs.writeFileSync "#{opts.path+opts.store}.gitignore","local"
    fs.mkdirSync "#{opts.path+opts.store}local"
    fs.writeFileSync "#{opts.path+opts.store}local/settings.json", settings
    print "Wrote settings to local file: #{opts.path+opts.store}local/settings.json\r\n\r\n#{settings}\r\n"
  else
    get_user_details cmd.setup

cmd.server = ->

  opts.server = true

  port = 1234
  http = require 'http'
  qs = require 'querystring'
  url = require 'url'

  command = (data) ->
    # POST = JSON.parse POST
    # opts.args._.push data.command.split ' '
    args = data.command.trim().split ' '
    print args
    while process.argv.length > 2
      process.argv.pop()
    _.each args, (v) ->
      process.argv.push v

    main()



  http.createServer (req, res) ->
    out_html = ->
      # print req.body
      res.writeHead 200,
        'Content-Type': 'text/html'
      opts.command.args.return = true
      res.end cmd.html opts.command.args

    if req.method == 'POST'
      body=''
      req.on 'data', (data) ->
        body += data
      req.on 'end', ->
        POST =  qs.parse body
        command POST
        out_html()
    else if req.method == 'GET'
      url_parts = url.parse req.url, true
      print url_parts.query
      out_html()

  .listen port
  console.log "Server running at http://127.0.0.1:#{port}/"

# parse opts.args and return command object
# should validate required options, but not their values
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
      args: ->
        if opts.args._.length
          opts.args.title = opts.args._.join ' '
    delete:
      required: ['id']
      valid: ['force']
      args: ->
        if id = opts.args._.shift()
          opts.args.id = id.replace /^%/, ''
    help: {}
    init: {}
    search:
      valid: ['type','state']
    open:
      required: ['state'] # auto populated
      valid: ['type']
      args: ->
        opts.args.state = 'open'
    closed:
      required: ['state'] # auto populated
      valid: ['type']
      args: ->
        opts.args.state = 'closed'
    view:
      required: ['id']
      args: get_id
    edit:
      required: ['id']
      valid: ['editor']
      args: get_id
    append:
      required: ['id']
      valid: ['message']
      args: get_id
    reopen:
      required: ['id']
      args: get_id
    close:
      required: ['id']
      args: get_id
    html: {}
    server: {}
  
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

# The main routine ************************************************************************************************
main = ->

  # Parse the command line options.
  opts.args = parseArgs()  

  # Generate command from arguments
  opts.command = get_command()

  opts.command.name = opts.command.name.replace /^(open|closed|list)$/, 'search'

  get_required opts.command.needs, ->
    # process.stdout.write "#{glob.clrs.red+glob.clrs.bright}Command: "
    # print opts.command
    # process.stdout.write "#{glob.clrs.reset}"

    # temporary fix of args
    opts.args._.unshift opts.command.name
    
    if opts.args.debug
      print opts.args
      
    if opts.args.exit
      exit 0    

    # Ensure we received an argument.

    if opts.args.help || ! opts.args._.length
      usage()
      exit 1
    else
      opts.cmd = opts.args._.shift()

    if cmd[opts.command.name]
      cmd[opts.command.name] opts.command.args
    else
      usage()

# Globals
opts =
  ext: 'log' # file extension for data files
  date: getDate()
  store: '.klog/'
  win: process.platform == 'win32'

# set project path
path = process.cwd().split /\//
for folder in path
  sep = if opts.win then "\\" else "/"
  tpath = (path.join sep)+sep
  if fs.existsSync "#{tpath+opts.store}"
    opts.path = tpath
    break
  path.pop()

# Read settings (including `user` and `email`)
if fs.existsSync "#{opts.path+opts.store}/local/settings.json"
  buffer = fs.readFileSync "#{opts.path+opts.store}/local/settings.json"
  settings = JSON.parse buffer.toString()
  opts = _.extend opts, settings

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

  gunmetal:"\u001b[30m\u001b[1m",
  silver:"\u001b[37m",
  white:"\u001b[37m\u001b[1m",

  back_red:"\u001b[41m",
  back_green:"\u001b[42m",
  back_blue:"\u001b[44m",
  back_cyan:"\u001b[46m",
  back_magenta:"\u001b[45m",
  back_yellow:"\u001b[43m",
  back_black:"\u001b[40m",
  back_silver:"\u001b[47m",

  reset:"\u001b[m"

}


# get hooks and add them to the glogal hook object
hooks = {}
if fs.existsSync "#{opts.path+opts.store}hooks"
  fs.readdirSync("#{opts.path+opts.store}hooks").forEach (file) ->
    hooks[file.replace /\.\w+$/,''] = require "#{opts.path+opts.store}hooks/#{file}"

# fire it up
main()

