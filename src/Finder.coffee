
{ setType, setKind } = require "type-utils"
define = require "define"

Finder = module.exports = (options) ->

  if (options instanceof RegExp) or (typeof options is "string")
    regex = options
    options = { regex }

  finder = (target) ->
    finder.target = target
    finder.next()

  setType finder, Finder

  define finder,

    target:
      value: options.target or ""
      willSet: targetWillBeSet

    _groups: []

    _regex:
      willSet: _regexWillBeSet

  define finder, sharedDescriptors

  finder.group = options.group or (if finder.groups.length > 1 then 1 else 0)
  finder._regex = options.regex

  return finder

setKind Finder, Function

define Finder,

  find: (regex, target, group) ->
    _defaultFinder._regex = regex
    _defaultFinder.group = if group? then group else 0
    return _defaultFinder target

  test: (regex, target) ->
    _defaultFinder._regex = regex
    return _defaultFinder.test target

define Finder.prototype,

  next: ->
    if @offset < 0
      return null
    match = @_regex.exec @target
    unless @group < @groups.length
      error = RangeError "'this.group' must be less than #{@groups.length}, but equaled #{@group}."
      error.code = "BAD_GROUP"
      throw error
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
    iterator = target if typeof iterator isnt "function" and typeof target is "function"
    target = @target if typeof target isnt "string"
    return _tempTarget.call this, target, =>
      index = 0
      loop
        match = @next()
        break if match is null
        iterator match, index++
      return null

  map: (target, iterator) ->
    map = []
    @each target, (match, index) ->
      map.push iterator match, index
    return map

  reduce: (target, initial, iterator) ->
    unless iterator instanceof Function
      iterator = initial
      initial = target
      target = @target
    @each target, (match, index) ->
      initial = iterator initial, match, index
    return initial

  all: (target) ->
    matches = []
    @each target, (match) -> matches.push match
    return matches

  test: (target) ->
    unless typeof target is "string"
      error = TypeError "'target' must be a String."
      error.code = "BAD_TARGET_TYPE"
      throw error
    return _tempTarget.call this, target, =>
      match = @_regex.exec target
      return match?

sharedDescriptors =

  groups:
    get: ->
      @_groups

  offset:
    get: ->
      if @_regex? then @_regex.lastIndex
    set: (newValue) ->
      unless typeof newValue is "number"
        error = TypeError "'this.offset' must be a Number."
        error.code = "BAD_OFFSET_TYPE"
        throw error
      if newValue < 0
        error = RangeError "@offset must be >= 0"
        error.code = ""
        throw error
      @_regex.lastIndex = newValue

  pattern:
    get: ->
      if @_regex? then @_regex.source
    set: (newValue) ->
      flags = _getRegexFlags newValue, {}
      flags.g = yes
      flags = Object.keys(flags).join ""
      newValue = newValue.replace "\\", "\\\\"
      @_regex = RegExp newValue, flags
      @offset = 0

["ignoreCase", "multiline"].forEach (key) ->
  sharedDescriptors[key] =
    get: -> @_regex[key]
    set: (newValue) ->
      return if @_regex[key] is newValue
      newFlags = {}
      newFlags[key] = newValue
      @_regex = _setRegexFlags @_regex, newFlags


### PRIVATE VARS ###


targetWillBeSet = (target) ->
  unless typeof target is "string"
    error = TypeError "'target' must be a String."
    error.code = "BAD_TARGET_TYPE"
    throw error
  @offset = 0
  target

_parenRegex = /(\(|\))/g

_regexFlags =
  global: "g"
  ignoreCase: "i"
  multiline: "m"

_regexWillBeSet = (regex = "") ->
  if typeof regex is "string"
    @pattern = regex
    @_regex
  else if regex instanceof RegExp
    regex = if regex.global then regex else _setRegexFlags regex, global: yes
    @_groups = _getGroups regex
    regex
  else
    throw TypeError "You must pass either a RegExp or String when setting @_regex."

_getRegexFlags = (input, output) ->
  for key, value of _regexFlags
    inputValue = input[key]
    if inputValue is true
      output[value] = true
    else if inputValue is false
      delete output[value]
  return output

_setRegexFlags = (regex, newFlags) ->
  flags = {}
  _getRegexFlags regex, flags
  _getRegexFlags newFlags, flags
  newRegex = RegExp regex.source, Object.keys(flags).join ""
  newRegex.lastIndex = regex.lastIndex
  return newRegex

_getGroups = (regex) ->
  parens = []
  groups = [regex.source]
  groupIndex = 0
  _parenRegex.lastIndex = 0
  loop
    match = _parenRegex.exec regex.source
    break unless match
    continue if regex.source[_parenRegex.lastIndex - 2] is "\\"
    if match[0] is "("
      parens.push
        index: _parenRegex.lastIndex
        group: ++groupIndex
    else
      unless parens.length
        throw Error "Unexpected right parenthesis!"
      paren = parens.pop()
      groups[paren.group] = regex.source.slice paren.index, _parenRegex.lastIndex - 1
  return groups

_tempTarget = (target, fn) ->
  _offset = @offset
  _target = @target
  @target = target
  result = fn()
  @target = _target
  @_regex.lastIndex = _offset # Avoid range errors in case _offset is under zero.
  return result

_defaultFinder = Finder ""
