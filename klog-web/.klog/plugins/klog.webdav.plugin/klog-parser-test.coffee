klogs = [
  """
# Not enough coffee
+ Id: fgw6
+ Added: 2013-04-02 17:41
+ Author: Billy Moon

The problem is, that too much coffee is...

1. not enough coffee
2. too much coffee

This is not limited to coffee, but also to arake, and perhaps other beverages.

---
+ Modified: 2012-04-02 17:44
+ Modifier: Billy Moon

This is not a property of beverages, but rather a property of good things, which have a caveat!
""",
  """
# Not enough coffee script
+ Id: ke10
+ Added: 2013-04-02 17:46
+ Author: Billy Moon

The problem is, that too much coffee script is...

1. not enough coffee script
2. too much coffee script

This is not limited to coffee script, but also to sugar-js, and perhaps other convenience languages and frameworks.

---
+ Modified: 2012-04-02 17:44
+ Modifier: Billy Moon
+ Tags: +related:fgw6

This is not a property of languages and frameworks, but rather a property of good things, which have a caveat! See %fgw6
"""
,
  """
### Not the right syntax
+ Id: hjy8
+ Added: 2013-04-02 17:46:22
+ auTHor: Billy Moon
+ tags: good bad ugly

- not the right heading level for the title...
- meta labels in the modified section have the wrong list type identifiers
- added date has seconds
- modified date is wrong format, so left alone (perhaps should generate warning, and encourage human intervention)
- too many spaces before tags meta label, and before it's value
- mixed case in author meta label

---
+ Modified: 2012-04-02 17:44:02
+ Modifier: Billy Moon
+ Priority: 1

- -- ----- - - -- -
- Modified: 2012-04-02 x17:44:22
+ Modifier: Billy Moon
*   Tags:         +related:fgw6 -good bad

This is not a property of languages and frameworks, but rather a property of good things, which have a caveat! See %fgw6.

Just need another line here for testing!
"""
]

console.log window.klog.parse klogs