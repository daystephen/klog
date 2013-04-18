## add email address of the author
+ Id: c4c8
+ Type: feature
+ Added: 2012-09-12 04:19
+ Status: open

this should be aiming to be a completely distributed system, so adding the email to the header would allow anyone fixing to contact the initial author of the issue. Alternatively, a hash of the email (or maybe just the firstbits) can be used, so that if you already know the email, then you know who the author is, and how to contact them, but if you don't know, then the email address is kept secure. This is only marginally better than writing the name of the author however, which might be a better approach to start with.

It is quite possible to try to extract this information from git, and failing that, to ask for it on the command line.
