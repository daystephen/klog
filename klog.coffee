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
argv = require('optimist').argv

#  Constants
opts =
  ext: 'log'; # file extension for data files

#
#  Functions
#


###
#
# Parse the command line options.
# 
###

parseCommandLineArguments = ->
  HELP = 0
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
  process.exit()

#
#  Parse any command line options.
#
parseCommandLineArguments()

#  Custom Modules

#
# MD5 Library
#
`MD5 = (function(){
/*
 * A JavaScript implementation of the RSA Data Security, Inc. MD5 Message
 * Digest Algorithm, as defined in RFC 1321.
 * Version 2.2 Copyright (C) Paul Johnston 1999 - 2009
 * Other contributors: Greg Holt, Andrew Kepert, Ydnar, Lostinet
 * Distributed under the BSD License
 * See http://pajhome.org.uk/crypt/md5 for more info.
 */

/*
 * Configurable variables. You may need to tweak these to be compatible with
 * the server-side, but the defaults work in most cases.
 */
var hexcase = 0;   /* hex output format. 0 - lowercase; 1 - uppercase        */
var b64pad  = "";  /* base-64 pad character. "=" for strict RFC compliance   */

/*
 * These are the functions you'll usually want to call
 * They take string arguments and return either hex or base-64 encoded strings
 */
var MD5 = function() {};

MD5.hex_md5 = function(s)    { return MD5.rstr2hex(MD5.rstr_md5(MD5.str2rstr_utf8(s))); }
MD5.b64_md5 = function(s)    { return MD5.rstr2b64(MD5.rstr_md5(MD5.str2rstr_utf8(s))); }
MD5.any_md5 = function(s, e) { return MD5.rstr2any(MD5.rstr_md5(MD5.str2rstr_utf8(s)), e); }
MD5.hex_hmac_md5 = function(k, d)
  { return MD5.rstr2hex(MD5.rstr_hmac_md5(MD5.str2rstr_utf8(k), MD5.str2rstr_utf8(d))); }
MD5.b64_hmac_md5 = function(k, d)
  { return MD5.rstr2b64(MD5.rstr_hmac_md5(MD5.str2rstr_utf8(k), MD5.str2rstr_utf8(d))); }
MD5.any_hmac_md5 = function(k, d, e)
  { return MD5.rstr2any(MD5.rstr_hmac_md5(MD5.str2rstr_utf8(k), MD5.str2rstr_utf8(d)), e); }

/*
 * Calculate the MD5 of a raw string
 */
MD5.rstr_md5 = function(s) {
  return MD5.binl2rstr(MD5.binl_md5(MD5.rstr2binl(s), s.length * 8));
}

/*
 * Calculate the HMAC-MD5, of a key and some data (raw strings)
 */
MD5.rstr_hmac_md5 = function(key, data) {
  var bkey = MD5.rstr2binl(key);
  if(bkey.length > 16) bkey = MD5.binl_md5(bkey, key.length * 8);

  var ipad = Array(16), opad = Array(16);
  for(var i = 0; i < 16; i++) {
    ipad[i] = bkey[i] ^ 0x36363636;
    opad[i] = bkey[i] ^ 0x5C5C5C5C;
  }

  var hash = MD5.binl_md5(ipad.concat(MD5.rstr2binl(data)), 512 + data.length * 8);
  return MD5.binl2rstr(MD5.binl_md5(opad.concat(hash), 512 + 128));
}

/*
 * Convert a raw string to a hex string
 */
MD5.rstr2hex = function(input) {
  try { hexcase } catch(e) { hexcase=0; }
  var hex_tab = hexcase ? "0123456789ABCDEF" : "0123456789abcdef";
  var output = "";
  var x;
  for(var i = 0; i < input.length; i++) {
    x = input.charCodeAt(i);
    output += hex_tab.charAt((x >>> 4) & 0x0F)
           +  hex_tab.charAt( x        & 0x0F);
  }
  return output;
}

/*
 * Convert a raw string to a base-64 string
 */
MD5.rstr2b64 = function(input) {
  try { b64pad } catch(e) { b64pad=''; }
  var tab = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  var output = "";
  var len = input.length;
  for(var i = 0; i < len; i += 3) {
    var triplet = (input.charCodeAt(i) << 16)
                | (i + 1 < len ? input.charCodeAt(i+1) << 8 : 0)
                | (i + 2 < len ? input.charCodeAt(i+2)      : 0);
    for(var j = 0; j < 4; j++) {
      if(i * 8 + j * 6 > input.length * 8) output += b64pad;
      else output += tab.charAt((triplet >>> 6*(3-j)) & 0x3F);
    }
  }
  return output;
}

/*
 * Convert a raw string to an arbitrary string encoding
 */
MD5.rstr2any = function(input, encoding) {
  var divisor = encoding.length;
  var i, j, q, x, quotient;

  /* Convert to an array of 16-bit big-endian values, forming the dividend */
  var dividend = Array(Math.ceil(input.length / 2));
  for(i = 0; i < dividend.length; i++) {
    dividend[i] = (input.charCodeAt(i * 2) << 8) | input.charCodeAt(i * 2 + 1);
  }

  /*
   * Repeatedly perform a long division. The binary array forms the dividend,
   * the length of the encoding is the divisor. Once computed, the quotient
   * forms the dividend for the next step. All remainders are stored for later
   * use.
   */
  var full_length = Math.ceil(input.length * 8 /
                                    (Math.log(encoding.length) / Math.log(2)));
  var remainders = Array(full_length);
  for(j = 0; j < full_length; j++) {
    quotient = Array();
    x = 0;
    for(i = 0; i < dividend.length; i++) {
      x = (x << 16) + dividend[i];
      q = Math.floor(x / divisor);
      x -= q * divisor;
      if(quotient.length > 0 || q > 0)
        quotient[quotient.length] = q;
    }
    remainders[j] = x;
    dividend = quotient;
  }

  /* Convert the remainders to the output string */
  var output = "";
  for(i = remainders.length - 1; i >= 0; i--)
    output += encoding.charAt(remainders[i]);

  return output;
}

/*
 * Encode a string as utf-8.
 * For efficiency, this assumes the input is valid utf-16.
 */
MD5.str2rstr_utf8 = function(input) {
  var output = "";
  var i = -1;
  var x, y;

  while(++i < input.length) {
    /* Decode utf-16 surrogate pairs */
    x = input.charCodeAt(i);
    y = i + 1 < input.length ? input.charCodeAt(i + 1) : 0;
    if(0xD800 <= x && x <= 0xDBFF && 0xDC00 <= y && y <= 0xDFFF) {
      x = 0x10000 + ((x & 0x03FF) << 10) + (y & 0x03FF);
      i++;
    }

    /* Encode output as utf-8 */
    if(x <= 0x7F)
      output += String.fromCharCode(x);
    else if(x <= 0x7FF)
      output += String.fromCharCode(0xC0 | ((x >>> 6 ) & 0x1F),
                                    0x80 | ( x         & 0x3F));
    else if(x <= 0xFFFF)
      output += String.fromCharCode(0xE0 | ((x >>> 12) & 0x0F),
                                    0x80 | ((x >>> 6 ) & 0x3F),
                                    0x80 | ( x         & 0x3F));
    else if(x <= 0x1FFFFF)
      output += String.fromCharCode(0xF0 | ((x >>> 18) & 0x07),
                                    0x80 | ((x >>> 12) & 0x3F),
                                    0x80 | ((x >>> 6 ) & 0x3F),
                                    0x80 | ( x         & 0x3F));
  }
  return output;
}

/*
 * Encode a string as utf-16
 */
MD5.str2rstr_utf16le = function(input) {
  var output = "";
  for(var i = 0; i < input.length; i++)
    output += String.fromCharCode( input.charCodeAt(i)        & 0xFF,
                                  (input.charCodeAt(i) >>> 8) & 0xFF);
  return output;
}

MD5.str2rstr_utf16be = function(input) {
  var output = "";
  for(var i = 0; i < input.length; i++)
    output += String.fromCharCode((input.charCodeAt(i) >>> 8) & 0xFF,
                                   input.charCodeAt(i)        & 0xFF);
  return output;
}

/*
 * Convert a raw string to an array of little-endian words
 * Characters >255 have their high-byte silently ignored.
 */
MD5.rstr2binl = function(input) {
  var output = Array(input.length >> 2);
  for(var i = 0; i < output.length; i++)
    output[i] = 0;
  for(var i = 0; i < input.length * 8; i += 8)
    output[i>>5] |= (input.charCodeAt(i / 8) & 0xFF) << (i%32);
  return output;
}

/*
 * Convert an array of little-endian words to a string
 */
MD5.binl2rstr = function(input) {
  var output = "";
  for(var i = 0; i < input.length * 32; i += 8)
    output += String.fromCharCode((input[i>>5] >>> (i % 32)) & 0xFF);
  return output;
}

/*
 * Calculate the MD5 of an array of little-endian words, and a bit length.
 */
MD5.binl_md5 = function(x, len) {
  /* append padding */
  x[len >> 5] |= 0x80 << ((len) % 32);
  x[(((len + 64) >>> 9) << 4) + 14] = len;

  var a =  1732584193;
  var b = -271733879;
  var c = -1732584194;
  var d =  271733878;

  for(var i = 0; i < x.length; i += 16) {
    var olda = a;
    var oldb = b;
    var oldc = c;
    var oldd = d;

    a = MD5.md5_ff(a, b, c, d, x[i+ 0], 7 , -680876936);
    d = MD5.md5_ff(d, a, b, c, x[i+ 1], 12, -389564586);
    c = MD5.md5_ff(c, d, a, b, x[i+ 2], 17,  606105819);
    b = MD5.md5_ff(b, c, d, a, x[i+ 3], 22, -1044525330);
    a = MD5.md5_ff(a, b, c, d, x[i+ 4], 7 , -176418897);
    d = MD5.md5_ff(d, a, b, c, x[i+ 5], 12,  1200080426);
    c = MD5.md5_ff(c, d, a, b, x[i+ 6], 17, -1473231341);
    b = MD5.md5_ff(b, c, d, a, x[i+ 7], 22, -45705983);
    a = MD5.md5_ff(a, b, c, d, x[i+ 8], 7 ,  1770035416);
    d = MD5.md5_ff(d, a, b, c, x[i+ 9], 12, -1958414417);
    c = MD5.md5_ff(c, d, a, b, x[i+10], 17, -42063);
    b = MD5.md5_ff(b, c, d, a, x[i+11], 22, -1990404162);
    a = MD5.md5_ff(a, b, c, d, x[i+12], 7 ,  1804603682);
    d = MD5.md5_ff(d, a, b, c, x[i+13], 12, -40341101);
    c = MD5.md5_ff(c, d, a, b, x[i+14], 17, -1502002290);
    b = MD5.md5_ff(b, c, d, a, x[i+15], 22,  1236535329);

    a = MD5.md5_gg(a, b, c, d, x[i+ 1], 5 , -165796510);
    d = MD5.md5_gg(d, a, b, c, x[i+ 6], 9 , -1069501632);
    c = MD5.md5_gg(c, d, a, b, x[i+11], 14,  643717713);
    b = MD5.md5_gg(b, c, d, a, x[i+ 0], 20, -373897302);
    a = MD5.md5_gg(a, b, c, d, x[i+ 5], 5 , -701558691);
    d = MD5.md5_gg(d, a, b, c, x[i+10], 9 ,  38016083);
    c = MD5.md5_gg(c, d, a, b, x[i+15], 14, -660478335);
    b = MD5.md5_gg(b, c, d, a, x[i+ 4], 20, -405537848);
    a = MD5.md5_gg(a, b, c, d, x[i+ 9], 5 ,  568446438);
    d = MD5.md5_gg(d, a, b, c, x[i+14], 9 , -1019803690);
    c = MD5.md5_gg(c, d, a, b, x[i+ 3], 14, -187363961);
    b = MD5.md5_gg(b, c, d, a, x[i+ 8], 20,  1163531501);
    a = MD5.md5_gg(a, b, c, d, x[i+13], 5 , -1444681467);
    d = MD5.md5_gg(d, a, b, c, x[i+ 2], 9 , -51403784);
    c = MD5.md5_gg(c, d, a, b, x[i+ 7], 14,  1735328473);
    b = MD5.md5_gg(b, c, d, a, x[i+12], 20, -1926607734);

    a = MD5.md5_hh(a, b, c, d, x[i+ 5], 4 , -378558);
    d = MD5.md5_hh(d, a, b, c, x[i+ 8], 11, -2022574463);
    c = MD5.md5_hh(c, d, a, b, x[i+11], 16,  1839030562);
    b = MD5.md5_hh(b, c, d, a, x[i+14], 23, -35309556);
    a = MD5.md5_hh(a, b, c, d, x[i+ 1], 4 , -1530992060);
    d = MD5.md5_hh(d, a, b, c, x[i+ 4], 11,  1272893353);
    c = MD5.md5_hh(c, d, a, b, x[i+ 7], 16, -155497632);
    b = MD5.md5_hh(b, c, d, a, x[i+10], 23, -1094730640);
    a = MD5.md5_hh(a, b, c, d, x[i+13], 4 ,  681279174);
    d = MD5.md5_hh(d, a, b, c, x[i+ 0], 11, -358537222);
    c = MD5.md5_hh(c, d, a, b, x[i+ 3], 16, -722521979);
    b = MD5.md5_hh(b, c, d, a, x[i+ 6], 23,  76029189);
    a = MD5.md5_hh(a, b, c, d, x[i+ 9], 4 , -640364487);
    d = MD5.md5_hh(d, a, b, c, x[i+12], 11, -421815835);
    c = MD5.md5_hh(c, d, a, b, x[i+15], 16,  530742520);
    b = MD5.md5_hh(b, c, d, a, x[i+ 2], 23, -995338651);

    a = MD5.md5_ii(a, b, c, d, x[i+ 0], 6 , -198630844);
    d = MD5.md5_ii(d, a, b, c, x[i+ 7], 10,  1126891415);
    c = MD5.md5_ii(c, d, a, b, x[i+14], 15, -1416354905);
    b = MD5.md5_ii(b, c, d, a, x[i+ 5], 21, -57434055);
    a = MD5.md5_ii(a, b, c, d, x[i+12], 6 ,  1700485571);
    d = MD5.md5_ii(d, a, b, c, x[i+ 3], 10, -1894986606);
    c = MD5.md5_ii(c, d, a, b, x[i+10], 15, -1051523);
    b = MD5.md5_ii(b, c, d, a, x[i+ 1], 21, -2054922799);
    a = MD5.md5_ii(a, b, c, d, x[i+ 8], 6 ,  1873313359);
    d = MD5.md5_ii(d, a, b, c, x[i+15], 10, -30611744);
    c = MD5.md5_ii(c, d, a, b, x[i+ 6], 15, -1560198380);
    b = MD5.md5_ii(b, c, d, a, x[i+13], 21,  1309151649);
    a = MD5.md5_ii(a, b, c, d, x[i+ 4], 6 , -145523070);
    d = MD5.md5_ii(d, a, b, c, x[i+11], 10, -1120210379);
    c = MD5.md5_ii(c, d, a, b, x[i+ 2], 15,  718787259);
    b = MD5.md5_ii(b, c, d, a, x[i+ 9], 21, -343485551);

    a = MD5.safe_add(a, olda);
    b = MD5.safe_add(b, oldb);
    c = MD5.safe_add(c, oldc);
    d = MD5.safe_add(d, oldd);
  }
  return Array(a, b, c, d);
}

/*
 * These functions implement the four basic operations the algorithm uses.
 */
MD5.md5_cmn = function(q, a, b, x, s, t) {
  return MD5.safe_add(MD5.bit_rol(MD5.safe_add(MD5.safe_add(a, q), MD5.safe_add(x, t)), s),b);
}
MD5.md5_ff = function(a, b, c, d, x, s, t) {
  return MD5.md5_cmn((b & c) | ((~b) & d), a, b, x, s, t);
}
MD5.md5_gg = function(a, b, c, d, x, s, t) {
  return MD5.md5_cmn((b & d) | (c & (~d)), a, b, x, s, t);
}
MD5.md5_hh = function(a, b, c, d, x, s, t) {
  return MD5.md5_cmn(b ^ c ^ d, a, b, x, s, t);
}
MD5.md5_ii = function(a, b, c, d, x, s, t) {
  return MD5.md5_cmn(c ^ (b | (~d)), a, b, x, s, t);
}

/*
 * Add integers, wrapping at 2^32. This uses 16-bit operations internally
 * to work around bugs in some JS interpreters.
 */
MD5.safe_add = function(x, y) {
  var lsw = (x & 0xFFFF) + (y & 0xFFFF);
  var msw = (x >> 16) + (y >> 16) + (lsw >> 16);
  return (msw << 16) | (lsw & 0xFFFF);
}

/*
 * Bitwise rotate a 32-bit number to the left.
 */
MD5.bit_rol = function(num, cnt) {
  return (num << cnt) | (num >>> (32 - cnt));
}

return MD5;

})()`

cmd_init = ->
  console.log 'will init'

cmd_add = (args) ->
  console.log 'will add with ' + args

cmd_append = (args) ->
  console.log 'will append with ' + args

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

cmd_init = (args) ->
  console.log 'will init with ' + args


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
  process.exit 0

else if $cmd.match /^add$/i

  #
  #  Add a bug.
  #
  cmd_add $args
  process.exit 0
else if $cmd.match /^append$/i

  #
  #  Append a section of text to an existing bug report.
  #
  cmd_append $args
  process.exit 0
else if $cmd.match /^html$/i

  #
  #  Output bugs as a simple HTML page.
  #
  cmd_html $args
  process.exit 0
else if $cmd.match /^(list|search)$/i

  #
  #  Find bugs.
  #
  cmd_search $args
  process.exit 0
else if $cmd.match /^open$/i

  #
  #  List only open bugs.
  #
  cmd_search $args, 'open'
  process.exit 0
else if $cmd.match /^closed$/i

  #
  #  List only closed bugs.
  #
  cmd_search $args, 'closed'
  process.exit 0
else if $cmd.match /^view$/i

  #
  #  View a single bug.
  #
  cmd_view $args
  process.exit 0
else if $cmd.match /^close$/i

  #
  #  Mark a bug as closed.
  #
  cmd_close $args
  process.exit 0
else if $cmd.match /^reopen$/i

  #
  #  Mark a bug as open.
  #
  cmd_reopen $args
  process.exit 0
else if $cmd.match /^edit$/i

  #
  #  Edit a bug.
  #
  cmd_edit $args
  process.exit 0
else if $cmd.match /^delete$/i

  #
  #  Delete a bug.
  #
  cmd_delete $args
  process.exit 0
else
  usage()

process.exit 0


debug =
  opts: opts
  argv: argv
  cmd: $cmd
  args: $args
console.log debug
old_code = """



###
###  Handlers for the commands.
###
###


# 
# Inititalise a new .klog directory.
# 
# 
###

sub cmd_init
{
    if ( !-d ".klog" )
    {
        mkpath( ".klog", { verbose => 0 } );
        exit 0;
    }
    else
    {
        print "There is already a .klog/ directory present here.\n";
        exit 1;
    }
}


# 
# Add a new bug.
# 
# The arguments specified are the optional title.
# 
# 
###

sub cmd_add
{
    my (@args) = (@_);

    my $title = undef;
    if ( scalar(@args) )
    {
        $title = join( " ", @args );
    }

    $title = "Untitled bug report" unless ( defined($title) );

    my $type =  $CONFIG{ 'type'} || 'bug';

    #
    #  Make a "random" filename, with the same UID as the content.s
    #
    my $uid  = randomUID();
    my $file = ".klog/".date().".$uid.log";

    my $date = date();

    #
    #  Write our template to it
    #
    open( FILE, ">", $file );
    print FILE<<EOF;
UID: $uid
Type: $type
Title: $title
Added: $date
Status: open

EOF


    #
    #  If we were given a message, add it to the file, and return without
    # invoking the editor.
    #
    if ( $CONFIG{ 'message' } )
    {
        print FILE $CONFIG{ 'message' };
        print FILE "\n";
        close(NEW);
        return;
    }


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
    else
    {

        #
        #  Otherwise add the default text, and show it in an editor.
        #
        print FILE<<EOF;
# klog:
# klog:  Enter your bug report here; it is better to write too much than
# klog: too little.
# klog:
# klog:  Lines beginning with "# klog:" will be ignored, and removed,
# klog: this file is saved.
# klog:

EOF
        close(FILE);
    }


    #
    #  Open the file in the users' editor.
    #
    editFile($file);

    #
    #  Once it was saved remove the lines that mention "# klog: "
    #
    removeClog($file);

    #
    #  If there is a hook, run it.
    #
    if ( -x ".klog/hook" )
    {
        system( ".klog/hook", "add", $file );
    }
}

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

sub cmd_append
{
    my (@args) = (@_);
    my $value = join( "", @args );


    #
    #  Ensure we know what we're operating upon
    #
    if ( !length($value) )
    {
        print
          "You must specify a bug to append to, either by the UID, or via the number.\n";
        print "\nFor example to append text to bug number 3 you'd run:\n";
        print "\tklog append 3\n\n";
        exit 1;
    }

    #
    #  Get the bug
    #
    my $bug = getBugByUIDORNumber($value);

    #
    #  Open the file.
    #
    open( NEW, ">>", $bug->{ 'file' } ) or
      die "Failed to open file $bug->{'file'} for appending: $!";


    my $date = date();

    #
    #  If we were given a message add it, otherwise spawn the editor.
    #
    if ( $CONFIG{ 'message' } )
    {
        print NEW "\nModified: $date\n";
        print NEW $CONFIG{ 'message' };
        print NEW "\n";
        close(NEW);
        return;
    }

    #
    #  Write out the new section
    #
    print NEW <<EOF;

Modified: $date

# klog:
# klog:  Enter your bug update here; it is better to write too much than
# klog: too little.
# klog:
# klog:  Lines beginning with "# klog:" will be ignored, and removed, once
# klog: this file is saved.
# klog:
EOF
    close(NEW);

    #
    #  Allow the user to make the edits.
    #
    editFile( $bug->{ 'file' } );

    #
    #  Once it was saved remove the lines that mention "# klog: "
    #
    removeClog( $bug->{ 'file' } );

    #
    #  If there is a hook, run it.
    #
    if ( -x ".klog/hook" )
    {
        system( ".klog/hook", "append", $bug->{ 'file' } );
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

###
###  Utility functions.
###
###

#
# return date in format
#
#    yyyy-mm-dd_hh-ii-ss
#
###

sub date
{

    if(!$executionDate){
      my ( $time, $microseconds ) = gettimeofday;
      $executionDate = sprintf "%d-%02d-%02d_%02d-%02d-%02d.%06d", map { $$_[5]+1900, $$_[4]+1, $$_[3], $$_[2], $$_[1], $$_[0], $microseconds } [localtime];      
    }

    return $executionDate;
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

# 
# Generate a system UID.  This should be created with the hostname and
# time included, such that collisions when running upon multiple systems
# are unlikely.
# 
# (A bug will be uniquely referenced by the UID, even though in practise
# people will use bug numbers they are prone to change.)
# 
# 
###

sub randomUID
{

    #
    #  The values that feed into the filename.
    #
    my $email = `git config --get user.email`;
    chomp $email;
    my $uid = join ".", date(), $email;
    $uid = md5($uid);
    $uid =~ s/(.{4}).+/$1/;

    return ($uid);
}

# 
# Find and return an array of hashes, one for each existing bug.
# 
# 
###

sub getBugs
{
    my $results;
    my $number = 0;

    foreach my $file ( sort( glob(".klog/*.$ext") ) )
    {
        $number += 1;

        my $status;
        my $title;
        my $type;
        my $uid;
        my $body;

        open( FILE, "<", $file );
        while ( my $line = <FILE> )
        {
            if ( $line =~ /^Title: (.*)/ )
            {
                $title = $1;
            }
         
            if ( $line =~ /^Type: (.*)/ )
            {
                $type = $1;
            }
            elsif ( $line =~ /^(Added|Modified):(.*)/ )
            {

                # ignored.
            }
            elsif ( $line =~ /^UID: (.*)/ )
            {
                $uid = $1;
            }
            elsif ( $line =~ /^Status: (.*)/i )
            {
                $status = $1;
            }
            else
            {
                $body .= $line;
            }

        }
        close(FILE);

        push( @$results,
              {  file   => $file,
                 body   => $body,
                 number => $number,
                 uid    => $uid,
                 status => $status,
                 type => $type,
                 title  => $title
              } );
    }

    return ($results);
}


# 
# Open the given file with either the users editor, the systems editor,
# or as a last resort vim.
# 
# 
###

sub editFile
{
    my ($file) = (@_);

    #
    #  Open the editor
    #
    my $editor = $CONFIG{ 'editor' } || $ENV{ 'EDITOR' } || "vim";
    system( $editor, $file );

}


# 
# Remove the "# klog: " prefix from the given file.
# 
# 
###

sub removeClog
{
    my ($file) = (@_);

    my @lines;

    #
    #  Open the source file for reading.
    #
    open( FILE, "<", $file ) or
      die "Failed to open $file - $!";

    #
    #  Read it, and store the contents away.
    #
    while ( my $line = <FILE> )
    {
        push( @lines, $line );
    }
    close(FILE);


    #
    #  Open the file for writing.
    #
    open( NEW, ">", $file ) or
      die "Failed to open $file - $!";

    #
    #  Write the contents, removing any lines matching our marker-pattern
    #
    foreach my $line (@lines)
    {
        next if ( $line =~ /^# klog:/ );
        print NEW $line;
    }
    close(NEW);

}

# 
# Get the data for a given bug, either by number of UID.
# 
# 
###

sub getBugByUIDORNumber
{
    my ($arg) = (@_);

    #
    #  Get all bugs.
    #
    my $bugs = getBugs();
    my $bug;

    #
    #  For each one.
    #
    foreach my $possible (@$bugs)
    {

        #
        # If the argument was NNNN then look for that bug number.
        #
        if ( $arg =~ /^([0-9]+)$/i )
        {
            $bug = $possible if ( $1 == $possible->{ 'number' } );
        }
        else
        {

            #
            #  Otherwise look for it by UID
            #
            $bug = $possible if ( lc($arg) eq lc( $possible->{ 'uid' } ) );
        }

        return $bug if ( defined($bug) );
    }

    if ( !defined($bug) )
    {
        print "Bug not found: $arg\n";
        exit 1;
    }

}
"""