
# finder v1.0.0 [![stable](http://badges.github.io/stability-badges/dist/stable.svg)](http://github.com/badges/stability-badges)

```sh
npm install aleclarson/finder#1.0.0
```

```CoffeeScript
find = Finder /[0-9]/
find "a 1 b 2 c 3"      # "1"
find.next()             # "2"
```

glossary
--------

[properties](#properties)

[methods](#methods)

[examples](#examples)

properties
----------

#### target

The current `String` being searched.

This is **writable**.

**Note:** Setting `@target` will reset `@offset` to `0`.

-

#### pattern

The `String` being used to find matches.

This is **writable**.

**Note:** Setting `@pattern` will reset `@offset` to `0`.

-

#### offset

The current start index when searching `@target`.

This is **writable**.

-

#### group

A `Number` that determines which capturing group to use from `@groups`.

If `@groups.length >= 1`, this defaults to `1`. Otherwise, this defaults to `0` (which just uses the whole matched string).

This is **writable**.

-

#### groups

An `Array` of the capture groups inside `@regex`.

This is **not writable**.

-

#### ignoreCase

A `Boolean` that determines if uppercase and lowercase characters are treated the same.

This is **writable**.

-

#### multiline

A `Boolean` that determines if multiple lines should be searched at once.

This is **writable**.

instance methods
----------------

#### ()

Sets `@target` to the given `String` and returns the first match found.

-

#### next()

Find and return the next result found when searching `@target`.

-

#### all()

Return an `Array` containing all matches found in `@target`.

If you pass a `String`, it becomes the value of `@target`. Otherwise, the current value of `@target` is searched.

-

#### test()

Return a `Boolean` indicating if any matches were found in `@target`.

If you pass a `String`, it becomes the value of `@target`. Otherwise, the current value of `@target` is searched.

-

#### each()

Pass the given `Function` every match found in `@target`. Additionally, the index is passed as the second argument.

If you pass a `String`, it becomes the value of `@target`. Otherwise, the current value of `@target` is searched.

-

#### map()

Pass the given `Function` every match found in `@target`. Additionally, the index is passed as the second argument.

Each value returned by the `Function` is pushed into an `Array`; and the `Array` is returned once finished.

If you pass a `String`, it becomes the value of `@target`. Otherwise, the current value of `@target` is searched.

-

#### reduce()

Call the given `Function` with every match found in `@target`. Additionally, the **result** is passed as the first argument. And the **index** is passed as the third argument.

If you pass a `String`, it becomes the value of `@target`. Otherwise, the current value of `@target` is searched.

class methods
-------------

#### find()

Takes a `RegExp` or `String` as the first argument.

Takes a `String` as the second argument.

Find the first match without needing to construct a `Finder` instance.

examples
--------

Import the `Finder` type.

```CoffeeScript
Finder = require "finder"
```

-

Construct an instance of `Finder`.

```CoffeeScript
find = Finder "[a-z]+"

find = Finder /[a-z]+/
```

-

Find the first match in a `String`.

```CoffeeScript
find "a b c" # "a"

find.offset  # 1
```

-

Find the next match in a `String`.

```CoffeeScript
find.next() # "b"

find.offset # 3
```

-

Find all matches in a `String`.

```CoffeeScript
find.all "foo"   # ["foo"]

find.all()       # ["a", "b", "c"]
```

-

See if a match exists in a `String`.

```CoffeeScript
find.regex.source # "[a-z]+"

find.test "d e f" # true
find.test "4 5 6" # false

find.target       # "a b c"
find.test()       # true
```

-

Iterate over all matches found in a `String`.

```CoffeeScript
find.each (match) ->
  console.log "Match: " + match

find.each "a b c", (match, index) ->
  console.log "Match " + index + ": " + match
```

-

Perform reductions and maps easily.

```CoffeeScript
result.regex.source # "[a-z]+"

result = find.reduce "x y z", [], (array, match, index) -> array.push match + index
result              # ["x1", "y2", "z3"]

result = find.map "no no no", (match, index) -> match + index
result              # ["no1", "no2", "no3"]
```
