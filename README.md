
# finder v2.0.5 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

The `Finder` class provides a useful abstraction over the `RegExp` class.

```coffee
Finder = require "finder"

find = Finder "[a-z]+"

find "123 abc 345 def" # => "abc"
find.offset            # => 7

find.next()            # => "def"
find.offset            # => 15

find.next()            # => null
find.offset            # => -1

find.pattern = "^([a-z]+) [a-z]+$"  # A naive attempt at finding a person's name.
find.group = 1                      # This will cause only the first name to be returned.
find.ignoreCase = yes               # Allow [a-z] to match against [A-Z].

find "Alec Larson"     # => "Alec"
find "Alec"            # => null
```

And much more!
