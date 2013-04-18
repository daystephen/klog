## seperate source into concatable files
+ Id: deb0
+ Type: feature
+ Added: 2012-09-12 04:40
+ Status: open

the source code should be made modular, so that as the code grows, it is easy to maintain and understand. I imagine a folder of files to be included, and some kind of makefile like script that concats them all together. I imagine for development that the I will use an alias to first build klog, and then run it, passing on the supplied arguments unaltered.
