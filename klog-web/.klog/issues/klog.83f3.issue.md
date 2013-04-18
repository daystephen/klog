## file structure
+ Id: 83f3
+ Type: feature
+ Priority: 1
+ Added: 2013-03-29 10:11
+ Author: Billy Moon

The files structure in the .klog directory is as follows

    [project-directory]
      .klog/
        issues/
          klog.df5x.issue.md
        attachments/
          klog.df5x.attachment.gh78.jpg
        user/
          klog-user-settings.json
          klog-user-settings-billy@itaccess.org.json
          klog-user-settings-AF78CE2349F097CB.json
        settings/
          klog-settings.json
        archive/
          klog.as9j.issue.md
          klog.as9j.attachment.ghj7.png
        plugins/
          klog.plugin-title.plugin.js
          klog.other-plugin-title.plugin/
            manifest.json
            anything.js

There are no files in the root directory, only folders. This helps to keep things nicely organised.

#### File comments

All files are named, so that even in a flat file system, it is clear what each file is. When klog tidies up the folders, it is important to be able to clearly identify what files are, so they can be correctly handled.

Filenames can be generated form file contents on most cases, perhaps settings files will contain their own filename - perhaps not.

- issues have filenames derived from this logic
  - klog
    - namespaces files, so all klog issues appear together in directory listings, even when outside of the klog folder.
    - identifies the kind of file - a quick google search should reveal what they are, even if found in unusual location.
  - df5x
    - the issue id, generated as a douglas crocford base32 (with lowercase letters) encoded string, derived from the exact time (preferably millisecond acurate) the issue is created, and the user who created it if known. This should avoid conflicts, where it is possible lots of issues are created at the same time (on some batch job) but should never be created by the same person at the same time.
    - the id should be the first four digits (giving 1,048,576 possible outcomes, making conflicting id unlikely)
  - issue
    - specifies the file type, as the generic .md file suffix alone does not reveal all the details of what the file is
  - md
    - markdown, to clearly indicate the the file is a valid markdown file, and as such, can be rendered as HTML, and manipulated/viewed/edited in any way a markdown file can be... for example, pasted into an issue page in github, or a question in stack overflow.
  - attachemnts have filenames derived from this logic
    - klog.df5x
      - so that attachments appear near issues if listed in the same folder
    - attachment
      - to make it the purpose of the document clear, that it is attached to another document in some way
    - gh78
      - unique id, in case people create attachments on the same issue independantly of each other
  - user
    - klog-user-settings
      - descriptive name, so it is clear what it is, even if it travels (or is in the wrong directory due to incorrect hand editing)
    - billy@itaccess.org [optional]
      - to namespace settings files, if they are tracked (not recommended) so that several users can keep their settings in the same folder
    - AF78CE2349F097CB [optional]
      - md5 hash derived from email address, to keep email anonymous, whilst the system (or other users), with knowledge of the current user's email address, can lookup the correct settings file
    - json
      - filetype is json, so it can store key value pairs in an easy to edit (with lots of tools) format
  - archive
    - klog.as9j.issue.md
      - store old issue files (not necessarily closed ones, but ones deliberately archived)
      - the klog binary can send all closed issues older than a month here for example
    - klog.as9j.attachment.ghj7.png
      - attachments are placed in here too, better to keep all the archived files in one place, for easy backup/management
  - plugins
    - klog.plugin-title.plugin.js
      - same principles as above, klog prefix ensures cohesive listing amongst other files, and it is identifyable as a plugin out of context
    - klog.other-plugin-title.plugin [folder]
      - manifest.json [madatory]
        - if the plugin is a folder (allowing more complex plugins), it must have a manifest, which amongst other things, will define the root plugin file to load
        - anything.js
          - the manifest specifies what to run, so it does not matter what the other files are called - they could even be buried in nested sub-folders without problem