## rtf support
+ Id: 2928
+ Type: bug
+ Priority: 0
+ Added: 2013-03-29 09:25
+ Author: Billy Moon

It is quite possible to add rtf support on osx, utalising textutil, and probably on ubuntu using pandoc.

cat ~/Desktop/issue.htm | textutil -convert rtf -stdin -stdout -format html | pbcopy

---
+ Modified: 2013-03-29 21-27-13.673
+ Type: feature
+ Priority: 1
