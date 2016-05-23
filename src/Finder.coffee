
assertType = require "assertType"
isType = require "isType"
assert = require "assert"
Void = require "Void"
Null = require "Null"
Type = require "Type"

type = Type "Finder", (target) ->
  @target = target
  @next()

type.optionTypes =
  regex: [ RegExp, String, Null, Void ]
  target: [ String, Null, Void ]

type.createArguments (args) ->

  if isType args[0], Finder.optionTypes.regex
    args[0] = { regex: args[0] }

  return args

type.exposeGetters [ "groups" ]

type.defineValues

  _groups: -> []

type.definePrototype

  _parenRegex: lazy: ->
    chars = "(|)".split("").map (char) -> "\\" + char
    return RegExp "(" + chars.join("|") + ")", "g"

  _regexFlags: value: {
    global: "g"
    ignoreCase: "i"
    multiline: "m"
  }

type.defineProperties

  target:
    value: null
    willSet: (newValue) ->
      assertType newValue, Finder.optionTypes.target
      @offset = 0
      return newValue

  pattern:
    get: -> @_regex.source
    set: (newValue) ->
      flags = { global: yes } # This forces 'lastIndex' to be remembered.
      if @_regex
        flags.multiline = yes if @_regex.multiline
        flags.ignoreCase = yes if @_regex.ignoreCase
      @_regex = @_createRegex newValue, flags

  group:
    value: 0
    willSet: (newValue) ->
      assertType newValue, Number
      return newValue

  offset:
    get: -> @_regex.lastIndex
    set: (newValue) ->
      assertType newValue, Number
      assert newValue >= 0, "'offset' must be >= 0!"
      @_regex.lastIndex = newValue

  _regex:
    value: null
    willSet: (newValue) ->
      assertType newValue, Finder.optionTypes.regex
      unless newValue?
        return RegExp ""
      if isType newValue, String
        @pattern = newValue
        return @_regex
      unless newValue.global
        flags = { global: yes } # This forces 'lastIndex' to be remembered.
        flags.multiline = yes if newValue.multiline
        flags.ignoreCase = yes if newValue.ignoreCase
        return @_createRegex newValue.source, flags
      return newValue
    didSet: (newValue, oldValue) ->
      @offset = 0
      if (oldValue is null) or (newValue.source isnt oldValue.source)
        @_groups = @_parseRegexGroups newValue.source

type.willBuild ->

  flagProps = {}
  [ "multiline", "ignoreCase" ].forEach (flag) ->
    flagProps[flag] =
      get: -> @_regex[flag]
      set: (newValue) ->
        assertType newValue, Boolean
        return if @_regex[flag] is newValue
        flags = @_parseRegexFlags @_regex
        if newValue then flags[flag] = newValue
        else delete flags[flag]
        @_regex = @_createRegex @pattern, flags

  type.defineProperties flagProps

type.initInstance (options) ->

  @_regex = options.regex

  # If no 'group' is specified, use the first one if it exists.
  # Otherwise, it defaults to returning the whole expression.
  @group = options.group ?= if @_groups.length > 1 then 1 else 0

  if options.target?
    @target = options.target

type.defineMethods

  next: ->
    if @offset < 0
      return null
    match = @_regex.exec @target
    assert @group < @groups.length, { @group, @groups, reason: "Index of capturing group is out of bounds!" }
    result = null
    if match?
      if @group is null
        result = match.slice 1
        result.index = match.index
        result.string = match[0]
      else
        result = match[@group]
    if result?
      return result
    @_regex.lastIndex = -1
    return null

  each: (target, iterator) ->
    if arguments.length is 1
      iterator = target
      target = @target
    assertType target, String
    assertType iterator, Function
    @_each target, iterator

  map: (target, iterator) ->
    if arguments.length is 1
      iterator = target
      target = @target
    assertType target, String
    assertType iterator, Function
    results = []
    @_each target, (match, index) ->
      results.push iterator match, index
    return results

  all: (target) ->
    target ?= @target
    assertType target, String
    matches = []
    @_each target, (match) -> matches.push match
    return matches

  test: (target) ->
    assertType target, String
    return @_withTarget target, =>
      match = @_regex.exec target
      return match?

  _each: (target, iterator) ->
    return @_withTarget target, =>
      index = 0
      loop
        match = @next()
        break if match is null
        iterator match, index++
      return

  _parseRegexGroups: (pattern) ->

    assertType pattern, String

    parens = []
    groups = [pattern]
    groupIndex = 0

    regex = @_parenRegex
    regex.lastIndex = 0

    loop
      match = regex.exec pattern
      break unless match

      continue if pattern[regex.lastIndex - 2] is "\\"

      char = match[0]

      if char is "("
        parens.push
          index: regex.lastIndex
          group: ++groupIndex

      else if char is ")"
        assert parens.length, "Unexpected right parenthesis!"
        paren = parens.pop()
        groups[paren.group] = pattern.slice paren.index, regex.lastIndex - 1

      else if char is "|"
        parens.pop()

    return groups

  _parseRegexFlags: (regex, flags = {}) ->

    assertType regex, [ RegExp, Object ]
    assertType flags, Object

    for name, flag of @_regexFlags

      if regex[name] is yes
        flags[flag] = yes

      else if regex[name] is no
        delete flags[flag]

    return flags

  _createRegex: (pattern, flags) ->

    assertType pattern, String
    assertType flags, Object

    flags = @_parseRegexFlags flags
    flags = Object.keys(flags).join ""
    return RegExp pattern, flags

  _withTarget: (target, callback) ->

    lastTarget = @target
    lastOffset = @offset

    @target = target
    result = callback()

    @target = lastTarget

    if lastOffset isnt null
      # Avoid 'this.offset' since 'lastOffset' might equal -1.
      @_regex.lastIndex = lastOffset

    return result

type.defineStatics

  find: (regex, target, group) ->
    finder = Finder._finder
    finder._regex = regex
    finder.group = if group? then group else 0
    return finder target

  test: (regex, target, group) ->
    finder = Finder._finder
    finder._regex = regex
    finder.group = if group? then group else 0
    return finder.test target

  _finder: lazy: ->
    Finder null

module.exports = Finder = type.build()
