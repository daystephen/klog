# coffee -cb klog-parser-dom-test.coffee && phantomjs klog-parser-dom-test.js && rm klog-parser-dom-test.js
page = require("webpage").create()

url = "http://local/test/klog/klog-web/klog/klog-parser-test.html"

page.onConsoleMessage = (msg) ->
  # if typeof msg == "object" then msg = JSON.stringify msg
  console.log "Log: " + msg

page.open url, (status) ->
  klogs = page.evaluate ->
    klogs = document.getElementsByClassName "klog"
    klogs[3].innerHTML
  console.log klogs
  # setTimeout ->
  phantom.exit()
  # , 2000
  #Page is loaded!

