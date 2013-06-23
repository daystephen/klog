(->

  # define the klog object
  self = (data)->
    # console.log @, 123
    self.json data

  self.utils =

    toTitleCase: (str, all)->
      if all
        str.replace /\w\S*/g, (txt) ->
          txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
      else
        str.charAt(0).toUpperCase() + str.substr(1).toLowerCase()
    
    isArray: (obj) ->
      
      obj.constructor.toString().match /array/i

    isEmpty: (obj) ->
      
      # null and undefined are empty
      return true unless obj?
      
      # Assume if it has a length property with a non-zero value
      # that that property is correct.
      return false if obj.length and obj.length > 0
      return true if obj.length is 0
      for key of obj
        return false if hasOwnProperty.call(obj, key)
      true

  self.issues = []

  # define parse method
  self.json = (klogs)->

    if ! self.utils.isArray klogs
      klogs = [klogs]

    issues = []
    for klog in klogs
      lastline = ""

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
            if ! self.utils.isEmpty update.meta
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

        # console.dir JSON.parse JSON.stringify {line:line, last:lastline, total:JSON.parse JSON.stringify issue}
        lastline = line

      # finishing and cleanup
      if ! self.utils.isEmpty update.meta
        update.message = update.message.replace /\n\n?$/, ""
        issue.updates.push update
      issue.message = issue.message.replace /\n\n?$/, ""
      
      # console.dir JSON.parse JSON.stringify {line:line, last:lastline, total:JSON.parse JSON.stringify issue}
      issues.push issue
    
    issues

  self.loadFromWeb = (base, cb)->

    $.get base + "issues/", (d) ->
      issue_ids = []
      $("a", d).each ->
        $this = $ @
        issue_ids.push $this.attr("href") if $this.attr("href").match(/klog\.[a-zA-Z0-9]{4}\.issue\.md/)

      got = 0
      issues = []
      for id of issue_ids
        $.get base + "issues/" + issue_ids[id], (issue) ->
          issues.push issue
          got++
          
          if got is issue_ids.length
            cb(issues)

        , "text"
    , (e) ->
      alert e
    , "text"

  if typeof exports is "object"
    module.exports = self
  else if typeof define is "function" and define.amd
    define ->
      self

  else
    @klog = self

).call((-> @ || (if typeof window != "undefined" then window else global) )())