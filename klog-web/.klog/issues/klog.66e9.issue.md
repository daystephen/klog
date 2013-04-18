## use gitub style tags
+ Id: 66e9
+ Type: feature
+ Added: 2012-09-12 04:50
+ Status: open

it is a more extensible system to be able to attach an indefinate number of tags to a bug indicating it's status, and type etc... there is no reason not to be able to customize the tags at will, maybe with a confirmation if a new tag type is being created.

---
+ Modified: 2012-09-12 04:50

It would be a nice idea to store tags as a comma separated list, and strip all spaces on reading.

Also, a -tagname should be used to remove a tag (tags matching this pattern will be ignored on parsing) and a +tagname for tags added (the `+` will be stripped on parsing).

Tags should probably have namespacing with `:`, so `priority:high` and `priority:low` or example.

For example, if an issue is tagged as `wontfix,priority:high`, then you add `spam` and remove `prioroty:high`, the modification will look like this:

    Modified: 2012-09-20_22-03-01.444
    Tags: wontfix, +spam, -priority:high