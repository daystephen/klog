## merging of klog files is hard
+ Id: f2ec
+ Type: strategy
+ Added: 2012-09-19 04:26
+ Author: undefined

The merging of klog files, editied separately is trivial for klog to do (just use date ordering) but requires user intervention if handled by git. Maybe there is a way to deal with this with hooks. ALl klog files should be merged by klog before or after commits.
