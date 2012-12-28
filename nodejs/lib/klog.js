// Generated by CoffeeScript 1.3.3

/*

Author: Billy Moon (http://billy.itaccess.org/)

LICENSE:

  Copyright (c) 2012 by Billy Moon.  All rights reserved.

  This module is free software;
  you can redistribute it and/or modify it under the MIT license
  The LICENSE file contains the full text of the license.
*/


(function() {
  var asDate, buffer, changeBugState, cmd, editFile, editor, exec, exit, folder, fs, getBugByUIDORNumber, getBugs, getDate, get_command, get_confirmation, get_required, get_user_details, glob, hook, hooks, main, md5, opts, pad, parseArgs, path, print, randomUID, remove_comments, sep, settings, tpath, usage, _, _i, _len;

  fs = require('fs');

  exec = require("child_process").exec;

  _ = require('../lib/underscore-min.js');

  md5 = require('../lib/md5.js').MD5.hex_md5;

  editor = require('../lib/editor.js');

  parseArgs = function() {
    var arg, args, i, k, m, na, o, options, switches, v, validOptions, _i, _len, _ref;
    options = {
      s: 'state',
      m: 'message',
      e: 'editor',
      t: 'type',
      p: 'priority'
    };
    switches = {
      a: 'all',
      d: 'debug',
      f: 'force',
      r: 'return',
      x: 'plain'
    };
    args = process.argv;
    o = {
      _: [],
      $0: []
    };
    validOptions = [];
    for (k in options) {
      v = options[k];
      validOptions.push(v);
    }
    i = -2;
    na = false;
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      arg = args[_i];
      if (m = arg.match(/^--(.+?)(=(.+))?$/)) {
        na = m[1];
        o[m[1]] = m[3] || true;
      } else if (m = arg.match(/^-(.+?)(=(.+))?$/)) {
        if (na = options[m[1]]) {
          if (na === 'message') {
            o[na] = ((_ref = m[3]) != null ? _ref : [m[3]]) | [''];
          } else {
            o[na] = m[3] || true;
          }
        } else if (switches[m[1]]) {
          na = false;
          o[switches[m[1]]] = m[3] || true;
        } else {
          print('Unknown flag: ' + m[1]);
          exit(1);
        }
      } else if (++i > 0) {
        if (na === 'message') {
          o.message = [arg];
        } else if (na !== false) {
          o[na] = arg;
        } else {
          if (o.message) {
            o.message.push(arg);
          } else {
            o._.push(arg);
          }
        }
        na = false;
      } else {
        o['$0'].push(arg);
      }
    }
    if (o.message) {
      o.message = o.message.join(' ');
    }
    return o;
  };

  pad = function(e, t, n) {
    n = n || "0";
    t = t || 2;
    while (("" + e).length < t) {
      e = n + e;
    }
    return e;
  };

  getDate = function() {
    var c;
    c = new Date();
    return c.getFullYear() + "-" + pad(c.getMonth() + 1) + "-" + pad(c.getDate() - 5) + "_" + c.toLocaleTimeString().replace(/\D/g, '-') + "." + pad(c.getMilliseconds(), 3);
  };

  asDate = function(datestring) {
    return new Date(datestring.replace(/_/, 'T').replace(/T(.+)-(.+)-/, "T$1:$2:"));
  };

  randomUID = function() {
    var $uid;
    $uid = opts.date + "." + opts.email;
    $uid = md5($uid);
    $uid = $uid.replace(/(.{4}).+/, "$1");
    return $uid;
  };

  getBugs = function() {
    var $added, $author, $body, $modified, $number, $priority, $results, $status, $title, $type, $uid, buffer, file, files, line, lines, m, _i, _j, _len, _len1;
    files = fs.readdirSync("" + (opts.path + opts.store));
    files.sort();
    $results = [];
    $number = 1;
    for (_i = 0, _len = files.length; _i < _len; _i++) {
      file = files[_i];
      if (file.match(/\.log$/)) {
        $status = 'open';
        buffer = fs.readFileSync("" + (opts.path + opts.store) + file);
        lines = buffer.toString().split(/[\r\n]+/);
        $priority = 0;
        $modified = null;
        $body = [];
        for (_j = 0, _len1 = lines.length; _j < _len1; _j++) {
          line = lines[_j];
          if (m = line.match(/^Title: (.*)/)) {
            $title = m[1];
          } else if (m = line.match(/^Type: (.*)/)) {
            $type = m[1];
          } else if (m = line.match(/^Priority: (.*)/)) {
            $priority = m[1];
          } else if (m = line.match(/^Added: (.*)/)) {
            $added = m[1];
          } else if (m = line.match(/^Modified: (.*)/)) {
            $modified = m[1];
          } else if (m = line.match(/^Author: (.*)/)) {
            $author = m[1];
          } else if (m = line.match(/^UID: (.*)/)) {
            $uid = m[1];
          } else if (m = line.match(/^Status: (.*)/i)) {
            $status = m[1];
          } else {
            $body.push("\r\n" + line);
          }
        }
        if (!$modified) {
          $modified = $added;
        }
        $results.push({
          file: file,
          body: $body,
          number: $number++,
          uid: $uid,
          status: $status,
          type: $type,
          priority: $priority,
          title: $title,
          added: $added,
          modified: $modified,
          author: $author || 'unspecified'
        });
      }
    }
    return $results;
  };

  print = function(txt) {
    return console.log(txt);
  };

  getBugByUIDORNumber = function($arg) {
    var $bug, $bugs, $possible, bug, cb, ch, cr, hl, m, _i, _len;
    $bugs = getBugs();
    for (_i = 0, _len = $bugs.length; _i < _len; _i++) {
      $possible = $bugs[_i];
      $arg = $arg.replace(/^%/, '');
      if (m = $arg.match(/^([0-9]{1,3})$/i)) {
        if (parseInt(m[1]) === $possible.number) {
          $bug = $possible;
        }
      } else {
        if ($arg.toLowerCase() === $possible.uid.toLowerCase()) {
          $bug = $possible;
        }
      }
      if ($bug) {
        return $bug;
      }
    }
    print("Last resort, trying to search (open issues) for: " + glob.clrs.yellow + $arg + glob.clrs.reset);
    bug = cmd.search({
      "return": true,
      terms: $arg,
      state: 'open',
      all: false
    });
    if (bug) {
      hl = bug.status === 'open' ? glob.clrs.green : glob.clrs.red;
      cb = glob.clrs.bright;
      ch = glob.clrs.yellow;
      cr = glob.clrs.reset;
      print("Found: %" + hl + bug.uid + glob.clrs.reset + " [" + ch + bug.status + cr + "] [" + (ch + cb) + bug.type + cr + "] " + bug.title);
      return bug;
    }
    print("Bug not found!!");
    return exit(1);
  };

  exit = function(code) {
    if (!opts.server) {
      return process.exit(code);
    }
  };

  editFile = function(file) {
    var $editor;
    $editor = opts.args.editor ? opts.args.editor : process.env.EDITOR ? process.env.EDITOR : opts.win ? "notepad" : "vim";
    return editor(file, {});
  };

  remove_comments = function($file) {
    var buffer, content;
    try {
      buffer = fs.readFileSync($file);
    } catch (e) {
      print("Failed to open " + $file);
      exit;

    }
    content = buffer.toString().replace(/^# klog:.*(\r\n|\n|\r)/mg, '');
    return fs.writeFileSync($file, content);
  };

  usage = function() {
    print('\nklog [options] sub-command [args]\n\n  Available sub-commands:\n\n    add                 - Add a new bug.\n    append              - Append text to an existing bug.\n                          Set type with -t, and use `.` as message for no message\n    close               - Change an open bug to closed.\n    closed              - List all currently closed bugs.\n    edit                - Allow a bug to be edited.\n    delete              - Allow a bug to be deleted.\n    destroy             - Destroys the whole klog storage folder (including all issue data!)\n    init                - Initialise the system.\n    list|search         - Display existing bugs.\n    open                - List all currently open bugs.\n    reopen              - Change a closed bug to open.\n    view                - Show all details about a specific bug.\n    server              - HTTP server displays bugs, and accepts commands\n\n  Options:\n    -f, --force         - no confirmation when deleting\n    -t, --type          - issue type (default:bug) i.e. feature/enhance/task\n    -m, --message       - Use the given message rather than spawning an editor.\n    -s, --state         - Restrict matches when searching (open/closed).\n    -a, --all           - Search everywhere (type, and message), not just the title \n    -p, --priority      - Set the priority (`.` is replaced with `-`, so `.3` will result in `-3`)\n');
    return exit(0);
  };

  hook = function(action, file) {
    if (hooks[action]) {
      return hooks[action].run(file);
    }
  };

  changeBugState = function($value, $state) {
    var $bug, add, content, mod;
    if (!$state.match(/^(open|closed)$/i)) {
      print("Invalid status " + $state);
      exit(1);
    }
    $bug = getBugByUIDORNumber($value);
    if ($bug.status === $state) {
      print("The bug is already " + $state + "!\r\n");
      exit(1);
    }
    content = "\r\n\nModified: " + opts.date + "\nStatus: " + $state;
    fs.appendFileSync(opts.path + opts.store + $bug.file, content);
    add = asDate($bug.added);
    mod = asDate(opts.date);
    print("(" + Math.round(((mod - add) / 1000 / 60 / 60) * 100) / 100 + " hours after issue was added)");
    return hook($state, $bug.file);
  };

  get_user_details = function(callback) {
    if (opts.user && opts.email) {
      return callback();
    } else {
      return exec('git config --get user.email', function(se, so, e) {
        var stdin;
        if (so.length) {
          opts.email = so.replace(/[\r\n]+/, '');
          return exec('git config --get user.name', function(se, so, e) {
            if (so.length) {
              opts.user = so.replace(/[\r\n]+/, '');
            } else {
              opts.user = opts.email.replace(/@.+$/, '');
            }
            return callback();
          });
        } else {
          print("Tried to get email address from Git, but could not determine using:\n\r\n\tgit config --get user.email\r\n\nIt might be a good idea to set it with:\n\r\n\tgit config etc...\r\n");
          print("Please enter your details... (leave blank to abort)");
          stdin = process.openStdin();
          process.stdout.write("Name: ");
          return stdin.addListener("data", function(d) {
            if (!opts.user && (opts.user = d.toString().trim())) {
              return process.stdout.write("Email: ");
            } else if (!opts.email && (opts.email = d.toString().trim())) {
              process.stdin.destroy();
              return callback();
            } else {
              print("Error: tried everything, still no name and email!");
              return exit(1);
            }
          });
        }
      });
    }
  };

  get_confirmation = function(callback, message) {
    var stdin;
    stdin = process.openStdin();
    process.stdout.write("Are you sure? [yep/nope]: ");
    return stdin.addListener("data", function(d) {
      if (d.toString().match(/y(e(p|s|ah))?/i)) {
        callback();
        return process.stdin.destroy();
      } else {
        if (message) {
          print(message);
        }
        process.stdin.destroy();
        return exit(1);
      }
    });
  };

  get_required = function(items, final) {
    var item, stdin, _ref;
    stdin = process.stdin;
    if (!(items != null ? items.length : void 0)) {
      stdin.pause();
      if (!((_ref = opts.command.needs) != null ? _ref.length : void 0)) {
        delete opts.command.needs;
      }
      return final();
    } else {
      if (!opts.args[items[0]]) {
        item = items.shift();
      }
      if (!opts.args[item] && item) {
        process.stdout.write("" + item + ": ");
        stdin.resume();
        return stdin.once('data', function(d) {
          var line;
          stdin.pause();
          line = d.toString().trim();
          if (line) {
            opts.command.args[item] = line;
          } else {
            items.unshift(item);
          }
          return get_required(items, final);
        });
      }
    }
  };

  cmd = {};

  cmd.add = function(args) {
    var $priority, $title, $type, $uid;
    print(args);
    $uid = randomUID();
    $title = args.title;
    $type = args.type || 'bug';
    $priority = args.priority.replace(/\./, '-' || 0);
    opts.args.file = "" + opts.date + "." + $uid + ".log";
    opts.args.template = "UID: " + $uid + "\nType: " + $type + "\nPriority: " + $priority + "\nTitle: " + $title + "\nAdded: " + opts.date + "\nAuthor: " + opts.user + "\n\r\n";
    if (args.message) {
      fs.writeFileSync(opts.path + opts.store + opts.args.file, opts.args.template + args.message);
      print("added issue %" + glob.clrs.yellow + $uid + glob.clrs.reset);
      hook("add", opts.args.file);
    } else {
      opts.args.template += "# klog:\n# klog:  Enter your bug report here; it is better to write too much than\n# klog: too little.\n# klog:\n# klog:  Lines beginning with \"# klog:\" will be ignored, and removed,\n# klog: this file is saved.\n# klog:\r\n";
      fs.writeFileSync(opts.args.file, opts.args.template);
      editFile(opts.args.file);
      remove_comments(opts.args.file);
      print("added issue %" + glob.clrs.yellow + $uid + glob.clrs.reset);
      return hook("add", opts.args.file);
    }
  };

  cmd.append = function(args) {
    var $bug, $out;
    if (!args.id) {
      print("You must specify a bug to append to, either by the UID, or via the number.\nFor example to append text to bug number 3 you'd run:\n\r\n\tklog append 3\r\n");
      exit(1);
    }
    $bug = getBugByUIDORNumber(args.id);
    if (args.message || args.type) {
      $out = "\r\n\r\nModified: " + opts.date + "\r\n";
      if (args.type) {
        $out += "Type: " + args.type + "\r\n";
      }
      if (args.priority) {
        $out += "Priority: " + (args.priority.replace(/[\.]/, '-')) + "\r\n";
      }
      if (args.message !== '.') {
        $out += "" + (args.message || '');
      }
      fs.appendFileSync(opts.path + opts.store + $bug.file, $out);
      return;
    } else {
      $out = "\r\nModified: " + opts.date + "\r\n\r\n";
      fs.appendFileSync(opts.path + opts.store + $bug.file, $out);
    }
    editFile(opts.path + opts.store + $bug.file);
    return hook("append", $bug.file);
  };

  cmd.html = function(args) {
    var $b, $bugs, $closed, $closed_count, $open, $open_count, out, _i, _j, _k, _len, _len1, _len2;
    $bugs = getBugs();
    $open = [];
    $closed = [];
    for (_i = 0, _len = $bugs.length; _i < _len; _i++) {
      $b = $bugs[_i];
      if ($b.status.match(/open/i)) {
        $open.push($b);
      } else {
        $closed.push($b);
      }
    }
    $open_count = $open.length;
    $closed_count = $closed.length;
    out = "<!DOCTYPE HTML>\n<html lang=\"en-US\">\n<head>\n  <meta charset=\"UTF-8\">\n  <title>klog : issue tracking and time management</title>\n  <style type='text/css'>\n  body{\n    font-family: century gothic;\n  }\n  .bug {\n    background-color: silver;\n    border-radius: 0.5em 0.5em 0.5em 0.5em;\n    margin: 0.5em 0;\n    padding: 0.3em 1em;\n  }\n  #command-intro {\n    padding-left: 0.5em;\n    width: 37px;\n  }\n  input {\n    background-color: black;\n    border: medium none;\n    color: silver;\n    float: left;\n    height: 2em;\n    margin: 0;\n    padding: 0;\n  }\n  h1, h2, h3, h4, h5, h6, p, ul{\n    clear: both;\n  }\n  #command{\n    width: 40em\n  }\n  #execute{\n    border-left: 1px solid red\n  }\n  </style>\n</head>\n<body onload=\"document.getElementById('command').focus()\">\n  \n  <h1>Klog : issue tracking and time management</h1>\n\n  <ul>\n    <li><a href='#open' class='button'>" + $open_count + " : open bugs</a></li>\n    <li><a href='#closed' class='button'>" + $closed_count + " : closed bugs</a></li>\n  </ul>\n\n  <form action='.' method='POST'>\n    <input type=\"text\" value=\"$ klog\" readonly=\"readonly\" name=\"intro\" id=\"command-intro\">\n    <input type=\"text\" name=\"command\" id=\"command\">\n    <input type=\"submit\" id=\"execute\" value=\"execute!\">\n  </form>\n\n  <a name='open'></a>\n  <h2 id=\"open\">Open bugs</h2>";
    for (_j = 0, _len1 = $open.length; _j < _len1; _j++) {
      $b = $open[_j];
      out += "<div class='bug'>\n  <h3>" + $b.title + "</h3>\n  <ul>\n    <li>UID: " + $b.uid + "</li>\n    <li>Added: " + $b.added + "</li>\n    <li>Author: " + $b.author + "</li>\n    <li>Type: " + $b.type + "</li>\n  </ul>\n  <p>" + ($b.body.join("<br>\r\n<br>\r\n")) + "</p>\n  <hr>\n  <h4>Actions</h4>\n  <ul>\n    <li><a href='./?command=close " + $b.uid + "'>Close</a></li>\n    <li><a href='./?command=delete " + $b.uid + " -f'>Delete</a></li>\n  </ul>\n</div>";
    }
    out += "<h2 id=\"closed\">Closed bugs</h2>";
    for (_k = 0, _len2 = $closed.length; _k < _len2; _k++) {
      $b = $closed[_k];
      out += "<div class='bug'>\n  <h3>" + $b.title + "</h3>\n  <ul>\n    <li>UID: " + $b.uid + "</li>\n    <li>Added: " + $b.added + "</li>\n    <li>Author: " + $b.author + "</li>\n    <li>Type: " + $b.type + "</li>\n  </ul>\n  <p>" + ($b.body.join("\r\n")) + "</p>\n  <hr>\n  <h4>Actions</h4>\n  <ul>\n    <li><a href='./?command=reopen " + $b.uid + "'>Re-open</a></li>\n    <li><a href='./?command=delete " + $b.uid + " -f'>Delete</a></li>\n  </ul>\n</div>";
    }
    out += "  <div id=\"foot\">\n    Generated by <a href=\"http://billymoon.github.com/klog/\">klog</a>.\n  </div>\n</body>\n</html>";
    if (args["return"]) {
      return out;
    } else {
      return print(out);
    }
  };

  cmd.search = function(args) {
    var $b_body, $bug, $bugs, $match, $priority, $state, $term, $terms, $type, cb, ch, cr, found, hl, out, pool, pr, _i, _j, _len, _len1, _ref;
    $terms = args.terms;
    $bugs = getBugs();
    $state = args.state || 'all';
    $type = args.type || "all";
    $priority = args.priority || "all";
    found = [];
    out = [];
    for (_i = 0, _len = $bugs.length; _i < _len; _i++) {
      $bug = $bugs[_i];
      if ($state !== "all" && $state.toLowerCase() !== $bug.status.toLowerCase()) {
        continue;
      }
      if ($type !== "all" && $type.toLowerCase() !== $bug.type.toLowerCase()) {
        continue;
      }
      if (($priority + '').match(/\./)) {
        $priority = 0 - $priority * 10;
      }
      if ($priority !== "all" && $priority > $bug.priority) {
        continue;
      }
      $match = 1;
      $b_body = $bug.body.join('').replace(/(\\.|[^\w\s])/g, '');
      pool = args.all ? $bug.title + $bug.type + $b_body : $bug.title;
      if (args.terms) {
        _ref = $terms.split(/[ \t]+/);
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          $term = _ref[_j];
          if (!pool.match(new RegExp($term, 'i'))) {
            $match = 0;
          }
        }
      }
      if (!$match) {
        continue;
      }
      found.push($bug);
      hl = $bug.status === 'open' ? glob.clrs.green : glob.clrs.red;
      cb = glob.clrs.bright;
      ch = glob.clrs.yellow;
      cr = glob.clrs.reset;
      pr = $bug.priority > 1 ? glob.clrs.bright + glob.clrs.yellow : $bug.priority > 0 ? glob.clrs.yellow : $bug.priority < -1 ? glob.clrs.gunmetal : glob.clrs.silver;
      out.push("%" + hl + $bug.uid + glob.clrs.reset + " [" + pr + (pad(($bug.priority + '').replace(/^([1-9])/, '+$1'), 2, ' ')) + cr + "] [" + ch + $bug.status + cr + "] [" + (ch + cb) + $bug.type + cr + "] " + $bug.title);
    }
    if (args["return"]) {
      if (found.length === 1) {
        return found[0];
      }
      return print(out.join("\r\n"));
    } else {
      return print(out.join("\r\n"));
    }
  };

  cmd.view = function(args) {
    var $bug, $value, buffer;
    $value = args.id;
    if (!$value) {
      print("You must specify a bug to view, either by the UID, or via the number.\r\n");
      print("\r\nFor example to view bug number 3 you'd run:\r\n");
      print("\tklog view 3\r\n\r\n");
      print("Maybe a list of open bugs will help you:\r\n\r\n");
      cmd.search();
      print("\r\n");
      exit(1);
    }
    $bug = getBugByUIDORNumber($value);
    buffer = fs.readFileSync(opts.path + opts.store + $bug.file);
    return print(buffer.toString().replace(/^(\w+): /gm, "" + glob.clrs.yellow + "$1" + glob.clrs.reset + ": "));
  };

  cmd.close = function(args) {
    var $value;
    $value = args.id;
    if (!$value) {
      print("You must specify a bug to close, either by the UID, or via the number.\nFor example to close bug number 3 you'd run:\n\r\n\tklog close 3\r\n\r\n");
      exit(1);
    }
    return changeBugState($value, "closed");
  };

  cmd.reopen = function(args) {
    var $value;
    $value = args.id;
    if (!$value) {
      print("You must specify a bug to reopen, either by the UID, or via the number.\nFor example to reopen bug number 3 you'd run:\n\r\n\tklog reopen 3");
      exit(1);
    }
    return changeBugState($value, "open");
  };

  cmd.edit = function(args) {
    var $bug, $value;
    $value = args.id;
    if (!$value) {
      print("You must specify a bug to edit, either by the UID, or via the number.\nFor example to edit bug number 3 you'd run:\n\r\n\tklog edit 3\r\n\r\n");
      exit(1);
    }
    $bug = getBugByUIDORNumber($value);
    editFile(opts.path + opts.store + $bug.file);
    return hook("edit", $bug.file);
  };

  cmd["delete"] = function(args) {
    var do_delete;
    cmd.view(opts.command.args);
    do_delete = function() {
      var $bug, $file, $value;
      $value = args.id;
      if (!$value) {
        print("You must specify a bug to delete, either by the UID, or via the number.\nFor example to delete bug number 3 you'd run:\n\r\n\tklog delete 3\r\n");
        exit(1);
      }
      $bug = getBugByUIDORNumber($value);
      $file = $bug.file;
      fs.unlinkSync(opts.path + opts.store + $file);
      return hook("delete", $bug.file);
    };
    if (!args.force) {
      print("About to delete this bug...");
      return get_confirmation(function() {
        return do_delete();
      }, "Phew, that was close!");
    } else {
      return do_delete();
    }
  };

  cmd.init = function() {
    if (!fs.existsSync(opts.store)) {
      fs.mkdirSync(opts.store);
      opts.path = process.cwd() + '/';
      print("" + glob.clrs.gunmetal + "Now you have klogs on" + glob.clrs.reset + glob.clrs.red + "!" + glob.clrs.reset);
      return cmd.setup();
    } else {
      print("There is already a .klog/ directory present here");
      return exit(1);
    }
  };

  cmd.destroy = function(args) {
    if (args.force) {
      return exec("rm -Rf " + (opts.path + opts.store));
    } else {
      return print("This will destroy all issues. You must force this with `-f`.");
    }
  };

  cmd.setup = function() {
    var settings;
    if (opts.user && opts.email) {
      settings = "{\n  \"user\":\"" + (opts.user || 'John Doe') + "\",\n  \"email\":\"" + (opts.email || 'john@thedoughfactory.com') + "\"\n}";
      fs.writeFileSync("" + (opts.path + opts.store) + ".gitignore", "local");
      fs.mkdirSync("" + (opts.path + opts.store) + "local");
      fs.writeFileSync("" + (opts.path + opts.store) + "local/settings.json", settings);
      return print("Wrote settings to local file: " + (opts.path + opts.store) + "local/settings.json\r\n\r\n" + settings + "\r\n");
    } else {
      return get_user_details(cmd.setup);
    }
  };

  cmd.server = function() {
    var command, http, port, qs, url;
    opts.server = true;
    port = 1234;
    http = require('http');
    qs = require('querystring');
    url = require('url');
    command = function(data) {
      var args;
      if (data.command) {
        args = data.command.trim().split(' ');
      }
      print(args);
      while (process.argv.length > 2) {
        process.argv.pop();
      }
      _.each(args, function(v) {
        return process.argv.push(v);
      });
      opts.date = getDate();
      return main();
    };
    http.createServer(function(req, res) {
      var body, out_html, url_parts;
      out_html = function() {
        res.writeHead(200, {
          'Content-Type': 'text/html'
        });
        opts.command.args["return"] = true;
        return res.end(cmd.html(opts.command.args));
      };
      if (req.method === 'POST') {
        body = '';
        req.on('data', function(data) {
          return body += data;
        });
        return req.on('end', function() {
          var POST;
          POST = qs.parse(body);
          command(POST);
          return out_html();
        });
      } else if (req.method === 'GET') {
        url_parts = url.parse(req.url, true);
        command(url_parts.query);
        return out_html();
      }
    }).listen(port);
    return print("Serving `" + opts.path + "` at http://127.0.0.1:" + port + "/");
  };

  get_command = function() {
    var command, commands, get_id, has, message, out, rejects, requirement, subcommand, valid, x, _i, _j, _len, _len1, _ref, _ref1;
    out = {
      args: []
    };
    get_id = function() {
      var id;
      if (id = opts.args._.shift()) {
        return opts.args.id = id.replace(/^%/, '');
      }
    };
    commands = {
      add: {
        required: ['title', 'message'],
        valid: ['type', 'priority'],
        args: function() {
          if (opts.args._.length) {
            return opts.args.title = opts.args._.join(' ');
          }
        }
      },
      "delete": {
        required: ['id'],
        valid: ['force'],
        args: function() {
          var id;
          if (id = opts.args._.shift()) {
            return opts.args.id = id.replace(/^%/, '');
          }
        }
      },
      help: {},
      init: {},
      list: {
        valid: ['type', 'state', 'terms', 'all', 'return', 'priority'],
        args: function() {
          if (subcommand === 'search') {
            opts.args.all = true;
          }
          if (opts.args._.length) {
            return opts.args.terms = opts.args._.join(' ');
          }
        }
      },
      open: {
        required: ['state'],
        valid: ['type'],
        args: function() {
          return opts.args.state = 'open';
        }
      },
      closed: {
        required: ['state'],
        valid: ['type'],
        args: function() {
          return opts.args.state = 'closed';
        }
      },
      view: {
        required: ['id'],
        args: get_id
      },
      edit: {
        required: ['id'],
        valid: ['editor'],
        args: get_id
      },
      append: {
        required: ['id', 'message'],
        valid: ['type', 'priority'],
        args: get_id
      },
      reopen: {
        required: ['id'],
        args: get_id
      },
      close: {
        required: ['id'],
        args: get_id
      },
      html: {},
      server: {},
      destroy: {
        valid: ['force']
      }
    };
    for (command in commands) {
      if (!commands[command].valid) {
        commands[command].valid = [];
      }
      commands[command].valid.push('plain');
    }
    commands.search = commands.list;
    subcommand = opts.args._.shift() || 'help';
    command = commands[subcommand] || (subcommand = 'help');
    out.name = subcommand;
    if (command.args) {
      command.args();
    }
    if (command.required) {
      _ref = command.required;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        requirement = _ref[_i];
        if (has = opts.args[requirement]) {
          if (!out.args) {
            out.args = {};
          }
          out.args[requirement] = has;
        } else {
          if (!out.needs) {
            out.needs = [];
          }
          out.needs.push(requirement);
        }
      }
    }
    if (command.valid) {
      _ref1 = command.valid;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        valid = _ref1[_j];
        if (has = opts.args[valid]) {
          if (!out.args) {
            out.args = {};
          }
          out.args[valid] = has;
        }
      }
    }
    for (x in opts.args) {
      if (x !== '$0' && x !== '_') {
        if (!out.args[x]) {
          if (!rejects) {
            rejects = [];
          }
          rejects.push(x);
        }
      }
    }
    if (rejects) {
      message = "Error: unsupported option used";
      print(message);
      exit(1);
    }
    return out;
  };

  main = function() {
    var clr;
    opts.args = parseArgs();
    opts.command = get_command();
    opts.command.name = opts.command.name.replace(/^(open|closed|list)$/, 'search');
    if (opts.command.args.plain) {
      for (clr in glob.clrs) {
        glob.clrs[clr] = "";
      }
    }
    return get_required(opts.command.needs, function() {
      opts.args._.unshift(opts.command.name);
      if (opts.args.debug) {
        print(opts.args);
      }
      if (opts.args.exit) {
        exit(0);
      }
      if (opts.args.help || !opts.args._.length) {
        usage();
        exit(1);
      } else {
        opts.cmd = opts.args._.shift();
      }
      if (cmd[opts.command.name]) {
        return cmd[opts.command.name](opts.command.args);
      } else {
        return usage();
      }
    });
  };

  opts = {
    ext: 'log',
    date: getDate(),
    store: '.klog/',
    win: process.platform === 'win32'
  };

  path = process.cwd().split(/\//);

  for (_i = 0, _len = path.length; _i < _len; _i++) {
    folder = path[_i];
    sep = opts.win ? "\\" : "/";
    tpath = (path.join(sep)) + sep;
    if (fs.existsSync("" + (tpath + opts.store))) {
      opts.path = tpath;
      break;
    }
    path.pop();
  }

  if (fs.existsSync("" + (opts.path + opts.store) + "/local/settings.json")) {
    buffer = fs.readFileSync("" + (opts.path + opts.store) + "/local/settings.json");
    settings = JSON.parse(buffer.toString());
    opts = _.extend(opts, settings);
  }

  glob = {};

  glob.clrs = {
    bright: "\u001b[1m",
    red: "\u001b[31m",
    green: "\u001b[32m",
    blue: "\u001b[34m",
    cyan: "\u001b[36m",
    magenta: "\u001b[35m",
    yellow: "\u001b[33m",
    black: "\u001b[30m",
    gunmetal: "\u001b[30m\u001b[1m",
    silver: "\u001b[37m",
    white: "\u001b[37m\u001b[1m",
    back_red: "\u001b[41m",
    back_green: "\u001b[42m",
    back_blue: "\u001b[44m",
    back_cyan: "\u001b[46m",
    back_magenta: "\u001b[45m",
    back_yellow: "\u001b[43m",
    back_black: "\u001b[40m",
    back_silver: "\u001b[47m",
    reset: "\u001b[m"
  };

  hooks = {};

  if (fs.existsSync("" + (opts.path + opts.store) + "hooks")) {
    fs.readdirSync("" + (opts.path + opts.store) + "hooks").forEach(function(file) {
      return hooks[file.replace(/\.\w+$/, '')] = require("" + (opts.path + opts.store) + "hooks/" + file);
    });
  }

  main();

}).call(this);
