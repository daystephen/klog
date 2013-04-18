require "sugar"
fs = require "fs"

base = "/Users/itaccess/docs/projects/mine/klog-files/klog/.klog/"
outdir = "/Users/itaccess/docs/www/test/klog-web/.klog/"

files = fs.readdirSync base

ids = []
for file in files
  if file.match /log$/
    issue = fs.readFileSync(base+file).toString()
    lines = issue.split /\n/g
    out = []
    for line in lines
      if m = line.match /^(\w+):\s*(.+)$/
        if m[1].match /^title$/i
          out.unshift "## #{m[2]}"
        else if m[1].match /^uid$/i
          id = m[2]
          out.push "+ Id: #{m[2]}"
        else if m[1].match /^modified$/i
          modified = Date.create("#{ai[0]}-#{ai[1]}-#{ai[2]} #{ai[3]}:#{ai[4]}:#{ai[5]}.#{ai[6]}").format("{yyyy}-{MM}-{dd} {hh}:{mm}")
          out.push "---"
          out.push "+ #{m[1]}: #{modified}"
        else if m[1].match /^added$/i
          ai = m[2].split(/\D/)
          # console.log added_in
          added = Date.create("#{ai[0]}-#{ai[1]}-#{ai[2]} #{ai[3]}:#{ai[4]}:#{ai[5]}.#{ai[6]}").format("{yyyy}-{MM}-{dd} {hh}:{mm}")
          out.push "+ #{m[1]}: #{added}"
        else
          out.push "+ #{m[1]}: #{m[2]}"
      else
        out.push line
    ids.push id
    issuetext = out.join "\n"
    console.log issuetext
    fs.writeFileSync "#{outdir}klog.#{id}.issue.md", issuetext
fs.writeFileSync "#{outdir}index.txt", ids.join " "
