klogs = [
  """
# Not enough coffee
+ Id: fgw6
+ Added: 2013-04-02 17:41
+ Author: Billy Moon

The problem is, that too much coffee is...

1. not enough coffee
2. too much coffee

This is not limited to coffee, but also to arake, and perhaps other beverages.

---
+ Modified: 2012-04-02 17:44
+ Modifier: Billy Moon

This is not a property of beverages, but rather a property of good things, which have a caveat!
""",
  """
# Not enough coffee script
+ Id: ke10
+ Added: 2013-04-02 17:46
+ Author: Billy Moon

The problem is, that too much coffee script is...

1. not enough coffee script
2. too much coffee script

This is not limited to coffee script, but also to sugar-js, and perhaps other convenience languages and frameworks.

---
+ Modified: 2012-04-02 17:44
+ Modifier: Billy Moon
+ Tags: +related:fgw6

This is not a property of languages and frameworks, but rather a property of good things, which have a caveat! See %fgw6
"""
,
  """
### Not the right syntax
+ Id: hjy8
+ Added: 2013-04-02 17:46:22
+ auTHor: Billy Moon
+ tags: good bad ugly

- not the right heading level for the title...
- meta labels in the modified section have the wrong list type identifiers
- added date has seconds
- modified date is wrong format, so left alone (perhaps should generate warning, and encourage human intervention)
- too many spaces before tags meta label, and before it's value
- mixed case in author meta label

---
+ Modified: 2012-04-02 17:44:02
+ Modifier: Billy Moon
+ Priority: 1

- -- ----- - - -- -
- Modified: 2012-04-02 x17:44:22
+ Modifier: Billy Moon
*   Tags:         +related:fgw6 -good bad

This is not a property of languages and frameworks, but rather a property of good things, which have a caveat! See %fgw6.

Just need another line here for testing!
"""
]

klog = (klogs)->
  # utils
  toTitleCase = (str, all)->
    if all
      str.replace /\w\S*/g, (txt) ->
        txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
    else
      str.charAt(0).toUpperCase() + str.substr(1).toLowerCase()
  
  is_empty = (obj) ->
    
    # null and undefined are empty
    return true  unless obj?
    
    # Assume if it has a length property with a non-zero value
    # that that property is correct.
    return false  if obj.length and obj.length > 0
    return true  if obj.length is 0
    for key of obj
      return false  if hasOwnProperty.call(obj, key)
    true
  
  issues = []
  for klog in klogs
    lastline = ""
    in_meta = false
    current_meta = {}
    meta = {}
    sections = []
  
    # loop through the lines in the klog
    for line in klog.split /\n/
  
      # if it matches a klog meta list item
      if m = line.match /[+*-]\s*(\w+):\s*(.+)/
  
        # get key and val of list item
        key = m[1]
        val = m[2]
  
        # sanitize keys
        key = toTitleCase key
  
        # handle date type values
        if key.match /^added|modified$/i
          valdate = new Date val.replace /(\d{4}\W\d{2}\W\d{2})\W/, "$1T"
          if valdate.getTime? &! isNaN( valdate.getTime() )
            p = valdate.toISOString().split /\D/
            val = "#{p[0]}-#{p[1]}-#{p[2]} #{p[3]}:#{p[4]}"
  
        if in_meta
          meta[key] = val
  
        # handle start of meta section
        else
          in_meta = true
  
          if ! is_empty meta
            sections.push meta
            for k, v of meta
              if ! k.match /^message$/i
                current_meta[k] = v
          
          # start handling the current line
          meta = {}
  
          # if the previous line is not a markdown horizontal rule, assume it is a title
          if ! lastline.match /^(\s*-\s*){3,}$/
            meta["Title"] = lastline.replace /\s*#+\s*([^\n]+)[\r\n\s]*/, "$1"           
  
          # reset variables
          lastline = ""
  
        meta[key] = val
  
      # does not match klog list item
      else
        # handle end of meta section
        if in_meta
          in_meta = false
        else 
          if lastline.length
            meta.Message = (if meta.Message? then meta.Message else "") + lastline
          lastline = line + "\n"
  
    if lastline.length
        meta.Message = (if meta.Message? then meta.Message else "") + lastline + "\n"
      lastline = line + "\n"
  
    if ! is_empty meta
      sections.push meta
      for k, v of meta
        # if k.match /^tags$/i
        #   tags = meta.Tags.split /\s+/
        #   console.log tags
        #   for tag in v.split /\s+/
        #     if m = tag.match /^\+?([^-].*)$/
        #       if ! tags.indexOf m[1] > -1
        #         console.log "pushing: " + m[1]
        #         tags.push m[1]
        #   current_meta.Tags = tags.join " "
        #         # console.log m[1]
        # else...
        if ! k.match /^message$/i
          current_meta[k] = v
  
    issues.push {meta:current_meta,history:sections}
  issues

console.log klog klogs