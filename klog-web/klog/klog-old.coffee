(->

  # define the klog object
  klog = ()->

  klog.issues = []

  # define parse method
  klog.parse = (klogs)->

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
              # title = lastline.replace /\s*#+\s*([^\n]+)[\r\n\s]*/, "$1"
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
        # should be more like: {meta:meta,title:title,message:message}
        # should check if title or message exist
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
  
      # this is scrappy - never should be written there to need to be deleted
      title = current_meta.Title
      delete current_meta.Title

      issues.push {title:title,meta:current_meta,history:sections}

    issues

  # define parse method
  klog.json = (klogs)->

    # utils
    toTitleCase = (str, all)->
      if all
        str.replace /\w\S*/g, (txt) ->
          txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
      else
        str.charAt(0).toUpperCase() + str.substr(1).toLowerCase()
    
    is_empty = (obj) ->
      
      # null and undefined are empty
      return true unless obj?
      
      # Assume if it has a length property with a non-zero value
      # that that property is correct.
      return false if obj.length and obj.length > 0
      return true if obj.length is 0
      for key of obj
        return false if hasOwnProperty.call(obj, key)
      true
    
    issues = []
    for klog in klogs
      lastline = ""

      issues = []

      issue =
        title: ""
        meta: {}
        message: ""
        updates: []

      current = issue

      update =
        meta: {}
        message: ""

      # loop through the lines in the klog
      for line in klog.split /\n/

        # handle title
        if !lastline.length && m = line.match /^##\s*(.+)$/

          issue.title = m[1]

        # handle meta
        else if m = line.match /[+*-]\s*(\w+):\s*(.+)/

          # handle start meta
          # if lastline.match /^##\s*(.+)|---+$/
          if lastline.match /^---+$/
            if ! is_empty update.meta
              update.message = update.message.replace /\n\n?$/, ""
              issue.updates.push update
            update =
              meta: {}
              message: ""
            current = update

          issue.meta[m[1]] = m[2]
          current.meta[m[1]] = m[2]

        # handle end meta
        # we know the line we are on is not a meta line because of last condition section
        else if lastline.match /[+*-]\s*(\w+):\s*(.+)/

          # handle end of first meta block
          if !issue.original?
            issue.original = JSON.parse JSON.stringify issue.meta

        else if !line.match /^##\s*(.+)|---+$/

          current.message += line+"\n"

        # debug messages
        # console.dir JSON.parse JSON.stringify {line:line, last:lastline, total:JSON.parse JSON.stringify issue}

        # setting the lastline, should be the last thing to do in this loop
        lastline = line

      # finishing and cleanup
      if ! is_empty update.meta
        update.message = update.message.replace /\n\n?$/, ""
        issue.updates.push update
      issue.message = issue.message.replace /\n\n?$/, ""
      
      # debug messages
      # console.dir JSON.parse JSON.stringify {line:line, last:lastline, total:JSON.parse JSON.stringify issue}

      issues.push issue
    
    issues

  klog.loadFromWeb = (base, cb)->

    $.get base + "issues/", (d) ->
      issues = []
      $("a", d).each ->
        $this = $ @
        issues.push $this.attr("href") if $this.attr("href").match(/klog\.[a-zA-Z0-9]{4}\.issue\.md/)

      then_ = new Date()
      got = 0
      for i of issues
        $.get base + "issues/" + issues[i], (d) ->
          klog.issues.push d
          got++
          
          if got is issues.length
            # alert "got them all"
            cb()

        , "text"
    , (e) ->
      alert e
    , "text"

  if typeof exports is "object"
    module.exports = klog
  else if typeof define is "function" and define.amd
    define ->
      klog

  else
    @klog = klog

).call((-> @ || (if typeof window != "undefined" then window else global) )())